#!/bin/bash
export PATH="/usr/local/bin:$PATH"
H="$HOME/.config/sketchybar/helper"
STYLE=; [ -r "$HOME/.config/sketchybar/.barstyle" ] && read -r STYLE < "$HOME/.config/sketchybar/.barstyle"

if [ "$STYLE" = flat ]; then
  # Flat: a quiet mic and/or camera glyph at the left end of the right-hand group, only while one is in
  # use (a helper per device, every FLAT_POLL_PRIVACY s; nothing is sent to the bar unless it changed).
  source "$HOME/.config/sketchybar/plugins/smart_lib.sh"
  if smart_demo privacy; then MIC_ON=on; CAM_ON=on
  else
    MIC_ON=$("$H/audio" mic 2>/dev/null)
    CAM_ON=$("$H/camera" 2>/dev/null)
  fi
  if [ "$MIC_ON" = on ] || [ "$CAM_ON" = on ]; then
    source "$HOME/.config/sketchybar/icons.sh"   # $MIC and $CAMERA are the SF Symbols glyphs
    SM_ICON=; SM_LABEL=; SM_IW=0; SM_LW=0
    [ "$MIC_ON" = on ] && { SM_ICON=$MIC; SM_IW=18; }
    [ "$CAM_ON" = on ] && { SM_LABEL=$CAMERA; SM_LW=18; }
    smart_show privacy
  else
    smart_hide privacy
  fi
  exit 0
fi

MIC=$("$H/audio" mic 2>/dev/null)
CAM=$("$H/camera" 2>/dev/null)
M=off; C=off
[ "$MIC" = on ] && M=on
[ "$CAM" = on ] && C=on
DRAW=off
[ $M = on ] || [ $C = on ] && DRAW=on
# Hidden while zen mode hides the clock icon.
[ -f "${TMPDIR:-/tmp}/sketchybar_zen" ] && DRAW=off
sketchybar --set $NAME drawing=$DRAW icon.drawing=$M label.drawing=$C
