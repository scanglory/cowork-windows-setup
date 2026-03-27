# Getting Started with CoworkOS

## Welcome

Congratulations — your CoworkOS environment is set up and ready to go. CoworkOS turns Claude into a full AI productivity system, not just a chatbot. It remembers you, connects to your tools like email and your file system, and follows a structured workflow that keeps your projects organized. The more you use it, the more useful it becomes.

---

## Your CoworkOS Folder

During setup, a folder called **CoworkOS** was created inside your shared drive (Dropbox, OneDrive, or Google Drive). This is your home base.

Inside you will find:

- `.claude/` — Claude's configuration, memory files, rules, and your personal settings. You rarely need to touch this directly, but it is what makes Claude feel personalized to you.
- `Work/` — Your work-related projects, each in its own subfolder.
- `Personal/` — Personal projects, notes, and anything outside of work.

Why does the folder location matter? Because it is synced across your devices and backed up automatically. Claude always knows where your projects live, and you can pick up on any machine right where you left off.

---

## The Key Tools You Now Have

### Skills — Type `/` to Access

Skills are built-in commands that trigger structured workflows. Type a forward slash in Claude Code to see them.

| Skill | What It Does |
|-------|-------------|
| `/brainstorm` | Start any project or idea with structured thinking — great for getting unstuck or kicking off something new |
| `/wrap` | Run this at the END of every session to capture what Claude learned and save it to memory |
| `/tdd` | Launches a test-driven development workflow — write tests first, then implement |
| `/mcp-builder` | Build new MCP connections to add new tools and data sources to Claude |
| `/skill-creator` | Create your own custom slash commands for recurring workflows |
| `/review` | Get a thorough code review on any file or selection |
| `/debug` | Walk through a systematic debugging process with Claude |

### GSD (Get Shit Done) — Project Workflow

GSD is a structured system for running projects from idea to completion.

| Command | What It Does |
|---------|-------------|
| `/gsd:new-project` | Start a new project — Claude creates a roadmap and breaks it into phases |
| `/gsd:plan-phase` | Plan the next phase of an existing project |
| `/gsd:execute-phase` | Work through a planned phase step by step |
| `/gsd:progress` | See what has been completed and what is still ahead |

### MCP Connections — What Claude Can Now DO

MCP (Model Context Protocol) connections give Claude direct access to your tools. You do not need to copy and paste anything — just ask.

**Desktop Commander** gives Claude access to your file system and terminal:
- "List the files in my Documents folder"
- "Read the file at C:\Users\Me\Projects\notes.txt"
- "Run this PowerShell command for me"

**Outlook MCP** connects Claude to your email and calendar:
- "Show me my 5 most recent emails"
- "Draft a reply to the email from Sarah about the contract"
- "What is on my calendar today?"
- "Find the contact for John Smith"

### Memory System

Claude now remembers you across sessions. After each conversation, running `/wrap` saves what Claude learned — your preferences, ongoing projects, decisions made, and patterns in how you work.

These memory files are stored at `CoworkOS/.claude/memory/` in your shared drive. You can open and read them at any time. The more sessions you complete with `/wrap`, the smarter and more personalized Claude becomes.

---

## Your First 5 Actions

Work through these after setup to confirm everything is working and get comfortable with the system.

1. **Test Desktop Commander** — Ask Claude: "What files are in my Documents folder?" Claude should return a list without you doing anything else.

2. **Test Outlook MCP** — Ask Claude: "Show me my 5 most recent emails." If this does not work, see `docs/TROUBLESHOOTING.md` for the Outlook MCP section.

3. **Run /brainstorm** — Pick something you are currently working on or thinking about and type `/brainstorm`. Follow Claude's prompts and see where it goes.

4. **Start a project with GSD** — Type `/gsd:new-project` and follow the wizard. It will ask you a few questions and then generate a project roadmap.

5. **End the session with /wrap** — When you are done, type `/wrap`. Always do this. It is what makes the memory system work over time.

---

## Security Rules (IMPORTANT)

These rules protect you, your clients, and your business. Please read them.

- **NEVER paste API keys, passwords, or tokens into Claude chat.** If Claude needs credentials to connect to a service, they belong in `CoworkOS/.claude/.env` — not in the chat window. Claude reads secrets from that file automatically.
- **Always review AI-generated content before sending to clients or publishing.** Claude is powerful but not infallible. A quick read-through before you hit send is always worth it.
- **Never input confidential client data or personally identifiable information (PII) into prompts.** If you need Claude to work with sensitive data, talk to your administrator about a private deployment.
- **Your `.env` file is not synced to GitHub or shared externally.** Keep it that way.

---

## Building Custom Tools

**Build new MCP connections** with `/mcp-builder`. If your business uses a CRM, a custom database, an internal API, or any other tool, you can connect it to Claude. Once connected, Claude can read from and write to it just like it does with your files and email. You do not need to be a developer to start — `/mcp-builder` walks you through it.

**Create custom skills** with `/skill-creator` (or `/skill-create`). If you find yourself asking Claude to do the same thing repeatedly — draft a certain type of document, follow a specific checklist, run a particular analysis — you can turn that into a slash command. Your custom skills are saved to your CoworkOS folder and available in every future session.

---

## Getting Help

- **Setup issues:** See `docs/TROUBLESHOOTING.md` for solutions to the most common problems.
- **Skills documentation:** Type `/help` in Claude Code to see all available skills and what they do.
- **Updates:** Run `Update-CoworkOS.ps1` periodically to pull in the latest rules, agents, and skills. Your personal settings and memory files are never overwritten by an update.
