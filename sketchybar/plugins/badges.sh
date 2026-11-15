#!/bin/bash
# Reads each app's Dock badge with lsappinfo and shows it in the bar.
# Telegram and Outlook are folded into one "+N" badge (badge.more).
export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/plugins/style.sh"
source "$HOME/.config/sketchybar/plugins/icon_map.sh"

# badge_label "<lsappinfo output>" -> the badge text, empty if none
badge_label() { sed -n 's/.*"label"="\([^"]*\)".*/\1/p' <<<"$1"; }

# Flat style: only Slack and WhatsApp, as a quiet app icon and count, only while unread (smart_lib.sh).
# Two lsappinfo reads every FLAT_POLL_BADGES s and on front-app changes; nothing is sent unless a count changed.
if [ "$BAR_STYLE" = flat ]; then
  source "$HOME/.config/sketchybar/plugins/smart_lib.sh"
  for pair in $BADGE_APPS; do
    id=${pair%%:*}; short=${pair##*:}
    case $short in slack|whatsapp) ;; *) continue ;; esac
    if smart_demo $short; then
      case $short in slack) count=3 ;; *) count=12 ;; esac
      app=$short
    else
      count=$(badge_label "$(lsappinfo info -only StatusLabel -app "$id" 2>/dev/null)")
      app=""
    fi
    if [ -n "$count" ]; then
      [ -n "$app" ] && { [ "$app" = slack ] && app=Slack || app=WhatsApp; } || \
        app=$(lsappinfo info -only name -app "$id" | sed -n 's/.*"LSDisplayName"="\(.*\)".*/\1/p')
      __icon_map "$app"
      SM_ICON="$icon_result"; SM_LABEL="$count"; SM_IW=16
      smart_show badge.$short
    else
      smart_hide badge.$short
    fi
  done
  exit 0
fi

args=()
more_n=0
more_ids=""
for pair in $BADGE_APPS; do
  id=${pair%%:*}; name=badge.${pair##*:}
  count=$(badge_label "$(lsappinfo info -only StatusLabel -app "$id" 2>/dev/null)")
  [ -f "${TMPDIR:-/tmp}/sketchybar_zen" ] && count=""
  case $name in
    badge.telegram|badge.outlook)
      if [ -n "$count" ]; then
        n=${count//[^0-9]/}; [ -n "$n" ] || n=1
        more_n=$((more_n + n)); more_ids+=" $id"
      fi
      args+=(--set "$name" drawing=off)
      continue ;;
  esac
  if [ -n "$count" ]; then
    __icon_map "$(lsappinfo info -only name -app "$id" | sed -n 's/.*"LSDisplayName"="\(.*\)".*/\1/p')"
    args+=(--set "$name" drawing=on icon="$icon_result" label="$count")
  else
    args+=(--set "$name" drawing=off)
  fi
done

if [ "$more_n" -gt 0 ]; then
  args+=(--set badge.more drawing=on label="+$more_n"
         click_script="for b in$more_ids; do open -b \$b; done")
else
  args+=(--set badge.more drawing=off)
fi
sketchybar "${args[@]}"
