#!/bin/bash
# The "more" item: fills its popup rows (timer, GitHub, disk) and shows a red dot on the
# item when something needs attention: GitHub unread, a timer running or finished, low disk.
# Runs every 10s and when the popup opens. Usage as a click script: more.sh timer

export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/plugins/hover.sh"
source "$HOME/.config/sketchybar/colors.sh"

TIMER_STATE="${TMPDIR:-/tmp}/sketchybar_timer"
TIMER_DONE="${TMPDIR:-/tmp}/sketchybar_timer_done"
LIMIT_GB=${LIMIT_GB:-20}

if [ "$SENDER" = "mouse.exited.global" ]; then
  sketchybar --set more popup.drawing=off
  exit 0
fi

# Click on the timer row: clear a finished timer, else start 25 min (right-click 50) or stop
if [ "$1" = "timer" ]; then
  if [ -f "$TIMER_DONE" ]; then
    rm -f "$TIMER_DONE"
  else
    NAME=timer SENDER=mouse.clicked BUTTON=$BUTTON "$HOME/.config/sketchybar/plugins/timer.sh"
  fi
fi

alert=0
args=()

# Timer
if [ -f "$TIMER_STATE" ]; then
  left=$(( $(cat "$TIMER_STATE") - $(date +%s) ))
  [ "$left" -lt 0 ] && left=0
  args+=(--set more.timer icon.color=$YELLOW label="$(printf 'Timer  %d:%02d left   click to stop' $((left / 60)) $((left % 60)))")
  alert=1
elif [ -f "$TIMER_DONE" ]; then
  args+=(--set more.timer icon.color=$RED label="Timer finished   click to clear")
  alert=1
else
  args+=(--set more.timer icon.color=$GREY label="Start a 25 min timer   right-click: 50")
fi

# GitHub: the hidden github item keeps the unread count
read -r gh_on gh_count <<< "$(sketchybar --query github | jq -r '[.label.drawing, .label.value] | @tsv')"
if [ "$gh_on" = "on" ] && [ "${gh_count:-0}" -gt 0 ] 2>/dev/null; then
  args+=(--set more.github icon.color=$WHITE label="GitHub   $gh_count unread" label.color=$RED)
  alert=1
else
  args+=(--set more.github icon.color=$GREY label="GitHub   nothing unread" label.color=$GREY)
fi

# Disk
free_gb=$(df -g / | awk 'NR==2{print $4}')
if [ "$free_gb" -lt "$LIMIT_GB" ]; then
  args+=(--set more.disk icon.color=$RED label="Disk   ${free_gb} GB free, low" label.color=$RED)
  alert=1
else
  args+=(--set more.disk icon.color=$GREY label="Disk   ${free_gb} GB free" label.color=$LABEL_COLOR)
fi

# Zen mode keeps the dot hidden
[ -f "${TMPDIR:-/tmp}/sketchybar_zen" ] && alert=0
if [ "$alert" = 1 ]; then args+=(--set more label.drawing=on); else args+=(--set more label.drawing=off); fi

sketchybar "${args[@]}"
