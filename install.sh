#!/bin/bash
# Links this repo's SketchyBar, AeroSpace, Ghostty, Starship, Neovim and CLI-tool config into place,
# builds the helpers and sets up the theme engine (wallpapers, wallpaper tool, first theme sync).
# SKIP_HELPERS=1 skips the helper build (a rebuild re-signs the apps and voids their permissions).
# Anything already there is moved to a dated backup first, never deleted.
set -euo pipefail

need=(sketchybar aerospace jq borders python3 gh)
missing=(); for c in "${need[@]}"; do command -v "$c" >/dev/null || missing+=("$c"); done
if [ ${#missing[@]} -gt 0 ]; then
  echo "Missing: ${missing[*]}"
  echo "Install with:"
  echo "  brew tap FelixKratz/formulae && brew install sketchybar borders jq gh"
  echo "  brew install --cask nikitabobko/tap/aerospace font-sf-pro"
  echo "Also wanted: brew install starship neovim fastfetch lazydocker btop bat fzf lazygit yazi"
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
link starship/starship.toml "$HOME/.config/starship.toml"
link nvim "$HOME/.config/nvim"                      # LazyVim; the colourscheme file is written by theme.sh
link fastfetch "$HOME/.config/fastfetch"
link btop/btop.conf "$HOME/.config/btop/btop.conf"  # TTY theme: follows the terminal colours
link bat/config "$HOME/.config/bat/config"          # ansi theme
link lazygit/config.yml "$HOME/Library/Application Support/lazygit/config.yml"
link zsh/ansi-tools.zsh "$HOME/.config/zsh/ansi-tools.zsh"   # fzf follows the terminal colours

# ~/.zshrc: Starship as the prompt (keep it last) and the fzf colours. Each added once; the file is backed up first.
if [ -f "$HOME/.zshrc" ]; then
  if ! grep -q 'ansi-tools.zsh' "$HOME/.zshrc" || ! grep -q 'starship init zsh' "$HOME/.zshrc"; then cp "$HOME/.zshrc" "$HOME/.zshrc.bak-$STAMP"; fi
  grep -q 'ansi-tools.zsh' "$HOME/.zshrc" || { echo '[ -f ~/.config/zsh/ansi-tools.zsh ] && source ~/.config/zsh/ansi-tools.zsh' >> "$HOME/.zshrc"; echo "zshrc   added fzf colours"; }
  grep -q 'starship init zsh' "$HOME/.zshrc" || { echo 'eval "$(starship init zsh)"' >> "$HOME/.zshrc"; echo "zshrc   added Starship (remove any other prompt theme yourself)"; }
fi

chmod +x "$DOT"/sketchybar/sketchybarrc "$DOT"/sketchybar/items/*.sh "$DOT"/sketchybar/plugins/* \
  "$DOT"/themes/*.sh "$DOT"/themes/*.py
if [ "${SKIP_HELPERS:-}" = 1 ]; then echo "helpers skipped (SKIP_HELPERS=1)"; else "$DOT/sketchybar/helper/build.sh"; fi

# Alfred "om" menu (keyword om): copied, not linked, into Alfred's workflows folder. Alfred picks it up without a restart.
AW="$HOME/Library/Application Support/Alfred/Alfred.alfredpreferences/workflows"
if [ -d "$AW" ]; then
  mkdir -p "$AW/user.workflow.om-menu" && cp -R "$DOT/alfred/om-workflow/." "$AW/user.workflow.om-menu/" && echo "alfred  om workflow installed"
else echo "alfred  not found, skipped the om workflow"; fi

# Theme engine: wallpapers (git-ignored), the wallpaper tool, then sync every themed part to the active theme.
[ -d "$DOT/themes/backgrounds" ] || "$DOT/themes/fetch-backgrounds.sh" || echo "wallpapers: fetch failed, run themes/fetch-backgrounds.sh later"
[ -x "$DOT/themes/setwall" ] || swiftc -O "$DOT/themes/setwall.swift" -o "$DOT/themes/setwall" || echo "setwall: needs swiftc (xcode-select --install)"
/bin/bash "$DOT/sketchybar/plugins/theme.sh" set "$(/bin/bash "$DOT/sketchybar/plugins/theme.sh" current)" || true

echo
echo "Done. Reload with: sketchybar --reload  (and aerospace reload-config)"
