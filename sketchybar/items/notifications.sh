#!/bin/bash
# Unread badges for chat and mail apps (from their Dock badge). Badges show only while
# an app has unread items; click one to open the app. Slack and WhatsApp keep their own
# badge; Telegram and Outlook are folded into one "+N" badge (badge.more).
# GitHub notifications are counted by a hidden item; the "more" popup shows the result.

# bundle id : item name
BADGE_APPS="com.tinyspeck.slackmacgap:slack net.whatsapp.WhatsApp:whatsapp ru.keepcoder.Telegram:telegram com.microsoft.Outlook:outlook"

# The count lives on a hidden item (plugins/github.sh updates it every 3 minutes)
github=(
  drawing=off
  icon=":git_hub:"
  icon.font="sketchybar-app-font:Regular:15.0"
  icon.color=$GREY
  label.drawing=off
  label.font="$TEXT_FONT:Bold:12.0"
  label.color=$RED
  update_freq=180
  updates=on
  script="$PLUGIN_DIR/github.sh"
)

sketchybar --add item github right \
           --set github "${github[@]}" \
           --subscribe github system_woke

badge=(
  drawing=off
  icon.font="sketchybar-app-font:Regular:15.0"
  label.font="$TEXT_FONT:Bold:12.0"
  label.color=$RED
  padding_left=4
  padding_right=4
)

# Right to left: the "+N" badge is rightmost, then WhatsApp, then Slack
sketchybar --add item badge.more right \
           --set badge.more "${badge[@]}" icon.drawing=off
for pair in net.whatsapp.WhatsApp:whatsapp com.tinyspeck.slackmacgap:slack; do
  id=${pair%%:*}; name=badge.${pair##*:}
  sketchybar --add item $name right \
             --set $name "${badge[@]}" click_script="open -b $id"
done
# Telegram and Outlook never draw on their own; badges.sh adds them into badge.more
for pair in ru.keepcoder.Telegram:telegram com.microsoft.Outlook:outlook; do
  id=${pair%%:*}; name=badge.${pair##*:}
  sketchybar --add item $name right --set $name "${badge[@]}" click_script="open -b $id"
done

# Hidden driver that refreshes every badge in one pass
sketchybar --add item badges right \
           --set badges drawing=off updates=on update_freq=10 \
                        script="BADGE_APPS='$BADGE_APPS' $PLUGIN_DIR/badges.sh" \
           --subscribe badges front_app_switched system_woke
