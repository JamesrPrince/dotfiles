#!/bin/bash
# Compiles the small native helpers the bar reads (no Homebrew needed).
# Needs the Xcode command line tools: xcode-select --install
set -euo pipefail
cd "$(dirname "$0")"

clang -O2 -framework IOKit -o smc smc.c
clang -O2 -o cpu cpu.c
clang -O2 -F /System/Library/PrivateFrameworks -framework DisplayServices -framework CoreGraphics -o brightness brightness.c
clang -O2 -framework CoreAudio -framework CoreFoundation -o audio audio.c
clang -O2 -framework CoreMediaIO -framework CoreFoundation -o camera camera.c
swiftc -O -o wifi wifi.swift
swiftc -O -o clip clip.swift

# The calendar reader is a tiny app so macOS gives it its own Calendars permission.
mkdir -p SketchyBarCal.app/Contents/MacOS
clang -O2 -framework EventKit -framework Foundation -o SketchyBarCal.app/Contents/MacOS/cal cal.m
codesign -s - --force SketchyBarCal.app

# The Wi-Fi scanner is an app too: its own Location permission shows the network name and
# lets it scan for nearby networks. Info.plist (with the Location description) is kept in the bundle.
mkdir -p SketchyBarWiFi.app/Contents/MacOS
swiftc -O -o SketchyBarWiFi.app/Contents/MacOS/wifiscan wifiscan.swift
codesign -s - --force SketchyBarWiFi.app

# The Bluetooth helper is an app too: macOS gives Bluetooth to apps with a usage description, and
# aborts it for command-line tools started by AeroSpace/SketchyBar. IOBluetooth directly, no blueutil.
# The Allow prompt shows once: open SketchyBarBluetooth.app
mkdir -p SketchyBarBluetooth.app/Contents/MacOS
swiftc -O -o SketchyBarBluetooth.app/Contents/MacOS/btctl btctl.swift
codesign -s - --force SketchyBarBluetooth.app

echo "Helpers built: smc cpu brightness audio camera wifi clip SketchyBarCal.app SketchyBarWiFi.app SketchyBarBluetooth.app"
