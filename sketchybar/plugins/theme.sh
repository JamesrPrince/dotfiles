#!/bin/bash
# One switch that re-themes the desktop (the Omarchy idea).
#   theme.sh next          next theme in the list
#   theme.sh set <name>    a named theme (see list)
#   theme.sh list [--plain]  every theme; --plain is "id<TAB>name" for scripts
#   theme.sh current       the active theme id
#   theme.sh borders|ghostty|nvim|wall|alfred   re-apply one part only
# A switch sets: the bar (colors.sh), window borders, the Ghostty palette, the Neovim
# colourscheme, the wallpaper, the Alfred window theme. btop, bat, fzf, lazygit, yazi and Starship use the
# terminal's own ANSI colours, so they follow Ghostty with no files of their own.
# All parts are safe to run at any time.

export PATH="/usr/local/bin:$PATH"
CONF="$HOME/.config/sketchybar"
DOT="$(cd -P "$CONF" && cd .. && pwd -P)"     # the dotfiles repo behind the symlink
source "$CONF/colors.sh"

borders_on() {
  # A running borders instance takes new settings from a second call
  borders active_color=$ACCENT inactive_color=0x00000000 width=2.0 style=round hidpi=on \
    >/dev/null 2>&1 &
}

ghostty_on() {
  # Ghostty follows the theme through ~/.config/ghostty/theme.conf, which its config
  # includes. Rewritten only when it changes; a running Ghostty then reloads its config.
  local file="$HOME/.config/ghostty/theme.conf" want
  if [ "$THEME_GHOSTTY" = "palette" ]; then
    want=$(python3 - "$DOT/themes/$THEME/colors.toml" <<'PY'
import re, sys
c = dict(re.findall(r'^(\w+)\s*=\s*"([^"]*)"', open(sys.argv[1]).read(), re.M))
print("background = %s\nforeground = %s\ncursor-color = %s\nselection-background = %s\nselection-foreground = %s\n"
      % (c["background"], c["foreground"], c["bright_foreground"], c["selection"], c["foreground"]))
for i, k in enumerate(["background", "red", "green", "yellow", "blue", "magenta", "cyan", "foreground",
                       "muted", "bright_red", "bright_green", "bright_yellow", "bright_blue",
                       "bright_magenta", "bright_cyan", "bright_foreground"]):
    print("palette = %d=%s" % (i, c[k]))
PY
)
  else
    want="theme = $THEME_GHOSTTY"
  fi
  [ "$(cat "$file" 2>/dev/null)" = "$want" ] && return 0
  printf '%s\n' "$want" > "$file"
  pgrep -xq ghostty && osascript -e 'tell application "Ghostty" to if (count of terminals) > 0 then perform action "reload_config" on terminal 1' \
    >/dev/null 2>&1 &
}

nvim_on() {
  # LazyVim picks the colourscheme from nvim/lua/plugins/theme.lua (git-ignored),
  # a copy of Omarchy's per-theme neovim.lua. Running Neovims pick it up on restart.
  local src="$DOT/themes/$THEME/neovim.lua" dst="$HOME/.config/nvim/lua/plugins/theme.lua"
  [ -f "$src" ] || return 0
  mkdir -p "$(dirname "$dst")"
  cmp -s "$src" "$dst" || cp "$src" "$dst"
}

wall_on() {
  # First picture of the theme's folder (themes/fetch-backgrounds.sh downloads them).
  # setwall is a tiny NSWorkspace tool: System Events is refused on this Mac.
  local dir="$THEME" img tool="$DOT/themes/setwall"
  [ "$dir" = macchiato ] && dir=catppuccin
  img=$(ls "$DOT/themes/backgrounds/$dir"/* 2>/dev/null | grep -v '/omarchy\.' | sort | head -1)
  [ -n "$img" ] || return 0
  [ -x "$tool" ] || swiftc -O "$DOT/themes/setwall.swift" -o "$tool" 2>/dev/null || return 0
  "$tool" "$img" >/dev/null 2>&1
}

alfred_on() {
  # One Alfred theme per bar theme ("Om <name>", alfred/themes/). Alfred's own AppleScript switches it
  # live. Off until alfred/import.sh has imported the themes and made the marker file; the first call
  # then asks once for Automation permission (Alfred must be running: never started or restarted here).
  [ -f "$CONF/.alfred-themes" ] || return 0
  pgrep -xq Alfred || return 0
  osascript -e "tell application id \"com.runningwithcrayons.Alfred\" to set theme \"Om $THEME_NAME\"" \
    >/dev/null 2>&1 &
}

apply() { # apply <id>
  echo "$1" > "$CONF/.theme"
  source "$CONF/colors.sh"
  borders_on
  ghostty_on
  nvim_on
  wall_on
  alfred_on
  sketchybar --reload
}

case "$1" in
  next)
    set -- $THEMES
    NEXT=$1
    while [ $# -gt 0 ]; do
      if [ "$1" = "$THEME" ]; then NEXT=${2:-$(echo $THEMES | cut -d' ' -f1)}; break; fi
      shift
    done
    apply "$NEXT"
    ;;
  set)
    case " $THEMES " in
      *" $2 "*) apply "$2" ;;
      *) echo "Unknown theme '$2'. Try: theme.sh list" >&2; exit 1 ;;
    esac
    ;;
  list)
    for t in $THEMES; do
      n=$(THEME_OVERRIDE=$t bash -c 'source "$HOME/.config/sketchybar/colors.sh"; echo "$THEME_NAME"')
      if [ "$2" = "--plain" ]; then printf '%s\t%s\n' "$t" "$n"
      else printf '%s %-11s %s\n' "$([ "$t" = "$THEME" ] && echo '*' || echo ' ')" "$t" "$n"; fi
    done
    ;;
  current) echo "$THEME" ;;
  borders) borders_on ;;
  ghostty) ghostty_on ;;
  nvim)    nvim_on ;;
  wall)    wall_on ;;
  alfred)  alfred_on ;;
  *) echo "usage: theme.sh next | set <name> | list [--plain] | current | borders | ghostty | nvim | wall | alfred" >&2; exit 2 ;;
esac
