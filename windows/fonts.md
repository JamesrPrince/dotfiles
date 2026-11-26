# Fonts (Windows)

The terminal and the Zebar bar use **Maple Mono NF** (the Nerd Font build). winget has no package for it,
so `bootstrap.ps1` downloads the latest release from
[subframe7536/maple-font](https://github.com/subframe7536/maple-font/releases) and installs it for the current user.

By hand, if the script cannot find the asset:

1. Download `MapleMono-NF.zip` (not the CN or Ligature-less variants) from the releases page.
2. Unzip it, select all `.ttf` files, right-click, **Install** (per-user, no admin needed).
3. Restart WezTerm and Zebar.

Verify: `wezterm ls-fonts --list-system | Select-String "Maple Mono NF"`.
