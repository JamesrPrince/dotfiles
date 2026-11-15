#!/bin/bash
# One command that verifies the desktop: one PASS or FAIL line per check, exit 0 only if all pass.
#   check.sh            read-only: no bar reload, no theme or style switch
#                       (it does run `aerospace reload-config`, which is harmless)
#   check.sh --themes   also run themes/check-all.sh (switches through all 11 themes, then restores)
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

# --- themes: 11 of them, each complete -------------------------------------------------------------
list=$(bash "$CONF/plugins/theme.sh" list --plain | cut -f1)
count=$(echo "$list" | grep -c .)
bad=""
for t in $list; do
  w=$t; [ "$t" = macchiato ] && w=catppuccin     # macchiato shares Catppuccin's wallpapers
  [ -s "$DOT/themes/$t/colors.toml" ] || bad="$bad $t:colors"
  [ -s "$DOT/themes/$t/neovim.lua" ] || bad="$bad $t:neovim"
  ls "$DOT/themes/backgrounds/$w"/* >/dev/null 2>&1 || bad="$bad $t:wallpaper"
done
result "theme.sh list returns 11 themes, each with colours, neovim file, wallpaper folder" "$([ "$count" = 11 ] && [ -z "$bad" ] && echo 0 || echo 1)" "count $count$bad"
out=$(python3 "$DOT/alfred/gen-themes.py" --check 2>&1); result "one valid Alfred theme file per theme" $? "$(echo "$out" | head -1)"
cur=$(bash "$CONF/plugins/theme.sh" current)
result "launch mode exists and Caps Lock is F18" "$(aerospace list-modes | grep -qx launch && hidutil property --get UserKeyMapping | grep -q 30064771181 && echo 0 || echo 1)"

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

echo
[ "$fail" = 0 ] && echo "ALL PASS" || echo "FAILED"
exit $fail
