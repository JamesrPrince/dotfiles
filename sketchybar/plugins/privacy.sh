#!/bin/bash
export PATH="/usr/local/bin:$PATH"
H="$HOME/.config/sketchybar/helper"
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
