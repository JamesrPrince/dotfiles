#!/bin/bash
# AeroSpace layout pill: the window management in force on the focused workspace.
#   ↔ / ↕ TILES, ↔ / ↕ ACCORDION   the container of the focused window (the workspace root when empty)
#   FLOATING                        the workspace is in floating mode (layout-cycle.sh, alt-slash)
#   ... · FLOAT                     the workspace tiles, but the focused window floats (alt-t)
# Left click: tiles <-> accordion. Right click: horizontal <-> vertical.
# Flat style: coloured text (tiles neutral, accordion blue, floating warn); Centre Stage: grey in its pill.
# Also hides the bar while the focused window is AeroSpace full screen (one
# AeroSpace call answers both, so there is no separate full-screen item).

export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/plugins/hover.sh"
source "$HOME/.config/sketchybar/plugins/style.sh"

if [ "$SENDER" = "mouse.clicked" ]; then
  if [ "$BUTTON" = "right" ]; then aerospace layout horizontal vertical
  else aerospace layout tiles accordion; fi
fi

IFS='|' read -r WL L FS WS <<< "$(aerospace list-windows --focused \
  --format '%{window-layout}|%{window-parent-container-layout}|%{window-is-fullscreen}|%{workspace}' 2>/dev/null)"

[ -n "$WS" ] || WS=$(aerospace list-workspaces --focused 2>/dev/null)
# No focused window (an empty workspace) or a floating one: show what the workspace itself does
WINFLOAT=""
if [ -z "$WL" ] || [ "$WL" = floating ]; then
  [ "$WL" = floating ] && WINFLOAT=" · FLOAT"
  L=$(aerospace list-workspaces --focused --format '%{workspace-root-container-layout}' 2>/dev/null)
fi

# A workspace in floating mode (layout-cycle.sh) shows FLOATING whatever the focused window does
STATE="${AEROSPACE_LAYOUT_STATE:-$HOME/.local/state/aerospace-layouts}"
[ -n "$WS" ] && [ "$(cat "$STATE/$WS.mode" 2>/dev/null)" = floating ] && { L=floating; WINFLOAT=""; }

HIDDEN=off
[ "$FS" = "true" ] && HIDDEN=on

# Zen mode and the hidden scratchpad workspace hide the pill
[ -f "${TMPDIR:-/tmp}/sketchybar_zen" ] && L=zen
[ "$WS" = S ] && L=none

case "$L" in
  h_tiles)     LABEL="↔ TILES";     KIND=tiles ;;
  v_tiles)     LABEL="↕ TILES";     KIND=tiles ;;
  h_accordion) LABEL="↔ ACCORDION"; KIND=accordion ;;
  v_accordion) LABEL="↕ ACCORDION"; KIND=accordion ;;
  floating)    LABEL="FLOATING";    KIND=floating ;;
  *)           sketchybar --bar hidden=$HIDDEN --set "$NAME" drawing=off; exit 0 ;;
esac
LABEL="$LABEL$WINFLOAT"

if [ "$BAR_STYLE" = flat ]; then
  source "$HOME/.config/sketchybar/plugins/flat_config.sh"
  flat_colors
  case "$KIND" in
    accordion) COLOR=$BLUE ;;
    floating)  COLOR=$FLAT_WARN ;;
    *)         COLOR=$FLAT_REST ;;
  esac
  sketchybar --bar hidden=$HIDDEN --set "$NAME" drawing=on label="$LABEL" label.color=$COLOR
else
  sketchybar --bar hidden=$HIDDEN --set "$NAME" drawing=on label="$LABEL"
fi
