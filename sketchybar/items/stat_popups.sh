#!/bin/bash
# The three stats popups. Click net.up/net.down for the network, cpu.percent or the CPU graph for
# the CPU, mem for memory. The rows are filled by plugins/stat_net.sh, stat_cpu.sh and stat_mem.sh,
# which only run while their popup is open. Sourced at the end of items/stats.sh.

row=(
  icon.font="$FONT:Regular:14.0"
  icon.width=26
  icon.color=$GREY
  label.font="$TEXT_FONT:SemiBold:13.0"
  label.max_chars=46
  padding_left=8
  padding_right=12
  background.corner_radius=7
)
header=(
  icon.drawing=off
  label.font="$TEXT_FONT:ExtraBold:11.0"
  label.color=$GREY
  padding_left=8
  padding_right=12
)
appfont="sketchybar-app-font:Regular:15.0"
open_am="open -a 'Activity Monitor'; /usr/local/bin/sketchybar --set cpu.percent popup.drawing=off --set mem popup.drawing=off"

# add_row <popup> <name> [props...]
add_row() { local pop=$1 name=$2; shift 2; sketchybar --add item $name popup.$pop --set $name "${row[@]}" "$@"; }
add_hdr() { local pop=$1 name=$2 text=$3; sketchybar --add item $name popup.$pop --set $name "${header[@]}" label="$text"; }
# add_graph <popup> <name> <width> <height> <color> [props...]
add_graph() {
  local pop=$1 name=$2 w=$3 h=$4 color=$5; shift 5
  sketchybar --add graph $name popup.$pop $w \
             --set $name "${row[@]}" graph.color=$color graph.fill_color="0x40${color:4}" \
                   background.height=$h background.drawing=on background.color=$TRANSPARENT \
                   label.width=90 label.align=right "$@"
}

# --- Network -----------------------------------------------------------------------------------
add_graph net.up np.dl 150 28 $BLUE  icon=$NET_DOWN icon.color=$BLUE label="…"
add_graph net.up np.ul 150 28 $GREEN icon=$NET_UP   icon.color=$GREEN label="…"
add_row net.up np.peak icon=$ACTIVITY label="…"
add_row net.up np.used icon=$CLOCK label="…"
add_hdr net.up np.hdr.apps "TOP APPS NOW"
for n in 1 2 3 4 5; do
  add_row net.up np.app.$n icon.font="$appfont" icon.color=$WHITE drawing=off label="…"
done
add_row net.up np.verdict icon=$VOLUME_KNOB label="Checking…"
add_row net.up np.router icon=$ROUTER label="Router …"
add_row net.up np.net icon=$GLOBE label="Internet …"
add_row net.up np.ip icon=$LOCK_FILL label="…"
add_row net.up np.speed icon=$BOLT icon.color=$BLUE label="Test speed" \
        script="$PLUGIN_DIR/hover.sh" click_script="$PLUGIN_DIR/wifi_speed.sh run" \
        --subscribe np.speed mouse.entered mouse.exited
add_row net.up np.speed.result icon=" " label.color=$GREY label.font="$TEXT_FONT:SemiBold:12.0" drawing=off

# --- CPU ---------------------------------------------------------------------------------------
add_graph cpu.percent cp.graph 330 44 $BLUE icon.drawing=off label.drawing=off
add_row cpu.percent cp.load icon=$ACTIVITY label="…"
add_row cpu.percent cp.split icon=$CPU icon.color=$BLUE label="…"
add_row cpu.percent cp.throttle icon=$BOLT label="…"
add_row cpu.percent cp.temp icon=$THERMOMETER icon.color=$ORANGE label="…"
add_row cpu.percent cp.fan icon=$GEAR label="…"
add_hdr cpu.percent cp.hdr "TOP PROCESSES"
for n in 1 2 3 4 5; do
  add_row cpu.percent cp.proc.$n icon.font="$appfont" icon.color=$WHITE drawing=off label="…" \
          script="$PLUGIN_DIR/hover.sh" click_script="$open_am" \
          --subscribe cp.proc.$n mouse.entered mouse.exited
done
add_row cpu.percent cp.uptime icon=$CLOCK icon.color=$GREEN label="…"

# --- Memory ------------------------------------------------------------------------------------
add_row mem mp.pressure icon=$VOLUME_KNOB label="…"
add_row mem mp.used icon=$MEMORY icon.color=$MAGENTA label="…"
add_row mem mp.swap icon=$DISK label="…"
add_row mem mp.comp icon=$GEAR label="…"
add_hdr mem mp.hdr "TOP APPS"
for n in 1 2 3 4 5; do
  add_row mem mp.app.$n icon.font="$appfont" icon.color=$WHITE drawing=off label="…" \
          script="$PLUGIN_DIR/hover.sh" click_script="$open_am" \
          --subscribe mp.app.$n mouse.entered mouse.exited
done
