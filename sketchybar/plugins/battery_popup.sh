#!/bin/bash
# The battery popup (Omarchy 4.5 power panel). Items are made in items/battery.sh.
#   battery_popup.sh toggle   open or close it (battery click_script); while open it refreshes every 5 s
#   battery_popup.sh fill     refresh the rows once
#   battery_popup.sh set 1|0  Low Power Mode on or off (needs plugins' sudoers rule, see sudoers/)
# As a row script it handles mouse.entered / mouse.exited on the two profile rows.
# Every value is read from the machine; nothing here is invented.

export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

STATE="${TMPDIR:-/tmp}/sketchybar_battery_popup"
mkdir -p "$STATE"

popup_open() { [ "$(sketchybar --query battery 2>/dev/null | jq -r '.popup.drawing')" = "on" ]; }

# Profile rows: the active one is filled with the accent, a hover shows the quiet pill
paint_profiles() {
  local lpm=$1 saver=$TRANSPARENT bal=$TRANSPARENT
  [ "$lpm" = 1 ] && saver=$ACCENT_FILL || bal=$ACCENT_FILL
  echo "$lpm" > "$STATE/lpm"
  sketchybar --set battery.prof.saver background.drawing=on background.color=$saver \
             --set battery.prof.bal   background.drawing=on background.color=$bal
}

fill() {
  local io pm lpm
  io=$(ioreg -rn AppleSmartBattery)
  pm=$(pmset -g batt)
  lpm=$(pmset -g | awk '/lowpowermode/ {print $2; exit}')
  [ "$lpm" = 1 ] || lpm=0
  # The numbers, from ioreg (mAh and mV on this Mac)
  local key
  key() { echo "$io" | sed -n "s/^ *\"$1\" = \([0-9]*\)$/\1/p" | head -1; }
  local max design raw volt cycles ext chg full
  max=$(key MaxCapacity); design=$(key DesignCapacity); raw=$(key AppleRawMaxCapacity)
  volt=$(key Voltage); cycles=$(key CycleCount)
  ext=$(echo "$io" | sed -n 's/^ *"ExternalConnected" = \(.*\)$/\1/p' | head -1)
  chg=$(echo "$io" | sed -n 's/^ *"IsCharging" = \(.*\)$/\1/p' | head -1)
  full=$(echo "$io" | sed -n 's/^ *"FullyCharged" = \(.*\)$/\1/p' | head -1)
  [ -n "$max" ] && [ "$max" -le 100 ] && [ -n "$raw" ] && max=$raw   # Apple silicon reports % in MaxCapacity

  local pct line
  line=$(echo "$pm" | grep -m1 InternalBattery)
  pct=$(echo "$line" | grep -Eo '[0-9]+%' | head -1 | tr -d %)
  [ -z "$pct" ] && return 0

  # State. THRESHOLD only when macOS is holding the charge: plugged in, not charging, not full, below 100%.
  local sub state tlabel tval
  if [ "$ext" = Yes ] && [ "$chg" = No ] && [ "$full" != Yes ] && [ "$pct" -lt 99 ]; then
    sub=THRESHOLD; state=Holding; tlabel="Charge limit"; tval="${pct}%"
  elif [ "$ext" = Yes ] && { [ "$chg" = Yes ] || echo "$line" | grep -q "finishing charge"; }; then
    sub=CHARGING; state=Charging; tlabel="Time to full"
  elif [ "$ext" = Yes ]; then
    sub="FULLY CHARGED"; state="Fully charged"; tlabel="Time to full"; tval="—"
  else
    sub="ON BATTERY"; state=Discharging; tlabel="Time left"
  fi
  if [ -z "$tval" ]; then
    local hm
    hm=$(echo "$line" | grep -Eo '[0-9]+:[0-9]+ remaining' | cut -d' ' -f1)
    if [ -z "$hm" ] || [ "$hm" = "0:00" ]; then
      echo "$line" | grep -q "no estimate" && tval="Calculating…" || tval="—"
    else
      tval="${hm%%:*}h ${hm##*:}m"
    fi
  fi

  local wh health icon fillc
  wh=$(awk -v m="$max" -v v="$volt" 'BEGIN { if (m>0 && v>0) printf "%.1f Wh", m*v/1000000; else print "—" }')
  health=$(awk -v m="$max" -v d="$design" 'BEGIN { if (m>0 && d>0) printf "%d%%", m*100/d+0.5; else print "—" }')

  fillc=$WHITE
  [ "$pct" -lt 40 ] && fillc=$ORANGE
  [ "$pct" -lt 20 ] && fillc=$RED
  case $sub in
    CHARGING) icon=$BATTERY_CHARGING; fillc=$GREEN ;;
    "FULLY CHARGED") icon=$BATTERY_CHARGING; fillc=$GREEN ;;
    *) if [ "$pct" -ge 90 ]; then icon=$BATTERY_100; elif [ "$pct" -ge 60 ]; then icon=$BATTERY_75
       elif [ "$pct" -ge 40 ]; then icon=$BATTERY_50; elif [ "$pct" -ge 20 ]; then icon=$BATTERY_25
       else icon=$BATTERY_0; fi ;;
  esac

  sketchybar --set battery.head icon="$icon" icon.color=$fillc                  \
             --set battery.sub label="$sub"                                     \
             --set battery.pct label="${pct}%"                                  \
             --set battery.bar slider.percentage=$pct slider.highlight_color=$fillc \
             --set battery.size label="$wh"                                     \
             --set battery.cycles label="${cycles:-—}"                          \
             --set battery.time icon="$tlabel" label="$tval"                    \
             --set battery.state label="$state"                                 \
             --set battery.health label="$health"
  paint_profiles "$lpm"
}

set_mode() { # set_mode 1|0
  if sudo -n /usr/bin/pmset -a lowpowermode "$1" >/dev/null 2>&1; then
    sketchybar --set battery.err drawing=off
    fill
  else
    sketchybar --set battery.err drawing=on
    ( sleep 6; sketchybar --set battery.err drawing=off ) >/dev/null 2>&1 &
  fi
}

loop() {
  local pidfile="$STATE/loop.pid" old
  old=$(cat "$pidfile" 2>/dev/null)
  if [ -n "$old" ] && kill -0 "$old" 2>/dev/null; then exit 0; fi
  echo $$ > "$pidfile"
  while popup_open; do
    fill
    local i; for i in 1 2 3 4 5; do sleep 1; popup_open || break; done
  done
}

# Row script: hover on a profile row
case "$SENDER" in
  mouse.entered|mouse.exited)
    read -r lpm < "$STATE/lpm" 2>/dev/null
    [ "$NAME" = battery.prof.saver ] && on=1 || on=0
    if [ "$SENDER" = mouse.entered ]; then
      sketchybar --set "$NAME" background.color=$HOVER_COLOR
    elif [ "$lpm" = "$on" ]; then
      sketchybar --set "$NAME" background.color=$ACCENT_FILL
    else
      sketchybar --set "$NAME" background.color=$TRANSPARENT
    fi
    exit 0 ;;
esac

case "$1" in
  toggle)
    if popup_open; then
      "$HOME/.config/sketchybar/plugins/popup.sh" battery off
    else
      fill
      "$HOME/.config/sketchybar/plugins/popup.sh" battery on
      nohup "$0" loop >/dev/null 2>&1 &
    fi ;;
  fill) fill ;;
  set)  set_mode "$2" ;;
  loop) loop ;;
esac
