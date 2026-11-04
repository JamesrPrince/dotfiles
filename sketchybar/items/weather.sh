#!/bin/bash
# Weather from wttr.in (no key; location from your IP). Click for the next hours.
weather=(
  icon.font="$FONT:Regular:14.0"
  label.font="$FONT:Semibold:13.0"
  padding_left=6
  padding_right=6
  update_freq=900
  updates=on
  popup.align=right
  script="$PLUGIN_DIR/weather.sh"
)
sketchybar --add item weather right --set weather "${weather[@]}" \
           --subscribe weather mouse.clicked mouse.exited.global system_woke
