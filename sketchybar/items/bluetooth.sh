#!/bin/bash
# Bluetooth: the icon shows power and whether a device is connected. Click for
# the paired devices (click one to connect or disconnect it) and a power toggle.
# Talks to helper/SketchyBarBluetooth.app (IOBluetooth); plugins/bluetooth.sh fills the popup.

bluetooth=(
  icon=$BLUETOOTH_ICON
  icon.font="MesloLGS NF:Regular:16.0"   # Nerd Font glyph; SF Symbols has no Bluetooth symbol
  label.drawing=off
  padding_left=4
  padding_right=4
  update_freq=30
  updates=on
  popup.align=right
  popup.height=28
  script="$PLUGIN_DIR/bluetooth.sh"
  click_script="$PLUGIN_DIR/popup.sh bluetooth; NAME=bluetooth SENDER=refresh $PLUGIN_DIR/bluetooth.sh"
)

sketchybar --add item bluetooth right          \
           --set bluetooth "${bluetooth[@]}"   \
           --subscribe bluetooth system_woke mouse.entered mouse.exited mouse.exited.global

# The power row is permanent; the device rows (bluetooth.dev.N) are rebuilt by the plugin
sketchybar --add item bluetooth.power popup.bluetooth                       \
           --set bluetooth.power icon.font="$FONT:Regular:14.0" icon.width=26 \
                 label.font="$TEXT_FONT:SemiBold:13.0" label="Bluetooth"      \
                 padding_left=8 padding_right=12                              \
                 click_script="$PLUGIN_DIR/bluetooth.sh power"

# Shown only while macOS withholds Bluetooth access from SketchyBar (see plugins/bluetooth.sh)
sketchybar --add item bluetooth.note popup.bluetooth                              \
           --set bluetooth.note drawing=off icon=$BT_WARNING icon.color=$YELLOW      \
                 icon.font="$FONT:Regular:14.0" icon.width=26                        \
                 label="Click to allow Bluetooth access" label.color=$YELLOW      \
                 label.font="$TEXT_FONT:SemiBold:13.0" padding_left=8 padding_right=12 \
                 click_script="$PLUGIN_DIR/bluetooth.sh access"

# A reload drops the device rows, so make the plugin rebuild them
rm -f "${TMPDIR:-/tmp}/sketchybar_bluetooth_state"
