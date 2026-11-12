#!/bin/bash
# Control centre: a brightness slider, toggles for Wi-Fi, Bluetooth, Focus, dark mode
# and keep-awake, battery charge and health, the bar theme, and System Settings.
# Green icon = on.

control=(
  icon=$CONTROL
  icon.font="$FONT:Bold:15.0"
  icon.color=$WHITE
  label.drawing=off
  padding_left=10
  padding_right=4
  popup.align=right
  script="$PLUGIN_DIR/control.sh"
  click_script="$PLUGIN_DIR/popup.sh control; NAME=control $PLUGIN_DIR/control.sh refresh"
)

popup_row=(
  icon.font="$FONT:Regular:15.0"
  icon.width=28
  label.font="$TEXT_FONT:SemiBold:13.0"
  padding_left=8
  padding_right=14
)

sketchybar --add item control right          \
           --set control "${control[@]}"     \
           --subscribe control mouse.exited.global system_woke

brightness=(
  script="$PLUGIN_DIR/brightness.sh"
  updates=on
  icon=$BRIGHTNESS
  icon.font="$FONT:Regular:15.0"
  icon.color=$YELLOW
  icon.width=28
  label.drawing=off
  padding_left=8
  padding_right=14
  slider.highlight_color=$YELLOW
  slider.background.height=5
  slider.background.corner_radius=3
  slider.background.color=$BACKGROUND_2
  slider.knob=$VOLUME_KNOB
  slider.knob.drawing=on
)

sketchybar --add slider control.brightness popup.control 150 \
           --set control.brightness "${brightness[@]}"       \
           --subscribe control.brightness mouse.clicked

for row in wifi bluetooth focus dark awake battery health theme settings; do
  sketchybar --add item control.$row popup.control \
             --set control.$row "${popup_row[@]}"    \
                   click_script="$PLUGIN_DIR/control.sh $row"
done

sketchybar --set control.wifi      icon=$WIFI                                  \
           --set control.bluetooth icon=$BLUETOOTH                             \
           --set control.focus     icon=$FOCUS                                 \
           --set control.dark      icon=$DARK_MODE                             \
           --set control.awake     icon=$AWAKE                                 \
           --set control.battery   icon=$BATTERY_75                            \
           --set control.health    icon=$HEART icon.color=$RED                 \
           --set control.theme     icon="🎨" icon.font="$FONT:Regular:13.0"     \
                                   label="Theme: $THEME_NAME"                  \
                                   click_script="$PLUGIN_DIR/theme.sh next"    \
           --set control.settings  icon=$GEAR icon.color=$GREY label="System Settings…"
