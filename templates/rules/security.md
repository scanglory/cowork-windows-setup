# Security Guidelines

## Mandatory Security Checks

Before ANY commit:
- [ ] No hardcoded secrets (API keys, passwords, tokens, connection strings)
- [ ] All user inputs validated and sanitized
- [ ] SQL injection prevention (parameterized queries only)
- [ ] XSS prevention (sanitize all HTML output)
- [ ] CSRF protection enabled on state-changing endpoints
- [ ] Authentication and authorization verified on every protected route
- [ ] Rate limiting applied to all public endpoints
- [ ] Error messages do not leak sensitive data (stack traces, internal paths, etc.)

## Secret Management

- NEVER hardcode secrets in source code
- ALWAYS use environment variables or a dedicated secret manager
- Validate that all required secrets are present at application startup
- Rotate any secrets that may have been exposed — immediately
- Use `.env.example` with placeholder values; never commit `.env`

## Security Response Protocol

If a security issue is found:

1. STOP immediately — do not continue adding features
2. Assess the severity (critical, high, medium, low)
3. Fix CRITICAL and HIGH issues before continuing any other work
4. Rotate any exposed secrets
5. Review the entire codebase for similar patterns
6. Document the issue and resolution in your commit message

## Common Vulnerability Patterns to Avoid

- **Injection:** Always use parameterized queries; never interpolate user input into SQL or shell commands
- **Broken auth:** Use established auth libraries; do not roll your own authentication
- **Sensitive data exposure:** Encrypt sensitive data at rest and in transit; use HTTPS everywhere
- **Insecure deserialization:** Validate and sanitize all deserialized data
- **Using components with known vulnerabilities:** Keep dependencies updated; run `npm audit` or equivalent regularly
