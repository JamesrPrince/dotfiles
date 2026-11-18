// omwin: centres and resizes the om popup (a Ghostty window titled "om") through Accessibility.
//   swiftc -O omwin.swift -o omwin
//   omwin check                              exit 0 when this process may use Accessibility, else 3 (never prompts)
//   omwin fit <ghostty-pid> <rows> <cur> [settle]   resize the popup from <cur> rows to <rows>, centred; silent on
//                                            any failure. Without "settle" the fit returns at once (0.25 s limit).
//                                            With it, omwin guards the placement for 1 s (OM_FIT_WATCH, 1.5 s
//                                            limit): om runs that in the background after a new window's first
//                                            fit. Exit 0 fitted, 1 no om window, 2 bad call or no Accessibility,
//                                            4 missed or timed out.
// Row height is measured from the window: (height - pad) / cur. pad is OM_POPUP_PAD (default 16 points).
// Every height shares one top edge: where a 22-row window would sit when centred on the main display.
import ApplicationServices
import Foundation

let args = CommandLine.arguments
guard args.count >= 2 else { exit(2) }

if args[1] == "check" { exit(AXIsProcessTrusted() ? 0 : 3) }
guard args[1] == "fit", args.count == 5 || (args.count == 6 && args[5] == "settle"), AXIsProcessTrusted(),
      let pid = Int32(args[2]), let rows = Double(args[3]), let cur = Double(args[4]),
      rows > 0, cur > 0 else { exit(2) }
let settle = args.count == 6

let pad = Double(ProcessInfo.processInfo.environment["OM_POPUP_PAD"] ?? "") ?? 16

// Hard limit: a stalled Accessibility call must never hold the menu. The watchdog ends the process from
// another thread; OM_FIT_LIMIT (seconds) overrides it. Exit 4 means "tried and missed", 1 "no om window yet".
let limit = Double(ProcessInfo.processInfo.environment["OM_FIT_LIMIT"] ?? "") ?? (settle ? 1.5 : 0.25)
DispatchQueue.global().asyncAfter(deadline: .now() + limit) { exit(4) }

func attr(_ el: AXUIElement, _ name: String) -> CFTypeRef? {
    var v: CFTypeRef?
    return AXUIElementCopyAttributeValue(el, name as CFString, &v) == .success ? v : nil
}
func point(_ el: AXUIElement) -> CGPoint? {
    guard let v = attr(el, kAXPositionAttribute), CFGetTypeID(v) == AXValueGetTypeID() else { return nil }
    var p = CGPoint.zero; return AXValueGetValue(v as! AXValue, .cgPoint, &p) ? p : nil
}
func size(_ el: AXUIElement) -> CGSize? {
    guard let v = attr(el, kAXSizeAttribute), CFGetTypeID(v) == AXValueGetTypeID() else { return nil }
    var s = CGSize.zero; return AXValueGetValue(v as! AXValue, .cgSize, &s) ? s : nil
}
func setPos(_ el: AXUIElement, _ p: CGPoint) -> Bool {
    var p = p; guard let v = AXValueCreate(.cgPoint, &p) else { return false }
    return AXUIElementSetAttributeValue(el, kAXPositionAttribute as CFString, v) == .success
}
func setSize(_ el: AXUIElement, _ s: CGSize) -> Bool {
    var s = s; guard let v = AXValueCreate(.cgSize, &s) else { return false }
    return AXUIElementSetAttributeValue(el, kAXSizeAttribute as CFString, v) == .success
}

let app = AXUIElementCreateApplication(pid)
AXUIElementSetMessagingTimeout(app, Float(limit))
guard let wins = attr(app, kAXWindowsAttribute) as? [AXUIElement],
      let win = wins.first(where: { (attr($0, kAXTitleAttribute) as? String) == "om" }),
      let cs = size(win), cs.height > pad else { exit(1) }

// Cell size: never trust the window as found, because AeroSpace can tile a new window for a moment before
// its float rule applies (then it is 2484 wide and its height is not the popup's). Fixed defaults, with env
// overrides; the measured row height is used only when it is close to the default (the font changed a little).
let env = ProcessInfo.processInfo.environment
let width = Double(env["OM_POPUP_W"] ?? "") ?? 576
let defRow = Double(env["OM_POPUP_ROW"] ?? "") ?? 17
var rowH = defRow
let measured = (Double(cs.height) - pad) / cur
if env["OM_POPUP_ROW"] == nil, abs(measured - defRow) <= defRow * 0.15 { rowH = measured }
let display = CGDisplayBounds(CGMainDisplayID())
let newH = (pad + rows * rowH).rounded()
let x = (Double(display.width) - width) / 2 + Double(display.minX)
let y = (Double(display.height) - (pad + 22 * rowH)) / 2 + Double(display.minY)
let target = CGPoint(x: x.rounded(), y: y.rounded())
let wantSize = CGSize(width: width, height: newH)

func apply() -> Bool {
    // Position first so a grow stays on screen, size, then position again (the size step can nudge the origin).
    // Each set is a round trip to Ghostty, so a set whose value already holds is skipped: every height shares
    // one top edge, and a menu change in a placed window is then the size step alone.
    func placed() -> Bool { if let p = point(win) { return abs(p.x - target.x) < 1 && abs(p.y - target.y) < 1 }; return false }
    var ok = placed() || setPos(win, target)
    if let z = size(win), abs(z.width - wantSize.width) < 1, abs(z.height - wantSize.height) < 1 {} else { ok = setSize(win, wantSize) && ok }
    return (placed() || setPos(win, target)) && ok
}
func settled() -> Bool {
    guard let p = point(win), let z = size(win) else { return false }
    return abs(p.x - target.x) < 1 && abs(p.y - target.y) < 1 && abs(z.width - wantSize.width) < 1 && abs(z.height - wantSize.height) < 1
}
var good = apply()
if settle {
    // Guard for a new window: a late tile or float step can move it again, so watch it and put it back.
    // om runs this in the background, so the menu never waits for it.
    let watch = Double(env["OM_FIT_WATCH"] ?? "") ?? 1.0
    let end = Date().addingTimeInterval(watch)
    while Date() < end {
        Thread.sleep(forTimeInterval: 0.04)
        if !settled() { good = apply() }
    }
} else if good, !settled() {
    // A menu change in a window that is already floating: no waiting, one more try only when it missed.
    Thread.sleep(forTimeInterval: 0.02)
    if !settled() { good = apply() }
}
exit(good && settled() ? 0 : 4)
