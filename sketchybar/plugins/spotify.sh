#!/bin/bash

export PATH="/usr/local/bin:$PATH"
source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/plugins/style.sh"
[ "$BAR_STYLE" = flat ] && source "$HOME/.config/sketchybar/plugins/smart_lib.sh"

next ()
{
  osascript -e 'tell application "Spotify" to play next track'
}

back () 
{
  osascript -e 'tell application "Spotify" to play previous track'
}

play () 
{
  osascript -e 'tell application "Spotify" to playpause'
}

repeat () 
{
  REPEAT=$(osascript -e 'tell application "Spotify" to get repeating')
  if [ "$REPEAT" = "false" ]; then
    sketchybar -m --set spotify.repeat icon.highlight=on
    osascript -e 'tell application "Spotify" to set repeating to true'
  else 
    sketchybar -m --set spotify.repeat icon.highlight=off
    osascript -e 'tell application "Spotify" to set repeating to false'
  fi
}

shuffle () 
{
  SHUFFLE=$(osascript -e 'tell application "Spotify" to get shuffling')
  if [ "$SHUFFLE" = "false" ]; then
    sketchybar -m --set spotify.shuffle icon.highlight=on
    osascript -e 'tell application "Spotify" to set shuffling to true'
  else 
    sketchybar -m --set spotify.shuffle icon.highlight=off
    osascript -e 'tell application "Spotify" to set shuffling to false'
  fi
}

update ()
{
  PLAYING=1
  if [ "$(echo "$INFO" | jq -r '.["Player State"]')" = "Playing" ]; then
    PLAYING=0
    TRACK="$(echo "$INFO" | jq -r .Name | sed 's/\(.\{20\}\).*/\1.../')"
    ARTIST="$(echo "$INFO" | jq -r .Artist | sed 's/\(.\{20\}\).*/\1.../')"
    ALBUM="$(echo "$INFO" | jq -r .Album | sed 's/\(.\{25\}\).*/\1.../')"
    SHUFFLE=$(osascript -e 'tell application "Spotify" to get shuffling')
    REPEAT=$(osascript -e 'tell application "Spotify" to get repeating')
    COVER=$(osascript -e 'tell application "Spotify" to get artwork url of current track')
    NOW_PLAYING="$(echo "$INFO" | jq -r '.Name + (if (.Artist // "") != "" then "  ·  " + .Artist else "" end)' \
                   | sed 's/\(.\{28\}\).*/\1…/')"
    TITLE_FULL="$(echo "$INFO" | jq -r .Name)"
  fi

  args=()
  if [ $PLAYING -eq 0 ]; then
    curl -s --max-time 20 "$COVER" -o /tmp/cover.jpg
    if [ "$ARTIST" == "" ]; then
      args+=(--set spotify.title label="$TRACK"
             --set spotify.album label="Podcast"
             --set spotify.artist label="$ALBUM"  )
    else
      args+=(--set spotify.title label="$TRACK"
             --set spotify.album label="$ALBUM"
             --set spotify.artist label="$ARTIST")
    fi
    args+=(--set spotify.play icon=$SPOTIFY_PAUSE
           --set spotify.shuffle icon.highlight=$SHUFFLE
           --set spotify.repeat icon.highlight=$REPEAT
           --set spotify.cover background.image="/tmp/cover.jpg"
                               background.color=0x00000000
           )
    [ "$BAR_STYLE" = flat ] || args+=(--set spotify.anchor drawing=on label="$NOW_PLAYING"
                                      --set spotify.progress drawing=on)
  else
    args+=(--set spotify.anchor popup.drawing=off
           --set spotify.play icon=$SPOTIFY_PLAY                         )
    [ "$BAR_STYLE" = flat ] || args+=(--set spotify.anchor drawing=off --set spotify.progress drawing=off)
  fi
  sketchybar -m "${args[@]}"
  # The flat bar: a compact music item (icon and title), only while playing. spotify.progress stays off
  # (it would ask Spotify for its position every 2 s).
  if [ "$BAR_STYLE" = flat ]; then
    if [ $PLAYING -eq 0 ]; then printf 'on|%s\n' "$TITLE_FULL" > "$SMART_DIR/real.music"
    else rm -f "$SMART_DIR/real.music"; fi
    flat_music
  fi
}

# Flat: draw the music item from the last real state (or the demo's sample)
flat_music() {
  local t=""
  if smart_demo music; then t="Midnight City (Extended Mix)"
  elif [ -r "$SMART_DIR/real.music" ]; then IFS='|' read -r _ t < "$SMART_DIR/real.music"; fi
  if [ -n "$t" ]; then
    [ "${#t}" -gt "$FLAT_MUSIC_CHARS" ] && t="${t:0:$((FLAT_MUSIC_CHARS - 1))}…"
    SM_ICON=$SPOTIFY; SM_LABEL=$t; smart_show spotify.anchor
  else
    smart_hide spotify.anchor
  fi
}

scrubbing() {
  DURATION_MS=$(osascript -e 'tell application "Spotify" to get duration of current track')
  DURATION=$((DURATION_MS/1000))

  TARGET=$((DURATION*PERCENTAGE/100))
  osascript -e "tell application \"Spotify\" to set player position to $TARGET"
  sketchybar --set spotify.state slider.percentage=$PERCENTAGE
}

scroll() {
  pgrep -xq Spotify || exit 0   # never asks Spotify (which would launch it) unless it runs
  DURATION_MS=$(osascript -e 'tell application "Spotify" to get duration of current track')
  DURATION=$((DURATION_MS/1000))
  [ "$DURATION" -gt 0 ] 2>/dev/null || exit 0

  FLOAT="$(osascript -e 'tell application "Spotify" to get player position')"
  TIME=${FLOAT%.*}
  
  sketchybar --animate linear 10 \
             --set spotify.state slider.percentage="$((TIME*100/DURATION))" \
                                 icon="$(date -r $TIME +'%M:%S')" \
                                 label="$(date -r $DURATION +'%M:%S')"
}

mouse_clicked () {
  case "$NAME" in
    "spotify.next") next
    ;;
    "spotify.back") back
    ;;
    "spotify.play") play
    ;;
    "spotify.shuffle") shuffle
    ;;
    "spotify.repeat") repeat
    ;;
    "spotify.state") scrubbing
    ;;
    *) exit
    ;;
  esac
}

popup () {
  "$HOME/.config/sketchybar/plugins/popup.sh" spotify.anchor $1
}

# Hover opens the popup; a click on the anchor closes it and keeps it shut for
# a moment, or the pointer still resting on the anchor would reopen it at once.
HUSH="${TMPDIR:-/tmp}/sketchybar_spotify_hush"
hushed() {
  [ -f "$HUSH" ] && [ $(( $(date +%s) - $(stat -f %m "$HUSH") )) -le 1 ]
}
click_anchor() {
  if [ "$(sketchybar --query spotify.anchor | jq -r '.popup.drawing')" = "on" ]; then
    touch "$HUSH"; popup off
  else
    rm -f "$HUSH"; popup on
  fi
}

# Bar progress line; never asks Spotify (which would launch it) unless it runs
progress() {
  pgrep -xq Spotify || exit 0
  read -r POS DUR <<< "$(osascript -e 'tell application "Spotify" to return ((player position as integer) as text) & " " & (((duration of current track) / 1000 as integer) as text)' 2>/dev/null)"
  [ "${DUR:-0}" -gt 0 ] 2>/dev/null || exit 0
  sketchybar --animate linear 20 --set spotify.progress slider.percentage=$(( POS * 100 / DUR ))
}

routine() {
  case "$NAME" in
    "spotify.progress") progress
    ;;
    "spotify.state") scroll
    ;;
    *) update
    ;;
  esac
}

[ "$1" = "click" ] && { click_anchor; exit 0; }

# Flat, at load: if Spotify is already playing, build the event's info from it (never starts Spotify)
if [ "$1" = "initflat" ]; then
  pgrep -xq Spotify || exit 0
  INFO=$(osascript -e 'tell application "Spotify" to return (player state as text) & (ASCII character 9) & (name of current track) & (ASCII character 9) & (artist of current track) & (ASCII character 9) & (album of current track)' 2>/dev/null \
         | jq -R 'split("\t") | {"Player State": (.[0] | if . == "playing" then "Playing" else . end), Name: .[1], Artist: .[2], Album: .[3]}')
  [ -n "$INFO" ] && update
  exit 0
fi

case "$SENDER" in
  "mouse.clicked") mouse_clicked
  ;;
  "mouse.entered") hushed || popup on
  ;;
  "mouse.exited"|"mouse.exited.global") popup off
  ;;
  "routine") routine
  ;;
  "forced") exit 0
  ;;
  # Spotify's own event (track, play/pause, seek): the position items resync, the rest redraws
  "spotify_change") case "$NAME" in
      "spotify.progress") progress ;;
      "spotify.state") scroll ;;
      *) update ;;
    esac
  ;;
  "smart_refresh") flat_music
  ;;
  *) update
  ;;
esac
