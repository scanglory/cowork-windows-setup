# CoworkOS Windows Setup

Get the full Cowork AI productivity environment on Windows in one command.
Built for Claude Max plan users.

## What Gets Installed

| Component | What It Does |
|-----------|-------------|
| **CoworkOS Folder** | Synced project structure in your Dropbox/OneDrive/Google Drive |
| **Desktop Commander MCP** | Claude can read/write files and run terminal commands |
| **Outlook MCP** | Claude can read email, draft replies, check calendar, search contacts |
| **Superpowers Plugin** | Skills: /brainstorm, /wrap, /tdd, /debug, /review, /mcp-builder, /skill-creator |
| **GSD Plugin** | Project workflow: /gsd:new-project, /gsd:plan-phase, /gsd:execute-phase |
| **Everything Claude Code** | Development patterns and skill builder (/skill-create) |
| **Anthropic Skills** | Productivity tools: /wrap, /schedule, /pdf, /docx, /xlsx, and more |
| **Auto-Memory System** | Claude remembers your preferences across sessions |
| **Personalized CLAUDE.md** | Pre-configured with your brand, legal rules, and security defaults |

## Requirements

- Windows 10 or Windows 11
- Google Chrome (for Claude in Chrome extension)
- A Claude Max plan subscription
- Your Cowork access password (contact your administrator)

## Install

Open PowerShell and run:

```powershell
irm https://raw.githubusercontent.com/scanglory/cowork-windows-setup/main/bootstrap.ps1 | iex
```

The setup wizard will guide you through the rest (~15 minutes).

## Update

To update rules and agents to the latest version:

```powershell
irm https://raw.githubusercontent.com/scanglory/cowork-windows-setup/main/Update-CoworkOS.ps1 | iex
```

## After Setup

1. Open Claude Code
2. Read `docs/GETTING-STARTED.md` for your first steps
3. Run `/brainstorm` to start your first project

## Getting Help

- Read `docs/GETTING-STARTED.md` — plain-English intro to CoworkOS concepts
- Read `docs/TROUBLESHOOTING.md` — solutions to common setup issues
- Check the setup log: `cowork-setup.log` in the installer folder

## Administrators: Setting the Access Password

1. Run `tools\New-AccessHash.ps1` locally
2. Enter and confirm your password
3. Copy the output hash
4. Paste it into `bootstrap.ps1` as the `$ACCESS_HASH` value
5. Commit and push — share the password (not this file) with authorized users
