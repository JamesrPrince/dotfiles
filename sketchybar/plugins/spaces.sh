#!/bin/bash
# Refreshes every workspace item: the app icons on each workspace, and the
# focused one highlighted (its icons fold away, as in Felix's bar).

export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/plugins/icon_map.sh"

FOCUSED="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}"

args=()
for sid in $(aerospace list-workspaces --all); do
  icons=""
  while IFS= read -r app; do
    [ -n "$app" ] || continue
    __icon_map "$app"
    icons+="$icon_result "
  done <<< "$(aerospace list-windows --workspace "$sid" --format '%{app-name}' | sort -u)"

  selected=off
  width=dynamic
  if [ "$sid" = "$FOCUSED" ]; then
    selected=on
    width=0
  fi
  drawing=on
  [ -z "$icons" ] && drawing=off

  args+=(--set space.$sid icon.highlight=$selected label="${icons% }"
                          label.drawing=$drawing label.width=$width)
done

sketchybar --animate tanh 20 "${args[@]}"
