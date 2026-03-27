function Invoke-ProductivitySetup {
    param([hashtable]$Config)

    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  Let's personalize your CoworkOS experience" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""

    # Collect brand info
    Write-Host "What is your company or brand name? (press Enter to skip):" -NoNewline
    $CompanyName = Read-Host " "

    Write-Host "What industry are you in? (e.g. Technology, Legal, Marketing, Finance):" -NoNewline
    $Industry = Read-Host " "

    Write-Host "What tone should Claude use in outputs? [professional/casual/technical] (default professional):" -NoNewline
    $Tone = Read-Host " "

    # Collect user role
    Write-Host "What is your role or job title? (e.g. Software Engineer, Marketing Director):" -NoNewline
    $UserRole = Read-Host " "

    # Setup auto-memory directory
    $memoryDir = Join-Path $Config.CoworkRoot ".claude\memory"
    New-Item -ItemType Directory -Force -Path $memoryDir | Out-Null

    # Create starter memory files
    $userProfileContent = @"
---
name: user_profile
description: Core information about the user - role, expertise, working style
type: user
---

# User Profile

**Name:** $($Config.UserName)
**Role:** $UserRole
**Company:** $CompanyName
**Industry:** $Industry
**Setup Date:** $(Get-Date -Format "yyyy-MM-dd")

## Expertise & Background
[To be filled in as Claude learns about you]

## Working Style
[To be filled in as Claude learns about you]
"@

    $feedbackContent = @"
---
name: feedback_defaults
description: Default behaviors and preferences Claude should follow
type: feedback
---

# Default Behaviors

## Communication
- Keep responses concise and direct
- Use bullet points for lists
- Lead with the answer, not the reasoning

## Code
- Follow the rules in CoworkOS/.claude/rules/
- Always handle errors explicitly
- Prefer immutable patterns

[Add more as you discover your preferences]
"@

    Set-Content -Path (Join-Path $memoryDir "user_profile.md") -Value $userProfileContent
    Set-Content -Path (Join-Path $memoryDir "feedback_defaults.md") -Value $feedbackContent
    Set-Content -Path (Join-Path $Config.CoworkRoot ".claude\memory\MEMORY.md") -Value "# Memory Index`n`nSee individual memory files in this directory."

    Write-Host ""
    Write-Host "✓ Memory directory initialized at $memoryDir" -ForegroundColor Green

    return $Config + @{
        CompanyName = $CompanyName
        Industry    = $Industry
        Tone        = if ($Tone -eq '') { 'professional' } else { $Tone }
        UserRole    = $UserRole
        MemoryDir   = $memoryDir
    }
}

Export-ModuleMember -Function Invoke-ProductivitySetup
