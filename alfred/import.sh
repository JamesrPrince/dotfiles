#!/bin/bash
# One-time step for Alfred themes (James runs this in a terminal): opens the generated themes one at
# a time so Alfred shows its import sheet, then turns on live switching in theme.sh.
# Alfred imports themes only through that sheet, and can show only one sheet at a time, so the
# script waits for Enter between themes. Alfred must be running; this never restarts it.
#   import.sh            every theme
#   import.sh <id> ...   only these (e.g. import.sh nord gruvbox), to finish an interrupted run
DOT="$(cd "$(dirname "$0")" && pwd)"
python3 "$DOT/gen-themes.py" >/dev/null || exit 1

if [ $# -gt 0 ]; then
  files=(); for id in "$@"; do files+=("$DOT/themes/$id.alfredappearance"); done
else
  files=("$DOT"/themes/*.alfredappearance)
fi

n=0
for f in "${files[@]}"; do
  [ -f "$f" ] || { echo "no theme file: $f"; continue; }
  n=$((n + 1))
  name=$(basename "$f" .alfredappearance)
  printf '%d of %d: %s  (Enter to open, s then Enter to skip) ' "$n" "${#files[@]}" "$name"
  read -r answer
  [ "$answer" = s ] && continue
  open -a "Alfred 5" "$f"
  printf '   click Import in Alfred, then press Enter here '
  read -r _
done

touch "$HOME/.config/sketchybar/.alfred-themes"
echo "Done. The next theme switch asks once to let this app control Alfred: allow it."
