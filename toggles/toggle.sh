#!/bin/bash
# Quick desktop toggles, after Omarchy's Toggle menu. Usage:
#   toggle.sh status                    gaps=on|off, bar=on|off, opacity=n/a   (one per line)
#   toggle.sh gaps    on|off|toggle|status
#   toggle.sh bar     on|off|toggle|status
#   toggle.sh opacity toggle|status
# gaps on = the normal 8px gaps; off = no inner or outer gaps (AeroSpace).
# bar  on = bar shown; off = bar hidden (SketchyBar).      (Omarchy's own wording is the reverse.)
# opacity: Ghostty's `toggle_background_opacity` action, bound to cmd+shift+o in ghostty/config.
#   Ghostty has no CLI or socket to run an action and the on/off state is per window and not
#   readable, so only `toggle` exists: it presses the keybind, and only when Ghostty is frontmost.
#
# The AeroSpace gap lines live in dotfiles/aerospace/aerospace.toml. The top gap is shared with
# the bar (barstyle.sh sets it to 36 flat / 57 centre), so it is derived, not saved:
#   gaps on,  bar shown   style gap (36 / 57)       gaps off, bar shown   style gap - 8 (28 / 49, the bar itself)
#   gaps on,  bar hidden  the outer side gap (8)    gaps off, bar hidden  0
# The other five gap values are saved in ~/.local/state/toggles/gaps when gaps go off, so on is exact.

export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"
STATE="$HOME/.local/state/toggles"
SAVED="$STATE/gaps"
KEYS="inner.horizontal inner.vertical outer.left outer.bottom outer.right"
DEFAULT_GAP=8
OPACITY_KEYS="cmd+shift+o"

# ~/.aerospace.toml is a symlink: edit the file it points at, never the link (sed -i would replace it)
TOML="$HOME/.aerospace.toml"
[ -L "$TOML" ] && TOML=$(readlink "$TOML")
[ -f "$TOML" ] || TOML="$HOME/dotfiles/aerospace/aerospace.toml"

die() { echo "toggle: $*" >&2; exit 2; }

get_gap() { # get_gap <key>  -> the number on that gaps.<key> line
  sed -nE "s/^gaps\.$1[[:space:]]*=[[:space:]]*([0-9]+).*/\1/p" "$TOML" | head -1
}

# Sets gaps.<key> to <value>, keeping the line's spacing; returns 0 when it changed the file
set_gap() {
  [ "$(get_gap "$1")" = "$2" ] && return 1
  sed -i '' -E "s/^(gaps\.$1[[:space:]]*=[[:space:]]*)[0-9]+/\1$2/" "$TOML"
}

bar_state() { # on = shown, off = hidden
  local h i
  for i in 1 2 3; do   # the bar's socket refuses queries for a moment while it reloads
    h=$(sketchybar --query bar 2>/dev/null | sed -nE 's/.*"hidden": *"([a-z]+)".*/\1/p')
    [ -n "$h" ] && break
    sleep 0.4
  done
  case "$h" in on) echo off ;; off) echo on ;; *) echo n/a ;; esac
}

gaps_state() {
  local k
  for k in $KEYS; do [ "$(get_gap "$k")" = 0 ] || { echo on; return; }; done
  echo off
}

style_top() { # the top gap barstyle.sh sets for the current style
  local BAR_STYLE FLAT_TOP_GAP=36 CENTRE_TOP_GAP=57 conf="$HOME/.config/sketchybar/plugins/style.sh"
  [ -r "$conf" ] && source "$conf"
  if [ "$BAR_STYLE" = flat ]; then echo "$FLAT_TOP_GAP"; else echo "$CENTRE_TOP_GAP"; fi
}

# Writes every gap for (gaps state, bar state), then reloads AeroSpace if anything changed
apply() { # apply <gaps on|off> <bar on|off>
  local g=$1 b=$2 k v changed=0 side top t
  t=$(style_top)
  if [ "$g" = on ]; then
    side=$DEFAULT_GAP
    for k in $KEYS; do
      v=$DEFAULT_GAP
      [ -r "$SAVED" ] && v=$(sed -nE "s/^$k=([0-9]+)$/\1/p" "$SAVED" | head -1)
      v=${v:-$DEFAULT_GAP}
      set_gap "$k" "$v" && changed=1
      [ "$k" = outer.left ] && side=$v
    done
    if [ "$b" = off ]; then top=$side; else top=$t; fi
  else
    for k in $KEYS; do set_gap "$k" 0 && changed=1; done
    if [ "$b" = off ]; then top=0; else top=$((t - 8)); fi
  fi
  set_gap outer.top "$top" && changed=1
  if [ "$changed" = 1 ]; then aerospace reload-config || return 1; fi
  return 0
}

save_gaps() { # remember the current gaps (called only while gaps are on, never to save zeros)
  mkdir -p "$STATE" || return 1
  local k tmp="$SAVED.tmp"
  : > "$tmp"
  for k in $KEYS; do echo "$k=$(get_gap "$k")" >> "$tmp"; done
  mv "$tmp" "$SAVED"
}

do_gaps() {
  local want=$1 cur
  cur=$(gaps_state)
  case "$want" in
    status) echo "$cur"; return 0 ;;
    toggle) if [ "$cur" = on ]; then want=off; else want=on; fi ;;
    on|off) ;;
    *) die "gaps: use on|off|toggle|status" ;;
  esac
  if [ "$want" = off ] && [ "$cur" = on ]; then save_gaps || die "cannot save gaps to $STATE"; fi
  apply "$want" "$(bar_state)" || return 1
  echo "$want"
}

do_bar() {
  local want=$1 cur
  cur=$(bar_state)
  [ "$cur" = n/a ] && [ "$want" != status ] && die "bar: SketchyBar is not running"
  case "$want" in
    status) echo "$cur"; return 0 ;;
    toggle) if [ "$cur" = on ]; then want=off; else want=on; fi ;;
    on|off) ;;
    *) die "bar: use on|off|toggle|status" ;;
  esac
  if [ "$want" = off ]; then sketchybar --bar hidden=on || return 1; else sketchybar --bar hidden=off || return 1; fi
  apply "$(gaps_state)" "$want" || return 1
  echo "$want"
}

do_opacity() {
  case "$1" in
    status) echo "n/a" ;;
    toggle)
      local front
      front=$(/usr/bin/osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null)
      if [ "$front" != ghostty ] && [ "$front" != Ghostty ]; then
        echo "opacity: focus Ghostty and press $OPACITY_KEYS (frontmost is '${front:-unknown}')" >&2
        return 3
      fi
      /usr/bin/osascript -e 'tell application "System Events" to keystroke "o" using {command down, shift down}' || return 1
      echo "toggled" ;;
    on|off) die "opacity: Ghostty's state is per window and unreadable, so only toggle exists (press $OPACITY_KEYS in Ghostty)" ;;
    *) die "opacity: use toggle|status" ;;
  esac
}

case "$1" in
  ""|status)
    echo "gaps=$(gaps_state)"; echo "bar=$(bar_state)"; echo "opacity=$(do_opacity status)" ;;
  gaps)    do_gaps "${2:-toggle}" ;;
  bar)     do_bar "${2:-toggle}" ;;
  opacity) do_opacity "${2:-toggle}" ;;
  *) die "usage: toggle.sh status | gaps|bar|opacity [on|off|toggle|status]" ;;
esac
