#!/usr/bin/env python3
"""Theme reach: what one `theme.sh set` changes beyond the bar, Ghostty, nvim and Alfred.

Called through themes/reach.sh (which sets THEME, THEME_MODE, ACCENT from the bar's colors.sh).
  reach.py apply            VS Code Insiders, Claude Code, tmux, delta, macOS accent and light/dark
  reach.py bg next|prev|pick|current    wallpaper within the active theme's folder
  reach.py font [name|default]          terminal and editor font (no name: fzf pick)
  reach.py ghostty-font     the Ghostty lines for the chosen font (theme.sh's ghostty part appends them)
Every target edits its own settings key by key; a settings file is backed up once (.bak-20261118).
"""
import json, os, re, subprocess, sys, shutil, unicodedata, glob, tomllib, colorsys

HOME = os.path.expanduser("~")
DOT = os.path.realpath(os.path.join(os.path.dirname(os.path.realpath(__file__)), ".."))
STATE = os.path.join(HOME, ".config", "theme-reach")
BAK = ".bak-20261118"
THEME = os.environ.get("THEME", "")
MODE = os.environ.get("THEME_MODE", "dark")

# Omarchy 4.5's own vscode.json per theme (name, extension). None: Omarchy names no VS Code theme.
VSCODE = {
    "macchiato": ("CatppuccinMacchiato", "catppuccin.catppuccin-vsc"),   # not an Omarchy theme
    "catppuccin": ("CatppuccinMocha", "catppuccin.catppuccin-vsc"),
    "catppuccinlatte": ("CatppuccinLatte", "catppuccin.catppuccin-vsc"),
    "everforest": ("EverforestDark", "reesew.everforest-theme"),
    "flexokilight": ("flexoki-light", "shadesOfBuntu.flexoki-light"),
    "gruvbox": ("GruvboxDarkMedium", "jdinhlife.gruvbox"),
    "hackerman": ("Hackerman", "Bjarne.hackerman-omarchy"),
    "kanagawa": ("Kanagawa", "qufiwefefwoyn.kanagawa"),
    "lasthorizon": ("ShipatSea", "rikkarth.ship-at-sea"),
    "lumon": ("Lumon", "oldjobobo.lumon-theme"),
    "matteblack": ("MatteBlack", "TahaYVR.matteblack"),
    "nord": ("Nord", "arcticicestudio.nord-visual-studio-code"),
    "osakajade": ("OceanGreenDark", "jovejonovski.ocean-green"),
    "retro82": ("Retro82", "oldjobobo.retro-82-theme"),
    "rosepine": ("RosePineDawn", "mvllow.rose-pine"),
    "solitude": ("Noctokai", "farigab.noctokai-theme"),
    "tokyonight": ("TokyoNight", "enkia.tokyo-night"),
}
VSCODE_FALLBACK = {"dark": "Default Dark Modern", "light": "Default Light Modern"}
CODE_BIN = "/Applications/Visual Studio Code - Insiders.app/Contents/Resources/app/bin/code"
VSCODE_USER = os.path.join(HOME, "Library/Application Support/Code - Insiders/User/settings.json")
VSCODE_EXT = os.path.join(HOME, ".vscode-insiders/extensions")

FONTS = {  # ruled list; all Nerd Font builds by brew cask
    "JetBrains Mono": "JetBrainsMono Nerd Font",
    "CaskaydiaMono": "CaskaydiaMono Nerd Font",
    "Fira Code": "FiraCode Nerd Font",
    "Meslo": "MesloLGS Nerd Font",
}
DEFAULT_FONT = "Maple Mono NF"   # what ghostty/config sets; `font default` goes back to it

# macOS accent: AppleAccentColor value, name, accent RGB, AppleHighlightColor
MAC_ACCENTS = [
    (0, "red", (255, 82, 87), "1.000000 0.733333 0.721569 Red"),
    (1, "orange", (247, 130, 27), "1.000000 0.874510 0.701961 Orange"),
    (2, "yellow", (255, 198, 0), "1.000000 0.937255 0.690196 Yellow"),
    (3, "green", (98, 186, 70), "0.752941 0.964706 0.678431 Green"),
    (4, "blue", (0, 122, 255), "0.698039 0.843137 1.000000 Blue"),
    (5, "purple", (165, 80, 167), "0.968627 0.831373 1.000000 Purple"),
    (6, "pink", (247, 79, 158), "1.000000 0.749020 0.823529 Pink"),
    (-1, "graphite", (140, 140, 140), "0.847059 0.847059 0.862745 Graphite"),
]


def say(target, msg):
    print("%-8s %s" % (target, msg), flush=True)


def norm(s):
    s = unicodedata.normalize("NFKD", s)
    return re.sub(r"[^a-z0-9]", "", "".join(c for c in s if not unicodedata.combining(c)).lower())


def palette():
    """The theme's colours (themes/<id>/colors.toml); accent from the bar's ACCENT so they agree."""
    t = "catppuccin" if THEME == "macchiato" else THEME
    with open(os.path.join(DOT, "themes", t, "colors.toml"), "rb") as f:
        c = tomllib.load(f)
    acc = os.environ.get("ACCENT", "")
    if re.fullmatch(r"0x[0-9a-fA-F]{8}", acc):
        c["accent"] = "#" + acc[4:].lower()
    return c


def rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def blend(bg, fg, a):
    b, f = rgb(bg), rgb(fg)
    return "#%02x%02x%02x" % tuple(round(b[i] * (1 - a) + f[i] * a) for i in range(3))


def backup_once(path):
    if os.path.exists(path) and not os.path.exists(path + BAK):
        shutil.copy2(path, path + BAK)


def write_atomic(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp-theme"
    with open(tmp, "w") as f:
        f.write(text)
    os.replace(tmp, path)


def edit_json_keys(path, changes, indent):
    """Set (value) or delete (None) top-level keys in a JSON file; every other key untouched."""
    with open(path) as f:
        data = json.load(f)
    before = json.dumps(data, sort_keys=True)
    for k, v in changes.items():
        if v is None:
            data.pop(k, None)
        else:
            data[k] = v
    if json.dumps(data, sort_keys=True) == before:
        return False
    backup_once(path)
    write_atomic(path, json.dumps(data, indent=indent, ensure_ascii=False) + "\n")
    return True


def state(name, value=False):
    p = os.path.join(STATE, name)
    if value is False:
        try:
            return open(p).read().strip() or None
        except OSError:
            return None
    if value is None:
        try:
            os.remove(p)
        except OSError:
            pass
    else:
        os.makedirs(STATE, exist_ok=True)
        write_atomic(p, value + "\n")


# ---- VS Code Insiders ------------------------------------------------------------------------
def vscode_label(ext_id, name):
    """The colour theme's real label inside the installed extension, or None."""
    for d in glob.glob(os.path.join(VSCODE_EXT, ext_id.lower() + "-*")):
        try:
            pkg = json.load(open(os.path.join(d, "package.json")))
        except (OSError, ValueError):
            continue
        themes = pkg.get("contributes", {}).get("themes", [])
        want = norm(name)
        for key in ("label", "id"):
            for t in themes:
                if norm(t.get(key, "")) == want:
                    return t.get("label") or t.get("id")
        for t in themes:
            if want and want in norm(t.get("label", "")):
                return t.get("label")
    return None


def ext_installed(ext_id):
    return bool(glob.glob(os.path.join(VSCODE_EXT, ext_id.lower() + "-*")))


def vscode():
    if not os.path.exists(VSCODE_USER):
        return say("vscode", "skipped (no Insiders settings.json)")
    pick = VSCODE.get(THEME)
    note = ""
    label = None
    if pick:
        name, ext = pick
        if not ext_installed(ext):
            try:
                subprocess.run([CODE_BIN, "--install-extension", ext], capture_output=True, timeout=120)
            except (OSError, subprocess.SubprocessError):
                pass
        label = vscode_label(ext, name)
        if not label:
            note = " (extension %s missing or has no '%s': fallback)" % (ext, name)
    else:
        note = " (Omarchy names no VS Code theme: built-in fallback)"
    label = label or VSCODE_FALLBACK[MODE]
    try:
        changed = edit_json_keys(VSCODE_USER, {"workbench.colorTheme": label}, 4)
    except ValueError:
        return say("vscode", "BLOCKED settings.json is not plain JSON (comments?); set workbench.colorTheme = %r yourself" % label)
    say("vscode", "workbench.colorTheme = %r%s%s" % (label, " (changed)" if changed else "", note))


# ---- Claude Code ------------------------------------------------------------------------------
def claude_theme():
    """Claude Code's theme, read from ~/.claude/settings.json. Never written here: ~/.claude.json is
    live state that every running session rewrites, so a key set there is dropped within minutes."""
    try:
        return json.load(open(os.path.join(HOME, ".claude", "settings.json"))).get("theme")
    except (OSError, ValueError):
        return None


def claude():
    cur = claude_theme()
    if cur == "auto":
        return say("claude", "theme = auto (follows the terminal's light/dark, so it follows the switch)")
    if cur == MODE:
        return say("claude", "theme = %s" % MODE)
    say("claude", "NOT FOLLOWING: theme is %r; run /theme in Claude Code and pick auto" % cur)


# ---- tmux --------------------------------------------------------------------------------------
def tmux():
    c = palette()
    conf = os.path.join(HOME, ".config/tmux/theme.conf")
    lines = [
        "# Written by ~/dotfiles/themes/reach.py on every theme switch (%s). Do not edit." % THEME,
        "set -g status-style \"bg=%s,fg=%s\"" % (c["lighter_background"], c["foreground"]),
        "set -g message-style \"bg=%s,fg=%s\"" % (c["accent"], c["background"]),
        "set -g message-command-style \"bg=%s,fg=%s\"" % (c["accent"], c["background"]),
        "set -g pane-border-style \"fg=%s\"" % c["muted"],
        "set -g pane-active-border-style \"fg=%s\"" % c["accent"],
        "set -g mode-style \"bg=%s,fg=%s\"" % (c["selection"], c["foreground"]),
        "set -g window-status-style \"fg=%s\"" % c["dark_foreground"],
        "set -g window-status-current-style \"fg=%s,bold\"" % c["accent"],
        "set -g window-status-activity-style \"fg=%s\"" % c["yellow"],
        "set -g display-panes-colour \"%s\"" % c["muted"],
        "set -g display-panes-active-colour \"%s\"" % c["accent"],
        "set -g clock-mode-colour \"%s\"" % c["accent"],
    ]
    for k in ("accent", "background", "lighter_background", "foreground", "muted", "selection", "red", "green", "yellow", "blue", "magenta", "cyan"):
        lines.append("set -g @theme_%s \"%s\"" % (k, c[k]))
    lines.append("set -g @theme_mode \"%s\"" % MODE)
    text = "\n".join(lines) + "\n"
    old = open(conf).read() if os.path.exists(conf) else None
    if old != text:
        write_atomic(conf, text)
    tmuxbin = shutil.which("tmux", path="/usr/local/bin:/opt/homebrew/bin:" + os.environ.get("PATH", ""))
    reloaded = 0
    if tmuxbin:
        for sock in glob.glob("/private/tmp/tmux-%d/*" % os.getuid()) + glob.glob("/tmp/tmux-%d/*" % os.getuid()):
            r = subprocess.run([tmuxbin, "-S", sock, "source-file", "-q", conf], capture_output=True)
            reloaded += r.returncode == 0
    say("tmux", "%s %s; %s" % (conf, "rewritten" if old != text else "unchanged",
        ("reloaded %d server(s)" % reloaded) if tmuxbin else "tmux not installed, no server to reload"))


# ---- delta -------------------------------------------------------------------------------------
def delta():
    """~/.config/git/config is git's own second global file: read with ~/.gitconfig, no include needed,
    and ~/.gitconfig stays untouched."""
    c = palette()
    bg = c["background"]
    q = lambda s: '"%s"' % s
    kv = [
        ("dark" if MODE == "dark" else "light", "true"),
        ("minus-style", q("syntax " + blend(bg, c["red"], 0.20))),
        ("minus-emph-style", q("syntax " + blend(bg, c["red"], 0.42) + " bold")),
        ("minus-non-emph-style", q("syntax " + blend(bg, c["red"], 0.20))),
        ("plus-style", q("syntax " + blend(bg, c["green"], 0.20))),
        ("plus-emph-style", q("syntax " + blend(bg, c["green"], 0.42) + " bold")),
        ("plus-non-emph-style", q("syntax " + blend(bg, c["green"], 0.20))),
        ("minus-empty-line-marker-style", q("normal " + blend(bg, c["red"], 0.20))),
        ("plus-empty-line-marker-style", q("normal " + blend(bg, c["green"], 0.20))),
        ("line-numbers-minus-style", q(c["red"])),
        ("line-numbers-plus-style", q(c["green"])),
        ("line-numbers-zero-style", q(c["muted"])),
        ("line-numbers-left-style", q(c["muted"])),
        ("line-numbers-right-style", q(c["muted"])),
        ("file-style", q("bold " + c["accent"])),
        ("file-decoration-style", q(c["accent"] + " ul")),
        ("hunk-header-style", q("file line-number syntax")),
        ("hunk-header-file-style", q(c["accent"])),
        ("hunk-header-line-number-style", q(c["yellow"])),
        ("hunk-header-decoration-style", q(c["muted"] + " box")),
    ]
    text = ("# Written by ~/dotfiles/themes/reach.py on every theme switch (%s). Do not edit.\n"
            "# git reads this second global file next to ~/.gitconfig; delta takes its colours from it.\n[delta]\n" % THEME)
    text += "".join("\t%s = %s\n" % kv_ for kv_ in kv)
    conf = os.path.join(HOME, ".config/git/config")
    old = open(conf).read() if os.path.exists(conf) else ""
    begin, end = "# >>> theme reach: delta (managed block)\n", "# <<< theme reach: delta\n"
    block = begin + text + end
    if begin in old and end in old:          # replace our block only; everything else in the file is the user's
        new = old[:old.index(begin)] + block + old[old.index(end) + len(end):]
    elif not old.strip() or old.startswith("# Written by ~/dotfiles/themes/reach.py"):
        new = block                          # empty, or the whole-file version this replaced
    else:
        new = old.rstrip("\n") + "\n\n" + block
    if new != old:
        if old:
            backup_once(conf)
        write_atomic(conf, new)
    say("delta", "%s %s" % (conf, "delta block rewritten" if new != old else "unchanged"))


# ---- macOS accent and light/dark ----------------------------------------------------------------
def nearest_accent(hexcol):
    r, g, b = rgb(hexcol)
    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    if s < 0.18 or v < 0.15:
        return next(a for a in MAC_ACCENTS if a[1] == "graphite")
    def dist(a):
        ah = colorsys.rgb_to_hsv(*(x / 255 for x in a[2]))[0]
        d = abs(ah - h)
        return min(d, 1 - d)
    return min((a for a in MAC_ACCENTS if a[1] != "graphite"), key=dist)


def defaults(*args):
    return subprocess.run(["/usr/bin/defaults", *args], capture_output=True, text=True)


def notifier():
    """Tiny helper that posts the notification System Settings posts after an accent change."""
    d = os.path.join(HOME, ".cache/theme-reach")
    exe = os.path.join(d, "accentnotify")
    if not os.path.exists(exe):
        os.makedirs(d, exist_ok=True)
        src = os.path.join(DOT, "themes", "accentnotify.swift")
        if subprocess.run(["swiftc", "-O", src, "-o", exe], capture_output=True).returncode != 0:
            return None
    return exe


def macos():
    c = palette()
    idx, name, _, hl = nearest_accent(c["accent"])
    cur = defaults("read", "-g", "AppleAccentColor").stdout.strip()
    curhl = defaults("read", "-g", "AppleHighlightColor").stdout.strip()
    if cur != str(idx) or curhl != hl:
        defaults("write", "-g", "AppleAccentColor", "-int", str(idx))
        defaults("write", "-g", "AppleHighlightColor", "-string", hl)
        exe = notifier()
        if exe:
            subprocess.run([exe], capture_output=True)
    acc_msg = "accent %s (%d)" % (name, idx)
    want_dark = MODE == "dark"
    is_dark = defaults("read", "-g", "AppleInterfaceStyle").stdout.strip() == "Dark"
    if is_dark == want_dark:
        return say("macos", "%s; appearance already %s" % (acc_msg, MODE))
    r = subprocess.run(["/usr/bin/osascript", "-e",
        'tell application "System Events" to tell appearance preferences to set dark mode to %s' % ("true" if want_dark else "false")],
        capture_output=True, text=True, timeout=30)
    if r.returncode != 0:
        say("macos", "%s; appearance BLOCKED: %s" % (acc_msg, r.stderr.strip()[:160]))
        print("         run: osascript -e 'tell application \"System Events\" to tell appearance preferences to set dark mode to %s'"
              % ("true" if want_dark else "false"))
        return
    say("macos", "%s; appearance -> %s" % (acc_msg, MODE))


def apply():
    for fn in (ghostty_font, wall, vscode, claude, tmux, delta, macos):
        try:
            fn()
        except Exception as e:  # one target failing never stops the others
            say(fn.__name__, "FAILED %s: %s" % (type(e).__name__, e))


# ---- background -----------------------------------------------------------------------------------
def wall_dir():
    return "catppuccin" if THEME == "macchiato" else THEME


def wall_images():
    d = os.path.join(DOT, "themes/backgrounds", wall_dir())
    return sorted(p for p in glob.glob(d + "/*") if not os.path.basename(p).startswith("omarchy."))


def wall_current(imgs):
    cur = state("wall." + wall_dir())
    for p in imgs:
        if os.path.basename(p) == cur:
            return p
    return imgs[0] if imgs else None


def set_wall(path, remember=True):
    tool = os.path.join(DOT, "themes/setwall")
    if not os.access(tool, os.X_OK):
        subprocess.run(["swiftc", "-O", os.path.join(DOT, "themes/setwall.swift"), "-o", tool], capture_output=True)
    subprocess.run([tool, path], capture_output=True)
    if remember:
        state("wall." + wall_dir(), os.path.basename(path))


def wall():
    """The picture chosen with `bg` (the bar's own step always sets the first one)."""
    imgs = wall_images()
    if imgs and state("wall." + wall_dir()):
        cur = wall_current(imgs)
        set_wall(cur, remember=False)
        say("wall", os.path.basename(cur))


def bg(args):
    imgs = wall_images()
    if not imgs:
        sys.exit("no wallpapers for %s (themes/fetch-backgrounds.sh)" % wall_dir())
    cur = wall_current(imgs)
    sub = args[0] if args else "pick"
    if sub in ("next", "prev"):
        i = imgs.index(cur)
        new = imgs[(i + (1 if sub == "next" else -1)) % len(imgs)]
        set_wall(new)
        print("%s: %s (%d of %d)" % (wall_dir(), os.path.basename(new), imgs.index(new) + 1, len(imgs)))
    elif sub == "current":
        print(os.path.basename(cur))
    elif sub == "pick":
        names = [os.path.basename(p) for p in imgs]
        if args[1:]:  # non-interactive: bg pick <file>
            if args[1] not in names:
                sys.exit("not in this theme's folder: " + ", ".join(names))
            set_wall(os.path.join(os.path.dirname(imgs[0]), args[1]))
            return print("%s: %s" % (wall_dir(), args[1]))
        if not sys.stdin.isatty() or not shutil.which("fzf", path="/usr/local/bin:" + os.environ.get("PATH", "")):
            for i, n in enumerate(names, 1):
                print("%2d %s%s" % (i, n, "  *" if imgs[i - 1] == cur else ""))
            sys.exit("pick one with: theme.sh bg pick <file>")
        d = os.path.dirname(imgs[0])
        tool = os.path.join(DOT, "themes/setwall")
        # The wallpaper itself is the preview: it changes as the cursor moves; Esc puts the old one back.
        r = subprocess.run(["fzf", "--prompt", wall_dir() + " > ", "--bind",
                            "focus:execute-silent(%s %s/{} >/dev/null 2>&1 &)" % (tool, d)],
                           input="\n".join(names), text=True, stdout=subprocess.PIPE)
        pick = r.stdout.strip()
        if pick:
            set_wall(os.path.join(d, pick))
            print("%s: %s" % (wall_dir(), pick))
        else:
            set_wall(cur, remember=False)
    else:
        sys.exit("usage: theme.sh bg next | prev | pick [file] | current")


# ---- font ---------------------------------------------------------------------------------------------
def resolve_font(arg):
    n = norm(arg)
    if n in ("default", "maple", "maplemono", "maplemononf", "reset"):
        return None, True
    for k, fam in FONTS.items():
        if n in (norm(k), norm(fam), norm(k.replace(" Mono", ""))) or norm(fam).startswith(n) and len(n) >= 4:
            return fam, True
    return None, False


FONT_MARK = "# theme reach font"


def ghostty_font(reload=False):
    """Keep the chosen font as a marked block at the end of ~/.config/ghostty/theme.conf (which Ghostty's
    config includes). The bar's own ghostty step rewrites that file on a theme switch; this puts the block back."""
    conf = os.path.join(HOME, ".config/ghostty/theme.conf")
    if not os.path.exists(conf):
        return say("ghostty", "skipped (no theme.conf yet)")
    old = open(conf).read()
    base = old.split(FONT_MARK)[0].rstrip("\n") + "\n"
    fam = state("font")
    text = base + ('%s\nfont-family = ""\nfont-family = "%s"\n' % (FONT_MARK, fam) if fam else "")
    if text != old:
        write_atomic(conf, text)
        if reload and subprocess.run(["/usr/bin/pgrep", "-xq", "ghostty"]).returncode == 0:
            subprocess.run(["/usr/bin/osascript", "-e", 'tell application "Ghostty" to if (count of terminals) > 0 then perform action "reload_config" on terminal 1'], capture_output=True)
    say("ghostty", "font %s%s" % (fam or "default", " (changed)" if text != old else ""))


def vscode_font():
    fam = state("font")
    if not os.path.exists(VSCODE_USER):
        return say("vscode", "font skipped (no settings.json)")
    ch = {"editor.fontFamily": ("'%s', Menlo, monospace" % fam) if fam else None,
          "terminal.integrated.fontFamily": fam}
    try:
        changed = edit_json_keys(VSCODE_USER, ch, 4)
    except ValueError:
        return say("vscode", "BLOCKED settings.json is not plain JSON; set editor.fontFamily and terminal.integrated.fontFamily to %r yourself" % fam)
    say("vscode", "font %s%s" % (fam or "default (keys removed)", " (changed)" if changed else ""))


def font(args):
    names = list(FONTS) + ["default"]
    if args:
        fam, ok = resolve_font(" ".join(args))
        if not ok:
            sys.exit("unknown font '%s'. Choose: %s" % (" ".join(args), ", ".join(names)))
    else:
        if not sys.stdin.isatty() or not shutil.which("fzf", path="/usr/local/bin:" + os.environ.get("PATH", "")):
            cur = state("font") or DEFAULT_FONT
            print("current: " + cur)
            sys.exit("usage: theme.sh font <%s>" % "|".join(names))
        r = subprocess.run(["fzf", "--prompt", "font > "], input="\n".join(names), text=True, stdout=subprocess.PIPE)
        if not r.stdout.strip():
            return
        fam, ok = resolve_font(r.stdout.strip())
    if fam:
        have = glob.glob(os.path.join(HOME, "Library/Fonts", fam.replace(" ", "") + "*")) or \
            glob.glob(os.path.join(HOME, "Library/Fonts", fam.replace(" Nerd Font", "") .replace(" ", "") + "NerdFont*")) or \
            glob.glob("/Library/Fonts/" + fam.replace(" ", "") + "*")
        if not have and fam not in subprocess.run(["/usr/sbin/system_profiler", "SPFontsDataType"], capture_output=True, text=True).stdout:
            sys.exit("%s is not installed. brew bundle --file ~/dotfiles/Brewfile" % fam)
        state("font", fam)
    else:
        state("font", None)
    print("font: %s" % (fam or DEFAULT_FONT + " (default)"))
    ghostty_font(reload=True)
    vscode_font()


# ---- check (read-only; check.sh turns each line into a row) -------------------------------------------------
def check():
    """Prints `target<TAB>rc<TAB>detail`: does each target hold what the active theme calls for?"""
    out = []
    c = palette()
    def row(t, ok, d=""):
        out.append("%s\t%d\t%s" % (t, 0 if ok else 1, d))
    try:
        cur = json.load(open(VSCODE_USER)).get("workbench.colorTheme")
        pick = VSCODE.get(THEME)
        label = vscode_label(pick[1], pick[0]) if pick else None
        want = label or VSCODE_FALLBACK[MODE]
        row("vscode", cur == want, "workbench.colorTheme %r, want %r" % (cur, want))
    except (OSError, ValueError) as e:
        row("vscode", False, str(e))
    try:
        row("claude", claude_theme() in ("auto", MODE), "want theme auto or %s in ~/.claude/settings.json" % MODE)
    except (OSError, ValueError) as e:
        row("claude", False, str(e))
    conf = os.path.join(HOME, ".config/tmux/theme.conf")
    row("tmux", os.path.exists(conf) and ('pane-active-border-style "fg=%s"' % c["accent"]) in open(conf).read(), conf)
    conf = os.path.join(HOME, ".config/git/config")
    row("delta", os.path.exists(conf) and ('"bold %s"' % c["accent"]) in open(conf).read(), conf)
    idx = nearest_accent(c["accent"])[0]
    acc = defaults("read", "-g", "AppleAccentColor").stdout.strip()
    dark = defaults("read", "-g", "AppleInterfaceStyle").stdout.strip() == "Dark"
    row("macos", acc == str(idx) and dark == (MODE == "dark"), "accent %s want %d; dark=%s want %s" % (acc or "unset", idx, dark, MODE == "dark"))
    fam = state("font")
    tc = open(os.path.join(HOME, ".config/ghostty/theme.conf")).read() if os.path.exists(os.path.join(HOME, ".config/ghostty/theme.conf")) else ""
    try:
        vs = json.load(open(VSCODE_USER))
    except (OSError, ValueError):
        vs = {}
    ok = (('font-family = "%s"' % fam) in tc and vs.get("terminal.integrated.fontFamily") == fam) if fam else (FONT_MARK not in tc and "terminal.integrated.fontFamily" not in vs)
    row("font", ok, fam or "default")
    imgs = wall_images()
    row("bg", bool(imgs), "%d picture(s) in themes/backgrounds/%s" % (len(imgs), wall_dir()))
    print("\n".join(out))


def main():
    a = sys.argv[1:]
    cmd = a[0] if a else "apply"
    if cmd == "apply":
        apply()
    elif cmd == "check":
        check()
    elif cmd == "bg":
        bg(a[1:])
    elif cmd == "font":
        font(a[1:])
    elif cmd == "ghostty-font":
        ghostty_font(reload=True)
    elif cmd == "vscode-font":
        vscode_font()
    elif cmd in ("vscode", "claude", "tmux", "delta", "macos"):
        globals()[cmd]()
    else:
        sys.exit("usage: reach.py apply|bg|font|vscode|claude|tmux|delta|macos")


if __name__ == "__main__":
    main()
