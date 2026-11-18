#!/bin/bash
# Read-only speed numbers: one `name<TAB>value<TAB>unit` row each.
#   bench.sh          print the rows
#   bench.sh --save   also append a timestamped copy to ~/.local/state/snappy/bench.tsv
set -u
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"
DOT="$(cd "$(dirname "$0")" && pwd)"
AERO=$(command -v aerospace || true)

now_ms() { python3 -c 'import time;print(int(time.time()*1000))'; }
median5() { # median5 <cmd...>: median wall ms of 5 runs
  local i t0 t1 list=""
  for i in 1 2 3 4 5; do
    t0=$(now_ms); "$@" >/dev/null 2>&1; t1=$(now_ms)
    list="$list $((t1-t0))"
  done
  echo $list | tr ' ' '\n' | sort -n | sed -n 3p
}
row() { printf '%s\t%s\t%s\n' "$1" "$2" "$3"; }

out=$(
zsh -i -c exit >/dev/null 2>&1   # warm up
row zsh_start_warm "$(median5 zsh -i -c exit)" ms
if [ -n "$AERO" ]; then
  row aerospace_list_focused "$(median5 "$AERO" list-windows --focused)" ms
else row aerospace_list_focused n/a ms; fi
if [ -n "$AERO" ] && [ -x "$DOT/aerospace/layout-cycle.sh" ]; then
  row layout_cycle_enforce "$(median5 "$DOT/aerospace/layout-cycle.sh" enforce)" ms
else row layout_cycle_enforce n/a ms; fi
row cpu_speed_limit "$(pmset -g therm 2>/dev/null | awk '/CPU_Speed_Limit/{print $NF; f=1} END{if(!f)print "n/a"}')" percent
row load_1min "$(sysctl -n vm.loadavg | awk '{print $2}')" load
row swap_used "$(sysctl -n vm.swapusage | sed -n 's/.*used = \([0-9.]*\)M.*/\1/p')" MB
row mem_pressure_level "$(sysctl -n kern.memorystatus_vm_pressure_level 2>/dev/null || echo n/a)" level
row windowserver_cpu "$(ps -Ao %cpu=,comm= | awk '/\/WindowServer$/{s+=$1} END{printf "%.1f", s+0}')" percent
row process_count "$(ps -A | wc -l | tr -d ' ')" count
)
printf '%s\n' "$out"
if [ "${1:-}" = --save ]; then
  mkdir -p "$HOME/.local/state/snappy"
  ts=$(date '+%Y-%m-%dT%H:%M:%S')
  printf '%s\n' "$out" | while IFS= read -r l; do printf '%s\t%s\n' "$ts" "$l"; done >> "$HOME/.local/state/snappy/bench.tsv"
fi
