#!/bin/bash
# Brightness icon and slider, built like the volume item (items/volume.sh): the slider
# slides out when the brightness changes and hides again after 2s. Click the icon to
# show or hide it; dragging the slider sets the built-in display (helper/brightness).
# brightness_change is raised by helper/brightnesswatch, which listens for DisplayServices' own
# brightness notification (started by `brightness_bar.sh watch` after the bar loads). The slider
# still polls every 60s as a safety net: it catches a missed change and restarts the watcher.

sketchybar --add event brightness_change

brightness_slider=(
  script="$PLUGIN_DIR/brightness_bar.sh"
  updates=on
  update_freq=60
  label.drawing=off
  icon.drawing=off
  slider.highlight_color=$YELLOW
  slider.background.height=5
  slider.background.corner_radius=3
  slider.background.color=$BACKGROUND_2
  slider.knob=$VOLUME_KNOB
  slider.knob.drawing=off
)

brightness_icon=(
  click_script="$PLUGIN_DIR/brightness_bar.sh toggle"
  padding_left=10
  padding_right=0
  icon=$BRIGHTNESS
  icon.width=0
  icon.align=left
  icon.color=$GREY
  icon.font="$FONT:Regular:14.0"
  label=$BRIGHTNESS
  label.width=25
  label.align=left
  label.font="$FONT:Regular:14.0"
)

AFTER_LOAD+=("$PLUGIN_DIR/brightness_bar.sh watch")

sketchybar --add slider brightness right            \
           --set brightness "${brightness_slider[@]}" \
           --subscribe brightness brightness_change   \
                                  mouse.clicked       \
                                  mouse.entered       \
                                  mouse.exited        \
                                                      \
           --add item brightness_icon right           \
           --set brightness_icon "${brightness_icon[@]}"
