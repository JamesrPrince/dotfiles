#!/bin/bash
# Shows the AeroSpace mode. MODE comes from on-mode-changed in aerospace.toml.
export PATH="/usr/local/bin:$PATH"
source "$CONFIG_DIR/colors.sh"

[ -z "$MODE" ] && MODE=$(/usr/local/bin/aerospace list-modes --current 2>/dev/null)

case "$MODE" in
  service) sketchybar --set "$NAME" drawing=on label="SERVICE" background.color=$ORANGE ;;
  resize)  sketchybar --set "$NAME" drawing=on label="RESIZE"  background.color=$MAGENTA ;;
  *)       sketchybar --set "$NAME" drawing=off ;;
esac
