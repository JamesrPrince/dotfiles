#!/usr/bin/python3
"""World clock popup for SketchyBar, after Omarchy 4.5's Elsewhen (shell/plugins/panels/elsewhen).

Ported from Elsewhen's Model.js: the first-run seed (home plus four well-known cities, each at
least three hours from home and from each other, sorted eastward), the offset labels (+2h, or
UTC+2 after a click), the date and day labels, the WMO weather glyphs, and Open-Meteo for the
weather (no key, cached 20 minutes, fetched only when the popup opens).

Run by plugins/worldclock.sh, which exports the theme colours. State (cities and settings) is
~/.config/sketchybar/.worldclock.json, git-ignored; edit "cities" there to change the list.
"""
import json
import os
import subprocess
import sys
import time
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from zoneinfo import ZoneInfo

STATE = os.path.expanduser("~/.config/sketchybar/.worldclock.json")
CACHE = os.path.join(os.environ.get("TMPDIR", "/tmp"), "sketchybar_worldclock_weather.json")
WEATHER_TTL = 20 * 60
ITEM = "worldclock"
SB = "/usr/local/bin/sketchybar"
if not os.path.exists(SB):
    SB = "/opt/homebrew/bin/sketchybar"

MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
WEEKDAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

# Elsewhen's SEED_CANDIDATES: (label, zone, rank), rank 1 best known
SEED_CANDIDATES = [
    ("Honolulu", "Pacific/Honolulu", 3), ("Anchorage", "America/Anchorage", 3),
    ("Los Angeles", "America/Los_Angeles", 2), ("Vancouver", "America/Vancouver", 3),
    ("Mexico City", "America/Mexico_City", 3), ("Chicago", "America/Chicago", 3),
    ("New York", "America/New_York", 1), ("Sao Paulo", "America/Sao_Paulo", 2),
    ("Buenos Aires", "America/Argentina/Buenos_Aires", 3), ("Reykjavik", "Atlantic/Reykjavik", 3),
    ("London", "Europe/London", 1), ("Lisbon", "Europe/Lisbon", 3), ("Paris", "Europe/Paris", 1),
    ("Berlin", "Europe/Berlin", 3), ("Madrid", "Europe/Madrid", 3), ("Rome", "Europe/Rome", 3),
    ("Cairo", "Africa/Cairo", 3), ("Johannesburg", "Africa/Johannesburg", 3),
    ("Istanbul", "Europe/Istanbul", 3), ("Moscow", "Europe/Moscow", 3),
    ("Nairobi", "Africa/Nairobi", 3), ("Dubai", "Asia/Dubai", 2), ("Karachi", "Asia/Karachi", 3),
    ("Delhi", "Asia/Kolkata", 2), ("Bangkok", "Asia/Bangkok", 3), ("Jakarta", "Asia/Jakarta", 3),
    ("Singapore", "Asia/Singapore", 2), ("Hong Kong", "Asia/Hong_Kong", 2),
    ("Shanghai", "Asia/Shanghai", 2), ("Perth", "Australia/Perth", 3), ("Seoul", "Asia/Seoul", 3),
    ("Tokyo", "Asia/Tokyo", 1), ("Sydney", "Australia/Sydney", 2), ("Auckland", "Pacific/Auckland", 3),
]
DAY_MIN = 1440

# Elsewhen's weather glyphs (Material Design Icons): sunny is white-balance-sunny on purpose
GLYPHS = {"sunny": "\U000F05A8", "partly": "\U000F0595", "cloudy": "\U000F0590",
          "rain": "\U000F0597", "snow": "\U000F0598"}

ENV = os.environ
WHITE = ENV.get("WHITE", "0xffffffff")
GREY = ENV.get("GREY", "0xff888888")
DIM = "0xb3" + WHITE[4:]            # secondary text
FAINT = "0x80" + WHITE[4:]          # tertiary text
FLAT = ENV.get("BAR_STYLE") == "flat"
TEXT_FONT = ENV.get("TEXT_FONT", "Nunito")
NF = "Maple Mono NF"
STRIP_CELLS = 40                    # the daylight strip, 36 minutes a cell


# ---- state -------------------------------------------------------------------------------------

def home_zone():
    try:
        p = os.path.realpath("/etc/localtime")
        return p.split("zoneinfo/", 1)[1]
    except Exception:
        return "UTC"


def offset_min(zone, now=None):
    now = now or datetime.now(timezone.utc)
    return int(now.astimezone(ZoneInfo(zone)).utcoffset().total_seconds() // 60)


def seed(home):
    """Elsewhen's pickSeedZones: four cities, gap 3h, relaxing to 2h then 1h, sorted eastward."""
    home_label = home.split("/")[-1].replace("_", " ")
    h = offset_min(home)

    def dial(a, b):
        d = abs(a - b) % DAY_MIN
        return min(d, DAY_MIN - d)

    picked = []
    for gap in (180, 120, 60):
        picked = []
        for rank in (1, 2, 3):
            for label, zone, r in SEED_CANDIDATES:
                if r != rank or len(picked) >= 4 or zone == home or label.lower() == home_label.lower():
                    continue
                east = (offset_min(zone) - h) % DAY_MIN
                if min(east, DAY_MIN - east) < gap or any(dial(p[2], east) < gap for p in picked):
                    continue
                picked.append((label, zone, east))
        if len(picked) >= 4:
            break
    picked.sort(key=lambda p: p[2])
    return [{"name": home_label, "zone": home}] + [{"name": l, "zone": z} for l, z, _ in picked]


def load_state():
    try:
        with open(STATE) as f:
            st = json.load(f)
    except Exception:
        st = {}
    if not st.get("cities"):
        st["cities"] = seed(home_zone())
        st.setdefault("hour24", True)          # the bar's own clock is 24-hour
        st.setdefault("offsetMode", "home")
        st.setdefault("units", "F" if ENV.get("APPLE_LOCALE", "").endswith("_US") else "C")
        save_state(st)
    return st


def save_state(st):
    tmp = STATE + ".tmp"
    with open(tmp, "w") as f:
        json.dump(st, f, indent=2, ensure_ascii=False)
    os.replace(tmp, STATE)


# ---- weather (Open-Meteo, no key) ----------------------------------------------------------------

def fetch_json(url):
    req = urllib.request.Request(url, headers={"User-Agent": "sketchybar-worldclock"})
    with urllib.request.urlopen(req, timeout=10) as r:
        return json.load(r)


def geocode(city):
    """By the city's name, preferring a match on the same zone (Elsewhen geocodes by label)."""
    q = urllib.parse.urlencode({"name": city["name"], "count": 10, "format": "json"})
    res = fetch_json("https://geocoding-api.open-meteo.com/v1/search?" + q).get("results") or []
    same = [r for r in res if r.get("timezone") == city["zone"]]
    pick = (same or res or [None])[0]
    if pick:
        city["lat"], city["lon"] = round(pick["latitude"], 5), round(pick["longitude"], 5)


def refresh_weather(st, force=False):
    cache = read_cache()
    if not force and time.time() - cache.get("t", 0) < WEATHER_TTL and \
            all(key(c) in cache.get("data", {}) for c in st["cities"]):
        return False
    changed = False
    for c in st["cities"]:
        if "lat" not in c:
            try:
                geocode(c)
                changed = True
            except Exception:
                pass
    if changed:
        save_state(st)
    placed = [c for c in st["cities"] if "lat" in c]
    if not placed:
        return False
    q = urllib.parse.urlencode({
        "latitude": ",".join(str(c["lat"]) for c in placed),
        "longitude": ",".join(str(c["lon"]) for c in placed),
        "current": "temperature_2m,weather_code",
        "daily": "sunrise,sunset", "timezone": "auto", "forecast_days": 1,
    })
    try:
        out = fetch_json("https://api.open-meteo.com/v1/forecast?" + q)
    except Exception:
        return False                       # keep the previous reading
    out = out if isinstance(out, list) else [out]
    data = cache.get("data", {})
    for c, o in zip(placed, out):
        cur, daily = o.get("current") or {}, o.get("daily") or {}
        data[key(c)] = {"c": cur.get("temperature_2m"), "w": cur.get("weather_code"),
                        "sunrise": (daily.get("sunrise") or [None])[0],
                        "sunset": (daily.get("sunset") or [None])[0]}
    with open(CACHE, "w") as f:
        json.dump({"t": time.time(), "data": data}, f)
    return True


def read_cache():
    try:
        with open(CACHE) as f:
            return json.load(f)
    except Exception:
        return {}


def key(c):
    return c["name"] + "|" + c["zone"]


def weather_kind(code):
    """Elsewhen's weatherKind: WMO codes to five glyphs. A missing code is not 0 (clear)."""
    if code is None or code == "":
        return ""
    c = int(code)
    if c <= 1: return "sunny"
    if c == 2: return "partly"
    if c in (3, 45, 48): return "cloudy"
    if 71 <= c <= 77 or c in (85, 86): return "snow"
    if 51 <= c <= 67 or 80 <= c <= 82 or 95 <= c <= 99: return "rain"
    return ""


def temp_label(fact, units):
    if not fact or fact.get("c") is None:
        return ""
    c = fact["c"]
    return f"{round(c)}°C" if units == "C" else f"{round(c * 9 / 5 + 32)}°F"


# ---- rows ----------------------------------------------------------------------------------------

def utc_label(m):
    if m == 0:
        return "UTC"
    h, mm = divmod(abs(m), 60)
    return "UTC" + ("-" if m < 0 else "+") + str(h) + (f":{mm:02d}" if mm else "")


def relative_label(m, home_m):
    d = m - home_m
    if d == 0:
        return ""
    hours = round(d / 60, 1)
    hours = int(hours) if hours == int(hours) else hours
    return ("+" if d > 0 else "") + f"{hours}h"


def day_label(delta):
    if delta == 0: return ""
    if delta == 1: return "Tomorrow"
    if delta == -1: return "Yesterday"
    n = abs(delta)
    return ("+" if delta > 0 else "-") + f"{n} day" + ("" if n == 1 else "s")


def fmt_time(t, hour24):
    if hour24:
        return t.strftime("%H:%M")
    return f"{t.hour % 12 or 12}:{t.minute:02d} " + ("AM" if t.hour < 12 else "PM")


def frac(iso):
    """'2026-11-17T05:32' -> fraction of the day, in that city's own clock."""
    try:
        hh, mm = iso.split("T")[1].split(":")[:2]
        return (int(hh) * 60 + int(mm)) / DAY_MIN
    except Exception:
        return None


def strip(progress, fact):
    """24 hours, midnight to midnight: daylight thick, night thin. The marker at now is a sun
    inside the lit band and a moon outside it (SketchyBar gives a label one colour, so the
    shape carries what Elsewhen's gold and white marker does)."""
    sr = frac((fact or {}).get("sunrise") or "")
    ss = frac((fact or {}).get("sunset") or "")
    if sr is None or ss is None:
        sr, ss = 6 / 24, 18 / 24           # Elsewhen's band until the city is placed
    now_cell = min(STRIP_CELLS - 1, int(progress * STRIP_CELLS))
    cells = []
    for i in range(STRIP_CELLS):
        mid = (i + 0.5) / STRIP_CELLS
        lit = sr <= mid <= ss if sr <= ss else (mid >= sr or mid <= ss)
        cells.append("━" if lit else "╌")
    marker = GLYPHS["sunny"] if sr <= progress <= ss else "\U000F0594"   # weather-night
    cells[now_cell] = marker
    return "".join(cells)


# ---- drawing -------------------------------------------------------------------------------------

def sb(*args):
    subprocess.run([SB, *args], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def popup_open():
    try:
        out = subprocess.run([SB, "--query", ITEM], capture_output=True, text=True).stdout
        return json.loads(out)["popup"]["drawing"] == "on"
    except Exception:
        return False


def render(st):
    now = datetime.now(timezone.utc)
    home = home_zone()
    home_t = now.astimezone(ZoneInfo(home))
    home_m = offset_min(home, now)
    hour24, units, mode = st.get("hour24", True), st.get("units", "C"), st.get("offsetMode", "home")
    facts = read_cache().get("data", {})
    here = next((c["name"] for c in st["cities"] if c["zone"] == home), home.split("/")[-1].replace("_", " "))
    plugin = os.path.expanduser("~/.config/sketchybar/plugins/worldclock.sh")
    pad = ["padding_left=12", "padding_right=14"]
    if FLAT:
        pad += ["background.corner_radius=4"]
    W_LEFT, W_RIGHT = 190, 100

    a = ["--remove", "/worldclock\\..*/"]
    a += ["--add", "item", "worldclock.head", "popup." + ITEM, "--set", "worldclock.head", *pad,
          "icon.drawing=off", f"label=It's {fmt_time(home_t, hour24)} here in {here}",
          f"label.font={TEXT_FONT}:Bold:13.0", f"label.color={WHITE}",
          "background.padding_bottom=4", f"click_script={plugin} toggle hour24"]

    for i, c in enumerate(st["cities"]):
        try:
            tz = ZoneInfo(c["zone"])
        except Exception:
            continue
        t = now.astimezone(tz)
        m = int(t.utcoffset().total_seconds() // 60)
        delta = (t.date() - home_t.date()).days
        fact = facts.get(key(c))
        kind = weather_kind((fact or {}).get("w"))
        temp = temp_label(fact, units)
        when = f"{WEEKDAYS[t.weekday()]} {MONTHS[t.month - 1]} {t.day}"
        dl = day_label(delta)
        info = "  ".join(x for x in [(temp + (" " + GLYPHS[kind] if kind else "")).strip(),
                                       when + (" · " + dl if dl else "")] if x)
        rel = relative_label(m, home_m)
        offset = (t.tzname() + (" " + rel if rel else "")) if mode == "home" else utc_label(m)
        n = f"worldclock.c{i}"
        a += ["--add", "item", n + ".a", "popup." + ITEM, "--set", n + ".a", *pad,
              f"icon={c['name']}", f"icon.font={TEXT_FONT}:Bold:13.0", f"icon.color={WHITE}",
              f"icon.width={W_LEFT}", f"label={fmt_time(t, hour24)}", f"label.font={TEXT_FONT}:Bold:16.0",
              f"label.color={WHITE}", f"label.width={W_RIGHT}", "label.align=right",
              f"click_script={plugin} toggle hour24"]
        a += ["--add", "item", n + ".b", "popup." + ITEM, "--set", n + ".b", *pad,
              f"icon={info}", f"icon.font={NF}:Regular:11.0", f"icon.color={DIM}", f"icon.width={W_LEFT}",
              f"label={offset}", f"label.font={NF}:Regular:11.0", f"label.color={FAINT}",
              f"label.width={W_RIGHT}", "label.align=right", f"click_script={plugin} toggle offset"]
        a += ["--add", "item", n + ".s", "popup." + ITEM, "--set", n + ".s", *pad,
              "icon.drawing=off", f"label={strip((t.hour * 60 + t.minute) / DAY_MIN, fact)}",
              f"label.font={NF}:Regular:9.0", f"label.color={DIM}", "background.padding_bottom=6",
              f"click_script={plugin} toggle units"]
    sb(*a)


# ---- entry ---------------------------------------------------------------------------------------

def refresh_in_background(force=False):
    subprocess.Popen([sys.executable, "-I", __file__, "--weather"] + (["force"] if force else []),
                     env=dict(ENV), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                     start_new_session=True)


def main():
    argv = sys.argv[1:]
    st = load_state()
    if argv[:1] == ["--weather"]:
        if refresh_weather(st, force="force" in argv) and popup_open():
            render(st)
        return
    if argv[:1] == ["toggle"]:
        what = argv[1] if len(argv) > 1 else ""
        if ENV.get("MODIFIER") == "shift" or what == "units":
            st["units"] = "F" if st.get("units", "C") == "C" else "C"
        elif what == "offset":
            st["offsetMode"] = "utc" if st.get("offsetMode", "home") == "home" else "home"
        else:
            st["hour24"] = not st.get("hour24", True)
        save_state(st)
        render(st)
        return
    if ENV.get("SENDER") != "mouse.clicked":
        return
    plugin_dir = os.path.expanduser("~/.config/sketchybar/plugins")
    if ENV.get("BUTTON") in ("right", "middle"):
        refresh_in_background(force=True)
        return
    if popup_open():
        subprocess.run([os.path.join(plugin_dir, "popup.sh"), ITEM, "off"])
        return
    render(st)
    subprocess.run([os.path.join(plugin_dir, "popup.sh"), ITEM, "on"])
    refresh_in_background()


if __name__ == "__main__":
    main()
