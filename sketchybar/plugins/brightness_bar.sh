#!/bin/bash
# Bar brightness slider (items/brightness.sh), modelled on plugins/volume.sh.
# Uses the same helper as the control centre slider: helper/brightness prints 0-100,
# "helper/brightness 60" sets it. Run with the argument "toggle" from the icon click.

export PATH="/usr/local/bin:$PATH"

HELPER="$HOME/.config/sketchybar/helper/brightness"
LAST="${TMPDIR:-/tmp}/sketchybar_brightness_last"
WIDTH=70

# Called by the slider every 2s. One tiny helper call and a string compare; nothing
# else runs unless the value changed since the last look.
poll() {
  local b last
  b=$("$HELPER" 2>/dev/null) || exit 0
  [ -n "$b" ] && [ "$b" -ge 0 ] 2>/dev/null || exit 0
  last=$(cat "$LAST" 2>/dev/null)
  [ "$b" = "$last" ] && exit 0
  echo "$b" > "$LAST"
  # first look after a (re)load only records the value: no slide-out at startup
  [ -n "$last" ] && sketchybar --trigger brightness_change INFO="$b"
  exit 0
}

brightness_change() {
  sketchybar --set $NAME slider.percentage=$INFO \
             --animate tanh 30 --set $NAME slider.width=$WIDTH

  sleep 2

  # Check whether the brightness was changed again while sleeping
  FINAL_PERCENTAGE=$(sketchybar --query $NAME | jq -r ".slider.percentage")
  if [ "$FINAL_PERCENTAGE" -eq "$INFO" ]; then
    sketchybar --animate tanh 30 --set $NAME slider.width=0
  fi
}

toggle() {
  INITIAL_WIDTH=$(sketchybar --query brightness | jq -r ".slider.width")
  if [ "$INITIAL_WIDTH" -eq "0" ]; then
    b=$("$HELPER" 2>/dev/null)
    sketchybar --set brightness slider.percentage=${b:-50} --animate tanh 30 --set brightness slider.width=$WIDTH
  else
    sketchybar --animate tanh 30 --set brightness slider.width=0
  fi
}

[ "$1" = "toggle" ] && { toggle; exit 0; }

case "$SENDER" in
  "routine"|"forced") poll ;;
  "brightness_change") brightness_change ;;
  "mouse.clicked") "$HELPER" "$PERCENTAGE" >/dev/null ;;
  "mouse.entered") sketchybar --set $NAME slider.knob.drawing=on ;;
  "mouse.exited") sketchybar --set $NAME slider.knob.drawing=off ;;
esac
