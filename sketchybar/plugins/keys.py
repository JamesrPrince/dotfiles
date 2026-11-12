#!/usr/bin/python3
"""Key-binding cheat sheet for the SketchyBar 'keys' popups.

Reads ~/.aerospace.toml on every rebuild, so the sheet always matches the config.
Every binding lands somewhere: a command this script does not recognise is filed
by its first word, and as a last resort listed under Layout with the raw command.

  keys.py                rebuild the popups (run at bar load)
  keys.py toggle         rebuild, then show or hide the popups
  keys.py close          hide the popups
  keys.py scroll         mouse.scrolled handler: one page per swipe (reads $INFO)
  keys.py tab <Name>     jump to a section's page
  keys.py page next|prev|<n>
  keys.py check          verify every binding of the config appears in the sheet

The list is paged because SketchyBar popups cannot scroll and the full list is
taller than the screen. Layout: `keys.tabs` (a horizontal strip with the tabs and
the page indicator) sits above `keys` (the rows of the current page).
"""
import json
import os
import re
import subprocess
import sys
import time

HOME = os.path.expanduser("~")
CONFIG = HOME + "/.aerospace.toml"
CACHE_DIR = HOME + "/.cache"
APPS_CACHE = CACHE_DIR + "/sketchybar-keys-apps.json"
PAGES_FILE = CACHE_DIR + "/sketchybar-keys-pages.json"   # the built pages
STATE_FILE = CACHE_DIR + "/sketchybar-keys-state.json"   # page offset + last scroll time
SELF = HOME + "/.config/sketchybar/plugins/keys.py"
SKETCHYBAR = "/usr/local/bin/sketchybar"
FONT = "Nunito"

PAGE_LINES = 20          # rows per page (headers count); small enough that tabs get their own pages
KEY_WIDTH = 104          # fixed width of the key column, so descriptions line up
TABS_HEIGHT = 26
TABS_GAP = 10            # space between the tab strip and the rows popup
SCROLL_GAP = 0.25        # seconds of quiet that separate two swipes


def theme_colors():
    """Accent, text, dim, tab and active-tab colours of the active bar theme (colors.sh)."""
    try:
        out = subprocess.run(
            ["/bin/bash", "-c", 'source "$HOME/.config/sketchybar/colors.sh"; echo $BLUE $WHITE $GREY $BACKGROUND_2 $ACCENT_FILL'],
            capture_output=True, text=True, timeout=2).stdout.split()
        if len(out) == 5:
            return out
    except Exception:
        pass
    return ["0xff8aadf4", "0xffcad3f5", "0xff939ab7", "0x90494d64", "0x408aadf4"]


ACCENT, TEXT, DIM, TAB_BG, TAB_ACTIVE = theme_colors()

MODS = {"ctrl": "⌃", "alt": "⌥", "shift": "⇧", "cmd": "⌘"}
KEYS = {"backtick": "`", "slash": "/", "comma": ",", "minus": "-", "equal": "=",
        "semicolon": ";", "period": ".", "tab": "Tab", "esc": "Esc",
        "backspace": "⌫", "enter": "↩", "space": "Space",
        "left": "←", "right": "→", "up": "↑", "down": "↓"}

# The tabs, in order. Each is a section of the sheet.
TABS = ["Switch", "Rearrange", "Layout", "Apps", "Modes"]
HIDDEN_WORKSPACE = "S"   # the scratchpad workspace (see workspaces.conf)


def parse_bindings():
    """Return {mode: [(key, [commands])]} from every [mode.X.binding] table."""
    modes, mode = {}, None
    with open(CONFIG, encoding="utf-8") as f:
        for raw in f:
            line = raw.strip()
            m = re.match(r"^\[mode\.([\w-]+)\.binding\]$", line)
            if m:
                mode = m.group(1)
                modes.setdefault(mode, [])
                continue
            if line.startswith("["):
                mode = None
                continue
            if not mode or not line or line.startswith("#"):
                continue
            m = re.match(r"^([\w-]+)\s*=\s*(.+?)\s*(#.*)?$", line)
            if m:
                parts = re.findall(r"'([^']*)'|\"([^\"]*)\"", m.group(2))
                modes[mode].append((m.group(1), [a or b for a, b in parts]))
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


def ws(name):
    return "scratchpad" if name == HIDDEN_WORKSPACE else name


def describe(cmds, cache):
    """Map a binding's commands to (section, description).

    Sections: Switch, Rearrange, Layout, Apps; 'Service' and 'Resize' are the
    mode-only commands (listed under Modes, or under Layout if bound in main).
    Anything unrecognised is filed by its first word, so a binding never vanishes."""
    # Bar refresh triggers and the way back to main are plumbing, not what the key does
    cmds = [c for c in cmds if c != "mode main" and "sketchybar --trigger" not in c]
    c = " ".join(cmds).strip()
    if m := re.match(r"exec-and-forget open (?:-\w+ )*-b (\S+)", c):
        return "Apps", app_name(m.group(1).strip("'\""), cache)
    if m := re.match(r"exec-and-forget open (?:-\w+ )*-a (?:\"([^\"]+)\"|'([^']+)'|(\S+))", c):
        return "Apps", m.group(1) or m.group(2) or m.group(3)
    if "dfs-next" in c:
        return "Switch", "Next window"
    if "dfs-prev" in c:
        return "Switch", "Previous window"
    if m := re.match(r"focus (?:--\S+ \S+ )*(\w+)$", c):
        return "Switch", "Focus " + m.group(1)
    if c == "workspace-back-and-forth":
        return "Switch", "Last workspace"
    if m := re.match(r"workspace (?:--\S+ )*(\w+)$", c):
        return "Switch", ("Scratchpad" if m.group(1) == HIDDEN_WORKSPACE else "Workspace " + m.group(1))
    if m := re.match(r"move (?:--\S+ \S+ )*(\w+)$", c):
        return "Rearrange", "Move window " + m.group(1)
    if m := re.match(r"swap (?:--\S+ )*([\w-]+)$", c):
        return "Rearrange", "Swap with " + {"dfs-next": "next", "dfs-prev": "previous"}.get(m.group(1), m.group(1))
    if m := re.match(r"move-node-to-workspace --focus-follows-window (\w+)$", c):
        return "Rearrange", "Take window to " + ws(m.group(1))
    if m := re.match(r"move-node-to-workspace (?:--\S+ )*(\w+)$", c):
        return "Rearrange", "Send window to " + ws(m.group(1))
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
    if m := re.match(r"mode (\w+)$", c):
        return "Layout", m.group(1).capitalize() + " mode"
    if m := re.match(r"resize (width|height) ([+-])", c):
        grow = m.group(2) == "+"
        return "Resize", (("Wider" if grow else "Narrower") if m.group(1) == "width"
                          else ("Taller" if grow else "Shorter"))
    if c == "balance-sizes":
        return "Service", "Equal sizes"
    if c == "":
        return "Resize", "Done"
    if m := re.search(r"scratchpad\S*\s+(send|bring|toggle)\b", c):
        return "Rearrange", {"send": "Send window to scratchpad", "bring": "Bring scratchpad window back",
                             "toggle": "Toggle scratchpad"}[m.group(1)]
    if "theme.sh next" in c:
        return "Layout", "Next bar theme"
    if "cheat sheet" in c or "keys.py" in c:
        return "Layout", "This cheat sheet"
    # Unknown command: file it by its first word and show it as written
    shown = re.sub(r"^exec-and-forget\s+", "", c)
    shown = shown if len(shown) <= 34 else shown[:33] + "…"
    first = c.split()[0]
    if "scratch" in c.lower():
        return "Rearrange", shown
    if first in ("move", "swap", "move-node-to-workspace", "move-workspace-to-monitor", "join-with", "resize"):
        return "Rearrange", shown
    if first in ("focus", "workspace", "focus-monitor", "summon-workspace"):
        return "Switch", shown
    if re.match(r"exec-and-forget\s+open\b", c):
        return "Apps", shown
    return "Layout", shown


def collapse_numbers(rows):
    """Fold ⌥1 … ⌥5 'Workspace N' rows into one '⌥1–5' row."""
    out, groups = [], {}
    for key, desc in rows:
        m = re.match(r"^(.*?)(\d)$", key)
        d = re.match(r"^(.*?)(\d)$", desc)
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


def merge_same(rows):
    """Rows with the same description share one row: 'H ←' for two keys, one action."""
    out = {}
    for key, desc in rows:
        out.setdefault(desc, []).append(key)
    return [(" ".join(keys), desc) for desc, keys in out.items()]


def build_sections():
    """Return {tab: [(kind, key, text, tab)]}: kind 'h' for a header, 'r' for a row."""
    try:
        with open(APPS_CACHE, encoding="utf-8") as f:
            cache = json.load(f)
    except (OSError, ValueError):
        cache = {}
    modes = parse_bindings()
    grouped = {t: [] for t in TABS}
    entry_key = {}            # mode name -> the main-mode key that enters it
    for key, cmds in modes.get("main", []):
        section, desc = describe(cmds, cache)
        grouped[section if section in grouped else "Layout"].append((pretty_key(key), desc))
        for c in cmds:
            if (m := re.match(r"mode (\w+)$", c)) and m.group(1) != "main":
                entry_key[m.group(1)] = pretty_key(key)
    grouped["Apps"].sort(key=lambda r: r[0])

    sections = {}
    for tab in TABS:
        if tab == "Modes":
            continue
        rows = collapse_numbers(grouped[tab])
        if rows:
            sections[tab] = [("h", "", tab, tab)] + [("r", k, d, tab) for k, d in rows]

    # Modes: every [mode.X.binding] table except main, in file order
    lines = []
    for mode, bindings in modes.items():
        if mode == "main" or not bindings:
            continue
        rows = [(pretty_key(k), describe(c, cache)[1]) for k, c in bindings]
        title = "%s mode" % mode.capitalize()
        if mode in entry_key:
            title += " (%s then)" % entry_key[mode]
        lines.append(("h", "", title, "Modes"))
        lines += [("r", k, d, "Modes") for k, d in merge_same(rows)]
    if lines:
        sections["Modes"] = lines

    os.makedirs(CACHE_DIR, exist_ok=True)
    with open(APPS_CACHE, "w", encoding="utf-8") as f:
        json.dump(cache, f)
    return sections


def paginate(sections):
    """Pack sections into pages of at most PAGE_LINES rows. A block (a section, or one
    mode of Modes) starts on the current page if it fits, otherwise on a new one; one
    longer than a page is split, and the next part repeats the header as '(cont.)'.
    Returns (pages, tab -> first page)."""
    pages, cur, first = [], [], {}
    for tab in TABS:
        lines = sections.get(tab)
        if not lines:
            continue
        blocks, blk = [], []
        for ln in lines:
            if ln[0] == "h" and blk:
                blocks.append(blk)
                blk = []
            blk.append(ln)
        blocks.append(blk)
        for blk in blocks:
            free = PAGE_LINES - len(cur)
            if cur and len(blk) > free and (len(blk) <= PAGE_LINES or free < 4):
                pages.append(cur)
                cur = []
            first.setdefault(tab, len(pages))
            head, body = blk[0], blk[1:]
            cur.append(head)
            while body:
                room = PAGE_LINES - len(cur)
                if room <= 0:
                    pages.append(cur)
                    cur = [("h", "", head[2] + " (cont.)", tab)]
                    room = PAGE_LINES - 1
                cur += body[:room]
                body = body[room:]
    if cur:
        pages.append(cur)
    return pages, first


def load_pages():
    with open(PAGES_FILE, encoding="utf-8") as f:
        return json.load(f)


def load_state():
    try:
        with open(STATE_FILE, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def save_state(state):
    os.makedirs(CACHE_DIR, exist_ok=True)
    with open(STATE_FILE, "w", encoding="utf-8") as f:
        json.dump(state, f)


def sbar(args):
    return subprocess.run([SKETCHYBAR] + args, capture_output=True, text=True)


def render(page_index=None):
    """Write a page (default: the saved one) into the row slots and the tab strip."""
    data = load_pages()
    pages, first = data["pages"], data["first"]
    n = len(pages)
    if n == 0:
        return
    state = load_state()
    p = (state.get("page", 0) if page_index is None else page_index) % n
    state["page"] = p
    save_state(state)
    lines = pages[p]
    tabs_here = {ln[3] for ln in lines}
    args = []
    for i in range(data["slots"]):
        name = "keys.row.%03d" % i
        if i < len(lines):
            kind, key, text, _tab = lines[i]
            if kind == "h":
                args += ["--set", name, "drawing=on", "icon.drawing=off", "label=" + text,
                         "label.font=%s:Bold:13.0" % FONT, "label.color=" + ACCENT,
                         "label.padding_left=6", "label.padding_right=6"]
            else:
                args += ["--set", name, "drawing=on", "icon.drawing=on", "icon=" + key,
                         "icon.font=%s:Bold:12.5" % FONT, "icon.color=" + TEXT,
                         "icon.width=%d" % KEY_WIDTH, "icon.align=left",
                         "icon.padding_left=6", "icon.padding_right=0",
                         "label=" + text, "label.font=%s:Regular:12.5" % FONT,
                         "label.color=" + TEXT, "label.padding_left=0", "label.padding_right=10"]
        else:
            args += ["--set", name, "drawing=off"]
    for tab in TABS:
        if tab in first:
            on = tab in tabs_here
            args += ["--set", "keys.tab." + tab, "label.color=" + (ACCENT if on else DIM),
                     "background.color=" + (TAB_ACTIVE if on else "0x00000000")]
    args += ["--set", "keys.tab.page", "label=%d/%d" % (p + 1, n)]
    sbar(args)


def build():
    """Parse the config, store the pages, and (re)create the popup items."""
    pages, first = paginate(build_sections())
    slots = max([len(p) for p in pages] + [1])
    os.makedirs(CACHE_DIR, exist_ok=True)
    with open(PAGES_FILE, "w", encoding="utf-8") as f:
        json.dump({"pages": pages, "first": first, "slots": slots}, f)
    state = load_state()
    state["page"] = min(state.get("page", 0), max(len(pages) - 1, 0))
    save_state(state)

    run = "/usr/bin/python3 " + SELF
    args = ["--remove", "/keys\\.row\\..*/", "--remove", "/keys\\.tab\\..*/"]
    for i in range(slots):
        name = "keys.row.%03d" % i
        args += ["--add", "item", name, "popup.keys",
                 "--set", name, "drawing=off", "padding_left=6", "padding_right=6",
                 "background.drawing=off",
                 "script=%s scroll" % run, "click_script=%s close" % run,
                 "--subscribe", name, "mouse.scrolled"]
    for tab in [t for t in TABS if t in first] + ["page"]:
        name = "keys.tab." + tab
        args += ["--add", "item", name, "popup.keys.tabs",
                 "--set", name, "icon.drawing=off", "label=" + ("" if tab == "page" else tab),
                 "label.font=%s:SemiBold:12.5" % FONT, "label.color=" + DIM,
                 "label.padding_left=8", "label.padding_right=8",
                 "padding_left=1", "padding_right=1", "background.height=20",
                 "background.corner_radius=6", "background.drawing=on",
                 "background.color=0x00000000",
                 "script=%s scroll" % run,
                 "click_script=%s %s" % (run, "page next" if tab == "page" else "tab " + tab),
                 "--subscribe", name, "mouse.scrolled"]
    sbar(args)
    sbar(["--set", "keys.tab.page", "label.color=" + TEXT, "label.font=%s:Bold:12.5" % FONT])
    render()


def popup_open():
    """Read the popup state before any rebuild: right after the rows are re-added,
    a query can come back empty and the popup would never close."""
    for _ in range(5):
        try:
            return json.loads(sbar(["--query", "keys"]).stdout)["popup"]["drawing"] == "on"
        except (ValueError, KeyError):
            time.sleep(0.05)
    return False


def set_popups(on):
    if on:
        drop = TABS_HEIGHT + TABS_GAP + 6
        # slide both down into place, as plugins/popup.sh does for the other popups
        sbar(["--set", "keys.tabs", "popup.y_offset=-12", "popup.drawing=on",
              "--set", "keys", "popup.y_offset=%d" % (drop - 12), "popup.drawing=on",
              "--animate", "tanh", "15",
              "--set", "keys.tabs", "popup.y_offset=0",
              "--set", "keys", "popup.y_offset=%d" % drop])
    else:
        sbar(["--set", "keys.tabs", "popup.drawing=off", "--set", "keys", "popup.drawing=off"])


def scroll():
    """mouse.scrolled: one page per swipe. The events of one swipe (and its momentum)
    arrive in a burst; only the first after a quiet gap turns the page."""
    state = load_state()
    now = time.time()
    quiet = now - state.get("last", 0) > SCROLL_GAP
    state["last"] = now
    save_state(state)
    if not quiet:
        return
    delta = os.environ.get("SCROLL_DELTA", "")
    if not delta:
        try:
            delta = json.loads(os.environ.get("INFO", "{}")).get("delta", 0)
        except ValueError:
            delta = 0
    try:
        delta = float(delta)
    except ValueError:
        delta = 0
    if delta == 0:
        return
    # content follows the fingers: delta < 0 is "scroll down", the next page
    render(load_state().get("page", 0) + (1 if delta < 0 else -1))


def check():
    """Print every binding of the config and whether the built sheet shows it."""
    pages = load_pages()["pages"]
    shown = []
    for page in pages:
        for kind, key, _text, _tab in page:
            if kind == "r":
                shown += key.split(" ")
                if m := re.match(r"^(.*?)(\d)–(\d)$", key):
                    shown += [m.group(1) + str(d) for d in range(int(m.group(2)), int(m.group(3)) + 1)]
    total = missing = 0
    for mode, bindings in parse_bindings().items():
        for key, _cmds in bindings:
            total += 1
            ok = pretty_key(key) in shown
            missing += not ok
            print("%-8s %-20s %s" % (mode, pretty_key(key), "ok" if ok else "MISSING"))
    print("%d bindings, %d missing, %d pages" % (total, missing, len(pages)))
    sys.exit(1 if missing else 0)


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "build"
    if cmd == "scroll":
        scroll()
    elif cmd == "tab":
        render(load_pages()["first"].get(sys.argv[2], 0))
    elif cmd == "page":
        arg = sys.argv[2]
        cur = load_state().get("page", 0)
        render(cur + 1 if arg == "next" else cur - 1 if arg == "prev" else int(arg))
    elif cmd == "close":
        set_popups(False)
    elif cmd == "toggle":
        if popup_open():
            set_popups(False)
            return
        build()
        render(0)
        set_popups(True)
    elif cmd == "check":
        check()
    else:
        build()


if __name__ == "__main__":
    main()
