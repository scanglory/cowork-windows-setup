function Invoke-ChromeSetup {
    param([hashtable]$Config)

    # Step 1: Ask if Chrome is installed
    Write-Host "Do you use Google Chrome? [Y/n] (default Y):" -NoNewline
    $chromeResponse = Read-Host " "

    if ($chromeResponse -match '^[Nn]') {
        Write-Host "Skipping Chrome extension setup. You can install it later from the Chrome Web Store."
        return $Config + @{ ChromeSetupComplete = $false }
    }

    # Step 2: Display instructions
    Write-Host ""
    Write-Host "-----------------------------------------------------" -ForegroundColor Cyan
    Write-Host "  Claude in Chrome Extension Setup" -ForegroundColor Cyan
    Write-Host "-----------------------------------------------------" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Steps:"
    Write-Host "  1. Open Google Chrome"
    Write-Host "  2. Go to the Chrome Web Store"
    Write-Host "  3. Search for 'Claude for Chrome' or 'Claude Code Chrome'"
    Write-Host "  4. Click 'Add to Chrome'"
    Write-Host "  5. In the extension settings, add your Anthropic API key"
    Write-Host "     (Your API key should be in: $($Config.CoworkRoot)\.claude\.env)"
    Write-Host ""
    Write-Host "  ⚠ REMINDER: Your API key is in your .env file — do NOT"
    Write-Host "    type it directly into any website or chat." -ForegroundColor Yellow
    Write-Host ""

    # Step 3: Open Chrome Web Store
    Write-Host "Attempting to open Chrome Web Store..."
    Start-Process "chrome" -ArgumentList "https://chrome.google.com/webstore/search/claude" -ErrorAction SilentlyContinue
    if ($LASTEXITCODE -ne 0) {
        Start-Process "https://chrome.google.com/webstore/search/claude"
    }

    # Step 4: Wait for user
    Write-Host "Press Enter once you have installed the extension (or type 'skip' to skip)..."
    Read-Host "  Press Enter to continue" | Out-Null

    # Step 5: Return updated config
    return $Config + @{ ChromeSetupComplete = $true }
}

Export-ModuleMember -Function Invoke-ChromeSetup
