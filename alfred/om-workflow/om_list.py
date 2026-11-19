#!/usr/bin/python3
"""Alfred script filter for the `om` keyword: themes and desktop actions. Alfred filters by typing."""
import json, os, subprocess
HOME = os.path.expanduser("~")
theme = HOME + "/dotfiles/themes/theme.sh"
# themes/<id>/preview-thumb.png is the row's icon and preview.png opens with Quick Look (shift or cmd-Y);
# both come from themes/make-previews.py. The dotfiles folder is behind the sketchybar symlink.
THEMES = os.path.realpath(HOME + "/.config/sketchybar/../themes")
items = []
cur = ""
try:
    out = subprocess.run(["/bin/bash", theme, "list", "--plain"], capture_output=True, text=True, timeout=5).stdout
    cur = subprocess.run(["/bin/bash", theme, "current"], capture_output=True, text=True, timeout=5).stdout.strip()
    for line in out.splitlines():
        tid, _, name = line.partition("\t")
        active = tid == cur
        item = {"uid": "theme-" + tid, "title": "Theme: " + name + ("  \u25cf active" if active else ""),
                "subtitle": "Active theme. Shift for the full preview" if active
                            else "Switch bar, borders, Ghostty, Neovim and wallpaper. Shift for a preview",
                "arg": "theme:" + tid, "match": "theme " + name + " " + tid}
        thumb, full = THEMES + "/" + tid + "/preview-thumb.png", THEMES + "/" + tid + "/preview.png"
        if os.path.isfile(thumb):
            item["icon"] = {"path": thumb}
        if os.path.isfile(full):
            item["quicklookurl"] = full
        items.append(item)
except Exception:
    pass
# Screenshots and OCR belong to CleanShot X; only the colour picker stays here.
CAPTURE = [("colour", "colour", "Pick colour", "Colour under the cursor, #RRGGBB to the clipboard")]
for uid, cmd, title, sub in CAPTURE:
    items.append({"uid": "cap-" + uid, "title": title, "subtitle": sub, "arg": "cap:" + cmd,
                  "match": "capture screenshot " + title.lower() + " " + cmd + (" color" if uid == "colour" else "")})
toggles = {}
try:
    out = subprocess.run(["/bin/bash", HOME + "/dotfiles/toggles/toggle.sh", "status"], capture_output=True, text=True, timeout=5).stdout
    toggles = dict(l.split("=", 1) for l in out.split() if "=" in l)
except Exception:
    pass
TOGGLES = [("gaps", "Toggle gaps", "Window gaps (AeroSpace)"),
           ("bar", "Toggle bar", "Show or hide the bar"),
           ("opacity", "Toggle Ghostty opacity", "Front Ghostty window, cmd+shift+o")]
for name, title, sub in TOGGLES:
    st = toggles.get(name, "n/a")
    items.append({"uid": "toggle-" + name, "title": title + ("  (" + st + ")" if st in ("on", "off") else ""),
                  "subtitle": sub, "arg": "toggle:" + name, "match": "toggle " + title.lower() + " " + name})
items += [    {"uid": "barstyle", "title": "Next bar style", "subtitle": "barstyle.sh next", "arg": "barstyle", "match": "bar style next"},
    {"uid": "keys", "title": "Shortcut sheet", "subtitle": "Show or hide the key cheat sheet", "arg": "keys", "match": "shortcut keys cheat sheet"},
    {"uid": "lock", "title": "Lock screen", "subtitle": "pmset displaysleepnow", "arg": "lock", "match": "lock screen"},
    {"uid": "sleep", "title": "Sleep", "subtitle": "pmset sleepnow", "arg": "sleep", "match": "sleep"},
]
print(json.dumps({"items": items}))
