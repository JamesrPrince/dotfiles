#!/bin/bash
# Flat style, smart item "awake": an icon while something is deliberately keeping the Mac awake.
# Reads `pmset -g assertions` (one process, every FLAT_POLL_AWAKE s, on wake, and on smart_refresh)
# and counts only assertions owned by FLAT_AWAKE_OWNERS (Amphetamine by default) or by an open-ended
# caffeinate (the control centre's Keep Awake row). The system's own holders (audio, WindowServer,
# powerd, a browser playing video) and the 300-second caffeinates other tools start are ignored,
# so the icon means "James or an app he runs is keeping this Mac awake". Nothing is sent to the bar
# unless the answer changed.

source "$HOME/.config/sketchybar/plugins/hover.sh"
source "$HOME/.config/sketchybar/plugins/smart_lib.sh"
WHO="$SMART_DIR/awake.who"

if [ "$SENDER" = "mouse.exited.global" ]; then sketchybar --set awake popup.drawing=off; exit 0; fi

# click: a popup naming who is holding the Mac awake (read from the last poll)
if [ "$1" = click ]; then
  source "$HOME/.config/sketchybar/colors.sh"; source "$HOME/.config/sketchybar/icons.sh"
  FONT="SF Pro"; source "$HOME/.config/sketchybar/plugins/style.sh"
  args=(--remove '/awake\.row\..*/')
  n=0
  for who in $(cat "$WHO" 2>/dev/null); do
    n=$((n + 1))
    args+=(--add item awake.row.$n popup.awake
           --set awake.row.$n icon=$AWAKE icon.font="$FONT:Regular:14.0" icon.width=26 icon.color=$GREY
                              label="Held by $who" label.font="$TEXT_FONT:SemiBold:13.0"
                              padding_left=8 padding_right=12 background.corner_radius=4)
  done
  [ "$n" -eq 0 ] && args+=(--add item awake.row.1 popup.awake
                           --set awake.row.1 icon.drawing=off label="Nobody is holding it" label.color=$GREY
                                             label.font="$TEXT_FONT:SemiBold:13.0" padding_left=8 padding_right=12)
  sketchybar "${args[@]}" >/dev/null 2>&1
  "$HOME/.config/sketchybar/plugins/popup.sh" awake toggle
  exit 0
fi

source "$HOME/.config/sketchybar/plugins/awake_lib.sh"   # the shared detector (also the control popup's Keep Awake row)
holders=$(awake_holders); awake=0; [ -n "$holders" ] && awake=1

# who holds it, once each, for the click popup
echo $holders > "$WHO"

if [ "$awake" = 1 ]; then
  source "$HOME/.config/sketchybar/icons.sh"
  SM_ICON=$AWAKE; SM_LABEL=; smart_show awake
else
  smart_hide awake
fi
