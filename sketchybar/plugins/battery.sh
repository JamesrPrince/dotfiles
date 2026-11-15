#!/bin/bash

export PATH="/usr/local/bin:$PATH"
# Battery is always shown with its percentage. Green while charging,
# white from 40%, orange from 20-39%, red below 20%.

source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/colors.sh"

BATT=$(pmset -g batt)
PERCENTAGE=$(echo "$BATT" | grep -Eo "\d+%" | cut -d% -f1)
CHARGING=$(echo "$BATT" | grep 'AC Power')

# Flat style test switch (plugins/smart_demo.sh on battery): pretend 22% and not charging
BAR_STYLE=; [ -r "$HOME/.config/sketchybar/.barstyle" ] && read -r BAR_STYLE < "$HOME/.config/sketchybar/.barstyle"
if [ "$BAR_STYLE" = flat ]; then
  source "$HOME/.config/sketchybar/plugins/smart_lib.sh"
  smart_demo battery && { PERCENTAGE=22; CHARGING=""; }
fi
[ -z "$PERCENTAGE" ] && exit 0

if [ "$BAR_STYLE" = flat ]; then
  # Neutral by default. Colour and the percentage label appear only when the charge needs James
  # (FLAT_BATT_WARN / FLAT_BATT_CRIT in flat_config.sh) or while it charges.
  flat_colors
  case ${PERCENTAGE} in
    9[0-9]|100) ICON=$BATTERY_100 ;;
    [6-8][0-9]) ICON=$BATTERY_75 ;;
    [4-5][0-9]) ICON=$BATTERY_50 ;;
    [2-3][0-9]) ICON=$BATTERY_25 ;;
    1[0-9])     ICON=$BATTERY_25 ;;
    *)          ICON=$BATTERY_0 ;;
  esac
  COLOR=$FLAT_REST; LABEL=""
  [ "$PERCENTAGE" -lt "$FLAT_BATT_WARN" ] && { COLOR=$FLAT_WARN; LABEL="${PERCENTAGE}%"; }
  [ "$PERCENTAGE" -lt "$FLAT_BATT_CRIT" ] && COLOR=$FLAT_CRIT
  [ -n "$CHARGING" ] && { ICON=$BATTERY_CHARGING; COLOR=$FLAT_GOOD; }
  sketchybar --animate tanh 15 --set $NAME drawing=on icon="$ICON" icon.color=$COLOR
  smart_label_only $NAME "$LABEL" $COLOR
  exit 0
fi

COLOR=$WHITE
case ${PERCENTAGE} in
  9[0-9]|100) ICON=$BATTERY_100 ;;
  [6-8][0-9]) ICON=$BATTERY_75 ;;
  [4-5][0-9]) ICON=$BATTERY_50 ;;
  [2-3][0-9]) ICON=$BATTERY_25; COLOR=$ORANGE ;;
  1[0-9])     ICON=$BATTERY_25; COLOR=$RED ;;
  *)          ICON=$BATTERY_0;  COLOR=$RED ;;
esac

if [[ $CHARGING != "" ]]; then
  ICON=$BATTERY_CHARGING
  COLOR=$GREEN
fi

sketchybar --animate tanh 15 --set $NAME drawing=on icon="$ICON" icon.color=$COLOR \
           label="${PERCENTAGE}%"
