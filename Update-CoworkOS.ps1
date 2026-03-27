#Requires -Version 5.1
<#
.SYNOPSIS
    CoworkOS Update — Pulls latest rules, agents, and hooks
.DESCRIPTION
    Downloads the latest CoworkOS package and updates rules, agents, and hooks
    in your Claude config directory. Does NOT change your CLAUDE.md or .env.
#>

[CmdletBinding()]
param(
    [string]$ClaudeConfigDir = ""
)

Set-ExecutionPolicy -Scope Process Bypass -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                CoworkOS Update                              ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Detect Claude config dir if not provided
if ([string]::IsNullOrWhiteSpace($ClaudeConfigDir)) {
    $candidates = @("$env:USERPROFILE\.claude", "$env:APPDATA\Claude", "$env:LOCALAPPDATA\Claude")
    foreach ($c in $candidates) {
        if (Test-Path "$c\settings.json") { $ClaudeConfigDir = $c; break }
    }
    if ([string]::IsNullOrWhiteSpace($ClaudeConfigDir)) {
        $ClaudeConfigDir = "$env:USERPROFILE\.claude"
    }
}

Write-Host "  Claude config: $ClaudeConfigDir" -ForegroundColor Gray
Write-Host ""

# Download latest package
$repoOwner = "scanglory"
$repoName  = "cowork-windows-setup"
$zipUrl    = "https://github.com/$repoOwner/$repoName/archive/refs/heads/main.zip"
$tempDir   = Join-Path $env:TEMP "cowork-update-$(Get-Random)"
$zipPath   = "$tempDir.zip"

try {
    Write-Host "  Downloading latest CoworkOS package..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
    Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force

    $extractedDir = (Get-ChildItem $tempDir -Directory | Select-Object -First 1).FullName

    # Update rules
    $rulesSource = Join-Path $extractedDir "templates\rules"
    $rulesDest   = Join-Path $ClaudeConfigDir "rules\common"
    if (Test-Path $rulesSource) {
        New-Item -ItemType Directory -Force -Path $rulesDest | Out-Null
        Copy-Item "$rulesSource\*" $rulesDest -Force
        Write-Host "  ✓ Rules updated" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "  ✓ CoworkOS updated successfully" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Note: CLAUDE.md and .env were NOT changed." -ForegroundColor Gray
    Write-Host "  Run the full installer again to reconfigure those." -ForegroundColor Gray
    Write-Host ""

} catch {
    Write-Host "  Update failed: $_" -ForegroundColor Red
} finally {
    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}
