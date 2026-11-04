#!/bin/bash
# AeroSpace layout pill. Left click: tiles <-> accordion. Right click: horizontal <-> vertical.

export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/plugins/hover.sh"

if [ "$SENDER" = "mouse.clicked" ]; then
  if [ "$BUTTON" = "right" ]; then aerospace layout horizontal vertical
  else aerospace layout tiles accordion; fi
fi

# Zen mode hides the pill
[ -f "${TMPDIR:-/tmp}/sketchybar_zen" ] && { sketchybar --set "$NAME" drawing=off; exit 0; }

L=$(aerospace list-windows --focused --format '%{window-parent-container-layout}' 2>/dev/null)
case "$L" in
  h_tiles)     LABEL="↔ TILES" ;;
  v_tiles)     LABEL="↕ TILES" ;;
  h_accordion) LABEL="↔ ACCORDION" ;;
  v_accordion) LABEL="↕ ACCORDION" ;;
  floating)    LABEL="FLOATING" ;;
  *)           sketchybar --set "$NAME" drawing=off; exit 0 ;;
esac
sketchybar --set "$NAME" drawing=on label="$LABEL"
