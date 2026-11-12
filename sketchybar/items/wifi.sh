#!/bin/bash
# Wi-Fi: the icon shows state and signal; click for network name, IP,
# router and signal, the channel with advice on a quieter one, a speed test,
# the saved and nearby networks (click one to join it), and a toggle to turn
# Wi-Fi on or off.

wifi=(
  icon=$WIFI
  icon.font="$FONT:Regular:15.0"
  label.drawing=off
  padding_left=8
  padding_right=4
  update_freq=30
  updates=on
  popup.align=right
  script="$PLUGIN_DIR/wifi.sh"
  click_script="$PLUGIN_DIR/popup.sh wifi; NAME=wifi SENDER=refresh $PLUGIN_DIR/wifi.sh"
)

popup_row=(
  icon.font="$FONT:Regular:14.0"
  icon.width=26
  label.font="$TEXT_FONT:SemiBold:13.0"
  padding_left=8
  padding_right=12
)

sketchybar --add item wifi right                                    \
           --set wifi "${wifi[@]}"                                  \
           --subscribe wifi wifi_change system_woke mouse.exited.global

# Status rows, then the network lists (hidden until plugins/wifi.sh fills them), then the toggle.
# Nearby only appears once SketchyBarWiFi.app has Location access; see plugins/wifi.sh.
# SF Symbols glyphs for these rows, defined here (icons.sh is not mine to change).
ANTENNA=$'\xf4\x80\x96\x80'   # antenna.radiowaves.left.and.right
STAR=$'\xf4\x80\x8b\x83'      # star.fill

net_header=(
  icon.width=26
  label.font="$TEXT_FONT:ExtraBold:11.0"
  label.color=$GREY
  padding_left=8
  padding_right=12
  drawing=off
)
net_row=(
  icon.font="$FONT:Regular:14.0"
  icon.width=26
  label.font="$TEXT_FONT:SemiBold:13.0"
  label.max_chars=30
  padding_left=8
  padding_right=12
  drawing=off
  script="$PLUGIN_DIR/hover.sh"
)

for row in ssid ip router signal; do
  sketchybar --add item wifi.$row popup.wifi \
             --set wifi.$row "${popup_row[@]}"
done

# Channel and advice rows fill in from the scan (plugins/wifi.sh); the speed test rows
# belong to plugins/wifi_speed.sh. All start hidden.
sketchybar --add item wifi.channel popup.wifi \
           --set wifi.channel "${popup_row[@]}" icon=$ANTENNA icon.color=$GREY drawing=off \
           --add item wifi.advice popup.wifi \
           --set wifi.advice "${popup_row[@]}" icon=$STAR icon.color=$YELLOW drawing=off \
                 label.max_chars=50 script="$PLUGIN_DIR/hover.sh" \
                 --subscribe wifi.advice mouse.entered mouse.exited \
           --add item wifi.speed popup.wifi \
           --set wifi.speed "${popup_row[@]}" icon=$BOLT icon.color=$BLUE label="Test speed" drawing=off \
                 script="$PLUGIN_DIR/hover.sh" click_script="$PLUGIN_DIR/wifi_speed.sh run" \
           --subscribe wifi.speed mouse.entered mouse.exited \
           --add item wifi.speed.result popup.wifi \
           --set wifi.speed.result "${popup_row[@]}" icon=" " label.color=$GREY \
                 label.font="$TEXT_FONT:SemiBold:12.0" drawing=off

sketchybar --add item wifi.hdr.saved popup.wifi --set wifi.hdr.saved "${net_header[@]}" label="SAVED NETWORKS"
for n in 1 2 3 4 5 6 7 8; do
  sketchybar --add item wifi.saved.$n popup.wifi \
             --set wifi.saved.$n "${net_row[@]}" click_script="$PLUGIN_DIR/wifi_join.sh saved $n" \
             --subscribe wifi.saved.$n mouse.entered mouse.exited
done
sketchybar --add item wifi.hdr.near popup.wifi --set wifi.hdr.near "${net_header[@]}" label="NEARBY"
for n in 1 2 3 4 5; do
  sketchybar --add item wifi.near.$n popup.wifi \
             --set wifi.near.$n "${net_row[@]}" click_script="$PLUGIN_DIR/wifi_join.sh near $n" \
             --subscribe wifi.near.$n mouse.entered mouse.exited
done

sketchybar --add item wifi.toggle popup.wifi \
           --set wifi.toggle "${popup_row[@]}"

sketchybar --set wifi.ssid   icon=$WIFI icon.color=$BLUE label.font="$TEXT_FONT:Bold:13.0" \
           --set wifi.ip     icon=$NET_UP icon.color=$GREY                            \
           --set wifi.router icon=$ROUTER icon.color=$GREY                            \
           --set wifi.signal icon=$ACTIVITY icon.color=$GREY                          \
           --set wifi.toggle icon=$WIFI_OFF icon.color=$RED                           \
                             click_script="$PLUGIN_DIR/control.sh wifi; /usr/local/bin/sketchybar --set wifi popup.drawing=off"
