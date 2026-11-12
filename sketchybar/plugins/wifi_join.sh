#!/bin/bash
# Joins a network from the Wi-Fi popup. Usage: wifi_join.sh <saved|near|advice> <row number> [--dry-run]
# The row's name comes from the list wifi.sh wrote when it drew the popup, so no
# network name is ever put on a command line by hand. If macOS wants a password, an
# osascript dialog with hidden answer asks for it once; the password goes straight to
# networksetup and is never logged or stored. --dry-run (or WIFI_DRY_RUN=1) only says
# what it would do: no join, no dialog.

export PATH="/usr/local/bin:$PATH"
set +x   # the password must not appear in a trace

KIND=$1 N=$2
DRY=0
{ [ "$3" = "--dry-run" ] || [ -n "$WIFI_DRY_RUN" ]; } && DRY=1
LIST="${TMPDIR:-/tmp}/sketchybar_wifi_$KIND"

case $KIND in saved|near|advice) ;; *) echo "usage: wifi_join.sh <saved|near|advice> <row> [--dry-run]" >&2; exit 2 ;; esac
case $N in ''|*[!0-9]*) echo "bad row: $N" >&2; exit 2 ;; esac

SSID=$(sed -n "${N}p" "$LIST" 2>/dev/null)
[ -n "$SSID" ] || { echo "no network in $KIND row $N" >&2; exit 1; }

CURRENT=$(ipconfig getsummary en0 2>/dev/null | awk -F ' SSID : ' '/ SSID : /{print $2; exit}')

notify() { # notify <message>; the network name is passed as an argument, not spliced into the script
  osascript - "$1" "$SSID" >/dev/null 2>&1 <<'OSA'
on run argv
  display notification (item 1 of argv) with title "Wi-Fi" subtitle (item 2 of argv)
end run
OSA
}

ask_password() {
  osascript - "$SSID" 2>/dev/null <<'OSA'
on run argv
  tell current application to activate
  set r to display dialog ("Password for the Wi-Fi network " & quote & (item 1 of argv) & quote & ":") with title "Join Wi-Fi" default answer "" with hidden answer buttons {"Cancel", "Join"} default button "Join" with icon note giving up after 120
  if gave up of r then error number -128
  return text returned of r
end run
OSA
}

join() { # join [password]
  if [ -n "$1" ]; then networksetup -setairportnetwork en0 "$SSID" "$1" 2>&1
  else networksetup -setairportnetwork en0 "$SSID" 2>&1; fi
}

if [ "$DRY" = 1 ]; then
  echo "dry run: would run: networksetup -setairportnetwork en0 \"$SSID\""
  [ "$SSID" = "$CURRENT" ] && echo "dry run: already connected to it, so it would do nothing"
  echo "dry run: if that fails, it would ask for a password in a hidden-answer dialog and retry once"
  exit 0
fi

sketchybar --set wifi popup.drawing=off
[ "$SSID" = "$CURRENT" ] && exit 0   # already on it

# networksetup prints nothing on success and a message on failure.
OUT=$(join)
if [ -n "$OUT" ]; then
  case $OUT in
    *"Could not find network"*) notify "Out of range or not found" ;;
    *)
      PW=$(ask_password)
      if [ -n "$PW" ]; then
        OUT=$(join "$PW")
        [ -n "$OUT" ] && notify "Could not join. Check the password."
      fi
      PW="" ;;
  esac
fi
unset PW OUT
sketchybar --trigger wifi_change
( sleep 4; sketchybar --trigger wifi_change ) >/dev/null 2>&1 &
