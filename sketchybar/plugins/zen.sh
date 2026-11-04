#!/bin/bash

export PATH="/usr/local/bin:$PATH"
# Click the clock: hide everything but the workspaces and the time, or bring it back.

zen_on() {
  sketchybar --set apple.logo drawing=off \
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
  sketchybar --set apple.logo drawing=on \
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
}

if [ "$1" = "on" ]; then
  zen_on
elif [ "$1" = "off" ]; then
  zen_off
else
  if [ "$(sketchybar --query apple.logo | jq -r ".geometry.drawing")" = "on" ]; then
    zen_on
  else
    zen_off
  fi
fi
