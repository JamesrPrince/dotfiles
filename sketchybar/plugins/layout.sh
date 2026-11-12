#!/bin/bash
# AeroSpace layout pill. Left click: tiles <-> accordion. Right click: horizontal <-> vertical.
# Also hides the bar while the focused window is AeroSpace full screen (one
# AeroSpace call answers both, so there is no separate full-screen item).

export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/plugins/hover.sh"

if [ "$SENDER" = "mouse.clicked" ]; then
  if [ "$BUTTON" = "right" ]; then aerospace layout horizontal vertical
  else aerospace layout tiles accordion; fi
fi

IFS='|' read -r L FS <<< "$(aerospace list-windows --focused \
  --format '%{window-parent-container-layout}|%{window-is-fullscreen}' 2>/dev/null)"

HIDDEN=off
[ "$FS" = "true" ] && HIDDEN=on

# Zen mode hides the pill
[ -f "${TMPDIR:-/tmp}/sketchybar_zen" ] && L=zen

case "$L" in
  h_tiles)     LABEL="↔ TILES" ;;
  v_tiles)     LABEL="↕ TILES" ;;
  h_accordion) LABEL="↔ ACCORDION" ;;
  v_accordion) LABEL="↕ ACCORDION" ;;
  floating)    LABEL="FLOATING" ;;
  *)           sketchybar --bar hidden=$HIDDEN --set "$NAME" drawing=off; exit 0 ;;
esac
sketchybar --bar hidden=$HIDDEN --set "$NAME" drawing=on label="$LABEL"
