#!/bin/bash
# Theme reach: VS Code Insiders, Claude Code, tmux, delta, macOS accent + light/dark, background, font.
# Run by sketchybar/plugins/theme.sh (apply, bg, font); see reach.py. `reach.sh apply` is serialised and
# always styles the theme that is active when it gets its turn, so rapid switches end consistent.
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"
DOT="$(cd -P "$(dirname "$0")/.." && pwd -P)"
export THEME_OVERRIDE=
source "$HOME/.config/sketchybar/colors.sh"
export THEME THEME_MODE ACCENT
mkdir -p "$HOME/.config/theme-reach"
if [ "${1:-apply}" = apply ]; then
  lock="$HOME/.config/theme-reach/lock"; n=0
  until mkdir "$lock" 2>/dev/null; do
    # a lock is cleared only when the run that holds it is gone (its PID is inside), never on a timer
    owner=$(cat "$lock/pid" 2>/dev/null)
    if [ -n "$owner" ]; then kill -0 "$owner" 2>/dev/null || rm -rf "${lock:?}"
    else n=$((n+1)); [ $n -gt 10 ] && { rm -rf "${lock:?}"; n=0; }; fi   # no PID after 10 s: a dead run from before
    sleep 1
  done
  echo $$ > "$lock/pid"
  trap 'rm -rf "${lock:?}"' EXIT
  source "$HOME/.config/sketchybar/colors.sh"; export THEME THEME_MODE ACCENT   # the theme as of now
fi
exec_py() { /usr/bin/env python3 "$DOT/themes/reach.py" "$@"; }
exec_py "$@"
