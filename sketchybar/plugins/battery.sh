#!/bin/bash

export PATH="/usr/local/bin:$PATH"
# Battery is always shown with its percentage. Green while charging,
# white from 40%, orange from 20-39%, red below 20%.

source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/colors.sh"

BATT=$(pmset -g batt)
PERCENTAGE=$(echo "$BATT" | grep -Eo "\d+%" | cut -d% -f1)
CHARGING=$(echo "$BATT" | grep 'AC Power')

[ -z "$PERCENTAGE" ] && exit 0

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
