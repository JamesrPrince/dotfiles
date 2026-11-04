#!/bin/bash
# Wi-Fi icon and popup. Signal: green above -60 dBm, yellow above -70, orange below.

export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

if [ "$SENDER" = "mouse.exited.global" ]; then
  sketchybar --set wifi popup.drawing=off
  exit 0
fi

read -r POWER RSSI NOISE RATE SSID <<< "$("$HOME/.config/sketchybar/helper/wifi" 2>/dev/null)"
IP=$(ipconfig getifaddr en0)

# macOS 15 hides the network name from the helper without Location access;
# ipconfig shows it once `sudo ipconfig setverbose 1` has been run.
if [ -z "$SSID" ]; then
  SSID=$(ipconfig getsummary en0 | awk -F ' SSID : ' '/ SSID : /{print $2; exit}')
fi
[ -z "$SSID" ] || [ "$SSID" = "<redacted>" ] && SSID="Wi-Fi"

if [ "$POWER" != "on" ]; then
  ICON=$WIFI_OFF; COLOR=$GREY; TOGGLE="Turn Wi-Fi On"; TOGGLE_ICON=$WIFI; TOGGLE_COLOR=$GREEN
elif [ -z "$IP" ]; then
  ICON=$WIFI_OFF; COLOR=$RED; TOGGLE="Turn Wi-Fi Off"; TOGGLE_ICON=$WIFI_OFF; TOGGLE_COLOR=$RED
else
  ICON=$WIFI; TOGGLE="Turn Wi-Fi Off"; TOGGLE_ICON=$WIFI_OFF; TOGGLE_COLOR=$RED
  if [ "${RSSI:-0}" -ge -60 ]; then COLOR=$GREEN
  elif [ "${RSSI:-0}" -ge -70 ]; then COLOR=$YELLOW
  else COLOR=$ORANGE; fi
fi

args=(--set wifi icon=$ICON icon.color=$COLOR
      --set wifi.toggle label="$TOGGLE" icon=$TOGGLE_ICON icon.color=$TOGGLE_COLOR)

if [ "$POWER" = "on" ] && [ -n "$IP" ]; then
  ROUTER=$(route -n get default 2>/dev/null | awk '/gateway:/{print $2}')
  args+=(--set wifi.ssid label="$SSID" drawing=on
         --set wifi.ip label="IP $IP" drawing=on
         --set wifi.router label="Router ${ROUTER:--}" drawing=on
         --set wifi.signal label="Signal ${RSSI} dBm · ${RATE} Mbps" drawing=on)
else
  args+=(--set wifi.ssid label="Not connected" drawing=on
         --set wifi.ip drawing=off --set wifi.router drawing=off --set wifi.signal drawing=off)
fi

sketchybar "${args[@]}"
