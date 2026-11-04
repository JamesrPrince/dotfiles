#!/bin/bash
# VPN and public IP: a padlock while a VPN is connected, a globe otherwise,
# with the country your traffic leaves from. Click for the public IP (click
# it to copy) and a connect/disconnect row for each VPN macOS knows about.
vpn=(
  icon=$GLOBE
  icon.font="$FONT:Regular:14.0"
  icon.color=$GREY
  label.font="$FONT:Bold:10.0"
  label.color=$GREY
  label.padding_left=2
  padding_left=6
  padding_right=2
  update_freq=60
  updates=on
  popup.align=right
  script="$PLUGIN_DIR/vpn.sh"
  click_script="NAME=vpn SENDER=click $PLUGIN_DIR/vpn.sh"
)
sketchybar --add item vpn right \
           --set vpn "${vpn[@]}" \
           --subscribe vpn wifi_change system_woke mouse.entered mouse.exited mouse.exited.global
