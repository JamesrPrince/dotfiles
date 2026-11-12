#!/bin/bash
# Focus timer: click for 25 minutes, right-click for 50, click again to stop.
# Plays a sound and posts a notification when time is up.
timer=(
  icon=":clock:"
  icon.font="sketchybar-app-font:Regular:15.0"
  icon.color=$GREY
  label.drawing=off
  label.font="$TEXT_FONT:Bold:12.0"
  label.color=$YELLOW
  padding_left=6
  padding_right=6
  updates=on
  script="$PLUGIN_DIR/timer.sh"
)
sketchybar --add item timer right --set timer "${timer[@]}" --subscribe timer mouse.clicked system_woke
