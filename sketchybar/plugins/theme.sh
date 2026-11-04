#!/bin/bash
# Theme switcher. "next" moves to the next theme and reloads the bar;
# "borders" (re)starts JankyBorders in the theme's accent. Both are safe
# to run at any time.

export PATH="/usr/local/bin:$PATH"
CONF="$HOME/.config/sketchybar"
source "$CONF/colors.sh"

borders_on() {
  # A running borders instance takes new settings from a second call
  borders active_color=$ACCENT inactive_color=0x00000000 width=5.0 style=round hidpi=on \
    >/dev/null 2>&1 &
}

case "$1" in
  next)
    set -- $THEMES
    NEXT=$1
    while [ $# -gt 0 ]; do
      if [ "$1" = "$THEME" ]; then NEXT=${2:-$(echo $THEMES | cut -d' ' -f1)}; break; fi
      shift
    done
    echo "$NEXT" > "$CONF/.theme"
    source "$CONF/colors.sh"
    borders_on
    sketchybar --reload
    ;;
  borders) borders_on ;;
esac
