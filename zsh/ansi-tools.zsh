# Sourced from ~/.zshrc. Makes fzf use the terminal's 16 ANSI colours, so it follows
# the theme switch (theme.sh) with no per-theme file. bat, btop, lazygit, yazi and
# Starship do the same through their own configs.
export FZF_DEFAULT_OPTS="--color=16 ${FZF_DEFAULT_OPTS:-}"
