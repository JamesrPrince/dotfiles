# Omarchy 4.5 shell layer for zsh (github.com/omacom/omarchy, branch quattro:
# default/bash/{aliases,envs,fns/*}). Sourced from lean.zsh.
# Rule: on a name clash James's own definition wins. Every clash is recorded in
# _OZ_CLASHES; run `omarchy-clashes` to list them. Linux-only parts are skipped
# or adapted; the list is in `omarchy-skipped`.
# No external command runs at start: fzf keys come from a zcompiled cache.

typeset -ga _OZ_CLASHES=()

# _oz_free <name>: 0 when nothing of James's owns the name, else record the clash.
_oz_free() {
  if (( $+aliases[$1] || $+functions[$1] )); then _OZ_CLASHES+=$1; return 1; fi
  return 0
}
# _oz_alias <name> <definition>
_oz_alias() { _oz_free "$1" && alias -- "$1=$2"; }
# _oz_has <cmd>: on PATH? (whence -p avoids building the whole command hash table)
_oz_has() { whence -p "$1" >/dev/null; }

# ---- environment (only when unset) -----------------------------------------
: ${EDITOR:=nvim}
export EDITOR
export BAT_THEME="${BAT_THEME:-ansi}"
# Colour man pages with bat (BSD col on macOS takes the same flags)
if _oz_has bat && [[ -z $MANPAGER ]]; then
  export MANROFFOPT="-c"
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

# ---- file system -----------------------------------------------------------
if _oz_has eza; then
  _oz_alias ls  'eza -lh --group-directories-first --icons=auto'
  _oz_alias lsa 'ls -a'
  _oz_alias lt  'eza --tree --level=2 --long --icons --git'
  _oz_alias lta 'lt -a'
fi
# Directories
_oz_alias ..   'cd ..'
_oz_alias ...  'cd ../..'
_oz_alias .... 'cd ../../..'

# Fuzzy finder with a bat preview; eff opens the pick in $EDITOR
_oz_alias ff "fzf --preview 'bat --style=numbers --color=always {}'"
unalias eff 2>/dev/null
function eff { local file; file=$(ff) && [[ -n $file ]] && $EDITOR "$file" "$@"; }
# sff: pick a recent file, scp it. Omarchy used GNU find -printf; BSD stat here.
function sff {
  if (( $# == 0 )); then echo "Usage: sff <destination> (e.g. sff host:/tmp/)"; return 1; fi
  local file
  file=$(find . -type f -exec stat -f '%m	%N' {} + | sort -rn | cut -f2- | ff) && [[ -n $file ]] && scp "$file" "$1"
}

# cd that jumps with zoxide when the argument is not a directory
if _oz_has zoxide && _oz_free zd; then
  function zd {
    if (( $# == 0 )); then
      builtin cd ~ || return
    elif [[ $1 == -* && $1 != - ]]; then
      builtin cd "$@" || return
    elif [[ -d $1 ]]; then
      builtin cd "$1" || return
    else
      if ! z "$@"; then echo "Error: Directory not found"; return 1; fi
      printf '\U000F17A9 '; pwd
    fi
  }
  _oz_alias cd zd
fi

# ---- tools -----------------------------------------------------------------
_oz_alias c   'opencode --auto'
_oz_alias cx  'printf "\033[2J\033[3J\033[H" && claude --permission-mode auto'
_oz_alias cy  'codex --approve-for-me'
_oz_alias d   'docker'
_oz_alias t   'tmux attach || tmux new -s Work'
_oz_alias ic  'tdl c'
_oz_alias ix  'tdl cx'
_oz_alias icx 'tdl c cx'
_oz_has mise && _oz_alias mup 'MISE_MINIMUM_RELEASE_AGE=0 mise up'
_oz_free n && function n { if (( $# == 0 )); then command nvim .; else command nvim "$@"; fi; }

# Git
_oz_alias g    'git'
_oz_alias gcm  'git commit -m'
_oz_alias gcam 'git commit -a -m'
_oz_alias gcad 'git commit -a --amend'

# ---- functions: compression, worktrees, ssh --------------------------------
_oz_free compress && function compress { tar -czf "${1%/}.tar.gz" "${1%/}"; }
_oz_alias decompress 'tar -xzf'

# New worktree and branch beside the current repo
_oz_free ga && function ga {
  if [[ -z $1 ]]; then echo "Usage: ga [branch name]"; return 1; fi
  local branch="$1" base="${PWD:t}"
  local wt_path="../${base}--${branch}"
  git worktree add -b "$branch" "$wt_path" || return
  _oz_has mise && mise trust "$wt_path"
  cd "$wt_path"
}
# Remove the current worktree and its branch (asks with gum, else plain y/N)
_oz_free gd && function gd {
  local ok=0
  if _oz_has gum; then gum confirm "Remove worktree and branch?" && ok=1
  else local a; read -q "a?Remove worktree and branch? (y/N) " && ok=1; echo; fi
  (( ok )) || return 0
  local cwd="$PWD" worktree="${PWD:t}" root branch
  root="${worktree%%--*}"
  branch="${worktree#*--}"
  # Protect against nuking a non-worktree directory
  if [[ $root != $worktree ]]; then
    cd "../$root" || return
    # no --force and -d, not -D (Omarchy forces both): git refuses a dirty tree or an unmerged branch
    git worktree remove "$cwd" || { cd "$cwd"; return 1; }
    git branch -d "$branch"
  fi
}

# SSH port forwarding (pgrep -fl on macOS, not GNU -af)
function fip {
  (( $# < 2 )) && echo "Usage: fip <host> <port1> [port2] ..." && return 1
  local host="$1" port; shift
  for port in "$@"; do
    ssh -f -N -L "${port}:localhost:${port}" "$host" && echo "Forwarding localhost:$port -> $host:$port"
  done
}
function dip {
  (( $# == 0 )) && echo "Usage: dip <port1> [port2] ..." && return 1
  local port
  for port in "$@"; do
    pkill -f "ssh.*-L ${port}:localhost:${port}" && echo "Stopped forwarding port $port" || echo "No forwarding on port $port"
  done
}
function lip { pgrep -fl "ssh.*-L [0-9]+:localhost:[0-9]+" || echo "No active forwards"; }

# ssh wrapper: disarm mouse/alt-screen modes after a dropped link and reconnect.
# (zsh: `argv` is special, so the copy is named `args`.)
_oz_free ssh && function ssh {
  local rc started
  started=$SECONDS
  command ssh "$@"
  rc=$?
  [[ -t 1 ]] || return $rc
  _ssh_disarm
  if (( rc != 255 )) || [[ ! -t 0 ]] || ! _ssh_interactive "$@" || (( SECONDS - started < 30 )); then
    return $rc
  fi
  (
    while true; do
      echo "Connection lost. Reconnecting (Ctrl-C to stop)..."
      sleep 2
      command ssh "$@"
      rc=$?
      _ssh_disarm
      (( rc != 255 )) && exit $rc
    done
  )
}
function _ssh_disarm { printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?1004l\e[?1049l\e[?25h'; }
function _ssh_interactive {
  local value_opts="BbcDEeFIiJLlmOoPpQRSWw"
  local -a args=("$@")
  local arg letters i dest="" opts_done=""
  while (( $# )); do
    arg="$1"; shift
    if [[ -z $opts_done && $arg == "--" ]]; then
      opts_done=1
    elif [[ -z $opts_done && $arg == -?* ]]; then
      letters="${arg#-}"
      for (( i = 0; i < ${#letters}; i++ )); do
        if [[ $value_opts == *"${letters:$i:1}"* ]]; then
          (( i == ${#letters} - 1 )) && shift
          break
        fi
      done
    elif [[ -z $dest ]]; then
      dest="$arg"
    else
      return 1
    fi
  done
  [[ -n $dest ]] || return 1
  local resolved
  resolved=$(command ssh -G "${args[@]}" 2>/dev/null) || return 1
  ! grep -i '^remotecommand ' <<<"$resolved" | grep -qvi '^remotecommand none$'
}

# ---- tmux layouts (tdl, tds, tdlm, tsl) ------------------------------------
# Same as Omarchy except: -l N% instead of the deprecated -p N, zsh 1-based
# arrays, and tdl focuses the editor pane (upstream names an unset variable).

# tdl <c|cx|codex|other_ai> [<second_ai>]: editor, AI pane, terminal
function tdl {
  [[ -z $1 ]] && { echo "Usage: tdl <c|cx|codex|other_ai> [<second_ai>]"; return 1; }
  [[ -z $TMUX ]] && { echo "You must start tmux to use tdl."; return 1; }
  local current_dir="$PWD" ai="$1" ai2="$2"
  local editor_pane="$TMUX_PANE" ai_pane ai2_pane
  tmux rename-window -t "$editor_pane" "${current_dir:t}"
  tmux split-window -v -l 15% -t "$editor_pane" -c "$current_dir"
  ai_pane=$(tmux split-window -h -l 30% -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}')
  if [[ -n $ai2 ]]; then
    ai2_pane=$(tmux split-window -v -t "$ai_pane" -c "$current_dir" -P -F '#{pane_id}')
    tmux send-keys -t "$ai2_pane" "$ai2" C-m
  fi
  tmux send-keys -t "$ai_pane" "$ai" C-m
  tmux send-keys -t "$editor_pane" "$EDITOR ." C-m
  tmux select-pane -t "$editor_pane"
}

# tds: editor, diff watch, terminal, opencode in a square
function tds {
  [[ -n $1 ]] && { echo "Usage: tds"; return 1; }
  [[ -z $TMUX ]] && { echo "You must start tmux to use tds."; return 1; }
  local current_dir="$PWD" editor_pane="$TMUX_PANE" diff_pane terminal_pane opencode_pane
  tmux rename-window -t "$editor_pane" "${current_dir:t}"
  terminal_pane=$(tmux split-window -v -l 50% -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}')
  diff_pane=$(tmux split-window -h -l 50% -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}')
  opencode_pane=$(tmux split-window -h -l 50% -t "$terminal_pane" -c "$current_dir" -P -F '#{pane_id}')
  tmux send-keys -t "$editor_pane" -l "nvim ."
  tmux send-keys -t "$editor_pane" C-m
  tmux send-keys -t "$diff_pane" -l "hunk diff --watch"
  tmux send-keys -t "$diff_pane" C-m
  tmux send-keys -t "$opencode_pane" -l "opencode"
  tmux send-keys -t "$opencode_pane" C-m
  tmux select-pane -t "$editor_pane"
}

# tdlm <c|cx|codex|other_ai> [<second_ai>]: one tdl window per subdirectory
function tdlm {
  [[ -z $1 ]] && { echo "Usage: tdlm <c|cx|codex|other_ai> [<second_ai>]"; return 1; }
  [[ -z $TMUX ]] && { echo "You must start tmux to use tdlm."; return 1; }
  local ai="$1" ai2="${2:-}" base_dir="$PWD" first=true tdl_command dir dirpath pane_id
  tmux rename-session "$(print -r -- "${base_dir:t}" | tr '.:' '--')"
  for dir in "$base_dir"/*/(N); do
    [[ -d $dir ]] || continue
    dirpath="${dir%/}"
    printf -v tdl_command 'tdl %q' "$ai"
    [[ -n $ai2 ]] && printf -v tdl_command '%s %q' "$tdl_command" "$ai2"
    if [[ $first == true ]]; then
      printf -v tdl_command 'cd %q && %s' "$dirpath" "$tdl_command"
      tmux send-keys -t "$TMUX_PANE" "$tdl_command" C-m
      first=false
    else
      pane_id=$(tmux new-window -c "$dirpath" -P -F '#{pane_id}')
      tmux send-keys -t "$pane_id" "$tdl_command" C-m
    fi
  done
}

# tsl <pane_count> <command>: tiled swarm, same command in every pane
function tsl {
  [[ ! $1 =~ ^[1-9][0-9]*$ || -z $2 ]] && { echo "Usage: tsl <pane_count> <command>"; return 1; }
  [[ -z $TMUX ]] && { echo "You must start tmux to use tsl."; return 1; }
  local count="$1" cmd current_dir="$PWD" new_pane pane
  local -a panes
  shift
  if (( $# == 1 )); then cmd="$1"; else printf -v cmd '%q ' "$@"; cmd="${cmd% }"; fi
  tmux rename-window -t "$TMUX_PANE" "${current_dir:t}"
  panes=("$TMUX_PANE")
  while (( ${#panes} < count )); do
    new_pane=$(tmux split-window -h -t "${panes[-1]}" -c "$current_dir" -P -F '#{pane_id}')
    panes+=("$new_pane")
    tmux select-layout -t "${panes[1]}" tiled
  done
  for pane in "${panes[@]}"; do tmux send-keys -t "$pane" "$cmd" C-m; done
  tmux select-pane -t "${panes[1]}"
}

# ---- fzf: Ctrl+R history, Ctrl+T files, Alt+C cd, with fd/bat previews -----
# Key bindings only (no ** completion: it rewraps completions at every start).
if _oz_has fzf && [[ -t 0 ]]; then   # key bindings need a real line editor (not piped or `zsh -c` without a tty)
  if _oz_has fd; then
    export FZF_CTRL_T_COMMAND="fd --type f --hidden --follow --exclude .git"
    export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"
  fi
  export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range=:200 {}' --preview-window=right:55%:wrap"
  export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons --color=always {} 2>/dev/null || ls -la {}' --preview-window=right:55%"
  export FZF_CTRL_R_OPTS="--preview 'echo {2..}' --preview-window=down:3:wrap --bind='?:toggle-preview'"
  # Lazy: the keys are bound to stubs; the first press loads the real script, so start
  # pays nothing for it. The script is copied into ~/.cache/zsh and zcompiled.
  _oz_fzf_load() {
    local src="${HOMEBREW_PREFIX:-/usr/local}/opt/fzf/shell/key-bindings.zsh"
    [[ -r $src ]] || src="/opt/homebrew/opt/fzf/shell/key-bindings.zsh"
    local dst="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/fzf-keys.zsh"
    [[ -r $src ]] || return 1
    if [[ ! -s $dst || $src -nt $dst ]]; then
      mkdir -p "${dst:h}"; command cp "$src" "$dst" && zcompile "$dst" 2>/dev/null
    fi
    unfunction fzf-history-widget fzf-file-widget fzf-cd-widget 2>/dev/null
    source "$dst"
  }
  function fzf-history-widget { _oz_fzf_load && zle fzf-history-widget; }
  function fzf-file-widget    { _oz_fzf_load && zle fzf-file-widget; }
  function fzf-cd-widget      { _oz_fzf_load && zle fzf-cd-widget; }
  zle -N fzf-history-widget; zle -N fzf-file-widget; zle -N fzf-cd-widget
  bindkey -M emacs '^R' fzf-history-widget '^T' fzf-file-widget '\ec' fzf-cd-widget '\eC' fzf-cd-widget 'ç' fzf-cd-widget
  bindkey -M viins '^R' fzf-history-widget '^T' fzf-file-widget '\ec' fzf-cd-widget '\eC' fzf-cd-widget
fi

# ---- reports ---------------------------------------------------------------
function omarchy-clashes { print -l -- "Names James already defined (his definition wins):" ${(u)_OZ_CLASHES}; }
function omarchy-skipped {
  cat <<'EOF'
Skipped (Linux-only or tool absent): a (omarchy-agent), open (xdg-open; macOS has open),
r (shadows zsh's `r`), h/hdl/hds/hdlm/hsl (herdr), iso2sd and format-drive (lsblk/dd/parted),
rsw/lsw/dsw (inotifywait, setsid), kitty ff branch, bash-only shopt/inputrc/mise-activate lines.
EOF
}
