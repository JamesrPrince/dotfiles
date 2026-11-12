#!/bin/bash
# AeroSpace mode pill: hidden in main mode, a coloured label in service or resize mode.

sketchybar --add event aerospace_mode_change

mode=(
  drawing=off
  updates=on
  icon.drawing=off
  label.font="$TEXT_FONT:Black:12.0"
  label.color=$BLACK
  label.padding_left=10
  label.padding_right=10
  background.height=24
  background.corner_radius=8
  background.drawing=on
  padding_left=0
  padding_right=10
  script="$PLUGIN_DIR/mode.sh"
  click_script="/usr/local/bin/aerospace mode main; /usr/local/bin/sketchybar --trigger aerospace_mode_change MODE=main"
)

sketchybar --add item mode left \
           --set mode "${mode[@]}" \
           --subscribe mode aerospace_mode_change
