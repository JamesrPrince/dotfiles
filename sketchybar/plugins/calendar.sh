#!/bin/bash

export PATH="/usr/local/bin:$PATH"

if [ "$SENDER" = "mouse.exited.global" ]; then
  sketchybar --set $NAME popup.drawing=off
  exit 0
fi

sketchybar --set $NAME icon="$(date '+%a %d. %b')" label="$(date '+%H:%M')"
