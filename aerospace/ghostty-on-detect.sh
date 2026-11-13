#!/bin/bash
# Every real Ghostty window tiles, so alt-hjkl (focus) and alt-shift-hjkl (move) work on it.
# The first one goes to workspace 2; later ones tile where they open. Only the quick terminal
# and native-tab AX windows (AeroSpace #68) float. The aerospace.toml rule floats every new
# Ghostty window first, so those two never enter the tiling tree and nothing reflows.
#   ghostty-on-detect.sh [window-id]            act on the window (AeroSpace passes AEROSPACE_WINDOW_ID)
#   ghostty-on-detect.sh --dry-run [window-id]  print quick, tab or tile and change nothing
#   GHOSTTY_DETECT_DUMP=<file>                  read that debug-windows dump instead (for tests)
set -u

PATH="/usr/local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:${PATH:-/usr/bin:/bin:/usr/sbin:/sbin}"
export PATH

dry=0
if [ "${1:-}" = "--dry-run" ]; then dry=1; shift; fi

AERO=""
for candidate in /usr/local/bin/aerospace /opt/homebrew/bin/aerospace; do
    if [ -x "$candidate" ]; then
        AERO="$candidate"
        break
    fi
done
if [ -z "$AERO" ]; then
    AERO="$(command -v aerospace 2>/dev/null || true)"
fi
[ -n "$AERO" ] || exit 0

wid="${AEROSPACE_WINDOW_ID:-${1:-}}"
[ -n "$wid" ] || exit 0

GHOSTTY_CONF="$HOME/.config/ghostty/config"

float_here() {
    "$AERO" layout floating --window-id "$wid" >/dev/null 2>&1 || true
}

dump_of() { # debug-windows is not a stable API; every reader below copes with an empty dump
    if [ "$1" = "$wid" ] && [ -n "${GHOSTTY_DETECT_DUMP:-}" ]; then
        cat "$GHOSTTY_DETECT_DUMP"
    else
        "$AERO" debug-windows --window-id "$1" 2>/dev/null || true
    fi
}

frame_in() { # "x y w h" of the window in a dump read from stdin
    sed -n 's/.*"AXFrame" : "<AXValue[^"]*{value = x:\([-0-9.]*\) y:\([-0-9.]*\) w:\([0-9.]*\) h:\([0-9.]*\).*/\1 \2 \3 \4/p' | head -1
}

dump="$(dump_of "$wid")"
frame="$(printf '%s\n' "$dump" | frame_in)"

# The quick terminal is quick-terminal-size (height%,width%) of a screen. Its size is tested,
# not its position, because it is still sliding in when AeroSpace first sees it.
is_quick_terminal() {
    local w h size ph pw disp
    [ -n "$dump" ] || return 1
    printf '%s\n' "$dump" | grep -q 'Aero.AxUiElementWindowType_isDialogHeuristic" : true' && return 0
    # Only a real non-normal level means the quick terminal; the level often
    # reads null on an ordinary window, which falls through to the size checks
    if printf '%s\n' "$dump" | grep -q '"Aero.windowLevel" : "'; then
        printf '%s\n' "$dump" | grep -q '"Aero.windowLevel" : "normalWindow"' || return 0
    fi
    [ -n "$frame" ] || return 1
    read -r _ _ w h <<<"$frame"
    size="$(sed -n 's/^[[:space:]]*quick-terminal-size[[:space:]]*=[[:space:]]*\([0-9]*\)%,[[:space:]]*\([0-9]*\)%.*/\1 \2/p' "$GHOSTTY_CONF" 2>/dev/null | tail -1)"
    read -r ph pw <<<"${size:-45 50}"
    # Screen sizes in points from SketchyBar (same units as AXFrame; no Finder round trip).
    # 2560x1600 is the built-in display, for when the bar is not up yet.
    disp="$(/usr/local/bin/sketchybar --query displays 2>/dev/null | grep -E '"(w|h)":')"
    [ -n "$disp" ] || disp='"w":2560
"h":1600'
    if printf '%s\n' "$disp" | awk -F: -v W="$w" -v H="$h" -v pw="$pw" -v ph="$ph" '
        function near(a, b, tol) { return (a > b ? a - b : b - a) <= tol }
        /"w"/ { gsub(/[^0-9.]/, "", $2); sw = $2 }
        /"h"/ { gsub(/[^0-9.]/, "", $2); sh = $2
                if (sw > 0 && sh > 0 && near(W, sw * pw / 100, sw * 0.03) && near(H, sh * ph / 100, sh * 0.03)) hit = 1 }
        END { exit !hit }'; then
        return 0
    fi
    # An ordinary terminal window carries this identifier, whatever its size
    printf '%s\n' "$dump" | grep -q '"AXIdentifier" : "TerminalWindowRestoration"' && return 1
    # Unknown window clearly shorter than the first screen: treat as the quick terminal
    printf '%s\n' "$disp" | awk -F: -v H="$h" '
        /"h"/ && !seen { seen = 1; gsub(/[^0-9.]/, "", $2); if ($2 > 0 && H < 0.75 * $2) hit = 1 }
        END { exit !hit }'
}

others() { # other Ghostty windows as "id|layout"
    "$AERO" list-windows --monitor all --app-bundle-id com.mitchellh.ghostty --format '%{window-id}|%{window-layout}' 2>/dev/null | awk -F'|' -v id="$wid" '$1 != id'
}

# A native tab is its own AX window with exactly the frame of the window it sits in; a new
# window is cascaded, so its position differs. A hidden title bar has no tabs at all.
is_tab() {
    local id
    grep -Eq '^[[:space:]]*macos-titlebar-style[[:space:]]*=[[:space:]]*hidden' "$GHOSTTY_CONF" 2>/dev/null && return 1
    [ -n "$frame" ] || return 1
    for id in $(others | cut -d'|' -f1); do
        [ "$(dump_of "$id" | frame_in)" = "$frame" ] && return 0
    done
    return 1
}

if is_quick_terminal; then kind=quick
elif is_tab; then kind=tab
else kind=tile
fi

if [ "$dry" = 1 ]; then echo "$kind"; exit 0; fi
if [ "$kind" != tile ]; then
    float_here
    exit 0
fi

tiling_others="$(others | awk -F'|' '$2 != "" && $2 != "floating" { n++ } END { print n+0 }')"

# Windows restored in the first seconds after Ghostty starts all belong on workspace 2
pid="$("$AERO" list-windows --monitor all --app-bundle-id com.mitchellh.ghostty --format '%{window-id}|%{app-pid}' 2>/dev/null | awk -F'|' -v id="$wid" '$1 == id { print $2 }')"
age=""
[ -n "$pid" ] && age="$(ps -o etime= -p "$pid" 2>/dev/null | tr -d ' ')"
just_launched=0
[[ "$age" =~ ^00:(0[0-9]|1[0-4])$ ]] && just_launched=1

"$AERO" layout tiling --window-id "$wid" >/dev/null 2>&1 || true
if [ "${tiling_others:-0}" -eq 0 ] || [ "$just_launched" = 1 ]; then
    "$AERO" move-node-to-workspace --window-id "$wid" 2 >/dev/null 2>&1 || true
fi
