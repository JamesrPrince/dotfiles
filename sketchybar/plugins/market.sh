#!/bin/bash
# Flat style, smart item "market" (market.1 .. market.3, one label per symbol): short prices such as
# "BTC 65.4k  XAU 3,888", neutral, green or red only on a real day move (|change| >= FLAT_MARKET_MOVE_PCT
# %), dimmed when the quote is stale. With FLAT_MARKET_ALWAYS=1 (flat_config.sh, the default) it is always
# shown and always fetched, and no window is looked at. With FLAT_MARKET_ALWAYS=0 it is shown only while a
# trading window is open (patterns in market_windows.conf); with none open nothing but one
# `aerospace list-windows --all` runs per tick, and prices are not fetched at all. Prices come from
# plugins/market_fetch.sh (Mack's; symbols in market.conf), called detached: a fetch takes up to ~6.5 s and
# the bar is never made to wait. After a bar reload the last quote that fetch cached is drawn at once.
#   (no argument)  the item's script: state check on focus / workspace events, wake, and every
#                  FLAT_POLL_MARKET s; starts a fetch when the last result is older than
#                  FLAT_MARKET_FETCH_SECS; shows what it has
#   fetch          the detached fetch; renders when it returns
#   render         draw from the last result (if the item is on)
#   click          the popup: a row per symbol with the full price, day change and quote age, and a note
# Test switch: plugins/smart_demo.sh on market

source "$HOME/.config/sketchybar/plugins/hover.sh"
source "$HOME/.config/sketchybar/plugins/smart_lib.sh"
SELF="$HOME/.config/sketchybar/plugins/market.sh"
FETCH="$HOME/.config/sketchybar/plugins/market_fetch.sh"
PATTERNS="${MARKET_WINDOWS_CONF:-$HOME/.config/sketchybar/market_windows.conf}"   # the override is for tests
DATA="$SMART_DIR/market.out"
OPEN="$SMART_DIR/market.open"
LOCK="$SMART_DIR/market.lock"

if [ "$SENDER" = "mouse.exited.global" ]; then
  sketchybar --set market.1 popup.drawing=off
  exit 0
fi

now=$(date +%s)

# 12345.67 -> 12,345.67 ; commas <int>
commas() { local n=$1 out=""; while [ ${#n} -gt 3 ]; do out=",${n: -3}$out"; n=${n:0:${#n}-3}; done; echo "$n$out"; }
# short <price>: 65423.48 -> 65.4k ; 3887.60 -> 3,888 ; 59.40 -> 59.40
short() {
  local p=$1 i=${1%.*} f=${1#*.}
  [ "$f" = "$p" ] && f=00
  if [ "$i" -ge 10000 ]; then local t=$(( (i + 50) / 100 )); echo "$((t / 10)).$((t % 10))k"
  elif [ "$i" -ge 1000 ]; then [ "${f:0:2}" -ge 50 ] && i=$((i + 1)); commas "$i"
  else echo "$p"; fi
}
# hundredths <signed change> -> absolute value in hundredths (NA -> -1)
hundredths() { local c=${1#[+-]}; [ "$c" = NA ] && { echo -1; return; }; local i=${c%.*} f=${c#*.}; [ "$f" = "$c" ] && f=00; echo $(( 10#$i * 100 + 10#${f:0:2} )); }
age() { local d=$(( now - $1 )); [ "$d" -lt 0 ] && d=0
  if [ "$d" -lt 90 ]; then echo "${d}s ago"; elif [ "$d" -lt 5400 ]; then echo "$((d / 60))m ago"; else echo "$((d / 3600))h ago"; fi; }

# Is the item on? Always, when FLAT_MARKET_ALWAYS=1; else while a trading window is open.
window_open() {
  smart_demo market && return 0
  [ "$FLAT_MARKET_ALWAYS" = 1 ] && return 0
  local pat line args=()
  [ -r "$PATTERNS" ] || return 1
  while IFS= read -r line; do
    line=${line%%#*}; line=${line#"${line%%[![:space:]]*}"}; line=${line%"${line##*[![:space:]]}"}
    [ -n "$line" ] && args+=(-e "$line")
  done < "$PATTERNS"
  [ "${#args[@]}" -gt 0 ] || return 1
  aerospace list-windows --all --format '%{app-name}|%{window-title}' 2>/dev/null | grep -i -F -q "${args[@]}"
}

# A bar reload wipes $SMART_DIR (market.out with it), but market_fetch.sh keeps its own cache, same four
# tab-separated columns: draw that straight away rather than wait for the first fetch. The copy takes the
# cache's age, so the next tick still starts a fetch when it is older than FLAT_MARKET_FETCH_SECS.
seed_from_cache() {
  [ -s "$DATA" ] && return 0
  local c="${MARKET_CACHE:-${TMPDIR:-/tmp}/sketchybar-market.cache}"
  [ -s "$c" ] || return 0
  cp "$c" "$DATA.tmp" && touch -r "$c" "$DATA.tmp" && mv "$DATA.tmp" "$DATA"
}

data_file() {   # the file to draw: sample data under the demo switch
  if smart_demo market; then
    printf 'BTC\t65423.48\t-2.69\t%s\nXAU\t3887.60\t+0.03\t%s\n' $((now - 12)) $((now - 12)) > "$SMART_DIR/market.demo"
    echo "$SMART_DIR/market.demo"
  else echo "$DATA"; fi
}

render() {
  local f i=0 sym price chg ep stale col h
  f=$(data_file)
  seed_from_cache
  flat_colors
  if [ -s "$f" ]; then
    while IFS=$'\t' read -r sym price chg ep stale; do
      [ -n "$sym" ] && [ -n "$price" ] || continue
      i=$((i + 1)); [ "$i" -gt 3 ] && break
      col=$FLAT_REST
      h=$(hundredths "$chg")
      if [ "$h" -ge $(( FLAT_MARKET_MOVE_PCT * 100 )) ]; then
        case $chg in -*) col=$FLAT_DOWN ;; *) col=$FLAT_UP ;; esac
      fi
      [ "$stale" = stale ] && col=$FLAT_DIM
      [ -n "$ep" ] && [ $(( now - ep )) -gt $(( FLAT_MARKET_FETCH_SECS * 4 )) ] && col=$FLAT_DIM   # nothing newer for 4 fetch periods
      SM_ICON=; SM_LABEL="$sym $(short "$price")"; SM_LC=$col; smart_show market.$i
    done < "$f"
  fi
  # Slots without a symbol collapse (no line for a symbol: left out; no lines at all: hidden)
  for j in 1 2 3; do [ "$j" -gt "$i" ] && smart_hide market.$j; done
}

hide_all() { smart_hide market.1; smart_hide market.2; smart_hide market.3; }

start_fetch() {
  find "$LOCK" -maxdepth 0 -mmin +1 -exec rmdir {} \; 2>/dev/null   # a killed fetch
  mkdir "$LOCK" 2>/dev/null || return 0
  nohup "$SELF" fetch >/dev/null 2>&1 &
  disown 2>/dev/null
}

case "$1" in
  fetch)
    trap 'rmdir "$LOCK" 2>/dev/null' EXIT
    out=$("$FETCH" "$FLAT_MARKET_FETCH_SECS")
    printf '%s' "$out" > "$DATA.tmp"; [ -n "$out" ] && printf '\n' >> "$DATA.tmp"; mv "$DATA.tmp" "$DATA"
    rmdir "$LOCK" 2>/dev/null
    [ -e "$OPEN" ] && render
    exit 0 ;;
  render)
    if [ -e "$OPEN" ] || smart_demo market; then render; else hide_all; fi
    exit 0 ;;
  click) ;;
  *)
    # The window check: events and the slow timer
    if window_open; then
      : > "$OPEN"
      mt=0; [ -e "$DATA" ] && mt=$(stat -f %m "$DATA")
      if ! smart_demo market && [ $(( now - mt )) -ge "$FLAT_MARKET_FETCH_SECS" ]; then start_fetch; fi
      render
    else
      rm -f "$OPEN"
      hide_all
    fi
    exit 0 ;;
esac

# --- click: the popup ---------------------------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
flat_colors
FONT="SF Pro"
source "$HOME/.config/sketchybar/plugins/style.sh"
row=(icon.font="$FONT:Regular:14.0" icon.width=26 icon.color=$GREY label.font="$TEXT_FONT:SemiBold:13.0"
     padding_left=8 padding_right=12 background.corner_radius=$FLAT_POPUP_RADIUS)
args=(--remove '/market\.row\..*/')
add() { args+=(--add item market.row.$1 popup.market.1 --set market.row.$1 "${row[@]}" "${@:2}"); }
f=$(data_file)
n=0; have_xau=0
if [ -s "$f" ]; then
  while IFS=$'\t' read -r sym price chg ep stale; do
    [ -n "$sym" ] && [ -n "$price" ] || continue
    n=$((n + 1)); [ "$sym" = XAU ] && have_xau=1
    whole=${price%.*}; frac=${price#*.}; [ "$frac" = "$price" ] && frac=00
    full="$(commas "$whole").$frac"
    h=$(hundredths "$chg"); icon=$ACTIVITY; ic=$GREY
    if [ "$chg" != NA ]; then
      case $chg in -*) icon=$NET_DOWN ;; *) icon=$NET_UP ;; esac
      [ "$h" -ge $(( FLAT_MARKET_MOVE_PCT * 100 )) ] && { case $chg in -*) ic=$FLAT_DOWN ;; *) ic=$FLAT_UP ;; esac; }
    fi
    chg_txt="$chg%"; [ "$chg" = NA ] && chg_txt="n/a"
    note=$(age "${ep:-$now}"); [ "$stale" = stale ] && note="$note, stale"
    add sym$n icon=$icon icon.color=$ic label="$(printf '%-4s %11s  %7s  %s' "$sym" "$full" "$chg_txt" "$note")"
  done < "$f"
fi
[ "$n" -eq 0 ] && add none icon=$ACTIVITY label="No quote yet"
if [ "$have_xau" = 1 ]; then
  add note1 icon.drawing=off label="Gold's day change is the COMEX futures session;" label.font="$TEXT_FONT:Medium:11.0" label.color=$GREY
  add note2 icon.drawing=off label="its price is spot, so it sits flat on weekends." label.font="$TEXT_FONT:Medium:11.0" label.color=$GREY
fi
sketchybar "${args[@]}" >/dev/null 2>&1
"$HOME/.config/sketchybar/plugins/popup.sh" market.1 toggle
