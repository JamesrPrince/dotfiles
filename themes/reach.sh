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
  lock="$HOME/.config/theme-reach/lock"; n=0; waited=0
  until mkdir "$lock" 2>/dev/null; do
    # a lock is cleared only when the run that holds it is gone: its PID is inside, must be alive AND
    # still be a reach.sh (a reused PID belongs to some other process: stale). Never on a short timer:
    # the longest honest run is one extension install (120 s) plus the accent call (30 s), so only a
    # holder that outlives 300 s is taken to be stuck. It is stopped first, so two runs never overlap.
    owner=$(cat "$lock/pid" 2>/dev/null)
    if [ -n "$owner" ]; then
      case "$(ps -p "$owner" -o command= 2>/dev/null)" in
        *reach.sh*) ;;                                  # a live reach run: wait for it
        *) rm -rf "${lock:?}" ;;                        # dead, or the PID now runs something else
      esac
    else n=$((n+1)); [ $n -gt 10 ] && { rm -rf "${lock:?}"; n=0; }; fi   # no PID after 10 s: a dead run from before
    waited=$((waited+1))
    if [ $waited -gt "${THEME_REACH_LOCK_MAX:-300}" ]; then
      [ -n "$owner" ] && { pkill -P "$owner" 2>/dev/null; kill "$owner" 2>/dev/null; sleep 1; }
      rm -rf "${lock:?}"; waited=0
    fi
    sleep 1
  done
  echo $$ > "$lock/pid"
  # release only a lock that is still ours: a run that was replaced must not delete its successor's lock
  trap '[ "$(cat "$lock/pid" 2>/dev/null)" = "$$" ] && rm -rf "${lock:?}"' EXIT
  source "$HOME/.config/sketchybar/colors.sh"; export THEME THEME_MODE ACCENT   # the theme as of now
fi
exec_py() { /usr/bin/env python3 "$DOT/themes/reach.py" "$@"; }
exec_py "$@"
