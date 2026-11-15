#!/bin/bash
# The flat style's smart items: they appear only when they have something to say and take no space
# otherwise (see plugins/smart_lib.sh). Sourced by items/flat.sh, which then orders them. The values
# that decide WHEN they show live in plugins/flat_config.sh; the test switch is plugins/smart_demo.sh.
#
# Right group, left end (right to left as added, so left to right on screen):
#   music, market, mic/camera, VPN, keep-awake, Homebrew updates, Slack, WhatsApp | stats | tray
# After the clock: next meeting, then the focus timer (zero-width centre items: they draw to the
# right of the clock and never move it).

source "$PLUGIN_DIR/flat_config.sh"
flat_colors

TRANSP=0x00000000
# Properties that make an item take no space and show nothing
collapsed=(
  drawing=on
  updates=on
  padding_left=0 padding_right=0
  icon.width=0 icon.padding_left=0 icon.padding_right=0 icon.color=$TRANSP
  label.width=0 label.padding_left=0 label.padding_right=0 label.color=$TRANSP label.align=left
  background.drawing=off
)
sym="$FONT:Medium:$FLAT_ICON_FONT_SIZE"
txt="$TEXT_FONT:Medium:12.0"
nf="Maple Mono NF:Bold:$FLAT_NF_FONT_SIZE"

sketchybar --add event smart_refresh

# --- Mic / camera (existing item, was hidden in flat) ----------------------------------------------
sketchybar --set privacy position=right "${collapsed[@]}"                      \
                         update_freq=$FLAT_POLL_PRIVACY                       \
                         icon=$MIC icon.font="$sym" icon.drawing=on             \
                         label=$CAMERA label.font="$sym" label.drawing=on       \
           --subscribe privacy smart_refresh

# --- VPN: a padlock, only while connected ------------------------------------------------------------
sketchybar --set vpn "${collapsed[@]}"                                          \
                     update_freq=$FLAT_POLL_VPN                                \
                     icon=$LOCK_FILL icon.font="$sym" label.drawing=on label.font="$txt" \
                     popup.height=$FLAT_POPUP_ROW_H                            \
           --subscribe vpn smart_refresh

# --- Keep-awake (new) ------------------------------------------------------------------------------------
sketchybar --add item awake right                                               \
           --set awake "${collapsed[@]}" icon=$AWAKE icon.font="$sym"           \
                       label.drawing=off                                       \
                       update_freq=$FLAT_POLL_AWAKE                           \
                       script="$PLUGIN_DIR/smart_awake.sh"                     \
           --subscribe awake system_woke smart_refresh

# --- Homebrew updates (new): icon and count; click lists them, never upgrades -------------------------
sketchybar --add item updates right                                             \
           --set updates "${collapsed[@]}" icon="$FLAT_UPDATES_ICON" icon.font="$nf" \
                         label="" label.font="$txt"                            \
                         update_freq=$FLAT_POLL_UPDATES                       \
                         popup.align=right popup.height=$FLAT_POPUP_ROW_H       \
                         script="$PLUGIN_DIR/brew_updates.sh"                  \
                         click_script="$PLUGIN_DIR/brew_updates.sh click"      \
           --subscribe updates system_woke smart_refresh mouse.exited.global

# --- Slack and WhatsApp unread counts (existing badges; Telegram and Outlook stay hidden) ------------
for b in slack whatsapp; do
  sketchybar --set badge.$b "${collapsed[@]}" icon.font="sketchybar-app-font:Regular:13.0" \
                            label.font="$txt"
done
sketchybar --set badges update_freq=$FLAT_POLL_BADGES updates=on \
           --subscribe badges smart_refresh

# --- Market (new): BTC / gold while a trading window is open. Up to three symbols, one label each. ----
for i in 1 2 3; do
  sketchybar --add item market.$i right                                         \
             --set market.$i "${collapsed[@]}" icon.drawing=off label.font="$txt" \
                             popup.align=left popup.height=$FLAT_POPUP_ROW_H     \
                             click_script="$PLUGIN_DIR/market.sh click"
done
# The first one runs the script (events and the slow timer); the rest are fed by it
sketchybar --set market.1 update_freq=$FLAT_POLL_MARKET script="$PLUGIN_DIR/market.sh" \
           --subscribe market.1 aerospace_focus_change aerospace_workspace_change system_woke smart_refresh mouse.exited.global

# --- Music (existing Spotify anchor, compact): icon and title, hidden unless playing ------------------
sketchybar --set spotify.anchor position=right "${collapsed[@]}"                 \
                                icon=$SPOTIFY icon.font="$sym" label.font="$txt"   \
                                label.y_offset=0 y_offset=0                       \
                                popup.height=150 popup.align=right                \
           --subscribe spotify.anchor smart_refresh

# --- Next meeting and focus timer, after the clock --------------------------------------------------------
sketchybar --set next_event position=center width=0 "${collapsed[@]}"            \
                            update_freq=$FLAT_POLL_MEETING                      \
                            icon=$CALENDAR icon.font="$sym" label.font="$txt"     \
                            label.max_chars=40                                  \
           --subscribe next_event smart_refresh                                \
           --set timer position=center width=0 "${collapsed[@]}"                \
                       icon=$TIMER_ICON icon.font="$sym" icon.drawing=on        \
                       label.drawing=on label.font="$txt" label.color=$TRANSP    \
           --subscribe timer smart_refresh mouse.entered mouse.exited

# Once the bar is up: every smart item reads its state, and music picks up a song that is already playing
AFTER_LOAD+=("$PLUGIN_DIR/spotify.sh initflat" "/usr/local/bin/sketchybar --trigger smart_refresh")

# The music popup (hover on the music item) in the same quiet look: neutral controls, no green pill
sketchybar --set spotify.controls background.color=$BACKGROUND_2 background.corner_radius=$FLAT_POPUP_RADIUS \
           --set spotify.shuffle icon.color=$FLAT_HOVER icon.highlight_color=$ACCENT \
           --set spotify.back icon.color=$FLAT_HOVER \
           --set spotify.next icon.color=$FLAT_HOVER \
           --set spotify.repeat icon.color=$FLAT_HOVER icon.highlight_color=$ACCENT \
           --set spotify.play background.corner_radius=$FLAT_POPUP_RADIUS background.height=30 \
           --set spotify.state slider.highlight_color=$ACCENT slider.background.color=$BACKGROUND_2
