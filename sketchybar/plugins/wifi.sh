#!/bin/bash
# Wi-Fi icon and popup. Signal: green above -60 dBm, yellow above -70, orange below.
# While the popup is open it also lists the saved networks (networksetup) and, once
# helper/SketchyBarWiFi.app has Location access, the real network name and a scan of
# nearby networks, with advice on channel congestion; the connected channel shows without it.
# Without that access the popup shows the saved list, the channel and today's status only.

export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/plugins/hover.sh"
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
[ "$SSID" = "<redacted>" ] && SSID=""
CUR=$SSID   # the connected network's name, or empty when it is not known
[ -z "$SSID" ] && SSID="Wi-Fi"

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

# ---- Networks: saved, nearby, channel and advice ----------------------------------
WIFI_APP="$HOME/.config/sketchybar/helper/SketchyBarWiFi.app"
STATE="${TMPDIR:-/tmp}/sketchybar_wifi"
SCAN_F="${STATE}_scan"          # last scan output, whatever the Location state was
LOCK_D="${STATE}_scan.lock"
SAVED_CAP=8; SAVED_CAP_SCAN=4; NEAR_CAP=5   # keeps the popup near 20 rows
CHECK=$'\xf4\x80\x86\x85'   # SF Symbols checkmark, defined here so icons.sh stays untouched
CONNECTED=0; [ "$POWER" = "on" ] && [ -n "$IP" ] && CONNECTED=1

hide_networks() {
  local a=(--set wifi.hdr.saved drawing=off --set wifi.hdr.near drawing=off
           --set wifi.channel drawing=off --set wifi.advice drawing=off
           --set wifi.speed drawing=off --set wifi.speed.result drawing=off) i
  for i in 1 2 3 4 5 6 7 8; do a+=(--set wifi.saved.$i drawing=off); done
  for i in 1 2 3 4 5; do a+=(--set wifi.near.$i drawing=off); done
  sketchybar "${a[@]}"
}

in_near() { local n; for n in ${NEAR_NAME[@]+"${NEAR_NAME[@]}"}; do [ "$n" = "$1" ] && return 0; done; return 1; }
in_saved() { local n; for n in ${ALL_SAVED[@]+"${ALL_SAVED[@]}"}; do [ "$n" = "$1" ] && return 0; done; return 1; }

signal_color() { # signal_color <rssi>
  if [ "${1:-0}" -ge -60 ]; then echo $GREEN
  elif [ "${1:-0}" -ge -70 ]; then echo $YELLOW
  else echo $ORANGE; fi
}

band_name() { case $1 in 1) echo "2.4 GHz" ;; 2) echo "5 GHz" ;; 3) echo "6 GHz" ;; *) echo "" ;; esac; }

# Channel congestion, from the scan. Each access point adds its signal strength (rssi + 95, so a
# strong one counts about 50) to everything it occupies, and the router's own access point is left out.
#  - 2.4 GHz: channels sit 5 apart and an AP spans about 4 channels either side of its own (6 with a
#    40 MHz AP), so a neighbour on 3 also loads 1 and 6; only 1, 6 and 11 are offered.
#  - 5 and 6 GHz: an AP fills its whole bonded block (20, 40, 80 or 160 MHz: 36-48, 52-64, 100-112,
#    116-128, 132-144, 149-161 for 80 MHz). A block is scored at the router's own width as the average
#    load over its 20 MHz channels, and recommended by its first channel.
CHAN_AWK='
function blk(c, n,   base, step) {
  base = (band == 3) ? 1 : (c <= 64 ? 36 : (c <= 144 ? 100 : 149))
  step = 4 * n
  return base + int((c - base) / step) * step
}
function dfs(bs, n) { return band == 2 && bs <= 144 && bs + 4 * n - 4 >= 52 }
function score(ch, wid,   i, k, n, bs, ab, an, w, d, r, s, x) {
  s = 0
  if (band == 1) {
    for (i = 1; i <= na; i++) {
      d = Ac[i] - ch; if (d < 0) d = -d
      r = (Aw[i] >= 40) ? 7 : 5
      if (d < r) s += Ar[i] * (r - d) / r
    }
    return s
  }
  n = int(wid / 20); if (n < 1) n = 1
  bs = blk(ch, n)
  for (k = 0; k < n; k++) {
    x = bs + 4 * k
    for (i = 1; i <= na; i++) {
      an = int(Aw[i] / 20); if (an < 1) an = 1
      ab = blk(Ac[i], an)
      if (x >= ab && x <= ab + 4 * an - 4) s += Ar[i]
    }
  }
  return s / n
}
$1 == "AP" && $3 == band {
  if ($6 == xs && $4 == xc) next
  na++; Ar[na] = $2 + 95; if (Ar[na] < 0) Ar[na] = 0; Ac[na] = $4; Aw[na] = $5
}
END {
  if (mode == "score") { printf "%d", score(ch, wid); exit }
  # mode "best": cur score, then the quietest block among the supported channels
  n = int(wid / 20); if (n < 1) n = 1
  cur = score(xc, wid); cbs = (band == 1) ? xc : blk(xc, n)
  nc = split(sup, S, ","); for (i = 1; i <= nc; i++) ok[S[i]] = 1
  best = -1; bsc = 0; bpen = 0
  for (i = 1; i <= nc; i++) {
    c = S[i] + 0
    if (band == 1) { if (c != 1 && c != 6 && c != 11) continue; bs = c }
    else {
      bs = blk(c, n); if (seen[bs]++) continue
      full = 1; for (k = 0; k < n; k++) if (!ok[bs + 4 * k]) full = 0
      if (!full) continue
    }
    sc = score(bs, wid); pen = (band != 1 && dfs(bs, n)) ? 10 : 0
    if (best < 0 || sc + pen < bsc + bpen || (sc + pen == bsc + bpen && bs == cbs)) { best = bs; bsc = sc; bpen = pen }
  }
  printf "%d %d %d %d %d", cur, cbs, best, bsc, bpen
}'

# chan_score <band> <channel> <width> <own ssid> <own channel>
chan_score() {
  awk -F'\t' -v mode=score -v band="$1" -v ch="$2" -v wid="${3:-20}" -v xs="$4" -v xc="$5" "$CHAN_AWK" "$SCAN"
}

# advise: sets ADV_TEXT (empty = no advice), ADV_SSID (a network to switch to, else empty).
advise() {
  ADV_TEXT=""; ADV_SSID=""
  [ "$GRANTED" = 1 ] && [ -n "$CH_NUM" ] && [ -n "$CUR" ] || return 0
  local cur_score sc j name rssi band ch wid
  cur_score=$(chan_score "$CH_BAND" "$CH_NUM" "$CH_W" "$CUR" "$CH_NUM")

  # A saved network in range that is quieter, or on a better band, is worth switching to.
  local pick="" pick_sc=999999 pick_band=0
  for ((j=0; j<${#NEAR_NAME[@]}; j++)); do
    name=${NEAR_NAME[$j]}; rssi=${NEAR_RSSI[$j]}
    [ "$name" = "$CUR" ] && continue
    in_saved "$name" || continue
    [ "$rssi" -ge -75 ] && [ "$rssi" -ge $((RSSI-25)) ] || continue   # not much weaker than the current one
    read -r band ch wid < <(awk -F'\t' -v n="$name" '$1=="AP" && $6==n && (!f || $2>b){f=1; b=$2; band=$3; ch=$4; wid=$5} END{print band, ch, wid}' "$SCAN")
    [ -n "$ch" ] || continue
    sc=$(chan_score "$band" "$ch" "$wid" "$name" "$ch")
    if { [ "$band" -ge "$CH_BAND" ] && [ $((sc*10)) -le $((cur_score*6)) ] && [ $((cur_score-sc)) -ge 15 ]; } || \
       { [ "$CH_BAND" = 1 ] && [ "$band" -ge 2 ] && [ "$sc" -le "$cur_score" ]; }; then
      if [ "$sc" -lt "$pick_sc" ] || { [ "$sc" -eq "$pick_sc" ] && [ "$band" -gt "$pick_band" ]; }; then
        pick=$name; pick_sc=$sc; pick_band=$band
      fi
    fi
  done
  if [ -n "$pick" ]; then
    ADV_SSID=$pick
    ADV_TEXT="Switch to ${pick:0:14}$([ ${#pick} -gt 14 ] && echo …) · $(band_name "$pick_band")"
    return 0
  fi

  # Otherwise the quietest channel (block) for the router; advice only, the Mac cannot change the router.
  [ -n "$SUP" ] || [ "$CH_BAND" = 1 ] || return 0
  local sup=$SUP; [ "$CH_BAND" = 1 ] && sup="1,6,11"
  local cur cbs best bsc bpen tot note
  read -r cur cbs best bsc bpen < <(awk -F'\t' -v mode=best -v band="$CH_BAND" -v wid="${CH_W:-20}" -v xs="$CUR" -v xc="$CH_NUM" -v sup="$sup" "$CHAN_AWK" "$SCAN")
  [ -n "$best" ] || return 0
  tot=$((bsc+bpen))
  if [ "$best" != "$cbs" ] && [ $((tot*10)) -le $((cur*8)) ] && [ $((cur-tot)) -ge 8 ]; then
    note=""; [ "$CH_BAND" != 1 ] && note="${CH_W:-20} MHz"
    if [ "$bsc" -lt 5 ]; then note="${note:+$note, }clear"; fi
    ADV_TEXT="Best channel for your router: $best${note:+ ($note)}"
  else
    ADV_TEXT="Channel $CH_NUM is already the best for your router"
  fi
}

# render_networks <scan output file>: draws the channel, advice, Saved and (with Location access) Nearby.
render_networks() {
  local scan=$1 tag a b c d e s i j cap
  SCAN=$scan; GRANTED=0; CH_NUM=""; CH_BAND=""; CH_W=""; SUP=""
  NEAR_NAME=(); NEAR_RSSI=(); NEAR_LOCK=()
  if [ -s "$scan" ]; then
    while IFS=$'\t' read -r tag a b c d e; do
      case $tag in
        AUTH) [ "$a" = granted ] && GRANTED=1 ;;
        CUR)  [ $GRANTED = 1 ] && [ -n "$e" ] && CUR=$e ;;
        CH)   CH_NUM=$a; CH_BAND=$b; CH_W=$c ;;
        SUP)  SUP=$a ;;
        NET)  NEAR_RSSI+=("$a"); NEAR_LOCK+=("$b"); NEAR_NAME+=("$c") ;;
      esac
    done < "$scan"
  fi

  ALL_SAVED=()
  while IFS= read -r s; do [ -n "$s" ] && ALL_SAVED+=("$s"); done \
    < <(networksetup -listpreferredwirelessnetworks en0 2>/dev/null | sed $'1d; s/^\t//')

  local args=() icon color

  # Channel and advice, only while connected to a router.
  if [ $CONNECTED = 1 ] && [ -n "$CH_NUM" ]; then
    args+=(--set wifi.channel drawing=on label="Ch $CH_NUM · $(band_name "$CH_BAND")${CH_W:+ · $CH_W MHz}")
    advise
    if [ -n "$ADV_TEXT" ]; then
      args+=(--set wifi.advice drawing=on label="$ADV_TEXT")
      printf '%s\n' "$ADV_SSID" > "${STATE}_advice"
      if [ -n "$ADV_SSID" ]; then
        args+=(--set wifi.advice icon.color=$YELLOW script="$PLUGIN_DIR_W/hover.sh" click_script="$PLUGIN_DIR_W/wifi_join.sh advice 1")
      else
        args+=(--set wifi.advice icon.color=$GREY script="" click_script="" background.drawing=off)
      fi
    else
      args+=(--set wifi.advice drawing=off)
    fi
  else
    args+=(--set wifi.channel drawing=off --set wifi.advice drawing=off)
  fi

  # Saved: the connected one first, then those in range (when a scan is known), then the rest.
  local ordered=()
  for s in ${ALL_SAVED[@]+"${ALL_SAVED[@]}"}; do [ -n "$CUR" ] && [ "$s" = "$CUR" ] && ordered+=("$s"); done
  if [ $GRANTED = 1 ]; then
    for s in ${ALL_SAVED[@]+"${ALL_SAVED[@]}"}; do [ "$s" != "$CUR" ] && in_near "$s" && ordered+=("$s"); done
    for s in ${ALL_SAVED[@]+"${ALL_SAVED[@]}"}; do [ "$s" != "$CUR" ] && ! in_near "$s" && ordered+=("$s"); done
    cap=$SAVED_CAP_SCAN
  else
    for s in ${ALL_SAVED[@]+"${ALL_SAVED[@]}"}; do [ "$s" != "$CUR" ] && ordered+=("$s"); done
    cap=$SAVED_CAP
  fi

  : > "${STATE}_saved"
  i=0
  for s in ${ordered[@]+"${ordered[@]}"}; do
    [ $i -ge $cap ] && break
    i=$((i+1))
    printf '%s\n' "$s" >> "${STATE}_saved"
    if [ -n "$CUR" ] && [ "$s" = "$CUR" ]; then icon=$CHECK color=$GREEN
    elif [ $GRANTED = 1 ] && in_near "$s"; then icon=$WIFI color=$ICON_COLOR
    else icon=$WIFI color=$GREY; fi
    args+=(--set wifi.saved.$i drawing=on label="$s" icon="$icon" icon.color=$color)
  done
  for ((j=i+1; j<=8; j++)); do args+=(--set wifi.saved.$j drawing=off); done
  if [ $i -gt 0 ]; then args+=(--set wifi.hdr.saved drawing=on); else args+=(--set wifi.hdr.saved drawing=off); fi

  # Nearby: strongest first, one per name (the app already sorted and de-duplicated), not the connected one.
  : > "${STATE}_near"
  i=0
  if [ $GRANTED = 1 ]; then
    for ((j=0; j<${#NEAR_NAME[@]}; j++)); do
      s=${NEAR_NAME[$j]}
      [ -n "$CUR" ] && [ "$s" = "$CUR" ] && continue
      [ $i -ge $NEAR_CAP ] && break
      i=$((i+1))
      printf '%s\n' "$s" >> "${STATE}_near"
      if [ "${NEAR_LOCK[$j]}" = 1 ]; then icon=$LOCK; else icon=$WIFI; fi
      args+=(--set wifi.near.$i drawing=on label="$s" icon="$icon" icon.color=$(signal_color "${NEAR_RSSI[$j]}"))
    done
  fi
  for ((j=i+1; j<=NEAR_CAP; j++)); do args+=(--set wifi.near.$j drawing=off); done
  if [ $i -gt 0 ]; then args+=(--set wifi.hdr.near drawing=on); else args+=(--set wifi.hdr.near drawing=off); fi

  # With Location access the connected network's real name replaces the generic one.
  [ $GRANTED = 1 ] && [ -n "$CUR" ] && args+=(--set wifi.ssid label="$CUR")
  sketchybar "${args[@]}"
}

# scan_now: runs the helper app (it exits at once, printing AUTH undetermined, when Location is not allowed;
# the connected channel still comes back). Leaves the output in $SCAN_F.
# WIFI_SCAN_FIXTURE=<file> stands in for the app (testing).
scan_now() {
  local out="${STATE}_scan.new"
  if [ -n "$WIFI_SCAN_FIXTURE" ]; then cp "$WIFI_SCAN_FIXTURE" "$out"
  else
    [ -d "$WIFI_APP" ] || return 1
    find "$LOCK_D" -maxdepth 0 -mmin +1 -exec rmdir {} \; 2>/dev/null   # a lock left by a killed scan
    mkdir "$LOCK_D" 2>/dev/null || return 1                               # a scan is already running
    : > "$out"
    open -g -W --stdout "$out" "$WIFI_APP" --args --scan >/dev/null 2>&1
    rmdir "$LOCK_D" 2>/dev/null
  fi
  if head -1 "$out" | grep -q '^AUTH'; then mv "$out" "$SCAN_F"; return 0; fi
  rm -f "$out"; return 1
}

PLUGIN_DIR_W="$HOME/.config/sketchybar/plugins"
if [ "$POWER" = "on" ] && [ "$(sketchybar --query wifi | jq -r '.popup.drawing')" = "on" ]; then
  # Draw at once from the last scan (if under 10 minutes old), then refresh it.
  if [ -n "$(find "$SCAN_F" -mmin -10 2>/dev/null)" ]; then render_networks "$SCAN_F"
  else rm -f "$SCAN_F"; render_networks /dev/null; fi
  if scan_now; then render_networks "$SCAN_F"; fi
  if [ $CONNECTED = 1 ]; then "$PLUGIN_DIR_W/wifi_speed.sh" render
  else sketchybar --set wifi.speed drawing=off --set wifi.speed.result drawing=off; fi
else
  hide_networks
fi
