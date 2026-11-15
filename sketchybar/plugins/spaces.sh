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

# Flat style: the test switch (plugins/smart_demo.sh on workspaces) pretends every workspace holds six
# apps, to check the widest the app icons can get ("+2" after four)
FLATSTYLE=; [ -r "$HOME/.config/sketchybar/.barstyle" ] && read -r FLATSTYLE < "$HOME/.config/sketchybar/.barstyle"
SDIR="${TMPDIR:-/tmp}/sketchybar_smart"
if [ "$FLATSTYLE" = flat ] && [ -e "$SDIR/demo.workspaces" ]; then
  WINDOWS=""
  for d in 1 2 3 4 5; do
    for a in "Brave Browser" Ghostty Slack Finder Spotify WhatsApp; do WINDOWS+="$d|$a"$'\n'; done
  done
fi

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
if [ "$BAR_STYLE" = flat ]; then
  source "$HOME/.config/sketchybar/plugins/flat_config.sh"; flat_colors
  [ -d "$SDIR" ] || mkdir -p "$SDIR"
  echo "$FOCUSED" > "$SDIR/ws.focus"
fi

# Written by items/spaces.sh when the bar loads
SPACE_IDS=$(cat "${TMPDIR:-/tmp}/sketchybar_spaces" 2>/dev/null)
[ -n "$SPACE_IDS" ] || SPACE_IDS=$(visible_workspaces)

args=()
for sid in $SPACE_IDS; do
  icons=""
  if [ "$BAR_STYLE" != flat ]; then
    while IFS='|' read -r ws app; do
      [ "$ws" = "$sid" ] && [ -n "$app" ] || continue
      __icon_map "$app"
      icons+="$icon_result "
    done <<< "$WINDOWS"
  fi

  if [ "$BAR_STYLE" = flat ]; then
    # Plain numbers with their app icons (at most FLAT_WS_MAX_ICONS, then "+N"). The focused workspace is
    # in the accent on a faint marker, the others neutral, an empty one a dim number. The colours are set
    # directly (not through highlight) so the change animates.
    n=0; shown=""
    while IFS='|' read -r ws app; do
      [ "$ws" = "$sid" ] && [ -n "$app" ] || continue
      n=$((n + 1))
      if [ "$n" -le "$FLAT_WS_MAX_ICONS" ]; then __icon_map "$app"; shown+="$icon_result "; fi
    done <<< "$WINDOWS"
    extra=$((n - FLAT_WS_MAX_ICONS)); [ "$extra" -lt 0 ] && extra=0
    if [ "$sid" = "$FOCUSED" ]; then ic=$ACCENT; lc=$ACCENT; marker=$ACCENT_FILL
    elif [ "$n" -gt 0 ]; then ic=$FLAT_REST; lc=$GREY; marker=$TRANSPARENT
    else ic=$FLAT_DIM; lc=$GREY; marker=$TRANSPARENT; fi
    drawing=on; padr=4; [ "$n" -eq 0 ] && { drawing=off; padr=7; }
    more=off; [ "$extra" -gt 0 ] && more=on
    printf '%s %s\n' "$ic" "$lc" > "$SDIR/ws.$sid"
    args+=(--set space.$sid icon.highlight=off icon.color=$ic label.color=$lc label="${shown% }"
                            label.drawing=$drawing icon.padding_right=$padr
                            background.color=$marker background.border_width=0 background.height=20
           --set spacemore.$sid label="+$extra" label.drawing=$more label.color=$lc)
    continue
  fi

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

ANIM="tanh 10"; [ "$BAR_STYLE" = flat ] && ANIM=$FLAT_ANIM_WS
sketchybar --animate $ANIM "${args[@]}"
