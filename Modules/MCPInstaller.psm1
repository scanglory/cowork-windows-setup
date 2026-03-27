# MCPInstaller.psm1
# Installs Desktop Commander MCP and registers it in Claude's settings.json.

function Invoke-MCPInstall {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    # -- Step 1: Backup settings.json -----------------------------------------
    $settingsPath = "$($Config.ClaudeConfigDir)\settings.json"

    if (Test-Path $settingsPath) {
        $backupPath = "$settingsPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        try {
            Copy-Item $settingsPath $backupPath
            Write-Host "Backed up settings.json -> $backupPath"
        }
        catch {
            Write-Warning "Could not back up settings.json: $_"
        }
    }

    # -- Step 2: Install Desktop Commander ------------------------------------
    if ($Config.IsAdmin) {
        Write-Host "Installing Desktop Commander globally (admin)..."
        $null = & npm install -g @wonderwhy-er/desktop-commander 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Global npm install returned exit code $LASTEXITCODE. Continuing..."
        }
    }
    else {
        $npmPrefix = "$env:USERPROFILE\.npm-global"
        Write-Host "Installing Desktop Commander to user prefix: $npmPrefix ..."

        $null = & npm install --prefix $npmPrefix @wonderwhy-er/desktop-commander 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "npm install --prefix returned exit code $LASTEXITCODE. Continuing..."
        }

        # Persist PATH for this session and for the user environment
        $env:PATH = "$npmPrefix\bin;$env:PATH"
        $currentUserPath = [Environment]::GetEnvironmentVariable("PATH", "User")
        if ($currentUserPath -notlike "*$npmPrefix\bin*") {
            [Environment]::SetEnvironmentVariable(
                "PATH",
                "$npmPrefix\bin;$currentUserPath",
                "User"
            )
            Write-Host "Added $npmPrefix\bin to user PATH."
        }
    }

    # -- Step 3: Verify install ------------------------------------------------
    # desktop-commander is an MCP server, not a standalone CLI — verify via npm list
    $npmList = & npm list -g @wonderwhy-er/desktop-commander 2>&1
    if ($npmList -match "wonderwhy-er") {
        Write-Host "Desktop Commander installed OK."
    } else {
        Write-Warning "Desktop Commander may not have installed correctly. Continuing..."
    }

    # -- Step 4: Register in settings.json ------------------------------------
    $settingsDir = $Config.ClaudeConfigDir

    if (-not (Test-Path $settingsDir)) {
        try {
            New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
        }
        catch {
            Write-Error "Failed to create settings directory '$settingsDir': $_"
            throw
        }
    }

    # Read existing settings or start with empty object
    $settings = @{}
    if (Test-Path $settingsPath) {
        try {
            $rawJson = Get-Content -Path $settingsPath -Raw -ErrorAction Stop
            $parsed  = $rawJson | ConvertFrom-Json -ErrorAction Stop

            # Convert PSCustomObject to nested hashtable so we can merge safely
            $settings = ConvertTo-Hashtable $parsed
        }
        catch {
            Write-Warning "Could not parse existing settings.json ($_ ). Starting with empty settings."
            $settings = @{}
        }
    }

    # Build the desktop-commander MCP entry — run via npx (not a standalone binary)
    $dcEntry = @{
        command = "npx"
        args    = @("-y", "@wonderwhy-er/desktop-commander")
    }

    # Merge mcpServers — never mutate existing hashtable, build new ones
    $existingMcpServers = if ($settings.ContainsKey("mcpServers")) { $settings["mcpServers"] } else { @{} }
    $newMcpServers      = $existingMcpServers + @{ "desktop-commander" = $dcEntry }
    $newSettings        = $settings + @{ mcpServers = $newMcpServers }

    try {
        $newSettings | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsPath -Encoding UTF8
        Write-Host "Registered desktop-commander in $settingsPath"
    }
    catch {
        Write-Error "Failed to write settings.json: $_"
        throw
    }

    Write-Host ""
    Write-Host "Desktop Commander MCP installation complete."

    # -- Step 5: Return updated Config (immutable) -----------------------------
    return $Config + @{ DesktopCommanderInstalled = $true }
}

# -- Private helper: recursively convert PSCustomObject -> hashtable ------------
function ConvertTo-Hashtable {
    param([object]$InputObject)

    if ($null -eq $InputObject) { return $null }

    if ($InputObject -is [System.Management.Automation.PSCustomObject]) {
        $result = @{}
        foreach ($prop in $InputObject.PSObject.Properties) {
            $result[$prop.Name] = ConvertTo-Hashtable $prop.Value
        }
        return $result
    }

    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        return @($InputObject | ForEach-Object { ConvertTo-Hashtable $_ })
    }

    return $InputObject
}

Export-ModuleMember -Function Invoke-MCPInstall
