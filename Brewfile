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
# delta (git pager, git/delta.gitconfig): NOT from brew on Intel macOS 15, which compiles Rust from source.
#   Use the last Intel release: gh release download 0.18.2 -R dandavison/delta -p "*x86_64-apple-darwin*"
#   then install -m 755 delta /usr/local/bin/. On Apple Silicon: brew "git-delta".
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

# keys and tools
cask "maccy"                   # clipboard history, opened by Alt+Ctrl+V
cask "handy"                   # local push-to-talk dictation (Right Option); pick a small model in its Settings

# om menu
# fzf is the picker (already above). Night shift row appears once this is installed:
tap "smudge/smudge"
brew "smudge/smudge/nightlight"

# theme reach (theme.sh font: the ruled list, Nerd Font builds)
cask "font-jetbrains-mono-nerd-font"
cask "font-caskaydia-mono-nerd-font"
cask "font-fira-code-nerd-font"
cask "font-meslo-lg-nerd-font"

# shell layer: Omarchy terminal habits (zsh/omarchy.zsh, tmux/tmux.conf)
brew "tmux"
brew "tlrc"                    # tldr pages client; run `tldr --update` once
brew "fd"                      # fzf file and directory lists
brew "eza"
brew "zoxide"
