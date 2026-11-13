#!/bin/bash
# Runs the chosen `om` action. $1 is theme:<id>, barstyle, keys, lock or sleep.
export PATH="/usr/local/bin:/usr/bin:/bin"
S="$HOME/.config/sketchybar/plugins"
case "$1" in
  theme:*)  /bin/bash "$S/theme.sh" set "${1#theme:}" ;;
  barstyle) /bin/bash "$S/barstyle.sh" next ;;
  keys)     /usr/bin/python3 "$S/keys.py" toggle ;;
  lock)     /usr/bin/pmset displaysleepnow ;;
  sleep)    /usr/bin/pmset sleepnow ;;
esac
