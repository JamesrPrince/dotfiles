#!/bin/bash
# System stats: CPU graph and load, memory, network speed. Each has its own popup
# (items/stat_popups.sh): net.up/net.down, cpu.percent/cpu.graph, mem.

CPU_TOGGLE="$PLUGIN_DIR/stat_popup.sh cpu.percent cpu"
MEM_TOGGLE="$PLUGIN_DIR/stat_popup.sh mem mem"
NET_TOGGLE="$PLUGIN_DIR/stat_popup.sh net.up net"

cpu_graph=(
  graph.color=$BLUE
  graph.fill_color=$ACCENT_FILL
  label.drawing=off
  icon.drawing=off
  background.height=26
  background.drawing=on
  background.color=$TRANSPARENT
  width=48
  padding_left=0
  padding_right=4
  click_script="$CPU_TOGGLE"
)

cpu_percent=(
  icon=$CPU
  icon.color=$BLUE
  icon.font="$FONT:Regular:14.0"
  label="--%"
  label.font="$TEXT_FONT:ExtraBold:12.0"
  label.width=34
  label.align=right
  padding_left=6
  padding_right=0
  update_freq=3
  updates=on
  popup.align=left
  popup.height=24
  script="$PLUGIN_DIR/stats.sh"
  click_script="$CPU_TOGGLE"
)

mem=(
  icon=$MEMORY
  icon.color=$MAGENTA
  icon.font="$FONT:Regular:14.0"
  label="--%"
  label.font="$TEXT_FONT:ExtraBold:12.0"
  label.width=34
  label.align=right
  padding_left=8
  padding_right=2
  popup.align=left
  popup.height=24
  script="$PLUGIN_DIR/stat_item.sh"
  click_script="$MEM_TOGGLE"
)

net=(
  icon.drawing=off
  label.font="$TEXT_FONT:ExtraBold:9.0"
  label.width=58
  label.align=right
  y_offset=6
  padding_left=8
  padding_right=0
  click_script="$NET_TOGGLE"
)

popup_row=(
  icon.font="$FONT:Regular:14.0"
  icon.width=26
  label.font="$TEXT_FONT:SemiBold:13.0"
  padding_left=8
  padding_right=12
)

# net.down is added first: it is zero-width, and its text then lines up under net.up's
sketchybar --add item net.down left              \
           --set net.down "${net[@]}" y_offset=-5 width=0 \
           --add item net.up left                \
           --set net.up "${net[@]}" popup.align=left popup.height=24 script="$PLUGIN_DIR/stat_item.sh" \
           --subscribe net.up mouse.exited.global \
           --add item mem left                   \
           --set mem "${mem[@]}"                 \
           --subscribe mem mouse.exited.global   \
           --add item cpu.percent left           \
           --set cpu.percent "${cpu_percent[@]}" \
           --subscribe cpu.percent system_woke mouse.exited.global \
           --add graph cpu.graph left 100        \
           --set cpu.graph "${cpu_graph[@]}"

sketchybar --add bracket stats net.down net.up mem cpu.percent cpu.graph \
           --set stats background.color=$BACKGROUND_1                    \
                       background.border_color=$BACKGROUND_2             \
                       background.border_width=2                         \
                       background.drawing=on

source "$ITEM_DIR/stat_popups.sh"
