#!/bin/bash
# Feeds the stats items every few seconds: CPU load (graph + %), memory in
# use, GPU load, network speed on en0, and the popup's temperature, fan, disk, uptime.

export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/plugins/hover.sh"
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

HELPER="$HOME/.config/sketchybar/helper"
STATE="${TMPDIR:-/tmp}/sketchybar_net"

# CPU: user + system load since the last run (the helper keeps the tick counts)
CPU=$("$HELPER/cpu" "${TMPDIR:-/tmp}/sketchybar_cpu" 2>/dev/null)
CPU=${CPU:-0}
CPU_COLOR=$BLUE
[ "$CPU" -ge 50 ] && CPU_COLOR=$YELLOW
[ "$CPU" -ge 80 ] && CPU_COLOR=$RED

# Memory: 100 minus the system-wide free percentage
FREE=$(memory_pressure -Q 2>/dev/null | awk -F': ' '/free percentage/{gsub("%","",$2); print $2}')
MEM=$(( 100 - ${FREE:-100} ))

# GPU: busiest graphics card (Intel or Radeon), from IOAccelerator stats
GPU=$(ioreg -r -d 1 -c IOAccelerator | grep -o '"PerformanceStatistics" = {[^}]*}' \
      | grep -o '"Device Utilization %"=[0-9]*' | cut -d= -f2 | sort -n | tail -1)
GPU=${GPU:-0}
GPU_COLOR=$GREEN
[ "$GPU" -ge 50 ] && GPU_COLOR=$YELLOW
[ "$GPU" -ge 80 ] && GPU_COLOR=$RED

# Network: bytes per second on en0 since the last run
human() {
  awk -v b="$1" 'BEGIN{ if (b>=1048576) printf "%.1f MB/s", b/1048576;
                        else if (b>=1024) printf "%.0f KB/s", b/1024;
                        else printf "%d B/s", b }'
}
NOW=$(date +%s)
read -r IN OUT <<< "$(netstat -ibn -I en0 | awk 'NR==2{print $7, $10}')"
UP_LABEL="0 B/s"; DOWN_LABEL="0 B/s"
if [ -f "$STATE" ]; then
  read -r PNOW PIN POUT < "$STATE"
  DT=$(( NOW - PNOW )); [ "$DT" -lt 1 ] && DT=1
  if [ -n "$IN" ] && [ -n "$PIN" ] && [ "$IN" -ge "$PIN" ]; then
    DOWN_LABEL=$(human $(( (IN - PIN) / DT )))
    UP_LABEL=$(human $(( (OUT - POUT) / DT )))
  fi
fi
echo "$NOW $IN $OUT" > "$STATE"

args=(--push cpu.graph "$(awk -v c="$CPU" 'BEGIN{printf "%.2f", c/100}')"
      --set cpu.percent label="${CPU}%" icon.color=$CPU_COLOR
      --set cpu.graph graph.color=$CPU_COLOR
      --set mem label="${MEM}%"
      --set gpu label="${GPU}%" icon.color=$GPU_COLOR
      --set net.up label="$NET_UP $UP_LABEL"
      --set net.down label="$NET_DOWN $DOWN_LABEL")

# Popup rows only while the popup is open
if [ "$(sketchybar --query cpu.percent | jq -r '.popup.drawing')" = "on" ]; then
  read -r TEMP FAN <<< "$("$HELPER/smc" 2>/dev/null)"
  TEMP_INT=${TEMP%.*}
  TEMP_COLOR=$GREEN
  [ "${TEMP_INT:-0}" -ge 80 ] && TEMP_COLOR=$ORANGE
  [ "${TEMP_INT:-0}" -ge 95 ] && TEMP_COLOR=$RED
  if [ -n "$TEMP" ] && [ "$TEMP_INT" -gt 0 ]; then TEMP_LABEL="CPU ${TEMP}°C"; else TEMP_LABEL="CPU temperature unavailable"; fi
  if [ -n "$FAN" ] && [ "${FAN%.*}" -ge 0 ] 2>/dev/null; then FAN_LABEL="Fan ${FAN} rpm"; else FAN_LABEL="Fan unavailable"; fi
  DISK_LABEL=$(df -H / | awk 'NR==2{print $4 " free of " $2}')
  UPTIME_LABEL="Up $(uptime | sed -E 's/.*up ([^,]*(, *[0-9]+:[0-9]+)?).*/\1/; s/^ +//')"
  args+=(--set stats.temp label="$TEMP_LABEL" icon.color=$TEMP_COLOR
         --set stats.fan label="$FAN_LABEL"
         --set stats.disk label="Disk $DISK_LABEL"
         --set stats.uptime label="$UPTIME_LABEL")
fi

sketchybar "${args[@]}"
