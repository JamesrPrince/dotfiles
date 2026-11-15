#!/bin/bash
# Flat style, smart item "awake": an icon while something is deliberately keeping the Mac awake.
# Reads `pmset -g assertions` (one process, every FLAT_POLL_AWAKE s, on wake, and on smart_refresh)
# and counts only assertions owned by FLAT_AWAKE_OWNERS (Amphetamine by default) or by an open-ended
# caffeinate (the control centre's Keep Awake row). The system's own holders (audio, WindowServer,
# powerd, a browser playing video) and the 300-second caffeinates other tools start are ignored,
# so the icon means "James or an app he runs is keeping this Mac awake". Nothing is sent to the bar
# unless the answer changed.

source "$HOME/.config/sketchybar/plugins/smart_lib.sh"

awake=0
if smart_demo awake; then
  awake=1
else
  owner=""; kind=0; timed=0
  settle() {   # the assertion just read counts?
    [ -n "$owner" ] && [ "$kind" = 1 ] || return 0
    if [ "$owner" = caffeinate ]; then
      [ "$timed" = 0 ] && awake=1
    else
      case " $FLAT_AWAKE_OWNERS " in *" $owner "*) awake=1 ;; esac
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

if [ "$awake" = 1 ]; then
  source "$HOME/.config/sketchybar/icons.sh"
  SM_ICON=$AWAKE; SM_LABEL=; smart_show awake
else
  smart_hide awake
fi
