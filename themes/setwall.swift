// Sets the desktop picture on every screen. Compiled by theme.sh:
//   swiftc -O setwall.swift -o setwall      usage: setwall <image path>
// (osascript / System Events is refused on this Mac, NSWorkspace is not.)
import AppKit

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: setwall <image>\n".utf8))
    exit(2)
}
let url = URL(fileURLWithPath: CommandLine.arguments[1])
var failed = false
for screen in NSScreen.screens {
    do {
        try NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: [
            .imageScaling: NSImageScaling.scaleProportionallyUpOrDown.rawValue,
            .allowClipping: true,
        ])
    } catch {
        FileHandle.standardError.write(Data("setwall: \(error.localizedDescription)\n".utf8))
        failed = true
    }
}
exit(failed ? 1 : 0)
