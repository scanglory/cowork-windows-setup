function Invoke-ProjectMigration {
    param([hashtable]$Config)

    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  Scanning your existing Claude Code projects..." -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""

    $projectsDir = Join-Path $Config.ClaudeConfigDir "projects"

    if (-not (Test-Path $projectsDir)) {
        Write-Host "No existing Claude Code projects found. Skipping migration."
        return $Config + @{ ProjectsMigrated = 0 }
    }

    # Scan all project subdirectories
    $projectFolders = Get-ChildItem $projectsDir -Directory

    if ($projectFolders.Count -eq 0) {
        Write-Host "No existing Claude Code projects found. Skipping migration."
        return $Config + @{ ProjectsMigrated = 0 }
    }

    # Decode each folder name back to a path
    $projects = @()
    foreach ($folder in $projectFolders) {
        $encodedName = $folder.Name
        # Decode: leading dash is removed, remaining dashes between path segments
        # Windows paths look like: -C:-Users-johndoe-Documents-project
        # macOS paths look like: -Users-johndoe-Developer-project

        # Strategy: replace leading dash, then replace -X:- with X:\ for Windows drives
        $decoded = $encodedName -replace '^-', ''
        # Handle Windows drive letters: C:-Users → C:\Users
        $decoded = $decoded -replace '^([A-Za-z]):-', '$1:\'
        # Replace remaining dashes with backslashes (path separators)
        # But be careful: project names may contain dashes too
        # Use a heuristic: convert to forward slashes and let Windows handle
        $decoded = $decoded -replace '-', '\'

        # Extract project name from path (last component)
        $projectName = Split-Path $decoded -Leaf
        if ([string]::IsNullOrWhiteSpace($projectName)) {
            $projectName = $encodedName
        }

        # Check if original path still exists on disk
        $pathExists = Test-Path $decoded -ErrorAction SilentlyContinue

        # Read CLAUDE.md for description if it exists
        $claudeMdPath = Join-Path $decoded "CLAUDE.md"
        $description = ""
        if ($pathExists -and (Test-Path $claudeMdPath)) {
            $firstLines = Get-Content $claudeMdPath -TotalCount 10 -ErrorAction SilentlyContinue
            # Extract first non-empty, non-header line as description
            $firstMatch = $firstLines | Where-Object { $_ -match '\S' -and $_ -notmatch '^#' } | Select-Object -First 1
            $description = if ($firstMatch) { $firstMatch } else { "" }
            if ($description.Length -gt 60) { $description = $description.Substring(0, 57) + "..." }
        }

        # Check for git remote (for auto-categorization hints)
        $gitRemote = ""
        if ($pathExists) {
            $gitConfig = Join-Path $decoded ".git\config"
            if (Test-Path $gitConfig) {
                $remoteLines = Get-Content $gitConfig -ErrorAction SilentlyContinue | Where-Object { $_ -match 'url\s*=' }
                if ($remoteLines) {
                    $gitRemote = ($remoteLines[0] -split '=')[1].Trim()
                }
            }
        }

        # Auto-suggest category
        $suggested = Get-SuggestedCategory -ProjectName $projectName -Path $decoded -GitRemote $gitRemote -Config $Config

        $projects += [PSCustomObject]@{
            Name        = $projectName
            Path        = $decoded
            FolderName  = $encodedName
            Exists      = $pathExists
            Description = $description
            Suggested   = $suggested
        }
    }

    if ($projects.Count -eq 0) {
        Write-Host "No decodable projects found. Skipping migration."
        return $Config + @{ ProjectsMigrated = 0 }
    }

    # Display table
    Write-Host "Found $($projects.Count) Claude Code project(s):"
    Write-Host ""
    Write-Host ("  {0,-25} {1,-15} {2}" -f "Project", "Suggested", "Path")
    Write-Host ("  {0,-25} {1,-15} {2}" -f ("-" * 24), ("-" * 14), ("-" * 30))
    $i = 1
    foreach ($proj in $projects) {
        $existsMark = if ($proj.Exists) { "" } else { " [path not found]" }
        Write-Host ("  [{0}] {1,-22} {2,-15} {3}{4}" -f $i, $proj.Name, $proj.Suggested, $proj.Path, $existsMark)
        $i++
    }
    Write-Host ""

    # Ask user to confirm or modify
    Write-Host "Options for each project:"
    Write-Host "  Press Enter to accept all suggestions"
    Write-Host "  Or type project numbers to customize (e.g. '2,3' then Enter)"
    Write-Host ""
    $customInput = Read-Host "Accept all suggestions? (Enter) or list numbers to customize"

    $toCustomize = @()
    if (-not [string]::IsNullOrWhiteSpace($customInput)) {
        $toCustomize = $customInput -split ',' | ForEach-Object { [int]$_.Trim() - 1 }
    }

    # For projects user wants to customize, ask for their category
    $availableCategories = @("Work\Clients", "Work\Projects", "Work\Resources", "Skip")
    if ($Config.IncludePersonal) {
        $availableCategories += @("Personal\Projects", "Personal\Learning", "Personal\Creative")
    }
    $availableCategories += $Config.WorkCategories | ForEach-Object { "Work\$_" }

    $finalAssignments = @()
    for ($idx = 0; $idx -lt $projects.Count; $idx++) {
        $proj = $projects[$idx]
        if ($toCustomize -contains $idx) {
            Write-Host ""
            Write-Host "Project: $($proj.Name) ($($proj.Path))"
            $j = 1
            foreach ($cat in $availableCategories) {
                Write-Host "  [$j] $cat"
                $j++
            }
            $choice = Read-Host "Choose category [1-$($availableCategories.Count)]"
            $chosenIdx = [int]$choice - 1
            $category = if ($chosenIdx -ge 0 -and $chosenIdx -lt $availableCategories.Count) { $availableCategories[$chosenIdx] } else { $proj.Suggested }
            $finalAssignments += [PSCustomObject]@{ Project = $proj; Category = $category }
        }
        else {
            $finalAssignments += [PSCustomObject]@{ Project = $proj; Category = $proj.Suggested }
        }
    }

    # Create CoworkOS subfolders and write project pointers
    $migratedCount = 0
    foreach ($assignment in $finalAssignments) {
        if ($assignment.Category -eq "Skip") { continue }

        $proj     = $assignment.Project
        $category = $assignment.Category

        # Create CoworkOS subfolder for project
        $projFolder = Join-Path $Config.CoworkRoot "$category\$($proj.Name)"
        New-Item -ItemType Directory -Force -Path $projFolder | Out-Null

        # Write a README.md in the CoworkOS folder pointing to the project
        $pointerContent = @"
# $($proj.Name)

**Project Path:** $($proj.Path)
**CoworkOS Category:** $category
**Migrated:** $(Get-Date -Format "yyyy-MM-dd")

## Notes
[Add project notes here]

## Links
- Project code: ``$($proj.Path)``
"@
        Set-Content -Path "$projFolder\README.md" -Value $pointerContent -Encoding UTF8

        # If project path exists, write a CLAUDE.md there pointing to CoworkOS config
        if ($proj.Exists) {
            $claudePointer = @"
# Project: $($proj.Name)

This project is part of CoworkOS. Global config and memory are at:
``$($Config.CoworkRoot)\.claude\CLAUDE.md``

See CoworkOS for shared rules, memory, and workflow configuration.
"@
            $existingClaudeMd = Join-Path $proj.Path "CLAUDE.md"
            if (-not (Test-Path $existingClaudeMd)) {
                Set-Content -Path $existingClaudeMd -Value $claudePointer -Encoding UTF8
            }
        }

        $migratedCount++
    }

    Write-Host ""
    Write-Host "✓ $migratedCount project(s) added to CoworkOS structure" -ForegroundColor Green
    Write-Host ""

    return $Config + @{ ProjectsMigrated = $migratedCount }
}

function Get-SuggestedCategory {
    param(
        [string]$ProjectName,
        [string]$Path,
        [string]$GitRemote,
        [hashtable]$Config
    )

    # Heuristics for auto-categorization
    $name      = $ProjectName.ToLower()
    $pathLower = $Path.ToLower()

    # Personal signals
    $personalKeywords = @('journal', 'diary', 'personal', 'hobby', 'blog', 'home', 'family', 'learning', 'practice', 'sandbox')
    foreach ($kw in $personalKeywords) {
        if ($name -match $kw -or $pathLower -match $kw) {
            if ($Config.IncludePersonal) { return "Personal\Projects" }
        }
    }

    # Client signals
    $clientKeywords = @('client', 'customer', 'consulting', 'contract', 'agency')
    foreach ($kw in $clientKeywords) {
        if ($name -match $kw -or $pathLower -match $kw) { return "Work\Clients" }
    }

    # Default to Work\Projects
    return "Work\Projects"
}

Export-ModuleMember -Function Invoke-ProjectMigration
