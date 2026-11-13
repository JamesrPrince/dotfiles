#!/bin/bash
# Key-binding cheat sheet. plugins/keys.py fills two popups from ~/.aerospace.toml:
#   keys       the pages of bindings (scroll the wheel over it to turn the page)
#   keys.tabs  a strip above it: Switch / Rearrange / Layout / Apps / Modes tabs
#              and the "page/pages" indicator
# Both items are empty and zero-width, just left of the "more" item, and only anchor
# the popups. Open the sheet with alt-shift-/ or from the "Shortcuts" row in "more".

keys_tabs=(
  width=0
  padding_left=0
  padding_right=0
  icon.drawing=off
  label.drawing=off
  popup.align=right
  popup.horizontal=on
  popup.height=26
)

keys=(
  width=0
  padding_left=0
  padding_right=0
  icon.drawing=off
  label.drawing=off
  popup.align=right
  popup.height=24
)

sketchybar --add item keys.tabs right    \
           --set keys.tabs "${keys_tabs[@]}" \
           --add item keys right         \
           --set keys "${keys[@]}"

# keys.py (about a second of Python start-up and `aerospace`/`launch.sh` reads) fills the popups
# through the bar, so it runs once sketchybarrc has sent the batch, in the background, instead of
# holding up the load: the sheet is ready a moment after the bar is.
AFTER_LOAD+=("/usr/bin/python3 $PLUGIN_DIR/keys.py")
