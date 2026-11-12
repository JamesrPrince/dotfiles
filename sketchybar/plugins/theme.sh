#!/bin/bash
# Theme switcher. "next" moves to the next theme, sets Ghostty to match and
# reloads the bar; "borders" (re)starts JankyBorders in the theme's accent;
# "ghostty" syncs Ghostty only. All are safe to run at any time.

export PATH="/usr/local/bin:$PATH"
CONF="$HOME/.config/sketchybar"
source "$CONF/colors.sh"

borders_on() {
  # A running borders instance takes new settings from a second call
  borders active_color=$ACCENT inactive_color=0x00000000 width=5.0 style=round hidpi=on \
    >/dev/null 2>&1 &
}

ghostty_on() {
  # Ghostty follows the bar theme through ~/.config/ghostty/theme.conf, which
  # its config includes. Rewritten only when it changes; a running Ghostty
  # then reloads its config (scripted action, Ghostty 1.4+).
  local name file="$HOME/.config/ghostty/theme.conf"
  case "$THEME" in
    tokyonight) name="TokyoNight" ;;
    gruvbox)    name="Gruvbox Dark" ;;
    *)          name="Catppuccin Macchiato" ;;
  esac
  [ "$(cat "$file" 2>/dev/null)" = "theme = $name" ] && return 0
  echo "theme = $name" > "$file"
  pgrep -xq ghostty && osascript -e 'tell application "Ghostty" to if (count of terminals) > 0 then perform action "reload_config" on terminal 1' \
    >/dev/null 2>&1 &
}

case "$1" in
  next)
    set -- $THEMES
    NEXT=$1
    while [ $# -gt 0 ]; do
      if [ "$1" = "$THEME" ]; then NEXT=${2:-$(echo $THEMES | cut -d' ' -f1)}; break; fi
      shift
    done
    echo "$NEXT" > "$CONF/.theme"
    source "$CONF/colors.sh"
    borders_on
    ghostty_on
    sketchybar --reload
    ;;
  borders) borders_on ;;
  ghostty) ghostty_on ;;
esac
