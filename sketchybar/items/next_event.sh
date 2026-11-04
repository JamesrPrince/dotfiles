#!/bin/bash
# Countdown to the next calendar event, shown only in the hour before it starts.
next_event=(
  drawing=off
  updates=on
  update_freq=30
  icon=$CLOCK
  icon.font="$FONT:Regular:13.0"
  icon.color=$BLUE
  label.font="$FONT:Semibold:12.0"
  label.max_chars=30
  padding_left=6
  padding_right=2
  script="$PLUGIN_DIR/next_event.sh"
  click_script="open -a Calendar"
)
sketchybar --add item next_event right \
           --set next_event "${next_event[@]}" \
           --subscribe next_event system_woke mouse.entered mouse.exited
