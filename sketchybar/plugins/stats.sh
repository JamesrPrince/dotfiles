#!/bin/bash
# Feeds the stats items every few seconds: CPU load (graph + %), memory in
# use, GPU load, network speed on en0. Also keeps today's network totals and peak speeds
# in ~/.cache/sketchybar-net-today for the network popup (plugins/stat_net.sh). The popups
# themselves are filled by stat_net.sh, stat_cpu.sh and stat_mem.sh, only while open.
#
# One run is this script, `cat` (the theme colours), helper/statsample and one `sketchybar`
# call. statsample reads CPU, memory pressure, GPU and the en0 counters in a single process;
# it used to be memory_pressure, sysctl, ioreg, netstat, awk, date and friends (20 programs).
# Build it with: clang -O2 -o helper/statsample helper/statsample.c -framework IOKit -framework CoreFoundation
# Without the binary the old tool chain below still gives the same numbers, only slower.

export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/plugins/hover.sh"
if [ "$SENDER" = "mouse.exited.global" ]; then
  "$HOME/.config/sketchybar/plugins/popup.sh" "$NAME" off
  exit 0
fi
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
# The style, read with the shell's own `read` (plugins/style.sh would start a `cat`)
BAR_STYLE=; [ -r "$HOME/.config/sketchybar/.barstyle" ] && read -r BAR_STYLE < "$HOME/.config/sketchybar/.barstyle"

HELPER="$HOME/.config/sketchybar/helper"
STATE="${TMPDIR:-/tmp}/sketchybar_net"

# sample  ->  CPU MEMFREE LEVEL GPU EPOCH DAY IN OUT   (see helper/statsample.c)
sample() {
  if [ -x "$HELPER/statsample" ]; then
    "$HELPER/statsample" "${TMPDIR:-/tmp}/sketchybar_statsample" 2>/dev/null && return
  fi
  local cpu free level gpu in out
  cpu=$("$HELPER/cpu" "${TMPDIR:-/tmp}/sketchybar_cpu" 2>/dev/null)
  free=$(memory_pressure -Q 2>/dev/null | awk -F': ' '/free percentage/{gsub("%","",$2); print $2}')
  level=$(sysctl -n kern.memorystatus_vm_pressure_level 2>/dev/null)
  gpu=$(ioreg -r -d 1 -c IOAccelerator | grep -o '"PerformanceStatistics" = {[^}]*}' \
        | grep -o '"Device Utilization %"=[0-9]*' | cut -d= -f2 | sort -n | tail -1)
  read -r in out <<< "$(netstat -ibn -I en0 | awk 'NR==2{print $7, $10}')"
  echo "${cpu:-0} ${free:-100} ${level:-1} ${gpu:-0} $(date +%s) $(date +%F) ${in:-0} ${out:-0}"
}
read -r CPU FREE LEVEL GPU NOW DAY IN OUT <<< "$(sample)"
CPU=${CPU:-0}; GPU=${GPU:-0}; NOW=${NOW:-0}
[ "$IN" = 0 ] && [ "$OUT" = 0 ] && IN= OUT=   # no en0

# CPU: user + system load since the last run
CPU_COLOR=$BLUE
[ "$CPU" -ge 50 ] && CPU_COLOR=$YELLOW
[ "$CPU" -ge 80 ] && CPU_COLOR=$RED

# Memory pressure: 100 minus the system-wide free percentage that memory_pressure reports
# (not "memory used"), coloured by the kernel's pressure level, as Activity Monitor's graph is
# (1 normal, 2 warning, 4 critical)
MEM=$(( 100 - ${FREE:-100} ))
case $LEVEL in
  4) MEM_COLOR=$RED ;;
  2) MEM_COLOR=$YELLOW ;;
  *) MEM_COLOR=$GREEN ;;
esac

# GPU: busiest graphics card (Intel or Radeon)
GPU_COLOR=$GREEN
[ "$GPU" -ge 50 ] && GPU_COLOR=$YELLOW
[ "$GPU" -ge 80 ] && GPU_COLOR=$RED

# Network: bytes per second on en0 since the last run, as "1.2 MB/s", "340 KB/s" or "12 B/s" (into $RATE)
human() {
  local b=$1 t
  if [ "$b" -ge 1048576 ]; then
    t=$(( (b * 20 + 1048576) / 2097152 )); RATE="$((t / 10)).$((t % 10)) MB/s"
  elif [ "$b" -ge 1024 ]; then
    RATE="$(( (b * 2 + 1024) / 2048 )) KB/s"
  else
    RATE="$b B/s"
  fi
}
UP_LABEL="0 B/s"; DOWN_LABEL="0 B/s"
if [ -f "$STATE" ]; then
  read -r PNOW PIN POUT < "$STATE"
  DT=$(( NOW - PNOW )); [ "$DT" -lt 1 ] && DT=1
  if [ -n "$IN" ] && [ -n "$PIN" ] && [ "$IN" -ge "$PIN" ]; then
    human $(( (IN - PIN) / DT )); DOWN_LABEL=$RATE
    human $(( (OUT - POUT) / DT )); UP_LABEL=$RATE
  fi
fi
echo "$NOW $IN $OUT" > "$STATE"

# Today's data: bytes since the first look of the day, carried across a reboot (the counters
# restart at zero, so what was counted before is added to the carry), and the peak speeds.
# Fields: day baseIn baseOut lastIn lastOut carryIn carryOut peakDown peakUp
TODAY="$HOME/.cache/sketchybar-net-today"
if [ -n "$IN" ] && [ -n "$OUT" ]; then
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
  [ -d "$HOME/.cache" ] || mkdir -p "$HOME/.cache"
  echo "$DAY $BIN $BOUT $IN $OUT ${AIN:-0} ${AOUT:-0} ${PD:-0} ${PU:-0}" > "$TODAY"
fi

printf -v GRAPH '%d.%02d' $(( CPU / 100 )) $(( CPU % 100 ))   # 0.00 to 1.00
args=(--push cpu.graph "$GRAPH"
      --set cpu.percent label="${CPU}%" icon.color=$CPU_COLOR
      --set cpu.graph graph.color=$CPU_COLOR
      --set mem label="${MEM}%" icon.color=$MEM_COLOR
      --set gpu label="${GPU}%" icon.color=$GPU_COLOR
      --set net.up label="$NET_UP $UP_LABEL"
      --set net.down label="$NET_DOWN $DOWN_LABEL")

# The flat bar shows the GPU in its own item
if [ "$BAR_STYLE" = flat ]; then
  args+=(--set gpu.bar label="${GPU}%" icon.color=$GPU_COLOR)
fi

sketchybar "${args[@]}"
