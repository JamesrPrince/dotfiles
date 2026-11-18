#!/bin/bash

export PATH="/usr/local/bin:$PATH"
# Flat style: the focused window's app icon and title, right of the workspaces. Ghostty has no
# title bar in this look, so this is where a window says what it is doing.
# Runs on every AeroSpace focus / workspace change and every front-app switch (events), so a new
# window shows at once. It also runs every 5 s, for the one case with no event: a window retitling
# itself (a terminal's cwd, a browser tab) without focus moving; macOS announces that only through
# the Accessibility API, which a script started by the bar has no permission for. The bar is only
# told when the text changed.

[ -f "${TMPDIR:-/tmp}/sketchybar_zen" ] && exit 0
NAME="${NAME:-window_title}"
CACHE="${TMPDIR:-/tmp}/sketchybar_window_title"

now="$(aerospace list-windows --focused --format '%{app-name}|%{window-title}' 2>/dev/null | head -1)"
# Test switch (plugins/smart_demo.sh on title): a 70-character title, the longest the bar allows
[ -e "${TMPDIR:-/tmp}/sketchybar_smart/demo.title" ] && now="Ghostty|0123456789 The quick brown fox jumps over the lazy dog, then keeps going, to 70"
# "forced" is the bar loading (the item is empty then, whatever the cache says)
if [ "$SENDER" != forced ] && [ "$now" = "$(cat "$CACHE" 2>/dev/null)" ]; then exit 0; fi
printf '%s' "$now" > "$CACHE"

if [ -z "$now" ]; then   # an empty workspace: nothing is focused
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

app="${now%%|*}"
title="${now#*|}"
[ -n "$title" ] || title="$app"
source "$HOME/.config/sketchybar/plugins/icon_map.sh"
__icon_map "$app"
sketchybar --set "$NAME" drawing=on icon="$icon_result" label="$title"
