#!/bin/bash
# Claude Code hook: records each session's state for the SketchyBar "claude" item
# (sketchybar/items/claude.sh). Registered in ~/.claude/settings.json for SessionStart,
# UserPromptSubmit, Notification, Stop and SessionEnd. Reads the hook JSON on stdin.
#   SessionStart -> idle   UserPromptSubmit -> working   Notification -> waiting
#   Stop -> done           SessionEnd -> state file removed
# One file per session in ${TMPDIR:-/tmp}/claude_sessions/, five lines:
#   status, folder name, full cwd, PID of the claude process, epoch time.
# Always exits 0 and prints nothing on stdout, so it can never block or pollute a session.
# CLAUDE_HEADLESS=1 skips everything: set it on `claude -p` runs (no launchd job uses one
# today) so they never show up in the bar.

exec >/dev/null 2>&1
[ "$CLAUDE_HEADLESS" = 1 ] && exit 0
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"

input=$(cat)
IFS=$'\t' read -r sid cwd event < <(printf '%s' "$input" | jq -r '[.session_id // "", .cwd // "", .hook_event_name // ""] | @tsv')
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

printf '%s\n%s\n%s\n%s\n%s\n' "$status" "$(basename "${cwd:-?}")" "$cwd" "$pid" "$(date +%s)" > "$FILE.tmp.$$" \
  && mv "$FILE.tmp.$$" "$FILE"

# Claude Code already raises a native banner for Notification (inputNeededNotifEnabled), so the hook
# adds one only for Stop, the job-done signal.
if [ "$event" = Stop ]; then
  osascript -e "display notification \"Done in $(basename "${cwd:-?}" | tr -d '"\\')\" with title \"Claude Code\"" &
fi

sketchybar --trigger claude_update &
exit 0
