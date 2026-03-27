# Development Workflow

## 0. Research & Reuse (Mandatory Before Any New Implementation)

Before writing any new code:

1. **GitHub code search first** — run `gh search repos` and `gh search code` to find existing implementations, templates, and patterns
2. **Library docs second** — confirm API behavior, package usage, and version-specific details using primary vendor documentation
3. **Package registries** — search npm, PyPI, crates.io, or the relevant registry before writing utility code; prefer battle-tested libraries over hand-rolled solutions
4. **Broader web research** — only after the above steps are insufficient, search the web for patterns and approaches
5. **Look for adaptable implementations** — find open-source projects that solve 80% of the problem and can be forked, ported, or wrapped

Prefer adopting or porting a proven approach over writing net-new code when it meets the requirement.

## 1. Plan First

Before writing code:
- Create an implementation plan covering approach, dependencies, and risks
- Break the work into phases or tasks
- Identify edge cases and failure modes upfront
- Generate planning artifacts as needed: architecture notes, task lists, acceptance criteria

## 2. TDD Approach

Follow the RED → GREEN → IMPROVE cycle:

1. Write a failing test (RED)
2. Run the test — verify it fails for the right reason
3. Write the minimal implementation to make it pass (GREEN)
4. Run the test — verify it passes
5. Refactor for clarity and quality (IMPROVE)
6. Verify coverage is at or above 80%

## 3. Code Review

After writing code:
- Review for correctness, readability, and adherence to style guidelines
- Check for security issues (see `security.md`)
- Address all critical and high-severity issues before moving on
- Fix medium-severity issues when practical

## 4. Commit & Push

After passing review:
- Stage only relevant files (never `git add -A` blindly)
- Write a descriptive commit message following the conventional commits format (see `git-workflow.md`)
- Push to the remote branch and open a pull request with a full summary and test plan
