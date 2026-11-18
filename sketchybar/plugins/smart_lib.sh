#!/bin/bash
# Shared by the flat style's smart items (privacy, VPN, keep-awake, badges, market, music,
# next meeting, timer). Source it. An item that has nothing to say takes no space: it stays defined
# with drawing=on but with zero padding, zero icon and label width and transparent text; showing it
# animates the widths and colours in. Items that sit at the left end of the right-hand group only
# push each other leftwards, so the stats and tray never move. The meeting and timer sit after the clock as
# zero-width centre items (they draw to the right of the clock without moving it); the claude count and the music
# are the left end of the right-hand group. Between them is a budget in pixels that depends on the display's width
# (flat_config.sh: flat_budget): at 2560 with every smart item on, the timer ends at x=1607 and claude starts
# at x=1635 (28 px clear), the meeting title gets 12 columns and the music title 8. A narrower display gives the
# meeting and music titles less, then hides the music, then the meeting; below about 2030 px even the timer and
# claude cannot both fit beside every other smart item at once. Text is sized in display columns (CJK and emoji
# are two) and clipped by label.width, so wide glyphs lose their tail instead of drawing over a neighbour.
#
# Usage in a plugin:
#   source plugins/smart_lib.sh
#   SM_ICON="$glyph" SM_LABEL="text" SM_IC=$colour SM_LC=$colour smart_show vpn
#   smart_hide vpn
# Test switch: plugins/smart_demo.sh on <name...|all>  (or SMART_DEMO=name,name when running a plugin by hand);
# smart_demo <name> is true while a name is forced on. Names: privacy vpn awake updates (the control popup row) slack whatsapp
# market music meeting timer battery title workspaces.

export PATH="/usr/local/bin:$PATH"
export LC_CTYPE=en_US.UTF-8                    # ${#text} counts characters, not bytes
source "$HOME/.config/sketchybar/plugins/flat_config.sh"
SMART_DIR="${TMPDIR:-/tmp}/sketchybar_smart"
[ -d "$SMART_DIR" ] || mkdir -p "$SMART_DIR"

smart_demo() { case ",$SMART_DEMO," in *",$1,"*|*",all,"*) return 0 ;; esac; [ -e "$SMART_DIR/demo.$1" ]; }
smart_zen()  { [ -f "${TMPDIR:-/tmp}/sketchybar_zen" ]; }

# smart_geom <item>: G_IW icon cell, G_LP gap before the label, G_PL / G_PR item padding,
# G_CW label character width in tenths of a pixel (12 pt Maple Mono is 7.2 px)
smart_geom() {
  G_IW=18 G_LP=4 G_PL=4 G_PR=4 G_CW=72
  case $1 in
    privacy)            G_LP=0 ;;
    vpn|awake)          G_IW=18 G_PL=2 G_PR=2 ;;
    badge.*)            G_IW=16 G_LP=3 ;;
    market.*)           G_IW=0 G_LP=0 G_PL=4 G_PR=4 ;;
    spotify.anchor)     G_IW=18 G_PL=6 G_PR=6 ;;
    next_event)         G_PL=10 G_PR=0 ;;
    timer)              G_PL=10 G_PR=0 ;;
  esac
}

# smart_show <item>: SM_ICON (glyph, empty for none), SM_LABEL (text, empty for none), SM_IC / SM_LC
# (colours; default neutral), SM_IW / SM_LW (override the widths, for glyph labels)
smart_show() {
  local n=$1 cur key iw lw=0 lp=0 args
  smart_zen && return 0
  smart_geom "$n"
  iw=$G_IW; [ -n "$SM_ICON" ] || iw=0; [ -n "$SM_IW" ] && iw=$SM_IW
  if [ -n "$SM_LABEL" ]; then
    lw=${SM_LW:-$(( ($(flat_cols "$SM_LABEL") * G_CW + 9) / 10 + 2 ))}
    [ "$iw" = 0 ] || lp=$G_LP
    lw=$(( lw + lp ))        # label.width includes the label's own left padding
  fi
  key="on|$SM_ICON|$SM_LABEL|$SM_IC|$SM_LC|$iw|$lw"
  [ -r "$SMART_DIR/state.$n" ] && read -r cur < "$SMART_DIR/state.$n"
  [ "$cur" = "$key" ] && return 0
  printf '%s\n' "$key" > "$SMART_DIR/state.$n"
  flat_colors
  local pl=$G_PL ic=${SM_IC:-$FLAT_REST} lc=${SM_LC:-$FLAT_REST} total
  [ "$n" = timer ] && pl=$(smart_timer_pad)
  total=$(( pl + G_PR + iw + lw ))
  echo "$total" > "$SMART_DIR/w.$n"
  args=(--set "$n" drawing=on icon="$SM_ICON" label="$SM_LABEL"
        --animate $FLAT_ANIM
        --set "$n" padding_left=$pl padding_right=$G_PR icon.width=$iw icon.padding_left=0 icon.padding_right=0
                   label.width=$lw label.padding_left=$lp label.padding_right=0 icon.color=$ic label.color=$lc)
  # The timer starts after the meeting, whatever its width
  [ "$n" = next_event ] && smart_timer_follow
  sketchybar "${args[@]}"
}

# smart_hide <item>: collapse to nothing
smart_hide() {
  local n=$1 cur args
  smart_zen && return 0
  # No state file: never shown since the bar loaded, so it is already collapsed. "unknown" (written
  # when zen mode ends) forces one send.
  [ -r "$SMART_DIR/state.$n" ] && read -r cur < "$SMART_DIR/state.$n"
  [ -z "$cur" ] || [ "$cur" = off ] && return 0
  printf 'off\n' > "$SMART_DIR/state.$n"
  echo 0 > "$SMART_DIR/w.$n"
  args=(--animate $FLAT_ANIM
        --set "$n" padding_left=0 padding_right=0 icon.width=0 label.width=0 label.padding_left=0
                   icon.color=0x00000000 label.color=0x00000000)
  [ "$n" = next_event ] && smart_timer_follow
  sketchybar "${args[@]}"
}

# The timer's padding_left = where the meeting item ends (+ a gap), or the plain 10 when there is none
smart_timer_pad() {
  local w=0
  [ -r "$SMART_DIR/w.next_event" ] && read -r w < "$SMART_DIR/w.next_event"
  if [ "${w:-0}" -gt 0 ]; then echo $(( w + 10 )); else echo 10; fi
}
# smart_timer_follow: when the meeting changes size, move the timer along (if shown). Appends to the
# caller's `args` array (bash 3.2 has no namerefs; dynamic scope does the job).
smart_timer_follow() {
  local cur pl
  [ -r "$SMART_DIR/state.timer" ] && read -r cur < "$SMART_DIR/state.timer"
  case $cur in on\|*) pl=$(smart_timer_pad); args+=(--set timer padding_left=$pl) ;; esac
}

# smart_label_only <item> <text|""> <colour>: reveals or collapses just the label of an always-shown
# item (the battery percentage). Width from the text (12 pt Maple Mono).
smart_label_only() {
  local n=$1 text=$2 color=$3 lw=0 lp=0 key cur
  [ -n "$text" ] && { lp=3; lw=$(( (${#text} * 72 + 9) / 10 + 2 + lp )); }
  key="$text|$color"
  [ -r "$SMART_DIR/state.$n" ] && read -r cur < "$SMART_DIR/state.$n"
  [ "$cur" = "$key" ] && return 0
  printf '%s\n' "$key" > "$SMART_DIR/state.$n"
  if [ -n "$text" ]; then
    sketchybar --set "$n" label="$text" --animate $FLAT_ANIM --set "$n" label.width=$lw label.padding_left=$lp label.color=$color
  else
    sketchybar --animate $FLAT_ANIM --set "$n" label.width=0 label.padding_left=0 label.color=0x00000000
  fi
}
