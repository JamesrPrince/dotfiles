// wm.mjs: GlazeWM helper for the Windows desktop (the Mac's Ghostty quick terminal, AeroSpace
// scratchpad and launch keys). Talks to GlazeWM over its IPC socket (ws://localhost:6123), so a
// key press costs one Node start and no extra processes.
// bootstrap.ps1 links it to %USERPROFILE%\.glzr\glazewm\wm.mjs; config.yaml calls it with
// `shell-exec --hide-window node <that path> <command>`.
//
//   quick              ctrl+`: toggle the drop-down terminal (ghostty/config: top, 50% wide, 45% tall,
//                      one session, no animation)
//   watch              started by GlazeWM: hides the drop-down when focus leaves it
//                      (quick-terminal-autohide = true)
//   scratch-send       alt+shift+minus: send the focused window to the hidden workspace S
//   scratch-bring      alt+shift+equal: bring the last-sent window back to the current workspace
//   run <proc> <exe> [args...]   focus a window of <proc> if one is open, else start <exe>
//   new <exe> [args...]          always start a new <exe>
//   claude             a WezTerm window running Claude Code in the vault (~/ICOR)

import { spawn } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const QUICK_CLASS = 'quick';      // wezterm-gui start --class quick
const HIDDEN = 'S';               // the scratchpad workspace; the bar never shows it
const QUICK_W = 0.50, QUICK_H = 0.45;
const STACK = path.join(os.tmpdir(), 'glazewm-scratchpad.json');
const WEZTERM = path.join(process.env.ProgramFiles ?? 'C:\\Program Files', 'WezTerm', 'wezterm-gui.exe');

// ---- IPC -------------------------------------------------------------------------------------
function connect() {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket('ws://localhost:6123');
    const pending = [];
    const handlers = [];
    ws.onmessage = (e) => {
      const msg = JSON.parse(e.data);
      if (msg.messageType === 'client_response') {
        const i = pending.findIndex((p) => p.message === msg.clientMessage);
        if (i >= 0) { const [p] = pending.splice(i, 1); msg.success ? p.resolve(msg.data) : p.reject(new Error(msg.error)); }
      } else if (msg.messageType === 'event_subscription') {
        handlers.forEach((h) => h(msg.data));
      }
    };
    ws.onopen = () => resolve({
      send: (message) => new Promise((res, rej) => { pending.push({ message, resolve: res, reject: rej }); ws.send(message); }),
      onEvent: (h) => handlers.push(h),
      closed: new Promise((r) => { ws.onclose = r; }),
      close: () => ws.close(),
    });
    ws.onerror = () => reject(new Error('GlazeWM is not running'));
  });
}

const allWindows = async (wm) => (await wm.send('query windows')).windows;
const workspaces = async (wm) => (await wm.send('query workspaces')).workspaces;
const isQuick = (w) => w.processName === 'wezterm-gui' && w.className === QUICK_CLASS;

function windowsIn(node, out = []) {
  for (const c of node.children ?? []) (c.type === 'window' ? out.push(c) : windowsIn(c, out));
  return out;
}
async function workspaceOf(wm, id) {
  return (await workspaces(wm)).find((ws) => windowsIn(ws).some((w) => w.id === id));
}
async function focusedWorkspace(wm) {
  const all = await workspaces(wm);
  return all.find((ws) => ws.hasFocus) ?? all.find((ws) => ws.isDisplayed);
}
const tryCmd = (wm, c) => wm.send(c).catch(() => null);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
function start(exe, args = [], cwd = os.homedir()) {
  spawn(exe, args, { cwd, detached: true, stdio: 'ignore', windowsHide: false }).unref();
}

// ---- Quick terminal ------------------------------------------------------------------------
async function showQuick(wm, q) {
  const ws = await focusedWorkspace(wm);
  const mon = (await wm.send('query monitors')).monitors.find((m) => (m.children ?? []).some((c) => c.id === ws.id))
    ?? (await wm.send('query monitors')).monitors[0];
  const r = mon.workingRect ?? { left: mon.x, top: mon.y, right: mon.x + mon.width, bottom: mon.y + mon.height };
  const left = r.left ?? r.x, top = r.top ?? r.y;
  const width = (r.right ?? left + r.width) - left, height = (r.bottom ?? top + r.height) - top;
  const w = Math.round(width * QUICK_W), h = Math.round(height * QUICK_H);
  const x = left + Math.round((width - w) / 2);
  await tryCmd(wm, `command --id ${q.id} move --workspace ${ws.name}`);
  // set-floating ignores placement flags on a window that already floats, so size, then position.
  // (Flag syntax: --shown-on-top, not "--shown-on-top true".)
  if (q.state?.type !== 'floating') await tryCmd(wm, `command --id ${q.id} set-floating --shown-on-top`);
  await tryCmd(wm, `command --id ${q.id} size --width ${w}px --height ${h}px`);
  await tryCmd(wm, `command --id ${q.id} position --x-pos ${x} --y-pos ${top}`);
  await tryCmd(wm, `command focus --container-id ${q.id}`);
}
const hideQuick = (wm, q) => tryCmd(wm, `command --id ${q.id} move --workspace ${HIDDEN}`);

async function quick(wm) {
  let q = (await allWindows(wm)).find(isQuick);
  if (!q) {
    start(WEZTERM, ['start', '--class', QUICK_CLASS]);
    for (let i = 0; i < 60 && !q; i++) { await sleep(100); q = (await allWindows(wm)).find(isQuick); }
    if (!q) return;
    return showQuick(wm, q);
  }
  const ws = await workspaceOf(wm, q.id);
  const visible = ws && ws.name !== HIDDEN && ws.isDisplayed && q.state?.type !== 'minimized';
  if (!visible) return showQuick(wm, q);
  if (q.hasFocus) return hideQuick(wm, q);
  return tryCmd(wm, `command focus --container-id ${q.id}`);
}

// Autohide: when focus moves from the drop-down to anything else, send it back to S.
async function watch(wm) {
  let last = null;
  wm.onEvent(async (ev) => {
    const now = ev.focusedContainer;
    if (!now) return;
    if (last && last !== now.id) {
      const q = (await allWindows(wm)).find(isQuick);
      if (q && q.id === last) {
        const ws = await workspaceOf(wm, q.id);
        if (ws && ws.name !== HIDDEN) await hideQuick(wm, q);
      }
    }
    last = now.id;
  });
  await wm.send('sub -e focus_changed');
  await wm.closed;   // exits with GlazeWM
}

// ---- Scratchpad (AeroSpace's scratchpad.sh) ---------------------------------------------------
const readStack = () => { try { return JSON.parse(fs.readFileSync(STACK, 'utf8')); } catch { return []; } };
const writeStack = (s) => fs.writeFileSync(STACK, JSON.stringify(s.slice(-50)));

async function scratchSend(wm) {
  const f = (await wm.send('query focused')).focused;
  if (f?.type !== 'window' || isQuick(f)) return;
  await wm.send(`command --id ${f.id} move --workspace ${HIDDEN}`);
  writeStack([...readStack().filter((id) => id !== f.id), f.id]);
}
async function scratchBring(wm) {
  const s = (await workspaces(wm)).find((ws) => ws.name === HIDDEN);
  const parked = s ? windowsIn(s).filter((w) => !isQuick(w)) : [];
  if (!parked.length) return;
  const stack = readStack();
  const pick = [...stack].reverse().map((id) => parked.find((w) => w.id === id)).find(Boolean) ?? parked[parked.length - 1];
  const ws = await focusedWorkspace(wm);
  await wm.send(`command --id ${pick.id} move --workspace ${ws.name}`);
  await tryCmd(wm, `command focus --container-id ${pick.id}`);
  writeStack(stack.filter((id) => id !== pick.id));
}

// ---- Launch helpers ---------------------------------------------------------------------------
async function run(wm, proc, exe, args) {
  const w = (await allWindows(wm)).find((x) => x.processName.toLowerCase() === proc.toLowerCase() && !isQuick(x));
  if (w) return wm.send(`command focus --container-id ${w.id}`);
  start(exe === 'wezterm-gui' ? WEZTERM : exe, args);
}

// ---- Main -------------------------------------------------------------------------------------
const [cmd, ...rest] = process.argv.slice(2);
const wm = await connect();
try {
  switch (cmd) {
    case 'quick': await quick(wm); break;
    case 'watch': await watch(wm); break;
    case 'scratch-send': await scratchSend(wm); break;
    case 'scratch-bring': await scratchBring(wm); break;
    case 'run': await run(wm, rest[0], rest[1], rest.slice(2)); break;
    case 'new': start(rest[0] === 'wezterm-gui' ? WEZTERM : rest[0], rest.slice(1)); break;
    case 'claude': start(WEZTERM, ['start', '--cwd', path.join(os.homedir(), 'ICOR'), '--', 'claude']); break;
    default: console.error(`unknown command: ${cmd ?? '(none)'}`); process.exitCode = 2;
  }
} finally {
  if (cmd !== 'watch') wm.close();
}
