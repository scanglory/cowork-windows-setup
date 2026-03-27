#Requires -Version 5.1
<#
.SYNOPSIS
    CoworkOS Bootstrap — Downloads and launches the CoworkOS installer
.NOTES
    Usage: irm https://raw.githubusercontent.com/scanglory/cowork-windows-setup/main/bootstrap.ps1 | iex
#>

# ── Bypass execution policy for this process only ──────────────────────────
Set-ExecutionPolicy -Scope Process Bypass -Force -ErrorAction SilentlyContinue

# ── Password Gate ──────────────────────────────────────────────────────────
# Access is restricted to authorized Cowork users only.
# The hash below is SHA256 of the access password.
# To update: run tools\New-AccessHash.ps1 and paste the result here.
$ACCESS_HASH = "2C4788D16E505B232B7CD66D806770C4CD0630610CFB9BFF4502387A8E33673C"

function Test-AccessPassword {
    param([string]$StoredHash)

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                CoworkOS — Authorized Access Only            ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  This installer is for authorized Cowork members only." -ForegroundColor White
    Write-Host "  Contact your Cowork administrator for access." -ForegroundColor Gray
    Write-Host ""

    $attempts = 0
    $maxAttempts = 3

    while ($attempts -lt $maxAttempts) {
        $securePass = Read-Host "  Enter access password" -AsSecureString
        $plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePass)
        )

        $bytes = [System.Text.Encoding]::UTF8.GetBytes($plain)
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        $hashBytes = $sha256.ComputeHash($bytes)
        $inputHash = [System.BitConverter]::ToString($hashBytes) -replace '-', ''
        $sha256.Dispose()

        # Clear plaintext from memory immediately
        $plain = $null
        [GC]::Collect()

        if ($inputHash.ToUpper() -eq $StoredHash.ToUpper()) {
            Write-Host ""
            Write-Host "  ✓ Access granted" -ForegroundColor Green
            Write-Host ""
            return $true
        }

        $attempts++
        $remaining = $maxAttempts - $attempts
        if ($remaining -gt 0) {
            Write-Host "  ✗ Incorrect password. $remaining attempt(s) remaining." -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-Host "  ✗ Access denied. Maximum attempts reached." -ForegroundColor Red
    Write-Host ""
    return $false
}

# Validate password before doing anything else
if (-not (Test-AccessPassword -StoredHash $ACCESS_HASH)) {
    exit 1
}

# ── Download and extract repo ──────────────────────────────────────────────
$repoOwner = "scanglory"
$repoName  = "cowork-windows-setup"
$branch    = "main"
$zipUrl    = "https://github.com/$repoOwner/$repoName/archive/refs/heads/$branch.zip"
$tempDir   = Join-Path $env:TEMP "cowork-setup-$(Get-Random)"
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
