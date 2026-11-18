# Lean zsh: history, options, keys, one cached compinit, two brew plugins.
# Set fpath BEFORE sourcing this file (compinit runs once, here).

# History
HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
HISTSIZE=32768
SAVEHIST=32768
setopt share_history hist_ignore_dups hist_ignore_space

# Options
setopt auto_cd interactive_comments

# Keys (emacs)
bindkey -e
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[1;3C' forward-word
bindkey '^[[1;3D' backward-word
bindkey '^[b' backward-word
bindkey '^[f' forward-word
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[Z' reverse-menu-complete
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search

# Completion: one compinit, dump refreshed daily
_lean_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d $_lean_cache ]] || mkdir -p "$_lean_cache"
_lean_dump="$_lean_cache/zcompdump"
autoload -Uz compinit
_lean_fresh=($_lean_dump(N.mh-24))
if (( $#_lean_fresh )); then
  compinit -C -d "$_lean_dump"
else
  compinit -d "$_lean_dump"
fi
[[ -s $_lean_dump && ( ! -e $_lean_dump.zwc || $_lean_dump -nt $_lean_dump.zwc ) ]] && zcompile "$_lean_dump" 2>/dev/null
unset _lean_cache _lean_dump _lean_fresh
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select

# Plugins from Homebrew (syntax highlighting last)
_lean_share=("${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/share}" /usr/local/share /opt/homebrew/share)
for _p in zsh-autosuggestions zsh-syntax-highlighting; do
  for _d in $_lean_share; do
    [[ -n $_d && -r $_d/$_p/$_p.zsh ]] && { source "$_d/$_p/$_p.zsh"; break; }
  done
done
unset _lean_share _p _d
