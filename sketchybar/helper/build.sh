#!/bin/bash
# Compiles the small native helpers the bar reads (no Homebrew needed).
# Needs the Xcode command line tools: xcode-select --install
set -euo pipefail
cd "$(dirname "$0")"

clang -O2 -framework IOKit -o smc smc.c
clang -O2 -F /System/Library/PrivateFrameworks -framework DisplayServices -framework CoreGraphics -o brightness brightness.c
clang -O2 -framework CoreAudio -framework CoreFoundation -o audio audio.c
clang -O2 -framework CoreMediaIO -framework CoreFoundation -o camera camera.c
swiftc -O -o wifi wifi.swift

# The calendar reader is a tiny app so macOS gives it its own Calendars permission.
mkdir -p SketchyBarCal.app/Contents/MacOS
clang -O2 -framework EventKit -framework Foundation -o SketchyBarCal.app/Contents/MacOS/cal cal.m
codesign -s - --force SketchyBarCal.app

echo "Helpers built: smc brightness audio camera wifi SketchyBarCal.app"
