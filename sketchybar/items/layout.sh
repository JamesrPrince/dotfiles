#!/bin/bash
# Layout of the focused window's container: tiles or accordion, side by side
# (↔) or stacked (↕). Click switches tiles/accordion, right-click turns it.
# Its script also hides the bar while a window is AeroSpace full screen.
sketchybar --add event aerospace_layout_change

layout=(
  icon.drawing=off
  label.font="$TEXT_FONT:ExtraBold:10.0"
  label.color=$GREY
  label.padding_left=8
  label.padding_right=8
  padding_left=0
  padding_right=6
  updates=on
  script="$PLUGIN_DIR/layout.sh"
)
sketchybar --add item layout left \
           --set layout "${layout[@]}" \
           --subscribe layout aerospace_workspace_change aerospace_focus_change aerospace_layout_change \
                              mouse.clicked mouse.entered mouse.exited
