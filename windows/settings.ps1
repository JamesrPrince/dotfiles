<#
.SYNOPSIS
  Windows polish to match the Mac: taskbar auto-hide, fast key repeat, no UI animations, dark mode,
  the gruvbox wallpaper with an accent colour taken from it.
.DESCRIPTION
  Per-user settings only (HKCU and SystemParametersInfo); nothing needs admin and nothing touches
  security. Idempotent. The first run saves the values it replaces to
  %LOCALAPPDATA%\dotfiles\settings-backup.json; `settings.ps1 -Undo` puts them back.
  Run by bootstrap.ps1; safe to run by hand.
#>
[CmdletBinding()]
param([switch]$Undo)
$ErrorActionPreference = 'Stop'

function Say($tag, $msg) { Write-Host ("{0,-8}{1}" -f $tag, $msg) }

if (-not ('DotfilesWin' -as [type])) {
Add-Type @'
using System; using System.Runtime.InteropServices;
public static class DotfilesWin {
  [StructLayout(LayoutKind.Sequential)] public struct APPBARDATA { public int cbSize; public IntPtr hWnd; public uint uCallbackMessage; public uint uEdge; public RECT rc; public IntPtr lParam; }
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int left, top, right, bottom; }
  [StructLayout(LayoutKind.Sequential)] public struct ANIMATIONINFO { public uint cbSize; public int iMinAnimate; }
  [DllImport("shell32.dll")] public static extern UIntPtr SHAppBarMessage(uint msg, ref APPBARDATA data);
  [DllImport("user32.dll")] public static extern IntPtr FindWindow(string cls, string name);
  [DllImport("user32.dll", SetLastError=true)] public static extern bool SystemParametersInfo(uint a, uint u, IntPtr p, uint f);
  [DllImport("user32.dll", SetLastError=true)] public static extern bool SystemParametersInfo(uint a, uint u, ref ANIMATIONINFO p, uint f);
  [DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Unicode)] public static extern bool SystemParametersInfo(uint a, uint u, string p, uint f);
  [DllImport("user32.dll", SetLastError=true)] public static extern bool SystemParametersInfo(uint a, uint u, ref bool p, uint f);
  [DllImport("user32.dll", SetLastError=true)] public static extern bool SystemParametersInfo(uint a, uint u, ref uint p, uint f);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr SendMessageTimeout(IntPtr h, uint m, UIntPtr w, string l, uint f, uint t, out UIntPtr r);

  const uint ABM_GETSTATE = 4, ABM_SETSTATE = 10;
  public static int GetTaskbarState() { var d = new APPBARDATA(); d.cbSize = Marshal.SizeOf(d); d.hWnd = FindWindow("Shell_TrayWnd", null); return (int)SHAppBarMessage(ABM_GETSTATE, ref d); }
  public static void SetTaskbarState(int s) { var d = new APPBARDATA(); d.cbSize = Marshal.SizeOf(d); d.hWnd = FindWindow("Shell_TrayWnd", null); d.lParam = (IntPtr)s; SHAppBarMessage(ABM_SETSTATE, ref d); }
  public static void Broadcast(string area) { UIntPtr r; SendMessageTimeout((IntPtr)0xffff, 0x1A, UIntPtr.Zero, area, 2, 3000, out r); }
}
'@
}

$SPIF = 3   # SPIF_UPDATEINIFILE | SPIF_SENDCHANGE
$Personalize = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
$Desktop = 'HKCU:\Control Panel\Desktop'
$BackupDir = Join-Path $env:LOCALAPPDATA 'dotfiles'
$Backup = Join-Path $BackupDir 'settings-backup.json'
$WallDir = Join-Path $env:USERPROFILE '.config\wallpapers'
# The Mac's gruvbox wallpaper: the first picture in Omarchy v4.5.0's gruvbox backgrounds (themes/theme.sh)
$WallUrl = 'https://raw.githubusercontent.com/basecamp/omarchy/v4.5.0/themes/gruvbox/backgrounds/1-the-backwater.jpg'
$Wall = Join-Path $WallDir 'gruvbox-1-the-backwater.jpg'

function Get-Current {
  $kbDelay = [uint32]0; [DotfilesWin]::SystemParametersInfo(0x16, 0, [ref]$kbDelay, 0) | Out-Null   # SPI_GETKEYBOARDDELAY
  $kbSpeed = [uint32]0; [DotfilesWin]::SystemParametersInfo(0x0A, 0, [ref]$kbSpeed, 0) | Out-Null   # SPI_GETKEYBOARDSPEED
  $ai = New-Object DotfilesWin+ANIMATIONINFO; $ai.cbSize = 8; [DotfilesWin]::SystemParametersInfo(0x48, 8, [ref]$ai, 0) | Out-Null   # SPI_GETANIMATION
  $ca = $false; [DotfilesWin]::SystemParametersInfo(0x1042, 0, [ref]$ca, 0) | Out-Null               # SPI_GETCLIENTAREAANIMATION
  $p = Get-ItemProperty $Personalize -ErrorAction SilentlyContinue
  $d = Get-ItemProperty $Desktop -ErrorAction SilentlyContinue
  [ordered]@{
    TaskbarState        = [DotfilesWin]::GetTaskbarState()
    KeyboardDelay       = $kbDelay
    KeyboardSpeed       = $kbSpeed
    MinMaxAnimation     = $ai.iMinAnimate
    ClientAreaAnimation = $ca
    AppsUseLightTheme   = if ($p) { $p.AppsUseLightTheme } else { 1 }
    SystemUsesLightTheme= if ($p) { $p.SystemUsesLightTheme } else { 0 }
    Wallpaper           = $d.Wallpaper
    WallpaperStyle      = $d.WallpaperStyle
    AutoColorization    = if ($null -ne $d.AutoColorization) { $d.AutoColorization } else { '0' }   # unset means off
  }
}

function Set-All($v) {
  # Taskbar: ABS_AUTOHIDE = 1 (ABS_ALWAYSONTOP = 2 is a no-op since Windows 7)
  [DotfilesWin]::SetTaskbarState([int]$v.TaskbarState)
  # Key repeat: delay 0 = 250 ms, speed 31 = about 30/s (the Mac: 225 ms, 33/s)
  [DotfilesWin]::SystemParametersInfo(0x17, [uint32]$v.KeyboardDelay, [IntPtr]::Zero, $SPIF) | Out-Null   # SPI_SETKEYBOARDDELAY
  [DotfilesWin]::SystemParametersInfo(0x0B, [uint32]$v.KeyboardSpeed, [IntPtr]::Zero, $SPIF) | Out-Null   # SPI_SETKEYBOARDSPEED
  # Animations: minimise/maximise, and "Animation effects" (window open/close, fades)
  $ai = New-Object DotfilesWin+ANIMATIONINFO; $ai.cbSize = 8; $ai.iMinAnimate = [int]$v.MinMaxAnimation
  [DotfilesWin]::SystemParametersInfo(0x49, 8, [ref]$ai, $SPIF) | Out-Null                               # SPI_SETANIMATION
  [DotfilesWin]::SystemParametersInfo(0x1043, 0, [IntPtr]([int][bool]$v.ClientAreaAnimation), $SPIF) | Out-Null   # SPI_SETCLIENTAREAANIMATION
  # Dark mode
  New-Item -Path $Personalize -Force | Out-Null
  Set-ItemProperty $Personalize -Name AppsUseLightTheme -Value ([int]$v.AppsUseLightTheme) -Type DWord
  Set-ItemProperty $Personalize -Name SystemUsesLightTheme -Value ([int]$v.SystemUsesLightTheme) -Type DWord
  [DotfilesWin]::Broadcast('ImmersiveColorSet')
  # Accent colour from the wallpaper, then the wallpaper (style 10 = fill)
  if ($null -ne $v.AutoColorization) { Set-ItemProperty $Desktop -Name AutoColorization -Value ([string]$v.AutoColorization) }
  if ($null -ne $v.WallpaperStyle) { Set-ItemProperty $Desktop -Name WallpaperStyle -Value ([string]$v.WallpaperStyle) }
  Set-ItemProperty $Desktop -Name TileWallpaper -Value '0'
  if ($v.Wallpaper) { [DotfilesWin]::SystemParametersInfo(0x14, 0, [string]$v.Wallpaper, $SPIF) | Out-Null }   # SPI_SETDESKWALLPAPER
}

if ($Undo) {
  if (-not (Test-Path $Backup)) { Say 'skip' "no backup at $Backup; nothing to undo"; return }
  $v = Get-Content $Backup -Raw | ConvertFrom-Json
  Set-All $v
  Remove-Item $Backup
  Say 'undo' 'taskbar, key repeat, animations, theme and wallpaper restored'
  return
}

# Save what is there now, once (a re-run must not overwrite the original values with ours)
if (-not (Test-Path $Backup)) {
  New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
  Get-Current | ConvertTo-Json | Set-Content -Path $Backup -Encoding utf8
  Say 'backup' $Backup
}

if (-not (Test-Path $Wall)) {
  New-Item -ItemType Directory -Force -Path $WallDir | Out-Null
  try { Invoke-WebRequest $WallUrl -OutFile $Wall -UseBasicParsing; Say 'wall' "downloaded $Wall" }
  catch { Say 'WARN' "wallpaper download failed ($($_.Exception.Message)); keeping the current one" }
}

Set-All ([ordered]@{
  TaskbarState = 1; KeyboardDelay = 0; KeyboardSpeed = 31; MinMaxAnimation = 0; ClientAreaAnimation = $false
  AppsUseLightTheme = 0; SystemUsesLightTheme = 0
  Wallpaper = $(if (Test-Path $Wall) { $Wall } else { $null }); WallpaperStyle = '10'; AutoColorization = '1'
})
Say 'ok' 'taskbar auto-hides; key repeat 250 ms / ~30 per s; animations off; dark mode; gruvbox wallpaper and accent'
