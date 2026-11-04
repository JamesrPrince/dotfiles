#!/bin/bash

export PATH="/usr/local/bin:$PATH"
# Shows the focused app's icon and name.

if [ "$SENDER" = "front_app_switched" ]; then
  source "$HOME/.config/sketchybar/plugins/icon_map.sh"
  __icon_map "$INFO"
  sketchybar --set "$NAME" icon="$icon_result" label="$INFO"
fi
