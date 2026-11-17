#!/bin/bash
# A two-second toast under the bar's clock: the active theme's name and its preview thumbnail
# (the palette strip is along the bottom of it). After Omarchy 4.5's theme picker.
#   theme_toast.sh          show the active theme now
#   theme_toast.sh --wait   wait for a bar reload that is under way (theme.sh sets theme_toast.wait
#                           first; a reload wipes that item), then show
# Runs detached from theme.sh next (alt-shift-t); a newer toast replaces an older one.
# Never sets popup.height=-1 (it crashes SketchyBar 2.24).

export PATH="/usr/local/bin:$PATH"
CONF="$HOME/.config/sketchybar"
DOT="$(cd -P "$CONF" && cd .. && pwd -P)"
SECONDS_SHOWN=2
PIDF="${TMPDIR:-/tmp}/sketchybar_theme_toast.pid"

[ -f "$PIDF" ] && kill "$(cat "$PIDF")" 2>/dev/null
echo $$ > "$PIDF"

if [ "$1" = "--wait" ]; then
  # Reload done = the sentinel is gone (the reload wiped it), keys.tab.page exists (the last item
  # sketchybarrc adds, from AFTER_LOAD) and the clock has been drawn (it has bounding_rects). A query
  # that fails, as while the bar restarts, is none of these. Gives up after about 40 s.
  for _ in $(seq 130); do
    if ! sketchybar --query theme_toast.wait >/dev/null 2>&1 && sketchybar --query keys.tab.page >/dev/null 2>&1 \
       && [ "$(sketchybar --query calendar 2>/dev/null | jq -r '.bounding_rects | length' 2>/dev/null)" -ge 1 ] 2>/dev/null; then
      break
    fi
    sleep 0.3
  done
  sleep 0.4
fi

source "$CONF/colors.sh"
source "$CONF/plugins/style.sh"
thumb="$DOT/themes/$THEME/preview-thumb.png"

sketchybar --remove theme_toast.wait --remove theme_toast.img --remove theme_toast.name --remove theme_toast >/dev/null 2>&1
args=(
  --add item theme_toast center
  --set theme_toast width=0 padding_left=0 padding_right=0 icon.drawing=off label.drawing=off
        background.drawing=off popup.align=center popup.y_offset=-12
        popup.background.color=$POPUP_BACKGROUND_COLOR popup.background.border_color=$ACCENT
        popup.background.border_width=2 popup.background.corner_radius=9
  --add item theme_toast.name popup.theme_toast
  --set theme_toast.name icon.drawing=off width=210 label="$THEME_NAME" label.align=center label.width=210
        label.color=$WHITE label.font="$TEXT_FONT:Bold:13.0"
        padding_left=0 padding_right=0
)
[ -f "$thumb" ] && args+=(
  --add item theme_toast.img popup.theme_toast
  --set theme_toast.img icon.drawing=off label.drawing=off width=210 background.height=119 background.drawing=on background.color=0x00000000
        padding_left=0 padding_right=0
        background.image="$thumb" background.image.scale=0.5 background.image.drawing=on
)
args+=(--set theme_toast popup.drawing=on --animate tanh 15 --set theme_toast popup.y_offset=0)
sketchybar "${args[@]}"
sketchybar --move theme_toast before worldclock 2>/dev/null

sleep "$SECONDS_SHOWN"
sketchybar --set theme_toast popup.drawing=off --remove theme_toast.img --remove theme_toast.name --remove theme_toast >/dev/null 2>&1
rm -f "$PIDF"
