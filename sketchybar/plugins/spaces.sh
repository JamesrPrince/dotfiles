#!/bin/bash
# Refreshes every workspace item: the app icons on each workspace, and the
# focused one in an accent pill (its icons fold away, as in Felix's bar),
# empty ones in grey.
#
# Several events fire for one switch (workspace change, focus change, window
# change), a few milliseconds apart. Each run waits 30ms and gives way if a
# newer one started, so only the last of a burst reads AeroSpace, once it has
# settled. It then compares the state with the last one drawn and stops if
# nothing moved, so the pill animates once instead of restarting.
# space_windows_change (a window opened or closed) comes from macOS before
# AeroSpace has registered the window, so that run first waits 250ms. It waits
# before taking its turn, so it never delays a workspace switch.

export PATH="/usr/local/bin:$PATH"
STATE_FILE="${TMPDIR:-/tmp}/sketchybar_spaces_state"
TOKEN_FILE="${TMPDIR:-/tmp}/sketchybar_spaces_token"

[ "$SENDER" = "space_windows_change" ] && sleep 0.25

TOKEN="$$.$RANDOM"
echo "$TOKEN" > "$TOKEN_FILE"
sleep 0.03
[ "$(cat "$TOKEN_FILE" 2>/dev/null)" = "$TOKEN" ] || exit 0

FOCUSED="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}"

# One AeroSpace call for every window, instead of one per workspace
WINDOWS=$(aerospace list-windows --all --format '%{workspace}|%{app-name}' | sort -u)

STATE="$FOCUSED"$'\n'"$WINDOWS"
case "$SENDER" in
  system_woke|forced) ;;   # always redraw after sleep or a bar reload
  *) [ "$STATE" = "$(cat "$STATE_FILE" 2>/dev/null)" ] && exit 0 ;;
esac
printf '%s' "$STATE" > "$STATE_FILE"

source "$HOME/.config/sketchybar/plugins/icon_map.sh"
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/plugins/style.sh"
source "$HOME/.config/sketchybar/workspaces.conf"

# Written by items/spaces.sh when the bar loads
SPACE_IDS=$(cat "${TMPDIR:-/tmp}/sketchybar_spaces" 2>/dev/null)
[ -n "$SPACE_IDS" ] || SPACE_IDS=$(visible_workspaces)

args=()
for sid in $SPACE_IDS; do
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

  if [ "$BAR_STYLE" = flat ]; then
    # Plain numbers: the focused one in the accent (highlight) on a faint marker, empty ones grey
    args+=(--set space.$sid icon.highlight=$selected icon.color=$color label.drawing=off
                            background.color=$pill background.border_width=0 background.height=18)
    continue
  fi
  args+=(--set space.$sid icon.highlight=$selected icon.color=$color label="${icons% }"
                          label.drawing=$drawing label.width=$width
                          background.color=$pill background.border_color=$ACCENT
                          background.border_width=$border background.height=26)
done

sketchybar --animate tanh 10 "${args[@]}"
