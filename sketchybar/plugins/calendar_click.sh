#!/bin/bash
# Click the clock: left shows today's and tomorrow's events, right (or shift) toggles zen mode.
export PATH="/usr/local/bin:$PATH"

if [ "$BUTTON" = "right" ] || [ "$MODIFIER" = "shift" ]; then
  exec "$HOME/.config/sketchybar/plugins/zen.sh"
fi

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
FONT="SF Pro"
source "$HOME/.config/sketchybar/plugins/style.sh"   # TEXT_FONT: Nunito, or Maple Mono NF in the flat style

if [ "$(sketchybar --query calendar | jq -r '.popup.drawing')" = "on" ]; then
  sketchybar --set calendar popup.drawing=off
  exit 0
fi

# The helper is a tiny app so it has its own Calendars permission; "open" runs it and
# collects its output. Each line is "time<TAB>title".
OUT="${TMPDIR:-/tmp}/sketchybar_cal"
: > "$OUT"
# "open -W" prints "Unable to block on application" when the helper exits before open can wait
# on it. That is harmless, but its exit code is not reliable, so ignore both and wait for the
# helper to finish writing.
open -g -W --stdout "$OUT" "$HOME/.config/sketchybar/helper/SketchyBarCal.app" --args 2 2>/dev/null
sleep 0.1
for _ in $(seq 40); do pgrep -qx cal || break; sleep 0.1; done

row=(icon.font="$TEXT_FONT:Bold:12.0" icon.width=90 icon.color=$BLUE
     label.font="$TEXT_FONT:SemiBold:13.0" label.max_chars=40
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
