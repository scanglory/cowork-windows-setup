# Testing Requirements

## Minimum Test Coverage: 80%

All projects must maintain at least 80% test coverage. Coverage is measured across lines, branches, and functions.

## Required Test Types

All three test types are required for every project:

1. **Unit Tests** — test individual functions, utilities, and components in isolation; mock all external dependencies
2. **Integration Tests** — test API endpoints, database operations, and service interactions with real or near-real dependencies
3. **End-to-End (E2E) Tests** — test critical user flows from the UI or API surface all the way through the system

Choose the appropriate E2E framework for your language and platform (e.g., Playwright for web, Cypress for frontend-heavy apps, pytest for Python services).

## Test-Driven Development Workflow

MANDATORY workflow for all new features and bug fixes:

1. **RED** — Write a test that describes the desired behavior; run it and confirm it fails
2. **GREEN** — Write the minimal implementation to make the test pass; run it and confirm it passes
3. **IMPROVE** — Refactor for clarity, performance, and maintainability; re-run tests to confirm nothing broke

Do not write implementation code before the test exists.

## Test Quality Guidelines

- Tests must be isolated — no shared mutable state between tests
- Tests must be deterministic — same input always produces same output
- Mock external services and I/O at the boundary
- Use descriptive test names that explain what is being tested and what the expected outcome is
- Avoid testing implementation details; test observable behavior instead

## Troubleshooting Failing Tests

1. Check test isolation — verify no shared state is leaking between tests
2. Verify mocks are correct and returning expected values
3. Read the failure message carefully before changing anything
4. Fix the implementation to match the test, not the other way around (unless the test is demonstrably wrong)
