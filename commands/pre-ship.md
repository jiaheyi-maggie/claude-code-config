This is the final quality gate before shipping. Nothing goes to production without passing this checklist. Be ruthless — it's cheaper to catch issues now than after users hit them.

## What's being shipped
$ARGUMENTS

If no arguments, review all changes on the current branch vs. main.

## Step 1: Gather context

- Run `git diff main...HEAD --stat` to see all changed files
- Run `git log main..HEAD --oneline` to see all commits
- Read the PRD.md if it exists
- Check for any HANDOVER.md or TODO items

## Step 2: Quality gates — all must pass

### Gate 1: Build & Tests
```bash
# Run the full build
npm run build  # or equivalent

# Run all tests
npm run test   # or equivalent

# Type checking
npx tsc --noEmit  # if TypeScript
```
- [ ] Build passes with zero warnings
- [ ] All tests pass
- [ ] Type checking passes
- [ ] No skipped or commented-out tests (`.skip`, `xit`, `@pytest.mark.skip`)

### Gate 2: Semantic correctness (from /review-feature)
For every handler/button/action changed:
- [ ] Read the function name, then the body — it does what the name says
- [ ] Trace 3 critical user flows end-to-end: UI → handler → API → DB → response → UI update
- [ ] Empty states: what does the user see with no data?
- [ ] Error states: what does the user see when the API fails?
- [ ] Loading states: is there feedback during async operations?

### Gate 3: Edge cases
- [ ] What happens with empty input?
- [ ] What happens with very long input? (max length validation?)
- [ ] What happens with special characters? (`<script>`, `'; DROP TABLE`, `../../../etc/passwd`)
- [ ] What happens with concurrent requests? (double-click, race condition)
- [ ] What happens offline or with slow network?

### Gate 4: Security (abbreviated — run /security-audit for full)
- [ ] No hardcoded secrets
- [ ] All user input validated/sanitized
- [ ] Auth checks on every protected route
- [ ] No PII in logs
- [ ] Dependencies are up to date (`npm audit` / `pip audit`)

### Gate 5: Performance
- [ ] No N+1 queries
- [ ] No unnecessary re-renders (React: check dependency arrays)
- [ ] Large lists are paginated or virtualized
- [ ] Images are optimized / lazy loaded
- [ ] No blocking operations on the main thread

### Gate 6: Developer experience
- [ ] New env vars documented
- [ ] Database migrations are reversible
- [ ] Breaking API changes are versioned or documented
- [ ] README updated if setup steps changed

### Gate 7: Product alignment
- [ ] Compare implemented features against PRD.md (if exists)
- [ ] Every acceptance criterion is met
- [ ] Nothing was quietly dropped
- [ ] Nothing was gold-plated (added but not requested)
- [ ] The "magic moment" works as intended

## Step 3: Verdict

```
## Pre-Ship Report: [feature/product name]

### Status: [SHIP IT / BLOCKED — fix N issues]

### Gates
| Gate | Status | Notes |
|------|--------|-------|
| Build & Tests | PASS/FAIL | |
| Semantic Correctness | PASS/FAIL | |
| Edge Cases | PASS/FAIL | |
| Security | PASS/FAIL | |
| Performance | PASS/FAIL | |
| Developer Experience | PASS/FAIL | |
| Product Alignment | PASS/FAIL | |

### Blocking Issues
1. [issue] — [fix]

### Non-Blocking Notes
1. [observation]

### Ship Confidence: [HIGH / MEDIUM / LOW]
```

If any gate is FAIL, fix the blocking issues before declaring SHIP IT.
