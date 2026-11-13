#!/bin/bash
# One-time step for Alfred themes (James runs this): opens each generated theme so Alfred shows its
# import sheet (click Import for each of the 11), then turns on live switching in theme.sh.
# Alfred imports themes only through that sheet. Alfred must be running; this never restarts it.
DOT="$(cd "$(dirname "$0")" && pwd)"
python3 "$DOT/gen-themes.py" >/dev/null || exit 1
for f in "$DOT"/themes/*.alfredappearance; do open -a "Alfred 5" "$f"; sleep 1; done
touch "$HOME/.config/sketchybar/.alfred-themes"
echo "Click Import on each of the 11 sheets. Then the next theme switch asks once to let this app control Alfred: allow it."
