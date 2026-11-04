#!/bin/bash
# Disk warning: appears in red only when the startup disk has under 20 GB free.
disk=(
  drawing=off
  updates=on
  update_freq=300
  icon=$DISK
  icon.color=$RED
  icon.font="$FONT:Regular:15.0"
  label.font="$FONT:Semibold:12.0"
  label.color=$RED
  padding_left=6
  padding_right=6
  script="$PLUGIN_DIR/disk.sh"
  click_script="open -b com.apple.settings.Storage 2>/dev/null || open 'x-apple.systempreferences:com.apple.settings.Storage'"
)
sketchybar --add item disk right --set disk "${disk[@]}" --subscribe disk system_woke
