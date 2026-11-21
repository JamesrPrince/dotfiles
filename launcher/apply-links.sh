#!/bin/zsh
# Loads command-bar-links.json into Vorssaint's command bar (quits and reopens Vorssaint).
set -e
D="${0:A:h}"
osascript -e 'quit app "Vorssaint"'; sleep 3
defaults write com.vorssaint.utils commandBarLinks -data "$(xxd -p "$D/command-bar-links.json" | tr -d '\n')"
open /Applications/Vorssaint.app; sleep 5
defaults export com.vorssaint.utils - | plutil -extract commandBarLinks raw -o - - | base64 -d \
  | /usr/bin/python3 -c 'import json,sys; print(len(json.load(sys.stdin)), "command bar links loaded")'
