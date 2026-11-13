#!/usr/bin/python3
"""Regenerates sketchybar/colors.sh from themes/<id>/colors.toml (Omarchy's files).

Mapping: BLACK=darker_background  WHITE=bright_foreground  RED..MAGENTA=the base colours
GREY=foreground 62% over background  BAR=background @ a0  BACKGROUND_1=selection @ 90
BACKGROUND_2=muted @ 90  POPUP=background  ACCENT=accent.  Prints a contrast report.
Usage: python3 themes/gen-colors.py > sketchybar/colors.sh   (macchiato is kept as written below)
"""
import os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__))
# id, display name, Ghostty theme ("palette" = write the Omarchy palette)
THEMES = [
    ("tokyonight", "Tokyo Night",  "TokyoNight"),
    ("catppuccin", "Catppuccin",   "Catppuccin Mocha"),
    ("everforest", "Everforest",   "Everforest Dark Soft"),
    ("gruvbox",    "Gruvbox",      "Gruvbox Dark"),
    ("kanagawa",   "Kanagawa",     "Kanagawa Wave"),
    ("nord",       "Nord",         "Nord"),
    ("rosepine",   "Rose Pine",    "Rose Pine Dawn"),
    ("matteblack", "Matte Black",  "Matte Black"),
    ("osakajade",  "Osaka Jade",   "palette"),
    ("ristretto",  "Ristretto",    "Monokai Pro Ristretto"),
]

def load(tid):
    return dict(re.findall(r'^(\w+)\s*=\s*"([^"]*)"', open(f"{HERE}/{tid}/colors.toml").read(), re.M))
def rgb(h): h = h.lstrip("#"); return [int(h[i:i+2], 16) for i in (0, 2, 4)]
def hexs(v): return "".join("%02x" % round(x) for x in v)
def lum(h):
    f = lambda c: (c/255/12.92) if c/255 <= 0.03928 else (((c/255)+0.055)/1.055)**2.4
    r, g, b = [f(x) for x in rgb(h)]; return 0.2126*r + 0.7152*g + 0.0722*b
def contrast(a, b):
    la, lb = sorted([lum(a), lum(b)], reverse=True); return (la+0.05)/(lb+0.05)
def X(h, a="ff"): return "0x" + a + h.lstrip("#").lower()

out = ['''#!/bin/bash
# Colour themes. The active one is named in ~/.config/sketchybar/.theme
# (git-ignored). Switch with plugins/theme.sh (next | set <name> | list), alt-shift-t,
# the Theme row in the control centre, or the Alfred "om" menu.
# GENERATED for every theme except macchiato: python3 ~/dotfiles/themes/gen-colors.py
# (reads themes/<id>/colors.toml, which are Omarchy's own files). Every theme exports
# the same variable names; WHITE is the text colour (dark on a light theme).
# THEME_GHOSTTY: bundled Ghostty theme, or "palette" to write themes/<id>/colors.toml.

THEMES="macchiato %s"
THEME=${THEME_OVERRIDE:-$(cat "$HOME/.config/sketchybar/.theme" 2>/dev/null)}   # THEME_OVERRIDE: preview/list without switching
case " $THEMES " in *" $THEME "*) ;; *) THEME=macchiato ;; esac
export THEME THEMES

case $THEME in''' % " ".join(t[0] for t in THEMES)]
rep = []
for tid, name, gh in THEMES:
    c = load(tid); bg = c["background"]; fg = c["foreground"]
    k = 0.62
    while True:   # dim text: foreground mixed into background until it reads (>= 3.5:1)
        grey = "#" + hexs([a*k + b*(1-k) for a, b in zip(rgb(fg), rgb(bg))])
        if contrast(grey, bg) >= 3.5 or k >= 0.95: break
        k += 0.03
    white = c["bright_foreground"]
    if contrast(white, bg) < 4.5: white = fg
    rep.append((tid, contrast(white, bg), contrast(grey, bg), c["mode"]))
    out.append(f'''  {tid})
    export THEME_NAME="{name}" THEME_MODE={c["mode"]} THEME_GHOSTTY="{gh}"
    export BLACK={X(c["darker_background"])}  WHITE={X(white)}  RED={X(c["red"])}    GREEN={X(c["green"])}
    export BLUE={X(c["blue"])}   YELLOW={X(c["yellow"])} ORANGE={X(c["orange"])} MAGENTA={X(c["magenta"])}
    export GREY={X(grey)}
    export BAR_COLOR={X(bg, "a0")} BACKGROUND_1={X(c["selection"], "90")} BACKGROUND_2={X(c["muted"], "90")}
    export POPUP_BACKGROUND_COLOR={X(bg)}
    export ACCENT={X(c["accent"])}
    ;;''')
out.append('''  *)
    export THEME_NAME="Catppuccin Macchiato" THEME_MODE=dark THEME_GHOSTTY="Catppuccin Macchiato"
    export BLACK=0xff181926  WHITE=0xffcad3f5  RED=0xffed8796    GREEN=0xffa6da95
    export BLUE=0xff8aadf4   YELLOW=0xffeed49f ORANGE=0xfff5a97f MAGENTA=0xffc6a0f6
    export GREY=0xff939ab7
    export BAR_COLOR=0xa024273a BACKGROUND_1=0x903c3e4f BACKGROUND_2=0x90494d64
    export POPUP_BACKGROUND_COLOR=0xff24273a
    export ACCENT=0xff8aadf4
    ;;
esac

export TRANSPARENT=0x00000000
export ICON_COLOR=$WHITE
export LABEL_COLOR=$WHITE
export POPUP_BORDER_COLOR=$WHITE
export SHADOW_COLOR=$BLACK

# Accent: the focused workspace pill and the window border
export ACCENT_FILL="0x40${ACCENT:4}"    # accent at 25%
export HOVER_COLOR="0x26${WHITE:4}"     # text colour at 15%''')
print("\n".join(out))
for r in rep: print("# %-10s %-5s text %.1f  dim %.1f" % (r[0], r[3], r[1], r[2]), file=sys.stderr)
