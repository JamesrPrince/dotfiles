#!/bin/bash
# The one keep-awake detector, shared by the flat bar's smart item (smart_awake.sh) and the control
# popup's Keep Awake row (control.sh). Source it, then:
#   awake_scan      prints one "name pid" line per assertion that counts, sorted and unique
#   awake_holders   prints the holder names, once each, on one line (empty = nothing is holding the Mac awake)
# What counts (`pmset -g assertions`): an assertion that prevents sleep, owned by a name in
# FLAT_AWAKE_OWNERS (Amphetamine, OnlySwitch), or by a caffeinate with NO timeout. System holders
# (audio, WindowServer, powerd, a browser playing video) and caffeinates with a timeout
# ("asserting for 300 secs") are ignored; "asserting forever" is the open-ended kind.
# Test inputs: SMART_DEMO=awake / smart_demo.sh on awake (a pretend OnlySwitch holds it) and
# AWAKE_PMSET_FILE=<file of `pmset -g assertions` text>, which is read in place of the real command.

source "$HOME/.config/sketchybar/plugins/smart_lib.sh"

awake_scan() {
  if smart_demo awake; then echo "OnlySwitch 0"; return 0; fi
  local owner="" pid="" kind=0 timed=0 line out re
  out=$(if [ -n "$AWAKE_PMSET_FILE" ]; then cat "$AWAKE_PMSET_FILE" 2>/dev/null; else pmset -g assertions 2>/dev/null; fi)
  settle() {   # the assertion just read counts?
    [ -n "$owner" ] && [ "$kind" = 1 ] || return 0
    if [ "$owner" = caffeinate ]; then
      [ "$timed" = 0 ] && echo "$owner $pid"
    else
      case " $FLAT_AWAKE_OWNERS " in *" $owner "*) echo "$owner $pid" ;; esac
    fi
  }
  re='pid ([0-9]+)\(([^)]*)\): .* (PreventUserIdleSystemSleep|PreventUserIdleDisplaySleep|PreventSystemSleep|NoIdleSleepAssertion|NoDisplaySleepAssertion) '
  {
    while IFS= read -r line; do
      if [[ $line =~ $re ]]; then
        settle; pid=${BASH_REMATCH[1]}; owner=${BASH_REMATCH[2]}; kind=1; timed=0
      elif [[ $line == *"pid "* ]]; then
        settle; owner=""; kind=0; timed=0
      elif [[ $line == *"asserting for "[0-9]* ]]; then   # "asserting for 300 secs" is timed; "asserting forever" is not
        timed=1
      fi
    done <<< "$out"
    settle
  } | sort -u
}

awake_holders() { awake_scan | awk '{print $1}' | sort -u | tr '\n' ' ' | sed 's/ $//'; echo; }
