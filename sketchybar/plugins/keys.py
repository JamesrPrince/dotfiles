#!/usr/bin/python3
"""Key-binding cheat sheet for the SketchyBar 'keys' popup.

Reads ~/.aerospace.toml on every run, so the sheet always matches the config.
  keys.py          rebuild the popup rows
  keys.py toggle   rebuild, then show or hide the popup
"""
import json
import os
import re
import subprocess
import sys

CONFIG = os.path.expanduser("~/.aerospace.toml")
CACHE = os.path.expanduser("~/.cache/sketchybar-keys-apps.json")
SKETCHYBAR = "/usr/local/bin/sketchybar"
FONT = "SF Pro"
ACCENT = "0xff8aadf4"
TEXT = "0xffcad3f5"
DIM = "0xff939ab7"

MODS = {"ctrl": "⌃", "alt": "⌥", "shift": "⇧", "cmd": "⌘"}
KEYS = {"backtick": "`", "slash": "/", "comma": ",", "minus": "-", "equal": "=",
        "semicolon": ";", "period": ".", "tab": "Tab", "esc": "Esc",
        "backspace": "⌫", "enter": "↩", "space": "Space",
        "left": "←", "right": "→", "up": "↑", "down": "↓"}

# Section order and the commands that belong to each
SECTIONS = ["Switch", "Rearrange", "Layout", "Open apps", "Service mode (⌥⇧; then)", "Resize mode (⌥⇧R then)"]


def parse_bindings():
    """Return {mode: [(key, command_text)]} from the binding tables."""
    modes, mode = {}, None
    with open(CONFIG, encoding="utf-8") as f:
        for raw in f:
            line = raw.strip()
            m = re.match(r"^\[mode\.(\w+)\.binding\]$", line)
            if m:
                mode = m.group(1)
                modes[mode] = []
                continue
            if line.startswith("["):
                mode = None
                continue
            if not mode or not line or line.startswith("#"):
                continue
            m = re.match(r"^([\w-]+)\s*=\s*(.+?)\s*(#.*)?$", line)
            if m:
                value = m.group(2)
                parts = re.findall(r"'([^']*)'|\"([^\"]*)\"", value)
                cmds = [a or b for a, b in parts]
                modes[mode].append((m.group(1), cmds))
    return modes


def pretty_key(key):
    *mods, base = key.split("-")
    return "".join(MODS.get(x, x) for x in mods) + KEYS.get(base, base.upper())


def app_name(bundle_id, cache):
    if bundle_id not in cache:
        out = subprocess.run(["mdfind", "kMDItemCFBundleIdentifier == '%s'" % bundle_id],
                             capture_output=True, text=True).stdout.splitlines()
        paths = [p for p in out if "Parallels" not in p] or out
        cache[bundle_id] = os.path.basename(paths[0])[:-4] if paths else bundle_id
    return cache[bundle_id]


def describe(cmds, cache):
    """Map a binding's commands to (section, description)."""
    cmds = [c for c in cmds if c != "mode main"]
    c = " ".join(cmds)
    if m := re.match(r"exec-and-forget open -b (\S+)", c):
        return "Open apps", app_name(m.group(1), cache)
    if "dfs-next" in c:
        return "Switch", "Next window"
    if "dfs-prev" in c:
        return "Switch", "Previous window"
    if m := re.match(r"focus (\w+)$", c):
        return "Switch", "Focus " + m.group(1)
    if m := re.match(r"workspace (\w+)$", c):
        return "Switch", "Workspace " + m.group(1)
    if c == "workspace-back-and-forth":
        return "Switch", "Last workspace"
    if m := re.match(r"move (\w+)$", c):
        return "Rearrange", "Move window " + m.group(1)
    if m := re.match(r"move-node-to-workspace (\w+)$", c):
        return "Rearrange", "Send window to " + m.group(1)
    if c.startswith("move-workspace-to-monitor"):
        return "Rearrange", "Workspace to next monitor"
    if m := re.match(r"resize smart ([+-])", c):
        return "Rearrange", "Grow window" if m.group(1) == "+" else "Shrink window"
    if m := re.match(r"join-with (\w+)$", c):
        return "Service", "Join with " + m.group(1)
    if c.startswith("layout tiles"):
        return "Layout", "Tiles / flip direction"
    if c.startswith("layout accordion"):
        return "Layout", "Accordion"
    if c.startswith("fullscreen"):
        return "Layout", "Full screen"
    if c == "layout floating tiling":
        return "Service", "Float / tile window"
    if c == "flatten-workspace-tree":
        return "Service", "Reset layout"
    if c == "close-all-windows-but-current":
        return "Service", "Close other windows"
    if c == "reload-config":
        return "Service", "Reload config, exit"
    if c == "mode service":
        return "Layout", "Service mode"
    if c == "mode resize":
        return "Layout", "Resize mode"
    if m := re.match(r"resize (width|height) ([+-])", c):
        return "Resize", ("Wider" if m.group(1) == "width" else "Taller") if m.group(2) == "+" else ("Narrower" if m.group(1) == "width" else "Shorter")
    if c == "balance-sizes":
        return "Service", "Equal sizes"
    if c == "":
        return "Resize", "Done"
    if "cheat sheet" in c or "keys.py" in c:
        return "Layout", "This cheat sheet"
    return "Layout", c


def collapse_numbers(rows):
    """Fold ⌥1 … ⌥9 'Workspace N' rows into one '⌥1–9' row."""
    out, groups = [], {}
    for key, desc in rows:
        m = re.match(r"^(.*?)(\d)$", key)
        d = re.match(r"^(.*?)(\w)$", desc)
        if m and d and d.group(2) == m.group(2):
            g = groups.setdefault((m.group(1), d.group(1)), [])
            if not g:
                out.append(((m.group(1), d.group(1)), g))
            g.append(m.group(2))
        else:
            out.append((key, desc))
    rows = []
    for item in out:
        if isinstance(item[1], list):
            (prefix, text), nums = item
            rng = nums[0] if len(nums) == 1 else "%s–%s" % (nums[0], nums[-1])
            rows.append((prefix + rng, text + rng))
        else:
            rows.append(item)
    return rows


def build_rows():
    try:
        with open(CACHE, encoding="utf-8") as f:
            cache = json.load(f)
    except (OSError, ValueError):
        cache = {}
    modes = parse_bindings()
    grouped = {s: [] for s in SECTIONS}
    for key, cmds in modes.get("main", []):
        section, desc = describe(cmds, cache)
        grouped[section].append((pretty_key(key), desc))
    for key, cmds in modes.get("service", []):
        grouped[SECTIONS[-2]].append((pretty_key(key), describe(cmds, cache)[1]))
    # Resize mode: the arrows repeat h/j/k/l, so list the letters only
    for key, cmds in modes.get("resize", []):
        if key in ("left", "right", "up", "down", "enter"):
            continue
        grouped[SECTIONS[-1]].append((pretty_key(key), describe(cmds, cache)[1]))
    grouped["Open apps"].sort(key=lambda r: r[0])
    os.makedirs(os.path.dirname(CACHE), exist_ok=True)
    with open(CACHE, "w", encoding="utf-8") as f:
        json.dump(cache, f)
    lines = []
    for section in SECTIONS:
        rows = collapse_numbers(grouped[section])
        if rows:
            lines.append(("header", section))
            lines += [("row", "%-8s %s" % (k, d)) for k, d in rows]
    return lines


def main():
    args = [SKETCHYBAR, "--remove", "/keys\\.row\\..*/"]
    for i, (kind, text) in enumerate(build_rows()):
        name = "keys.row.%03d" % i
        header = kind == "header"
        args += ["--add", "item", name, "popup.keys",
                 "--set", name, "icon.drawing=off", "label=" + text,
                 "label.font=%s:%s:%s" % (FONT, "Bold" if header else "Regular",
                                          "13.0" if header else "12.0"),
                 "label.color=" + (ACCENT if header else TEXT),
                 "padding_left=6", "padding_right=6",
                 "label.padding_top=%d" % (6 if header and i else 0)]
    subprocess.run(args, capture_output=True)
    if len(sys.argv) > 1 and sys.argv[1] == "toggle":
        subprocess.run([SKETCHYBAR, "--set", "keys", "popup.drawing=toggle"])


if __name__ == "__main__":
    main()
