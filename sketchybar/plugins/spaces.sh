#!/bin/bash
# Refreshes every workspace item: the app icons on each workspace, and the
# focused one in an accent pill (its icons fold away, as in Felix's bar),
# empty ones in grey.

export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/plugins/icon_map.sh"
source "$HOME/.config/sketchybar/colors.sh"

FOCUSED="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}"

# One AeroSpace call for every window, instead of one per workspace
WINDOWS=$(aerospace list-windows --all --format '%{workspace}|%{app-name}' | sort -u)

args=()
for sid in $(aerospace list-workspaces --all); do
  icons=""
  while IFS='|' read -r ws app; do
    [ "$ws" = "$sid" ] && [ -n "$app" ] || continue
    __icon_map "$app"
    icons+="$icon_result "
  done <<< "$WINDOWS"

  selected=off
  width=dynamic
  pill=$TRANSPARENT
  border=0
  if [ "$sid" = "$FOCUSED" ]; then
    selected=on
    width=0
    pill=$ACCENT_FILL
    border=1
  fi
  drawing=on
  color=$WHITE
  if [ -z "$icons" ]; then
    drawing=off
    color=$GREY
  fi

  args+=(--set space.$sid icon.highlight=$selected icon.color=$color label="${icons% }"
                          label.drawing=$drawing label.width=$width
                          background.color=$pill background.border_color=$ACCENT
                          background.border_width=$border background.height=26)
done

sketchybar --animate tanh 20 "${args[@]}"
