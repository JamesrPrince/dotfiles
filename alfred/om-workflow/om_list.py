#!/usr/bin/python3
"""Alfred script filter for the `om` keyword: themes and desktop actions. Alfred filters by typing."""
import json, os, subprocess
HOME = os.path.expanduser("~")
theme = HOME + "/.config/sketchybar/plugins/theme.sh"
items = []
cur = ""
try:
    out = subprocess.run(["/bin/bash", theme, "list", "--plain"], capture_output=True, text=True, timeout=5).stdout
    cur = subprocess.run(["/bin/bash", theme, "current"], capture_output=True, text=True, timeout=5).stdout.strip()
    for line in out.splitlines():
        tid, _, name = line.partition("\t")
        items.append({"uid": "theme-" + tid, "title": "Theme: " + name,
                      "subtitle": "Switch bar, borders, Ghostty, Neovim and wallpaper" + ("  (active)" if tid == cur else ""),
                      "arg": "theme:" + tid, "match": "theme " + name + " " + tid})
except Exception:
    pass
items += [
    {"uid": "barstyle", "title": "Next bar style", "subtitle": "barstyle.sh next", "arg": "barstyle", "match": "bar style next"},
    {"uid": "keys", "title": "Shortcut sheet", "subtitle": "Show or hide the key cheat sheet", "arg": "keys", "match": "shortcut keys cheat sheet"},
    {"uid": "lock", "title": "Lock screen", "subtitle": "pmset displaysleepnow", "arg": "lock", "match": "lock screen"},
    {"uid": "sleep", "title": "Sleep", "subtitle": "pmset sleepnow", "arg": "sleep", "match": "sleep"},
]
print(json.dumps({"items": items}))
