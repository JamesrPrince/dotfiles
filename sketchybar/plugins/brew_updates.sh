#!/bin/bash
# Flat style, smart item "updates": a package icon and a count while Homebrew has updates waiting.
#   (no argument)  the item's script: reads the cache and shows or hides the item. If the cache is
#                  older than FLAT_BREW_HOURS it starts a detached refresh first (never waited for).
#   click          opens the popup listing what is outdated. It only lists: nothing is upgraded from
#                  the bar. The rows can copy the `brew upgrade` command; running it is James's.
#   refresh        runs the check again now (the popup's "Check again" row)
#   job            the detached refresh itself: `brew outdated`, read-only (no `brew update`, so the
#                  list is as fresh as Homebrew's own index, which any brew command refreshes)
# Cache: ~/.cache/sketchybar-brew-outdated (one "name (current) < latest" line per package) and its
# stamp ~/.cache/sketchybar-brew-checked. Cost when nothing is due: one small bash run per
# FLAT_POLL_UPDATES s that reads two files. brew itself runs at most every FLAT_BREW_HOURS.

source "$HOME/.config/sketchybar/plugins/hover.sh"
source "$HOME/.config/sketchybar/plugins/smart_lib.sh"
CACHE_DIR="$HOME/.cache"
LIST="$CACHE_DIR/sketchybar-brew-outdated"
STAMP="$CACHE_DIR/sketchybar-brew-checked"
LOCK="$SMART_DIR/brew.lock"
SELF="$HOME/.config/sketchybar/plugins/brew_updates.sh"

if [ "$SENDER" = "mouse.exited.global" ]; then
  sketchybar --set updates popup.drawing=off
  exit 0
fi

BREW=/usr/local/bin/brew; [ -x "$BREW" ] || BREW=/opt/homebrew/bin/brew

start_job() {   # detached, single instance, stale locks (a killed job) cleared after 10 minutes
  [ -x "$BREW" ] || return 0
  find "$LOCK" -maxdepth 0 -mmin +10 -exec rmdir {} \; 2>/dev/null
  mkdir "$LOCK" 2>/dev/null || return 0
  nohup nice -n 10 "$SELF" job >/dev/null 2>&1 &
  disown 2>/dev/null
}

if [ "$1" = job ]; then
  trap 'rmdir "$LOCK" 2>/dev/null' EXIT
  mkdir -p "$CACHE_DIR"
  export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ANALYTICS=1 HOMEBREW_NO_ENV_HINTS=1
  "$BREW" outdated --verbose > "$LIST.tmp" 2>/dev/null &
  bpid=$!
  t=0; while kill -0 "$bpid" 2>/dev/null && [ "$t" -lt 300 ]; do sleep 1; t=$((t + 1)); done   # 5 minute ceiling
  if kill -0 "$bpid" 2>/dev/null; then kill "$bpid" 2>/dev/null; rc=1; else wait "$bpid"; rc=$?; fi
  if [ "$rc" = 0 ]; then mv "$LIST.tmp" "$LIST"; else rm -f "$LIST.tmp"; fi
  : > "$STAMP"
  sketchybar --trigger smart_refresh
  exit 0
fi

# Is a refresh due?
now=$(date +%s)
mt=0; [ -e "$STAMP" ] && mt=$(stat -f %m "$STAMP")
if [ "$1" = refresh ]; then start_job; exit 0; fi
if [ $(( now - mt )) -ge $(( FLAT_BREW_HOURS * 3600 )) ]; then start_job; fi

if smart_demo updates; then
  printf '%s\n' "node (20.11.1) < 21.2.0" "ripgrep (14.0.3) < 14.1.0" "git (2.43.0) < 2.44.0" > "$SMART_DIR/updates.demo"
  SRC="$SMART_DIR/updates.demo"
else
  SRC="$LIST"
fi
count=0; [ -s "$SRC" ] && count=$(grep -c . "$SRC")

if [ "$1" != click ]; then
  if [ "$count" -gt 0 ]; then
    source "$HOME/.config/sketchybar/icons.sh"
    SM_ICON=$FLAT_UPDATES_ICON; SM_LABEL=$count; SM_IW=18
    smart_show updates
  else
    smart_hide updates
  fi
  exit 0
fi

# --- click: the popup (rows only list; "Check again" runs a read-only check, "Copy" fills the clipboard) ---
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
flat_colors
FONT="SF Pro"
source "$HOME/.config/sketchybar/plugins/style.sh"
row=(icon.font="$FONT:Regular:14.0" icon.width=26 icon.color=$GREY label.font="$TEXT_FONT:SemiBold:13.0" label.max_chars=46
     padding_left=8 padding_right=12 background.corner_radius=$FLAT_POPUP_RADIUS)
args=(--remove '/updates\.row\..*/')
add() { args+=(--add item updates.row.$1 popup.updates --set updates.row.$1 "${row[@]}" "${@:2}"); }
hover=(script="$HOME/.config/sketchybar/plugins/hover.sh")

if [ "$count" -gt 0 ]; then
  add hdr icon.drawing=off label="$count UPDATE$( [ "$count" = 1 ] || echo S ) WAITING" label.font="$TEXT_FONT:ExtraBold:11.0" label.color=$GREY
  n=0
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    n=$((n + 1)); [ "$n" -gt "$FLAT_BREW_MAX_ROWS" ] && break
    name=${line%% *}; rest=${line#* }
    cur=${rest#\(}; cur=${cur%%)*}; new=${line##*< }; [ "$new" = "$line" ] && new=${line##*!= }
    add pkg$n icon="$FLAT_UPDATES_ICON" icon.font="Maple Mono NF:Bold:14.0" label="$name  $cur → $new"
  done < "$SRC"
  [ "$count" -gt "$FLAT_BREW_MAX_ROWS" ] && add more icon.drawing=off label="+ $((count - FLAT_BREW_MAX_ROWS)) more" label.color=$GREY
else
  add none icon=$LOCK_FILL label="Everything is up to date"
fi
mt=0; [ -e "$STAMP" ] && mt=$(stat -f %m "$STAMP")
ago="never"; [ "$mt" -gt 0 ] && ago="$(date -r "$mt" '+%H:%M')"
add again icon=$BOLT label="Check again   (last: $ago)" "${hover[@]}" click_script="$SELF refresh; sketchybar --set updates popup.drawing=off"
add copy icon=$COPY label="Copy  brew upgrade" "${hover[@]}" click_script="printf 'brew upgrade' | pbcopy; sketchybar --set updates popup.drawing=off"
add note icon.drawing=off label="Nothing is upgraded from the bar" label.font="$TEXT_FONT:Medium:11.0" label.color=$GREY
sketchybar "${args[@]}" >/dev/null 2>&1
sketchybar --subscribe updates.row.again mouse.entered mouse.exited --subscribe updates.row.copy mouse.entered mouse.exited >/dev/null 2>&1
"$HOME/.config/sketchybar/plugins/popup.sh" updates toggle
