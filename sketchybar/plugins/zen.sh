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
             --set vpn drawing=off \
             --set weather drawing=off \
             --set next_event drawing=off \
             --set '/badge\..*/' drawing=off \
             --set front_app drawing=off \
             --set calendar icon.drawing=off \
             --set volume_icon drawing=off \
             --set brightness_icon drawing=off \
             --set bluetooth drawing=off \
             --set more drawing=off \
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
             --set vpn drawing=on \
             --set weather drawing=on \
             --trigger aerospace_layout_change \
             --set front_app drawing=on \
             --set calendar icon.drawing=on \
             --set volume_icon drawing=on \
             --set brightness_icon drawing=on \
             --set bluetooth drawing=on \
             --set more drawing=on \
             --set control drawing=on \
             --set wifi drawing=on \
             --set cpu.graph drawing=on \
             --set cpu.percent drawing=on \
             --set mem drawing=on \
             --set net.up drawing=on \
             --set net.down drawing=on \
             --set spotify.play updates=on \
             --trigger power_source_change
  # The next event shows only when it has something to say: let its script decide
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
