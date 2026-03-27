# Performance Guidelines

## Model Selection Strategy

When choosing an AI model for a task, match the model to the complexity of the work:

| Model | Best For |
|-------|---------|
| **Haiku** (lightweight, fast, low cost) | Frequent invocations, simple completions, worker agents in multi-agent pipelines, pair programming assistance |
| **Sonnet** (best coding model, balanced) | Main development work, orchestrating multi-agent workflows, complex coding tasks, most day-to-day use |
| **Opus** (deepest reasoning, highest cost) | Complex architectural decisions, research and analysis tasks, problems requiring maximum reasoning depth |

Default to Sonnet for most work. Use Haiku when cost and latency matter more than depth. Reserve Opus for decisions with long-lasting architectural impact.

## Context Window Management

Avoid approaching the last 20% of the context window when performing:
- Large-scale refactoring spanning many files
- Feature implementation requiring coordination across modules
- Debugging complex multi-component interactions

Tasks with lower context sensitivity (safe to do at any context depth):
- Single-file edits
- Independent utility creation
- Documentation updates
- Simple, well-scoped bug fixes

If you are near the context limit on a complex task, summarize progress, start a new session, and continue from the summary.

## Build Troubleshooting

When a build fails:
1. Read the full error output before making changes
2. Identify the root cause — do not guess or make random changes
3. Fix the issue incrementally, verifying after each change
4. If the error is unclear, search for the exact error message before trying solutions
5. Verify the build passes cleanly after the fix before moving on

## General Performance Principles

- Profile before optimizing — measure, do not guess
- Optimize the critical path first; ignore the rest until it matters
- Prefer algorithmic improvements over micro-optimizations
- Cache expensive operations at appropriate boundaries
- Avoid premature optimization — write clear code first, optimize when needed
