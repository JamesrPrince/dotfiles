#!/bin/bash
# Speed test row of the Wi-Fi popup, run with macOS's built-in networkQuality.
#   wifi_speed.sh run     the row's click: starts a test (a click while one runs does nothing)
#   wifi_speed.sh render  redraws the two rows from the last result (wifi.sh calls it)
# Never runs on its own: a test uses real data, so the row says so on a phone hotspot.

export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

STATE="${TMPDIR:-/tmp}/sketchybar_wifi"
LOCK="${STATE}_speed.lock"      # present while a test runs
RESULT="${STATE}_speed_result"  # last result: "<label>" (one line)
HOURGLASS=$'\xf4\x80\x96\x87'   # hourglass

# Phone hotspot: an iPhone hands out 172.20.10.x, an Android hotspot says "ANDROID_METERED" in
# its DHCP reply, and the saved names give away the rest.
is_hotspot() {
  local gw ssid
  gw=$(route -n get default 2>/dev/null | awk '/gateway:/{print $2}')
  case $gw in 172.20.10.*) return 0 ;; esac
  ipconfig getpacket en0 2>/dev/null | grep -qi 'android' && return 0
  ssid=$(ipconfig getsummary en0 2>/dev/null | awk -F ' SSID : ' '/ SSID : /{print $2; exit}')
  printf '%s' "$ssid" | grep -qiE "iphone|ipad|hotspot|galaxy|infinix|tecno|android|pixel|redmi|xiaomi|oneplus|samsung|(^|[^A-Za-z])S[0-9]+" && return 0
  return 1
}

render() {
  local label="Test speed" args=()
  is_hotspot && label="Test speed (uses mobile data)"
  if [ -d "$LOCK" ]; then
    args+=(--set wifi.speed drawing=on icon="$HOURGLASS" icon.color=$GREY label="Testing…" label.color=$GREY click_script="")
  else
    args+=(--set wifi.speed drawing=on icon=$BOLT icon.color=$BLUE label="$label" label.color=$LABEL_COLOR
           click_script="$HOME/.config/sketchybar/plugins/wifi_speed.sh run")
  fi
  if [ -s "$RESULT" ]; then args+=(--set wifi.speed.result drawing=on label="$(cat "$RESULT")")
  else args+=(--set wifi.speed.result drawing=off); fi
  sketchybar "${args[@]}"
}

run() {
  find "$LOCK" -maxdepth 0 -mmin +3 -exec rmdir {} \; 2>/dev/null   # a lock left by a killed test
  mkdir "$LOCK" 2>/dev/null || exit 0                               # already running
  render
  local json dl ul rpm
  json=$(networkQuality -c 2>/dev/null)
  dl=$(printf '%s' "$json" | jq -r '.dl_throughput // empty' 2>/dev/null)
  ul=$(printf '%s' "$json" | jq -r '.ul_throughput // empty' 2>/dev/null)
  rpm=$(printf '%s' "$json" | jq -r '.responsiveness // empty' 2>/dev/null)
  if [ -n "$dl" ] && [ -n "$ul" ]; then
    printf '↓ %d · ↑ %d Mbps · RPM %d · %s\n' \
      "$(awk -v v="$dl" 'BEGIN{printf "%d", v/1000000+0.5}')" "$(awk -v v="$ul" 'BEGIN{printf "%d", v/1000000+0.5}')" \
      "$(awk -v v="${rpm:-0}" 'BEGIN{printf "%d", v+0.5}')" "$(date +%H:%M)" > "$RESULT"
  else
    printf 'Test failed · %s\n' "$(date +%H:%M)" > "$RESULT"
  fi
  rmdir "$LOCK" 2>/dev/null
  render
}

case "$1" in
  run) run ;;
  render) render ;;
  *) echo "usage: wifi_speed.sh run|render" >&2; exit 2 ;;
esac
