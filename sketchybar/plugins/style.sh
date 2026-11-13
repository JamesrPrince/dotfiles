#!/bin/bash
# The bar style, shared by sketchybarrc, the plugins and barstyle.sh. Source it.
#   centre  "Centre Stage": the floating bar with pills, workspaces in the middle (default)
#   flat    edge to edge and thin, like Omarchy's Waybar: no pills, icons only on the right
# The choice lives in ~/.config/sketchybar/.barstyle (git-ignored); a missing or unknown value
# means centre. Change it with plugins/barstyle.sh, never by editing this file.

# `read` is the shell's own: a $(cat ...) here would start a process for every plugin run
BAR_STYLE=; [ -r "$HOME/.config/sketchybar/.barstyle" ] && read -r BAR_STYLE < "$HOME/.config/sketchybar/.barstyle"
[ "$BAR_STYLE" = flat ] || BAR_STYLE=centre

if [ "$BAR_STYLE" = flat ]; then
  TEXT_FONT="Maple Mono NF"   # labels and text in the flat style
else
  TEXT_FONT="Nunito"          # labels and text in Centre Stage
fi

# AeroSpace's top gap = bar y_offset + bar height + the 8px gap to the windows
CENTRE_BAR_HEIGHT=39
FLAT_BAR_HEIGHT=28
CENTRE_TOP_GAP=57                        # 10 + 39 + 8
FLAT_TOP_GAP=$((FLAT_BAR_HEIGHT + 8))    # 0 + 28 + 8
