#!/bin/bash
# Flat style only: hides every item the flat bar does not show. They stay defined (plugins
# refer to them by name) but drawing=off. Called by items/flat.sh when the bar loads and by
# zen.sh when zen mode ends, because zen turns some of them back on.

export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/plugins/style.sh"
[ "$BAR_STYLE" = flat ] || exit 0

sketchybar --set weather drawing=off \
           --set privacy drawing=off \
           --set front_app drawing=off \
           --set layout drawing=off \
           --set spotify.anchor drawing=off \
           --set spotify.progress drawing=off \
           --set net.down drawing=off \
           --set more drawing=off \
           --set brightness drawing=off \
           --set brightness_icon drawing=off \
           --set vpn drawing=off \
           --set next_event drawing=off \
           --set github drawing=off \
           --set timer drawing=off \
           --set '/badge\..*/' drawing=off \
           --set badges drawing=off \
           --set calendar icon.drawing=off
