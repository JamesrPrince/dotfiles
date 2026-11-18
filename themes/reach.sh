#!/bin/bash
# Theme reach: VS Code Insiders, Claude Code, tmux, delta, macOS accent + light/dark, background, font.
# Run by sketchybar/plugins/theme.sh (apply, bg, font); see reach.py. `reach.sh apply` is serialised and
# always styles the theme that is active when it gets its turn, so rapid switches end consistent.
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"
DOT="$(cd -P "$(dirname "$0")/.." && pwd -P)"
export THEME_OVERRIDE=
logdir="$HOME/.config/theme-reach"; errf="$logdir/last.err"; events=""
mkdir -p "$logdir"
# last.err: present only when something went wrong (an error outside reach.py, a replaced or timed-out holder,
# reach.py exiting non-zero). Timestamped, with the theme, kept to the last 20 lines. A clean run removes it.
note() {
  printf '%s theme=%s run=%s: %s\n' "$(date '+%F %T')" "${THEME:-?}" "$$" "$(printf %s "$*" | cut -c1-300)" >>"$errf"
  tail -n 20 "$errf" >"$errf.t$$" 2>/dev/null && mv -f "$errf.t$$" "$errf"
}
if [ "${1:-apply}" = apply ]; then
  errtmp="$logdir/last.err.$$"; exec 2>>"$errtmp"   # this shell's own errors (colors.sh, lock wait) are caught here
  release() {
    if [ -s "$errtmp" ]; then while IFS= read -r l; do note "$l"; done < <(head -n 5 "$errtmp"); fi
    rm -f "$errtmp"
    # release only a lock that is still ours: a run that was replaced must not delete its successor's lock
    [ -n "$lock" ] && [ "$(cat "$lock/pid" 2>/dev/null)" = "$$" ] && rm -rf "${lock:?}"
    return 0
  }
  trap release EXIT
fi
source "$HOME/.config/sketchybar/colors.sh"
export THEME THEME_MODE ACCENT
# stop a process and everything it started (python, then a `code --install-extension` it launched, and so on).
# The list is taken first and the parent stopped before the children, so nothing is respawned mid-walk.
tree_of() { local c; echo "$1"; for c in $(pgrep -P "$1" 2>/dev/null); do tree_of "$c"; done; }
killtree() {
  local pids; pids=$(tree_of "$1")
  kill $pids 2>/dev/null; sleep 0.2; kill -9 $pids 2>/dev/null; return 0
}
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
      [ -n "$owner" ] && { events="$events;lock wait passed ${THEME_REACH_LOCK_MAX:-300}s: stopped stuck run $owner (its switch did not finish)"; killtree "$owner"; sleep 1; }
      rm -rf "${lock:?}"; waited=0
    fi
    sleep 1
  done
  echo $$ > "$lock/pid"
  rm -f "$errf"; [ -n "$events" ] && note "${events#;}"   # a new run starts from a clean slate; only its own findings stay
  source "$HOME/.config/sketchybar/colors.sh"; export THEME THEME_MODE ACCENT   # the theme as of now
fi
exec_py() { /usr/bin/env python3 "$DOT/themes/reach.py" "$@"; }
if [ "${1:-apply}" = apply ]; then
  # last.log is replaced only by a run that finished: this run writes to its own file and moves it into place
  # at the end (runs are serialised by the lock, so the newest finished run wins). A run that is stopped
  # leaves the previous complete log alone. The caller must not truncate last.log itself.
  tmp="$logdir/last.log.$$"
  for f in "$logdir"/last.err.[0-9]*; do [ "$f" != "$errtmp" ] && rm -f "$f"; done 2>/dev/null
  rm -f "$logdir"/last.log.[0-9]* 2>/dev/null   # leftovers of stopped runs; we hold the lock, so none is live
  exec_py "$@" >"$tmp" 2>&1; rc=$?
  cat "$tmp"; mv -f "$tmp" "$logdir/last.log"
  [ $rc -ne 0 ] && note "reach.py exited $rc (see last.log)"
  exit $rc
fi
exec_py "$@"
