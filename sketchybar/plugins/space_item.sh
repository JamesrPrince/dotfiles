#!/bin/bash
# Script of every workspace item: hover highlight (hover.sh), and closing the
# window-list popup when the mouse leaves the item and its popup.

source "$HOME/.config/sketchybar/plugins/hover.sh"

if [ "$SENDER" = "mouse.exited.global" ]; then
  # NAME is space.N; leave it open only if it is open
  "$HOME/.config/sketchybar/plugins/popup.sh" "$NAME" off
fi
