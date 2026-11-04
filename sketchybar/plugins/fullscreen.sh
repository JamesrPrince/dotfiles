#!/bin/bash
# Hides the bar while the focused window is AeroSpace full screen.
export PATH="/usr/local/bin:$PATH"
fs=$(aerospace list-windows --focused --format '%{window-is-fullscreen}' 2>/dev/null)
if [ "$fs" = "true" ]; then sketchybar --bar hidden=on; else sketchybar --bar hidden=off; fi
