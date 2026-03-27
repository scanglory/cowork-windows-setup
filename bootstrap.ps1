#Requires -Version 5.1
<#
.SYNOPSIS
    CoworkOS Bootstrap — Downloads and launches the CoworkOS installer
.NOTES
    Usage: irm https://raw.githubusercontent.com/scanglory/cowork-windows-setup/main/bootstrap.ps1 | iex
#>

# ── Bypass execution policy for this process only ──────────────────────────
Set-ExecutionPolicy -Scope Process Bypass -Force -ErrorAction SilentlyContinue

# ── Download and extract repo ──────────────────────────────────────────────
$repoOwner = "scanglory"
$repoName  = "cowork-windows-setup"
$branch    = "main"
$zipUrl    = "https://github.com/$repoOwner/$repoName/archive/refs/heads/$branch.zip"
$tempDir   = Join-Path $env:TEMP "cowork-setup-$([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())"
$zipPath   = "$tempDir.zip"

Write-Host "  Downloading CoworkOS setup files..." -ForegroundColor Cyan

try {
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

    # Configure proxy if detected
    $proxy = $env:HTTPS_PROXY ?? $env:HTTP_PROXY
    $iwrParams = @{ Uri = $zipUrl; OutFile = $zipPath; UseBasicParsing = $true }
    if ($proxy) { $iwrParams.Proxy = $proxy; $iwrParams.ProxyUseDefaultCredentials = $true }

    Invoke-WebRequest @iwrParams

    Write-Host "  Extracting..." -ForegroundColor Cyan
    Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force

    # Find extracted folder (GitHub adds -main suffix)
    $extractedDir = Get-ChildItem $tempDir -Directory | Select-Object -First 1

    if (-not $extractedDir) {
        throw "Failed to extract setup files."
    }

    # Unblock all downloaded scripts
    Get-ChildItem $extractedDir.FullName -Recurse -Filter "*.ps1" | ForEach-Object {
        Unblock-File $_.FullName -ErrorAction SilentlyContinue
    }
    Get-ChildItem $extractedDir.FullName -Recurse -Filter "*.psm1" | ForEach-Object {
        Unblock-File $_.FullName -ErrorAction SilentlyContinue
    }

    # Launch installer
    $installerPath = Join-Path $extractedDir.FullName "Install-CoworkOS.ps1"
    if (-not (Test-Path $installerPath)) {
        throw "Install-CoworkOS.ps1 not found in downloaded package."
    }

    Write-Host "  Launching installer..." -ForegroundColor Cyan
    Write-Host ""

    & $installerPath

} catch {
    Write-Host ""
    Write-Host "  Bootstrap error: $_" -ForegroundColor Red
    Write-Host "  Please try again or contact your Cowork administrator." -ForegroundColor Gray
    exit 1
} finally {
    # Clean up temp files
    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}
