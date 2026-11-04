#!/bin/bash
# Wi-Fi: the icon shows state and signal; click for network name, IP,
# router and signal, with a toggle to turn Wi-Fi on or off.

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
  label.font="$FONT:Semibold:13.0"
  padding_left=8
  padding_right=12
)

sketchybar --add item wifi right                                    \
           --set wifi "${wifi[@]}"                                  \
           --subscribe wifi wifi_change system_woke mouse.exited.global

for row in ssid ip router signal toggle; do
  sketchybar --add item wifi.$row popup.wifi \
             --set wifi.$row "${popup_row[@]}"
done

sketchybar --set wifi.ssid   icon=$WIFI icon.color=$BLUE label.font="$FONT:Bold:13.0" \
           --set wifi.ip     icon=$NET_UP icon.color=$GREY                            \
           --set wifi.router icon=$ROUTER icon.color=$GREY                            \
           --set wifi.signal icon=$ACTIVITY icon.color=$GREY                          \
           --set wifi.toggle icon=$WIFI_OFF icon.color=$RED                           \
                             click_script="$PLUGIN_DIR/control.sh wifi; /usr/local/bin/sketchybar --set wifi popup.drawing=off"
