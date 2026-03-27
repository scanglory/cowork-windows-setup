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

    # app.json — basic vault config
    $appJson = @{
        legacyEditor    = $false
        livePreview     = $true
        defaultViewMode = "source"
        vimMode         = $false
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

    # ── Step 4: Guide user to install Local REST API plugin ─────────────────────
    Write-Host ""
    Write-Host "  ─────────────────────────────────────────────────────"
    Write-Host "  Install the Obsidian Local REST API Plugin" -ForegroundColor Cyan
    Write-Host "  ─────────────────────────────────────────────────────"
    Write-Host ""
    Write-Host "  This lets Claude search and interact with your vault."
    Write-Host ""
    Write-Host "  Steps:"
    Write-Host "  1. Open Obsidian"
    Write-Host "  2. Open your CoworkOS vault: $($Config.CoworkRoot)"
    Write-Host "  3. Go to Settings → Community Plugins → Browse"
    Write-Host "  4. Search for: 'Local REST API'"
    Write-Host "  5. Install and Enable it"
    Write-Host "  6. Go to Settings → Local REST API"
    Write-Host "  7. Copy the API Key shown there"
    Write-Host ""

    # Try to open Obsidian automatically
    $obsidianExe = @(
        "${env:LOCALAPPDATA}\Obsidian\Obsidian.exe",
        "${env:PROGRAMFILES}\Obsidian\Obsidian.exe"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1

    if ($obsidianExe) {
        Write-Host "  Opening Obsidian..." -ForegroundColor Gray
        Start-Process $obsidianExe
    }

    Write-Host "  Press any key once you have the API key ready..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Write-Host ""

    # ── Step 5: Collect API key and install Obsidian MCP ────────────────────────
    $apiKey = Read-Host "  Enter your Obsidian Local REST API key" -AsSecureString
    $apiKeyPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($apiKey)
    )

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

    # ── Step 6: Recommend Smart Connections plugin ───────────────────────────────
    Write-Host "  ─────────────────────────────────────────────────────"
    Write-Host "  Recommended: Smart Connections Plugin" -ForegroundColor Yellow
    Write-Host "  ─────────────────────────────────────────────────────"
    Write-Host ""
    Write-Host "  For semantic search (find related notes by meaning):"
    Write-Host "  Settings → Community Plugins → Browse → 'Smart Connections'"
    Write-Host "  Install and enable it. Enter your Anthropic API key when prompted."
    Write-Host "  Store your API key in .env — do NOT type it directly into Obsidian."
    Write-Host ""
    Write-Host "  Press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    # ── Step 7: Return updated config ───────────────────────────────────────────
    return $Config + @{
        ObsidianSetupComplete = $true
        ObsidianVaultPath     = $Config.CoworkRoot
    }
}

Export-ModuleMember -Function Invoke-ObsidianSetup
