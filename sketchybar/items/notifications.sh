#!/bin/bash
# Unread badges for chat and mail apps (from their Dock badge), and GitHub notifications.
# Badges show only while an app has unread items; click one to open the app.
# The GitHub icon is grey with nothing unread; click it for the list, right-click for the page.

# bundle id : item name
BADGE_APPS="com.tinyspeck.slackmacgap:slack net.whatsapp.WhatsApp:whatsapp ru.keepcoder.Telegram:telegram com.microsoft.Outlook:outlook"

github=(
  icon=":git_hub:"
  icon.font="sketchybar-app-font:Regular:15.0"
  icon.color=$GREY
  label.drawing=off
  label.font="$FONT:Bold:12.0"
  label.color=$RED
  padding_left=6
  padding_right=6
  update_freq=180
  updates=on
  popup.align=right
  script="$PLUGIN_DIR/github.sh"
)

sketchybar --add item github right \
           --set github "${github[@]}" \
           --subscribe github mouse.clicked mouse.exited.global system_woke

for pair in $BADGE_APPS; do
  id=${pair%%:*}; name=badge.${pair##*:}
  sketchybar --add item $name right \
             --set $name drawing=off \
                         icon.font="sketchybar-app-font:Regular:15.0" \
                         label.font="$FONT:Bold:12.0" \
                         label.color=$RED \
                         padding_left=4 padding_right=4 \
                         click_script="open -b $id"
done

# Hidden driver that refreshes every badge in one pass
sketchybar --add item badges right \
           --set badges drawing=off updates=on update_freq=10 \
                        script="BADGE_APPS='$BADGE_APPS' $PLUGIN_DIR/badges.sh" \
           --subscribe badges front_app_switched system_woke
