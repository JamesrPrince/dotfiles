#!/bin/bash
# Hover highlight. Plugins source this first; it handles mouse.entered and
# mouse.exited and stops the plugin there. Items with no plugin of their own
# use it as their script. The focused workspace keeps its accent pill.

case "$SENDER" in
  mouse.entered|mouse.exited) ;;
  *) return 0 2>/dev/null || exit 0 ;;
esac

export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/colors.sh"

if [[ $NAME == space.* ]] && \
   [ "$(sketchybar --query "$NAME" | jq -r '.icon.highlight')" = "on" ]; then
  exit 0
fi

if [ "$SENDER" = "mouse.entered" ]; then
  sketchybar --animate tanh 8 --set "$NAME" background.drawing=on \
             background.color=$HOVER_COLOR background.height=24 background.corner_radius=7
else
  sketchybar --animate tanh 8 --set "$NAME" background.color=$TRANSPARENT
fi
exit 0
