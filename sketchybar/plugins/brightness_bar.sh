#!/bin/bash
# Bar brightness slider (items/brightness.sh), modelled on plugins/volume.sh.
# Uses the same helper as the control centre slider: helper/brightness prints 0-100,
# "helper/brightness 60" sets it. Run with the argument "toggle" from the icon click.

export PATH="/usr/local/bin:$PATH"

HELPER="$HOME/.config/sketchybar/helper/brightness"
LAST="${TMPDIR:-/tmp}/sketchybar_brightness_last"
WIDTH=70

WATCH="$HOME/.config/sketchybar/helper/brightnesswatch"

# The brightness_change event comes from helper/brightnesswatch (DisplayServices' own change
# notification), started here once the bar has loaded. Classic style only: the flat bar has no
# brightness slider (flat_hide.sh turns the item off), so nothing runs there.
is_flat() { local s=; [ -r "$HOME/.config/sketchybar/.barstyle" ] && read -r s < "$HOME/.config/sketchybar/.barstyle"; [ "$s" = flat ]; }

watch() {
  is_flat && { pkill -x brightnesswatch 2>/dev/null; exit 0; }   # a switch to flat stops it
  [ -x "$WATCH" ] || exit 0
  nohup "$WATCH" >/dev/null 2>&1 &   # a no-op if one already runs (it holds a lock)
  exit 0
}

# Safety net, every 60s (the event does the real work): a helper call and a string compare to catch
# a change the watcher missed, and a respawn of the watcher if it died. Nothing else runs unless the
# value changed since the last look.
poll() {
  local b last
  [ -x "$WATCH" ] && ! is_flat && ! pgrep -xq brightnesswatch && { nohup "$WATCH" >/dev/null 2>&1 & }
  b=$("$HELPER" 2>/dev/null) || exit 0
  [ -n "$b" ] && [ "$b" -ge 0 ] 2>/dev/null || exit 0
  last=; [ -r "$LAST" ] && read -r last < "$LAST"   # builtin read: no cat process
  [ "$b" = "$last" ] && exit 0
  echo "$b" > "$LAST"
  # first look after a (re)load only records the value: no slide-out at startup
  [ -n "$last" ] && sketchybar --trigger brightness_change INFO="$b"
  exit 0
}

brightness_change() {
  echo "$INFO" > "$LAST"   # so the safety poll does not report the same change again
  sketchybar --set $NAME slider.percentage=$INFO \
             --animate tanh 30 --set $NAME slider.width=$WIDTH

  sleep 2

  # Check whether the brightness was changed again while sleeping
  FINAL_PERCENTAGE=$(sketchybar --query $NAME | jq -r ".slider.percentage")
  # An empty answer (the bar was busy) also collapses it, so the slider can never stay stuck open
  if [ -z "$FINAL_PERCENTAGE" ] || [ "$FINAL_PERCENTAGE" -eq "$INFO" ]; then
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
[ "$1" = "watch" ] && watch

case "$SENDER" in
  "routine"|"forced") poll ;;
  "brightness_change") brightness_change ;;
  "mouse.clicked") "$HELPER" "$PERCENTAGE" >/dev/null ;;
  "mouse.entered") sketchybar --set $NAME slider.knob.drawing=on ;;
  "mouse.exited") sketchybar --set $NAME slider.knob.drawing=off ;;
esac
