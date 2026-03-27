function Invoke-PluginInstall {
    param([hashtable]$Config)

    # Step 1: Install plugins via claude plugin install
    $plugins = @(
        'superpowers@claude-plugins-official',
        'everything-claude-code@everything-claude-code',
        'anthropic-skills@claude-plugins-official'
    )

    foreach ($pluginName in $plugins) {
        Write-Host "Installing $pluginName..."
        $result = & claude plugin install $pluginName 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Plugin $pluginName installation may have failed: $result"
        } else {
            Write-Host "✓ $pluginName installed" -ForegroundColor Green
        }
    }

    # Step 2: Install GSD (Get Shit Done)
    Write-Host ""
    Write-Host "Installing GSD (Get Shit Done)..."
    $gsdInstalled = $false

    if ($Config.IsAdmin) {
        $gsdResult = & npm install -g get-shit-done-cc 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ GSD installed globally" -ForegroundColor Green
            $gsdInstalled = $true
        } else {
            Write-Warning "Global GSD install failed: $gsdResult"
        }
    }

    if (-not $gsdInstalled) {
        # Try local prefix install
        $localPrefix = Join-Path $env:APPDATA "npm"
        $gsdResult = & npm install --prefix $localPrefix get-shit-done-cc 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ GSD installed to local prefix: $localPrefix" -ForegroundColor Green
            $gsdInstalled = $true
        } else {
            Write-Warning "Local GSD install failed: $gsdResult"
            # Check if already available via npx
            $npxCheck = & npx get-shit-done-cc --version 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ GSD is available via npx (version: $npxCheck)" -ForegroundColor Green
                $gsdInstalled = $true
            } else {
                Write-Warning "GSD could not be installed or found. You may need to install it manually: npm install -g get-shit-done-cc"
            }
        }
    }

    Write-Host ""
    Write-Host "GSD provides /gsd:new-project, /gsd:plan-phase and other workflow commands"

    # Step 3: Verify plugins
    Write-Host ""
    Write-Host "Verifying installed plugins..."
    $pluginList = & claude plugin list 2>&1
    if ($pluginList -notmatch 'superpowers') {
        Write-Warning "Could not confirm 'superpowers' plugin is listed. Claude CLI version differences may affect output format."
    } else {
        Write-Host "✓ Plugin verification passed" -ForegroundColor Green
    }

    # Step 4: Install GSD agents and rules into Claude config dir
    $agentsSource = Join-Path $PSScriptRoot "..\agents"
    $claudeAgentsDir = Join-Path $Config.ClaudeConfigDir "agents"

    # Check if GSD already installed agents to Claude config dir
    if (Test-Path $claudeAgentsDir) {
        $existingAgents = Get-ChildItem $claudeAgentsDir -Filter "*.md" -ErrorAction SilentlyContinue
        if ($existingAgents.Count -gt 0) {
            Write-Host "✓ GSD agents already present in $claudeAgentsDir" -ForegroundColor Green
        } else {
            Write-Host "GSD agents will be available after your first GSD session"
        }
    } else {
        Write-Host "GSD agents will be available after your first GSD session"
    }

    # Copy rules from repo's templates\rules\ to ClaudeConfigDir\rules\common\
    $rulesSource = Join-Path $PSScriptRoot "..\templates\rules"
    $rulesDest = Join-Path $Config.ClaudeConfigDir "rules\common"
    if (Test-Path $rulesSource) {
        New-Item -ItemType Directory -Force -Path $rulesDest | Out-Null
        Copy-Item "$rulesSource\*" $rulesDest -Force
        Write-Host "✓ Rules deployed to $rulesDest" -ForegroundColor Green
    }

    # Step 5: Configure GSD hooks in settings.json
    $hooksSource = Join-Path $PSScriptRoot "..\hooks"
    $hooksDest = Join-Path $Config.ClaudeConfigDir "hooks"

    if (Test-Path $hooksSource) {
        New-Item -ItemType Directory -Force -Path $hooksDest | Out-Null
        Copy-Item "$hooksSource\*" $hooksDest -Force
        Write-Host "✓ Hooks deployed to $hooksDest" -ForegroundColor Green
    }

    # Register hooks in settings.json
    $settingsPath = Join-Path $Config.ClaudeConfigDir "settings.json"
    $hookCommandBase = "$env:USERPROFILE\.claude\hooks"

    $hooksConfig = @{
        hooks = @{
            SessionStart = @(
                @{
                    matcher = ""
                    hooks   = @(
                        @{
                            type    = "command"
                            command = "node $hookCommandBase\gsd-check-update.js"
                        }
                    )
                }
            )
            PostToolUse  = @(
                @{
                    matcher = ""
                    hooks   = @(
                        @{
                            type    = "command"
                            command = "node $hookCommandBase\gsd-context-monitor.js"
                        }
                    )
                }
            )
        }
    }

    if (Test-Path $settingsPath) {
        try {
            $existingSettings = Get-Content $settingsPath -Raw | ConvertFrom-Json -ErrorAction Stop
            $settingsHash = @{}
            $existingSettings.PSObject.Properties | ForEach-Object { $settingsHash[$_.Name] = $_.Value }
            $mergedSettings = $settingsHash + @{ hooks = $hooksConfig.hooks }
            $mergedSettings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath
            Write-Host "✓ Hooks registered in settings.json" -ForegroundColor Green
        } catch {
            Write-Warning "Could not update settings.json with hooks: $_"
        }
    } else {
        try {
            New-Item -ItemType Directory -Force -Path (Split-Path $settingsPath) | Out-Null
            $hooksConfig | ConvertTo-Json -Depth 10 | Set-Content $settingsPath
            Write-Host "✓ settings.json created with hooks configuration" -ForegroundColor Green
        } catch {
            Write-Warning "Could not create settings.json: $_"
        }
    }

    # Step 6: Return updated config
    return $Config + @{
        PluginsInstalled = $true
        GSDInstalled     = $gsdInstalled
    }
}

Export-ModuleMember -Function Invoke-PluginInstall
