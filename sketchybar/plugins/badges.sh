#!/bin/bash
# Reads each app's Dock badge with lsappinfo and shows it in the bar.
export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/plugins/icon_map.sh"

# badge_label "<lsappinfo output>" -> the badge text, empty if none
badge_label() { sed -n 's/.*"label"="\([^"]*\)".*/\1/p' <<<"$1"; }

args=()
for pair in $BADGE_APPS; do
  id=${pair%%:*}; name=badge.${pair##*:}
  count=$(badge_label "$(lsappinfo info -only StatusLabel -app "$id" 2>/dev/null)")
  [ -f "${TMPDIR:-/tmp}/sketchybar_zen" ] && count=""
  if [ -n "$count" ]; then
    __icon_map "$(lsappinfo info -only name -app "$id" | sed -n 's/.*"LSDisplayName"="\(.*\)".*/\1/p')"
    args+=(--set "$name" drawing=on icon="$icon_result" label="$count")
  else
    args+=(--set "$name" drawing=off)
  fi
done
sketchybar "${args[@]}"
