#!/bin/bash
# Script of a stats item that owns a popup: hover highlight, and closing the popup when the
# mouse leaves the item and its popup.
source "$HOME/.config/sketchybar/plugins/hover.sh"
if [ "$SENDER" = "mouse.exited.global" ]; then
  "$HOME/.config/sketchybar/plugins/popup.sh" "$NAME" off
fi
