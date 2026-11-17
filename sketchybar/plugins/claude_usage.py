#!/usr/bin/env python3
"""Claude Code usage meters for the bar's Claude popup. Prints ONE JSON record.

LOCAL DATA ONLY. A port of the local-stats half of Omarchy 4.5's omarchy-agent-usage-claude:
transcripts in ~/.claude/projects, with the stats-cache.json and history.jsonl fallbacks. It reads no
Keychain item, no OAuth token, no ~/.claude/.credentials*, and calls no network endpoint. The plan-limit
bars (5-hour / weekly) are NOT built: see plan_limits() below.

  claude_usage.py              print the record; recompute only when the cache is older than 5 minutes
  claude_usage.py --force      recompute now and refresh the cache
  claude_usage.py --cached     print the cache as it is (never scans); exit 1 if there is none
  claude_usage.py --refresh-bg start a detached refresh if the cache is stale (returns at once), then
                               ask the bar to redraw (`sketchybar --trigger claude_update`)

The cache is sketchybar/.claude_usage.json (git-ignored). Tokens are counted once per API reply
(message id + request id; a reply repeated across forked transcripts counts once). The 5-hour window is
the local approximation of Claude's rolling block: it opens at the top of the hour of the first reply
after a 5-hour gap and runs five hours, so it can differ from the server's own window.
"""
from __future__ import annotations

import datetime as dt
import json
import os
import subprocess
import sys
import time
from pathlib import Path

CACHE_TTL = 300                 # seconds a record stays fresh
WINDOW = 5 * 3600               # the plan's rolling block
LOOKBACK = 12 * 3600            # how far back to find where the current block began
CACHE = Path(__file__).resolve().parent.parent / ".claude_usage.json"
LOCK = CACHE.with_name(".claude_usage.lock")
CLAUDE_DIR = Path(os.environ.get("CLAUDE_CONFIG_DIR") or Path.home() / ".claude")


def number(v) -> int:
    return int(v) if isinstance(v, (int, float)) and not isinstance(v, bool) and v > 0 else 0


# ---------------------------------------------------------------------------------- plan limits
def plan_limits():
    """HOOK, deliberately empty: the authoritative 5-hour and weekly plan limits.

    Omarchy gets them from Anthropic's OAuth usage endpoint with the CLI's login token. That means a
    credential read and a network call, both out of scope for this build (James, 2026-11-17). When
    that is approved, return {"fiveHour": {"used": 0-100, "resetsAt": iso}, "weekly": {...}} here and
    the popup's "limits" row turns into bars. Until then: None, and the popup shows "not connected".
    """
    return None


# --------------------------------------------------------------------------------- local scan
def parse_ts(s):
    try:
        return dt.datetime.fromisoformat(s.replace("Z", "+00:00")).timestamp()
    except Exception:
        return None


def scan_transcripts(since: float):
    """Replies at or after `since` (epoch): {key: (ts, model, in, out, cache_read, cache_create, session)}."""
    projects = CLAUDE_DIR / "projects"
    replies: dict = {}
    found = False
    if not projects.is_dir():
        return replies, found
    for root, _dirs, files in os.walk(projects):
        for name in files:
            if not name.endswith(".jsonl"):
                continue
            found = True
            path = os.path.join(root, name)
            try:
                if os.stat(path).st_mtime < since:
                    continue
                fh = open(path, "rb")
            except OSError:
                continue
            with fh:
                for raw in fh:
                    # cheap byte test first: most lines are not a reply with usage
                    if b'"usage"' not in raw or b'"assistant"' not in raw:
                        continue
                    try:
                        d = json.loads(raw)
                    except ValueError:
                        continue
                    if d.get("type") != "assistant":
                        continue
                    msg = d.get("message")
                    if not isinstance(msg, dict) or not isinstance(msg.get("usage"), dict):
                        continue
                    ts = parse_ts(d.get("timestamp") or "")
                    model = str(msg.get("model") or "")
                    if ts is None or ts < since or model.startswith("<"):   # "<synthetic>" is no API call
                        continue
                    u = msg["usage"]
                    row = (ts, model, number(u.get("input_tokens")), number(u.get("output_tokens")),
                           number(u.get("cache_read_input_tokens")), number(u.get("cache_creation_input_tokens")),
                           str(d.get("sessionId") or ""))
                    key = f'{msg.get("id") or ""}:{d.get("requestId") or ""}' if msg.get("id") else f"{path}:{d.get('uuid')}"
                    old = replies.get(key)
                    if old is None or row[3] >= old[3]:   # a streamed reply is logged more than once: keep the fullest
                        replies[key] = row
    return replies, found


def bucket():
    return {"input": 0, "output": 0, "cacheRead": 0, "cacheCreate": 0, "messages": 0, "sessions": 0, "topModel": "", "tokens": 0}


def summarise(rows):
    b = bucket()
    sessions, by_model = set(), {}
    for ts, model, i, o, cr, cc, sid in rows:
        b["input"] += i; b["output"] += o; b["cacheRead"] += cr; b["cacheCreate"] += cc
        b["messages"] += 1
        if sid:
            sessions.add(sid)
        by_model[model] = by_model.get(model, 0) + 1   # the model that answered most replies
    b["sessions"] = len(sessions)
    b["tokens"] = b["input"] + b["output"] + b["cacheRead"] + b["cacheCreate"]
    if by_model:
        b["topModel"] = max(by_model.items(), key=lambda kv: kv[1])[0]
    return b


def current_block(rows, now):
    """(start, end) of the active 5-hour block, or None when the last one has run out."""
    start = end = None
    for ts in sorted(r[0] for r in rows):
        if start is None or ts >= end:
            start = ts - ts % 3600          # top of the (UTC) hour; whole-hour zones make this the local hour too
            end = start + WINDOW
    return (start, end) if start is not None and now < end else None


# History and stats-cache fallbacks (Omarchy's stats_cache_fallback / today_prompts_from_history).
LOCAL_COMMANDS = frozenset((
    "add-dir", "advisor", "agents", "allowed-tools", "app", "artifacts", "autocompact", "background", "bashes",
    "bg", "branch", "brief", "btw", "bug", "cd", "checkpoint", "clear", "color", "compact", "config", "context",
    "copy", "cost", "daemon", "desktop", "diff", "effort", "exit", "export", "fast", "feedback", "focus", "fork",
    "goal", "help", "hooks", "ide", "import", "install", "login", "logout", "loops", "mcp", "memory", "model",
    "name", "new", "output-style", "permissions", "plan", "plugin", "plugins", "quit", "recap", "reload-plugins",
    "remote", "rename", "reset", "restart", "resume", "rewind", "session", "settings", "skills", "stats",
    "status", "stop", "tasks", "terminal-setup", "theme", "undo", "update", "upgrade", "usage", "version", "voice",
))


def history_today():
    """(prompts, sessions) typed today, from history.jsonl."""
    start = dt.datetime.combine(dt.date.today(), dt.time.min).timestamp() * 1000
    prompts, sessions = 0, set()
    try:
        lines = (CLAUDE_DIR / "history.jsonl").read_text(encoding="utf-8", errors="replace").splitlines()
    except OSError:
        return 0, 0
    for line in reversed(lines):
        try:
            e = json.loads(line)
        except ValueError:
            continue
        if not isinstance(e, dict):
            continue
        if number(e.get("timestamp")) < start:
            break
        text = str(e.get("display") or "").strip()
        if text.startswith("/") and len(text) > 1 and text[1:].split(None, 1)[0].lower() in LOCAL_COMMANDS:
            continue   # a built-in command that asks the model nothing
        prompts += 1
        if e.get("sessionId"):
            sessions.add(str(e["sessionId"]))
    return prompts, len(sessions)


def stats_cache_today():
    """Tokens per model for the local day of the newest dailyModelTokens entry, or None."""
    try:
        data = json.loads((CLAUDE_DIR / "stats-cache.json").read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return None
    if not isinstance(data, dict):
        return None
    per_model = {}
    for m, v in (data.get("modelUsage") or {}).items():
        if isinstance(v, dict):
            per_model[m] = v
    return {"asOf": data.get("lastComputedDate"), "modelUsage": per_model}


def collect():
    now = time.time()
    midnight = dt.datetime.combine(dt.date.today(), dt.time.min).timestamp()
    since = min(midnight, now - LOOKBACK)
    replies, found = scan_transcripts(since)
    rows = list(replies.values())
    today = summarise(r for r in rows if r[0] >= midnight)
    block = current_block(rows, now)
    window = summarise(r for r in rows if block and r[0] >= block[0])
    window.update(startsAt=dt.datetime.fromtimestamp(block[0]).isoformat(timespec="seconds") if block else None,
                  resetsAt=dt.datetime.fromtimestamp(block[1]).isoformat(timespec="seconds") if block else None,
                  active=block is not None)
    source = "transcripts"
    prompts, h_sessions = history_today()
    if not found:
        # a machine without transcripts: aggregate counters and typed prompts are all there is
        sc = stats_cache_today()
        source = "stats-cache" if sc else ("history" if prompts else "none")
        today["messages"], today["sessions"] = prompts, h_sessions
        if sc and sc["modelUsage"]:
            top = max(sc["modelUsage"].items(), key=lambda kv: sum(number(kv[1].get(k)) for k in kv[1] if k.endswith("Tokens")))
            today["topModel"] = top[0]
    return {
        "version": 1,
        "generatedAt": dt.datetime.now().isoformat(timespec="seconds"),
        "generatedEpoch": int(now),
        "ttlSeconds": CACHE_TTL,
        "source": source,
        "today": dict(today, prompts=prompts),
        "window": window,
        "limits": plan_limits(),          # None until the hook above is filled in
    }


# ------------------------------------------------------------------------------- cache + CLI
def read_cache():
    try:
        return json.loads(CACHE.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return None


def write_cache(rec):
    tmp = CACHE.with_name(f"{CACHE.name}.tmp.{os.getpid()}")
    try:
        tmp.write_text(json.dumps(rec), encoding="utf-8")
        os.replace(tmp, CACHE)
    except OSError:
        pass


def fresh(rec):
    return bool(rec) and time.time() - number(rec.get("generatedEpoch")) < CACHE_TTL


def refresh_bg():
    """Start a detached recompute unless the cache is fresh or one is already running."""
    if fresh(read_cache()):
        return 0
    try:
        if time.time() - LOCK.stat().st_mtime < 120:
            return 0
        LOCK.unlink()
    except OSError:
        pass
    try:
        LOCK.touch()
    except OSError:
        return 0
    cmd = f'{sys.executable!r} {str(Path(__file__).resolve())!r} --force >/dev/null 2>&1; rm -f {str(LOCK)!r}; sketchybar --trigger claude_update >/dev/null 2>&1'
    subprocess.Popen(["/bin/sh", "-c", cmd], stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                     stderr=subprocess.DEVNULL, start_new_session=True,
                     env=dict(os.environ, PATH="/usr/local/bin:/opt/homebrew/bin:" + os.environ.get("PATH", "")))
    return 0


def main(argv):
    sys.dont_write_bytecode = True
    if "--cached" in argv:
        rec = read_cache()
        if rec is None:
            return 1
        print(json.dumps(rec))
        return 0
    if "--refresh-bg" in argv:
        return refresh_bg()
    rec = None if "--force" in argv else read_cache()
    if not fresh(rec):
        rec = collect()
        write_cache(rec)
    print(json.dumps(rec, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
