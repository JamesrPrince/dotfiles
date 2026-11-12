#!/bin/bash
# Current weather in the bar. Click for the popup, in four sections:
#   NOW         place and sky, feels-like, humidity, wind, UV, air quality
#   TODAY       sunrise and sunset
#   NEXT HOURS  the next four 3-hour slots
#   NEXT 3 DAYS day name, sky, high / low, max rain chance
# wttr.in (j1) feeds everything but air quality; it is fetched on the bar's own timer and the
# popup reads the cache. Air quality comes from Open-Meteo, only when the popup opens, cached
# 30 minutes; if that call fails the row stays hidden. Keeps the last reading if the network is down.
# Test hooks (never set in normal use): SKETCHYBAR_WEATHER_TEST_WTTR and SKETCHYBAR_WEATHER_TEST_AQ
# replace the two URLs, e.g. with an unreachable host, to exercise the failure paths.
export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/plugins/hover.sh"
source "$HOME/.config/sketchybar/colors.sh"
FONT="SF Pro"
TEXT_FONT="Nunito"
NAME=${NAME:-weather}
CACHE="${TMPDIR:-/tmp}/sketchybar_weather.json"
AQ_CACHE="${TMPDIR:-/tmp}/sketchybar_weather_aqi.json"
AQ_TTL=1800
WTTR_URL="${SKETCHYBAR_WEATHER_TEST_WTTR:-https://wttr.in/?format=j1}"
AQ_URL="${SKETCHYBAR_WEATHER_TEST_AQ:-https://air-quality-api.open-meteo.com/v1/air-quality}"
AQ_MAROON=0xffa6364f   # US AQI "hazardous"; the theme has no maroon

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

# A click on an open popup just closes it: no rebuild, no network.
if [ "$SENDER" = "mouse.clicked" ] && \
   [ "$(sketchybar --query $NAME | jq -r '.popup.drawing')" = "on" ]; then
  "$HOME/.config/sketchybar/plugins/popup.sh" "$NAME" off; exit 0
fi

if [ "$SENDER" != "mouse.clicked" ] || [ ! -s "$CACHE" ]; then
  new=$(curl -s -m 10 "$WTTR_URL") && jq -e .current_condition >/dev/null 2>&1 <<<"$new" && echo "$new" > "$CACHE"
fi

if [ ! -s "$CACHE" ]; then
  if [ "$SENDER" = "mouse.clicked" ]; then   # first run and offline: say so instead of doing nothing
    sketchybar --remove '/weather\.row\..*/' >/dev/null 2>&1
    sketchybar --add item weather.row.0 popup.$NAME \
               --set weather.row.0 icon.drawing=off label="Weather unavailable" label.color=$GREY \
                     label.font="$TEXT_FONT:SemiBold:12.0" padding_left=10 padding_right=14
    "$HOME/.config/sketchybar/plugins/popup.sh" "$NAME" on
  fi
  exit 0
fi

read -r code temp < <(jq -r '.current_condition[0] | "\(.weatherCode) \(.temp_C)"' "$CACHE")
sketchybar --set $NAME icon="$(emoji "$code")" label="${temp}°"

[ "$SENDER" = "mouse.clicked" ] || exit 0

# ---- air quality: Open-Meteo, popup opens only, 30-minute cache keyed by location ----------
read -r lat lon < <(jq -r '.nearest_area[0] | "\(.latitude) \(.longitude)"' "$CACHE")
aq_fresh() { # prints the cached us_aqi when the cache is for this location and under 30 min old
  [ -s "$AQ_CACHE" ] || return 1
  local age=$(( $(date +%s) - $(stat -f %m "$AQ_CACHE") ))
  [ "$age" -lt "$AQ_TTL" ] || return 1
  jq -er --arg k "$lat,$lon" 'select(.key == $k) | .data.current.us_aqi | select(. != null) | round' "$AQ_CACHE" 2>/dev/null
}
aq_fetch() { # fetches, caches, prints us_aqi; fails quietly
  local raw
  [ -n "$lat" ] && [ "$lat" != null ] && [ -n "$lon" ] && [ "$lon" != null ] || return 1
  raw=$(curl -s -m 5 "$AQ_URL?latitude=$lat&longitude=$lon&current=us_aqi,pm2_5") || return 1
  jq -e '.current.us_aqi != null' >/dev/null 2>&1 <<<"$raw" || return 1
  jq -c --arg k "$lat,$lon" '{key: $k, data: .}' <<<"$raw" > "$AQ_CACHE"
  jq -r '.current.us_aqi | round' <<<"$raw"
}
aq_set() { # <aqi>: fills the air-quality row in the standard US AQI colour band
  local v=$1 band color
  if   [ "$v" -le 50 ];  then band="Good";             color=$GREEN
  elif [ "$v" -le 100 ]; then band="Moderate";         color=$YELLOW
  elif [ "$v" -le 150 ]; then band="Sensitive groups"; color=$ORANGE
  elif [ "$v" -le 200 ]; then band="Unhealthy";        color=$RED
  elif [ "$v" -le 300 ]; then band="Very unhealthy";   color=$MAGENTA
  else                        band="Hazardous";        color=$AQ_MAROON; fi
  AQ_SET=(--set weather.row.aq drawing=on label="Air quality $v · $band" label.color=$color)
}

# ---- the popup rows -------------------------------------------------------------------------
sketchybar --remove '/weather\.row\..*/' >/dev/null 2>&1
today=$(date +%Y-%m-%d); tomorrow=$(date -v+1d +%Y-%m-%d); nowkey=$(date +%Y%m%d%H%M)

IFS=$'\t' read -r place desc feels hum wind wdir uv sunrise sunset < <(jq -r '
  [.nearest_area[0].areaName[0].value, (.current_condition[0].weatherDesc[0].value | gsub("^ +| +$"; "")),
   .current_condition[0].FeelsLikeC, .current_condition[0].humidity,
   .current_condition[0].windspeedKmph, .current_condition[0].winddir16Point,
   .current_condition[0].uvIndex,
   .weather[0].astronomy[0].sunrise, .weather[0].astronomy[0].sunset] | @tsv' "$CACHE")
sunrise=$(date -j -f "%I:%M %p" "$sunrise" +%H:%M 2>/dev/null || echo "$sunrise")
sunset=$(date -j -f "%I:%M %p" "$sunset" +%H:%M 2>/dev/null || echo "$sunset")
if   [ "${uv:-0}" -le 2 ]; then uvl="low"
elif [ "${uv:-0}" -le 5 ]; then uvl="moderate"
else uvl="high"; fi

hdr=(icon.width=26 label.font="$TEXT_FONT:ExtraBold:11.0" label.color=$GREY padding_left=8 padding_right=12)
row=(icon.font="$FONT:Regular:14.0" icon.width=26 label.font="$TEXT_FONT:SemiBold:13.0"
     padding_left=8 padding_right=12)
args=(); n=0
add_hdr() { n=$((n+1)); args+=(--add item weather.row.$n popup.$NAME --set weather.row.$n "${hdr[@]}" label="$1"); }
add_row() { n=$((n+1)); args+=(--add item weather.row.$n popup.$NAME --set weather.row.$n "${row[@]}" icon="$1" label="$2"); }

add_hdr "NOW"
n=$((n+1))
args+=(--add item weather.row.$n popup.$NAME
       --set weather.row.$n "${row[@]}" icon="$(emoji "$code")" label="$place · $desc"
             label.font="$TEXT_FONT:Bold:13.0" label.color=$BLUE)
add_row "🌡" "Feels like ${feels}° · Humidity ${hum}%"
add_row "💨" "Wind ${wind} km/h ${wdir} · UV ${uv} ${uvl}"
args+=(--add item weather.row.aq popup.$NAME --set weather.row.aq "${row[@]}" icon="🍃" drawing=off)
if aq=$(aq_fresh); then aq_set "$aq"; args+=("${AQ_SET[@]}"); fi   # a cache hit shows at once; a miss is fetched below

add_hdr "TODAY"
add_row "🌅" "Sunrise $sunrise · Sunset $sunset"

add_hdr "NEXT HOURS"
i=0
while IFS=$'\t' read -r day time hcode htemp rain; do
  [ "$(( ${day//-/}$(printf '%04d' "$time") ))" -le "$nowkey" ] && continue
  [ $i -ge 4 ] && break
  hh=$(printf '%02d:00' $((time / 100)))
  if   [ "$day" = "$tomorrow" ]; then hh="tmrw $hh"
  elif [ "$day" != "$today" ];   then hh="$(date -j -f %Y-%m-%d "$day" +%a) $hh"; fi
  add_row "$(emoji "$hcode")" "$hh · ${htemp}° · rain ${rain}%"
  i=$((i+1))
done < <(jq -r '.weather[0:3][] | .date as $d | .hourly[] |
                [$d, .time, .weatherCode, .tempC, .chanceofrain] | @tsv' "$CACHE")

add_hdr "NEXT 3 DAYS"
i=0
while IFS=$'\t' read -r day hi lo rain dcode; do
  [[ "$day" < "$today" ]] && continue   # a stale cache may still hold yesterday
  [ $i -ge 3 ] && break
  if [ "$day" = "$today" ]; then dn="Today"; else dn=$(date -j -f %Y-%m-%d "$day" +%a); fi
  add_row "$(emoji "$dcode")" "$dn · ${hi}° / ${lo}° · rain ${rain}%"
  i=$((i+1))
done < <(jq -r '.weather[0:3][] | [.date, .maxtempC, .mintempC,
                ([.hourly[].chanceofrain | tonumber] | max), (.hourly[4] // .hourly[0]).weatherCode] | @tsv' "$CACHE")

sketchybar "${args[@]}"
"$HOME/.config/sketchybar/plugins/popup.sh" "$NAME" on

# Air quality cache miss: fetch after the popup is up so a slow network never delays it.
# On failure the row simply stays hidden.
if [ -z "$aq" ] && aq=$(aq_fetch); then
  aq_set "$aq"; sketchybar "${AQ_SET[@]}"
fi
exit 0
