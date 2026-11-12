#!/bin/bash
# GitHub notifications via the gh CLI: count on the icon, latest 8 in the popup.
export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/plugins/hover.sh"
source "$CONFIG_DIR/colors.sh"
TEXT_FONT="Nunito"
NAME=github

if [ "$SENDER" = "mouse.exited.global" ]; then
  sketchybar --set $NAME popup.drawing=off; exit 0
fi
if [ "$SENDER" = "mouse.clicked" ] && [ "$BUTTON" = "right" ]; then
  open "https://github.com/notifications"; exit 0
fi

json=$(gh api notifications 2>/dev/null) || { sketchybar --set $NAME icon.color=$GREY label.drawing=off; exit 0; }
count=$(jq length <<<"$json")

if [ "$count" -gt 0 ]; then
  sketchybar --set $NAME icon.color=$WHITE label="$count" label.drawing=on
else
  sketchybar --set $NAME icon.color=$GREY label.drawing=off
fi

# Popup only on a left click
[ "$1" = "click" ] || [ "$SENDER" = "mouse.clicked" ] || exit 0

sketchybar --remove '/github\.row\..*/' >/dev/null 2>&1
rows=()
if [ "$count" -eq 0 ]; then
  rows+=(--add item github.row.0 popup.$NAME --set github.row.0 label="No unread notifications" icon.drawing=off label.color=$GREY padding_left=10 padding_right=14)
else
  i=0
  while IFS=$'\t' read -r repo title url; do
    rows+=(--add item github.row.$i popup.$NAME
           --set github.row.$i icon="${repo#*/}" icon.color=$BLUE icon.font="$TEXT_FONT:Bold:12.0"
                 label="$title" label.max_chars=50 padding_left=10 padding_right=14
                 click_script="open '$url'; sketchybar --set $NAME popup.drawing=off")
    i=$((i+1))
  done < <(jq -r '.[0:8][] | [.repository.full_name, .subject.title,
      ((.subject.url // "") | sub("api.github.com/repos"; "github.com") | sub("/pulls/"; "/pull/")
       | if . == "" then "https://github.com/notifications" else . end)] | @tsv' <<<"$json")
fi
sketchybar "${rows[@]}"
"$HOME/.config/sketchybar/plugins/popup.sh" "$NAME"
