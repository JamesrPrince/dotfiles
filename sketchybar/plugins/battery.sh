#!/bin/bash

export PATH="/usr/local/bin:$PATH"
# Battery shows only when it needs attention: below 60% and not charging.
# Orange from 20-39%, red below 20%.

source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/colors.sh"

PERCENTAGE=$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)
CHARGING=$(pmset -g batt | grep 'AC Power')

[ -z "$PERCENTAGE" ] && exit 0

DRAWING=on
COLOR=$WHITE
case ${PERCENTAGE} in
  9[0-9]|100) ICON=$BATTERY_100; DRAWING=off
  ;;
  [6-8][0-9]) ICON=$BATTERY_75; DRAWING=off
  ;;
  [4-5][0-9]) ICON=$BATTERY_50
  ;;
  [2-3][0-9]) ICON=$BATTERY_25; COLOR=$ORANGE
  ;;
  1[0-9]) ICON=$BATTERY_25; COLOR=$RED
  ;;
  *) ICON=$BATTERY_0; COLOR=$RED
esac

if [[ $CHARGING != "" ]]; then
  ICON=$BATTERY_CHARGING
  DRAWING=off
fi

sketchybar --animate tanh 15 --set $NAME drawing=$DRAWING icon="$ICON" icon.color=$COLOR
