#!/bin/bash
# Click on a workspace number. Usage (click_script): space_click.sh <workspace>
#   left-click   switch to the workspace (unchanged)
#   right-click  popup listing that workspace's windows; click a row to focus it

export PATH="/usr/local/bin:$PATH"
SID=$1
PLUGINS="$HOME/.config/sketchybar/plugins"

if [ "$BUTTON" != "right" ]; then
  aerospace workspace "$SID"
  exit 0
fi

# A second right-click closes it
if [ "$(sketchybar --query space.$SID | jq -r '.popup.drawing')" = "on" ]; then
  "$PLUGINS/popup.sh" space.$SID off
  exit 0
fi

source "$PLUGINS/icon_map.sh"
source "$HOME/.config/sketchybar/colors.sh"

# Drop the rows of the previous opening, and any other workspace's popup
sketchybar --remove '/spwin\..*/' >/dev/null 2>&1
for other in $(sketchybar --query bar | jq -r '.items[]' | grep '^space\.[^.]*$'); do
  [ "$other" = "space.$SID" ] || sketchybar --set "$other" popup.drawing=off
done

args=()
n=0
while IFS='|' read -r wid app title; do
  [ -n "$wid" ] || continue
  __icon_map "$app"
  [ -n "$title" ] || title="$app"
  name="spwin.$SID.$n"
  args+=(--add item "$name" popup.space.$SID
         --set "$name" icon="$icon_result" icon.font="sketchybar-app-font:Regular:16.0"
                       icon.width=30 icon.color=$WHITE
                       label="$title" label.max_chars=44 label.font="$TEXT_FONT:SemiBold:14.0"
                       padding_left=8 padding_right=12 background.corner_radius=7
                       script="$PLUGINS/hover.sh"
                       click_script="/usr/local/bin/aerospace focus --window-id $wid; /usr/local/bin/sketchybar --set space.$SID popup.drawing=off"
         --subscribe "$name" mouse.entered mouse.exited)
  n=$((n+1))
done < <(aerospace list-windows --workspace "$SID" --format '%{window-id}|%{app-name}|%{window-title}')

if [ "$n" -eq 0 ]; then
  args+=(--add item spwin.$SID.0 popup.space.$SID
         --set spwin.$SID.0 icon.drawing=off label="No windows" label.color=$GREY
                            label.font="$TEXT_FONT:SemiBold:13.0" padding_left=8 padding_right=12)
fi

sketchybar "${args[@]}"
"$PLUGINS/popup.sh" space.$SID on
