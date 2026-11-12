#!/bin/bash
# Weather from wttr.in (no key; location from your IP). Click for the popup: now (feels-like,
# humidity, wind, UV, air quality), sunrise and sunset, the next hours and the next 3 days.
weather=(
  icon.font="$FONT:Regular:14.0"
  label.font="$TEXT_FONT:SemiBold:13.0"
  padding_left=6
  padding_right=6
  update_freq=900
  updates=on
  popup.align=left
  script="$PLUGIN_DIR/weather.sh"
)
sketchybar --add item weather left --set weather "${weather[@]}" \
           --subscribe weather mouse.clicked mouse.exited.global system_woke
