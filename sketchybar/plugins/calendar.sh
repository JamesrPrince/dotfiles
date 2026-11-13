#!/bin/bash

export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/plugins/hover.sh"

if [ "$SENDER" = "mouse.exited.global" ]; then
  sketchybar --set $NAME popup.drawing=off
  exit 0
fi

source "$HOME/.config/sketchybar/plugins/style.sh"

if [ "$BAR_STYLE" = flat ]; then   # weekday and time, as Waybar shows it
  sketchybar --set $NAME label="$(date '+%A %H:%M')"
  exit 0
fi

sketchybar --set $NAME icon="$(date '+%a %d. %b')" label="$(date '+%H:%M')"
