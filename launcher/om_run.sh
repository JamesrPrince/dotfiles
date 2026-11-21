#!/bin/bash
# Runs the chosen `om` action. $1 is theme:<id>, cap:<cmd>, toggle:<name>, barstyle, keys, lock or sleep.
export PATH="/usr/local/bin:/usr/bin:/bin"
S="$HOME/.config/sketchybar/plugins"
case "$1" in
  theme:*)  /bin/bash "$S/theme.sh" set "${1#theme:}" ;;
  cap:*)    /bin/bash "$HOME/dotfiles/capture/capture.sh" "${1#cap:}" ;;
  toggle:*) /bin/bash "$HOME/dotfiles/toggles/toggle.sh" "${1#toggle:}" toggle ;;
  barstyle) /bin/bash "$S/barstyle.sh" next ;;
  keys)     /usr/bin/python3 "$S/keys.py" toggle ;;
  lock)     /usr/bin/pmset displaysleepnow ;;
  sleep)    /usr/bin/pmset sleepnow ;;
esac
