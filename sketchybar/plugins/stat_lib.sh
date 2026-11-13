#!/bin/bash
# Shared bits of the stats popups (stat_net.sh, stat_cpu.sh, stat_mem.sh).
export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

FONT="SF Pro"          # glyph icons (SF Symbols)
source "$HOME/.config/sketchybar/plugins/style.sh"   # TEXT_FONT: Nunito, or Maple Mono NF in the flat style
APP_FONT="sketchybar-app-font:Regular:15.0"
CACHE="$HOME/.cache"
mkdir -p "$CACHE"

# popup_open <anchor>: succeeds while that item's popup is showing
popup_open() { [ "$(sketchybar --query "$1" 2>/dev/null | jq -r '.popup.drawing')" = "on" ]; }

# nap <seconds> <anchor>: sleeps in 1 s steps and stops early once the popup closes
nap() { local i; for ((i = 0; i < $1; i++)); do popup_open "$2" || return 1; sleep 1; done; }

# human_rate <bytes/s>, human_bytes <bytes>
human_rate() {
  awk -v b="$1" 'BEGIN{ if (b>=1048576) printf "%.1f MB/s", b/1048576;
                        else if (b>=1024) printf "%.0f KB/s", b/1024; else printf "%d B/s", b }'
}
human_bytes() {
  awk -v b="$1" 'BEGIN{ if (b>=1073741824) printf "%.1f GB", b/1073741824;
                        else if (b>=1048576) printf "%.0f MB", b/1048576;
                        else if (b>=1024) printf "%.0f KB", b/1024; else printf "%d B", b }'
}

# single_instance <name>: exits if another loop of that name is alive, else claims the pidfile
single_instance() {
  local pidfile="${TMPDIR:-/tmp}/sketchybar_stat_$1.pid" old
  old=$(cat "$pidfile" 2>/dev/null)
  if [ -n "$old" ] && kill -0 "$old" 2>/dev/null; then exit 0; fi
  echo $$ > "$pidfile"
}

# app_icon <name>: the sketchybar-app-font glyph for an app, into $icon_result
app_icon() { __icon_map "$1"; }
