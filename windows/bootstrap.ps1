<#
.SYNOPSIS
  Sets up a fresh Windows 11 machine with this repo's Windows side (WezTerm, GlazeWM, Zebar, Starship, Neovim, git).
.DESCRIPTION
  Run from a normal (non-admin) PowerShell:  .\windows\bootstrap.ps1
  Idempotent: safe to re-run. Anything already in place is backed up (name.bak-<stamp>), never deleted.
  Holds no secrets. GitHub access comes from `gh auth login`, which this script prompts for.
  Untested: written without a Windows machine. Read the output; fix forward.
  Developer Mode (Settings > System > For developers) lets file links be real symlinks; without it
  files are copied instead (re-run after editing the repo copy). Directories use junctions, which need no rights.
#>
[CmdletBinding()]
param(
    [switch]$SkipPackages,
    [switch]$SkipFonts,
    [switch]$SkipVault
)
$ErrorActionPreference = 'Stop'

$Win   = $PSScriptRoot                                  # <repo>\windows
$Repo  = Split-Path $Win -Parent
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$Home_ = $env:USERPROFILE

function Say($tag, $msg) { Write-Host ("{0,-8}{1}" -f $tag, $msg) }

function Update-SessionPath {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user    = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machine;$user"
}

function Test-Command($name) { [bool](Get-Command $name -ErrorAction SilentlyContinue) }

function Backup($path) {
    $bak = "$path.bak-$Stamp"
    Move-Item -LiteralPath $path -Destination $bak
    Say 'backup' $bak
}

# Link-Item <source in repo> <destination>
function Link-Item($src, $dst) {
    $isDir = (Get-Item -LiteralPath $src).PSIsContainer
    $existing = Get-Item -LiteralPath $dst -Force -ErrorAction SilentlyContinue
    if ($existing) {
        if ($existing.LinkType -and ($existing.Target -contains $src -or $existing.Target -eq $src)) { Say 'ok' $dst; return }
        if (-not $isDir -and -not $existing.LinkType -and
            (Get-FileHash -LiteralPath $src).Hash -eq (Get-FileHash -LiteralPath $dst).Hash) { Say 'ok' "$dst (copy, identical)"; return }
        Backup $dst
    }
    New-Item -ItemType Directory -Force -Path (Split-Path $dst -Parent) | Out-Null
    if ($isDir) {
        New-Item -ItemType Junction -Path $dst -Target $src | Out-Null
        Say 'linked' "$dst (junction) -> $src"
    } else {
        try {
            New-Item -ItemType SymbolicLink -Path $dst -Target $src -ErrorAction Stop | Out-Null
            Say 'linked' "$dst -> $src"
        } catch {
            Copy-Item -LiteralPath $src -Destination $dst
            Say 'copied' "$dst (no symlink rights; turn on Developer Mode to link)"
        }
    }
}

# ---- 1. Packages -------------------------------------------------------------------------------
if (-not $SkipPackages) {
    if (-not (Test-Command winget)) { throw 'winget not found. Update "App Installer" from the Microsoft Store and re-run.' }
    Say 'winget' 'importing winget.json (already-installed packages are skipped)'
    winget import --import-file (Join-Path $Win 'winget.json') --accept-package-agreements --accept-source-agreements --ignore-unavailable
    Update-SessionPath

    # Claude Code is not in winget; it has its own installer. Asks first because it runs a remote script.
    if (-not (Test-Command claude)) {
        $a = Read-Host 'Install Claude Code now (runs: irm https://claude.ai/install.ps1 | iex)? [y/N]'
        if ($a -match '^[Yy]') { Invoke-RestMethod https://claude.ai/install.ps1 | Invoke-Expression; Update-SessionPath }
        else { Say 'skip' 'Claude Code (install later with the command above)' }
    } else { Say 'ok' 'Claude Code already installed' }
} else { Say 'skip' 'packages' }

# ---- 2. Maple Mono NF (see fonts.md) -----------------------------------------------------------
if (-not $SkipFonts) {
    $fontDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
    $already = Get-ChildItem $fontDir -Filter 'MapleMono-NF-*.ttf' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($already) { Say 'ok' 'Maple Mono NF already installed' }
    else {
        try {
            $rel   = Invoke-RestMethod 'https://api.github.com/repos/subframe7536/maple-font/releases/latest' -Headers @{ 'User-Agent' = 'dotfiles-bootstrap' }
            $asset = $rel.assets | Where-Object { $_.name -match '^MapleMono-NF(-unhinted)?\.zip$' } | Select-Object -First 1
            if (-not $asset) { throw 'no MapleMono-NF zip in the latest release' }
            $tmp = Join-Path $env:TEMP "maple-$Stamp"
            New-Item -ItemType Directory -Force -Path $tmp | Out-Null
            Invoke-WebRequest $asset.browser_download_url -OutFile "$tmp\maple.zip"
            Expand-Archive "$tmp\maple.zip" -DestinationPath "$tmp\x" -Force
            New-Item -ItemType Directory -Force -Path $fontDir | Out-Null
            $reg = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
            Get-ChildItem "$tmp\x" -Filter *.ttf -Recurse | ForEach-Object {
                Copy-Item $_.FullName (Join-Path $fontDir $_.Name) -Force
                New-ItemProperty -Path $reg -Name "$($_.BaseName) (TrueType)" -Value (Join-Path $fontDir $_.Name) -PropertyType String -Force | Out-Null
            }
            Remove-Item $tmp -Recurse -Force
            Say 'font' "installed $($asset.name) (restart WezTerm and Zebar)"
        } catch {
            Say 'WARN' "font install failed ($($_.Exception.Message)). Follow windows\fonts.md by hand."
        }
    }
} else { Say 'skip' 'fonts' }

# ---- 3. Config links ---------------------------------------------------------------------------
Link-Item (Join-Path $Win 'wezterm')                   (Join-Path $Home_ '.config\wezterm')
Link-Item (Join-Path $Win 'glazewm\config.yaml')       (Join-Path $Home_ '.glzr\glazewm\config.yaml')
Link-Item (Join-Path $Win 'zebar\gruvbox-bar')         (Join-Path $Home_ '.glzr\zebar\gruvbox-bar')
$zs = Join-Path $Home_ '.glzr\zebar\settings.json'
if (-not (Test-Path $zs)) { Link-Item (Join-Path $Win 'zebar\settings.json') $zs }
else { Say 'keep' "$zs exists; make sure its startupConfigs lists the gruvbox-bar widget (see windows\zebar\settings.json)" }
Link-Item (Join-Path $Repo 'starship\starship.toml')   (Join-Path $Home_ '.config\starship.toml')
Link-Item (Join-Path $Repo 'nvim')                     (Join-Path $env:LOCALAPPDATA 'nvim')

# git: copy the delta pager keys into the global config (same approach as install.sh). Identity is yours to set.
if (Test-Command git) {
    $deltaCfg = Join-Path $Repo 'git\delta.gitconfig'
    git config --file $deltaCfg --list | ForEach-Object {
        $k, $v = $_ -split '=', 2
        git config --global $k $v
    }
    Say 'gitcfg' 'delta settings copied into ~/.gitconfig'
    if (-not (git config --global user.name) -or -not (git config --global user.email)) {
        Say 'TODO' 'set your identity:  git config --global user.name "..."; git config --global user.email "..."  (kept out of this repo)'
    }
} else { Say 'WARN' 'git not on PATH yet; open a new shell and re-run to apply the git config' }

# ---- 4. PowerShell 7 profile: starship + zoxide ------------------------------------------------
$profilePath = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1'
New-Item -ItemType Directory -Force -Path (Split-Path $profilePath -Parent) | Out-Null
if (-not (Test-Path $profilePath)) { New-Item -ItemType File -Path $profilePath | Out-Null }
$content = Get-Content $profilePath -Raw
if ($null -eq $content) { $content = '' }
if ($content -notmatch '# >>> dotfiles >>>') {
    Copy-Item $profilePath "$profilePath.bak-$Stamp"
    $block = @'

# >>> dotfiles >>>
if (Get-Command starship -ErrorAction SilentlyContinue) { Invoke-Expression (&starship init powershell) }
if (Get-Command zoxide -ErrorAction SilentlyContinue)   { Invoke-Expression (& { (zoxide init powershell | Out-String) }) }
# <<< dotfiles <<<
'@
    Add-Content -Path $profilePath -Value $block
    Say 'profile' "added starship + zoxide to $profilePath"
} else { Say 'ok' 'PowerShell profile already set up' }

# ---- 5. Vault (private repo; needs gh auth) ----------------------------------------------------
if (-not $SkipVault) {
    $vault = Join-Path $Home_ 'ICOR'
    if (Test-Path (Join-Path $vault '.git')) { Say 'ok' "$vault already cloned" }
    elseif (-not (Test-Command gh)) { Say 'WARN' 'gh not on PATH yet; open a new shell and re-run to clone the vault' }
    else {
        gh auth status *> $null
        if ($LASTEXITCODE -ne 0) {
            Read-Host 'The vault is private. Press Enter to run `gh auth login` (choose GitHub.com, HTTPS, browser)'
            gh auth login
        }
        gh auth status *> $null
        if ($LASTEXITCODE -eq 0) {
            if (Test-Path $vault) { Say 'WARN' "$vault exists but is not a git repo; move it aside and re-run" }
            else { gh repo clone JamesrPrince/icor-vault $vault }
        } else { Say 'skip' 'vault clone (not logged in to gh). Run gh auth login, then re-run this script.' }
    }
} else { Say 'skip' 'vault' }

Say 'done' 'Sign out and back in (or start glazewm) to pick everything up. MetaTrader 5 comes from your broker.'
