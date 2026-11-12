#!/bin/bash
# Scratchpad on a hidden AeroSpace workspace "S" (not in persistent-workspaces).
#   scratchpad.sh send   - send the focused window to S
#   scratchpad.sh bring  - bring the most recent S window back here, floating
# The ids of sent windows live in $STACK (newest last).
AS=/usr/local/bin/aerospace
SK=/usr/local/bin/sketchybar
STACK="${HOME}/.cache/aerospace-scratchpad.stack"
mkdir -p "$(dirname "$STACK")"; touch "$STACK"

refresh() { "$SK" --trigger aerospace_focus_change >/dev/null 2>&1 & }

case "$1" in
send)
    id=$("$AS" list-windows --focused --format '%{window-id}') || exit 1
    [ -n "$id" ] || exit 0
    "$AS" move-node-to-workspace --window-id "$id" S || exit 1
    grep -vx "$id" "$STACK" > "$STACK.tmp"; echo "$id" >> "$STACK.tmp"; mv "$STACK.tmp" "$STACK"
    refresh
    ;;
bring)
    in_s=$("$AS" list-windows --workspace S --format '%{window-id}')
    [ -n "$in_s" ] || exit 0
    # newest stack entry still in S; else any window in S
    id=$(tail -r "$STACK" | while read -r s; do echo "$in_s" | grep -qx "$s" && { echo "$s"; break; }; done)
    [ -n "$id" ] || id=$(echo "$in_s" | tail -n 1)
    ws=$("$AS" list-workspaces --focused)
    "$AS" move-node-to-workspace --window-id "$id" "$ws" || exit 1
    "$AS" layout --window-id "$id" floating
    "$AS" focus --window-id "$id"
    grep -vx "$id" "$STACK" > "$STACK.tmp"; mv "$STACK.tmp" "$STACK"
    # Not centred: AeroSpace has no centring command and the Accessibility/osascript route was refused
    # by the permission system. The window returns at its last floating size and position.
    refresh
    ;;
*) echo "usage: $0 send|bring" >&2; exit 2 ;;
esac
