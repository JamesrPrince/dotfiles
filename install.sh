#!/bin/bash
# Links this repo's SketchyBar, AeroSpace and Ghostty config into place and builds the helpers.
# Anything already there is moved to a dated backup first, never deleted.
set -euo pipefail

need=(sketchybar aerospace jq borders python3 gh)
missing=(); for c in "${need[@]}"; do command -v "$c" >/dev/null || missing+=("$c"); done
if [ ${#missing[@]} -gt 0 ]; then
  echo "Missing: ${missing[*]}"
  echo "Install with:"
  echo "  brew tap FelixKratz/formulae && brew install sketchybar borders jq gh"
  echo "  brew install --cask nikitabobko/tap/aerospace font-sf-pro"
  echo "  curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/latest/download/sketchybar-app-font.ttf -o ~/Library/Fonts/sketchybar-app-font.ttf"
  exit 1
fi

DOT="$(cd "$(dirname "$0")" && pwd)"
STAMP=$(date +%Y%m%d-%H%M%S)

link() { # link <repo path> <target>
  local src="$DOT/$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then echo "ok      $dst"; return; fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then mv "$dst" "$dst.bak-$STAMP"; echo "backup  $dst.bak-$STAMP"; fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"; echo "linked  $dst -> $src"
}

# Configs call tools by full Homebrew path (/usr/local/bin on Intel).
# On Apple Silicon, point them at /opt/homebrew/bin instead.
PREFIX=$(brew --prefix 2>/dev/null || echo /usr/local)
if [ "$PREFIX" != "/usr/local" ]; then
  grep -rl "/usr/local/bin" "$DOT/sketchybar" "$DOT/aerospace" | while read -r f; do
    sed -i '' "s#/usr/local/bin#$PREFIX/bin#g" "$f"
  done
  echo "paths   /usr/local/bin -> $PREFIX/bin"
fi

link sketchybar "$HOME/.config/sketchybar"
link aerospace/aerospace.toml "$HOME/.aerospace.toml"
link ghostty "$HOME/.config/ghostty"

chmod +x "$DOT"/sketchybar/sketchybarrc "$DOT"/sketchybar/items/*.sh "$DOT"/sketchybar/plugins/*
"$DOT/sketchybar/helper/build.sh"

echo
echo "Done. Reload with: sketchybar --reload  (and aerospace reload-config)"
