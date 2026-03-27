# FolderBuilder.psm1
# Builds the CoworkOS folder structure interactively.

function Invoke-FolderBuild {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    # Determine work-only or work + personal
    Write-Host ""
    $modeInput = Read-Host "Work only or Work + Personal? [W/P] (default W)"
    $modeInput = $modeInput.Trim().ToUpper()
    if ($modeInput -eq '') { $modeInput = 'W' }

    $includePersonal = $modeInput -eq 'P'

    # Collect work categories
    Write-Host ""
    $workInput = Read-Host "Enter your work project categories, comma-separated (e.g. Clients,Projects,Resources)"
    $workInput = $workInput.Trim()
    $workCategories = if ($workInput -eq '') {
        @('Clients', 'Projects', 'Resources')
    }
    else {
        $workInput -split '\s*,\s*' | Where-Object { $_ -ne '' }
    }

    # Collect personal categories if requested
    $personalCategories = @()
    if ($includePersonal) {
        Write-Host ""
        $personalInput = Read-Host "Enter your personal project categories, comma-separated (e.g. Projects,Learning,Creative)"
        $personalInput = $personalInput.Trim()
        $personalCategories = if ($personalInput -eq '') {
            @('Projects', 'Learning', 'Creative')
        }
        else {
            $personalInput -split '\s*,\s*' | Where-Object { $_ -ne '' }
        }
    }

    $coworkRoot = Join-Path $Config.DriveRoot "CoworkOS"

    # OneDrive warning
    if ($Config.DriveRoot -match 'OneDrive') {
        Write-Host ""
        Write-Host "NOTE: Your CoworkOS project folders will sync via OneDrive." -ForegroundColor Yellow
        Write-Host "  Keep your Claude config (~\.claude\) OUT of OneDrive to avoid sync conflicts." -ForegroundColor Yellow
        Write-Host "  Your Claude config will stay in: $env:USERPROFILE\.claude\" -ForegroundColor Yellow
        Write-Host ""
    }

    # Create base claude dirs
    $claudeRulesDir  = Join-Path $coworkRoot ".claude\rules"
    $claudeMemoryDir = Join-Path $coworkRoot ".claude\memory"

    foreach ($dir in @($claudeRulesDir, $claudeMemoryDir)) {
        try {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Host "Created: $dir"
        }
        catch {
            Write-Error "Failed to create directory '$dir': $_"
            throw
        }
    }

    # Create work category directories
    foreach ($category in $workCategories) {
        $categoryDir = Join-Path $coworkRoot "Work\$category"
        try {
            New-Item -ItemType Directory -Path $categoryDir -Force | Out-Null
            Write-Host "Created: $categoryDir"
        }
        catch {
            Write-Error "Failed to create directory '$categoryDir': $_"
            throw
        }
    }

    # Create personal category directories
    if ($includePersonal) {
        foreach ($category in $personalCategories) {
            $categoryDir = Join-Path $coworkRoot "Personal\$category"
            try {
                New-Item -ItemType Directory -Path $categoryDir -Force | Out-Null
                Write-Host "Created: $categoryDir"
            }
            catch {
                Write-Error "Failed to create directory '$categoryDir': $_"
                throw
            }
        }
    }

    # Copy rule templates from repo's templates\rules\ if they exist
    $scriptRoot = Split-Path -Parent $PSScriptRoot
    $templateRulesDir = Join-Path $scriptRoot "templates\rules"
    if (Test-Path $templateRulesDir) {
        try {
            Copy-Item -Path "$templateRulesDir\*" -Destination $claudeRulesDir -Recurse -Force
            Write-Host "Copied rule templates to: $claudeRulesDir"
        }
        catch {
            Write-Warning "Could not copy rule templates from '$templateRulesDir': $_"
        }
    }
    else {
        Write-Host "No rule templates found at '$templateRulesDir' — skipping copy."
    }

    # Create .gitignore in CoworkRoot
    $gitignorePath = Join-Path $coworkRoot ".gitignore"
    $gitignoreContent = @"
.env
*.log
.DS_Store
Thumbs.db
"@
    try {
        Set-Content -Path $gitignorePath -Value $gitignoreContent -Encoding UTF8 -Force
        Write-Host "Created: $gitignorePath"
    }
    catch {
        Write-Error "Failed to create .gitignore at '$gitignorePath': $_"
        throw
    }

    Write-Host ""
    Write-Host "CoworkOS folder structure created at: $coworkRoot"

    # Return new Config hashtable with additional keys added (immutable pattern)
    return $Config + @{
        CoworkRoot         = $coworkRoot
        WorkCategories     = $workCategories
        PersonalCategories = $personalCategories
        IncludePersonal    = $includePersonal
    }
}

Export-ModuleMember -Function Invoke-FolderBuild
