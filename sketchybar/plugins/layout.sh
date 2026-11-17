#!/bin/bash
# AeroSpace layout pill. Left click: tiles <-> accordion. Right click: horizontal <-> vertical.
# Also hides the bar while the focused window is AeroSpace full screen (one
# AeroSpace call answers both, so there is no separate full-screen item).

export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/plugins/hover.sh"
source "$HOME/.config/sketchybar/plugins/style.sh"

if [ "$SENDER" = "mouse.clicked" ]; then
  if [ "$BUTTON" = "right" ]; then aerospace layout horizontal vertical
  else aerospace layout tiles accordion; fi
fi

IFS='|' read -r L FS WS <<< "$(aerospace list-windows --focused \
  --format '%{window-parent-container-layout}|%{window-is-fullscreen}|%{workspace}' 2>/dev/null)"

# A workspace in floating mode (layout-cycle.sh) shows FLOATING even when empty or when
# the focused window is one the user tiled by hand
STATE="${AEROSPACE_LAYOUT_STATE:-$HOME/.local/state/aerospace-layouts}"
[ -n "$WS" ] || WS=$(aerospace list-workspaces --focused 2>/dev/null)
[ -n "$WS" ] && [ "$(cat "$STATE/$WS.mode" 2>/dev/null)" = floating ] && L=floating

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
# The flat bar has no layout pill
SHOW=on
[ "$BAR_STYLE" = flat ] && SHOW=off
sketchybar --bar hidden=$HIDDEN --set "$NAME" drawing=$SHOW label="$LABEL"
