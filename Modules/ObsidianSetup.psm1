function Invoke-ObsidianSetup {
    param([hashtable]$Config)

    # ── Header ──────────────────────────────────────────────────────────────────
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  Obsidian Second Brain Setup" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Your CoworkOS folder will be your Obsidian vault."
    Write-Host "  Claude will read and write notes directly to it."
    Write-Host ""

    # ── Step 1: Check / install Obsidian ────────────────────────────────────────
    $obsidianInstalled = $false
    if (Test-Path "${env:LOCALAPPDATA}\Obsidian\Obsidian.exe") { $obsidianInstalled = $true }
    if (Test-Path "${env:PROGRAMFILES}\Obsidian\Obsidian.exe") { $obsidianInstalled = $true }
    if (Get-Command obsidian -ErrorAction SilentlyContinue)    { $obsidianInstalled = $true }

    if (-not $obsidianInstalled) {
        Write-Host "  Obsidian not found. Installing via winget..." -ForegroundColor Cyan
        winget install Obsidian.Obsidian --accept-source-agreements --accept-package-agreements
        # Refresh PATH
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
                    [System.Environment]::GetEnvironmentVariable("PATH", "User")
    } else {
        Write-Host "  ✓ Obsidian is already installed" -ForegroundColor Green
    }

    # ── Step 2: Initialize CoworkOS folder as Obsidian vault ────────────────────
    $obsidianDir = Join-Path $Config.CoworkRoot ".obsidian"
    New-Item -ItemType Directory -Force -Path $obsidianDir | Out-Null

    # app.json — basic vault config (community plugins must be enabled here)
    $appJson = @{
        legacyEditor            = $false
        livePreview             = $true
        defaultViewMode         = "source"
        vimMode                 = $false
    } | ConvertTo-Json
    Set-Content -Path "$obsidianDir\app.json" -Value $appJson -Encoding UTF8


    # appearance.json
    $appearanceJson = @{
        theme = "moonstone"
    } | ConvertTo-Json
    Set-Content -Path "$obsidianDir\appearance.json" -Value $appearanceJson -Encoding UTF8

    # core-plugins.json — enable key built-ins
    $corePlugins = @(
        "file-explorer", "global-search", "switcher", "backlink", "canvas",
        "outgoing-link", "tag-pane", "properties", "daily-notes", "templates",
        "note-composer", "command-palette", "bookmarks", "outline", "word-count"
    ) | ConvertTo-Json
    Set-Content -Path "$obsidianDir\core-plugins.json" -Value $corePlugins -Encoding UTF8

    Write-Host "  ✓ Obsidian vault initialized at: $($Config.CoworkRoot)" -ForegroundColor Green

    # ── Step 3: Create vault-level .claude folder and hooks config ───────────────
    $vaultClaudeDir = Join-Path $Config.CoworkRoot ".claude"
    New-Item -ItemType Directory -Force -Path $vaultClaudeDir | Out-Null

    $vaultSettings = @{
        hooks = @{
            SessionStart = @(
                @{
                    matcher = ""
                    hooks   = @(@{
                        type    = "command"
                        command = "node `"$($Config.ClaudeConfigDir)\hooks\gsd-check-update.js`""
                    })
                }
            )
            PostToolUse  = @(
                @{
                    matcher = ""
                    hooks   = @(@{
                        type    = "command"
                        command = "node `"$($Config.ClaudeConfigDir)\hooks\gsd-context-monitor.js`""
                    })
                }
            )
        }
    } | ConvertTo-Json -Depth 10
    Set-Content -Path "$vaultClaudeDir\settings.json" -Value $vaultSettings -Encoding UTF8
    Write-Host "  ✓ Vault Claude hooks configured" -ForegroundColor Green

    # ── Step 4: Auto-install Local REST API plugin from GitHub ──────────────────
    Write-Host ""
    Write-Host "  Installing Obsidian Local REST API plugin..." -ForegroundColor Cyan

    $pluginId  = "obsidian-local-rest-api"
    $pluginDir = Join-Path $obsidianDir "plugins\$pluginId"
    New-Item -ItemType Directory -Force -Path $pluginDir | Out-Null

    # Fetch latest release metadata from GitHub API
    $releaseApi = "https://api.github.com/repos/coddingtonbear/obsidian-local-rest-api/releases/latest"
    try {
        $iwrParams = @{ Uri = $releaseApi; UseBasicParsing = $true; Headers = @{ 'User-Agent' = 'CoworkOS-Setup' } }
        if ($Config.Proxy) { $iwrParams.Proxy = $Config.Proxy; $iwrParams.ProxyUseDefaultCredentials = $true }
        $releaseInfo = Invoke-WebRequest @iwrParams | ConvertFrom-Json
        $tag = $releaseInfo.tag_name

        # Download main.js, manifest.json, styles.css from the release assets
        $baseUrl = "https://github.com/coddingtonbear/obsidian-local-rest-api/releases/download/$tag"
        foreach ($file in @("main.js", "manifest.json", "styles.css")) {
            $fileParams = @{
                Uri             = "$baseUrl/$file"
                OutFile         = "$pluginDir\$file"
                UseBasicParsing = $true
            }
            if ($Config.Proxy) { $fileParams.Proxy = $Config.Proxy; $fileParams.ProxyUseDefaultCredentials = $true }
            try { Invoke-WebRequest @fileParams } catch { <# styles.css is optional #> }
        }
        Write-Host "  ✓ Plugin files downloaded ($tag)" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Could not download plugin automatically: $_" -ForegroundColor Red
        Write-Host "  Manual install: Settings → Community Plugins → Browse → 'Local REST API'" -ForegroundColor Yellow
    }

    # Enable the plugin in community-plugins.json
    $cpPath = Join-Path $obsidianDir "community-plugins.json"
    $enabledPlugins = if (Test-Path $cpPath) {
        Get-Content $cpPath -Raw | ConvertFrom-Json
    } else {
        @()
    }
    if ($enabledPlugins -notcontains $pluginId) {
        $enabledPlugins = @($enabledPlugins) + $pluginId
    }
    Set-Content -Path $cpPath -Value ($enabledPlugins | ConvertTo-Json) -Encoding UTF8

    # Generate a cryptographically random API key
    $keyBytes = New-Object byte[] 32
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($keyBytes)
    $apiKeyPlain = [System.BitConverter]::ToString($keyBytes) -replace '-', ''

    # Write plugin data.json with pre-set API key (plugin reads this on startup)
    $pluginData = @{
        apiKey              = $apiKeyPlain
        port                = 27123
        bindingHost         = "127.0.0.1"
        enableInsecureServer = $false
    } | ConvertTo-Json
    Set-Content -Path "$pluginDir\data.json" -Value $pluginData -Encoding UTF8

    Write-Host "  ✓ Local REST API plugin configured (API key pre-generated)" -ForegroundColor Green

    # Install obsidian-mcp npm package
    Write-Host ""
    Write-Host "  Installing Obsidian MCP connector..." -ForegroundColor Cyan
    if ($Config.IsAdmin) {
        npm install -g mcp-obsidian 2>&1 | Out-Null
    } else {
        $npmPrefix = "$env:USERPROFILE\.npm-global"
        npm install --prefix $npmPrefix mcp-obsidian 2>&1 | Out-Null
    }

    # Register in Claude settings.json
    $settingsPath = "$($Config.ClaudeConfigDir)\settings.json"
    $settingsRaw  = if (Test-Path $settingsPath) { Get-Content $settingsPath -Raw } else { '{}' }
    $settings     = $settingsRaw | ConvertFrom-Json

    $mcpEntry = @{
        command = "npx"
        args    = @("-y", "mcp-obsidian")
        env     = @{
            OBSIDIAN_API_KEY = "OBSIDIAN_API_KEY_FROM_ENV"
            OBSIDIAN_HOST    = "127.0.0.1"
            OBSIDIAN_PORT    = "27123"
        }
    }

    if (-not $settings.mcpServers) {
        $settings | Add-Member -NotePropertyName mcpServers -NotePropertyValue @{}
    }
    $settings.mcpServers | Add-Member -NotePropertyName "obsidian" -NotePropertyValue $mcpEntry -Force
    Set-Content -Path $settingsPath -Value ($settings | ConvertTo-Json -Depth 10) -Encoding UTF8

    # Write API key to .env
    $envPath  = Join-Path $Config.CoworkRoot ".claude\.env"
    $envLines = if (Test-Path $envPath) { Get-Content $envPath } else { @() }
    $envLines = $envLines | Where-Object { $_ -notmatch '^OBSIDIAN_API_KEY=' }
    $envLines += "OBSIDIAN_API_KEY=$apiKeyPlain"
    Set-Content -Path $envPath -Value $envLines -Encoding UTF8

    # Clear from memory
    $apiKeyPlain = $null
    [GC]::Collect()

    Write-Host "  ✓ Obsidian MCP configured" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Test it in Claude: 'Search my vault for project notes'"
    Write-Host ""

    # ── Step 6: Prompt user to open Obsidian and enable community plugins ────────
    Write-Host ""
    Write-Host "  ─────────────────────────────────────────────────────"
    Write-Host "  One Manual Step Required" -ForegroundColor Yellow
    Write-Host "  ─────────────────────────────────────────────────────"
    Write-Host ""
    Write-Host "  Obsidian blocks community plugins until you approve them once."
    Write-Host ""
    Write-Host "  1. Open Obsidian and select your CoworkOS vault"
    Write-Host "  2. Go to Settings → Community Plugins"
    Write-Host "  3. Click 'Turn off Restricted Mode'"
    Write-Host "  4. Click 'Enable' on 'Local REST API' (already installed)"
    Write-Host ""
    Write-Host "  Your API key is already set — no need to copy anything." -ForegroundColor Green
    Write-Host ""

    $obsidianExe = @(
        "${env:LOCALAPPDATA}\Obsidian\Obsidian.exe",
        "${env:PROGRAMFILES}\Obsidian\Obsidian.exe"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($obsidianExe) {
        Write-Host "  Opening Obsidian..." -ForegroundColor Gray
        Start-Process $obsidianExe
    }

    Write-Host "  Press Enter when done..."
    Read-Host "  Press Enter to continue" | Out-Null
    Write-Host ""

    # ── Step 7: Recommend Smart Connections plugin ───────────────────────────────
    Write-Host "  ─────────────────────────────────────────────────────"
    Write-Host "  Recommended: Smart Connections Plugin" -ForegroundColor Yellow
    Write-Host "  ─────────────────────────────────────────────────────"
    Write-Host ""
    Write-Host "  For semantic search (find related notes by meaning):"
    Write-Host "  Settings → Community Plugins → Browse → 'Smart Connections'"
    Write-Host "  Install and enable it. Enter your Anthropic API key when prompted."
    Write-Host "  Store your API key in .env — do NOT type it directly into Obsidian."
    Write-Host ""
    Write-Host "  Press Enter to continue..."
    Read-Host "  Press Enter to continue" | Out-Null

    # ── Step 7: Return updated config ───────────────────────────────────────────
    return $Config + @{
        ObsidianSetupComplete = $true
        ObsidianVaultPath     = $Config.CoworkRoot
    }
}

Export-ModuleMember -Function Invoke-ObsidianSetup
