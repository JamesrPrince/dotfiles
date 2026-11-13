# dotfiles

My macOS desktop: an [AeroSpace](https://github.com/nikitabobko/AeroSpace) tiling window manager and a [SketchyBar](https://github.com/FelixKratz/SketchyBar) menu bar in the style of FelixKratz's setup. Built and tested on macOS 15 (Intel).

## What's in the bar

| Left | Right |
| --- | --- |
| Apple menu, AeroSpace workspaces with app icons, layout pill, front app, Spotify | Calendar with next-event countdown, clipboard history, mic/camera indicator, control centre, AeroSpace key cheat sheet, Wi-Fi, VPN and public IP, battery with percentage, volume, CPU / memory / GPU / network stats |

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
- **Themes**: eleven, switched as one (see Theme engine below). `alt-shift-t` or the Theme row in the control centre moves to the next one.
- **Hover and popups**: clickable items light up under the pointer, and popups slide in.
- **Spotify**: the track and artist sit in the bar with a thin progress line under them while music plays. Click for album art and controls.
- **Next event**: in the hour before your next timed event, its name and a countdown sit left of the clock; orange from 10 minutes, red at the start. Click opens Calendar.
- **Layout pill**: shows the focused window's layout (`↔ TILES`, `↕ ACCORDION`, `FLOATING`). Click switches tiles and accordion, right-click turns it horizontal or vertical.
- **VPN and IP**: a green padlock while a VPN is connected, a globe otherwise, with the country your traffic leaves from (from [ifconfig.co](https://ifconfig.co), ipinfo.io as fallback). Click for the public IP (click to copy), city, and a connect/disconnect row for each VPN in System Settings.
- **Clipboard history**: click the copy icon for the last 10 texts you copied; click one to copy it again. Copies a password manager marks as concealed are never kept. History lives in `~/.cache/sketchybar/clipboard.json` (25 entries, readable only by you).
- **Disk warning**: a red disk item appears only when the startup disk has under 20 GB free.
- **Full screen**: the bar hides while a window is AeroSpace full screen (`alt-shift-f`) and comes back when you leave it.
- **GitHub**: the GitHub icon turns white with a red count when you have unread notifications. Click for the latest 8 (each opens its page), right-click for github.com/notifications. Needs `gh auth login`.

## Install

```bash
git clone https://github.com/JamesrPrince/dotfiles ~/dotfiles
~/dotfiles/install.sh
```

`install.sh` checks the tools are installed, moves anything already at a target (`~/.config/sketchybar`, `~/.aerospace.toml`, and the Ghostty, Starship, Neovim, fastfetch, btop, bat and lazygit configs) to a dated `.bak-` copy, symlinks the repo into place, adds the Starship and fzf lines to `~/.zshrc` if missing, remaps Caps Lock to F18 (LaunchAgent), compiles the helpers, installs the Alfred `om` workflow, downloads the wallpapers, compiles the wallpaper tool, syncs every themed part to the active theme, and ends with `barstyle.sh set` for the current style (centre on a fresh install), which writes the matching AeroSpace top gap. `SKIP_HELPERS=1 ./install.sh` skips the helper build (a rebuild re-signs the apps and voids the permissions you granted them). On Apple Silicon it rewrites `/usr/local/bin` to `/opt/homebrew/bin` in the configs.

### Requirements

```bash
brew bundle --file ~/dotfiles/Brewfile   # bar, AeroSpace, Ghostty, terminal tools, fonts
xcode-select --install                   # clang and swiftc for the helpers
```

fastfetch is not in the Brewfile: on Intel Homebrew has no bottle and compiles llvm and rust for hours. Install the [release binary](https://github.com/fastfetch-cli/fastfetch/releases) into `/usr/local/bin` (updates are manual).

Hide the macOS menu bar (System Settings → Control Center → Automatically hide and show the menu bar → Always).

## Check

```bash
~/dotfiles/check.sh            # read-only: one PASS or FAIL line per check, exit 0 only if all pass
~/dotfiles/check.sh --styles   # also switches to the other bar style and back, checking each
~/dotfiles/check.sh --themes   # also runs themes/check-all.sh (switches through all 11 themes, then restores)
```

It checks shell and Python syntax, Ghostty and AeroSpace config, the shortcut sheet (0 missing), the helper apps' signatures, every symlink `install.sh` makes, the bar style against `gaps.outer.top`, that no two visible bar items overlap (`net.down` sits under `net.up` on purpose), that all 11 themes are complete, the Alfred theme files, and the Caps Lock leader key.

## Launch mode (Caps Lock)

Tap Caps Lock, then one letter. Caps Lock is remapped to F18 with macOS's own `hidutil`, re-applied at login by `launchd/dev.dotfiles.capslock-f18.plist` (no Karabiner, no sudo). AeroSpace's `f18` enters `launch` mode; a letter runs `aerospace/launch.sh` and returns to `main`; Esc or Caps Lock again cancels. The bar shows LAUNCH while it waits (needs a line in `plugins/mode.sh`), and the cheat sheet has a Launch page.

| Key | Opens | Key | Opens |
| --- | --- | --- | --- |
| b | default browser (detected) | s | Slack |
| t | Ghostty | w | WhatsApp |
| n | new Ghostty window | o | Notion |
| f | Finder | a | Claude |
| c | VS Code Insiders | e | Outlook |
| m | btop (new Ghostty window) | x | Excel |
| l | lazygit (new Ghostty window) | p | Spotify |
| d | lazydocker (new Ghostty window) | y | yazi (new Ghostty window) |

Tools and `n` use Ghostty's AppleScript; the first time, macOS asks once to let AeroSpace control Ghostty. A new Ghostty window floats on the current workspace (the first one tiles on workspace 2).

## Alfred and the browser

Alfred has one appearance theme per bar theme (`alfred/themes/<id>.alfredappearance`, "Om <name>"), generated by `python3 alfred/gen-themes.py` from the same `themes/<id>/colors.toml`. Alfred imports themes only through its import sheet: run `alfred/import.sh` once and click Import on each. After that `theme.sh set` switches Alfred live through its own AppleScript (the first switch asks for Automation permission). The browser toolbar is not themed: Chromium's `BrowserThemeColor` needs a managed policy (root-owned files or a configuration profile).

## Theme engine

One switch re-themes the desktop, the way Omarchy does. All colours come from Omarchy's own `colors.toml` files (`themes/<name>/`).

```bash
theme.sh list            # every theme, * marks the active one
theme.sh set nord        # switch to one
theme.sh next            # alt-shift-t
theme.sh current         # the active id
```

(`theme.sh` is `~/.config/sketchybar/plugins/theme.sh`.) Themes: macchiato (the original), tokyonight, catppuccin, everforest, gruvbox, kanagawa, nord, rosepine (light), matteblack, osakajade, ristretto. The active one is kept in `sketchybar/.theme` (git-ignored).

A switch changes:

| Part | How |
| --- | --- |
| Bar and popups | `sketchybar/colors.sh`, generated by `themes/gen-colors.py` (same variable names for every theme; on a light theme `WHITE`, the text colour, is dark) |
| Window borders | JankyBorders in the theme's accent, 2 px |
| Ghostty | `ghostty/theme.conf` (git-ignored): a bundled Ghostty theme, or for Osaka Jade the palette from its `colors.toml` |
| Neovim | `nvim/lua/plugins/theme.lua` (git-ignored), a copy of the theme's `themes/<name>/neovim.lua`; LazyVim loads it on the next start |
| Wallpaper | first picture in `themes/backgrounds/<name>/`, set by `themes/setwall` (Swift, `NSWorkspace.setDesktopImageURL`). Applies to the current Space. |
| Alfred | one theme per bar theme (`alfred/themes/`), switched through Alfred's AppleScript once imported (see Alfred and the browser) |
| btop, bat, fzf, lazygit, yazi, Starship, fastfetch | nothing to switch: each is set to use the terminal's 16 ANSI colours (btop `TTY`, bat `ansi`, fzf `--color=16`, lazygit named colours, Starship cyan), so they follow Ghostty |

Wallpapers are not in git. `themes/fetch-backgrounds.sh` downloads them from Omarchy (Osaka Jade from its own repo); `install.sh` runs it. A wallpaper tool rebuild is `swiftc -O themes/setwall.swift -o themes/setwall`.

Add a theme: put `colors.toml` and `neovim.lua` in `themes/<id>/`, add a line to `THEMES` in `themes/gen-colors.py`, run `python3 themes/gen-colors.py > sketchybar/colors.sh`, and add the wallpaper mapping in `fetch-backgrounds.sh`.

## Terminal and editor

- **Starship** is the prompt (`starship/starship.toml`, Omarchy's own). It runs from the end of `~/.zshrc` on top of oh-my-zsh (`ZSH_THEME=""`). powerlevel10k stays installed but unused.
- **Ghostty**: no title bar, 0.97 opacity, Maple Mono NF.
- **Neovim** with [LazyVim](https://www.lazyvim.org) in `nvim/`. The first start downloads the plugins; run `nvim` once with a network.
- **fastfetch**: `fastfetch` prints Omarchy's boxed layout in terminal colours.
- **lazydocker**: `lazydocker`, plus `lazygit`, `btop`, `yazi` as before.

## Helpers

Small native programs in `sketchybar/helper/`, compiled by `build.sh` (binaries are git-ignored):

| Helper | Does |
| --- | --- |
| `smc` | CPU temperature and fan speed |
| `cpu` | CPU load since the last read, without the one-second wait of iostat |
| `wifi` | Wi-Fi name and signal |
| `clip` | clipboard history |
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

`alt-shift-/` shows the AeroSpace key cheat sheet in the bar. `alt-shift-t` switches theme and `alt-shift-b` the bar style. Bindings live in `aerospace/aerospace.toml`.

- **Modes**: `alt-shift-;` service mode, `alt-shift-r` resize mode (h/j/k/l or arrows, `b` equal sizes, esc to leave). A pill next to the workspaces shows which mode is on; click it to go back to normal.
- **Workspaces**: five (`alt-1` to `alt-5`). New windows open on a fixed one: 3 Obsidian and Notion, 4 Excel and Outlook, 5 WhatsApp, Telegram, Slack and Spotify. Browsers, terminals and the rest open where you are.
- **Floating**: System Settings, Calculator, Activity Monitor, Archive Utility, Finder's Get Info, System Information, Disk Utility and FaceTime float instead of tiling.
