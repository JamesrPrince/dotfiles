#!/bin/bash
# Capture confirmation: capture/capture.sh runs `sketchybar --trigger capture_done MSG=...`.
# The anchor sits beside the clock and draws nothing; plugins/capture_toast.sh pops $MSG under it.
sketchybar --add event capture_done \
           --add item capture center \
           --set capture width=0 padding_left=0 padding_right=0 icon.drawing=off label.drawing=off \
                 background.drawing=off popup.align=center \
                 popup.background.color=$POPUP_BACKGROUND_COLOR popup.background.border_color=$ACCENT \
                 popup.background.border_width=2 popup.background.corner_radius=9 \
                 script="$PLUGIN_DIR/capture_toast.sh" \
           --subscribe capture capture_done \
           --add item capture.msg popup.capture \
           --set capture.msg icon.drawing=off label.color=$WHITE label.font="$TEXT_FONT:Bold:13.0" \
                 label.padding_left=12 label.padding_right=12
