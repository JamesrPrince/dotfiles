#!/bin/bash
# Snappier macOS: faster key repeat, SHORTER (not disabled) animations. Reversible.
#   snappy.sh apply    save current values to ~/.local/state/snappy/before.tsv (first time only), then set targets
#   snappy.sh revert   restore the saved values exactly (keys that were unset are deleted)
#   snappy.sh status   key, current, target, OK/DIFF per line; exit 1 on any DIFF
# Never runs killall: the Dock line it prints is for you to run.
set -u
STATE="$HOME/.local/state/snappy"
BEFORE="$STATE/before.tsv"

# domain  key  type  target
KEYS='NSGlobalDomain	KeyRepeat	int	2
NSGlobalDomain	InitialKeyRepeat	int	15
NSGlobalDomain	ApplePressAndHoldEnabled	bool	false
NSGlobalDomain	NSWindowResizeTime	float	0.08
NSGlobalDomain	QLPanelAnimationDuration	float	0.08
com.apple.dock	autohide-delay	float	0
com.apple.dock	autohide-time-modifier	float	0.2
com.apple.dock	expose-animation-duration	float	0.12
com.apple.dock	springboard-show-duration	float	0.12
com.apple.dock	springboard-hide-duration	float	0.12
com.apple.dock	mru-spaces	bool	false'

TAB=$(printf '\t')

current() { # current <domain> <key>  -> value or "unset"
  defaults read "$1" "$2" 2>/dev/null || echo unset
}
norm() { # norm <type> <value>: bool true/false -> 1/0
  case "$2" in true|YES) echo 1 ;; false|NO) echo 0 ;; *) echo "$2" ;; esac
}
same() { # same <a> <b>: numeric compare when both numeric
  [ "$1" = "$2" ] && return 0
  awk -v a="$1" -v b="$2" 'BEGIN{ if (a+0==a && b+0==b && a+0==b+0) exit 0; exit 1 }' 2>/dev/null
}
setkey() { # setkey <domain> <key> <type> <value>
  case "$3" in
    bool) case "$4" in 1|true) v=true ;; *) v=false ;; esac; defaults write "$1" "$2" -bool "$v" ;;
    *) defaults write "$1" "$2" "-$3" "$4" ;;
  esac
}
notes() {
  echo "Run this for the Dock keys to take effect:  killall Dock"
  echo "Key repeat settings apply after logout/login."
}

cmd=${1:-}
case "$cmd" in
  apply)
    mkdir -p "$STATE"
    if [ ! -f "$BEFORE" ]; then
      tmp="$BEFORE.tmp"; : > "$tmp"
      while IFS="$TAB" read -r d k t v; do
        printf '%s\t%s\t%s\t%s\n' "$d" "$k" "$t" "$(current "$d" "$k")" >> "$tmp"
      done <<EOK
$KEYS
EOK
      mv "$tmp" "$BEFORE"
      echo "saved current state to ~/.local/state/snappy/before.tsv"
    else
      echo "before.tsv exists, keeping it"
    fi
    while IFS="$TAB" read -r d k t v; do setkey "$d" "$k" "$t" "$v"; done <<EOK
$KEYS
EOK
    echo "applied"; notes ;;
  revert)
    [ -f "$BEFORE" ] || { echo "no before.tsv: nothing to revert" >&2; exit 1; }
    while IFS="$TAB" read -r d k t v; do
      if [ "$v" = unset ]; then defaults delete "$d" "$k" 2>/dev/null || true
      else setkey "$d" "$k" "$t" "$v"; fi
    done < "$BEFORE"
    rm -f "$BEFORE"
    echo "reverted"; notes ;;
  status)
    rc=0
    while IFS="$TAB" read -r d k t v; do
      cur=$(current "$d" "$k")
      if [ "$cur" != unset ] && same "$(norm "$t" "$cur")" "$(norm "$t" "$v")"; then s=OK; else s=DIFF; rc=1; fi
      printf '%s\t%s\t%s\t%s\n' "$k" "$cur" "$v" "$s"
    done <<EOK
$KEYS
EOK
    exit $rc ;;
  *) echo "usage: snappy.sh apply|revert|status" >&2; exit 2 ;;
esac
