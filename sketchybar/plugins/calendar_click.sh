#!/bin/bash
# Click the clock: left shows today's and tomorrow's events, right (or shift) toggles zen mode.
export PATH="/usr/local/bin:$PATH"

if [ "$BUTTON" = "right" ] || [ "$MODIFIER" = "shift" ]; then
  exec "$HOME/.config/sketchybar/plugins/zen.sh"
fi

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
FONT="SF Pro"

if [ "$(sketchybar --query calendar | jq -r '.popup.drawing')" = "on" ]; then
  sketchybar --set calendar popup.drawing=off
  exit 0
fi

# The helper is a tiny app so it has its own Calendars permission; "open" runs it and
# collects its output. Each line is "time<TAB>title".
OUT="${TMPDIR:-/tmp}/sketchybar_cal"
: > "$OUT"
open -g -W --stdout "$OUT" "$HOME/.config/sketchybar/helper/SketchyBarCal.app" --args 2

row=(icon.font="$FONT:Bold:12.0" icon.width=90 icon.color=$BLUE
     label.font="$FONT:Semibold:13.0" label.max_chars=40
     padding_left=8 padding_right=14)
args=(--remove '/calendar\.event\..*/')
N=0
while IFS=$'\t' read -r when title; do
  [ -z "$when" ] && continue
  if [ "$when" = "DENIED" ]; then
    args+=(--add item calendar.event.0 popup.calendar --set calendar.event.0 "${row[@]}" icon=$CALENDAR label="No access to Calendars")
    N=1; break
  fi
  args+=(--add item calendar.event.$N popup.calendar --set calendar.event.$N "${row[@]}" icon="$when" label="$title"
         click_script="open -a Calendar; sketchybar --set calendar popup.drawing=off")
  N=$((N+1)); [ $N -ge 10 ] && break
done < "$OUT"

if [ $N -eq 0 ]; then
  args+=(--add item calendar.event.0 popup.calendar --set calendar.event.0 "${row[@]}" icon=$CALENDAR icon.width=28 label="Nothing today or tomorrow")
fi

sketchybar "${args[@]}" --set calendar popup.drawing=on
