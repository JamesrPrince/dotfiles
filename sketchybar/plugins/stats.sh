#!/bin/bash
# Feeds the stats items every few seconds: CPU load (graph + %), memory in
# use, GPU load, network speed on en0. Also keeps today's network totals and peak speeds
# in ~/.cache/sketchybar-net-today for the network popup (plugins/stat_net.sh). The popups
# themselves are filled by stat_net.sh, stat_cpu.sh and stat_mem.sh, only while open.

export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/plugins/hover.sh"
if [ "$SENDER" = "mouse.exited.global" ]; then
  "$HOME/.config/sketchybar/plugins/popup.sh" "$NAME" off
  exit 0
fi
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

# Today's data: bytes since the first look of the day, carried across a reboot (the counters
# restart at zero, so what was counted before is added to the carry), and the peak speeds.
# Fields: day baseIn baseOut lastIn lastOut carryIn carryOut peakDown peakUp
TODAY="$HOME/.cache/sketchybar-net-today"
if [ -n "$IN" ] && [ -n "$OUT" ]; then
  DAY=$(date +%F)
  read -r TDAY BIN BOUT LIN LOUT AIN AOUT PD PU < "$TODAY" 2>/dev/null
  if [ "$TDAY" != "$DAY" ]; then
    BIN=$IN; BOUT=$OUT; AIN=0; AOUT=0; PD=0; PU=0
  elif [ "$IN" -lt "${LIN:-0}" ]; then   # counters restarted: reboot
    AIN=$(( AIN + LIN - BIN )); AOUT=$(( AOUT + LOUT - BOUT )); BIN=0; BOUT=0
  fi
  D_NOW=0; U_NOW=0
  if [ -n "$PIN" ] && [ "$IN" -ge "$PIN" ]; then D_NOW=$(( (IN - PIN) / DT )); U_NOW=$(( (OUT - POUT) / DT )); fi
  [ "$D_NOW" -gt "${PD:-0}" ] && PD=$D_NOW
  [ "$U_NOW" -gt "${PU:-0}" ] && PU=$U_NOW
  mkdir -p "$HOME/.cache"
  echo "$DAY $BIN $BOUT $IN $OUT ${AIN:-0} ${AOUT:-0} ${PD:-0} ${PU:-0}" > "$TODAY"
fi

args=(--push cpu.graph "$(awk -v c="$CPU" 'BEGIN{printf "%.2f", c/100}')"
      --set cpu.percent label="${CPU}%" icon.color=$CPU_COLOR
      --set cpu.graph graph.color=$CPU_COLOR
      --set mem label="${MEM}%"
      --set gpu label="${GPU}%" icon.color=$GPU_COLOR
      --set net.up label="$NET_UP $UP_LABEL"
      --set net.down label="$NET_DOWN $DOWN_LABEL")

sketchybar "${args[@]}"
