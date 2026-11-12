#!/bin/bash
# Mic and camera indicator: appears only while something is using them
# (orange mic, green camera). Checks every 5s without opening either device.

privacy=(
  drawing=off
  updates=on
  update_freq=5
  icon=$MIC
  icon.color=$ORANGE
  icon.font="$FONT:Regular:14.0"
  label=$CAMERA
  label.color=$GREEN
  label.font="$TEXT_FONT:Regular:14.0"
  padding_left=6
  padding_right=6
  script="$PLUGIN_DIR/privacy.sh"
)

sketchybar --add item privacy right        \
           --set privacy "${privacy[@]}"   \
           --subscribe privacy system_woke
