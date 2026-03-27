# Agent Orchestration

## Available Agents

| Agent | Purpose | When to Use |
|-------|---------|-------------|
| `planner` | Implementation planning, task breakdown | Complex features, refactoring, anything spanning multiple files or sessions |
| `architect` | System design, architectural decisions | Designing new systems, evaluating structural trade-offs |
| `tdd-guide` | Test-driven development coaching | Any new feature or bug fix — enforces write-tests-first |
| `code-reviewer` | Code review for correctness, style, and security | Immediately after writing or modifying code |
| `security-reviewer` | Dedicated security analysis | Before any commit touching auth, data handling, or external integrations |

## When to Use Each Agent

**Use `planner` when:**
- A feature request is complex enough that you are not sure where to start
- You need to break work into phases or tasks before coding
- The change touches many files or systems

**Use `tdd-guide` when:**
- Implementing any new feature
- Fixing a bug (write a test that reproduces it first)
- You are unsure how to structure your tests

**Use `code-reviewer` when:**
- You have just written or modified code
- You want a second opinion before opening a PR
- You are not confident about edge cases or error handling

**Use `security-reviewer` when:**
- Your change involves authentication, authorization, or session management
- You are handling user input, file uploads, or external API data
- You are about to commit anything touching secrets or credentials

## Parallel Execution

ALWAYS run independent agents in parallel rather than sequentially:

```
# GOOD: Parallel execution
Launch 3 agents simultaneously:
1. security-reviewer — analyze the auth module
2. code-reviewer — review the payment service
3. tdd-guide — write tests for the new user flow

# BAD: Sequential when there is no dependency
Run security-reviewer, wait for it to finish,
then run code-reviewer, wait, then run tdd-guide.
```

Parallel execution saves significant time on multi-agent workflows. Only run agents sequentially when the output of one feeds directly into the next.
