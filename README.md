# dotfiles

My macOS desktop: an [AeroSpace](https://github.com/nikitabobko/AeroSpace) tiling window manager and a [SketchyBar](https://github.com/FelixKratz/SketchyBar) menu bar in the style of FelixKratz's setup. Built and tested on macOS 15 (Intel).

## What's in the bar

| Left | Right |
| --- | --- |
| Apple menu, AeroSpace workspaces with app icons, front app, Spotify | Calendar, mic/camera indicator, control centre, AeroSpace key cheat sheet, Wi-Fi, battery with percentage, volume, CPU / memory / GPU / network stats |

- **Control centre**: brightness slider, Wi-Fi, Bluetooth, Focus, dark mode and keep-awake toggles, battery charge and health, System Settings.
- **Calendar**: left-click shows today's and tomorrow's events. Right-click toggles zen mode, which hides the busy items.
- **Volume**: click for the volume slider. Right-click lists audio outputs so you can switch.
- **Stats**: click for a popup with CPU temperature, fan speed, disk and uptime.
- **Privacy**: an orange mic or green camera shows only while one is in use.
- **Unread badges**: Slack, WhatsApp, Telegram and Outlook show their unread count (from the Dock badge) only while they have one. Click to open the app.
- **Weather**: current temperature from [wttr.in](https://wttr.in) (no key; location comes from your IP), refreshed every 15 minutes. Click for the next six 3-hour slots with rain chance.
- **Focus timer**: click the clock icon for 25 minutes, right-click for 50, click again to stop. A sound and a notification mark the end.
- **Battery**: always shown with its percentage. Green while charging, orange below 40%, red below 20%.
- **GPU**: load of the busiest graphics card (Intel UHD or Radeon), green, yellow from 50%, red from 80%.
- **Workspaces**: the focused workspace is a pill in the theme's accent; empty ones are grey.
- **Themes**: Catppuccin Macchiato, Tokyo Night and Gruvbox. `alt-shift-t` or the Theme row in the control centre moves to the next one; the window borders follow. The choice is kept in `sketchybar/.theme` (git-ignored).
- **Hover and popups**: clickable items light up under the pointer, and popups slide in.
- **Spotify**: the track and artist sit in the bar with a thin progress line under them while music plays. Click for album art and controls.
- **Disk warning**: a red disk item appears only when the startup disk has under 20 GB free.
- **Full screen**: the bar hides while a window is AeroSpace full screen (`alt-shift-f`) and comes back when you leave it.
- **GitHub**: the GitHub icon turns white with a red count when you have unread notifications. Click for the latest 8 (each opens its page), right-click for github.com/notifications. Needs `gh auth login`.

## Install

```bash
git clone https://github.com/JamesrPrince/dotfiles ~/dotfiles
~/dotfiles/install.sh
```

`install.sh` checks the tools are installed, moves any existing `~/.config/sketchybar` and `~/.aerospace.toml` to a dated `.bak-` copy, symlinks the repo into place and compiles the helpers. On Apple Silicon it rewrites `/usr/local/bin` to `/opt/homebrew/bin` in the configs.

### Requirements

```bash
brew tap FelixKratz/formulae && brew install sketchybar borders jq gh
brew install --cask nikitabobko/tap/aerospace font-sf-pro
curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/latest/download/sketchybar-app-font.ttf -o ~/Library/Fonts/sketchybar-app-font.ttf
xcode-select --install   # clang and swiftc for the helpers
```

Hide the macOS menu bar (System Settings → Control Center → Automatically hide and show the menu bar → Always).

## Helpers

Small native programs in `sketchybar/helper/`, compiled by `build.sh` (binaries are git-ignored):

| Helper | Does |
| --- | --- |
| `smc` | CPU temperature and fan speed |
| `wifi` | Wi-Fi name and signal |
| `brightness` | read and set display brightness |
| `audio` | list and switch audio outputs |
| `camera` | is the camera in use |
| `SketchyBarCal.app` | calendar events (an app bundle, so macOS grants it Calendar access) |

## macOS 15 notes

- **Wi-Fi name**: macOS hides the SSID unless you run `sudo ipconfig setverbose 1` once.
- **Calendar**: the first left-click on the clock asks for Calendar access for SketchyBarCal. Allow it.
- **Focus toggle**: make a Shortcut named `Toggle Focus` (Set Focus → Do Not Disturb → Toggle). Without it the row opens Focus settings.
- **Bluetooth**: the row shows state and opens Bluetooth settings; macOS 15 blocks a toggle helper.

## Keys

`alt-shift-/` shows the AeroSpace key cheat sheet in the bar. `alt-shift-t` changes the bar theme. Bindings live in `aerospace/aerospace.toml`.

- **Modes**: `alt-shift-;` service mode, `alt-shift-r` resize mode (h/j/k/l or arrows, `b` equal sizes, esc to leave). A pill next to the workspaces shows which mode is on; click it to go back to normal.
- **Workspaces**: five (`alt-1` to `alt-5`). New windows open on a fixed one: 3 Obsidian and Notion, 4 Excel and Outlook, 5 WhatsApp, Telegram, Slack and Spotify. Browsers, terminals and the rest open where you are.
- **Floating**: System Settings, Calculator, Activity Monitor, Archive Utility, Finder's Get Info, System Information, Disk Utility and FaceTime float instead of tiling.
