#!/bin/bash
# Launch-mode actions for AeroSpace (`mode launch` in aerospace.toml; Caps Lock is F18 via launchd/).
#   launch.sh <name>   open or focus an app, or run a tool in a new Ghostty window
#   launch.sh list     "<name>|<description>" per action (the shortcut sheet, keys.py, reads this)
# Tools open in a new Ghostty window through Ghostty's own AppleScript. The first use asks once:
# "AeroSpace wants to control Ghostty" (System Settings > Privacy > Automation).
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"

default_browser() { # bundle id of the default https handler, else Safari
  /usr/bin/python3 - <<'PY'
import os, plistlib
try:
    p = plistlib.load(open(os.path.expanduser("~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist"), "rb"))
    for h in p.get("LSHandlers", []):
        if h.get("LSHandlerURLScheme") == "https" and h.get("LSHandlerRoleAll"):
            print(h["LSHandlerRoleAll"]); raise SystemExit
except Exception:
    pass
print("com.apple.Safari")
PY
}

ghostty_window() { # ghostty_window [command]  (no command: a plain shell)
  /usr/bin/osascript - "$1" <<'AS' >/dev/null 2>&1
on run argv
  tell application "Ghostty"
    if (item 1 of argv) is "" then
      new window
    else
      set cfg to new surface configuration
      set command of cfg to (item 1 of argv)
      new window with configuration cfg
    end if
    activate
  end tell
end run
AS
}

case "$1" in
  browser) open -b "$(default_browser)" ;;
  ghostty) open -b com.mitchellh.ghostty ;;
  new)     ghostty_window "" ;;
  finder)  open -b com.apple.finder ;;
  code)    open -b com.microsoft.VSCodeInsiders ;;
  btop)    ghostty_window "/usr/local/bin/btop" ;;
  lazygit) ghostty_window "/usr/local/bin/lazygit" ;;
  lazydocker) ghostty_window "/usr/local/bin/lazydocker" ;;
  yazi)    ghostty_window "/usr/local/bin/yazi" ;;
  slack)   open -b com.tinyspeck.slackmacgap ;;
  whatsapp) open -b net.whatsapp.WhatsApp ;;
  notion)  open -b notion.id ;;
  claude)  open -b com.anthropic.claudefordesktop ;;
  outlook) open -b com.microsoft.Outlook ;;
  excel)   open -b com.microsoft.Excel ;;
  spotify) open -b com.spotify.client ;;
  list)
    cat <<'LIST'
browser|Browser
ghostty|Ghostty
new|New Ghostty window
finder|Finder
code|VS Code
btop|btop
lazygit|lazygit
lazydocker|lazydocker
yazi|yazi
slack|Slack
whatsapp|WhatsApp
notion|Notion
claude|Claude
outlook|Outlook
excel|Excel
spotify|Spotify
LIST
    ;;
  *) echo "usage: launch.sh <name> | list" >&2; exit 2 ;;
esac
