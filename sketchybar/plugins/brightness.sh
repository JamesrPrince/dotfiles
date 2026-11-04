#!/bin/bash
# Brightness slider in the control centre: dragging or clicking sets the built-in display.
export PATH="/usr/local/bin:$PATH"
[ "$SENDER" = "mouse.clicked" ] || exit 0
"$HOME/.config/sketchybar/helper/brightness" "$PERCENTAGE" >/dev/null
