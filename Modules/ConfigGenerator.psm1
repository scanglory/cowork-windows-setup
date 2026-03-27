function Invoke-ConfigGeneration {
    param([hashtable]$Config)

    # Step 1: Read CLAUDE.md template
    $templatePath = Join-Path $PSScriptRoot "..\templates\CLAUDE.md.template"
    if (-not (Test-Path $templatePath)) {
        throw "CLAUDE.md template not found at: $templatePath"
    }
    $claudeTemplate = Get-Content $templatePath -Raw

    # Step 2: Replace all template tokens
    $companyName = if ([string]::IsNullOrWhiteSpace($Config.CompanyName)) { 'Your Company' } else { $Config.CompanyName }
    $industry    = if ([string]::IsNullOrWhiteSpace($Config.Industry))    { 'Your Industry' } else { $Config.Industry }
    $setupDate   = Get-Date -Format 'yyyy-MM-dd'

    $claudeContent = $claudeTemplate `
        -replace '{{USER_NAME}}',    $Config.UserName `
        -replace '{{SETUP_DATE}}',   $setupDate `
        -replace '{{COWORK_ROOT}}',  $Config.CoworkRoot `
        -replace '{{DRIVE_PATH}}',   $Config.DriveRoot `
        -replace '{{COMPANY_NAME}}', $companyName `
        -replace '{{INDUSTRY}}',     $industry `
        -replace '{{TONE}}',         $Config.Tone

    # Step 3: Append dynamic installed tools section
    $toolsSection = @"

## Installed Tools & MCP Connections

**Active MCP Servers:**
$(if ($Config.DesktopCommanderInstalled) { "- Desktop Commander: Read/write files, run terminal commands, manage processes" })
$(if ($Config.OutlookMCPEnabled) { "- Outlook MCP ($($Config.OutlookAccountType)): Read/search emails, draft/send, calendar, contacts" })

**Active Plugins:**
- Superpowers: Skills system (/brainstorm, /wrap, /tdd, /debug, /review)
- Everything Claude Code: Development patterns and workflow tools
- Anthropic Skills: Additional productivity skills (/wrap, /schedule, /docx, /pdf, etc.)
- GSD: Project workflow (/gsd:new-project, /gsd:plan-phase, /gsd:execute-phase, etc.)

**CoworkOS Path:** $($Config.CoworkRoot)
"@
    $claudeContent = $claudeContent -replace '{{INSTALLED_TOOLS}}', $toolsSection
    # If placeholder wasn't in template, append tools section at end
    if ($claudeContent -notlike "*$($toolsSection.Substring(0, [Math]::Min(50, $toolsSection.Length)).Trim())*") {
        $claudeContent += "`n$toolsSection"
    }

    # Step 4: Write CLAUDE.md to two locations
    $claudeMdCowork = Join-Path $Config.CoworkRoot ".claude\CLAUDE.md"
    $claudeMdGlobal = Join-Path $Config.ClaudeConfigDir "CLAUDE.md"
    Set-Content -Path $claudeMdCowork -Value $claudeContent -Encoding UTF8
    Set-Content -Path $claudeMdGlobal -Value $claudeContent -Encoding UTF8
    Write-Host "[OK] CLAUDE.md generated" -ForegroundColor Green

    # Step 5: Generate MEMORY.md from template
    $memTemplatePath = Join-Path $PSScriptRoot "..\templates\MEMORY.md.template"
    if (-not (Test-Path $memTemplatePath)) {
        throw "MEMORY.md template not found at: $memTemplatePath"
    }
    $memTemplate = Get-Content $memTemplatePath -Raw
    $memContent = $memTemplate `
        -replace '{{USER_NAME}}',    $Config.UserName `
        -replace '{{COMPANY_NAME}}', $companyName `
        -replace '{{SETUP_DATE}}',   $setupDate `
        -replace '{{COWORK_ROOT}}',  $Config.CoworkRoot

    $memPath = Join-Path $Config.CoworkRoot ".claude\MEMORY.md"
    Set-Content -Path $memPath -Value $memContent -Encoding UTF8
    Write-Host "[OK] MEMORY.md generated" -ForegroundColor Green

    # Step 6: Generate .env file
    $envPath = Join-Path $Config.CoworkRoot ".claude\.env"
    # Only create if doesn't exist yet
    if (-not (Test-Path $envPath)) {
        $envContent = @"
# CoworkOS Environment Variables
# NEVER share this file or paste these values into Claude chat

# Anthropic
ANTHROPIC_API_KEY=your_api_key_here

# Outlook MCP
OUTLOOK_EMAIL=$(if ($Config.OutlookEmail) { $Config.OutlookEmail } else { 'your_email@outlook.com' })

# CoworkOS
COWORK_ROOT=$($Config.CoworkRoot)
"@
        Set-Content -Path $envPath -Value $envContent -Encoding UTF8
    }

    # Apply strict ACL (current user only)
    try {
        $acl = Get-Acl $envPath
        $acl.SetAccessRuleProtection($true, $false)  # Disable inheritance
        foreach ($rule in @($acl.Access)) { [void]$acl.RemoveAccessRule($rule) }
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            [System.Security.Principal.WindowsIdentity]::GetCurrent().Name,
            "FullControl",
            "Allow"
        )
        $acl.AddAccessRule($rule)
        Set-Acl -Path $envPath -AclObject $acl
        Write-Host "[OK] .env created with restricted permissions" -ForegroundColor Green
    } catch {
        Write-Warning "Could not set strict .env permissions: $_"
    }

    # Step 7: Copy .env.example to CoworkRoot
    $envExampleSrc = Join-Path $PSScriptRoot "..\templates\.env.example"
    $envExampleDest = Join-Path $Config.CoworkRoot ".claude\.env.example"
    if (Test-Path $envExampleSrc) {
        Copy-Item $envExampleSrc $envExampleDest -Force
    }

    # Step 8: Return updated config
    $newConfig = $Config.Clone()
    $newConfig['ClaudeMdPath'] = $claudeMdCowork
    $newConfig['MemoryMdPath'] = $memPath
    $newConfig['EnvPath']      = $envPath
    return $newConfig
}

Export-ModuleMember -Function Invoke-ConfigGeneration
