#!/bin/bash
# Test switch for the flat style's smart items: forces them visible with sample data, so each can be
# checked without a real call, song or meeting. Flags live in $TMPDIR/sketchybar_smart (wiped on a
# bar reload), so a reload also switches everything off.
#   smart_demo.sh on  <name...|all>    force on
#   smart_demo.sh off [name...|all]    force off (default all)
#   smart_demo.sh status               which are forced on
# Names: privacy vpn awake updates slack whatsapp market music meeting timer battery
#        title (a 70-character window title) workspaces (4 app icons and a +N on every workspace)
# Each smart item's plugin also honours SMART_DEMO=name,name when you run it by hand.

export PATH="/usr/local/bin:$PATH"
PLUGINS="$HOME/.config/sketchybar/plugins"
source "$PLUGINS/smart_lib.sh"
ALL="privacy vpn awake updates slack whatsapp market music meeting timer battery title workspaces"

cmd=$1; shift
names=("$@"); [ "${names[*]}" = all ] && names=($ALL)
case $cmd in
  on)
    [ "${#names[@]}" -gt 0 ] || { echo "usage: smart_demo.sh on <name...|all>" >&2; exit 2; }
    for n in "${names[@]}"; do
      case " $ALL " in *" $n "*) : > "$SMART_DIR/demo.$n" ;; *) echo "unknown: $n" >&2; exit 2 ;; esac
    done ;;
  off)
    [ "${#names[@]}" -gt 0 ] || names=($ALL)
    for n in "${names[@]}"; do rm -f "$SMART_DIR/demo.$n"; done ;;
  status)
    for n in $ALL; do [ -e "$SMART_DIR/demo.$n" ] && echo "$n"; done
    exit 0 ;;
  *) echo "usage: smart_demo.sh on <name...|all> | off [name...|all] | status" >&2; exit 2 ;;
esac

# Redraw: the smart items re-read their state (and see the flags); the title and workspaces are redrawn
sketchybar --trigger smart_refresh
SENDER=forced NAME=window_title "$PLUGINS/window_title.sh" >/dev/null 2>&1
SENDER=forced "$PLUGINS/spaces.sh" >/dev/null 2>&1
exit 0
