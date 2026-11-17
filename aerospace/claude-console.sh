#!/bin/bash
# Quake-style Claude console, after Omarchy 4.5's SUPER+` agent console (alt-c).
# One dedicated Ghostty window running `claude` in ~/ICOR, summoned and hidden with one key.
# It is not the ctrl+` quick terminal, which stays a plain shell.
#
#   claude-console.sh toggle   not running: open it on this workspace, floating
#                              elsewhere or hidden: bring it here, floating, and focus it
#                              focused: send it away to the hidden workspace S
#   claude-console.sh status   print "<window-id> <workspace>" or "none"
#
# The window is a separate Ghostty process (open -n) with a pinned title, so Claude Code cannot
# rename it and aerospace.toml can float it on detection. The window id and pid are kept in
# $STATE/window.id; the title is only the fallback. The process ignores the global ctrl+`
# keybind (the first Ghostty owns it) and quits with its last window.
# Hiding reuses scratchpad.sh's workspace S, so alt-shift-equal can also pull the console back.
# Not built: centring the float (AeroSpace has no command for it); it keeps its last frame.
#
# Test overrides: CLAUDE_CONSOLE_CMD (command to run), CLAUDE_CONSOLE_STATE (state directory).
set -u

PATH="/usr/local/bin:/opt/homebrew/bin:$HOME/.local/bin:/usr/bin:/bin:${PATH:-}"
export PATH
AS=/usr/local/bin/aerospace
SK=/usr/local/bin/sketchybar
[ -x "$AS" ] || AS="$(command -v aerospace)" || exit 1

TITLE=claude-console
HIDDEN=S
DIR="${CLAUDE_CONSOLE_DIR:-$HOME/ICOR}"
STATE="${CLAUDE_CONSOLE_STATE:-$HOME/.local/state/claude-console}"
IDFILE="$STATE/window.id"
LOCK="$STATE/.lock"
CMD="${CLAUDE_CONSOLE_CMD:-$(command -v claude || echo "$HOME/.local/bin/claude")}"
mkdir -p "$STATE"

refresh() { "$SK" --trigger aerospace_focus_change >/dev/null 2>&1 & }

lock() { # a second press while the first is still opening the window does nothing
    if ! mkdir "$LOCK" 2>/dev/null; then
        if [ -n "$(find "$LOCK" -maxdepth 0 -mmin +1 2>/dev/null)" ]; then
            rmdir "$LOCK" 2>/dev/null; mkdir "$LOCK" 2>/dev/null || return 1
        else
            return 1
        fi
    fi
    trap 'rmdir "$LOCK" 2>/dev/null' EXIT
}

windows() { "$AS" list-windows --all --format '%{window-id}|%{app-pid}|%{app-bundle-id}|%{workspace}|%{window-title}' 2>/dev/null; }

# Print "id|workspace" of the console, or nothing. The recorded id (with its pid) wins; a Ghostty
# window with the pinned title is the fallback and is recorded.
find_console() {
    local all id pid line
    all="$(windows)"
    if [ -f "$IDFILE" ] && read -r id pid < "$IDFILE" && [ -n "$id" ]; then
        line="$(printf '%s\n' "$all" | awk -F'|' -v i="$id" -v p="$pid" \
            '$1 == i && $2 == p && $3 == "com.mitchellh.ghostty" { print $1 "|" $4; exit }')"
        [ -n "$line" ] && { echo "$line"; return; }
    fi
    line="$(printf '%s\n' "$all" | awk -F'|' -v t="$TITLE" \
        '$3 == "com.mitchellh.ghostty" && $5 == t { print $1 "|" $2 "|" $4; exit }')"
    if [ -n "$line" ]; then
        IFS='|' read -r id pid ws <<< "$line"
        echo "$id $pid" > "$IDFILE"
        echo "$id|$ws"
        return
    fi
    rm -f "$IDFILE"
}

place() { # place <id> <workspace>: here, floating, focused
    "$AS" move-node-to-workspace --window-id "$1" "$2" >/dev/null 2>&1
    "$AS" layout --window-id "$1" floating >/dev/null 2>&1
    "$AS" focus --window-id "$1" >/dev/null 2>&1
}

launch() { # launch <workspace>
    local ws="$1" i id pid
    open -na Ghostty --args \
        --title="$TITLE" \
        --working-directory="$DIR" \
        --quit-after-last-window-closed=true \
        --keybind=global:ctrl+grave_accent=unbind \
        ${CLAUDE_CONSOLE_CMD:+--confirm-close-surface=false} \
        -e "$CMD" || return 1
    for i in $(seq 1 60); do # up to 12 s for the window to appear
        sleep 0.2
        read -r id pid <<< "$(windows | awk -F'|' -v t="$TITLE" \
            '$3 == "com.mitchellh.ghostty" && $5 == t { print $1, $2; exit }')"
        [ -n "$id" ] && break
    done
    [ -n "$id" ] || { echo "claude-console: window did not appear" >&2; return 1; }
    echo "$id $pid" > "$IDFILE"
    place "$id" "$ws"
    echo "opened $id on $ws"
}

case "${1:-toggle}" in
status)
    found="$(find_console)"
    if [ -n "$found" ]; then echo "${found%|*} ${found#*|}"; else echo none; fi
    ;;
toggle)
    lock || exit 0
    here="$("$AS" list-workspaces --focused)" || exit 1
    [ -n "$here" ] || exit 1
    focused="$("$AS" list-windows --focused --format '%{window-id}' 2>/dev/null)"
    found="$(find_console)"
    if [ -z "$found" ]; then
        launch "$here"
    else
        id="${found%|*}"; ws="${found#*|}"
        if [ "$id" = "$focused" ]; then
            "$AS" move-node-to-workspace --window-id "$id" "$HIDDEN" >/dev/null 2>&1
            echo "hid $id from $ws to $HIDDEN"
        else
            place "$id" "$here"
            echo "brought $id from $ws to $here"
        fi
    fi
    refresh
    ;;
*) echo "usage: $0 toggle|status" >&2; exit 2 ;;
esac
