#!/bin/bash
# Countdown to the next timed event today, from the SketchyBarCal helper.
# Calendar is read every 5 minutes into a cache; the countdown runs off it
# every 30 seconds. Shown from 60 minutes before; orange from 10, red at the start.

export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/plugins/hover.sh"
source "$HOME/.config/sketchybar/colors.sh"

# Zen mode keeps it hidden
source "$HOME/.config/sketchybar/plugins/style.sh"
[ -f "${TMPDIR:-/tmp}/sketchybar_zen" ] && { [ "$BAR_STYLE" = flat ] || sketchybar --set "$NAME" drawing=off; exit 0; }

# Flat style: the meeting shows from FLAT_MEET_WINDOW_MIN minutes ahead, as a calendar glyph and
# "<title> in 12m" right of the clock, monochrome until FLAT_MEET_SOON_MIN (see smart_lib.sh).
if [ "$BAR_STYLE" = flat ]; then
  source "$HOME/.config/sketchybar/plugins/smart_lib.sh"
  WINDOW=$FLAT_MEET_WINDOW_MIN
else
  WINDOW=60
fi

CACHE="${TMPDIR:-/tmp}/sketchybar_next"
APP="$HOME/.config/sketchybar/helper/SketchyBarCal.app"

if [ "$SENDER" = "system_woke" ] || [ "$SENDER" = "forced" ] || \
   [ -z "$(find "$CACHE" -mmin -5 2>/dev/null)" ]; then
  : > "$CACHE.tmp"
  # open -W can fail with "Unable to block on application" when the helper has already finished,
  # so do not depend on its exit code: wait for the helper, then keep what it wrote.
  open -g -W --stdout "$CACHE.tmp" "$APP" --args 1 2>/dev/null
  sleep 0.1
  for _ in $(seq 40); do pgrep -qx cal || break; sleep 0.1; done
  mv "$CACHE.tmp" "$CACHE"
fi

NOW=$(date +%s); TODAY=$(date +%Y-%m-%d)
TITLE=""; MINS=""
if [ "$BAR_STYLE" = flat ] && smart_demo meeting; then TITLE="Quarterly planning review"; MINS=12; else
while IFS=$'\t' read -r when title; do
  [[ "$when" =~ ^[0-9]{2}:[0-9]{2}$ ]] || continue
  T=$(date -j -f "%Y-%m-%d %H:%M:%S" "$TODAY $when:00" +%s 2>/dev/null) || continue
  [ "$T" -lt $((NOW - 60)) ] && continue          # already under way
  TITLE="$title"; MINS=$(( (T - NOW + 59) / 60 )); break
done < "$CACHE" 2>/dev/null
fi

if [ -z "$MINS" ] || [ "$MINS" -gt "$WINDOW" ]; then
  if [ "$BAR_STYLE" = flat ]; then smart_hide next_event; else sketchybar --set "$NAME" drawing=off; fi
  exit 0
fi

if [ "$BAR_STYLE" = flat ]; then
  flat_colors
  [ "${#TITLE}" -gt "$FLAT_MEET_CHARS" ] && TITLE="${TITLE:0:$((FLAT_MEET_CHARS - 1))}…"
  SM_IC=$FLAT_REST; SM_LC=$FLAT_REST
  if   [ "$MINS" -le 0 ]; then WHEN="now"; SM_IC=$FLAT_CRIT; SM_LC=$FLAT_CRIT
  else
    WHEN="in ${MINS}m"
    [ "$MINS" -le "$FLAT_MEET_SOON_MIN" ] && { SM_IC=$FLAT_WARN; SM_LC=$FLAT_WARN; }
  fi
  source "$HOME/.config/sketchybar/icons.sh"; SM_ICON=$CALENDAR
  SM_LABEL="$TITLE $WHEN"
  smart_show next_event
  exit 0
fi

[ ${#TITLE} -gt 22 ] && TITLE="${TITLE:0:21}…"
if   [ "$MINS" -le 0 ];  then WHEN="now";          COLOR=$RED
elif [ "$MINS" -le 10 ]; then WHEN="in ${MINS}m";  COLOR=$ORANGE
else                          WHEN="in ${MINS}m";  COLOR=$BLUE; fi

sketchybar --set "$NAME" drawing=on icon.color=$COLOR label="$TITLE $WHEN"
