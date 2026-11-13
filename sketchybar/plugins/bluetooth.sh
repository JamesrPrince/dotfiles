#!/bin/bash
# Bluetooth icon and popup, through the SketchyBarBluetooth.app helper (helper/btctl.swift).
#   (no argument)       sketchybar event: refresh the icon and popup
#   power               toggle Bluetooth power
#   connect <address>   connect or disconnect that device
#   access              ask for (or open the settings of) the Bluetooth permission
# Icon: grey when off, white when on, blue when a device is connected.
#
# macOS gives Bluetooth to apps, not to command-line tools started by AeroSpace, so the
# helper is a small app with its own permission. Until it is allowed
# (open ~/.config/sketchybar/helper/SketchyBarBluetooth.app) the popup falls back to a
# read-only list from system_profiler plus a "Needs Bluetooth access" row.

export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/plugins/hover.sh"
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

FONT="SF Pro"          # glyph icons (SF Symbols)
source "$HOME/.config/sketchybar/plugins/style.sh"   # TEXT_FONT: Nunito, or Maple Mono NF in the flat style
BT_FONT="MesloLGS NF"  # Bluetooth glyphs (Nerd Font)
BT_APP="${BT_APP:-$HOME/.config/sketchybar/helper/SketchyBarBluetooth.app}"   # override only to test the fallback
STATE="${TMPDIR:-/tmp}/sketchybar_bluetooth_state"
AUTH_FILE="${TMPDIR:-/tmp}/sketchybar_bluetooth_auth"
PRIVACY_PANE="x-apple.systempreferences:com.apple.preference.security?Privacy_Bluetooth"

if [ "$SENDER" = "mouse.exited.global" ]; then
  sketchybar --set bluetooth popup.drawing=off
  exit 0
fi

# bt_helper <args>: runs the app and prints its JSON; prints nothing if it hangs (10 s) or fails
bt_helper() {
  local out="${TMPDIR:-/tmp}/sketchybar_bluetooth_out.$$" pid
  rm -f "$out"
  open -g -W --stdout "$out" "$BT_APP" --args "$@" >/dev/null 2>&1 &
  pid=$!
  ( sleep 10; kill $pid 2>/dev/null ) >/dev/null 2>&1 &
  wait $pid 2>/dev/null
  tail -n 1 "$out" 2>/dev/null
  rm -f "$out"
}

# needs_access: the click on the "Needs Bluetooth access" row, or on any control while blocked.
# Not yet asked: opens the app (its Allow prompt is the user's to answer). Denied: the settings pane.
needs_access() {
  if [ "$(cat "$AUTH_FILE" 2>/dev/null)" = "undetermined" ]; then open "$BT_APP"; else open "$PRIVACY_PANE"; fi
}

JSON=""
case "$1" in
  access)
    needs_access
    exit 0
    ;;
  power)
    JSON=$(bt_helper status)
    if [ "$(jq -r '.auth' <<< "$JSON" 2>/dev/null)" != "allowed" ]; then
      jq -r '.auth' <<< "$JSON" > "$AUTH_FILE" 2>/dev/null
      needs_access; exit 0
    fi
    [ "$(jq -r '.power' <<< "$JSON")" = "true" ] && JSON=$(bt_helper power off) || JSON=$(bt_helper power on)
    rm -f "$STATE"
    ;;
  connect)
    JSON=$(bt_helper status)
    if [ "$(jq -r '.auth' <<< "$JSON" 2>/dev/null)" != "allowed" ]; then
      jq -r '.auth' <<< "$JSON" > "$AUTH_FILE" 2>/dev/null
      needs_access; exit 0
    fi
    sketchybar --set bluetooth popup.drawing=off
    if [ "$(jq -r --arg a "$2" '.devices[] | select(.address == $a) | .connected' <<< "$JSON")" = "true" ]; then
      JSON=$(bt_helper disconnect "$2")
    else
      JSON=$(bt_helper connect "$2")
    fi
    rm -f "$STATE"
    ;;
  *)
    JSON=$(bt_helper status)
    ;;
esac

# Full mode: the helper answered with auth "allowed". Read-only mode: system_profiler.
MODE=full
AUTH=$(jq -r '.auth // empty' <<< "$JSON" 2>/dev/null)
if [ "$AUTH" = "allowed" ]; then
  [ "$(jq -r '.power' <<< "$JSON")" = "true" ] && POWER=1 || POWER=0
  DEVICES=$(jq -r '.devices | sort_by([(.connected | not), (.name | ascii_downcase)])[] | "\(.address)|\(.connected)|\(.name)"' <<< "$JSON")
else
  MODE=readonly
  echo "${AUTH:-unknown}" > "$AUTH_FILE"
  PROFILE=$(system_profiler SPBluetoothDataType -json 2>/dev/null)
  if [ "$(jq -r '.SPBluetoothDataType[0].controller_properties.controller_state' <<< "$PROFILE")" = "attrib_on" ]; then
    POWER=1
  else
    POWER=0
  fi
  DEVICES=$(jq -r '.SPBluetoothDataType[0] |
      ([(.device_connected // [])[] | to_entries[] | [.value.device_address, "true", .key]] +
       [(.device_not_connected // [])[] | to_entries[] | [.value.device_address, "false", .key]])
      | sort_by([(.[1] == "false"), (.[2] | ascii_downcase)])[]
      | "\(.[0] | ascii_downcase | gsub(":"; "-"))|\(.[1])|\(.[2])"' <<< "$PROFILE")
fi

args=()
if [ "$MODE" = readonly ]; then
  if [ "$AUTH" = "denied" ]; then NOTE="Bluetooth access denied: open settings"; else NOTE="Click to allow Bluetooth access"; fi
  args+=(--set bluetooth.note drawing=on label="$NOTE")
else
  args+=(--set bluetooth.note drawing=off)
fi

if [ "$POWER" != "1" ]; then
  new="$MODE:off"
  args+=(--set bluetooth icon=$BLUETOOTH_OFF icon.color=$GREY
         --set bluetooth.power icon=$BT_POWER icon.color=$GREEN label="Turn Bluetooth On")
  DEVICES=""
else
  CONNECTED=$(grep -c '|true|' <<< "$DEVICES")
  if [ "$CONNECTED" -gt 0 ]; then BAR_ICON=$BLUETOOTH_CONNECTED COLOR=$BLUE; else BAR_ICON=$BLUETOOTH_ICON COLOR=$WHITE; fi
  args+=(--set bluetooth icon=$BAR_ICON icon.color=$COLOR
         --set bluetooth.power icon=$BT_POWER icon.color=$RED label="Turn Bluetooth Off")
  new="$MODE:on:$DEVICES"
fi

# Rebuild the device rows only when something changed, so the popup does not flicker
if [ "$(cat "$STATE" 2>/dev/null)" != "$new" ]; then
  echo "$new" > "$STATE"
  sketchybar --remove '/bluetooth\.dev\..*/' >/dev/null 2>&1
  n=0
  while IFS='|' read -r addr connected name; do
    [ -n "$addr" ] || continue
    if [ "$connected" = "true" ]; then
      icon=$BLUETOOTH_CONNECTED; icon_color=$GREEN; label_color=$WHITE; font="$TEXT_FONT:Bold:13.0"
    else
      icon=$BLUETOOTH_ICON; icon_color=$GREY; label_color=$GREY; font="$TEXT_FONT:SemiBold:13.0"
    fi
    row="bluetooth.dev.$n"
    args+=(--add item $row popup.bluetooth
           --set $row icon=$icon icon.color=$icon_color icon.font="$BT_FONT:Regular:15.0" icon.width=26
                      label="$name" label.color=$label_color label.font="$font" label.max_chars=32
                      padding_left=8 padding_right=12 background.corner_radius=7
                      script="$HOME/.config/sketchybar/plugins/hover.sh"
                      click_script="$HOME/.config/sketchybar/plugins/bluetooth.sh connect $addr"
           --subscribe $row mouse.entered mouse.exited)
    n=$((n+1))
  done <<< "$DEVICES"
fi

sketchybar "${args[@]}"
