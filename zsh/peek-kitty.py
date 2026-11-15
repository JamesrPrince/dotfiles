#!/usr/bin/env python3
"""Draw a PNG inline in Ghostty with the kitty graphics protocol (no chafa needed).
Usage: peek-kitty.py <file.png> [columns]   (scaled to the given width in terminal cells)"""
import base64, sys

def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__.strip(), file=sys.stderr); return 2
    data = base64.standard_b64encode(open(sys.argv[1], "rb").read())
    cols = sys.argv[2] if len(sys.argv) > 2 else ""
    out = sys.stdout.buffer
    first = True
    for i in range(0, len(data), 4096):
        chunk = data[i:i + 4096]
        more = 1 if i + 4096 < len(data) else 0
        keys = f"a=T,f=100,q=2{',c=' + cols if cols else ''},m={more}" if first else f"m={more}"
        out.write(b"\x1b_G" + keys.encode() + b";" + chunk + b"\x1b\\")
        first = False
    out.write(b"\n"); out.flush()
    return 0

if __name__ == "__main__":
    sys.exit(main())
