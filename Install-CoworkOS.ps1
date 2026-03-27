#Requires -Version 5.1
<#
.SYNOPSIS
    CoworkOS Windows Setup — Main Installer
.DESCRIPTION
    Installs and configures CoworkOS for Claude Max users on Windows.
    Runs all setup modules in sequence, passing shared config between them.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

# -- Banner -----------------------------------------------------------------
function Show-Banner {
    Write-Host ""
    Write-Host "+══════════════════════════════════════════════════════════════+" -ForegroundColor Cyan
    Write-Host "|                    CoworkOS Setup                           |" -ForegroundColor Cyan
    Write-Host "|           For Claude Max Plan Users on Windows              |" -ForegroundColor Cyan
    Write-Host "+══════════════════════════════════════════════════════════════+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  This wizard will set up your complete AI productivity environment:" -ForegroundColor White
    Write-Host "  - CoworkOS folder structure in your shared drive" -ForegroundColor Gray
    Write-Host "  - Desktop Commander MCP (file system + terminal access)" -ForegroundColor Gray
    Write-Host "  - Outlook MCP (email, calendar, contacts)" -ForegroundColor Gray
    Write-Host "  - Superpowers, GSD, Everything Claude Code plugins" -ForegroundColor Gray
    Write-Host "  - Auto-memory system and personalized CLAUDE.md" -ForegroundColor Gray
    Write-Host ""

    # Security reminder
    Write-Host "+══════════════════════════════════════════════════════════════+" -ForegroundColor Yellow
    Write-Host "|  SECURITY REMINDER                                          |" -ForegroundColor Yellow
    Write-Host "|  NEVER paste API keys, passwords, or tokens into Claude.    |" -ForegroundColor Yellow
    Write-Host "|  All secrets will be stored in your .env file.              |" -ForegroundColor Yellow
    Write-Host "+══════════════════════════════════════════════════════════════+" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Press Enter to begin setup..." -NoNewline
    Read-Host "  Press Enter to continue" | Out-Null
    Write-Host ""
    Write-Host ""
}

# -- Progress helper ---------------------------------------------------------
function Write-Phase {
    param([int]$Phase, [int]$Total, [string]$Name)
    Write-Host ""
    Write-Host "  [$Phase/$Total] $Name" -ForegroundColor Cyan
    Write-Host "  $('-' * 50)" -ForegroundColor DarkGray
}

# -- Log setup --------------------------------------------------------------
$logPath = Join-Path $PSScriptRoot "cowork-setup.log"
Start-Transcript -Path $logPath -Append -ErrorAction SilentlyContinue

# -- Main -------------------------------------------------------------------
try {
    Show-Banner

    # Import all modules
    $modulesDir = Join-Path $PSScriptRoot "Modules"
    $moduleFiles = @(
        "DriveDetector.psm1",
        "FolderBuilder.psm1",
        "ClaudeInstaller.psm1",
        "MCPInstaller.psm1",
        "ObsidianSetup.psm1",
        "OutlookMCP.psm1",
        "ChromeSetup.psm1",
        "PluginInstaller.psm1",
        "ProductivitySetup.psm1",
        "ConfigGenerator.psm1",
        "ProjectMigrator.psm1"
    )
    foreach ($mod in $moduleFiles) {
        $modPath = Join-Path $modulesDir $mod
        Write-Host "  Loading $mod..." -ForegroundColor DarkGray
        if (Test-Path $modPath) {
            try {
                Import-Module $modPath -Force -ErrorAction Stop
            } catch {
                throw "Failed to load module '$mod': $($_.Exception.Message)"
            }
        } else {
            Write-Warning "Module not found: $mod"
        }
    }
    Write-Host "  All modules loaded." -ForegroundColor DarkGray

    # Initialize shared config hashtable
    $Config = @{
        InstallerRoot = $PSScriptRoot
        SetupDate     = (Get-Date -Format "yyyy-MM-dd")
    }

    $totalPhases = 11

    # Phase 1: Collect user name (UserName is needed by ProductivitySetup but
    # also used in ConfigGenerator header — collect it early)
    Write-Phase 1 $totalPhases "Prerequisites & Dependencies"
    $Config = Invoke-ClaudeInstall -Config $Config

    # Phase 2: Choose shared drive
    Write-Phase 2 $totalPhases "Shared Drive Selection"
    $Config = Invoke-DriveDetection -Config $Config

    # Phase 3: Build folder structure
    Write-Phase 3 $totalPhases "CoworkOS Folder Structure"
    $Config = Invoke-FolderBuild -Config $Config

    # Phase 4: Migrate existing projects
    Write-Phase 4 $totalPhases "Migrate Existing Claude Projects"
    $Config = Invoke-ProjectMigration -Config $Config

    # Phase 5: Install MCPs
    Write-Phase 5 $totalPhases "MCP Installation (Desktop Commander)"
    $Config = Invoke-MCPInstall -Config $Config

    # Phase 6: Obsidian
    Write-Phase 6 $totalPhases "Obsidian Second Brain Setup"
    $Config = Invoke-ObsidianSetup -Config $Config

    # Phase 7: Outlook MCP
    Write-Phase 7 $totalPhases "Outlook MCP Setup"
    $Config = Invoke-OutlookMCPSetup -Config $Config

    # Phase 8: Chrome extension
    Write-Phase 8 $totalPhases "Chrome Extension Setup"
    $Config = Invoke-ChromeSetup -Config $Config

    # Phase 9: Plugins + GSD
    Write-Phase 9 $totalPhases "Plugin Installation (Superpowers, GSD, Everything Claude Code)"
    $Config = Invoke-PluginInstall -Config $Config

    # Phase 10: Productivity setup (branding, memory, legal)
    Write-Phase 10 $totalPhases "Personalization (Brand, Memory, Legal)"
    $Config = Invoke-ProductivitySetup -Config $Config

    # Phase 11: Generate config files
    Write-Phase 11 $totalPhases "Generating CLAUDE.md, MEMORY.md, .env"
    $Config = Invoke-ConfigGeneration -Config $Config

    # -- Summary -----------------------------------------------------------
    Write-Host ""
    Write-Host "+══════════════════════════════════════════════════════════════+" -ForegroundColor Green
    Write-Host "|                  Setup Complete!                            |" -ForegroundColor Green
    Write-Host "+══════════════════════════════════════════════════════════════+" -ForegroundColor Green
    Write-Host ""
    Write-Host "  CoworkOS installed at: $($Config.CoworkRoot)" -ForegroundColor White
    Write-Host "  Claude config at:      $($Config.ClaudeConfigDir)" -ForegroundColor White
    Write-Host ""
    Write-Host "  Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Open Claude Code and start a new session" -ForegroundColor Gray
    Write-Host "  2. Try: 'List my recent emails' (Outlook MCP)" -ForegroundColor Gray
    Write-Host "  3. Try: /brainstorm to start your first project" -ForegroundColor Gray
    Write-Host "  4. Try: /gsd:new-project to set up a new project" -ForegroundColor Gray
    Write-Host "  5. Run /wrap at the end of each session to capture learnings" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Read the getting started guide:" -ForegroundColor Cyan
    Write-Host "  $PSScriptRoot\docs\GETTING-STARTED.md" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Setup log saved to: $logPath" -ForegroundColor DarkGray
    Write-Host ""

} catch {
    Write-Host ""
    Write-Host "+══════════════════════════════════════════════════════════════+" -ForegroundColor Red
    Write-Host "|  Setup encountered an error                                 |" -ForegroundColor Red
    Write-Host "+══════════════════════════════════════════════════════════════+" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Error type:    $($_.Exception.GetType().Name)" -ForegroundColor Red
    Write-Host "  Error message: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Stack trace:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  See full log: $logPath" -ForegroundColor Gray
    Write-Host "  For help, check: docs\TROUBLESHOOTING.md" -ForegroundColor Gray
    Write-Host ""
} finally {
    Stop-Transcript -ErrorAction SilentlyContinue
}
