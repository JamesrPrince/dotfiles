#!/bin/bash
# Network popup (anchor net.up): live throughput graphs, today's data and peak speed, the apps
# using the network now, latency to the router and the internet, public IP and ISP, speed test.
#   stat_net.sh reset   fill the rows with "…"
#   stat_net.sh loop    gather and draw every second until the popup closes
# The slow parts (nettop, ping, ipinfo) run in background workers that also stop with the popup.

source "$HOME/.config/sketchybar/plugins/stat_lib.sh"
source "$HOME/.config/sketchybar/plugins/icon_map.sh"

ANCHOR=net.up
IFACE=en0                                   # the same interface the bar's speed labels use
D="${TMPDIR:-/tmp}/sketchybar_statnet"; mkdir -p "$D"
TODAY="$CACHE/sketchybar-net-today"         # written by stats.sh: day, baselines, carry, peaks
IPCACHE="$CACHE/sketchybar-ipinfo.json"
SPEED_RESULT="${TMPDIR:-/tmp}/sketchybar_wifi_speed_result"
SPEED_LOCK="${TMPDIR:-/tmp}/sketchybar_wifi_speed.lock"
DOT=􀀁

if [ "$1" = reset ]; then
  args=()
  for r in np.dl np.ul np.peak np.used np.verdict np.router np.net np.ip; do args+=(--set $r label="…"); done
  for n in 1 2 3 4 5; do args+=(--set np.app.$n drawing=off); done
  sketchybar "${args[@]}"
  exit 0
fi
[ "$1" = loop ] || exit 0
single_instance net

# --- background workers -----------------------------------------------------------------
worker_apps() {   # top apps by current throughput: nettop's second sample is a 1 s delta
  while popup_open $ANCHOR; do
    # nettop names a process "name.pid" (Claude Code shows up as its version, "2.1.322"), so the
    # pid is looked up in ps and named like the CPU and memory lists: the app bundle, else the
    # executable's file name
    ps -Ao pid=,comm= > "$D/pids"
    nettop -P -d -L 2 -s 1 -J bytes_in,bytes_out -x 2>/dev/null | awk -F, '
      FNR == NR { pid = $1; sub(/^ +/, "", pid); sub(/ .*/, "", pid)
                  c = $0; sub(/^ *[0-9]+ +/, "", c)
                  if (sub(/\.app\/.*/, "", c) == 0) sub(/^.*\//, "", c); else sub(/^.*\//, "", c)
                  sub(/^-/, "", c); name[pid] = c; next }
      /^,bytes_in/ { b++; next }
      b == 2 && NF >= 3 {
        n = $1; pid = n; sub(/^.*\./, "", pid); sub(/\.[0-9]+$/, "", n)
        if (pid in name) n = name[pid]; else sub(/ H(e(l(p(e(r)?)?)?)?)?$/, "", n)
        i[n] += $2; o[n] += $3 }
      END { for (n in i) if (i[n] + o[n] > 0) printf "%s|%d|%d\n", n, i[n], o[n] }' "$D/pids" - \
      | sort -t'|' -k2,2nr -k3,3nr | head -5 > "$D/apps.tmp" && mv "$D/apps.tmp" "$D/apps"
    sleep 1
  done
}

ping_one() {   # prints "<avg ms or empty> <loss %>"
  ping -c 5 -i 0.3 -q "$1" 2>&1 | awk '
    /packet loss/ { for (k = 1; k <= NF; k++) if ($k ~ /%$/) loss = $k; sub(/%/, "", loss) }
    /round-trip/ { split($0, a, " = "); split(a[2], b, "/"); ms = b[2] }
    END { printf "%s %s\n", (ms == "" ? "-" : ms), (loss == "" ? 100 : loss) }'
}
worker_ping() {
  while popup_open $ANCHOR; do
    gw=$(route -n get default 2>/dev/null | awk '/gateway:/{print $2}')
    ( ping_one "${gw:-192.168.0.1}" > "$D/ping_router.tmp" ) &
    ( ping_one 1.1.1.1 > "$D/ping_net.tmp" ) &
    wait
    echo "$(cat "$D/ping_router.tmp") $(cat "$D/ping_net.tmp")" > "$D/ping.tmp" && mv "$D/ping.tmp" "$D/ping"
    nap 12 $ANCHOR || break
  done
}

worker_ip() {     # one request, cached for 10 minutes
  find "$IPCACHE" -mmin -10 2>/dev/null | grep -q . && return
  curl -s --max-time 6 https://ipinfo.io/json -o "$IPCACHE.tmp" && jq -e .ip "$IPCACHE.tmp" >/dev/null 2>&1 \
    && mv "$IPCACHE.tmp" "$IPCACHE"
}

trap 'kill $(jobs -p) 2>/dev/null' EXIT
worker_apps & worker_ping & worker_ip &

# --- main loop: counters every second --------------------------------------------------
# graph height: square root of the speed, full height at 5 MB/s, so quiet traffic still shows
scale() { awk -v b="$1" 'BEGIN{ v = sqrt(b / 5242880); if (v > 1) v = 1; printf "%.3f", v }'; }
PNOW=""; PIN=""; POUT=""; PK_D=0; PK_U=0

while popup_open $ANCHOR; do
  NOW=$(date +%s)
  read -r IN OUT <<< "$(netstat -ibn -I $IFACE | awk 'NR==2{print $7, $10}')"
  DOWN=0; UP=0
  if [ -n "$PNOW" ] && [ -n "$IN" ] && [ "$IN" -ge "$PIN" ]; then
    DT=$(( NOW - PNOW )); [ "$DT" -lt 1 ] && DT=1
    DOWN=$(( (IN - PIN) / DT )); UP=$(( (OUT - POUT) / DT ))
  fi
  PNOW=$NOW PIN=$IN POUT=$OUT
  [ "$DOWN" -gt "$PK_D" ] && PK_D=$DOWN
  [ "$UP" -gt "$PK_U" ] && PK_U=$UP

  # today: written by stats.sh (day base, carry across a reboot, peaks); here we only read it
  read -r TDAY BIN BOUT LIN LOUT AIN AOUT TPD TPU < "$TODAY" 2>/dev/null
  USED_IN=$(( ${AIN:-0} + ${IN:-0} - ${BIN:-0} )); USED_OUT=$(( ${AOUT:-0} + ${OUT:-0} - ${BOUT:-0} ))
  [ "$USED_IN" -lt 0 ] && USED_IN=0; [ "$USED_OUT" -lt 0 ] && USED_OUT=0
  PEAK_D=$PK_D; [ "${TPD:-0}" -gt "$PEAK_D" ] && PEAK_D=$TPD
  PEAK_U=$PK_U; [ "${TPU:-0}" -gt "$PEAK_U" ] && PEAK_U=$TPU

  args=(--push np.dl "$(scale $DOWN)" --set np.dl label="$(human_rate $DOWN)"
        --push np.ul "$(scale $UP)"   --set np.ul label="$(human_rate $UP)"
        --set np.peak label="Peak today   ↓ $(human_rate $PEAK_D)   ↑ $(human_rate $PEAK_U)"
        --set np.used label="Used today   ↓ $(human_bytes $USED_IN)   ↑ $(human_bytes $USED_OUT)")

  # apps
  n=0
  while IFS='|' read -r name ain aout; do
    [ -n "$name" ] || continue
    n=$((n+1))
    app_icon "$name"
    args+=(--set np.app.$n drawing=on icon="$icon_result" label="$name   ↓ $(human_rate $ain)  ↑ $(human_rate $aout)")
  done < "$D/apps" 2>/dev/null
  for ((k = n + 1; k <= 5; k++)); do args+=(--set np.app.$k drawing=off); done
  [ "$n" -eq 0 ] && args+=(--set np.app.1 drawing=on icon=" " label="…")

  # latency, loss and the verdict
  if read -r RMS RLOSS NMS NLOSS < "$D/ping" 2>/dev/null; then
    fmt() { [ "$1" = "-" ] && printf 'no reply' || printf '%.0f ms' "$1"; }
    args+=(--set np.router label="Router $(fmt $RMS) · ${RLOSS%.*}% loss"
           --set np.net label="Internet $(fmt $NMS) · ${NLOSS%.*}% loss")
    if [ "$RMS" = "-" ] || [ "${RLOSS%.*}" -ge 10 ] || [ "${RMS%.*}" -gt 60 ] 2>/dev/null; then
      V="Wi-Fi issue"; VC=$RED
    elif [ "$NMS" = "-" ] || [ "${NLOSS%.*}" -ge 10 ] || [ "${NMS%.*}" -gt 250 ] 2>/dev/null; then
      V="ISP issue"; VC=$ORANGE
    else V="Connection OK"; VC=$GREEN; fi
    args+=(--set np.verdict label="$V" icon.color=$VC)
  else
    args+=(--set np.router label="Router …" --set np.net label="Internet …" --set np.verdict label="Checking…" icon.color=$GREY)
  fi

  # public IP, ISP, city
  if [ -s "$IPCACHE" ]; then
    args+=(--set np.ip label="$(jq -r '"\(.ip) · \((.org // "") | sub("^AS[0-9]+ "; "")) · \(.city // "")"' "$IPCACHE" 2>/dev/null)")
  fi

  # speed test: the click is plugins/wifi_speed.sh run; its lock and result files drive these rows
  if [ -d "$SPEED_LOCK" ]; then args+=(--set np.speed label="Testing…" label.color=$GREY icon.color=$GREY)
  else args+=(--set np.speed label="Test speed" label.color=$LABEL_COLOR icon.color=$BLUE); fi
  if [ -s "$SPEED_RESULT" ]; then args+=(--set np.speed.result drawing=on label="$(cat "$SPEED_RESULT")")
  else args+=(--set np.speed.result drawing=off); fi

  sketchybar "${args[@]}" 2>/dev/null
  sleep 1
done
