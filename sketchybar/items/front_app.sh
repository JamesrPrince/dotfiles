#!/bin/bash

front_app=(
  script="$PLUGIN_DIR/front_app.sh"
  icon.font="sketchybar-app-font:Regular:16.0"
  icon.color=$ORANGE
  icon.padding_right=6
  padding_left=0
  label.color=$WHITE
  label.font="$TEXT_FONT:Black:12.0"
  label.max_chars=16
  padding_right=2
  associated_display=active
)

sketchybar --add item front_app left         \
           --set front_app "${front_app[@]}" \
           --subscribe front_app front_app_switched
