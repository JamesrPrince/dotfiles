#!/bin/bash

export PATH="/usr/local/bin:$PATH"

WIDTH=70

detail_on() {
  sketchybar --animate tanh 30 --set volume slider.width=$WIDTH
}

detail_off() {
  sketchybar --animate tanh 30 --set volume slider.width=0
}

toggle_detail() {
  INITIAL_WIDTH=$(sketchybar --query volume | jq -r ".slider.width")
  if [ "$INITIAL_WIDTH" -eq "0" ]; then
    detail_on
  else
    detail_off
  fi
}

toggle_devices() {
  AUDIO="$HOME/.config/sketchybar/helper/audio"
  [ -x "$AUDIO" ] || exit 0
  source "$HOME/.config/sketchybar/colors.sh"
  source "$HOME/.config/sketchybar/icons.sh"

  args=(--remove '/volume.device\..*/' --set "$NAME" popup.align=right)
  COUNTER=0
  CURRENT="$("$AUDIO" current)"
  while IFS= read -r device; do
    [ -z "$device" ] && continue
    COLOR=$GREY
    [ "$device" = "$CURRENT" ] && COLOR=$WHITE
    # The row passes its index, not its name, so names with spaces or quotes are safe.
    args+=(--add item volume.device.$COUNTER popup."$NAME" \
           --set volume.device.$COUNTER label="$device" label.color="$COLOR" \
                 icon=$SPEAKER icon.color="$COLOR" icon.width=26 \
                 padding_left=8 padding_right=14 \
                 click_script="$HOME/.config/sketchybar/plugins/audio_switch.sh $COUNTER")
    COUNTER=$((COUNTER+1))
  done <<< "$("$AUDIO" list)"

  sketchybar -m "${args[@]}" > /dev/null
  "$HOME/.config/sketchybar/plugins/popup.sh" "$NAME"
}

if [ "$BUTTON" = "right" ] || [ "$MODIFIER" = "shift" ]; then
  toggle_devices
else
  toggle_detail
fi
