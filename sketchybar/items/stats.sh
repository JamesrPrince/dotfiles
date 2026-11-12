#!/bin/bash
# System stats: CPU graph and load, memory, GPU, network speed. Click any of them
# for a popup with CPU temperature, fan speed, disk and uptime.

POPUP_TOGGLE="$PLUGIN_DIR/popup.sh cpu.percent; NAME=cpu.percent $PLUGIN_DIR/stats.sh"

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
  click_script="$POPUP_TOGGLE"
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
  popup.align=right
  script="$PLUGIN_DIR/stats.sh"
  click_script="$POPUP_TOGGLE"
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
  click_script="$POPUP_TOGGLE"
)

gpu=(
  icon=GPU
  icon.color=$GREEN
  icon.font="$TEXT_FONT:ExtraBold:9.0"
  label="--%"
  label.font="$TEXT_FONT:ExtraBold:12.0"
  label.width=34
  label.align=right
  padding_left=8
  padding_right=2
  click_script="$POPUP_TOGGLE"
)

net=(
  icon.drawing=off
  label.font="$TEXT_FONT:ExtraBold:9.0"
  label.width=58
  label.align=right
  y_offset=6
  padding_left=8
  padding_right=0
  click_script="$POPUP_TOGGLE"
)

popup_row=(
  icon.font="$FONT:Regular:14.0"
  icon.width=26
  label.font="$TEXT_FONT:SemiBold:13.0"
  padding_left=8
  padding_right=12
)

sketchybar --add graph cpu.graph right 100       \
           --set cpu.graph "${cpu_graph[@]}"     \
           --add item cpu.percent right          \
           --set cpu.percent "${cpu_percent[@]}" \
           --subscribe cpu.percent system_woke   \
           --add item mem right                  \
           --set mem "${mem[@]}"                 \
           --add item gpu right                  \
           --set gpu "${gpu[@]}"                 \
           --add item net.down right             \
           --set net.down "${net[@]}" y_offset=-5 width=0 \
           --add item net.up right               \
           --set net.up "${net[@]}"

for row in temp fan disk uptime; do
  sketchybar --add item stats.$row popup.cpu.percent \
             --set stats.$row "${popup_row[@]}"
done

sketchybar --set stats.temp   icon=$THERMOMETER icon.color=$ORANGE \
           --set stats.fan    icon=$GEAR icon.color=$GREY          \
           --set stats.disk   icon=$DISK icon.color=$BLUE          \
           --set stats.uptime icon=$ACTIVITY icon.color=$GREEN

sketchybar --add bracket stats cpu.graph cpu.percent mem gpu net.up net.down \
           --set stats background.color=$BACKGROUND_1                    \
                       background.border_color=$BACKGROUND_2             \
                       background.border_width=2                         \
                       background.drawing=on
