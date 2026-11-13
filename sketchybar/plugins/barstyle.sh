#!/bin/bash
# Switches the bar style. Usage:
#   barstyle.sh next          centre -> flat -> centre
#   barstyle.sh set <style>   centre or flat
#   barstyle.sh get           prints the current style
# Writes ~/.config/sketchybar/.barstyle, sets AeroSpace's top gap to fit the bar (the one
# `gaps.outer.top` line of the real aerospace.toml), reloads AeroSpace's config, then the bar.

export PATH="/usr/local/bin:$PATH"
CONF="$HOME/.config/sketchybar"
source "$CONF/plugins/style.sh"

# ~/.aerospace.toml is a symlink: edit the file it points at, never the link itself
TOML="$HOME/.aerospace.toml"
[ -L "$TOML" ] && TOML=$(readlink "$TOML")
[ -f "$TOML" ] || TOML="$HOME/dotfiles/aerospace/aerospace.toml"

set_style() {
  local style=$1 gap
  case "$style" in
    centre) gap=$CENTRE_TOP_GAP ;;
    flat)   gap=$FLAT_TOP_GAP ;;
    *) echo "barstyle: unknown style '$style' (use centre or flat)" >&2; return 2 ;;
  esac

  echo "$style" > "$CONF/.barstyle" || return 1

  # Only touch the file when the gap actually changes
  if ! grep -Eq "^gaps\.outer\.top[[:space:]]*=[[:space:]]*$gap[[:space:]]*(#.*)?$" "$TOML"; then
    sed -i '' -E "s/^(gaps\.outer\.top[[:space:]]*=[[:space:]]*)[0-9]+/\1$gap/" "$TOML" || return 1
  fi

  local rc=0
  aerospace reload-config || rc=$?
  sketchybar --reload || rc=$?
  return $rc
}

case "$1" in
  next)
    if [ "$BAR_STYLE" = flat ]; then set_style centre; else set_style flat; fi ;;
  set)
    set_style "$2" ;;
  get)
    echo "$BAR_STYLE" ;;
  *)
    echo "usage: barstyle.sh next | set <centre|flat> | get" >&2
    exit 2 ;;
esac
