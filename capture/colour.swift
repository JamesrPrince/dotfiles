// colour.swift - NSColorSampler picker. Click a pixel; prints #RRGGBB (sRGB) and exits 0.
// Esc / cancel exits 1 with no output. Needs a click, so it is build-tested only.
import AppKit

if CommandLine.arguments.count > 1 {
    print("usage: colour   click a pixel; prints #RRGGBB (sRGB). Esc cancels (exit 1)")
    exit(CommandLine.arguments[1] == "-h" || CommandLine.arguments[1] == "--help" ? 0 : 2)
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let sampler = NSColorSampler()
sampler.show { picked in
    guard let c = picked?.usingColorSpace(.sRGB) else { exit(1) }
    func b(_ v: CGFloat) -> Int { max(0, min(255, Int((v * 255).rounded()))) }
    print(String(format: "#%02X%02X%02X", b(c.redComponent), b(c.greenComponent), b(c.blueComponent)))
    exit(0)
}
app.run()
