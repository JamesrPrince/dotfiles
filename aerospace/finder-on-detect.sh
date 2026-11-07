#!/bin/bash
# Finder browser windows tile. Quick Look and dialogs float.
# Space-bar QL is a Finder window titled with the filename, not "Quick Look".
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

tile_here() {
    "$AERO" layout tiling --window-id "$wid" >/dev/null 2>&1 || true
}

is_ql_or_dialog() {
    local dump title ident
    dump="$("$AERO" debug-windows --window-id "$wid" 2>/dev/null || true)"
    # Fail closed to floating so a missed QL cannot reflow tiles.
    [ -n "$dump" ] || return 0
    title="$(printf '%s\n' "$dump" | sed -n 's/.*"AXTitle" : "\(.*\)".*/\1/p' | head -1)"
    case "$title" in
        "Quick Look"|"Finder Settings"|*" Info") return 0 ;;
    esac
    printf '%s\n' "$dump" | grep -q 'Aero.AxUiElementWindowType_isDialogHeuristic" : true' && return 0
    printf '%s\n' "$dump" | grep -q '"AXFullScreenButton" : null' && return 0
    ident="$(printf '%s\n' "$dump" | sed -n 's/.*"AXIdentifier" : "\(.*\)".*/\1/p' | head -1)"
    [ "$ident" = "FinderWindow" ] || return 0
    return 1
}

if is_ql_or_dialog; then
    float_here
    exit 0
fi

tile_here
