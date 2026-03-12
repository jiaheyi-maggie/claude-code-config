Perform a comprehensive security audit of the codebase. This is not a cursory scan — methodically check every attack surface.

## Scope
$ARGUMENTS

If no arguments, audit the entire project. If arguments specify a file or feature, focus there but still check related attack surfaces.

## Step 1: Reconnaissance

Map the attack surface:
- Find all entry points: API routes, form handlers, webhooks, CLI inputs, file uploads
- Find all data stores: databases, caches, session stores, file system, cookies, localStorage
- Find all external calls: API clients, email services, payment processors, auth providers
- Find all secrets: grep for API keys, tokens, passwords, connection strings
- Find all auth/authz checkpoints

Run these searches:
```
# Secrets in code
grep -r "password\|secret\|api_key\|token\|private_key\|AWS_\|STRIPE_" --include="*.{ts,js,py,env,json,yaml,yml}" -l

# SQL queries
grep -r "query\|execute\|rawQuery\|raw(\|sequelize.literal\|\$queryRaw" --include="*.{ts,js,py}" -l

# User input consumption
grep -r "req.body\|req.query\|req.params\|request.form\|request.args\|request.json\|searchParams" --include="*.{ts,js,py,tsx,jsx}" -l
```

## Step 2: Audit — OWASP Top 10 focus

### A01: Broken Access Control
- [ ] Auth check on every protected route (not just in middleware that could be bypassed)
- [ ] Authz check verifies the user owns the resource (not just "is logged in")
- [ ] No IDOR: can user A access user B's data by changing an ID in the URL?
- [ ] Rate limiting on sensitive endpoints (login, password reset, API)
- [ ] CORS configured correctly (not `*` in production)

### A02: Cryptographic Failures
- [ ] Passwords hashed with bcrypt/scrypt/argon2 (not MD5/SHA)
- [ ] Sensitive data encrypted at rest
- [ ] HTTPS enforced (no mixed content)
- [ ] Secrets not committed to git (check git history too: `git log --all -p -S "password"`)
- [ ] JWT tokens have expiration, secrets are strong, algorithm is explicit (not `none`)

### A03: Injection
- [ ] All SQL uses parameterized queries — EVERY query, including LIMIT/OFFSET
- [ ] No `eval()`, `exec()`, `Function()` with user input
- [ ] No shell command injection (user input in `child_process.exec`, `subprocess.run`)
- [ ] No template injection (user input in template literals rendered as HTML)
- [ ] XSS: all user content escaped/sanitized before rendering (especially `dangerouslySetInnerHTML`, `innerHTML`, `v-html`)

### A04: Insecure Design
- [ ] Business logic flaws: can a user skip steps? (pay without adding to cart, verify without email)
- [ ] Race conditions: can concurrent requests cause double-spend, double-create?
- [ ] Mass assignment: can users set fields they shouldn't? (is_admin, role, balance)

### A05: Security Misconfiguration
- [ ] Debug mode off in production
- [ ] Default credentials changed
- [ ] Error messages don't leak stack traces, file paths, or internal details
- [ ] Security headers set: CSP, X-Frame-Options, X-Content-Type-Options, Strict-Transport-Security

### A07: Authentication Failures
- [ ] Token refresh has a mutex (concurrent requests don't trigger parallel refreshes)
- [ ] Session invalidated on logout (server-side, not just client cookie deletion)
- [ ] Password reset tokens are single-use and time-limited
- [ ] `undefined === undefined` guard: env var comparison checks existence first

### A08: Data Integrity Failures
- [ ] Dependencies audited: `npm audit` / `pip audit` / `cargo audit`
- [ ] Lock file committed (package-lock.json, poetry.lock)
- [ ] No deserialization of untrusted data without validation

### A09: Logging & Monitoring
- [ ] Failed auth attempts logged
- [ ] No PII in logs (email, password, tokens)
- [ ] No secrets in logs (grep log statements for sensitive variable names)

### A10: SSRF
- [ ] User-provided URLs validated before fetching
- [ ] No internal network access via user-controlled URLs
- [ ] Redirect URLs validated (only relative paths matching `/^\/[a-zA-Z]/`)

## Step 3: Report

```
## Security Audit Report
Date: [date] | Scope: [what was audited]

### Critical (fix immediately)
1. **[vulnerability type]** — file:line
   Attack: [how it can be exploited]
   Fix: [specific code change]

### High (fix before shipping)
1. ...

### Medium (fix soon)
1. ...

### Low (improve when convenient)
1. ...

### Passed
- [x] [check that passed]

### Recommendations
- [systemic improvements]
```

Fix all Critical and High issues immediately after presenting the report.
