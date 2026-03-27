# OutlookMCP.psm1
# Detects Outlook account type and configures the appropriate MCP connection.

# Personal Outlook domains
$script:PersonalDomains = @(
    "outlook.com",
    "hotmail.com",
    "live.com",
    "msn.com"
)

function Invoke-OutlookMCPSetup {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    # -- Step 1: Ask if user wants Outlook MCP --------------------------------
    Write-Host ""
    $enablePrompt = Read-Host "Would you like to connect Outlook/Microsoft 365 to Claude? [Y/n] (default Y)"

    if ($enablePrompt -match '^[Nn]') {
        Write-Host "Skipping Outlook MCP setup."
        return $Config + @{ OutlookMCPEnabled = $false }
    }

    # -- Step 2: Get email and detect account type -----------------------------
    $email = ""
    while ($email -eq "") {
        $email = (Read-Host "Enter your Outlook/Microsoft email address").Trim()
        if ($email -eq "") {
            Write-Warning "Email address cannot be empty. Please try again."
        }
    }

    $domain      = ($email -split "@")[-1].ToLower()
    $accountType = if ($script:PersonalDomains -contains $domain) { "Personal" } else { "Corporate" }

    if ($accountType -eq "Personal") {
        Write-Host "Detected: Personal Outlook account"
    }
    else {
        Write-Host "Detected: Corporate Microsoft 365 account"
    }

    # -- Step 3a / 3b: Account-type-specific setup -----------------------------
    $mcpEntry  = $null
    $envVars   = @{}

    if ($accountType -eq "Personal") {
        $mcpEntry = Invoke-PersonalOutlookSetup -Config $Config -Email $email
        $envVars  = $mcpEntry.EnvVars
        $mcpEntry = $mcpEntry.McpEntry
    }
    else {
        $mcpEntry = Invoke-CorporateOutlookSetup -Config $Config -Email $email
        $envVars  = $mcpEntry.EnvVars
        $mcpEntry = $mcpEntry.McpEntry
    }

    # -- Write .env file -------------------------------------------------------
    $envDir  = "$($Config.CoworkRoot)\.claude"
    $envPath = "$envDir\.env"

    if (-not (Test-Path $envDir)) {
        try {
            New-Item -ItemType Directory -Path $envDir -Force | Out-Null
        }
        catch {
            Write-Error "Failed to create .env directory '$envDir': $_"
            throw
        }
    }

    # Read existing .env lines, then add/overwrite the new keys (immutable approach)
    $existingLines = @()
    if (Test-Path $envPath) {
        try {
            $existingLines = Get-Content -Path $envPath -ErrorAction Stop
        }
        catch {
            Write-Warning "Could not read existing .env file: $_"
        }
    }

    $newLines = Merge-EnvFileLines -ExistingLines $existingLines -NewVars $envVars

    try {
        $newLines | Set-Content -Path $envPath -Encoding UTF8
        Write-Host "Wrote credentials to $envPath"
    }
    catch {
        Write-Error "Failed to write .env file: $_"
        throw
    }

    # -- Register in settings.json ---------------------------------------------
    $settingsPath = "$($Config.ClaudeConfigDir)\settings.json"
    $settings     = Read-SettingsJson -Path $settingsPath

    $existingMcpServers = if ($settings.ContainsKey("mcpServers")) { $settings["mcpServers"] } else { @{} }
    $serverKey          = if ($accountType -eq "Personal") { "outlook-imap" } else { "outlook-msgraph" }
    $newMcpServers      = $existingMcpServers + @{ $serverKey = $mcpEntry }
    $newSettings        = $settings + @{ mcpServers = $newMcpServers }

    try {
        $newSettings | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsPath -Encoding UTF8
        Write-Host "Registered $serverKey MCP in $settingsPath"
    }
    catch {
        Write-Error "Failed to write settings.json: $_"
        throw
    }

    # -- Step 4: Test connection guidance -------------------------------------
    Write-Host ""
    Write-Host "Testing Outlook connection..."
    Write-Host ""
    Write-Host "Outlook MCP configured. Test it in Claude by asking:"
    Write-Host '  "List my 5 most recent emails"'
    Write-Host ""

    # -- Step 5: Return updated Config (immutable) -----------------------------
    return $Config + @{
        OutlookMCPEnabled  = $true
        OutlookAccountType = $accountType
        OutlookEmail       = $email
    }
}

# -- Private: Personal (IMAP) setup -------------------------------------------
function Invoke-PersonalOutlookSetup {
    param(
        [hashtable]$Config,
        [string]$Email
    )

    Write-Host ""
    Write-Host "For personal Outlook, we'll use IMAP with an app password."
    Write-Host ""
    Write-Host "Steps to create an app password:"
    Write-Host "  1. Go to account.microsoft.com/security"
    Write-Host "  2. Sign in and go to 'Advanced security options'"
    Write-Host "  3. Under 'App passwords', click 'Create a new app password'"
    Write-Host "  4. Copy the generated password"
    Write-Host ""

    # Prompt for app password securely, then convert to plain text for .env storage
    $securePassword = Read-Host "Enter your Outlook app password" -AsSecureString
    $plainPassword  = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    )

    # Install imap-mcp
    Write-Host "Installing imap-mcp via npm..."
    & npm install -g imap-mcp 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "imap-mcp global install returned exit code $LASTEXITCODE. npx fallback will be used."
    }

    $mcpEntry = @{
        command = "npx"
        args    = @("-y", "imap-mcp")
        env     = @{
            IMAP_USER     = $Email
            IMAP_PASSWORD = "`$OUTLOOK_APP_PASSWORD"
            IMAP_HOST     = "outlook.office365.com"
            IMAP_PORT     = "993"
        }
    }

    $envVars = @{
        OUTLOOK_EMAIL        = $Email
        OUTLOOK_APP_PASSWORD = $plainPassword
    }

    return @{
        McpEntry = $mcpEntry
        EnvVars  = $envVars
    }
}

# -- Private: Corporate (Microsoft Graph) setup --------------------------------
function Invoke-CorporateOutlookSetup {
    param(
        [hashtable]$Config,
        [string]$Email
    )

    Write-Host ""
    Write-Host "For corporate Microsoft 365, we'll use Microsoft Graph API with device code authentication."
    Write-Host "This is the most reliable method for accounts with multi-factor authentication."
    Write-Host ""
    Write-Host "You'll need to register an application in Azure Active Directory:"
    Write-Host "  1. Go to portal.azure.com -> Azure Active Directory -> App Registrations"
    Write-Host "  2. Click 'New registration'"
    Write-Host "  3. Name: 'CoworkOS Claude Integration'"
    Write-Host "  4. Supported account type: 'Accounts in this organizational directory only'"
    Write-Host "  5. Click Register"
    Write-Host "  6. Copy the 'Application (client) ID' and 'Directory (tenant) ID'"
    Write-Host "  7. Go to 'API permissions' -> Add permission -> Microsoft Graph -> Delegated"
    Write-Host "  8. Add: Mail.Read, Mail.Send, Calendars.Read, Calendars.ReadWrite, Contacts.Read"
    Write-Host "  9. Click 'Grant admin consent' (or ask your IT admin)"
    Write-Host ""

    $clientId = ""
    while ($clientId -eq "") {
        $clientId = (Read-Host "Enter your Application (client) ID").Trim()
        if ($clientId -eq "") {
            Write-Warning "Client ID cannot be empty. Please try again."
        }
    }

    $tenantId = ""
    while ($tenantId -eq "") {
        $tenantId = (Read-Host "Enter your Directory (tenant) ID").Trim()
        if ($tenantId -eq "") {
            Write-Warning "Tenant ID cannot be empty. Please try again."
        }
    }

    # Attempt to install a Microsoft Graph MCP package
    Write-Host "Installing Microsoft Graph MCP server..."
    & npm install -g @modelcontextprotocol/server-msgraph 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "@modelcontextprotocol/server-msgraph not found or failed to install."
        Write-Warning "Contact your Cowork administrator for the Microsoft Graph MCP setup guide."
        Write-Warning "A placeholder entry will be added to settings.json."
    }

    $mcpEntry = @{
        command = "npx"
        args    = @("-y", "@modelcontextprotocol/server-msgraph")
        env     = @{
            MSGRAPH_CLIENT_ID = "`$OUTLOOK_CLIENT_ID"
            MSGRAPH_TENANT_ID = "`$OUTLOOK_TENANT_ID"
            MSGRAPH_USER      = $Email
        }
    }

    $envVars = @{
        OUTLOOK_CLIENT_ID = $clientId
        OUTLOOK_TENANT_ID = $tenantId
        OUTLOOK_EMAIL     = $Email
    }

    return @{
        McpEntry = $mcpEntry
        EnvVars  = $envVars
    }
}

# -- Private: Read settings.json, return hashtable (or empty if missing) -------
function Read-SettingsJson {
    param([string]$Path)

    if (-not (Test-Path $Path)) { return @{} }

    try {
        $rawJson = Get-Content -Path $Path -Raw -ErrorAction Stop
        $parsed  = $rawJson | ConvertFrom-Json -ErrorAction Stop
        return ConvertTo-Hashtable $parsed
    }
    catch {
        Write-Warning "Could not parse settings.json ($_ ). Starting with empty settings."
        return @{}
    }
}

# -- Private: Merge new env vars into existing .env lines (immutable) ----------
function Merge-EnvFileLines {
    param(
        [string[]]$ExistingLines,
        [hashtable]$NewVars
    )

    # Build a map of keys already present so we can replace rather than duplicate
    $existingMap = @{}
    foreach ($line in $ExistingLines) {
        if ($line -match '^([^#=]+)=(.*)$') {
            $existingMap[$Matches[1].Trim()] = $line
        }
    }

    # Overwrite keys that appear in NewVars; keep all others unchanged
    $updatedMap = $existingMap.Clone()
    foreach ($key in $NewVars.Keys) {
        $updatedMap[$key] = "$key=$($NewVars[$key])"
    }

    # Rebuild lines: preserve original order then append any brand-new keys
    $outputLines = @()
    foreach ($line in $ExistingLines) {
        if ($line -match '^([^#=]+)=') {
            $key = $Matches[1].Trim()
            $outputLines += $updatedMap[$key]
            $updatedMap.Remove($key)    # mark as emitted
        }
        else {
            $outputLines += $line       # comments / blank lines preserved as-is
        }
    }

    # Append keys that did not exist before
    foreach ($key in $NewVars.Keys) {
        if ($updatedMap.ContainsKey($key)) {
            $outputLines += "$key=$($NewVars[$key])"
        }
    }

    return $outputLines
}

# -- Private: recursively convert PSCustomObject -> hashtable ------------------
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

Export-ModuleMember -Function Invoke-OutlookMCPSetup
