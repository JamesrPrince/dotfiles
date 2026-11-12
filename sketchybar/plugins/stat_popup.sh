#!/bin/bash
# Opens or closes one of the stats popups. Usage (click_script): stat_popup.sh <anchor> <kind>
#   stat_popup.sh net.up net | cpu.percent cpu | mem mem
# Opening closes the other two (and any other popup is closed by its own handler). The
# gathering loop (stat_<kind>.sh loop) only runs while the popup is open.

export PATH="/usr/local/bin:$PATH"
ANCHOR=$1 KIND=$2
PLUGINS="$HOME/.config/sketchybar/plugins"

if [ "$(sketchybar --query "$ANCHOR" | jq -r '.popup.drawing')" = "on" ]; then
  "$PLUGINS/popup.sh" "$ANCHOR" off
  exit 0
fi
for other in net.up cpu.percent mem; do
  [ "$other" = "$ANCHOR" ] || "$PLUGINS/popup.sh" "$other" off
done
"$PLUGINS/stat_$KIND.sh" reset          # "…" rows until the first results land
"$PLUGINS/popup.sh" "$ANCHOR" on
nohup "$PLUGINS/stat_$KIND.sh" loop >/dev/null 2>&1 &
