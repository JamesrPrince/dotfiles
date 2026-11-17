#!/bin/bash
# Build the capture helpers (plain swiftc, macOS 15 target). Binaries are git-ignored.
set -euo pipefail
cd "$(dirname "$0")"
ARCH=$(uname -m)
for h in ocr colour; do
  swiftc -O -target "$ARCH-apple-macosx15.0" "$h.swift" -o "$h"
  echo "built capture/$h"
done
