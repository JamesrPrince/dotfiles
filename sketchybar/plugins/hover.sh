#!/bin/bash
# Hover highlight. Plugins source this first; it handles mouse.entered and
# mouse.exited and stops the plugin there. Items with no plugin of their own
# use it as their script. The focused workspace keeps its accent pill.

case "$SENDER" in
  mouse.entered|mouse.exited) ;;
  *) return 0 2>/dev/null || exit 0 ;;
esac

export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/colors.sh"

# The flat bar has no hover pills. Items on the bar shift colour: icon.highlight / label.highlight turn on
# (their highlight colour is the full text colour; the resting colour is a quiet 80% of it), so a state
# colour a plugin sets on icon.color is never wiped by the hover. Workspaces recolour their own number
# and icons, and go back to the colours plugins/spaces.sh recorded. Rows inside popups keep a hover
# pill, with the flat radius.
if [ "$(cat "$HOME/.config/sketchybar/.barstyle" 2>/dev/null)" = flat ]; then
  source "$HOME/.config/sketchybar/plugins/flat_config.sh"
  SDIR="${TMPDIR:-/tmp}/sketchybar_smart"
  case "$NAME" in
    space.*)
      [ -r "$SDIR/ws.focus" ] && read -r FOC < "$SDIR/ws.focus"
      [ "${NAME#space.}" = "$FOC" ] && exit 0            # the focused one keeps its accent
      if [ "$SENDER" = "mouse.entered" ]; then
        flat_colors
        sketchybar --animate tanh 6 --set "$NAME" icon.color=$FLAT_HOVER label.color=$FLAT_HOVER
      else
        [ -r "$SDIR/ws.${NAME#space.}" ] && read -r ICOL LCOL < "$SDIR/ws.${NAME#space.}"
        [ -n "$ICOL" ] && sketchybar --animate tanh 6 --set "$NAME" icon.color=$ICOL label.color=$LCOL
      fi
      exit 0 ;;
    apple.logo|calendar|net.up|net.down|cpu.percent|gpu.bar|mem|bluetooth|wifi|volume_icon|control|battery|\
    vpn|updates|badge.*|market.*|next_event|timer|awake|privacy)
      if [ "$SENDER" = "mouse.entered" ]; then H=on; else H=off; fi
      args=(--set "$NAME" icon.highlight=$H label.highlight=$H)
      [ "$NAME" = net.up ] && args+=(--set net.down icon.highlight=$H label.highlight=$H)
      [ "$NAME" = net.down ] && args+=(--set net.up icon.highlight=$H label.highlight=$H)
      sketchybar "${args[@]}"
      exit 0 ;;
  esac
  # A popup row: a quiet pill
  if [ "$SENDER" = "mouse.entered" ]; then
    sketchybar --animate tanh 8 --set "$NAME" background.drawing=on background.color=$HOVER_COLOR \
               background.height=22 background.corner_radius=$FLAT_POPUP_RADIUS
  else
    sketchybar --animate tanh 8 --set "$NAME" background.color=$TRANSPARENT
  fi
  exit 0
fi

if [[ $NAME == space.* ]] && \
   [ "$(sketchybar --query "$NAME" | jq -r '.icon.highlight')" = "on" ]; then
  exit 0
fi

if [ "$SENDER" = "mouse.entered" ]; then
  sketchybar --animate tanh 8 --set "$NAME" background.drawing=on \
             background.color=$HOVER_COLOR background.height=24 background.corner_radius=7
else
  sketchybar --animate tanh 8 --set "$NAME" background.color=$TRANSPARENT
fi
exit 0
