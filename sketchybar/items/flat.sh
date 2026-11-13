#!/bin/bash
# The flat style (see plugins/style.sh), modelled on Omarchy's Waybar (config/waybar in
# github.com/basecamp/omarchy: 26px bar, workspaces as numbers on the left, "Friday 14:05" in the
# middle, bluetooth, network, volume, cpu and battery as bare icons on the right, 8px side margins),
# plus the Apple logo and live machine stats, which James asked for.
#
# sketchybarrc sources this after every item has been added, so each name a plugin refers to still
# exists. It only moves, restyles and hides; Centre Stage never reads it.

# --- No pills ------------------------------------------------------------------------------------
sketchybar --set spaces background.drawing=off \
           --set status background.drawing=off \
           --set front background.drawing=off \
           --set stats background.drawing=off \
           --set mode background.drawing=off label.font="$TEXT_FONT:Bold:12.0"

# --- Left: the workspaces as plain numbers -------------------------------------------------------
# The focused one is in ACCENT (icon.highlight_color, set in items/spaces.sh) on a faint marker;
# plugins/spaces.sh colours it and greys the empty ones.
for sid in $SPACE_IDS; do
  sketchybar --set space.$sid position=left                  \
                              icon=$sid                      \
                              icon.font="$TEXT_FONT:SemiBold:13.0" \
                              icon.padding_left=7            \
                              icon.padding_right=7           \
                              padding_left=1                 \
                              padding_right=1                \
                              label.drawing=off              \
                              background.height=18           \
                              background.corner_radius=4
done

# --- Left, after the workspaces: the focused window's app icon and title --------------------------
# Ghostty has no title bar in this look (macos-titlebar-style = hidden), so the title lives here.
# max_chars keeps the longest title well clear of the clock in the centre.
sketchybar --add item window_title left                              \
           --set window_title script="$PLUGIN_DIR/window_title.sh"   \
                              update_freq=3                          \
                              icon.font="sketchybar-app-font:Regular:14.0" \
                              icon.color=$GREY                       \
                              icon.padding_left=0                    \
                              icon.padding_right=6                   \
                              label.font="$TEXT_FONT:Medium:12.0"    \
                              label.color=$WHITE                     \
                              label.max_chars=70                     \
                              padding_left=12                        \
                              padding_right=0                        \
           --subscribe window_title aerospace_focus_change aerospace_workspace_change front_app_switched

# --- Centre: the clock, weekday and time ---------------------------------------------------------
sketchybar --set calendar position=center                    \
                          icon.drawing=off                   \
                          label.font="$TEXT_FONT:SemiBold:13.0" \
                          label.width=dynamic                \
                          label.align=center                 \
                          padding_left=0                     \
                          padding_right=0                    \
                          update_freq=10                     \
                          popup.align=center

# --- Left: the Apple logo, before the workspaces; it opens the same popup as in Centre Stage -------
sketchybar --set apple.logo icon.color=$ICON_COLOR icon.font="$FONT:Bold:14.0" \
                            padding_left=4 padding_right=4

# --- Right, left to right: live stats, then the tray icons ------------------------------------------
#   network (up over down, stacked), CPU (percentage and graph), GPU, memory   |   bluetooth, Wi-Fi, volume, battery, control
# The stats are Centre Stage's own items, refreshed by plugins/stats.sh; they just move here with
# their labels showing, in fixed-width labels so a changing value never shifts its neighbours.
# plugins/stats.sh also feeds gpu.bar.
stat=(
  padding_left=4
  padding_right=4
  icon.padding_left=3
  icon.padding_right=2
  label.padding_left=2
  label.padding_right=3
)
sketchybar --add item gpu.bar right                                   \
           --set gpu.bar "${stat[@]}"                                  \
                         icon=GPU icon.font="$TEXT_FONT:Bold:9.0" icon.color=$GREEN \
                         label="--%" label.font="$TEXT_FONT:ExtraBold:12.0" \
                         label.width=34 label.align=right
# Network: up over down, stacked as in Centre Stage. net.down is zero-width and sits just right of
# net.up (a zero-width item on the right side draws leftwards), so its text draws under net.up's;
# both share font, width and padding to line up.
netstack=(
  label.font="$TEXT_FONT:Bold:9.0"
  label.width=72
  label.align=right
)
sketchybar --set net.up position=right "${stat[@]}" "${netstack[@]}"  \
                        y_offset=5                                    \
                        popup.align=right                             \
           --set net.down position=right "${stat[@]}" "${netstack[@]}" \
                          y_offset=-5 width=0 drawing=on              \
           --set cpu.percent position=right "${stat[@]}"              \
                             popup.align=right                       \
           --set mem position=right "${stat[@]}" popup.align=right

# The CPU graph is the same item as in Centre Stage (same name, so plugins/stats.sh keeps feeding it,
# and the same click opens the CPU popup). A graph's bounding rect always reports the width it was
# added with, so it is added again here at the flat width (44px) to keep the overlap check honest.
sketchybar --remove cpu.graph
sketchybar --add graph cpu.graph right 44                       \
           --set cpu.graph graph.color=$BLUE                   \
                           graph.fill_color=$ACCENT_FILL       \
                           label.drawing=off icon.drawing=off  \
                           background.height=20                \
                           background.drawing=on               \
                           background.color=$TRANSPARENT       \
                           padding_left=0 padding_right=4      \
                           click_script="$PLUGIN_DIR/stat_popup.sh cpu.percent cpu"

sketchybar --set battery label.drawing=off icon.font="$FONT:Regular:16.0" \
           --set volume_icon label.font="$FONT:Regular:14.0"

for item in bluetooth wifi volume_icon battery control; do
  sketchybar --set $item padding_left=5 padding_right=5
done
sketchybar --set bluetooth icon.padding_left=3 icon.padding_right=3 \
           --set wifi icon.padding_left=3 icon.padding_right=3      \
           --set control icon.padding_left=3 icon.padding_right=3

# Left to right: net.up, net.down (zero-width, drawn under net.up), cpu, gpu, mem, bluetooth, wifi, volume icon, volume slider,
# battery, control. The keys anchors (the shortcut sheet's popups) stay at the far right edge.
sketchybar --move control after keys     \
           --move battery after control  \
           --move volume after battery   \
           --move volume_icon after volume \
           --move wifi after volume_icon   \
           --move bluetooth after wifi     \
           --move mem after bluetooth      \
           --move gpu.bar after mem        \
           --move cpu.graph after gpu.bar   \
           --move cpu.percent after cpu.graph \
           --move net.down after cpu.percent \
           --move net.up after net.down

# --- The control entry also holds the shortcut sheet (the "more" item is not shown) ---------------
sketchybar --add item control.keys popup.control                 \
           --set control.keys icon=$KEYBOARD icon.color=$BLUE      \
                              icon.font="$FONT:Regular:15.0" icon.width=28 \
                              label="Shortcuts   ⌥⇧/"             \
                              label.font="$TEXT_FONT:SemiBold:13.0" \
                              padding_left=8 padding_right=14      \
                              click_script="/usr/bin/python3 $PLUGIN_DIR/keys.py toggle; /usr/local/bin/sketchybar --set control popup.drawing=off" \
           --move control.keys before control.settings

# --- Everything else is defined but not drawn ------------------------------------------------------
source "$PLUGIN_DIR/flat_hide.sh"   # sourced, so its calls join the load-time batch
