# Hooks System

## Hook Types

Hooks intercept Claude's actions at defined points in the execution lifecycle:

| Hook Type | Trigger | Common Uses |
|-----------|---------|-------------|
| `PreToolUse` | Before a tool call executes | Validate parameters, block disallowed actions, log intent |
| `PostToolUse` | After a tool call completes | Auto-format files, run linters, verify side effects |
| `Stop` | When a session ends | Run final verification, generate summaries, sync memory files |

**PreToolUse** hooks can inspect and modify tool parameters before execution, or block the call entirely if it violates a policy.

**PostToolUse** hooks receive the tool result and can trigger follow-up actions — for example, running `prettier` automatically after any file edit.

**Stop** hooks run when the agent finishes a session — useful for ensuring memory is saved and session state is consistent.

## TodoWrite Best Practices

Use the `TodoWrite` tool to track progress on multi-step tasks:

- **Create todos before starting** — listing tasks upfront reveals gaps, wrong order, and missing steps before you invest time in them
- **Keep todos granular** — each item should represent 15-60 minutes of work, not a vague goal
- **Update as you go** — mark items complete, add discovered sub-tasks, and remove items that turn out to be unnecessary
- **Use todos to verify understanding** — if you cannot write a clear todo list for a task, you do not understand it well enough to start coding

A good todo list reveals:
- Steps that are out of order
- Missing prerequisite items
- Unnecessary or redundant items
- Wrong level of granularity (too vague or too detailed)
- Misinterpreted requirements (visible when you try to write concrete tasks)
