#!/bin/bash
# CPU popup (anchor cpu.percent): a 60 s CPU graph, load averages with the core count, the
# user/system/idle split, throttling, temperature, fan, the top 5 processes, uptime.
#   stat_cpu.sh reset   fill the rows with "…"
#   stat_cpu.sh loop    gather and draw until the popup closes (one pass takes about 1.5 s)

source "$HOME/.config/sketchybar/plugins/stat_lib.sh"
source "$HOME/.config/sketchybar/plugins/icon_map.sh"

ANCHOR=cpu.percent
HELPER="$HOME/.config/sketchybar/helper"

if [ "$1" = reset ]; then
  args=()
  for r in cp.load cp.split cp.throttle cp.temp cp.fan cp.uptime; do args+=(--set $r label="…"); done
  for n in 1 2 3 4 5; do args+=(--set cp.proc.$n drawing=off); done
  sketchybar "${args[@]}"
  exit 0
fi
[ "$1" = loop ] || exit 0
single_instance cpu

CORES=$(sysctl -n hw.physicalcpu); THREADS=$(sysctl -n hw.logicalcpu)

while popup_open $ANCHOR; do
  # iostat's second sample covers one second: user, system, idle and the load averages
  read -r US SY ID L1 L5 L15 <<< "$(iostat -c 2 -w 1 | tail -1 | awk '{print $(NF-5), $(NF-4), $(NF-3), $(NF-2), $(NF-1), $NF}')"
  BUSY=$(( ${US:-0} + ${SY:-0} ))
  COLOR=$BLUE; [ "$BUSY" -ge 50 ] && COLOR=$YELLOW; [ "$BUSY" -ge 80 ] && COLOR=$RED

  # throttling: pmset prints CPU_Speed_Limit, below 100 means the Mac is slowing itself down
  LIMIT=$(pmset -g therm 2>/dev/null | awk '/CPU_Speed_Limit/{print $3}')
  if [ -n "$LIMIT" ] && [ "$LIMIT" -lt 100 ] 2>/dev/null; then
    TH="Throttled to ${LIMIT}%"; THC=$ORANGE; [ "$LIMIT" -lt 70 ] && THC=$RED
  else TH="Full speed (${LIMIT:-100}%)"; THC=$GREEN; fi

  # temperature and fan, from the Intel SMC helper
  read -r TEMP FAN <<< "$("$HELPER/smc" 2>/dev/null)"
  TI=${TEMP%.*}; TC=$GREEN
  [ "${TI:-0}" -ge 80 ] && TC=$ORANGE; [ "${TI:-0}" -ge 95 ] && TC=$RED
  if [ -n "$TEMP" ] && [ "${TI:-0}" -gt 0 ]; then TL="CPU ${TEMP}°C"; else TL="CPU temperature unavailable"; TC=$GREY; fi
  if [ -n "$FAN" ] && [ "${FAN%.*}" -ge 0 ] 2>/dev/null; then FL="Fan ${FAN} rpm"; else FL="Fan unavailable"; fi

  UP="Up $(uptime | sed -E 's/.*up ([^,]*(, *[0-9]+:[0-9]+)?).*/\1/; s/^ +//')"

  args=(--push cp.graph "$(awk -v c="$BUSY" 'BEGIN{printf "%.2f", c/100}')" --set cp.graph graph.color=$COLOR
        --set cp.load label="Load $(printf '%.1f · %.1f · %.1f' "$L1" "$L5" "$L15") · ${CORES}C/${THREADS}T"
        --set cp.split label="User ${US}%   System ${SY}%   Idle ${ID}%"
        --set cp.throttle label="$TH" label.color=$THC icon.color=$THC
        --set cp.temp label="$TL" icon.color=$TC
        --set cp.fan label="$FL"
        --set cp.uptime label="$UP")

  # top 5 processes by CPU, helpers grouped under their app; ps reports % of one core, so
  # it is divided by the thread count to agree with the user/system/idle split above
  n=0
  while IFS='|' read -r pct name; do
    [ -n "$name" ] || continue
    n=$((n+1))
    __icon_map "$name"
    args+=(--set cp.proc.$n drawing=on icon="$icon_result" label="$name   ${pct}%")
  done < <(ps -Ao pcpu=,comm= | awk -v threads="$THREADS" '
      { p = $1 / threads; $1 = ""; sub(/^ +/, ""); n = $0
        if (sub(/\.app\/.*/, "", n) == 0) sub(/^.*\//, "", n); else sub(/^.*\//, "", n)
        sub(/^-/, "", n); c[n] += p }
      END { for (n in c) printf "%.1f|%s\n", c[n], n }' | sort -t'|' -k1,1nr | head -5)
  for ((k = n + 1; k <= 5; k++)); do args+=(--set cp.proc.$k drawing=off); done

  sketchybar "${args[@]}" 2>/dev/null
done
