# DriveDetector.psm1
# Detects and selects the shared drive for CoworkOS installation.

function Invoke-DriveDetection {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    $candidates = @()

    # Probe each candidate path in order
    $dropboxPath = Join-Path $env:USERPROFILE "Dropbox"
    if (Test-Path $dropboxPath) {
        $candidates += [PSCustomObject]@{ Label = "Dropbox"; Path = $dropboxPath }
    }

    if ($env:OneDrive -and (Test-Path $env:OneDrive)) {
        $candidates += [PSCustomObject]@{ Label = "OneDrive"; Path = $env:OneDrive }
    }

    $oneDriveUserPath = Join-Path $env:USERPROFILE "OneDrive"
    if ((Test-Path $oneDriveUserPath) -and ($env:OneDrive -ne $oneDriveUserPath)) {
        $candidates += [PSCustomObject]@{ Label = "OneDrive"; Path = $oneDriveUserPath }
    }

    $googleDrivePath = Join-Path $env:USERPROFILE "Google Drive"
    if (Test-Path $googleDrivePath) {
        $candidates += [PSCustomObject]@{ Label = "Google Drive"; Path = $googleDrivePath }
    }

    $googleDriveAltPath = Join-Path $env:USERPROFILE "GoogleDrive"
    if (Test-Path $googleDriveAltPath) {
        $candidates += [PSCustomObject]@{ Label = "Google Drive"; Path = $googleDriveAltPath }
    }

    # Always add local folder option last
    $candidates += [PSCustomObject]@{ Label = "Local folder (specify path)"; Path = $null }

    # Display numbered menu
    Write-Host ""
    Write-Host "Select where to install CoworkOS:"
    for ($i = 0; $i -lt $candidates.Count; $i++) {
        $item = $candidates[$i]
        $index = $i + 1
        if ($item.Path) {
            Write-Host "  [$index] $($item.Label) ($($item.Path))"
        }
        else {
            Write-Host "  [$index] $($item.Label)"
        }
    }

    $defaultChoice = 1
    $choicePrompt = "Choice [$defaultChoice]"
    $rawInput = Read-Host $choicePrompt

    $choiceInt = if ($rawInput -match '^\d+$') { [int]$rawInput } else { $defaultChoice }

    if ($choiceInt -lt 1 -or $choiceInt -gt $candidates.Count) {
        Write-Warning "Invalid choice '$rawInput'. Defaulting to [$defaultChoice]."
        $choiceInt = $defaultChoice
    }

    $selected = $candidates[$choiceInt - 1]

    $driveRoot = if ($selected.Path) {
        $selected.Path
    }
    else {
        # Local folder — prompt for path
        $localPath = Read-Host "Enter the full path for your CoworkOS folder"
        $localPath = $localPath.Trim()

        if (-not (Test-Path $localPath)) {
            $createIt = Read-Host "Path '$localPath' does not exist. Create it? [Y/n]"
            if ($createIt -eq '' -or $createIt -match '^[Yy]') {
                try {
                    New-Item -ItemType Directory -Path $localPath -Force | Out-Null
                    Write-Host "Created: $localPath"
                }
                catch {
                    Write-Error "Failed to create directory '$localPath': $_"
                    throw
                }
            }
            else {
                Write-Error "Path '$localPath' does not exist and was not created. Aborting."
                throw "Drive selection failed: path not available."
            }
        }

        $localPath
    }

    Write-Host ""
    Write-Host "Drive root set to: $driveRoot"

    # Return new Config hashtable with DriveRoot added (immutable pattern)
    $newConfig = $Config.Clone()
    $newConfig['DriveRoot'] = $driveRoot
    return $newConfig
}

Export-ModuleMember -Function Invoke-DriveDetection
