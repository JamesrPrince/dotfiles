#!/bin/bash
# Claude Code hook: records each session's state for the SketchyBar "claude" item
# (sketchybar/items/claude.sh). Registered in ~/.claude/settings.json for SessionStart,
# UserPromptSubmit, Notification, Stop and SessionEnd. Reads the hook JSON on stdin.
#   SessionStart -> idle   UserPromptSubmit -> working   Notification -> waiting
#   Stop -> done           SessionEnd -> state file removed
# One file per session in ${TMPDIR:-/tmp}/claude_sessions/, six lines:
#   status, folder name, full cwd, PID of the claude process, epoch time, Ghostty window id,
#   last prompt (first 40 chars), context tokens in use, model, waiting reason (only while waiting).
# Prompt comes from UserPromptSubmit, the reason from Notification's message, and context and model
# from the last assistant turn in the transcript; each keeps its old value when an event lacks it.
# The window id is the AeroSpace id of the window focused when the session starts or a prompt is
# sent (you just typed there, so it is this session's window); the bar's popup rows focus it.
# Always exits 0 and prints nothing on stdout, so it can never block or pollute a session.
# CLAUDE_HEADLESS=1 skips everything: set it on `claude -p` runs (no launchd job uses one
# today) so they never show up in the bar.

exec >/dev/null 2>&1
[ "$CLAUDE_HEADLESS" = 1 ] && exit 0
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"

input=$(cat)
IFS=$'\t' read -r sid cwd event tpath < <(printf '%s' "$input" | jq -r '[.session_id // "", .cwd // "", .hook_event_name // "", .transcript_path // ""] | @tsv')
case "$sid" in ""|*/*|.*) exit 0 ;; esac

DIR="${TMPDIR:-/tmp}/claude_sessions"
mkdir -p "$DIR"
FILE="$DIR/$sid"

case "$event" in
  SessionStart)     status=idle ;;
  UserPromptSubmit) status=working ;;
  Notification)     status=waiting ;;
  Stop)             status=done ;;
  SessionEnd)       rm -f "$FILE"; sketchybar --trigger claude_update & exit 0 ;;
  *) exit 0 ;;
esac

# The claude process: $PPID may be a shell wrapping the hook, so walk up until the command is claude
pid=$PPID
p=$PPID
for _ in 1 2 3 4 5 6; do
  comm=$(ps -o comm= -p "$p" 2>/dev/null)
  case "${comm##*/}" in claude*) pid=$p; break ;; esac
  p=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ')
  [ -n "$p" ] && [ "$p" -gt 1 ] 2>/dev/null || break
done

# This session's window: the focused Ghostty window at SessionStart / UserPromptSubmit; else keep the old one
wid=""
prompt=""; ctx=""; model=""
[ -f "$FILE" ] && { wid=$(sed -n 6p "$FILE"); prompt=$(sed -n 7p "$FILE"); ctx=$(sed -n 8p "$FILE"); model=$(sed -n 9p "$FILE"); }

# Last prompt: one line, no separators the bar splits on, pasted-text wrapper tags dropped,
# cut to 40 characters
if [ "$event" = UserPromptSubmit ]; then
  prompt=$(printf '%s' "$input" | jq -r '.prompt // ""' | tr '\n\t|' '   ' \
    | sed -E 's#</?pasted_content[^>]*>##g' | tr -s ' ' | sed 's/^ //' | cut -c1-40)
fi
# Waiting reason, e.g. "Claude needs your permission to use Bash" -> "permission to use Bash"
reason=""
if [ "$event" = Notification ]; then
  reason=$(printf '%s' "$input" | jq -r '.message // ""' | tr '\n|' '  ' \
           | sed -E 's/^Claude (needs your|is waiting for( your)?) //; s/ +$//' | cut -c1-40)
fi
# Context in use and model, from the newest assistant turn that carries usage
if [ -n "$tpath" ] && [ -f "$tpath" ]; then
  IFS=$'\t' read -r m c < <(tail -n 120 "$tpath" | jq -r 'select(.type=="assistant" and .message.usage)
      | [.message.model // "", ((.message.usage | (.input_tokens // 0) + (.cache_read_input_tokens // 0)
         + (.cache_creation_input_tokens // 0) + (.output_tokens // 0)))] | @tsv' 2>/dev/null | tail -1)
  [ -n "$c" ] && [ "$c" -gt 0 ] 2>/dev/null && ctx=$c
  # claude-opus-5-5 -> Opus 5.5
  [ -n "$m" ] && model=$(printf '%s' "$m" | sed -E 's/^claude-//; s/-([0-9]+)-([0-9]+).*$/ \1.\2/' | awk '{ print toupper(substr($0,1,1)) substr($0,2) }')
fi
case "$event" in
  SessionStart|UserPromptSubmit)
    IFS='|' read -r fid fapp < <(aerospace list-windows --focused --format '%{window-id}|%{app-name}' 2>/dev/null)
    [ "$fapp" = Ghostty ] && [ -n "$fid" ] && wid=$fid ;;
esac

printf '%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n' "$status" "$(basename "${cwd:-?}")" "$cwd" "$pid" "$(date +%s)" "$wid" \
  "$prompt" "$ctx" "$model" "$reason" > "$FILE.tmp.$$" \
  && mv "$FILE.tmp.$$" "$FILE"

# Claude Code already raises a native banner for Notification (inputNeededNotifEnabled), so the hook
# adds one only for Stop, the job-done signal.
if [ "$event" = Stop ]; then
  osascript -e "display notification \"Done in $(basename "${cwd:-?}" | tr -d '"\\')\" with title \"Claude Code\"" &
fi

sketchybar --trigger claude_update &
exit 0
