#!/bin/bash
# Focus timer. The end time lives in a file so the countdown survives a bar reload.
export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/colors.sh"
NAME=${NAME:-timer}
STATE="${TMPDIR:-/tmp}/sketchybar_timer"

stop() {
  rm -f "$STATE"
  sketchybar --set $NAME update_freq=0 icon.color=$GREY label.drawing=off
}

if [ "$SENDER" = "mouse.clicked" ]; then
  if [ -f "$STATE" ]; then stop; exit 0; fi
  mins=25; [ "$BUTTON" = "right" ] && mins=50
  echo $(( $(date +%s) + mins * 60 )) > "$STATE"
  sketchybar --set $NAME update_freq=1 icon.color=$YELLOW label.drawing=on
fi

[ -f "$STATE" ] || { sketchybar --set $NAME update_freq=0 icon.color=$GREY label.drawing=off; exit 0; }

left=$(( $(cat "$STATE") - $(date +%s) ))
if [ "$left" -le 0 ]; then
  stop
  afplay /System/Library/Sounds/Glass.aiff &
  osascript -e 'display notification "Time for a break." with title "Focus timer done"'
  exit 0
fi
sketchybar --set $NAME update_freq=1 icon.color=$YELLOW label.drawing=on \
           label="$(printf '%d:%02d' $((left / 60)) $((left % 60)))"
