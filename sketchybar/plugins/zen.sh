#!/bin/bash

export PATH="/usr/local/bin:$PATH"
# Click the clock: hide everything but the workspaces and the time, or bring it back.
# The flag file tells the items that show themselves (privacy, badges, layout,
# disk, next event) to stay hidden.
ZEN="${TMPDIR:-/tmp}/sketchybar_zen"

zen_on() {
  touch "$ZEN"
  sketchybar --set apple.logo drawing=off \
             --set layout drawing=off \
             --set gpu drawing=off \
             --set vpn drawing=off \
             --set github drawing=off \
             --set weather drawing=off \
             --set timer drawing=off \
             --set disk drawing=off \
             --set next_event drawing=off \
             --set '/badge\..*/' drawing=off \
             --set separator drawing=off \
             --set front_app drawing=off \
             --set calendar icon.drawing=off \
             --set keys drawing=off \
             --set volume_icon drawing=off \
             --set battery drawing=off \
             --set control drawing=off \
             --set privacy drawing=off \
             --set wifi drawing=off \
             --set cpu.graph drawing=off \
             --set cpu.percent drawing=off \
             --set mem drawing=off \
             --set net.up drawing=off \
             --set net.down drawing=off \
             --set spotify.anchor drawing=off \
             --set spotify.play updates=off
}

zen_off() {
  rm -f "$ZEN"
  sketchybar --set apple.logo drawing=on \
             --set gpu drawing=on \
             --set vpn drawing=on \
             --set github drawing=on \
             --set weather drawing=on \
             --set timer drawing=on \
             --trigger aerospace_layout_change \
             --set separator drawing=on \
             --set front_app drawing=on \
             --set calendar icon.drawing=on \
             --set keys drawing=on \
             --set volume_icon drawing=on \
             --set control drawing=on \
             --set wifi drawing=on \
             --set cpu.graph drawing=on \
             --set cpu.percent drawing=on \
             --set mem drawing=on \
             --set net.up drawing=on \
             --set net.down drawing=on \
             --set spotify.play updates=on \
             --trigger power_source_change
  # Disk and next event show only when they have something to say: let their
  # scripts decide
  NAME=disk "$HOME/.config/sketchybar/plugins/disk.sh" &
  NAME=next_event "$HOME/.config/sketchybar/plugins/next_event.sh" &
}

if [ "$1" = "on" ]; then
  zen_on
elif [ "$1" = "off" ]; then
  zen_off
else
  if [ ! -f "$ZEN" ]; then
    zen_on
  else
    zen_off
  fi
fi
