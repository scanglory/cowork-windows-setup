# Git Workflow

## Commit Message Format

```
<type>: <description>

<optional body>
```

**Types:**
- `feat` — a new feature
- `fix` — a bug fix
- `refactor` — code restructuring without behavior change
- `docs` — documentation changes only
- `test` — adding or updating tests
- `chore` — maintenance tasks (dependencies, config, tooling)
- `perf` — performance improvements
- `ci` — CI/CD pipeline changes

**Rules:**
- Use imperative mood in description ("add feature" not "added feature")
- Keep description under 72 characters
- Reference issue numbers in the body when applicable

## Branch Naming Conventions

```
<type>/<short-description>
```

Examples:
- `feat/user-auth`
- `fix/email-validation`
- `refactor/payment-module`
- `chore/update-dependencies`

**Rules:**
- Use lowercase and hyphens, no underscores or spaces
- Keep branch names short and descriptive
- Delete branches after merging

## Pull Request Workflow

1. **Analyze full commit history** — use `git diff [base-branch]...HEAD` to see all changes, not just the latest commit
2. **Draft a comprehensive PR summary** — explain the why, not just the what
3. **Include a test plan** — list specific things to verify during review
4. **Request review** — assign at least one reviewer before merging
5. **Squash or rebase** before merging to keep history clean

**PR checklist:**
- [ ] All tests pass
- [ ] No secrets or credentials in diff
- [ ] PR description explains the purpose
- [ ] Test plan is included
- [ ] Breaking changes are documented
