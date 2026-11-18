#!/bin/bash
# The theme switch with its full reach. Same commands as sketchybar/plugins/theme.sh (it does the bar, borders,
# Ghostty palette, nvim, wallpaper, Alfred), then themes/reach.sh adds VS Code Insiders, Claude Code, tmux, delta,
# macOS accent and light/dark, the chosen wallpaper and font. Plus two commands of its own:
#   theme.sh bg [next|prev|pick [file]|current]   wallpaper within the active theme's folder
#   theme.sh font [JetBrains Mono|CaskaydiaMono|Fira Code|Meslo|default]   Ghostty and VS Code Insiders font
#   theme.sh reach        re-apply the reach targets only
# The plugin's apply() also runs the reach step (in the background), so a switch from the bar's control
# centre reaches everything too; THEME_REACH_SKIP=1 below stops it running twice.
DOT="$(cd -P "$(dirname "$0")/.." && pwd -P)"
PLUG="$DOT/sketchybar/plugins/theme.sh"
R="$DOT/themes/reach.sh"
case "$1" in
  bg)    shift; exec /bin/bash "$R" bg "$@" ;;
  font)  shift; exec /bin/bash "$R" font "$@" ;;
  reach) exec /bin/bash "$R" apply ;;
  next|set|"")
    THEME_REACH_SKIP=1 /bin/bash "$PLUG" "$@"; rc=$?
    [ $rc = 0 ] && { /bin/bash "$R" apply; }
    exit $rc ;;
  *) exec /bin/bash "$PLUG" "$@" ;;
esac
