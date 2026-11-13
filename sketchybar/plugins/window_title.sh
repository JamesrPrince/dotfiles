#!/bin/bash

export PATH="/usr/local/bin:$PATH"
# Flat style: the focused window's app icon and title, right of the workspaces. Ghostty has no
# title bar in this look, so this is where a window says what it is doing.
# Runs on focus and workspace changes, and every few seconds, because a terminal retitles itself
# without any event. The bar is only told when the text changed.

[ -f "${TMPDIR:-/tmp}/sketchybar_zen" ] && exit 0
NAME="${NAME:-window_title}"
CACHE="${TMPDIR:-/tmp}/sketchybar_window_title"

now="$(aerospace list-windows --focused --format '%{app-name}|%{window-title}' 2>/dev/null | head -1)"
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
