#!/bin/bash
# Opens or closes an item's popup; opening slides it down into place.
# Usage: popup.sh <item> [on|off|toggle]  (default toggle)

export PATH="/usr/local/bin:$PATH"
ITEM=$1
WANT=${2:-toggle}
NOW=$(sketchybar --query "$ITEM" | jq -r '.popup.drawing')
if [ "$WANT" = toggle ]; then
  [ "$NOW" = "on" ] && WANT=off || WANT=on
fi
[ "$WANT" = "$NOW" ] && exit 0

if [ "$WANT" = on ]; then
  sketchybar --set "$ITEM" popup.y_offset=-12 popup.drawing=on \
             --animate tanh 15 --set "$ITEM" popup.y_offset=0
else
  sketchybar --set "$ITEM" popup.drawing=off
fi
