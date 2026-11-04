#!/bin/bash
# Control centre actions. With an argument (wifi, bluetooth, dark, awake,
# battery, health, settings) it acts on that; with none, or "refresh", it redraws the rows.

export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

HELPER="$HOME/.config/sketchybar/helper"

wifi_power() { networksetup -getairportpower en0 | awk '{print tolower($NF)}'; }
dark_on()    { [ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" = "Dark" ] && echo on || echo off; }
# A command-line tool can't switch Bluetooth on macOS 15 (privacy check aborts it),
# so the row reads the state and its click opens Bluetooth settings.
bt_on()      { system_profiler SPBluetoothDataType 2>/dev/null | grep -m1 -q 'State: On' && echo on || echo off; }
# Active Focus name, or "off". Reads the Focus store (needs Full Disk Access for SketchyBar).
focus_name() {
  local db="$HOME/Library/DoNotDisturb/DB" id
  [ -r "$db/Assertions.json" ] || { echo unknown; return; }
  id=$(jq -r '.data[0].storeAssertionRecords[0].assertionDetails.assertionDetailsModeIdentifier // empty' "$db/Assertions.json" 2>/dev/null)
  [ -z "$id" ] && { echo off; return; }
  jq -r --arg id "$id" '.data[0].modeConfigurations[$id].mode.name // "On"' "$db/ModeConfigurations.json" 2>/dev/null || echo On
}
awake_on()   { pgrep -qf 'caffeinate -dis' && echo on || echo off; }

row() { # row <name> <state> <label>
  local color=$GREY
  [ "$2" = "on" ] && color=$GREEN
  args+=(--set control.$1 icon.color=$color label="$3")
}

refresh() {
  args=()
  W=$(wifi_power); row wifi "$W" "Wi-Fi  $( [ "$W" = on ] && echo On || echo Off )"
  B=$(bt_on); row bluetooth "$B" "Bluetooth  $( [ "$B" = on ] && echo On || echo Off )"
  F=$(focus_name)
  case $F in
    off)     row focus off "Focus  Off" ;;
    unknown) row focus off "Focus…" ;;
    *)       row focus on "Focus  $F" ;;
  esac
  D=$(dark_on);  row dark  "$D" "Dark Mode  $( [ "$D" = on ] && echo On || echo Off )"
  A=$(awake_on); row awake "$A" "Keep Awake  $( [ "$A" = on ] && echo On || echo Off )"
  if [ "$A" = on ]; then args+=(--set control.awake icon=$AWAKE); else args+=(--set control.awake icon=$AWAKE_OFF); fi
  battery_rows
  B=$("$HELPER/brightness" 2>/dev/null)
  [ -n "$B" ] && [ "$B" -ge 0 ] 2>/dev/null && args+=(--set control.brightness slider.percentage=$B)
  sketchybar "${args[@]}"
}

# Charge, state and time left; then health and cycle count. Read only while the popup is open.
battery_rows() {
  local batt pct state left icon=$BATTERY_75 color=$GREEN
  batt=$(pmset -g batt)
  pct=$(echo "$batt" | grep -Eo '[0-9]+%' | head -1 | tr -d %)
  if [ -z "$pct" ]; then args+=(--set control.battery drawing=off --set control.health drawing=off); return; fi
  left=$(echo "$batt" | grep -Eo '[0-9]+:[0-9]+ remaining' | cut -d' ' -f1)
  if echo "$batt" | grep -q 'AC Power'; then
    icon=$BATTERY_CHARGING
    if echo "$batt" | grep -q '; charging'; then state="Charging${left:+ · $left to full}"; else state="Plugged in"; fi
  else
    state="${left:+$left left}"; state=${state:-On battery}
    case $pct in [3-5][0-9]) icon=$BATTERY_50 ;; [1-2][0-9]) icon=$BATTERY_25; color=$ORANGE ;; [0-9]) icon=$BATTERY_0; color=$RED ;; esac
  fi
  [ "$pct" -ge 90 ] && [ "$icon" != "$BATTERY_CHARGING" ] && icon=$BATTERY_100
  args+=(--set control.battery icon=$icon icon.color=$color label="Battery  $pct% · $state")
  local io max design cycles health
  io=$(ioreg -rn AppleSmartBattery)
  max=$(echo "$io" | awk -F'= ' '/"AppleRawMaxCapacity" =/{print $2; exit}')
  design=$(echo "$io" | awk -F'= ' '/"DesignCapacity" =/{print $2; exit}')
  cycles=$(echo "$io" | awk -F'= ' '/"CycleCount" =/{print $2; exit}')
  if [ -n "$max" ] && [ -n "$design" ] && [ "$design" -gt 0 ]; then
    health=$(( max * 100 / design ))
    args+=(--set control.health label="Health  $health% · ${cycles:-?} cycles")
  else
    args+=(--set control.health drawing=off)
  fi
}

case "$1" in
  wifi)
    if [ "$(wifi_power)" = "on" ]; then networksetup -setairportpower en0 off
    else networksetup -setairportpower en0 on; fi
    sketchybar --trigger wifi_change ;;
  bluetooth)
    sketchybar --set control popup.drawing=off
    open "x-apple.systempreferences:com.apple.BluetoothSettings"
    exit 0 ;;
  dark)
    osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to not dark mode' ;;
  awake)
    if [ "$(awake_on)" = "on" ]; then pkill -f 'caffeinate -dis'
    else nohup caffeinate -dis >/dev/null 2>&1 & disown; fi ;;
  focus)
    # Runs your "Toggle Focus" shortcut if you made one; otherwise opens Focus settings.
    if shortcuts list 2>/dev/null | grep -qx "Toggle Focus"; then
      shortcuts run "Toggle Focus"; sleep 1
    else
      sketchybar --set control popup.drawing=off
      open "x-apple.systempreferences:com.apple.Focus-Settings.extension"
      exit 0
    fi ;;
  battery|health)
    sketchybar --set control popup.drawing=off
    open "x-apple.systempreferences:com.apple.Battery-Settings.extension"
    exit 0 ;;
  settings)
    sketchybar --set control popup.drawing=off
    open -a "System Settings"
    exit 0 ;;
esac

if [ "$SENDER" = "mouse.exited.global" ]; then
  sketchybar --set control popup.drawing=off
  exit 0
fi

refresh
