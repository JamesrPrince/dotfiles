#!/bin/bash

calendar=(
  icon=cal
  icon.font="$TEXT_FONT:Black:12.0"
  icon.padding_right=0
  label.font="$TEXT_FONT:Bold:12.0"
  label.width=45
  label.align=right
  padding_left=15
  update_freq=30
  script="$PLUGIN_DIR/calendar.sh"
  popup.align=right
  click_script="$PLUGIN_DIR/calendar_click.sh"
)

sketchybar --add item calendar right       \
           --set calendar "${calendar[@]}" \
           --subscribe calendar system_woke mouse.exited.global
