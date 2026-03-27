# ClaudeInstaller.psm1
# Installs and verifies prerequisites: Claude Code, Node.js, Git.

# Private helper: refresh PATH from machine and user environment variables
function Refresh-Path {
    $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    $userPath    = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $env:PATH    = "$machinePath;$userPath"
}

# Exported helper: locate the Claude config directory
function Get-ClaudeConfigDir {
    $candidates = @(
        "$env:USERPROFILE\.claude",
        "$env:APPDATA\Claude",
        "$env:LOCALAPPDATA\Claude"
    )

    foreach ($dir in $candidates) {
        if (Test-Path (Join-Path $dir "settings.json")) {
            return $dir
        }
    }

    return "$env:USERPROFILE\.claude"
}

function Invoke-ClaudeInstall {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    # ── Step 1: Proxy detection ──────────────────────────────────────────────
    $proxy = if ($env:HTTPS_PROXY) { $env:HTTPS_PROXY } elseif ($env:HTTP_PROXY) { $env:HTTP_PROXY } else { $null }

    if (-not $proxy) {
        $ieSettings = Get-ItemProperty `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" `
            -ErrorAction SilentlyContinue
        if ($ieSettings -and $ieSettings.ProxyEnable -eq 1 -and $ieSettings.ProxyServer) {
            $proxy = "http://$($ieSettings.ProxyServer)"
        }
    }

    if ($proxy) {
        Write-Host "Proxy detected: $proxy. Configuring npm..."
        & npm config set proxy $proxy 2>$null
        & npm config set https-proxy $proxy 2>$null
    }

    # ── Step 2: SmartScreen warning ──────────────────────────────────────────
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║  Windows may show security prompts during install.   ║" -ForegroundColor Yellow
    Write-Host "║  If SmartScreen appears: 'More info' → 'Run anyway' ║" -ForegroundColor Yellow
    Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""

    # ── Step 3: Check / install Node.js ─────────────────────────────────────
    $nodeCmd = Get-Command node -ErrorAction SilentlyContinue

    if (-not $nodeCmd) {
        Write-Host "Node.js not found. Installing via winget..."
        & winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
        Refresh-Path
    }
    else {
        # Check version — require 18+
        $nodeVersionRaw = & node --version 2>&1
        # Format: v20.11.0
        if ($nodeVersionRaw -match '^v(\d+)') {
            $nodeMajor = [int]$Matches[1]
            if ($nodeMajor -lt 18) {
                Write-Host "Node.js $nodeVersionRaw is below v18. Installing nvm-windows and upgrading..."
                & winget install CoreyButler.NVMforWindows --accept-source-agreements --accept-package-agreements
                Refresh-Path
                & nvm install 20
                & nvm use 20
                Refresh-Path
            }
            else {
                Write-Host "Node.js $nodeVersionRaw detected — OK."
            }
        }
        else {
            Write-Warning "Could not parse Node.js version from: $nodeVersionRaw"
        }
    }

    # Verify node is accessible
    $nodeVerify = & node --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Node.js verification failed after install. Output: $nodeVerify"
        throw "Node.js installation could not be verified."
    }
    Write-Host "Node.js verified: $nodeVerify"

    # ── Step 4: Check / install Git ──────────────────────────────────────────
    $gitCmd = Get-Command git -ErrorAction SilentlyContinue

    if (-not $gitCmd) {
        Write-Host "Git not found. Installing via winget..."
        & winget install Git.Git --accept-source-agreements --accept-package-agreements
        Refresh-Path
    }
    else {
        Write-Host "Git detected — OK."
    }

    # Verify git is accessible
    $gitVerify = & git --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Git verification failed after install. Output: $gitVerify"
        throw "Git installation could not be verified."
    }
    Write-Host "Git verified: $gitVerify"

    # ── Step 5: Check Claude Code ────────────────────────────────────────────
    $claudeCmd = Get-Command claude -ErrorAction SilentlyContinue

    if (-not $claudeCmd) {
        Write-Host ""
        Write-Host "Claude Code not found."
        Write-Host "Please download and install Claude Code from: claude.ai/download"
        Write-Host "After installing, restart this terminal and run the setup again."
        Write-Host ""
        Write-Host "Press any key once Claude Code is installed to continue..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

        Refresh-Path
        $claudeCmd = Get-Command claude -ErrorAction SilentlyContinue

        if (-not $claudeCmd) {
            Write-Error "Claude Code still not found after waiting. Please install it from claude.ai/download and re-run setup."
            throw "Claude Code installation could not be verified."
        }
    }
    else {
        Write-Host "Claude Code detected — OK."
    }

    # ── Step 6: Detect (or create) Claude config dir ─────────────────────────
    $claudeConfigDir = Get-ClaudeConfigDir

    if (-not (Test-Path $claudeConfigDir)) {
        try {
            New-Item -ItemType Directory -Path $claudeConfigDir -Force | Out-Null
            Write-Host "Created Claude config directory: $claudeConfigDir"
        }
        catch {
            Write-Error "Failed to create Claude config directory '$claudeConfigDir': $_"
            throw
        }
    }
    else {
        Write-Host "Claude config directory: $claudeConfigDir"
    }

    # ── Step 7: Detect admin status ──────────────────────────────────────────
    $currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if ($isAdmin) {
        Write-Host "Running with administrator privileges."
    }
    else {
        Write-Host "Running without administrator privileges (some steps may require elevation)."
    }

    Write-Host ""
    Write-Host "Prerequisites check complete."

    # Return new Config hashtable with additional keys added (immutable pattern)
    return $Config + @{
        ClaudeConfigDir = $claudeConfigDir
        IsAdmin         = $isAdmin
        Proxy           = $proxy
    }
}

Export-ModuleMember -Function Invoke-ClaudeInstall, Get-ClaudeConfigDir
