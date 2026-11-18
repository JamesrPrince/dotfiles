#!/bin/bash

export PATH="/usr/local/bin:$PATH"
# Flat style: the focused window's app icon and title, right of the workspaces. Ghostty has no
# title bar in this look, so this is where a window says what it is doing.
# Runs on every AeroSpace focus / workspace change and every front-app switch (events), so a new
# window shows at once. It also runs every 5 s, for the one case with no event: a window retitling
# itself (a terminal's cwd, a browser tab) without focus moving; macOS announces that only through
# the Accessibility API, which a script started by the bar has no permission for. The bar is only
# told when the text changed.
# Width: the title gets the room between its own left edge and the clock block, worked out in pixels
# from the display's width (flat_config.sh: flat_title_px) and clipped there (label.width is a hard
# clip, so wide glyphs cannot reach the clock). It is worked out again half a second after an event,
# once the workspaces have finished resizing, and on display changes.

[ -f "${TMPDIR:-/tmp}/sketchybar_zen" ] && exit 0
NAME="${NAME:-window_title}"
CACHE="${TMPDIR:-/tmp}/sketchybar_window_title"

now="$(aerospace list-windows --focused --format '%{app-name}|%{window-title}' 2>/dev/null | head -1)"
# Test switch (plugins/smart_demo.sh on title): a 70-character title, longer than the bar allows (the label caps at 56)
[ -e "${TMPDIR:-/tmp}/sketchybar_smart/demo.title" ] && now="Ghostty|0123456789 The quick brown fox jumps over the lazy dog, then keeps going, to 70"
source "$HOME/.config/sketchybar/plugins/flat_config.sh"
px=$(flat_title_px)
# "forced" is the bar loading (the item is empty then, whatever the cache says)
if [ "$SENDER" != forced ] && [ "$now|$px" = "$(cat "$CACHE" 2>/dev/null)" ]; then exit 0; fi
printf '%s' "$now|$px" > "$CACHE"

if [ -z "$now" ]; then   # an empty workspace: nothing is focused
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

app="${now%%|*}"
title="${now#*|}"
[ -n "$title" ] || title="$app"
source "$HOME/.config/sketchybar/plugins/icon_map.sh"
__icon_map "$app"
draw() {   # draw <px>: the title clipped to px (icon only when there is no room)
  local px=$1 cols w
  if [ "$px" -lt 14 ]; then sketchybar --set "$NAME" drawing=on icon="$icon_result" label="" label.width=0 label.padding_left=0 label.padding_right=0; return; fi
  cols=$(flat_cols "$title"); w=$(( (cols * 72 + 9) / 10 + 2 ))
  [ "$w" -gt "$px" ] && w=$px
  sketchybar --set "$NAME" drawing=on icon="$icon_result" label="$title" label.max_chars=$(( px * 10 / 72 )) label.width=$w label.padding_left=0 label.padding_right=0
}
draw "$px"
# Workspaces resize a moment after the event that moved the title: look again, and correct if they did
if [ "$SENDER" != routine ]; then
  sleep 0.5
  px2=$(flat_title_px)
  if [ "$px2" != "$px" ]; then printf '%s' "$now|$px2" > "$CACHE"; draw "$px2"; fi
fi
