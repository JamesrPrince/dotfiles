#!/bin/bash
# World clock (items/worldclock.sh). Hover and closing are handled here; everything else is
# plugins/worldclock.py, which gets the theme colours and the bar style through the environment.
#   worldclock.sh                 the bar item's own events (click: open/close, right click: refresh)
#   worldclock.sh toggle <what>   a popup row was clicked: hour24, offset (shift-click: units)
export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/plugins/hover.sh"

if [ "$SENDER" = "mouse.exited.global" ]; then
  sketchybar --set worldclock popup.drawing=off
  exit 0
fi

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/plugins/style.sh"
export WHITE GREY YELLOW GREEN THEME ACCENT POPUP_BACKGROUND_COLOR BAR_STYLE TEXT_FONT SENDER BUTTON MODIFIER
exec /usr/bin/python3 -I "$HOME/.config/sketchybar/plugins/worldclock.py" "$@"
