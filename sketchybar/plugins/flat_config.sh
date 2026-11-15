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
FLAT_MEET_CHARS=12        # meeting title cap (the bar has ~120 px between the clock and the right-hand smart items: see smart_lib.sh)
FLAT_MUSIC_CHARS=16       # track title cap
FLAT_BREW_HOURS=4         # `brew outdated` is re-run at most this often, started when the control popup opens (never blocks)
FLAT_MARKET_MOVE_PCT=1    # |day change| % at which a market price turns FLAT_UP / FLAT_DOWN
FLAT_MARKET_FETCH_SECS=30 # market prices are fetched at most this often, and only with a trading window open
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
FLAT_POLL_MARKET=30       # one `aerospace list-windows --all`; prices only while a trading window is open

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
