#!/bin/bash
# VPN state from `scutil --nc list`; public IP and country from ifconfig.co,
# looked up again when the VPN or network changes, or every 15 minutes.

export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/plugins/hover.sh"
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
FONT="SF Pro"
PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

if [ "$SENDER" = "mouse.exited.global" ]; then
  sketchybar --set vpn popup.drawing=off
  exit 0
fi

LIST=$(scutil --nc list 2>/dev/null | grep -E '^\*? *\(' )
VPN=$(echo "$LIST" | awk -F'"' '/\(Connected\)/{print $2; exit}')
CACHE="${TMPDIR:-/tmp}/sketchybar_ip"

# Cache line: vpn-name|ip|country|city
IFS='|' read -r C_VPN IP CC CITY < "$CACHE" 2>/dev/null
if [ "$C_VPN" != "$VPN" ] || [ -z "$IP" ] || [ "$SENDER" = "wifi_change" ] || \
   [ "$SENDER" = "system_woke" ] || [ -z "$(find "$CACHE" -mmin -15 2>/dev/null)" ]; then
  [ "$SENDER" = "wifi_change" ] || [ "$C_VPN" != "$VPN" ] && sleep 2   # let routes settle
  # ifconfig.co first; ipinfo.io as the fallback (it rate-limits shared IPs)
  JSON=$(curl -s --max-time 4 https://ifconfig.co/json)
  IP=$(echo "$JSON" | jq -r '.ip // empty' 2>/dev/null)
  CC=$(echo "$JSON" | jq -r '.country_iso // empty' 2>/dev/null)
  if [ -z "$IP" ]; then
    JSON=$(curl -s --max-time 4 https://ipinfo.io/json)
    IP=$(echo "$JSON" | jq -r '.ip // empty' 2>/dev/null)
    CC=$(echo "$JSON" | jq -r '.country // empty' 2>/dev/null)
  fi
  CITY=$(echo "$JSON" | jq -r '.city // empty' 2>/dev/null)
  echo "$VPN|$IP|$CC|$CITY" > "$CACHE"
fi

if [ -n "$VPN" ]; then
  sketchybar --set vpn icon=$LOCK_FILL icon.color=$GREEN label="$CC" label.color=$GREEN
elif [ -n "$IP" ]; then
  sketchybar --set vpn icon=$GLOBE icon.color=$WHITE label="$CC" label.color=$GREY
else
  sketchybar --set vpn icon=$GLOBE icon.color=$GREY label="" label.color=$GREY
fi

[ "$SENDER" = "click" ] || exit 0

# Popup: status, public IP (click copies), place, then one row per VPN service
row=(icon.font="$FONT:Regular:14.0" icon.width=26 label.font="$FONT:Semibold:13.0"
     padding_left=8 padding_right=12)
args=(--remove '/vpn\.row\..*/')
add() { args+=(--add item vpn.row.$1 popup.vpn --set vpn.row.$1 "${row[@]}" "${@:2}"); }

if [ -n "$VPN" ]; then add status icon=$LOCK_FILL icon.color=$GREEN label="Connected: $VPN" label.font="$FONT:Bold:13.0"
else                    add status icon=$GLOBE icon.color=$GREY label="No VPN" label.font="$FONT:Bold:13.0"; fi
add ip icon=$COPY icon.color=$GREY label="${IP:-No public IP}" \
       click_script="printf %s '$IP' | pbcopy; sketchybar --set vpn popup.drawing=off"
[ -n "$CITY$CC" ] && add place icon=$GLOBE icon.color=$GREY label="${CITY:+$CITY, }$CC"

N=0
while IFS= read -r line; do
  NAMEV=$(echo "$line" | awk -F'"' '{print $2}')
  [ -z "$NAMEV" ] && continue
  echo "$line" | grep -q 'VPN' || continue
  if echo "$line" | grep -q '(Connected)'; then
    add svc$N icon=$LOCK_FILL icon.color=$RED label="Disconnect $NAMEV" \
        click_script="scutil --nc stop '$NAMEV'; sketchybar --set vpn popup.drawing=off; sleep 4; NAME=vpn SENDER=routine $PLUGIN_DIR/vpn.sh"
  else
    add svc$N icon=$LOCK_FILL icon.color=$GREEN label="Connect $NAMEV" \
        click_script="scutil --nc start '$NAMEV'; sketchybar --set vpn popup.drawing=off; sleep 6; NAME=vpn SENDER=routine $PLUGIN_DIR/vpn.sh"
  fi
  N=$((N+1))
done <<< "$LIST"

sketchybar "${args[@]}" >/dev/null 2>&1
"$PLUGIN_DIR/popup.sh" vpn toggle
