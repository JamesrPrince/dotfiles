#!/bin/bash
# The flat style's tuning knobs, in one place. Source it; it only sets variables and one function.
# Everything colour-related comes from the theme (colors.sh) through flat_colors, so all 11 themes work.
# Thresholds are used by plugins/stats.sh, battery.sh, wifi.sh, bluetooth.sh and the smart items
# (plugins/smart_lib.sh and its callers). Change a number here, then `sketchybar --reload`.

# --- When colour appears (everything else stays neutral) -------------------------------------------
FLAT_CPU_HIGH=80          # CPU % that turns the CPU icon, label and graph FLAT_WARN ...
FLAT_CPU_CRIT=95          # ... and FLAT_CRIT
FLAT_CPU_SAMPLES=2        # in a row (stats.sh samples every 3 s), so one spike does not flash the bar
FLAT_GPU_HIGH=80
FLAT_GPU_CRIT=95
FLAT_GPU_SAMPLES=2
# Memory follows the kernel's pressure level (1 normal, 2 warning, 4 critical): normal neutral,
# warning FLAT_WARN, critical FLAT_CRIT.
FLAT_BATT_WARN=30         # battery % that turns the icon FLAT_WARN and shows the percentage label ...
FLAT_BATT_CRIT=15         # ... and FLAT_CRIT
FLAT_WIFI_WEAK=-70        # dBm: below this the Wi-Fi icon turns FLAT_WARN ...
FLAT_WIFI_BAD=-80         # ... and below this FLAT_CRIT. Wi-Fi off or no IP: FLAT_WARN / FLAT_CRIT.

# --- Smart items: when they show ------------------------------------------------------------------
FLAT_MEET_WINDOW_MIN=30   # next meeting shows this many minutes ahead
FLAT_MEET_SOON_MIN=5      # inside this it turns FLAT_WARN (and FLAT_CRIT once it starts)
FLAT_BREW_HOURS=4         # `brew outdated` is re-run at most this often, started when the control popup opens (never blocks)
FLAT_MARKET_MOVE_PCT=1    # |day change| % at which a market price turns FLAT_UP / FLAT_DOWN
FLAT_MARKET_ALWAYS=1      # market item: 1 = always shown and fetched; 0 = only while a trading window from market_windows.conf is open
FLAT_MARKET_FETCH_SECS=30 # market prices are fetched at most this often (the feed's limit: never lower), while the item is on
# Keep-awake: the owners whose power assertions count (pmset -g assertions): Amphetamine and OnlySwitch's
# "keep awake" switch, plus an open-ended caffeinate (the control centre's Keep Awake row; the 300 s ones
# other tools start are ignored). Click the icon to see who is holding.
FLAT_AWAKE_OWNERS="Amphetamine OnlySwitch"

# --- Poll intervals (seconds) of the items that have no event to listen to -------------------------
FLAT_POLL_PRIVACY=5       # mic / camera: two tiny helper processes per tick
FLAT_POLL_AWAKE=30        # one `pmset -g assertions`
FLAT_POLL_VPN=60          # one `scutil --nc list` (and on Wi-Fi changes / wake)
FLAT_POLL_BADGES=15       # two `lsappinfo` reads
FLAT_POLL_MEETING=30      # reads a cache; the calendar helper runs every 5 minutes
FLAT_POLL_MARKET=30       # redraws the market item and starts a fetch when due; with FLAT_MARKET_ALWAYS=0 also one `aerospace list-windows --all`

# --- Geometry --------------------------------------------------------------------------------------
FLAT_ICON_FONT_SIZE=14    # every glyph on the right side: SF Pro Medium at this size
FLAT_ICON_W=20            # fixed icon cell, so the spacing between icons is even
FLAT_ICON_PAD=3           # either side of an icon cell
FLAT_NF_FONT_SIZE=16      # the few Nerd Font glyphs (Bluetooth, updates): Maple Mono NF Bold, drawn as heavy as SF Medium
FLAT_UPDATES_ICON=$(printf '\xf3\xb0\x8f\x97')   # nf-md-package-variant-closed (U+F03D7)
FLAT_POPUP_RADIUS=4
FLAT_POPUP_BORDER_W=1
FLAT_POPUP_ROW_H=26
FLAT_ANIM="tanh 12"       # appear / disappear of the smart items (about 0.2 s)
FLAT_ANIM_WS="tanh 8"     # workspace change
FLAT_WS_MAX_ICONS=4       # app icons per workspace, then "+N"

# Colours derived from the theme. Call once colors.sh is loaded (it loads it if it is not).
flat_colors() {
  [ -n "$WHITE" ] || source "$HOME/.config/sketchybar/colors.sh"
  FLAT_REST="0xcc${WHITE:4}"          # neutral icon and label
  FLAT_HOVER=$WHITE                   # hover: the full text colour
  FLAT_DIM="0x77${WHITE:4}"           # dimmed: Bluetooth off, stale prices, empty workspaces' neighbours
  FLAT_WARN=$ORANGE
  FLAT_CRIT=$RED
  # Matte Black's own ORANGE (c63d3d) is almost its RED (d35f5f), so 80% and 95% would look alike: its warn
  # slot takes the theme's amber (its GREEN slot, ffc107) and critical stays red. Every other theme unchanged.
  [ "$THEME" = matteblack ] && FLAT_WARN=$GREEN
  FLAT_GOOD=$GREEN                    # charging
  FLAT_UP=$GREEN
  FLAT_DOWN=$RED
  FLAT_POPUP_BORDER="0x66${GREY:4}"   # a quiet 1 px edge
  FLAT_DIVIDER="0x55${GREY:4}"
  FLAT_GRAPH_FILL="0x22${WHITE:4}"
}

# The smart items, in the order zen mode and the demo switch walk them
SMART_ITEMS="privacy vpn awake badge.slack badge.whatsapp market.1 market.2 market.3 spotify.anchor next_event timer"

# --- Width-aware layout ----------------------------------------------------------------------------
# Nothing here is a character count for one screen: the room each flexible text gets (window title,
# meeting title, track title) is worked out in pixels from the display's logical width, and the text is
# clipped to it (label.width is a hard clip, so even wide glyphs cannot draw past it). Test override:
# FLAT_DISPLAY_W=1920 in the environment of a plugin run by hand.
# Measured on the 2560 bar with every smart item on (see smart_lib.sh for the picture):
FLAT_CLOCK_HALF=87        # the clock block (clock.pad + clock + world clock) is this far either side of the centre
FLAT_RIGHT_W=793          # market.1's left edge to the bar's right edge: markets, mic, VPN, awake, badges, stats, tray
FLAT_GAP=16               # least clear pixels between the time items and the right-hand items
FLAT_TITLE_GAP=20         # least clear pixels between the window title and the clock block
FLAT_CLAUDE_W=47          # claude's slot: the item (30, 37 with two digits) plus its 10 px gap to the music
FLAT_TIMER_W=70           # the timer's slot: 10 gap + icon + "25:00"
FLAT_MEET_OH=85           # meeting item minus its title: 10 gap, icon, "in 12m"
FLAT_MUSIC_OH=36          # music item minus its title: padding and icon
FLAT_TITLE_ICON_W=24      # window title: the app icon and its padding, before the text
FLAT_TEXT_MIN_PX=50       # under this a title is not worth showing (about 6 characters): the next item is shed instead

flat_display_w() {   # logical width of the narrowest display the bar is on
  local w=${FLAT_DISPLAY_W:-}
  [ -n "$w" ] || w=$(/usr/local/bin/sketchybar --query displays 2>/dev/null | python3 -c 'import json,sys; print(int(min(d["frame"]["w"] for d in json.load(sys.stdin))))' 2>/dev/null)
  case $w in ''|*[!0-9]*) w=2560 ;; esac
  echo "$w"
}

# flat_cols <text>: display columns (CJK and emoji count two)
flat_cols() {
  if ( LC_ALL=C; [[ "$1" =~ ^[\ -~]*$ ]] ); then echo "${#1}"; return; fi
  python3 -I -c 'import sys,unicodedata as u; print(sum(2 if u.east_asian_width(c) in "WF" else 1 for c in sys.argv[1]))' "$1" 2>/dev/null || echo "${#1}"
}

# flat_trim <text> <columns>: the text cut to fit, ending in an ellipsis
flat_trim() {
  local t=$1 n=$2
  [ "$n" -gt 0 ] || { echo ""; return; }
  [ "$(flat_cols "$t")" -le "$n" ] && { echo "$t"; return; }
  if ( LC_ALL=C; [[ "$t" =~ ^[\ -~]*$ ]] ); then echo "${t:0:$((n - 1))}…"; return; fi
  python3 -I -c 'import sys,unicodedata as u
t,n=sys.argv[1],int(sys.argv[2]); o="";c=0
for ch in t:
    w=2 if u.east_asian_width(ch) in "WF" else 1
    if c+w>n-1: break
    o+=ch;c+=w
print(o+"\u2026")' "$t" "$n" 2>/dev/null || echo "${t:0:$((n - 1))}…"
}

# flat_budget: sets FLAT_W, FLAT_MEET_PX and FLAT_MUSIC_PX (px for the title text; 0 = no title, -1 = item
# hidden). The time items grow right from the clock and the music grows left from the right-hand group, so
# they share what is between them. Order of giving way when the display is too narrow: the music title,
# the music item, the meeting title, the meeting item.
flat_budget() {
  local free text p
  FLAT_W=$(flat_display_w)
  free=$(( FLAT_W - FLAT_RIGHT_W - (FLAT_W / 2 + FLAT_CLOCK_HALF) - FLAT_GAP - FLAT_CLAUDE_W - FLAT_TIMER_W ))
  text=$(( free - FLAT_MEET_OH - FLAT_MUSIC_OH ))
  if   [ "$text" -ge $(( 2 * FLAT_TEXT_MIN_PX )) ]; then p=$(( text * 40 / 100 )); FLAT_MUSIC_PX=$p; FLAT_MEET_PX=$(( text - p ))
  elif [ "$text" -ge "$FLAT_TEXT_MIN_PX" ]; then FLAT_MUSIC_PX=0; FLAT_MEET_PX=$text
  elif [ $(( text + FLAT_MUSIC_OH )) -ge "$FLAT_TEXT_MIN_PX" ]; then FLAT_MUSIC_PX=-1; FLAT_MEET_PX=$(( text + FLAT_MUSIC_OH ))
  elif [ $(( text + FLAT_MUSIC_OH )) -ge 0 ]; then FLAT_MUSIC_PX=-1; FLAT_MEET_PX=0
  else FLAT_MUSIC_PX=-1; FLAT_MEET_PX=-1; fi
}
# px -> whole columns of 12 pt Maple Mono (7.2 px each; CJK and emoji take two)
flat_px_cols() { echo $(( $1 * 10 / 72 )); }

# flat_title_px: room for the window title's text: from the title's own left edge (it sits after the
# workspaces, whose width varies) to the clock block. 0 or less means icon only.
flat_title_px() {
  local w x
  w=$(flat_display_w)
  x=$(/usr/local/bin/sketchybar --query window_title 2>/dev/null | python3 -c 'import json,sys; print(int(min(r["origin"][0] for r in json.load(sys.stdin)["bounding_rects"].values())))' 2>/dev/null)
  case $x in ''|*[!0-9]*) x=718 ;; esac   # the bar answers empty while it reloads: assume the widest workspaces
  echo $(( w / 2 - FLAT_CLOCK_HALF - FLAT_TITLE_GAP - x - FLAT_TITLE_ICON_W ))
}
