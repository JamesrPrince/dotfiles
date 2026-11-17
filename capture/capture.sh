#!/bin/bash
# Capture menu actions, after Omarchy's omarchy-capture-*. Called from the Alfred `om` menu.
#   capture.sh region | region-file | window | text | colour   (each takes --help)
# Confirmation goes to the bar: `sketchybar --trigger capture_done MSG=...` (no-op if the
# bar or the event is absent). Cancelling a pick (Esc) exits 0 silently.
# Screen Recording permission: macOS prompts on first screencapture for the app that runs this.
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR="${CAPTURE_DIR:-$HOME/Pictures/Screenshots}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/capture.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

usage() {
  cat <<'U'
usage: capture.sh <command>
  region        pick a region, PNG to the clipboard
  region-file   pick a region, save PNG as screenshot-YYYY-MM-DD_HH-MM-SS.png
                in $CAPTURE_DIR (default ~/Pictures/Screenshots)
  window        click a window, PNG to the clipboard
  text          pick a region, OCR it (Vision), text to the clipboard
  colour        click a pixel, #RRGGBB to the clipboard
Run `capture.sh <command> --help` for one command. Helpers: capture/build.sh.
U
}

help_for() {
  case "$1" in
    region)      echo "capture.sh region: interactive region (screencapture -i), PNG to the clipboard. Esc cancels." ;;
    region-file) echo "capture.sh region-file: interactive region, saved to \$CAPTURE_DIR (default ~/Pictures/Screenshots) as screenshot-<date>_<time>.png. Esc cancels." ;;
    window)      echo "capture.sh window: click a window (screencapture -iW), PNG to the clipboard. Esc cancels." ;;
    text)        echo "capture.sh text: pick a region, OCR with capture/ocr (Vision, accurate, auto language), text to the clipboard. Exit 1 if no text." ;;
    colour)      echo "capture.sh colour: NSColorSampler via capture/colour; #RRGGBB to the clipboard. Esc cancels." ;;
  esac
}

# Bar confirmation. Quote-safe: the message is one MSG= argument.
notify() {
  command -v sketchybar >/dev/null 2>&1 && sketchybar --trigger capture_done "MSG=$1" >/dev/null 2>&1
  return 0
}

# Interactive pick into $TMP/shot.png; returns 1 if cancelled (no file written).
pick() { /usr/sbin/screencapture -i "$@" -x "$TMP/shot.png" 2>/dev/null; [ -s "$TMP/shot.png" ]; }

png_to_clipboard() {
  /usr/bin/osascript -e 'on run a' -e 'set the clipboard to (read (POSIX file (item 1 of a)) as «class PNGf»)' -e 'end run' "$1" >/dev/null
}

need() { [ -x "$HERE/$1" ] || { echo "capture: $1 not built; run $HERE/build.sh" >&2; notify "Capture: run build.sh"; exit 1; }; }

cmd="${1:-}"
case "$cmd" in
  ""|-h|--help|help) usage; exit 0 ;;
  region|region-file|window|text|colour)
    case "${2:-}" in -h|--help) help_for "$cmd"; exit 0 ;; esac ;;
  *) echo "capture: unknown command '$cmd'" >&2; usage >&2; exit 2 ;;
esac

case "$cmd" in
  region)
    pick || exit 0
    png_to_clipboard "$TMP/shot.png" && notify "Region copied" ;;
  region-file)
    pick || exit 0
    mkdir -p "$DIR"
    out="$DIR/screenshot-$(date +%Y-%m-%d_%H-%M-%S).png"
    mv "$TMP/shot.png" "$out" && notify "Saved ${out/#$HOME/~}" ;;
  window)
    pick -W || exit 0
    png_to_clipboard "$TMP/shot.png" && notify "Window copied" ;;
  text)
    need ocr
    pick || exit 0
    if text=$("$HERE/ocr" "$TMP/shot.png"); then
      printf '%s' "$text" | /usr/bin/pbcopy && notify "Text copied"
    else
      notify "No text found"; exit 1
    fi ;;
  colour)
    need colour
    hex=$("$HERE/colour") || exit 0
    printf '%s' "$hex" | /usr/bin/pbcopy && notify "$hex copied" ;;
esac
