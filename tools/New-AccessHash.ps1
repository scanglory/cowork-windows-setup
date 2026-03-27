<#
.SYNOPSIS
    Generate a SHA256 hash for use as the CoworkOS access password.
.DESCRIPTION
    Run this script locally to generate the hash for your access password.
    Copy the output hash and paste it into bootstrap.ps1 as the ACCESS_HASH value.

    NEVER share the plaintext password. Only share the bootstrap.ps1 (with hash).

.EXAMPLE
    .\tools\New-AccessHash.ps1
#>

Write-Host ""
Write-Host "CoworkOS — Password Hash Generator" -ForegroundColor Cyan
Write-Host "───────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""
Write-Host "This generates a SHA256 hash of your access password." -ForegroundColor White
Write-Host "Paste the result into bootstrap.ps1 as the ACCESS_HASH value." -ForegroundColor Gray
Write-Host ""
Write-Host "⚠ NEVER paste your actual password into any chat or document." -ForegroundColor Yellow
Write-Host ""

$securePass = Read-Host "Enter your desired access password" -AsSecureString
$confirm    = Read-Host "Confirm password" -AsSecureString

# Compare
$p1 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePass))
$p2 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($confirm))

if ($p1 -ne $p2) {
    Write-Host ""
    Write-Host "✗ Passwords do not match. Please try again." -ForegroundColor Red
    $p1 = $null; $p2 = $null; [GC]::Collect()
    exit 1
}

$bytes     = [System.Text.Encoding]::UTF8.GetBytes($p1)
$sha256    = [System.Security.Cryptography.SHA256]::Create()
$hashBytes = $sha256.ComputeHash($bytes)
$hash      = [System.BitConverter]::ToString($hashBytes) -replace '-', ''
$sha256.Dispose()

# Clear plaintext immediately
$p1 = $null; $p2 = $null; [GC]::Collect()

Write-Host ""
Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "Your ACCESS_HASH (copy this entire line):" -ForegroundColor Cyan
Write-Host ""
Write-Host $hash -ForegroundColor Green
Write-Host ""
Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. Copy the hash above" -ForegroundColor Gray
Write-Host '  2. Open bootstrap.ps1' -ForegroundColor Gray
Write-Host '  3. Replace REPLACE_WITH_YOUR_PASSWORD_HASH with the hash' -ForegroundColor Gray
Write-Host "  4. Commit and push bootstrap.ps1 to GitHub" -ForegroundColor Gray
Write-Host "  5. Share the password (NOT this file) with authorized users" -ForegroundColor Gray
Write-Host ""
