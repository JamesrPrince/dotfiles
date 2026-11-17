#!/bin/bash
# Per-workspace layout cycle, after Omarchy 4.5 (omarchy-hyprland-workspace-layout-toggle):
#   tiles -> accordion (the stack) -> floating -> tiles      (next, alt-slash)
#   tiles -> floating -> accordion -> tiles                  (back, alt-shift-period)
#
#   layout-cycle.sh [next|back] [--workspace N]   cycle the focused (or named) workspace
#   layout-cycle.sh set tiles|accordion|floating [--workspace N]
#   layout-cycle.sh current [--workspace N]       print the mode
#   layout-cycle.sh enforce                       float tiled windows on floating workspaces
#                                                 (on-focus-changed and a last on-window-detected rule)
#   layout-cycle.sh restore                       re-apply the saved modes (after-startup-command)
#
# Floating mode floats only the windows that were tiled and remembers their ids, so leaving
# the mode re-tiles exactly those. A window that floats by its own rule (Calculator, dialogs)
# is left alone both ways. A new tiled window on a floating workspace floats as it appears.
# `layout` acts on the focused container, so tiles and accordion flatten the workspace first.
#
# State, outside the repo: ~/.local/state/aerospace-layouts/<ws>.mode (accordion|floating;
# no file means tiles) and <ws>.floated (ids this script floated). AEROSPACE_LAYOUT_STATE
# overrides the directory.
# Not built: Omarchy also centres and cascades a new floating window. AeroSpace has no command
# to move or resize a floating window, so it keeps the frame it had.
set -u

PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:${PATH:-}"
export PATH
AERO=/usr/local/bin/aerospace
[ -x "$AERO" ] || AERO="$(command -v aerospace)" || exit 0
SKETCHYBAR=/usr/local/bin/sketchybar
STATE="${AEROSPACE_LAYOUT_STATE:-$HOME/.local/state/aerospace-layouts}"
LOCK="$STATE/.lock"

cmd="${1:-next}"; [ $# -gt 0 ] && shift
WS=""
NEWMODE=""
if [ "$cmd" = set ]; then NEWMODE="${1:-}"; [ $# -gt 0 ] && shift; fi
while [ $# -gt 0 ]; do
    case "$1" in
        --workspace) WS="${2:-}"; shift 2 ;;
        *) shift ;;
    esac
done

mkdir -p "$STATE"

floating_dirs() { grep -qs '^floating$' "$STATE"/*.mode 2>/dev/null; }

lock() { # take the lock; a lock older than 15s is stale
    local i=0
    while ! mkdir "$LOCK" 2>/dev/null; do
        if [ -n "$(find "$LOCK" -maxdepth 0 -mmin +1 2>/dev/null)" ]; then rmdir "$LOCK" 2>/dev/null; continue; fi
        i=$((i + 1)); [ "$i" -gt 40 ] && return 1
        sleep 0.1
    done
    trap 'rmdir "$LOCK" 2>/dev/null' EXIT
}

windows() { # windows <ws>: id|layout|fullscreen per line
    "$AERO" list-windows --workspace "$1" \
        --format '%{window-id}|%{window-layout}|%{window-is-fullscreen}' 2>/dev/null
}

saved_mode() { cat "$STATE/$1.mode" 2>/dev/null; }

current_mode() { # current_mode <ws>
    local saved layout
    saved=$(saved_mode "$1")
    if [ "$saved" = floating ]; then echo floating; return; fi
    layout=$(windows "$1" | awk -F'|' '$2 != "floating" {print $2; exit}')
    case "$layout" in
        *_accordion) echo accordion ;;
        "") echo "${saved:-tiles}" ;;
        *) echo tiles ;;
    esac
}

float_window() { "$AERO" layout --window-id "$1" floating >/dev/null 2>&1; }

float_tiled() { # float_tiled <ws>: float every tiled window not yet floated by us; echo how many
    local ws="$1" n=0 id layout fs
    while IFS='|' read -r id layout fs; do
        [ -n "$id" ] || continue
        [ "$layout" = floating ] && continue
        [ "$fs" = true ] && continue
        grep -qx "$id" "$STATE/$ws.floated" 2>/dev/null && continue
        echo "$id" >> "$STATE/$ws.floated"
        float_window "$id"
        n=$((n + 1))
    done <<< "$(windows "$ws")"
    echo "$n"
}

retile_floated() { # re-tile only the windows this script floated, and only if still on <ws>
    local ws="$1" id here
    [ -f "$STATE/$ws.floated" ] || return 0
    here=$(windows "$ws" | cut -d'|' -f1)
    while read -r id; do
        [ -n "$id" ] || continue
        echo "$here" | grep -qx "$id" && "$AERO" layout --window-id "$id" tiling >/dev/null 2>&1
    done < "$STATE/$ws.floated"
    rm -f "$STATE/$ws.floated"
}

set_tree_layout() { # set_tree_layout <ws> <tiles|h_accordion>
    local ws="$1" target="$2" id
    "$AERO" flatten-workspace-tree --workspace "$ws" >/dev/null 2>&1
    id=$(windows "$ws" | awk -F'|' '$2 != "floating" {print $1; exit}')
    [ -n "$id" ] && "$AERO" layout --window-id "$id" "$target" >/dev/null 2>&1
    return 0
}

apply() { # apply <ws> <mode>
    local ws="$1" mode="$2" prev
    prev=$(current_mode "$ws")
    if [ "$prev" = floating ] && [ "$mode" != floating ]; then retile_floated "$ws"; fi
    case "$mode" in
        floating) echo floating > "$STATE/$ws.mode"; float_tiled "$ws" >/dev/null ;;
        accordion) echo accordion > "$STATE/$ws.mode"; set_tree_layout "$ws" h_accordion ;;
        *) rm -f "$STATE/$ws.mode"; set_tree_layout "$ws" tiles ;;
    esac
}

refresh_bar() { "$SKETCHYBAR" --trigger aerospace_layout_change >/dev/null 2>&1 || true; }

case "$cmd" in
    next|back|set|current)
        [ -n "$WS" ] || WS=$("$AERO" list-workspaces --focused 2>/dev/null)
        [ -n "$WS" ] || exit 1
        # S is the hidden scratchpad workspace: no layout of its own
        [ "$WS" = S ] && exit 0
        if [ "$cmd" = current ]; then current_mode "$WS"; exit 0; fi
        lock || exit 1
        cur=$(current_mode "$WS")
        case "$cmd" in
            set) new="$NEWMODE" ;;
            back) case "$cur" in tiles) new=floating ;; floating) new=accordion ;; *) new=tiles ;; esac ;;
            *)    case "$cur" in tiles) new=accordion ;; accordion) new=floating ;; *) new=tiles ;; esac ;;
        esac
        case "$new" in tiles|accordion|floating) ;; *) echo "layout-cycle: unknown mode '$new'" >&2; exit 2 ;; esac
        apply "$WS" "$new"
        refresh_bar
        echo "$WS: $cur -> $new"
        ;;
    enforce)
        floating_dirs || exit 0     # no floating workspace: nothing to do, no aerospace call
        lock || exit 0
        changed=0
        for f in "$STATE"/*.mode; do
            [ "$(cat "$f" 2>/dev/null)" = floating ] || continue
            ws=$(basename "$f" .mode)
            [ "$(float_tiled "$ws")" -gt 0 ] && changed=1
        done
        [ "$changed" = 1 ] && refresh_bar
        exit 0
        ;;
    restore)
        sleep 2   # let AeroSpace register the open windows
        lock || exit 0
        for f in "$STATE"/*.mode; do
            [ -f "$f" ] || continue
            ws=$(basename "$f" .mode); mode=$(cat "$f")
            rm -f "$STATE/$ws.floated"   # window ids do not survive a restart
            case "$mode" in
                floating) float_tiled "$ws" >/dev/null ;;
                accordion) set_tree_layout "$ws" h_accordion ;;
            esac
        done
        refresh_bar
        ;;
    *)
        echo "usage: layout-cycle.sh [next|back|set <mode>|current|enforce|restore] [--workspace N]" >&2
        exit 2
        ;;
esac
