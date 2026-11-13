#!/bin/bash
# Flat style only: hides every item the flat bar does not show. They stay defined (plugins
# refer to them by name) but drawing=off. Called by items/flat.sh when the bar loads and by
# zen.sh when zen mode ends, because zen turns some of them back on.
# items/flat.sh sources it while the bar loads (so its calls join sketchybarrc's batch);
# zen.sh runs it as a program. Both work.

export PATH="/usr/local/bin:$PATH"
[ -n "$BAR_STYLE" ] || source "$HOME/.config/sketchybar/plugins/style.sh"
[ "$BAR_STYLE" = flat ] || { return 0 2>/dev/null || exit 0; }

sketchybar --set weather drawing=off \
           --set privacy drawing=off \
           --set front_app drawing=off \
           --set layout drawing=off \
           --set spotify.anchor drawing=off \
           --set spotify.progress drawing=off \
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

# Hidden items must not keep their timers and event hooks running: a hidden item's script
# still starts on every update_freq tick (and once at load) unless updates=off, and under load
# those processes delay the bar's own work. None of these is shown or reachable in the flat
# bar (privacy exits straight away in it, more/github/weather only fill popups that are not
# there, brightness is the slider that slides out in Centre Stage). Centre Stage reloads the
# items from scratch, so this never leaks into it.
sketchybar --set weather updates=off \
           --set privacy updates=off \
           --set more updates=off \
           --set brightness updates=off \
           --set vpn updates=off \
           --set next_event updates=off \
           --set github updates=off \
           --set badges updates=off \
           --set spotify.progress updates=off
