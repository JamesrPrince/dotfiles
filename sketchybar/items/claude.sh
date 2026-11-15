#!/bin/bash
# Claude Code sessions: the terminal's version of the desktop app's session sidebar. Hidden while no
# `claude` is running; otherwise an icon and the session count, coloured by the most urgent state
# (waiting yellow > done green > working blue > idle grey). Click for a popup listing each session
# (folder, status, age); click a row to focus that Ghostty window.
# State files come from claude/hooks/session-state.sh, which fires claude_update; plugins/claude.sh
# reads them. Flat style: the item is a smart item (plugins/smart_lib.sh), set up in items/flat_smart.sh.

sketchybar --add event claude_update

claude=(
  drawing=off
  icon=$''
  icon.font="Maple Mono NF:Bold:14.0"
  icon.color=$GREY
  icon.padding_left=6
  icon.padding_right=2
  label.font="$TEXT_FONT:Bold:12.0"
  label.color=$GREY
  label.padding_right=6
  padding_left=4
  padding_right=4
  update_freq=30
  updates=on
  popup.align=right
  popup.height=28
  script="$PLUGIN_DIR/claude.sh"
  click_script="$PLUGIN_DIR/claude.sh click"
)

sketchybar --add item claude right \
           --set claude "${claude[@]}" \
           --subscribe claude claude_update system_woke mouse.entered mouse.exited mouse.exited.global
