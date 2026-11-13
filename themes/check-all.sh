#!/bin/bash
# Runs theme.sh set for every theme, validates Ghostty after each, then restores the theme
# that was active. Prints one line per theme; exits 1 if anything failed.
T="$HOME/.config/sketchybar/plugins/theme.sh"
G=/Applications/Ghostty.app/Contents/MacOS/ghostty
start=$(/bin/bash "$T" current); fail=0
for t in $(/bin/bash "$T" list --plain | cut -f1); do
  /bin/bash "$T" set "$t" >/dev/null 2>&1; s=$?
  sleep 1
  "$G" +validate-config >/dev/null 2>&1; g=$?
  nv=$(cmp -s "$HOME/dotfiles/themes/$t/neovim.lua" "$HOME/.config/nvim/lua/plugins/theme.lua" && echo ok || echo DIFF)
  echo "$t set=$s ghostty=$g nvim=$nv"
  [ "$s" = 0 ] && [ "$g" = 0 ] && [ "$nv" = ok ] || fail=1
done
/bin/bash "$T" set "$start"; r=$?
echo "restored $start rc=$r (now $(/bin/bash "$T" current))"
[ "$fail" = 0 ] && [ "$r" = 0 ]
