-- WezTerm: the Windows counterpart of ghostty/config (Ghostty has no Windows build).
-- Linked to %USERPROFILE%\.config\wezterm by windows\bootstrap.ps1.
local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Font: Maple Mono NF 13 (installed by bootstrap.ps1, see windows/fonts.md)
config.font = wezterm.font("Maple Mono NF")
config.font_size = 13.0

-- Window: 8px padding, 0.97 opacity, no title bar (RESIZE keeps the drag-to-resize border).
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.window_background_opacity = 0.97
config.window_decorations = "RESIZE"
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.window_close_confirmation = "NeverPrompt"

-- Gruvbox Dark (same palette as Ghostty's "Gruvbox Dark" theme).
config.colors = {
  foreground = "#ebdbb2",
  background = "#282828",
  cursor_bg = "#ebdbb2",
  cursor_fg = "#282828",
  cursor_border = "#ebdbb2",
  selection_bg = "#665c54",
  selection_fg = "#ebdbb2",
  ansi = { "#282828", "#cc241d", "#98971a", "#d79921", "#458588", "#b16286", "#689d6a", "#a89984" },
  brights = { "#928374", "#fb4934", "#b8bb26", "#fabd2f", "#83a598", "#d3869b", "#8ec07c", "#ebdbb2" },
  tab_bar = {
    background = "#282828",
    active_tab = { bg_color = "#504945", fg_color = "#ebdbb2" },
    inactive_tab = { bg_color = "#282828", fg_color = "#928374" },
    new_tab = { bg_color = "#282828", fg_color = "#928374" },
  },
}

-- Cursor: steady block.
config.default_cursor_style = "SteadyBlock"

-- Shell: PowerShell 7 (winget Microsoft.PowerShell).
config.default_prog = { "pwsh.exe", "-NoLogo" }

-- Notes on what is NOT ported:
-- * ctrl+` drop-down terminal: WezTerm has none built in. It is bound in GlazeWM instead
--   (glazewm/config.yaml launches a floating "scratch" WezTerm window on that key).
-- * Alt is left free for GlazeWM, so no Option-as-Alt setting is needed.
-- * Ghostty's cmd+d / cmd+w split keys are mapped to ctrl+shift below, since Windows has no Cmd.
config.keys = {
  { key = "d", mods = "CTRL|SHIFT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "D", mods = "CTRL|SHIFT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "w", mods = "CTRL|SHIFT", action = wezterm.action.CloseCurrentPane({ confirm = false }) },
  { key = "Enter", mods = "CTRL|SHIFT", action = wezterm.action.TogglePaneZoomState },
  { key = "LeftArrow", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Left") },
  { key = "RightArrow", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Right") },
  { key = "UpArrow", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Up") },
  { key = "DownArrow", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Down") },
}

return config
