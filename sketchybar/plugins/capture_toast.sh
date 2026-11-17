#!/bin/bash
# Two-second toast under the clock for capture/capture.sh (event capture_done, text in $MSG).
# A newer capture replaces an older toast. Never sets popup.height=-1 (it crashes SketchyBar 2.24).
export PATH="/usr/local/bin:$PATH"
[ "$SENDER" = capture_done ] || exit 0
PIDF="${TMPDIR:-/tmp}/sketchybar_capture_toast.pid"
[ -f "$PIDF" ] && kill "$(cat "$PIDF")" 2>/dev/null
echo $$ > "$PIDF"
sketchybar --set capture.msg label="${MSG:-Captured}" --set capture popup.drawing=on
sleep 2
sketchybar --set capture popup.drawing=off
rm -f "$PIDF"
