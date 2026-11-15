#!/usr/bin/env bash
# market_fetch.sh - keyless BTC/USD and XAU/USD quotes for the bar.
#
# Usage: market_fetch.sh [max_age_seconds]     (default 30; 0 = always fetch)
# Output, one line per symbol in market.conf order, tab separated:
#   SYMBOL<TAB>price<TAB>change_percent<TAB>epoch_of_quote[<TAB>stale]
#   price: plain decimal USD. change_percent: signed decimal, 24h (BTC) or
#   session (XAU); the literal NA if the source gave none. epoch_of_quote:
#   unix seconds when the quote was fetched. 5th field "stale" only when the
#   network failed and an older cached quote is served. No line when there is
#   nothing. Always exits 0, never writes to stderr.
# Env: MARKET_CONF (default: ../market.conf next to this script),
#      MARKET_CACHE (default ${TMPDIR:-/tmp}/sketchybar-market.cache),
#      MARKET_TEST_BASE (test only: replaces scheme+host of every URL).
# Sources (no key, no account): BTC Coinbase Exchange /stats (fallback Binance);
# XAU gold-api.com spot (fallback Yahoo GC=F), change from Yahoo GC=F.
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export MARKET_CONF="${MARKET_CONF:-$here/../market.conf}"
export MARKET_CACHE="${MARKET_CACHE:-${TMPDIR:-/tmp}/sketchybar-market.cache}"
exec /usr/bin/python3 -I - "${1:-30}" 2>/dev/null <<'PY'
import json, os, sys, time, urllib.request

try:
    MAX_AGE = float(sys.argv[1])
except Exception:
    MAX_AGE = 30.0
CONF = os.environ["MARKET_CONF"]
CACHE = os.environ["MARKET_CACHE"]
TEST_BASE = os.environ.get("MARKET_TEST_BASE", "")
UA = "Mozilla/5.0 (Macintosh) market-watch/1.0"
TIMEOUT = 5
DEADLINE = time.time() + 6  # whole run, all symbols

def get(url):
    if TEST_BASE:
        url = TEST_BASE.rstrip("/") + "/" + url.split("://", 1)[1].split("/", 1)[1]
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    left = DEADLINE - time.time()
    if left <= 0.2:
        raise TimeoutError("budget")
    with urllib.request.urlopen(req, timeout=min(TIMEOUT, left)) as r:
        return json.loads(r.read(1 << 20))

def num(x):
    v = float(x)
    if v != v or v in (float("inf"), float("-inf")):
        raise ValueError("nan")
    return v

def pct(last, open_):
    return (last - open_) / open_ * 100.0 if open_ > 0 else None

def btc():
    try:
        d = get("https://api.exchange.coinbase.com/products/BTC-USD/stats")
        last, o = num(d["last"]), num(d["open"])
    except Exception:
        d = get("https://api.binance.com/api/v3/ticker/24hr?symbol=BTCUSDT")
        last, o = num(d["lastPrice"]), num(d["openPrice"])
    if last <= 0:
        raise ValueError("price")
    return last, pct(last, o)

def eth():
    d = get("https://api.exchange.coinbase.com/products/ETH-USD/stats")
    last, o = num(d["last"]), num(d["open"])
    if last <= 0:
        raise ValueError("price")
    return last, pct(last, o)

def gc():
    try:
        d = get("https://query2.finance.yahoo.com/v8/finance/chart/GC=F?interval=1d&range=2d")
    except Exception:
        d = get("https://query1.finance.yahoo.com/v8/finance/chart/GC=F?interval=1d&range=2d")
    m = d["chart"]["result"][0]["meta"]
    return num(m["regularMarketPrice"]), num(m["regularMarketChangePercent"])

def xau():
    price = chg = None
    try:
        price = num(get("https://api.gold-api.com/price/XAU")["price"])
    except Exception:
        pass
    try:
        gp, gchg = gc()
        chg = gchg
        if price is None:
            price = gp
    except Exception:
        pass
    if price is None or price <= 0:
        raise ValueError("price")
    return price, chg

SOURCES = {"BTC": btc, "ETH": eth, "XAU": xau}

def read_conf():
    syms = []
    try:
        for line in open(CONF):
            s = line.split("#", 1)[0].strip().upper()
            if s and s in SOURCES and s not in syms:
                syms.append(s)
    except Exception:
        pass
    return syms

def read_cache():
    c = {}
    try:
        for line in open(CACHE):
            f = line.rstrip("\n").split("\t")
            if len(f) == 4:
                num(f[1]); int(f[3])
                c[f[0]] = f
    except Exception:
        pass
    return c

def write_cache(c):
    try:
        tmp = CACHE + ".%d" % os.getpid()
        with open(tmp, "w") as fh:
            for f in c.values():
                fh.write("\t".join(f) + "\n")
        os.replace(tmp, CACHE)
    except Exception:
        pass

def fmt_price(p):
    return ("%.2f" % p) if p >= 1 else ("%.6f" % p)

now = int(time.time())
cache = read_cache()
out, dirty = [], False
for sym in read_conf():
    ent = cache.get(sym)
    if ent and 0 <= now - int(ent[3]) <= MAX_AGE:
        out.append(ent)
        continue
    try:
        price, chg = SOURCES[sym]()
        ent = [sym, fmt_price(price), ("%+.2f" % chg) if chg is not None else "NA", str(now)]
        cache[sym] = ent
        dirty = True
        out.append(ent)
    except Exception:
        if ent:
            out.append(ent + ["stale"])
if dirty:
    write_cache(cache)
sys.stdout.write("".join("\t".join(f) + "\n" for f in out))
PY
