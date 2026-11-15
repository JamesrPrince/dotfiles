#!/bin/bash
# Focus timer. The end time lives in a file so the countdown survives a bar reload.
# Flat style: while it runs, a clock glyph and the time left show right of the meeting item (see
# smart_lib.sh); click it to stop. It is started from the control centre's "Focus timer" row (flat) or
# the "more" popup (Centre Stage). The 1 s tick runs only while it counts down.
export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/plugins/hover.sh"
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/plugins/style.sh"
NAME=${NAME:-timer}
STATE="${TMPDIR:-/tmp}/sketchybar_timer"
FLAT=0
if [ "$BAR_STYLE" = flat ]; then
  FLAT=1
  source "$HOME/.config/sketchybar/plugins/smart_lib.sh"
  source "$HOME/.config/sketchybar/icons.sh"
fi

stop() {
  rm -f "$STATE"
  if [ "$FLAT" = 1 ]; then sketchybar --set $NAME update_freq=0; smart_hide timer
  else sketchybar --set $NAME update_freq=0 icon.color=$GREY label.drawing=off; fi
}

show() {   # show <label>
  if [ "$FLAT" = 1 ]; then
    SM_ICON=$TIMER_ICON; SM_LABEL=$1; smart_show timer
    sketchybar --set $NAME update_freq=1
  else
    sketchybar --set $NAME update_freq=1 icon.color=$YELLOW label.drawing=on label="$1"
  fi
}

if [ "$SENDER" = "mouse.clicked" ]; then
  if [ -f "$STATE" ]; then stop; exit 0; fi
  mins=25; [ "$BUTTON" = "right" ] && mins=50
  rm -f "${TMPDIR:-/tmp}/sketchybar_timer_done"
  echo $(( $(date +%s) + mins * 60 )) > "$STATE"
  [ "$FLAT" = 1 ] || sketchybar --set $NAME update_freq=1 icon.color=$YELLOW label.drawing=on
fi

if [ "$FLAT" = 1 ] && smart_demo timer && [ ! -f "$STATE" ]; then
  show "24:10"; sketchybar --set $NAME update_freq=0; exit 0
fi

if [ ! -f "$STATE" ]; then
  if [ "$FLAT" = 1 ]; then smart_hide timer; sketchybar --set $NAME update_freq=0
  else sketchybar --set $NAME update_freq=0 icon.color=$GREY label.drawing=off; fi
  exit 0
fi

left=$(( $(cat "$STATE") - $(date +%s) ))
if [ "$left" -le 0 ]; then
  stop
  touch "${TMPDIR:-/tmp}/sketchybar_timer_done"   # the "more" dot stays red until it is cleared
  afplay /System/Library/Sounds/Glass.aiff &
  osascript -e 'display notification "Time for a break." with title "Focus timer done"'
  exit 0
fi
label="$(printf '%d:%02d' $((left / 60)) $((left % 60)))"
if [ "$FLAT" = 1 ]; then show "$label"
else sketchybar --set $NAME update_freq=1 icon.color=$YELLOW label.drawing=on label="$label"; fi
