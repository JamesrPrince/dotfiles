#!/bin/bash
# Polls the clipboard every 2 seconds (helper/clip) and builds the history popup on click.

export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/plugins/hover.sh"
CLIP="$HOME/.config/sketchybar/helper/clip"

case "$SENDER" in
  mouse.exited.global) sketchybar --set clipboard popup.drawing=off; exit 0 ;;
  click) ;;
  *) "$CLIP" poll >/dev/null; exit 0 ;;
esac

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
FONT="SF Pro"
PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

"$CLIP" poll >/dev/null
row=(icon.font="$FONT:Bold:11.0" icon.width=22 icon.color=$GREY
     label.font="$FONT:Semibold:13.0" padding_left=8 padding_right=12)
args=(--remove '/clipboard\.row\..*/')
N=0
while IFS=$'\t' read -r i text; do
  [ -z "$i" ] && continue
  args+=(--add item clipboard.row.$i popup.clipboard
         --set clipboard.row.$i "${row[@]}" icon="$((i+1))" label="$text"
               click_script="$CLIP copy $i; sketchybar --set clipboard popup.drawing=off")
  N=$((N+1))
done < <("$CLIP" list 10)

if [ $N -eq 0 ]; then
  args+=(--add item clipboard.row.empty popup.clipboard
         --set clipboard.row.empty "${row[@]}" icon=$COPY label="Nothing copied yet")
else
  args+=(--add item clipboard.row.clear popup.clipboard
         --set clipboard.row.clear "${row[@]}" icon="×" icon.color=$RED label="Clear history" label.color=$GREY
               click_script="$CLIP clear; sketchybar --set clipboard popup.drawing=off")
fi

sketchybar "${args[@]}" >/dev/null 2>&1
"$PLUGIN_DIR/popup.sh" clipboard toggle
