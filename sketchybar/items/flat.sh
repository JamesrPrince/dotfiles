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

# --- Left: the workspaces as plain numbers, each with its app icons ------------------------------
# The focused one is in ACCENT on a faint marker, the others neutral, empty ones a dim number;
# plugins/spaces.sh colours them (directly, so the change animates) and fills the app icons
# (sketchybar-app-font, grey, at most FLAT_WS_MAX_ICONS, then "+N" in spacemore.<id>, which is
# an item of its own because the app font has no digits).
source "$PLUGIN_DIR/flat_config.sh"
flat_colors
for sid in $SPACE_IDS; do
  sketchybar --set space.$sid position=left                  \
                              icon=$sid                      \
                              icon.font="$TEXT_FONT:SemiBold:13.0" \
                              icon.color=$FLAT_DIM           \
                              icon.highlight_color=$FLAT_HOVER \
                              icon.padding_left=7            \
                              icon.padding_right=7           \
                              padding_left=1                 \
                              padding_right=0                \
                              label.font="sketchybar-app-font:Regular:13.0" \
                              label.color=$GREY              \
                              label.padding_left=0           \
                              label.padding_right=7          \
                              label.background.drawing=off   \
                              label.drawing=off              \
                              label.width=dynamic            \
                              popup.height=$FLAT_POPUP_ROW_H \
                              background.height=20           \
                              background.corner_radius=4     \
           --add item spacemore.$sid left                    \
           --set spacemore.$sid icon.drawing=off label="" label.drawing=off \
                              label.font="$TEXT_FONT:SemiBold:11.0" label.color=$GREY \
                              label.padding_left=0 label.padding_right=6    \
                              padding_left=0 padding_right=0                \
                              background.drawing=off                        \
                              click_script="$PLUGIN_DIR/space_click.sh $sid" \
           --move spacemore.$sid after space.$sid
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
# The world clock sits right of the clock, as Elsewhen does in Omarchy 4.5 (centerEnd, before weather)
sketchybar --set worldclock position=center                  \
                            icon.font="Maple Mono NF:Regular:$FLAT_NF_FONT_SIZE" \
                            icon.color=$FLAT_REST            \
                            icon.highlight_color=$FLAT_HOVER \
                            icon.width=16                    \
                            icon.align=center                \
                            icon.padding_left=0              \
                            icon.padding_right=0             \
                            padding_left=9                   \
                            padding_right=0                  \
                            popup.align=center               \
           --add item clock.pad center                       \
           --set clock.pad width=25 padding_left=0 padding_right=0 icon.drawing=off label.drawing=off \
                           background.drawing=off             \
           --move clock.pad before calendar
# clock.pad mirrors the globe's 25px (9 padding + 16 icon) on the clock's left, so the clock
# itself stays centred on the screen, as Omarchy's does

# --- Left: the Apple logo, before the workspaces; it opens the same popup as in Centre Stage -------
sketchybar --set apple.logo icon.color=$FLAT_REST icon.font="$FONT:Medium:15.0" \
                            icon.width=$FLAT_ICON_W icon.align=center icon.padding_left=0 icon.padding_right=0 \
                            padding_left=4 padding_right=4 popup.height=$FLAT_POPUP_ROW_H

# --- Right, left to right: smart items, live stats, a divider, then the tray icons ---------------------
#   [music market mic VPN awake badges]  net up/down, CPU % and graph, GPU, memory  |  bluetooth, Wi-Fi, volume, battery, control
# The stats are Centre Stage's own items, refreshed by plugins/stats.sh; they just move here with
# their labels showing, in fixed-width labels so a changing value never shifts its neighbours.
# They are neutral; colour appears only when a value needs James (plugins/stats.sh, flat_config.sh).
# plugins/stats.sh also feeds gpu.bar.
stat=(
  padding_left=4
  padding_right=4
  icon.padding_left=3
  icon.padding_right=2
  label.padding_left=2
  label.padding_right=3
  icon.color=$FLAT_REST
  label.color=$FLAT_REST
  icon.highlight_color=$FLAT_HOVER
  label.highlight_color=$FLAT_HOVER
)
sketchybar --add item gpu.bar right                                   \
           --set gpu.bar "${stat[@]}"                                  \
                         icon=GPU icon.font="$TEXT_FONT:Bold:9.0"      \
                         label="--%" label.font="$TEXT_FONT:ExtraBold:12.0" \
                         label.width=34 label.align=right
# Network: up over down, stacked as in Centre Stage. net.down is zero-width and sits just right of
# net.up (a zero-width item on the right side draws leftwards), so its text draws under net.up's;
# both share font, width and padding to line up.
netstack=(
  label.font="$TEXT_FONT:Bold:9.0"
  label.width=64
  label.align=right
)
sketchybar --set net.up position=right "${stat[@]}" "${netstack[@]}"  \
                        y_offset=5                                    \
                        popup.align=right popup.height=$FLAT_POPUP_ROW_H \
           --set net.down position=right "${stat[@]}" "${netstack[@]}" \
                          y_offset=-5 width=0 drawing=on              \
           --set cpu.percent position=right "${stat[@]}"              \
                             icon.font="$FONT:Medium:$FLAT_ICON_FONT_SIZE" \
                             popup.align=right popup.height=$FLAT_POPUP_ROW_H \
           --set mem position=right "${stat[@]}" popup.align=right    \
                     icon.font="$FONT:Medium:$FLAT_ICON_FONT_SIZE" popup.height=$FLAT_POPUP_ROW_H

# The CPU graph is the same item as in Centre Stage (same name, so plugins/stats.sh keeps feeding it,
# and the same click opens the CPU popup). A graph's bounding rect always reports the width it was
# added with, so it is added again here at the flat width (38px) to keep the overlap check honest.
sketchybar --remove cpu.graph
sketchybar --add graph cpu.graph right 38                       \
           --set cpu.graph graph.color=$FLAT_REST               \
                           graph.fill_color=$FLAT_GRAPH_FILL    \
                           label.drawing=off icon.drawing=off  \
                           background.height=20                \
                           background.drawing=on               \
                           background.color=$TRANSPARENT       \
                           padding_left=0 padding_right=4      \
                           click_script="$PLUGIN_DIR/stat_popup.sh cpu.percent cpu"

# --- The tray: one icon weight (SF Pro Medium 14; the two Nerd Font glyphs are Bold 15, which draws as
# heavy), one icon cell (20 wide, centred), even spacing. Their plugins colour them only on a state.
tray=(
  padding_left=$FLAT_ICON_PAD
  padding_right=$FLAT_ICON_PAD
  icon.font="$FONT:Medium:$FLAT_ICON_FONT_SIZE"
  icon.width=$FLAT_ICON_W
  icon.align=center
  icon.padding_left=0
  icon.padding_right=0
  icon.color=$FLAT_REST
  icon.highlight_color=$FLAT_HOVER
  label.highlight_color=$FLAT_HOVER
)
sketchybar --set bluetooth "${tray[@]}" icon.font="Maple Mono NF:Bold:$FLAT_NF_FONT_SIZE" popup.height=$FLAT_POPUP_ROW_H \
           --set wifi "${tray[@]}" popup.height=$FLAT_POPUP_ROW_H           \
           --set control "${tray[@]}" popup.height=$FLAT_POPUP_ROW_H        \
           --set battery "${tray[@]}" icon.width=24                         \
                         label.drawing=on label.width=0 label.padding_left=0 label.padding_right=0 \
                         label.color=$TRANSPARENT label.font="$TEXT_FONT:SemiBold:12.0" \
           --set volume_icon padding_left=$FLAT_ICON_PAD padding_right=$FLAT_ICON_PAD \
                             label.font="$FONT:Medium:$FLAT_ICON_FONT_SIZE" label.width=$FLAT_ICON_W \
                             label.align=center label.padding_left=0 label.padding_right=0 \
                             label.color=$FLAT_REST label.highlight_color=$FLAT_HOVER \
                             popup.height=$FLAT_POPUP_ROW_H

# A thin, quiet divider between the stats and the tray
sketchybar --add item flat.div right                                \
           --set flat.div width=1 icon.drawing=off label.drawing=off \
                          padding_left=7 padding_right=7             \
                          background.drawing=on background.height=14 \
                          background.corner_radius=0 background.color=$FLAT_DIVIDER

# --- The smart items: appear only when relevant (items/flat_smart.sh) -----------------------------------
source "$ITEM_DIR/flat_smart.sh"
sketchybar --subscribe battery smart_refresh

# The order, right to left (a later "after" sits to the left of the one before it):
#   keys anchors | control, battery, volume, volume icon, Wi-Fi, bluetooth | divider |
#   memory, GPU, CPU graph, CPU %, net down (zero-width), net up |
#   WhatsApp, Slack, keep-awake, VPN, mic/camera, market 3-2-1, music
# net.down must stay right of net.up (a zero-width item on the right side draws leftwards).
sketchybar --move control after keys     \
           --move battery after control  \
           --move volume after battery   \
           --move volume_icon after volume \
           --move wifi after volume_icon   \
           --move bluetooth after wifi     \
           --move flat.div after bluetooth \
           --move mem after flat.div       \
           --move gpu.bar after mem        \
           --move cpu.graph after gpu.bar   \
           --move cpu.percent after cpu.graph \
           --move net.down after cpu.percent \
           --move net.up after net.down      \
           --move badge.whatsapp after net.up \
           --move badge.slack after badge.whatsapp \
           --move claude after badge.slack     \
           --move awake after badge.slack    \
           --move vpn after awake            \
           --move privacy after vpn          \
           --move market.3 after privacy     \
           --move market.2 after market.3    \
           --move market.1 after market.2    \
           --move spotify.anchor after market.1 \
           --move worldclock after calendar  \
           --move next_event after worldclock \
           --move timer after next_event

# --- The control entry also holds the shortcut sheet and the focus timer (the "more" item is not shown) -
sketchybar --add item control.keys popup.control                 \
           --set control.keys icon=$KEYBOARD icon.color=$BLUE      \
                              icon.font="$FONT:Regular:15.0" icon.width=28 \
                              label="Shortcuts   ⌥⇧/"             \
                              label.font="$TEXT_FONT:SemiBold:13.0" \
                              padding_left=8 padding_right=14      \
                              click_script="/usr/bin/python3 $PLUGIN_DIR/keys.py toggle; /usr/local/bin/sketchybar --set control popup.drawing=off" \
           --move control.keys before control.settings             \
           --add item control.timer popup.control                  \
           --set control.timer icon=$TIMER_ICON icon.color=$GREY    \
                               icon.font="$FONT:Regular:15.0" icon.width=28 \
                               label="Focus timer   25 min  (right-click: 50)" \
                               label.font="$TEXT_FONT:SemiBold:13.0" \
                               padding_left=8 padding_right=14      \
                               click_script="NAME=timer SENDER=mouse.clicked BUTTON=\$BUTTON $PLUGIN_DIR/timer.sh; /usr/local/bin/sketchybar --set control popup.drawing=off" \
           --move control.timer before control.settings            \
           --add item control.updates popup.control                \
           --set control.updates drawing=off icon="$FLAT_UPDATES_ICON" icon.color=$GREY \
                                 icon.font="Maple Mono NF:Bold:15.0" icon.width=28 \
                                 label="Updates" label.font="$TEXT_FONT:SemiBold:13.0" \
                                 padding_left=8 padding_right=14      \
                                 click_script="$PLUGIN_DIR/brew_updates.sh toggle" \
           --move control.updates before control.settings
# The control popup opens through plugins/control.sh; in flat it also lets the Homebrew row read its cache
sketchybar --set control click_script="$PLUGIN_DIR/popup.sh control; NAME=control $PLUGIN_DIR/control.sh refresh; $PLUGIN_DIR/brew_updates.sh row"

# --- Popups in the bar's own language: radius 4, a 1 px quiet border (the defaults in sketchybarrc),
# rows of one height and one padding, hover pills with the same radius (plugins/hover.sh).
sketchybar --set '/^(apple\.(prefs|activity|lock)|control\.[a-z]+|wifi\.(ssid|ip|router|signal|channel|advice|speed|speed\.result|toggle)|wifi\.(saved|near)\.[0-9]|wifi\.hdr\.(saved|near)|bluetooth\.(power|note)|np\.[a-z0-9.]+|cp\.[a-z0-9.]+|mp\.[a-z0-9.]+)$/' \
                  padding_left=8 padding_right=12 background.corner_radius=$FLAT_POPUP_RADIUS \
           --set '/^space\.[0-9A-Za-z]+$/' popup.height=$FLAT_POPUP_ROW_H

# --- Hover: a quiet colour shift (icon.highlight / label.highlight), no pills ---------------------------
sketchybar --set gpu.bar icon.highlight_color=$FLAT_HOVER
for item in apple.logo calendar worldclock net.up net.down cpu.percent mem bluetooth wifi volume_icon control \
            vpn badge.slack badge.whatsapp claude market.1 market.2 market.3 next_event timer; do
  sketchybar --subscribe $item mouse.entered mouse.exited
done
for sid in $SPACE_IDS; do sketchybar --subscribe space.$sid mouse.entered mouse.exited; done
sketchybar --set market.2 script="$PLUGIN_DIR/hover.sh" --set market.3 script="$PLUGIN_DIR/hover.sh"

# --- Everything else is defined but not drawn ------------------------------------------------------
source "$PLUGIN_DIR/flat_hide.sh"   # sourced, so its calls join the load-time batch
