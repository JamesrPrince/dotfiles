# dotfiles

My macOS desktop: an [AeroSpace](https://github.com/nikitabobko/AeroSpace) tiling window manager and a [SketchyBar](https://github.com/FelixKratz/SketchyBar) menu bar in the style of FelixKratz's setup. Built and tested on macOS 15 (Intel).

## What's in the bar

| Left | Right |
| --- | --- |
| Apple menu, AeroSpace workspaces with app icons, front app, Spotify | Calendar, mic/camera indicator, control centre, AeroSpace key cheat sheet, Wi-Fi, battery, volume, CPU / memory / network stats |

- **Control centre**: brightness slider, Wi-Fi, Bluetooth, Focus, dark mode and keep-awake toggles, battery charge and health, System Settings.
- **Calendar**: left-click shows today's and tomorrow's events. Right-click toggles zen mode, which hides the busy items.
- **Volume**: click for the volume slider. Right-click lists audio outputs so you can switch.
- **Stats**: click for a popup with CPU temperature, fan speed, disk and uptime.
- **Privacy**: an orange mic or green camera shows only while one is in use.

## Install

```bash
git clone https://github.com/JamesrPrince/dotfiles ~/dotfiles
~/dotfiles/install.sh
```

`install.sh` checks the tools are installed, moves any existing `~/.config/sketchybar` and `~/.aerospace.toml` to a dated `.bak-` copy, symlinks the repo into place and compiles the helpers. On Apple Silicon it rewrites `/usr/local/bin` to `/opt/homebrew/bin` in the configs.

### Requirements

```bash
brew tap FelixKratz/formulae && brew install sketchybar borders jq
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

`alt-shift-/` shows the AeroSpace key cheat sheet in the bar. Bindings live in `aerospace/aerospace.toml`.
