#!/usr/bin/env osascript -l JavaScript
// Workspaces: window layouts for Alfred. Usage: osascript -l JavaScript layout.js <vault|build|comms|focus|meeting|shutdown> [--dry-run]
// Geometry is fractions of the main display's visible frame (menu bar and Dock excluded). Apps are keyed by bundle id.
// Every run is logged to <Alfred Workflow Data>/com.icor.workspaces/layout.log; any problem raises a notification naming the failed step.
ObjC.import('AppKit'); ObjC.import('Foundation');
const SE = Application('System Events');
const T0 = Date.now();
const APPS = { // key: [display name, bundle id]
  obsidian: ['Obsidian', 'md.obsidian'], claude: ['Claude', 'com.anthropic.claudefordesktop'],
  ghostty: ['Ghostty', 'com.mitchellh.ghostty'], cursor: ['Cursor', 'com.todesktop.230313mzl4w4u92'],
  vscode: ['Visual Studio Code - Insiders', 'com.microsoft.VSCodeInsiders'],
  outlook: ['Microsoft Outlook', 'com.microsoft.Outlook'], whatsapp: ['WhatsApp', 'net.whatsapp.WhatsApp'],
  telegram: ['Telegram', 'ru.keepcoder.Telegram'], teams: ['Microsoft Teams', 'com.microsoft.teams2'],
  granola: ['Granola', 'com.granola.app'], brave: ['Brave Browser', 'com.brave.Browser'], zoom: ['zoom.us', 'us.zoom.xos'],
};
const NEWWIN = { ghostty: 'new window', brave: 'make new window' }; // apps that stay running with zero windows
const fresh = {}, problems = [];
let DRY = false, NAME = '?';

// ---------- logging and notifications ----------
const env = $.NSProcessInfo.processInfo.environment;
const DATA = ObjC.unwrap(env.objectForKey('alfred_workflow_data')) || ($.NSHomeDirectory().js + '/Library/Application Support/Alfred/Workflow Data/com.icor.workspaces');
const LOG = DATA + '/layout.log';
function log(s) {
  try {
    const fm = $.NSFileManager.defaultManager;
    fm.createDirectoryAtPathWithIntermediateDirectoriesAttributesError(DATA, true, $(), $());
    const line = $(new Date().toISOString() + ' [' + NAME + '] +' + (Date.now() - T0) + 'ms ' + s + '\n');
    if (!fm.fileExistsAtPath(LOG)) line.writeToFileAtomicallyEncodingError(LOG, true, $.NSUTF8StringEncoding, $());
    else { const h = $.NSFileHandle.fileHandleForWritingAtPath(LOG); h.seekToEndOfFile; h.writeData(line.dataUsingEncoding($.NSUTF8StringEncoding)); h.closeFile; }
  } catch (e) {}
}
function notify(t, m) { try { const a = Application.currentApplication(); a.includeStandardAdditions = true; a.displayNotification(m, { withTitle: t }); } catch (e) {} }
function problem(step, msg) { problems.push(step + ': ' + msg); log('PROBLEM ' + step + ': ' + msg); }
function classify(e) {
  const m = String(e && e.message || e);
  if (/-1719|assistive|-25211|-25200/i.test(m)) return 'permission (Accessibility for Alfred)';
  if (/-1743|not authori[sz]ed/i.test(m)) return 'permission (Automation for Alfred)';
  return 'error';
}

function selfPath() {
  const args = ObjC.deepUnwrap($.NSProcessInfo.processInfo.arguments); let f = args.filter(a => /layout\.js$/.test(a))[0] || 'layout.js';
  return f.charAt(0) === '/' ? f : $.NSFileManager.defaultManager.currentDirectoryPath.js + '/' + f;
}
const SELF = selfPath();
// ---------- helpers ----------
function sh(cmd) { const a = $.NSTask.alloc.init; a.launchPath = '/bin/bash'; a.arguments = ['-c', cmd + ' >/dev/null 2>&1']; a.launch; a.waitUntilExit; return a.terminationStatus; }
function pause(s) { $.NSThread.sleepForTimeInterval(s); }
function exists(p) { return $.NSFileManager.defaultManager.fileExistsAtPath(p); }
function installed(k) { const n = APPS[k][0] + '.app'; return exists('/Applications/' + n) || exists($.NSHomeDirectory().js + '/Applications/' + n); }
function proc(k) { const r = SE.applicationProcesses.whose({ bundleIdentifier: APPS[k][1] }); return r.length ? r[0] : null; }
function running(k) { return proc(k) !== null; }
function frame() {
  const s = $.NSScreen.screens.objectAtIndex(0), f = s.frame, v = s.visibleFrame;
  return { x: v.origin.x, y: f.size.height - (v.origin.y + v.size.height), w: v.size.width, h: v.size.height };
}
function mainWindow(p) { // prefer a standard window; fall back to the first (one batched event for all subroles)
  const ws = p.windows(); if (!ws.length) return null;
  let roles = []; try { roles = p.windows.subrole(); } catch (e) {}
  const i = roles.indexOf('AXStandardWindow');
  return ws[i >= 0 ? i : 0];
}
function ensure(k) { // returns a window, launching the app / opening a window if needed
  const name = APPS[k][0], bid = APPS[k][1];
  if (!installed(k)) { problem('app missing', name + ' is not installed'); return null; }
  let p = proc(k), t = Date.now(), reopened = false, nudged = false, activated = false;
  if (!p) { fresh[k] = true; sh('open -b ' + bid); log('launched ' + name); }
  const end = Date.now() + (fresh[k] ? 25 : 10) * 1000;
  while (Date.now() < end) {
    p = proc(k);
    if (p) {
      let w = mainWindow(p); if (w) return w;
      try { if (!p.visible()) { p.visible = true; pause(0.15); w = mainWindow(p); if (w) return w; } } catch (e) {} // hidden apps list no windows
      if (!activated) { activated = true; try { p.frontmost = true; } catch (e) {} pause(0.1); continue; } // some apps only list windows once active
      if (!reopened && Date.now() - t > 1500) { reopened = true; sh('open -b ' + bid); } // surfaces a window, also from another Space
      if (!nudged && Date.now() - t > (fresh[k] ? 3500 : 2500) && NEWWIN[k]) { // only when the app truly has no window anywhere
        nudged = true; let n = 0; try { n = Application(bid).windows().length; } catch (e) {}
        if (n === 0) sh("/usr/bin/osascript -e 'tell application id \""+bid+"\" to " + NEWWIN[k] + "'");
      }
    }
    pause(0.25);
  }
  problem('window never appeared', name + ' showed no window within ' + (fresh[k] ? 25 : 10) + 's');
  return null;
}
function geometry(r) { const f = frame(); return { pos: [Math.round(f.x + r[0] * f.w), Math.round(f.y + r[1] * f.h)], size: [Math.round(r[2] * f.w), Math.round(r[3] * f.h)] }; }
function setBounds(w, g) { w.size = g.size; w.position = g.pos; w.size = g.size; w.position = g.pos; }
function leaveFullscreen(p, w) { // returns the (possibly new) window
  try {
    const fs = w.attributes.byName('AXFullScreen');
    if (fs.value()) { fs.value = false; pause(1.3); return mainWindow(p) || w; }
  } catch (e) {}
  return w;
}
function place(k, r, last) {
  const w0 = ensure(k); if (!w0) return true; // ensure already recorded why
  const name = APPS[k][0];
  try {
    const p = proc(k);
    try { if (w0.attributes.byName('AXMinimized').value()) w0.attributes.byName('AXMinimized').value = false; } catch (e) {}
    const w = leaveFullscreen(p, w0), g = geometry(r);
    w.size = g.size; w.position = g.pos; w.size = g.size;
    log('placed ' + name + ' -> ' + JSON.stringify(g));
    return true;
  } catch (e) { if (last) problem(classify(e), name + ': ' + e.message); else log('retry ' + name + ': ' + e.message); return false; }
}
function recheck(k, r) { // after launch settles: re-apply, then verify
  const name = APPS[k][0];
  try {
    let p = proc(k), w = p && mainWindow(p);
    for (let i = 0; !w && i < 16; i++) { pause(0.25); p = proc(k); w = p && mainWindow(p); } // some apps swap their window after launch
    if (!w) { problem('window never appeared', name + ' had no window after launch settled'); return; }
    const g = geometry(r); setBounds(w, g);
    const pos = w.position(), sz = w.size();
    if (Math.abs(pos[0] - g.pos[0]) > 6 || Math.abs(pos[1] - g.pos[1]) > 6) problem('placement', name + ' ended at ' + pos + ' not ' + g.pos);
    else if (Math.abs(sz[0] - g.size[0]) > 6 || Math.abs(sz[1] - g.size[1]) > 6) log('note ' + name + ' size ' + sz + ' differs from ' + g.size + ' (app minimum size?)');
  } catch (e) { problem(classify(e), name + ': ' + e.message); }
}
function arrange(list, front) { // place all, settle once for freshly launched apps, verify, then raise the main one
  for (const [k, r] of list) { place(k, r, false) || place(k, r, true); } // one retry: a window object can go stale mid-run
  const fr = list.filter(([k]) => fresh[k]);
  if (fr.length) { pause(2); for (const [k, r] of fr) recheck(k, r); }
  try { proc(front).frontmost = true; } catch (e) {}
}

// ---------- layouts ----------
const layouts = {
  vault() { arrange([['obsidian', [0, 0, 2 / 3, 1]], ['claude', [2 / 3, 0, 1 / 3, 0.5]], ['ghostty', [2 / 3, 0.5, 1 / 3, 0.5]]], 'obsidian'); },
  build() {
    const ide = installed('cursor') ? 'cursor' : 'vscode';
    arrange([[ide, [0, 0, 0.5, 1]], ['brave', [0.5, 0, 0.5, 0.5]], ['ghostty', [0.5, 0.5, 0.5, 0.5]]], ide);
  },
  comms() {
    const l = [['outlook', [0, 0, 0.5, 1]], ['whatsapp', [0.5, 0, 0.5, 0.5]], ['telegram', [0.5, 0.5, 0.5, 0.5]]];
    if (running('teams')) l.push(['teams', [0, 0, 0.5, 1]]); // only when already open
    arrange(l, running('teams') ? 'teams' : 'outlook');
  },
  focus() {
    const all = SE.applicationProcesses.whose({ backgroundOnly: false })();
    const skip = ['com.runningwithcrayons.Alfred'];
    let front = null;
    for (const p of all) { try { if (p.frontmost() && skip.indexOf(p.bundleIdentifier()) < 0) { front = p; break; } } catch (e) {} }
    if (!front) { problem('no front app', 'could not tell which app is in front'); return; }
    const fname = front.name(), f = frame();
    try { const w = leaveFullscreen(front, mainWindow(front)); setBounds(w, { pos: [f.x, f.y], size: [f.w, f.h] }); log('maximised ' + fname); }
    catch (e) { problem(classify(e), 'maximise ' + fname + ': ' + e.message); }
    let hidden = 0;
    for (const p of all) { try { const b = p.bundleIdentifier(); if (b !== front.bundleIdentifier() && skip.indexOf(b) < 0 && b !== 'com.apple.finder' && p.visible()) { p.visible = false; hidden++; } } catch (e) {} }
    log('hid ' + hidden + ' apps');
    try { front.frontmost = true; } catch (e) {}
  },
  meeting() {
    const call = running('zoom') ? 'zoom' : running('teams') ? 'teams' : (installed('zoom') ? 'zoom' : 'teams');
    arrange([['granola', [0, 0, 0.28, 1]], [call, [0.28, 0, 0.72, 1]]], call);
    if (!DRY) { if (sh('/usr/bin/shortcuts run "Meeting DND"') !== 0) log('note Do Not Disturb not set: no working Shortcut named "Meeting DND"'); }
  },
  shutdown() {
    const keys = Object.keys(APPS), quit = [], still = [];
    for (const k of keys) { if (!running(k)) continue; if (DRY) { quit.push(APPS[k][0] + ' (dry run)'); continue; }
      try { Application(APPS[k][1]).quit(); quit.push(APPS[k][0]); } catch (e) { problem(classify(e), APPS[k][0] + ': ' + e.message); } }
    if (!DRY) { pause(4); for (const k of keys) if (running(k)) still.push(APPS[k][0]); }
    const msg = 'Asked to quit: ' + (quit.join(', ') || 'nothing running') + (still.length ? '. Still open (unsaved work or a prompt): ' + still.join(', ') : '');
    log(msg); notify('Workspaces: shutdown', msg);
  },
};

function run(argv) {
  NAME = argv[0]; DRY = argv.indexOf('--dry-run') >= 0;
  log('start' + (DRY ? ' (dry run)' : ''));
  if (!layouts[NAME]) { notify('Workspaces', 'unknown layout: ' + NAME); log('unknown layout'); return 'unknown layout'; }
  try { SE.applicationProcesses.whose({ frontmost: true })[0].windows.length; } // permission preflight
  catch (e) { const c = classify(e); problem(c, e.message); notify('Workspaces: ' + NAME + ' failed', c + '. Grant it in System Settings > Privacy & Security.'); return 'FAILED ' + c; }
  try { layouts[NAME](); } catch (e) { problem(classify(e), e.message); }
  const ms = Date.now() - T0;
  if (problems.length) { notify('Workspaces: ' + NAME + ' incomplete', problems.join(' | ')); log('end with ' + problems.length + ' problem(s) in ' + ms + 'ms'); return 'PROBLEMS ' + problems.join(' | '); }
  log('end ok in ' + ms + 'ms'); return 'ok ' + ms + 'ms';
}
