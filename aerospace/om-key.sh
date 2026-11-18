#!/bin/bash
# om-key.sh [path...]  - run the Omarchy menu: `om`, or `om <path>` to jump into a submenu.
# AeroSpace's exec environment has a short PATH, so look for om on PATH, then in ~/dotfiles.
export PATH="$HOME/dotfiles/bin:$HOME/dotfiles:$HOME/.local/bin:/usr/local/bin:/opt/homebrew/bin:$PATH"
if [ "$1" = "--which" ]; then command -v om || exit 1; exit 0; fi
if ! OM=$(command -v om); then
  /usr/bin/osascript -e 'display notification "om not found on PATH or in ~/dotfiles" with title "Omarchy menu"' >/dev/null 2>&1
  exit 1
fi
exec "$OM" "$@"
