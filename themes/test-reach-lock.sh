#!/bin/bash
# Real test of reach.sh: (1) a stuck holder with a child and a grandchild is replaced and no member of its
# tree survives; (2) two applies in quick succession leave last.log as one complete run. Runs in a scratch HOME
# with a stub reach.py, so it touches nothing real. Prints PASS/FAIL lines; exit 0 only if all pass.
DOT="$(cd -P "$(dirname "$0")/.." && pwd -P)"
T=$(mktemp -d); mine=""   # $mine: PIDs this test started and may kill; nothing else is ever signalled
trap 'for p in $mine; do kill $p 2>/dev/null; done; rm -rf "$T"' EXIT
mkdir -p "$T/home/.config/sketchybar" "$T/dot/themes" "$T/holder"
echo 'THEME=nord' > "$T/home/.config/sketchybar/colors.sh"
cp "$DOT/themes/reach.sh" "$T/dot/themes/reach.sh"
printf 'import sys,time\nfor t in "ghostty wall vscode claude tmux delta macos".split():\n    print("%%-8s ok" %% t, flush=True); time.sleep(0.2)\n' > "$T/dot/themes/reach.py"
fail=0; ok() { echo "PASS $1"; }; bad() { echo "FAIL $1"; fail=1; }
# stuck holder: a "reach.sh" (so the PID check sees a live run) -> sh child -> sleep grandchild (stands for code --install-extension)
cat > "$T/holder/reach.sh" <<'H'
#!/bin/bash
sh -c 'sleep 7351 & wait' &
wait
H
mkdir -p "$T/home/.config/theme-reach/lock"
bash "$T/holder/reach.sh" & hp=$!; mine="$mine $hp"
echo $hp > "$T/home/.config/theme-reach/lock/pid"
sleep 1
gc=$(pgrep -P "$(pgrep -P $hp | head -1)")   # grandchild: the sleep under the holder's sh child
mine="$mine $gc"
[ -n "$gc" ] && ok "setup: grandchild $gc runs under holder $hp" || bad "setup: no grandchild"
HOME="$T/home" THEME_REACH_LOCK_MAX=2 bash "$T/dot/themes/reach.sh" apply >/dev/null 2>&1
sleep 0.5
alive=""; for p in $hp $gc; do kill -0 $p 2>/dev/null && alive="$alive $p"; done
[ -z "$alive" ] && ok "stuck holder replaced: holder and grandchild both gone" || { bad "survivors:$alive"; kill $alive 2>/dev/null; }
grep -q "stopped stuck run $hp" "$T/home/.config/theme-reach/last.err" 2>/dev/null && ok "replaced holder is recorded in last.err" || bad "replacement not in last.err"
# rapid switches: two applies at once -> last.log is one complete run
rm -f "$T/home/.config/theme-reach/last.log"
for i in 1 2; do HOME="$T/home" bash "$T/dot/themes/reach.sh" apply >/dev/null 2>&1 & done; wait
l="$T/home/.config/theme-reach/last.log"
[ "$(wc -l <"$l" | tr -d ' ')" = 7 ] && [ "$(tail -1 "$l" | awk '{print $1}')" = macos ] && [ "$(head -1 "$l" | awk '{print $1}')" = ghostty ] && ok "two quick applies: last.log is one complete 7-line run" || bad "last.log not one complete run ($(wc -l <"$l") lines)"
ls "$T/home/.config/theme-reach" | grep -q 'last.log\.' && bad "temp log left behind"
[ ! -e "$T/home/.config/theme-reach/last.err" ] && ok "clean runs leave no last.err" || bad "last.err after clean runs: $(cat "$T/home/.config/theme-reach/last.err")"
# early failure: colors.sh breaks before reach.py runs -> last.err gets a timestamped line with the theme
echo 'THEME=nord; nosuchcmd_reach_test' > "$T/home/.config/sketchybar/colors.sh"
HOME="$T/home" bash "$T/dot/themes/reach.sh" apply >/dev/null 2>&1
e="$T/home/.config/theme-reach/last.err"
grep -q 'theme=nord' "$e" 2>/dev/null && grep -q 'nosuchcmd_reach_test' "$e" && grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2} ' "$e" && ok "early failure recorded in last.err" || bad "early failure not in last.err"
# reach.py failing: non-zero exit is recorded
echo 'THEME=nord' > "$T/home/.config/sketchybar/colors.sh"; echo 'import sys; sys.exit(3)' > "$T/dot/themes/reach.py"
HOME="$T/home" bash "$T/dot/themes/reach.sh" apply >/dev/null 2>&1
grep -q 'reach.py exited 3' "$e" && ok "reach.py failure recorded in last.err" || bad "reach.py failure not recorded"
exit $fail
