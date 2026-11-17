#!/usr/bin/python3
"""Builds the theme previews that Alfred's `om` list and the alt-shift-t toast show.

For every themes/<id>/ that has a colors.toml it writes
  preview.png        1280x720 or bigger. Omarchy's own preview.png where the theme exists there
                     (MIT, copied byte for byte with --omarchy / --osaka), otherwise generated here:
                     the theme's wallpaper cropped to 16:9 with a strip of its palette along the bottom.
  preview-thumb.png  400x225: preview.png scaled down, with the palette strip along the bottom.
                     Alfred shows it as the row's icon; the toast shows it too.

Standard library plus macOS `sips` only (sips scales, crops and decodes webp; the strip and the PNG
are written here). Safe to re-run; previews are committed, so this runs only when a theme changes.

Usage:
  python3 themes/make-previews.py                      thumbs for all, generate previews that are missing
  python3 themes/make-previews.py --force              regenerate every generated preview
  python3 themes/make-previews.py --omarchy <omarchy repo> [--osaka <omarchy-osaka-jade-theme repo>]
                                                       first copy Omarchy's preview.png for shared themes
"""
import os, re, shutil, struct, subprocess, sys, tempfile, zlib

HERE = os.path.dirname(os.path.abspath(__file__))
# our id -> Omarchy's folder name (themes/<name>/preview.png in github.com/basecamp/omarchy)
OMARCHY = {"tokyonight": "tokyo-night", "catppuccin": "catppuccin", "everforest": "everforest",
           "gruvbox": "gruvbox", "kanagawa": "kanagawa", "nord": "nord", "rosepine": "rose-pine",
           "matteblack": "matte-black", "ristretto": "ristretto"}
SWATCH_KEYS = ["background", "foreground", "accent", "red", "yellow", "green", "cyan", "blue", "magenta"]
THUMB_W, THUMB_H, THUMB_STRIP = 400, 225, 18
PREV_W, PREV_H, PREV_STRIP = 1280, 720, 64


def sips(*args):
    subprocess.run(["/usr/bin/sips", *args], check=True, capture_output=True)


def dims(path):
    out = subprocess.run(["/usr/bin/sips", "-g", "pixelWidth", "-g", "pixelHeight", path],
                         check=True, capture_output=True, text=True).stdout
    return int(re.search(r"pixelWidth: (\d+)", out).group(1)), int(re.search(r"pixelHeight: (\d+)", out).group(1))


def load_bmp(path):
    """24 or 32 bit BMP (what sips writes) -> (w, h, rows) with rows a list of bytearrays of RGB."""
    d = open(path, "rb").read()
    off = struct.unpack_from("<I", d, 10)[0]
    w, h, _, bpp = struct.unpack_from("<iiHH", d, 18)
    top_down = h < 0
    h = abs(h)
    bpp //= 8
    stride = (w * bpp + 3) & ~3
    rows = []
    for y in range(h):
        sy = y if top_down else h - 1 - y
        raw = d[off + sy * stride: off + sy * stride + w * bpp]
        row = bytearray(w * 3)
        row[0::3], row[1::3], row[2::3] = raw[2::bpp], raw[1::bpp], raw[0::bpp]    # BGR(A) -> RGB
        rows.append(row)
    return w, h, rows


def write_png(path, w, h, rows):
    raw = b"".join(b"\x00" + bytes(r) for r in rows)
    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xffffffff)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
                + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def palette(tid):
    c = dict(re.findall(r'^(\w+)\s*=\s*"([^"]*)"', open(f"{HERE}/{tid}/colors.toml").read(), re.M))
    return [bytes(int(c[k].lstrip("#")[i:i + 2], 16) for i in (0, 2, 4)) for k in SWATCH_KEYS]


def add_strip(rows, w, strip_h, colors):
    """Overwrites the bottom strip_h rows with equal swatches, a hairline above in the first colour."""
    h = len(rows)
    n = len(colors)
    line = bytearray(w * 3)
    for i, col in enumerate(colors):
        for x in range(i * w // n, (i + 1) * w // n):
            line[x * 3:x * 3 + 3] = col
    for y in range(h - strip_h, h):
        rows[y] = bytearray(line)


def fit(src, W, H, out):
    """Scale src to cover W x H, then centre-crop (sips only)."""
    w, h = dims(src)
    if w * H >= h * W:
        sips("-s", "format", "png", "--resampleHeight", str(H), src, "--out", out)
    else:
        sips("-s", "format", "png", "--resampleWidth", str(W), src, "--out", out)
    sips("-c", str(H), str(W), out)


def render(src, W, H, strip, colors, out, tmp):
    part = os.path.join(tmp, "fit.png")
    bmp = os.path.join(tmp, "fit.bmp")
    fit(src, W, H, part)
    sips("-s", "format", "bmp", part, "--out", bmp)
    w, h, rows = load_bmp(bmp)
    add_strip(rows, w, strip, colors)
    write_png(out, w, h, rows)


def wallpaper(tid):
    d = f"{HERE}/backgrounds/{'catppuccin' if tid == 'macchiato' else tid}"      # macchiato borrows Catppuccin's
    pics = sorted(f for f in (os.listdir(d) if os.path.isdir(d) else []) if not f.startswith("omarchy."))
    return os.path.join(d, pics[0]) if pics else None


def main(argv):
    force = "--force" in argv
    def opt(name):
        return argv[argv.index(name) + 1] if name in argv else None
    omarchy, osaka = opt("--omarchy"), opt("--osaka")
    ids = sorted(d for d in os.listdir(HERE) if os.path.isfile(f"{HERE}/{d}/colors.toml"))
    made, bad = [], []
    with tempfile.TemporaryDirectory() as tmp:
        for tid in ids:
            prev, thumb = f"{HERE}/{tid}/preview.png", f"{HERE}/{tid}/preview-thumb.png"
            theirs = None
            if omarchy and tid in OMARCHY:
                theirs = f"{omarchy}/themes/{OMARCHY[tid]}/preview.png"
            if osaka and tid == "osakajade":
                theirs = f"{osaka}/preview.png"
            if theirs and os.path.isfile(theirs):
                shutil.copyfile(theirs, prev)
                made.append(f"{tid}: Omarchy preview")
            elif force or not os.path.isfile(prev):
                wall = wallpaper(tid)
                if not wall:
                    bad.append(f"{tid}: no wallpaper to build a preview from")
                    continue
                render(wall, PREV_W, PREV_H, PREV_STRIP, palette(tid), prev, tmp)
                made.append(f"{tid}: generated preview")
            render(prev, THUMB_W, THUMB_H, THUMB_STRIP, palette(tid), thumb, tmp)
    print("\n".join(made + bad) or "nothing to do")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
