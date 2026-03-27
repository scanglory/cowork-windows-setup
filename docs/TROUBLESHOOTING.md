# Troubleshooting CoworkOS Setup

Solutions to the most common issues encountered during and after setup.

---

## 1. "PowerShell says scripts are not allowed"

**Problem:** You run the install command and see an error like `execution of scripts is disabled on this system`.

**Solution:** Windows blocks scripts by default as a security measure. You need to temporarily allow them.

Open PowerShell as Administrator (right-click the Start menu, choose "Windows PowerShell (Admin)") and run:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Type `Y` and press Enter when prompted. Then close that window and re-run the install command in a regular PowerShell window. You do not need to leave this setting changed permanently — `RemoteSigned` is a safe default for most users.

---

## 2. "bootstrap.ps1 shows 'Access Denied' from Windows Defender"

**Problem:** Windows Defender SmartScreen blocks the script with a warning that it is from an unknown publisher.

**Solution (Option A — Easiest):** In the warning dialog, click **More info**, then click **Run anyway**. SmartScreen is being cautious about scripts downloaded from the internet, which is normal behavior.

**Solution (Option B — If the file is already saved locally):** Open PowerShell as Administrator and run:

```powershell
Unblock-File -Path "C:\path\to\bootstrap.ps1"
```

Replace the path with the actual location of the file, then run it again.

---

## 3. "Node.js or npm not found after install"

**Problem:** The installer reports that Node.js was installed successfully, but when you open a new PowerShell window and type `node --version` or `npm --version`, you get "command not found."

**Solution:** Close your current PowerShell window completely and open a new one. Windows only picks up changes to the PATH environment variable in new sessions. If the problem persists after reopening PowerShell, log out of Windows and log back in, then try again.

---

## 4. "claude plugin install fails"

**Problem:** A step in the installer fails when trying to run `claude plugin install` or a similar command.

**Solution:** This usually means Claude Code is not installed or is not on your system PATH.

First, confirm Claude Code is installed:
```powershell
claude --version
```

If that command returns "not found," install Claude Code first from [claude.ai/download](https://claude.ai/download), then re-run the setup script. If `claude --version` works but plugin install still fails, try closing and reopening PowerShell, then run the plugin install command again manually.

---

## 5. "Outlook MCP not connecting"

**Problem:** You ask Claude "Show me my recent emails" and it cannot connect to Outlook.

**Solution — Personal/Consumer Outlook accounts:** You need an app password rather than your regular Outlook password. Log into your Microsoft account at [account.microsoft.com](https://account.microsoft.com), navigate to Security, find "App passwords," and generate a new one. Use that password in your `.env` file instead of your normal password.

**Solution — Corporate/work accounts:** Your IT administrator needs to grant the app permission to access your mailbox via the Microsoft Graph API. Share the MCP setup documentation with them and ask them to approve the required Graph API permissions (Mail.Read, Calendars.Read, Contacts.Read) for your account.

---

## 6. "Desktop Commander not found in Claude settings"

**Problem:** Claude says it cannot access your files or run commands, or Desktop Commander does not appear in Claude's MCP server list.

**Solution:** Check whether Desktop Commander is registered in your Claude configuration. Open the file `%APPDATA%\Claude\claude_desktop_config.json` (paste that path into File Explorer) and look for a `mcpServers` section containing `desktop-commander`.

If it is missing, reinstall Desktop Commander by running:

```powershell
npm install -g @wonderwhy-er/desktop-commander
```

Then restart Claude Code. The server should appear automatically on next launch.

---

## 7. "CoworkOS folder disappeared from OneDrive"

**Problem:** The CoworkOS folder was created during setup but no longer appears in your OneDrive.

**Solution:** OneDrive's selective sync feature can hide folders to save local disk space — they still exist in the cloud but are not visible locally. To fix this:

1. Right-click the OneDrive icon in your system tray (bottom-right corner of the taskbar).
2. Click **Settings**, then go to the **Sync and backup** tab.
3. Click **Choose folders** (or **Manage backup**).
4. Make sure the CoworkOS folder is checked.
5. Click OK. OneDrive will sync the folder back to your local drive.

---

## 8. "I accidentally put my API key in Claude chat"

**Problem:** You pasted an API key, password, or other secret directly into a Claude conversation.

**Solution:** Rotate the key immediately — do not wait.

- For Anthropic API keys: Go to [console.anthropic.com](https://console.anthropic.com), navigate to API keys, delete the exposed key, and create a new one.
- For other services: Go to that service's developer or security settings and revoke the key, then generate a replacement.

After rotating, update your `CoworkOS/.claude/.env` file with the new key. Review the conversation history to confirm the key is no longer visible, and consider whether the key may have been logged anywhere else.

---

## 9. "GSD commands not working"

**Problem:** Typing `/gsd:new-project` or other GSD commands does nothing or returns an error.

**Solution:** Verify that the GSD plugin is installed correctly:

```powershell
npx get-shit-done-cc --version
```

If you see a version number, the package is installed but may not be registered with Claude Code. Try restarting Claude Code.

If the command fails with "not found," reinstall the plugin:

```powershell
npm install -g get-shit-done-cc
```

Then restart Claude Code and try the GSD command again.

---

## 10. "Setup failed partway through"

**Problem:** The installer stopped in the middle — maybe due to a network error, a permissions issue, or an unexpected dialog box.

**Solution:** First, check the log file for details about what went wrong. Open the folder where you ran the installer and look for `cowork-setup.log`. Open it in Notepad — the last few lines will describe the error.

Once you know what failed, fix that specific issue using the relevant section above, then re-run the installer:

```powershell
irm https://raw.githubusercontent.com/YOUR_GITHUB_ORG/cowork-windows-setup/main/bootstrap.ps1 | iex
```

The installer is safe to re-run. It checks what is already installed and skips completed steps, so you will not end up with duplicates or broken state.
