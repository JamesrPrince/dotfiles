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

awake=0; holders=""
if smart_demo awake; then
  awake=1; holders="OnlySwitch"
else
  owner=""; kind=0; timed=0
  settle() {   # the assertion just read counts?
    [ -n "$owner" ] && [ "$kind" = 1 ] || return 0
    if [ "$owner" = caffeinate ]; then
      [ "$timed" = 0 ] && { awake=1; holders="$holders $owner"; }
    else
      case " $FLAT_AWAKE_OWNERS " in *" $owner "*) awake=1; holders="$holders $owner" ;; esac
    fi
  }
  re='pid [0-9]+\(([^)]*)\): .* (PreventUserIdleSystemSleep|PreventUserIdleDisplaySleep|PreventSystemSleep|NoIdleSleepAssertion|NoDisplaySleepAssertion) '
  while IFS= read -r line; do
    if [[ $line =~ $re ]]; then
      settle; owner=${BASH_REMATCH[1]}; kind=1; timed=0
    elif [[ $line == *"pid "* ]]; then
      settle; owner=""; kind=0; timed=0
    elif [[ $line == *"asserting for "[0-9]* ]]; then   # "asserting for 300 secs" is timed; "asserting forever" is not
      timed=1
    fi
  done <<< "$(pmset -g assertions 2>/dev/null)"
  settle
fi

# who holds it, once each, for the click popup
echo $(printf '%s\n' $holders | sort -u) > "$WHO"

if [ "$awake" = 1 ]; then
  source "$HOME/.config/sketchybar/icons.sh"
  SM_ICON=$AWAKE; SM_LABEL=; smart_show awake
else
  smart_hide awake
fi
