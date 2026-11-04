#!/bin/bash
# Makes output device number $1 (as listed by "helper/audio list") the default, then closes the list.
export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/colors.sh"
AUDIO="$HOME/.config/sketchybar/helper/audio"
DEVICE="$("$AUDIO" list | sed -n "$(( $1 + 1 ))p")"
[ -n "$DEVICE" ] && "$AUDIO" set "$DEVICE"
sketchybar --set '/volume\.device\..*/' label.color=$GREY icon.color=$GREY \
           --set volume.device.$1 label.color=$WHITE icon.color=$WHITE \
           --set volume_icon popup.drawing=off
