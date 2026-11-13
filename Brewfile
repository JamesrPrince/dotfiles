# What this desktop needs: brew bundle --file ~/dotfiles/Brewfile
# (only the tools the dotfiles use, not everything on the Mac)
tap "felixkratz/formulae"
tap "nikitabobko/tap"

# Bar, windows, borders
brew "sketchybar"
brew "borders"
brew "jq"
brew "gh"                      # the bar's GitHub item (gh auth login)
cask "aerospace"
cask "ghostty"

# Terminal side
brew "starship"
brew "neovim"
brew "btop"
brew "bat"
brew "fzf"
brew "lazygit"
brew "lazydocker"
brew "yazi"

# Fonts
cask "font-sf-pro"
cask "font-nunito"
cask "font-maple-mono-nf"
cask "font-sketchybar-app-font"

# fastfetch is NOT here on purpose: on Intel Homebrew has no bottle and builds llvm and rust
# for hours. Install the release binary instead (updates are manual):
#   curl -L https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-macos-universal.tar.gz | tar xz
#   then copy the fastfetch binary from the extracted folder to /usr/local/bin/
# On Apple Silicon `brew install fastfetch` is fine.
