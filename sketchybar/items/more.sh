#!/bin/bash
# The "more" item (far right): a popup with the things that do not earn a bar slot --
# the shortcut sheet, the focus timer, GitHub notifications, free disk space and GPU load.
# A red dot appears next to the dots when one of them needs attention: unread GitHub
# notifications, a timer running or finished, or low disk. plugins/more.sh fills the rows.

more=(
  icon=$MORE
  icon.font="$FONT:Bold:15.0"
  icon.color=$WHITE
  icon.padding_left=6
  icon.padding_right=2
  label="●"
  label.drawing=off
  label.font="$TEXT_FONT:Black:8.0"
  label.color=$RED
  label.padding_left=0
  label.padding_right=4
  label.y_offset=5
  padding_left=2
  padding_right=2
  update_freq=10
  updates=on
  popup.align=right
  popup.height=28
  script="$PLUGIN_DIR/more.sh"
  click_script="$PLUGIN_DIR/popup.sh more; NAME=more SENDER=refresh $PLUGIN_DIR/more.sh"
)

popup_row=(
  icon.font="$FONT:Regular:14.0"
  icon.width=26
  label.font="$TEXT_FONT:SemiBold:13.0"
  padding_left=8
  padding_right=12
  background.corner_radius=7
  script="$PLUGIN_DIR/hover.sh"
)

sketchybar --add item more right           \
           --set more "${more[@]}"         \
           --subscribe more system_woke mouse.entered mouse.exited mouse.exited.global

for row in keys timer github disk; do
  sketchybar --add item more.$row popup.more \
             --set more.$row "${popup_row[@]}" \
             --subscribe more.$row mouse.entered mouse.exited
done

# GPU load: stats.sh writes its label with the other stats; the row just lives here
sketchybar --add item gpu popup.more                          \
           --set gpu "${popup_row[@]}"                         \
                     icon=GPU icon.color=$GREEN icon.font="$TEXT_FONT:ExtraBold:11.0" icon.width=40 \
                     label="--%" label.font="$TEXT_FONT:SemiBold:13.0" \
           --subscribe gpu mouse.entered mouse.exited

sketchybar --set more.keys   icon=$KEYBOARD icon.color=$BLUE label="Shortcuts   ⌥⇧/" \
                             click_script="/usr/bin/python3 $PLUGIN_DIR/keys.py toggle; /usr/local/bin/sketchybar --set more popup.drawing=off" \
           --set more.timer  icon=$TIMER_ICON icon.color=$GREY label="Focus timer" \
                             click_script="$PLUGIN_DIR/more.sh timer" \
           --set more.github icon=":git_hub:" icon.font="sketchybar-app-font:Regular:15.0" icon.color=$GREY label="GitHub" \
                             click_script="open https://github.com/notifications; /usr/local/bin/sketchybar --set more popup.drawing=off" \
           --set more.disk   icon=$DISK icon.color=$GREY label="Disk"  \
                             click_script="open 'x-apple.systempreferences:com.apple.settings.Storage'; /usr/local/bin/sketchybar --set more popup.drawing=off"
