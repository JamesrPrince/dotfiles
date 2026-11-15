#!/bin/bash
# Flat style: Homebrew updates, as a row in the control popup ("Updates  73"). Not on the bar, and
# nothing polls for it: the row is filled when the control popup opens (items/flat.sh runs `row` from
# the control item's click script), from a cache.
#   row      read the cache and show or hide the row. If the cache is older than FLAT_BREW_HOURS it
#            starts a detached refresh first (never waited for); the row updates when that finishes.
#   toggle   the row's click: shows or hides its two action rows
#   refresh  run the check again now (the "Check again" row)
#   job      the detached refresh itself: `brew outdated`, read-only (no `brew update`, so the list is
#            as fresh as Homebrew's own index, which any brew command refreshes)
# Nothing is ever upgraded from the bar: the actions are "Check again" (read-only) and "Copy brew upgrade"
# (fills the clipboard; running it is James's). Cache: ~/.cache/sketchybar-brew-outdated (one
# "name (current) < latest" line per package) and its stamp ~/.cache/sketchybar-brew-checked.
# Test switch: plugins/smart_demo.sh on updates (sample count, no brew, cache untouched).

source "$HOME/.config/sketchybar/plugins/smart_lib.sh"
CACHE_DIR="$HOME/.cache"
LIST="$CACHE_DIR/sketchybar-brew-outdated"
STAMP="$CACHE_DIR/sketchybar-brew-checked"
LOCK="$SMART_DIR/brew.lock"
SELF="$HOME/.config/sketchybar/plugins/brew_updates.sh"
BREW=/usr/local/bin/brew; [ -x "$BREW" ] || BREW=/opt/homebrew/bin/brew

start_job() {   # detached, single instance, stale locks (a killed job) cleared after 10 minutes
  [ -x "$BREW" ] || return 0
  find "$LOCK" -maxdepth 0 -mmin +10 -exec rmdir {} \; 2>/dev/null
  mkdir "$LOCK" 2>/dev/null || return 0
  nohup nice -n 10 "$SELF" job >/dev/null 2>&1 &
  disown 2>/dev/null
}

case "$1" in
  job)
    trap 'rmdir "$LOCK" 2>/dev/null' EXIT
    mkdir -p "$CACHE_DIR"
    export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ANALYTICS=1 HOMEBREW_NO_ENV_HINTS=1
    "$BREW" outdated --verbose > "$LIST.tmp" 2>/dev/null &
    bpid=$!
    t=0; while kill -0 "$bpid" 2>/dev/null && [ "$t" -lt 300 ]; do sleep 1; t=$((t + 1)); done   # 5 minute ceiling
    if kill -0 "$bpid" 2>/dev/null; then kill "$bpid" 2>/dev/null; rc=1; else wait "$bpid"; rc=$?; fi
    if [ "$rc" = 0 ]; then mv "$LIST.tmp" "$LIST"; else rm -f "$LIST.tmp"; fi
    : > "$STAMP"
    "$SELF" row
    exit 0 ;;
  refresh)
    start_job; exit 0 ;;
  toggle)
    # The two action rows are added and removed (rows added while the popup is open are measured properly)
    if sketchybar --query control.updates.again >/dev/null 2>&1; then
      sketchybar --remove control.updates.again --remove control.updates.copy
    else
      FONT="SF Pro"; source "$HOME/.config/sketchybar/plugins/style.sh"
      source "$HOME/.config/sketchybar/colors.sh"; source "$HOME/.config/sketchybar/icons.sh"
      row=(icon.color=$GREY icon.font="$FONT:Regular:15.0" icon.width=28 label.font="$TEXT_FONT:SemiBold:13.0"
           padding_left=20 padding_right=14)   # indented under the Updates row (leading spaces in a label are not measured)
      sketchybar --add item control.updates.again popup.control \
                 --set control.updates.again "${row[@]}" icon=$BOLT label="Check again" \
                       click_script="$SELF refresh; /usr/local/bin/sketchybar --set control popup.drawing=off" \
                 --move control.updates.again after control.updates \
                 --add item control.updates.copy popup.control \
                 --set control.updates.copy "${row[@]}" icon=$COPY label="Copy  brew upgrade   (not run)" \
                       click_script="printf 'brew upgrade' | pbcopy; /usr/local/bin/sketchybar --set control popup.drawing=off" \
                 --move control.updates.copy after control.updates.again
    fi
    exit 0 ;;
  row) ;;
  *) echo "usage: brew_updates.sh row | toggle | refresh | job" >&2; exit 2 ;;
esac

# --- row ---------------------------------------------------------------------------------------------
now=$(date +%s)
mt=0; [ -e "$STAMP" ] && mt=$(stat -f %m "$STAMP")
if ! smart_demo updates && [ $(( now - mt )) -ge $(( FLAT_BREW_HOURS * 3600 )) ]; then start_job; fi

count=0
if smart_demo updates; then count=73
elif [ -s "$LIST" ]; then count=$(grep -c . "$LIST"); fi

if [ "$count" -gt 0 ]; then
  ago="never"; [ "$mt" -gt 0 ] && ago="$(date -r "$mt" '+%H:%M')"
  sketchybar --set control.updates drawing=on label="Updates  $count   (checked $ago)"
else
  sketchybar --set control.updates drawing=off --remove control.updates.again --remove control.updates.copy 2>/dev/null
fi
