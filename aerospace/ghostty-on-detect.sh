#!/bin/bash
# First real Ghostty window tiles on workspace 2. Extra native-tab AX windows
# (AeroSpace #68) and the quick terminal float in place and are not moved.
set -u

PATH="/usr/local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:${PATH:-/usr/bin:/bin:/usr/sbin:/sbin}"
export PATH

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

float_here() {
    "$AERO" layout floating --window-id "$wid" >/dev/null 2>&1 || true
}

# Quick terminal is 45%x50% from the top (Ghostty config). debug-windows is
# not a stable API; if parse fails we only float extras and leave a comment
# in aerospace.toml that the overlay stays on the current workspace.
is_quick_terminal() {
    local dump h desk_h
    dump="$("$AERO" debug-windows --window-id "$wid" 2>/dev/null || true)"
    [ -n "$dump" ] || return 1
    printf '%s\n' "$dump" | grep -q 'Aero.AxUiElementWindowType_isDialogHeuristic" : true' && return 0
    if printf '%s\n' "$dump" | grep -q '"Aero.windowLevel"'; then
        printf '%s\n' "$dump" | grep -q '"Aero.windowLevel" : "normalWindow"' || return 0
    fi
    h="$(printf '%s\n' "$dump" | sed -n 's/.*"AXSize" : "<AXValue[^"]*{value = w:[0-9.]* h:\([0-9.]*\).*/\1/p' | head -1)"
    [ -n "$h" ] || return 1
    desk_h="$(osascript -e 'tell application "Finder" to get item 4 of (bounds of window of desktop)' 2>/dev/null || true)"
    [ -n "$desk_h" ] || return 1
    awk -v h="$h" -v s="$desk_h" 'BEGIN { exit !(s > 0 && h < 0.75 * s) }'
}

if is_quick_terminal; then
    float_here
    exit 0
fi

tiling_others="$("$AERO" list-windows --monitor all --app-bundle-id com.mitchellh.ghostty --format '%{window-id}|%{window-layout}' 2>/dev/null | awk -F'|' -v id="$wid" '$1 != id && $2 != "" && $2 != "floating" { n++ } END { print n+0 }')"

if [ "${tiling_others:-0}" -gt 0 ]; then
    float_here
    exit 0
fi

"$AERO" layout tiling --window-id "$wid" >/dev/null 2>&1 || true
"$AERO" move-node-to-workspace --window-id "$wid" 2 >/dev/null 2>&1 || true
