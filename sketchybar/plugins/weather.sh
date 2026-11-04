#!/bin/bash
# Current weather in the bar, the next six 3-hour slots in the popup.
# Keeps the last reading if the network is down.
export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/colors.sh"
NAME=${NAME:-weather}
CACHE="${TMPDIR:-/tmp}/sketchybar_weather.json"

if [ "$SENDER" = "mouse.exited.global" ]; then
  sketchybar --set $NAME popup.drawing=off; exit 0
fi

emoji() { # wttr.in weather code -> emoji
  case $1 in
    113) echo "☀️";; 116) echo "⛅️";; 119|122) echo "☁️";;
    143|248|260) echo "🌫";; 200|386|389|392|395) echo "⛈";;
    179|227|230|323|326|329|332|335|338|368|371) echo "🌨";;
    *) echo "🌧";;
  esac
}

if [ "$SENDER" != "mouse.clicked" ] || [ ! -s "$CACHE" ]; then
  new=$(curl -s -m 10 "https://wttr.in/?format=j1") && jq -e .current_condition >/dev/null 2>&1 <<<"$new" && echo "$new" > "$CACHE"
fi
[ -s "$CACHE" ] || exit 0

read -r code temp desc < <(jq -r '.current_condition[0] | "\(.weatherCode) \(.temp_C) \(.weatherDesc[0].value)"' "$CACHE")
sketchybar --set $NAME icon="$(emoji "$code")" label="${temp}°"

[ "$SENDER" = "mouse.clicked" ] || exit 0

sketchybar --remove '/weather\.row\..*/' >/dev/null 2>&1
now=$(date +%H%M | sed 's/^0*//'); now=${now:-0}
place=$(jq -r '.nearest_area[0].areaName[0].value' "$CACHE")
args=(--add item weather.row.h popup.$NAME
      --set weather.row.h icon.drawing=off label="$place · $desc" label.font="SF Pro:Bold:12.0"
            label.color=$BLUE padding_left=10 padding_right=14)
i=0
while IFS=$'\t' read -r day time code temp rain; do
  [ "$day" = 0 ] && [ "$time" -le "$now" ] && continue
  [ $i -ge 6 ] && break
  hh=$(printf '%02d:00' $((time / 100)))
  [ "$day" = 1 ] && hh="tmrw $hh"
  args+=(--add item weather.row.$i popup.$NAME
         --set weather.row.$i icon="$(emoji "$code")" icon.width=26 label="$hh   ${temp}°   rain ${rain}%"
               label.font="SF Pro:Regular:12.0" padding_left=10 padding_right=14)
  i=$((i+1))
done < <(jq -r '.weather[0:2] | to_entries[] | .key as $d | .value.hourly[] |
                [$d, .time, .weatherCode, .tempC, .chanceofrain] | @tsv' "$CACHE")
sketchybar "${args[@]}" --set $NAME popup.drawing=toggle
