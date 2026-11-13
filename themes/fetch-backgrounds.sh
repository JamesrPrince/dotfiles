#!/bin/bash
# Downloads Omarchy's wallpapers into themes/backgrounds/<theme>/ (git-ignored;
# stills only, no intro videos). Safe to re-run. Osaka Jade lives in its own repo.
set -euo pipefail
DOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$DOT/themes/backgrounds"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

git clone --depth 1 -q https://github.com/basecamp/omarchy.git "$TMP/omarchy"
git clone --depth 1 -q https://github.com/omacom/omarchy-osaka-jade-theme.git "$TMP/osaka"

grab() { # grab <our id> <source backgrounds dir>
  mkdir -p "$DEST/$1"
  find "$2" -maxdepth 1 -type f \( -iname '*.webp' -o -iname '*.jpg' -o -iname '*.png' \) -exec cp -n {} "$DEST/$1/" \;
  echo "$1: $(ls "$DEST/$1" | wc -l | tr -d ' ') images"
}
for pair in tokyonight:tokyo-night catppuccin:catppuccin everforest:everforest gruvbox:gruvbox \
            kanagawa:kanagawa nord:nord rosepine:rose-pine matteblack:matte-black ristretto:ristretto; do
  grab "${pair%%:*}" "$TMP/omarchy/themes/${pair##*:}/backgrounds"
done
grab osakajade "$TMP/osaka/backgrounds"
# macchiato is not an Omarchy theme: it borrows Catppuccin's pictures (theme.sh maps it)
