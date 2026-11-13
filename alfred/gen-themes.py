#!/usr/bin/python3
"""Writes one Alfred appearance theme per bar theme: alfred/themes/<id>.alfredappearance.
Colours come from themes/<id>/colors.toml, the same files that colour the bar and Ghostty.
Theme names are "Om <name>" (the name theme.sh passes to Alfred's `set theme`).
Usage: python3 alfred/gen-themes.py            write all
       python3 alfred/gen-themes.py --check    validate the files on disk, exit 1 on a problem
"""
import json, os, re, subprocess, sys
HERE = os.path.dirname(os.path.abspath(__file__))
THEMES_DIR = os.path.join(os.path.dirname(HERE), "themes")
OUT = os.path.join(HERE, "themes")

def theme_list():
    """[(id, display name)] from theme.sh, the single list of themes."""
    out = subprocess.run(["/bin/bash", os.path.join(os.path.dirname(HERE), "sketchybar/plugins/theme.sh"), "list", "--plain"],
                         capture_output=True, text=True, check=True).stdout
    return [tuple(l.split("\t", 1)) for l in out.splitlines() if l]

def colours(tid):
    return dict(re.findall(r'^(\w+)\s*=\s*"([^"]*)"', open(f"{THEMES_DIR}/{tid}/colors.toml").read(), re.M))

def a(h, alpha="ff"):
    return h.lower() + alpha

def build(tid, name):
    c = colours(tid)
    fg, sub, sel = c["bright_foreground"], c["light_foreground"], c["selection"]
    font = lambda size, col, colsel: {"size": size, "font": "System", "color": a(col), "colorSelected": a(colsel)}
    return {"alfredtheme": {
        "name": "Om " + name, "credit": "dotfiles, from themes/%s/colors.toml" % tid,
        "result": {"textSpacing": 5, "roundness": 6, "paddingVertical": 4, "iconSize": 36, "iconPaddingHorizontal": 6,
                   "backgroundSelected": a(sel),
                   "text": font(18, fg, fg), "subtext": font(12, c["dark_foreground"], sub), "shortcut": font(16, c["dark_foreground"], fg)},
        "search": {"background": a(c["darker_background"]), "backgroundSelected": a(sel), "roundness": 6,
                   "paddingHorizontal": 8, "paddingVertical": 6, "spacing": 8,
                   "text": {"size": 32, "font": "System Light", "color": a(fg), "colorSelected": a(fg)}},
        "window": {"color": a(c["background"]), "borderColor": a(c["accent"]), "borderPadding": 2, "blur": 0,
                   "roundness": 8, "width": 600, "paddingHorizontal": 10, "paddingVertical": 10},
        "separator": {"color": a(c["muted"]), "thickness": 1},
        "scrollbar": {"color": a(c["muted"]), "thickness": 2},
    }}

def validate(path, tid, name):
    d = json.load(open(path))["alfredtheme"]
    assert d["name"] == "Om " + name, "name"
    for sect in ("result", "search", "window", "separator", "scrollbar"):
        assert sect in d, sect
    cols = []
    def walk(x):
        if isinstance(x, dict): [walk(v) for v in x.values()]
        elif isinstance(x, str) and x.startswith("#"): cols.append(x)
    walk(d)
    assert cols and all(re.fullmatch(r"#[0-9a-f]{8}", x) for x in cols), "colour format"

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    themes = theme_list()
    if "--check" in sys.argv:
        bad = 0
        for tid, name in themes:
            try: validate(f"{OUT}/{tid}.alfredappearance", tid, name)
            except Exception as e: bad += 1; print("FAIL", tid, e)
        print("%d themes, %d bad" % (len(themes), bad)); sys.exit(1 if bad or len(themes) != 11 else 0)
    for tid, name in themes:
        with open(f"{OUT}/{tid}.alfredappearance", "w") as f:
            json.dump(build(tid, name), f, indent=2); f.write("\n")
        print("wrote", tid)
