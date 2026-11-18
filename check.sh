#!/bin/bash
# One command that verifies the desktop: one PASS or FAIL line per check, exit 0 only if all pass.
#   check.sh            read-only: no bar reload, no theme or style switch
#                       (it does run `aerospace reload-config`, which is harmless)
#   check.sh --themes   also run themes/check-all.sh (switches through all themes, then restores)
#   check.sh --styles   also switch to the other bar style and back, checking each (reloads the bar twice);
#                        in flat it also forces every smart item visible and checks nothing overlaps
#   check.sh --smart    only the forced-visible smart-item check, on the current (flat) style
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"
DOT="$(cd "$(dirname "$0")" && pwd)"
CONF="$HOME/.config/sketchybar"
GHOSTTY=/Applications/Ghostty.app/Contents/MacOS/ghostty
fail=0

result() { # result <name> <rc> [detail]
  if [ "$2" = 0 ]; then printf 'PASS  %s\n' "$1"; else printf 'FAIL  %s%s\n' "$1" "${3:+  ($3)}"; fail=1; fi
}

# --- syntax ---------------------------------------------------------------------------------
bad=""
while IFS= read -r f; do bash -n "$f" 2>/dev/null || bad="$bad ${f#$DOT/}"; done < <(
  { find "$DOT" \( -name .git -o -name backgrounds -o -name '*.app' -o -name nvim \) -prune -o -type f -name '*.sh' -print
    echo "$DOT/sketchybar/sketchybarrc"; } | sort -u)
result "bash -n on every shell file" "$([ -z "$bad" ] && echo 0 || echo 1)" "$bad"

bad=""
for f in "$DOT"/zsh/*.zsh; do zsh -n "$f" 2>/dev/null || bad="$bad ${f#$DOT/}"; done
result "zsh -n on the zsh files" "$([ -z "$bad" ] && echo 0 || echo 1)" "$bad"

bad=""; pyc=$(mktemp -d)   # bytecode goes to a temp dir, never into the repo
while IFS= read -r f; do
  PYTHONPYCACHEPREFIX="$pyc" python3 -m py_compile "$f" 2>/dev/null || bad="$bad ${f#$DOT/}"
done < <(find "$DOT" \( -name .git -o -name backgrounds -o -name '*.app' -o -name nvim \) -prune -o -type f -name '*.py' -print)
rm -rf "$pyc"
result "py_compile on every python file" "$([ -z "$bad" ] && echo 0 || echo 1)" "$bad"

# --- tools ----------------------------------------------------------------------------------
out=$("$GHOSTTY" +validate-config 2>&1); result "ghostty +validate-config" $? "$(echo "$out" | head -1)"
out=$(aerospace reload-config 2>&1); result "aerospace reload-config" $? "$(echo "$out" | head -1)"
out=$(/usr/bin/python3 "$CONF/plugins/keys.py" check 2>&1); rc=$?
result "keys.py check: 0 missing" "$rc" "$(echo "$out" | tail -1)"

bad=""
for app in SketchyBarWiFi SketchyBarBluetooth SketchyBarCal; do
  codesign -v "$DOT/sketchybar/helper/$app.app" 2>/dev/null || bad="$bad $app"
done
result "codesign -v on the three helper apps" "$([ -z "$bad" ] && echo 0 || echo 1)" "$bad"

# --- symlinks: every `link <repo path> <target>` line of install.sh ----------------------------
bad=""; n=0
while read -r src dst; do
  dst=$(eval echo "$dst"); n=$((n+1))
  [ -L "$dst" ] && [[ "$(readlink "$dst")" == "$DOT/$src" ]] || bad="$bad ${dst/#$HOME/~}"
done < <(sed -n 's/^link \([^ ]*\) \("[^"]*"\).*/\1 \2/p' "$DOT/install.sh")
result "all $n install.sh symlinks point into dotfiles" "$([ -z "$bad" ] && [ "$n" -gt 0 ] && echo 0 || echo 1)" "$bad"

# --- bar style and the AeroSpace top gap -----------------------------------------------------
style_check() { # style_check [label]  - state valid and gap matches
  local label=${1:-bar style} raw style want got
  raw=$(cat "$CONF/.barstyle" 2>/dev/null)
  case "$raw" in flat|centre|"") ;; *) result "$label: state valid" 1 "'.barstyle' holds '$raw'"; return ;; esac
  style=$(bash -c 'source "$HOME/.config/sketchybar/plugins/style.sh"; echo $BAR_STYLE')
  want=$(bash -c 'source "$HOME/.config/sketchybar/plugins/style.sh"; [ "$BAR_STYLE" = flat ] && echo $FLAT_TOP_GAP || echo $CENTRE_TOP_GAP')
  got=$(sed -n 's/^gaps\.outer\.top[[:space:]]*=[[:space:]]*\([0-9]*\).*/\1/p' "$DOT/aerospace/aerospace.toml")
  result "$label: '$style' with gaps.outer.top $want" "$([ "$got" = "$want" ] && echo 0 || echo 1)" "gaps.outer.top is '$got'"
}
style_check "bar style"

# --- no two visible bar items overlap ----------------------------------------------------------
overlap_check() { # overlap_check [label] [smart]  - "smart": the smart items are forced on, so each must be drawn
  local label=${1:-bar items} out
  out=$(SMART_CHECK=${2:-} python3 - <<'PY'
import json, os, subprocess, time
q = lambda *a: json.loads(subprocess.run(["sketchybar", "--query", *a], capture_output=True, text=True).stdout)
def collect():
    global centre_clock
    bar = q("bar"); H = bar["height"]; items = []; centre_clock = False
    for name in bar["items"]:
        it = q(name)
        if it.get("type") != "item" or it["geometry"]["drawing"] != "on" or it["geometry"]["position"] not in ("left", "right", "center"):
            continue
        for disp, r in (it.get("bounding_rects") or {}).items():
            (x, y), (w, h) = r["origin"], r["size"]
            if w > 0 and h > 0 and y < H:
                items.append((name, disp, x, y, w, h))
                if name == "calendar":
                    centre_clock = it["geometry"]["position"] == "center"
    return items
for _ in range(15):   # the bar answers empty while it reloads: retry for up to 15 s
    try:
        items = collect(); break
    except ValueError:
        time.sleep(1)
else:
    raise SystemExit(1)
bad = []
# The clock sits exactly in the middle of its display, with or without smart items next to it
if centre_clock:   # flat style only: in Centre Stage the clock lives at the right
    frames = {"display-%s" % d["arrangement-id"]: d["frame"]["w"] for d in q("displays")}
    for name, disp, x, y, w, h in items:
        if name == "calendar" and disp in frames and abs(x + w / 2 - frames[disp] / 2) > 1:
            bad.append("clock-off-centre(%+.1f)" % (x + w / 2 - frames[disp] / 2))
# Forced on, every smart item must really be drawn (a broken demo switch would pass the overlap check
# trivially), and nothing may touch the window title or the stats
if os.environ.get("SMART_CHECK"):
    drawn = {it[0] for it in items}
    want = "privacy vpn awake badge.slack badge.whatsapp market.1 market.2 spotify.anchor next_event timer window_title".split()
    bad += ["not-drawn:" + n for n in want if n not in drawn]
    # Homebrew updates are a row in the control popup, not a bar item: forced on, the row must be drawn
    if q("control.updates")["geometry"]["drawing"] != "on":
        bad.append("not-drawn:control.updates")
for i, a in enumerate(items):
    for b in items[i + 1:]:
        if a[1] != b[1] or {a[0], b[0]} == {"net.up", "net.down"}:   # net.down is drawn under net.up in flat style
            continue
        if min(a[2] + a[4], b[2] + b[4]) - max(a[2], b[2]) > 1 and min(a[3] + a[5], b[3] + b[5]) - max(a[3], b[3]) > 1:
            bad.append(a[0] + "/" + b[0])
print(len(items), " ".join(bad[:5]))
PY
)
  result "$label: no overlap among ${out%% *} visible items" "$([ -n "$out" ] && [ -z "${out#* }" ] && echo 0 || echo 1)" "overlap: ${out#* }"
}
overlap_check "bar items"

# --- flat style, FLAT_MARKET_ALWAYS=1: the market item is on the bar without any trading window open ---
if [ "$(cat "$CONF/.barstyle" 2>/dev/null)" = flat ] && [ "$(bash -c 'source "$HOME/.config/sketchybar/plugins/flat_config.sh"; echo $FLAT_MARKET_ALWAYS')" = 1 ]; then
  ok=1
  for _ in 1 2 3 4 5 6 7 8; do   # a fresh bar draws it on its first tick or when the first fetch lands
    sketchybar --query market.1 2>/dev/null | python3 -c 'import json,sys; g=json.load(sys.stdin)["geometry"]; sys.exit(0 if g["drawing"]=="on" else 1)' 2>/dev/null && { ok=0; break; }
    sleep 1
  done
  result "market item always on (FLAT_MARKET_ALWAYS=1), no trading window needed" "$ok" "market.1 is hidden: no cached quote and the fetch failed?"
fi

# --- the flat style's smart items, all forced visible at once (test switch plugins/smart_demo.sh) -------
smart_check() { # smart_check [label]  - flat only; always switches the test flags off again
  local label=${1:-smart items}
  [ "$(cat "$CONF/.barstyle" 2>/dev/null)" = flat ] || return 0
  trap 'bash "$CONF/plugins/smart_demo.sh" off >/dev/null 2>&1' EXIT   # a Ctrl-C mid-check still switches them off
  bash "$CONF/plugins/smart_demo.sh" on all >/dev/null 2>&1
  sleep 2   # the appear animation
  overlap_check "$label: all smart items forced visible" smart
  bash "$CONF/plugins/smart_demo.sh" off >/dev/null 2>&1
  sleep 1
}

# --- themes: all of them, each complete -------------------------------------------------------------
list=$(bash "$CONF/plugins/theme.sh" list --plain | cut -f1)
count=$(echo "$list" | grep -c .)
bad=""
for t in $list; do
  w=$t; [ "$t" = macchiato ] && w=catppuccin     # macchiato shares Catppuccin's wallpapers
  [ -s "$DOT/themes/$t/colors.toml" ] || bad="$bad $t:colors"
  [ -s "$DOT/themes/$t/neovim.lua" ] || bad="$bad $t:neovim"
  ls "$DOT/themes/backgrounds/$w"/* >/dev/null 2>&1 || bad="$bad $t:wallpaper"
done
result "theme.sh list returns $(ls ~/dotfiles/themes/*/colors.toml | wc -l | tr -d " ") themes, each with colours, neovim file, wallpaper folder" "$([ "$count" = "$(ls ~/dotfiles/themes/*/colors.toml | wc -l | tr -d " ")" ] && [ -z "$bad" ] && echo 0 || echo 1)" "count $count$bad"
out=$(python3 "$DOT/alfred/gen-themes.py" --check 2>&1); result "one valid Alfred theme file per theme" $? "$(echo "$out" | head -1)"
cur=$(bash "$CONF/plugins/theme.sh" current)
result "launch mode exists and Caps Lock is F18" "$(aerospace list-modes | grep -qx launch && hidutil property --get UserKeyMapping | grep -q 30064771181 && echo 0 || echo 1)"
out=$(bash "$DOT/snappy.sh" status 2>&1); rc=$?
result "snappy.sh status: key repeat and animation settings at target" "$rc" "$(echo "$out" | grep DIFF | head -2 | tr '\n' ' ')"

# om menu
OM="$DOT/om/om"
out=$(bash "$OM" list 2>&1); n=$(echo "$out" | grep -c '^[a-z-]*/$'); top=$(echo "$out" | grep -c '^[a-z-]*/\?$')
dry=$(bash "$OM" update --dry-run 2>&1)
miss=""; for a in "Claude Web" "ChatGPT Web" WhatsApp "Slack Web" Gmail "Google Calendar" GitHub YouTube; do [ -x "$HOME/Applications/$a.app/Contents/MacOS/launcher" ] || miss="$miss $a"; done
result "om menu tree: 9 top branches, update dry run has the snapshot, 8 web apps in ~/Applications" "$(
  [ "$(echo "$out" | grep -c '^\(apps\|learn\|trigger\|style\|setup\|install\|remove\|update\|system\)/$')" = 9 ] \
  && echo "$dry" | grep -q 'tmutil localsnapshot' && [ -z "$miss" ] && [ -L "$HOME/.local/bin/om" ] && echo 0 || echo 1)" "missing:$miss"

# --- theme reach ------------------------------------------------------------------------------------
# theme reach: every target of the theme switch holds what the active theme calls for (read-only).
while IFS=$'\t' read -r t rc d; do
  case "$t" in
    vscode) n="theme reach: VS Code Insiders colour theme matches the theme" ;;
    claude) n="theme reach: Claude Code theme matches light/dark" ;;
    tmux)   n="theme reach: ~/.config/tmux/theme.conf carries the theme accent" ;;
    delta)  n="theme reach: delta colours (~/.config/git/config) carry the theme accent" ;;
    macos)  n="theme reach: macOS accent and light/dark match the theme" ;;
    font)   n="theme reach: chosen font agrees across Ghostty and VS Code Insiders" ;;
    bg)     n="theme reach: wallpaper folder for the active theme is not empty" ;;
    *) continue ;;
  esac
  result "$n" "$rc" "$d"
done < <(/bin/bash "$DOT/themes/reach.sh" check 2>&1)
result "theme.sh bg and font answer" "$(bash "$DOT/themes/theme.sh" bg current >/dev/null 2>&1 && bash "$DOT/themes/theme.sh" font bogus 2>&1 | grep -q 'unknown font' && echo 0 || echo 1)"

# --- shell layer: Omarchy zsh + tmux (zsh/omarchy.zsh, tmux/tmux.conf) --------------------------------
out=$(zsh -i -c exit 2>&1); result "zsh -i -c exit is clean (shell layer)" "$([ -z "$out" ] && echo 0 || echo 1)" "$(echo "$out" | head -1)"
out=$(zsh -i -c 'for a in lsa lta ff g gcm cx t ic ix icx decompress; do [[ -n ${aliases[$a]} ]] || echo "alias $a"; done; for f in eff sff tdl tds tdlm tsl compress ga gd fip dip lip ssh n zd; do (( $+functions[$f] )) || echo "fn $f"; done' 2>&1)
result "Omarchy aliases and functions resolve" "$([ -z "$out" ] && echo 0 || echo 1)" "$(echo "$out" | head -3 | tr '\n' ' ')"
out=$(python3 - <<'PYEOF' 2>&1
import pty, os, select
pid, fd = pty.fork()
if pid == 0:
    os.execvp("zsh", ["zsh", "-i", "-c", 'bindkey | grep -c fzf'])
buf = b""
while select.select([fd], [], [], 10)[0]:
    try: d = os.read(fd, 4096)
    except OSError: break
    if not d: break
    buf += d
os.waitpid(pid, 0)
print(buf.decode(errors="replace").strip())
PYEOF
)
result "fzf key bindings on Ctrl+R, Ctrl+T, Alt+C (pty shell)" "$([ "${out%$'\r'}" -ge 3 ] 2>/dev/null && echo 0 || echo 1)" "bound: $out"
if command -v tmux >/dev/null; then
  tmux -L chk-shell kill-server 2>/dev/null
  out=$(tmux -L chk-shell -f "$DOT/tmux/tmux.conf" new -d -s t 'sleep 20' 2>&1 && tmux -L chk-shell show -gv prefix 2>&1)
  tmux -L chk-shell kill-server 2>/dev/null
  result "tmux.conf loads, prefix is C-Space" "$([ "$out" = C-Space ] && echo 0 || echo 1)" "$(echo "$out" | head -1)"
  grep -q 'source-file -q ~/.config/tmux/theme.conf' "$DOT/tmux/tmux.conf"; result "tmux.conf has the theme include line" $?
else result "tmux.conf loads, prefix is C-Space" 1 "tmux not installed"; fi
result "tldr works (tlrc)" "$(command -v tldr >/dev/null && tldr --version >/dev/null 2>&1 && echo 0 || echo 1)" "brew install tlrc"
# end shell layer

# --- optional, switching checks --------------------------------------------------------------------
for arg in "$@"; do
  case "$arg" in
    --themes)
      out=$(bash "$DOT/themes/check-all.sh" 2>&1); result "themes/check-all.sh (all themes, then restored to $cur)" $? "$(echo "$out" | grep -v ' set=0 ghostty=0 nvim=ok' | head -2 | tr '\n' ' ')" ;;
    --styles)
      start=$(bash "$CONF/plugins/barstyle.sh" get); other=$([ "$start" = flat ] && echo centre || echo flat)
      for s in "$other" "$start"; do
        bash "$CONF/plugins/barstyle.sh" set "$s" >/dev/null 2>&1
        sleep 3   # the bar reloads asynchronously; the overlap check retries until it answers
        style_check "switched to $s"; overlap_check "style $s"
        [ "$s" = flat ] && smart_check "style flat"
      done ;;
    --smart)
      smart_check "smart items" ;;
    *) echo "usage: check.sh [--themes] [--styles] [--smart]" >&2; exit 2 ;;
  esac
done

# keys and tools
result "om-key.sh is executable and valid bash" "$([ -x "$DOT/aerospace/om-key.sh" ] && bash -n "$DOT/aerospace/om-key.sh" && echo 0 || echo 1)" ""
result "Maccy and Handy are installed" "$([ -d /Applications/Maccy.app ] && [ -d /Applications/Handy.app ] && echo 0 || echo 1)" ""

echo
[ "$fail" = 0 ] && echo "ALL PASS" || echo "FAILED"
exit $fail
