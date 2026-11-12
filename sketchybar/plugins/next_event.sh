#!/bin/bash
# Countdown to the next timed event today, from the SketchyBarCal helper.
# Calendar is read every 5 minutes into a cache; the countdown runs off it
# every 30 seconds. Shown from 60 minutes before; orange from 10, red at the start.

export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/plugins/hover.sh"
source "$HOME/.config/sketchybar/colors.sh"

# Zen mode keeps it hidden
[ -f "${TMPDIR:-/tmp}/sketchybar_zen" ] && { sketchybar --set "$NAME" drawing=off; exit 0; }

CACHE="${TMPDIR:-/tmp}/sketchybar_next"
APP="$HOME/.config/sketchybar/helper/SketchyBarCal.app"

if [ "$SENDER" = "system_woke" ] || [ "$SENDER" = "forced" ] || \
   [ -z "$(find "$CACHE" -mmin -5 2>/dev/null)" ]; then
  : > "$CACHE.tmp"
  open -g -W --stdout "$CACHE.tmp" "$APP" --args 1 2>/dev/null && mv "$CACHE.tmp" "$CACHE"
fi

NOW=$(date +%s); TODAY=$(date +%Y-%m-%d)
TITLE=""; MINS=""
while IFS=$'\t' read -r when title; do
  [[ "$when" =~ ^[0-9]{2}:[0-9]{2}$ ]] || continue
  T=$(date -j -f "%Y-%m-%d %H:%M:%S" "$TODAY $when:00" +%s 2>/dev/null) || continue
  [ "$T" -lt $((NOW - 60)) ] && continue          # already under way
  TITLE="$title"; MINS=$(( (T - NOW + 59) / 60 )); break
done < "$CACHE" 2>/dev/null

if [ -z "$MINS" ] || [ "$MINS" -gt 60 ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

[ ${#TITLE} -gt 22 ] && TITLE="${TITLE:0:21}…"
if   [ "$MINS" -le 0 ];  then WHEN="now";          COLOR=$RED
elif [ "$MINS" -le 10 ]; then WHEN="in ${MINS}m";  COLOR=$ORANGE
else                          WHEN="in ${MINS}m";  COLOR=$BLUE; fi

sketchybar --set "$NAME" drawing=on icon.color=$COLOR label="$TITLE $WHEN"
