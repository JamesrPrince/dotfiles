#!/bin/bash
# Battery item and its popup (Omarchy 4.5 power panel). Click the icon to open it.
# The rows are filled, and the profile buttons handled, by plugins/battery_popup.sh.
# Sourced from sketchybarrc.

battery=(
  script="$PLUGIN_DIR/battery.sh"
  click_script="$PLUGIN_DIR/battery_popup.sh toggle"
  icon.font="$FONT:Regular:19.0"
  padding_right=5
  padding_left=0
  label.font="$TEXT_FONT:ExtraBold:12.0"
  label.padding_left=4
  update_freq=60
  updates=on
  popup.align=right
)

sketchybar --add item battery right      \
           --set battery "${battery[@]}" \
           --subscribe battery power_source_change system_woke mouse.exited.global

# Popup rows. One column: a popup stacks its items vertically.
bp_row=(
  icon.font="$TEXT_FONT:SemiBold:12.0"
  icon.color=$GREY
  icon.width=130
  icon.align=left
  label.font="$TEXT_FONT:SemiBold:13.0"
  label.width=150
  label.align=right
  padding_left=8
  padding_right=12
  background.corner_radius=6
)
bp_add() { local name=$1; shift; sketchybar --add item $name popup.battery --set $name "${bp_row[@]}" "$@"; }

# Header: glyph and title, the status in small caps, the big percentage, the bar
bp_add battery.head icon.font="$FONT:Regular:24.0" icon.color=$WHITE icon.width=42 \
       label.font="$TEXT_FONT:ExtraBold:15.0" label.width=250 label.align=left label="Battery"
bp_add battery.sub  icon.drawing=off label.font="$TEXT_FONT:ExtraBold:10.0" label.color=$GREY \
       label.width=290 label.align=left label.padding_left=42 label=""
bp_add battery.pct  icon.drawing=off label.font="$TEXT_FONT:ExtraBold:28.0" label.width=290 \
       label.align=left label.padding_left=42 label="…" background.height=40
sketchybar --add slider battery.bar popup.battery 290                 \
           --set battery.bar padding_left=8 padding_right=12 icon.drawing=off label.drawing=off \
                 slider.highlight_color=$WHITE slider.background.height=8 \
                 slider.background.corner_radius=4 slider.background.color=$BACKGROUND_2 \
                 slider.knob.drawing=off slider.percentage=0

# The grid
bp_add battery.size   icon="Battery size"   label="…"
bp_add battery.cycles icon="Charge cycles"  label="…"
bp_add battery.time   icon="Time left"      label="…"
bp_add battery.state  icon="Battery state"  label="…"
bp_add battery.health icon="Health"         label="…"

# Power profile: Power-saver = Low Power Mode on, Balanced = off. Performance does not exist on this Mac.
bp_add battery.hdr icon.drawing=off label="POWER PROFILE" label.color=$GREY \
       label.font="$TEXT_FONT:ExtraBold:10.0" label.width=290 label.align=left
prof=(
  icon.font="MesloLGS Nerd Font Mono:Regular:15.0"
  icon.color=$WHITE icon.width=42 icon.align=center
  label.font="$TEXT_FONT:SemiBold:13.0" label.color=$WHITE label.width=248 label.align=left
  script="$PLUGIN_DIR/battery_popup.sh"
)
bp_add battery.prof.saver "${prof[@]}" icon="󰌪" label="Power-saver" \
       click_script="$PLUGIN_DIR/battery_popup.sh set 1"
bp_add battery.prof.bal   "${prof[@]}" icon="󰊚" label="Balanced" \
       click_script="$PLUGIN_DIR/battery_popup.sh set 0"
bp_add battery.prof.perf  "${prof[@]}" icon="󰓅" label="Performance   n/a on Intel" \
       icon.color=$GREY label.color=$GREY script=""
bp_add battery.err icon.drawing=off label="needs sudoers rule" label.color=$ORANGE \
       label.width=290 label.align=left label.padding_left=42 drawing=off
sketchybar --subscribe battery.prof.saver mouse.entered mouse.exited \
           --subscribe battery.prof.bal mouse.entered mouse.exited
