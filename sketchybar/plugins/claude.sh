#!/bin/bash
# The "claude" item. State files (one per session) are written by claude/hooks/session-state.sh:
# status, folder, full cwd, claude PID, epoch. Runs on claude_update, every 30 s as a fallback and on wake.
# It prunes files whose PID is gone, then shows the count in the colour of the most urgent state.
#   claude.sh click           toggle the popup of sessions
#   claude.sh focus <folder>  focus that Ghostty window (the popup rows call this)
# The popup also carries a local usage block (today and this 5-hour window: tokens, messages, sessions, top
# model) from plugins/claude_usage.py. LOCAL data only: no Keychain, no token, no network. The plan-limit
# bars are not built; the "Limits" row says so (the hook is plan_limits() in claude_usage.py).

export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/plugins/hover.sh"
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/plugins/style.sh"
NAME=${NAME:-claude}
PLUGIN_DIR="$HOME/.config/sketchybar/plugins"   # not exported by sketchybar to plugins
[ "$SENDER" = mouse.clicked ] && set -- click   # the item subscribes to mouse.clicked (no click_script)
DIR="${TMPDIR:-/tmp}/claude_sessions"

if [ "$SENDER" = "mouse.exited.global" ]; then sketchybar --set claude popup.drawing=off; exit 0; fi

if [ "$1" = focus ]; then   # focus <window id|-> <folder>: the session's own window, else a title match
  sketchybar --set claude popup.drawing=off
  if [ "$2" != - ] && aerospace focus --window-id "$2" 2>/dev/null; then exit 0; fi
  set -- focus "$3"
  id=$(aerospace list-windows --all --format '%{window-id}|%{app-name}|%{window-title}' 2>/dev/null \
       | awk -F'|' -v f="$2" '$2 ~ /Ghostty/ && index($3, f) { print $1; exit }')
  if [ -n "$id" ]; then aerospace focus --window-id "$id"; else open -a Ghostty; fi
  exit 0
fi

# Prune dead sessions, then read the live ones
now=$(date +%s)
rows=(); worst=none; n=0
for f in "$DIR"/*; do
  [ -f "$f" ] || continue
  case $f in *.tmp.*) continue ;; esac
  { read -r st; read -r folder; read -r cwd; read -r pid; read -r ts; read -r wid; read -r prompt; read -r ctx; read -r model; read -r reason; } < "$f"
  if ! kill -0 "$pid" 2>/dev/null; then rm -f "$f"; continue; fi
  n=$((n + 1))
  rows+=("$st|$folder|$(( now - ${ts:-$now} ))|${wid:--}|$prompt|$ctx|$model|$reason")
  case $st in
    waiting) worst=waiting ;;
    done)    [ "$worst" = waiting ] || worst=done ;;
    working) case $worst in waiting|done) ;; *) worst=working ;; esac ;;
    *)       [ "$worst" = none ] && worst=idle ;;
  esac
done

case $worst in
  waiting) col=$YELLOW ;;
  done)    col=$GREEN ;;
  working) col=$BLUE ;;
  *)       col=$GREY ;;
esac
FLAT=0; [ "$BAR_STYLE" = flat ] && FLAT=1
if [ "$FLAT" = 1 ]; then source "$HOME/.config/sketchybar/plugins/smart_lib.sh"; fi

if [ "$FLAT" = 1 ] && smart_demo claude && [ "$n" -eq 0 ]; then n=2; worst=waiting; col=$YELLOW; rows=("waiting|dotfiles|12" "working|ICOR|340"); fi

if [ "$n" -eq 0 ]; then
  sketchybar --set claude popup.drawing=off
  if [ "$FLAT" = 1 ]; then smart_hide claude; else sketchybar --set claude drawing=off; fi
  exit 0
fi

if [ "$FLAT" = 1 ]; then
  SM_ICON=$''; SM_LABEL="$n"; SM_IC=$col; SM_LC=$col; SM_IW=16
  smart_show claude
else
  sketchybar --set claude drawing=on icon.color=$col label="$n" label.color=$col
fi

# Popup rows: rebuilt on click and while the popup is open (so ages stay fresh)
POP=$(sketchybar --query claude | jq -r '.popup.drawing')
if [ "$1" = click ] || [ "$POP" = on ]; then
  RR=7; [ "$FLAT" = 1 ] && RR=4
  args=(--remove '/claude\.row\..*/' --remove '/claude\.use\..*/')
  i=0
  for r in "${rows[@]}"; do
    IFS='|' read -r st folder age wid prompt ctx model reason <<< "$r"
    i=$((i + 1))
    if [ "$age" -lt 60 ]; then a="${age}s"; elif [ "$age" -lt 3600 ]; then a="$((age / 60))m"; else a="$((age / 3600))h"; fi
    # folder · last prompt · status (or what it waits on) · context · model · age
    lbl="$folder"; [ -n "$prompt" ] && lbl="$lbl · $prompt"
    if [ "$st" = waiting ] && [ -n "$reason" ]; then lbl="$lbl  —  waiting: $reason"; else lbl="$lbl  —  $st"; fi
    [ -n "$ctx" ] && lbl="$lbl · $(( (ctx + 500) / 1000 ))K"
    [ -n "$model" ] && lbl="$lbl · $model"
    lbl="$lbl · $a ago"
    case $st in waiting) c=$YELLOW ;; done) c=$GREEN ;; working) c=$BLUE ;; *) c=$GREY ;; esac
    args+=(--add item claude.row.$i popup.claude
           --set claude.row.$i icon=$'' icon.font="Maple Mono NF:Bold:14.0" icon.width=26 icon.color=$c
                               label="$lbl" label.font="$TEXT_FONT:SemiBold:13.0"
                               padding_left=8 padding_right=12 background.corner_radius=$RR
                               script="$PLUGIN_DIR/hover.sh"
                               click_script="$PLUGIN_DIR/claude.sh focus '${wid:--}' '$folder'"
           --subscribe claude.row.$i mouse.entered mouse.exited)
  done
  # Usage block: cached record (never scans here); a stale or missing cache is refreshed in the background,
  # which fires claude_update when done so this block redraws.
  USAGE="$PLUGIN_DIR/claude_usage.py"
  /usr/bin/python3 "$USAGE" --refresh-bg >/dev/null 2>&1
  UJ=$(/usr/bin/python3 "$USAGE" --cached 2>/dev/null)
  ui=0
  use_row() { # use_row <key> <value> [value colour]
    ui=$((ui + 1))
    args+=(--add item claude.use.$ui popup.claude
           --set claude.use.$ui icon="$1" icon.font="$TEXT_FONT:Bold:12.0" icon.width=92 icon.color=$GREY
                               label="$2" label.font="$TEXT_FONT:SemiBold:12.0" label.color=${3:-$WHITE}
                               padding_left=8 padding_right=12 background.drawing=off)
  }
  use_row "CLAUDE USAGE" "local data" $GREY
  if [ -z "$UJ" ]; then
    use_row "Usage" "reading local transcripts…" $GREY
  else
    while IFS='|' read -r key val; do use_row "$key" "$val"; done < <(jq -r '
      def n: if . >= 1e9 then "\((. / 1e8 | round) / 10)B" elif . >= 1e6 then "\((. / 1e5 | round) / 10)M"
             elif . >= 1e3 then "\((. / 1e2 | round) / 10)K" else "\(.)" end;
      def m: sub("^claude-"; "");
      def toks: "in \(.input | n) · out \(.output | n) · cache \(.cacheRead + .cacheCreate | n)";
      def cnt: "\(.messages) msgs · \(.sessions) sessions" + (if .topModel != "" then " · \(.topModel | m)" else "" end);
      "Today|\(.today | toks)",
      "|\(.today | cnt)\(if .today.prompts > 0 then " · \(.today.prompts) prompts" else "" end)",
      (if .window.active then
         "5h window|\(.window | toks)",
         "|\(.window | cnt) · resets \(.window.resetsAt[11:16])"
       else "5h window|no active window" end)' <<< "$UJ")
  fi
  use_row "Limits" "not connected" $GREY
  sketchybar "${args[@]}" >/dev/null 2>&1
  [ "$1" = click ] && "$HOME/.config/sketchybar/plugins/popup.sh" claude toggle
fi
exit 0
