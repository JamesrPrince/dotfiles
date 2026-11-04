#!/bin/bash
# Key-binding cheat sheet; plugins/keys.py fills the popup from ~/.aerospace.toml

keys=(
  icon=$KEYBOARD
  icon.font="$FONT:Bold:15.0"
  icon.color=$BLUE
  label.drawing=off
  padding_left=10
  popup.align=right
  click_script="/usr/bin/python3 $PLUGIN_DIR/keys.py toggle"
  script="$PLUGIN_DIR/popup.sh keys off"
)

sketchybar --add item keys right    \
           --set keys "${keys[@]}" \
           --subscribe keys mouse.exited.global

/usr/bin/python3 "$PLUGIN_DIR/keys.py"
