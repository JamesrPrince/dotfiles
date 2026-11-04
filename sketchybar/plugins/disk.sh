#!/bin/bash
# Shows free space only when it drops below LIMIT_GB.
export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/plugins/hover.sh"
LIMIT_GB=${LIMIT_GB:-20}
free_gb=$(df -g / | awk 'NR==2{print $4}')
if [ "$free_gb" -lt "$LIMIT_GB" ]; then
  sketchybar --set "$NAME" drawing=on label="${free_gb} GB free"
else
  sketchybar --set "$NAME" drawing=off
fi
