#!/bin/bash
# Shows the AeroSpace mode. MODE comes from on-mode-changed in aerospace.toml.
export PATH="/usr/local/bin:$PATH"
source "$CONFIG_DIR/colors.sh"
source "$HOME/.config/sketchybar/plugins/style.sh"

[ -z "$MODE" ] && MODE=$(/usr/local/bin/aerospace list-modes --current 2>/dev/null)

if [ "$BAR_STYLE" = flat ]; then   # coloured text, no pill
  case "$MODE" in
    service) sketchybar --set "$NAME" drawing=on label="SERVICE" label.color=$ORANGE ;;
    resize)  sketchybar --set "$NAME" drawing=on label="RESIZE"  label.color=$MAGENTA ;;
    *)       sketchybar --set "$NAME" drawing=off ;;
  esac
  exit 0
fi

case "$MODE" in
  service) sketchybar --animate tanh 12 --set "$NAME" drawing=on label="SERVICE" background.color=$ORANGE ;;
  resize)  sketchybar --animate tanh 12 --set "$NAME" drawing=on label="RESIZE"  background.color=$MAGENTA ;;
  *)       sketchybar --set "$NAME" drawing=off ;;
esac
