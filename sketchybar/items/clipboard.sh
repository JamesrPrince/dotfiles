#!/bin/bash
# Clipboard history: click for the last 10 things you copied (text only),
# click one to copy it again. Password-manager copies are never kept.
clipboard=(
  icon=$COPY
  icon.font="$FONT:Regular:14.0"
  icon.color=$GREY
  label.drawing=off
  padding_left=6
  padding_right=6
  update_freq=2
  updates=on
  popup.align=right
  script="$PLUGIN_DIR/clipboard.sh"
  click_script="NAME=clipboard SENDER=click $PLUGIN_DIR/clipboard.sh"
)
sketchybar --add item clipboard right \
           --set clipboard "${clipboard[@]}" \
           --subscribe clipboard mouse.entered mouse.exited mouse.exited.global
