#!/bin/bash
# World clock, after Omarchy 4.5's Elsewhen: a globe beside the clock that opens a panel of
# clocks, one row per city. Left click opens it, right or middle click refetches the weather.
# The cities and settings live in the git-ignored ~/.config/sketchybar/.worldclock.json, seeded
# on first open with your own city plus four well-known ones spread round the clock.
worldclock=(
  icon=󰇧
  icon.font="Maple Mono NF:Regular:15.0"
  label.drawing=off
  padding_left=6
  padding_right=2
  popup.align=right
  script="$PLUGIN_DIR/worldclock.sh"
)
sketchybar --add item worldclock right                  \
           --set worldclock "${worldclock[@]}"          \
           --move worldclock before calendar            \
           --subscribe worldclock mouse.clicked mouse.exited.global
