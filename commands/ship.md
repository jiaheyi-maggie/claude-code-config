You are orchestrating a complete feature from architecture through shipping. This is the full pipeline — design, plan, build, review, verify, ship — in one command.

## What to ship
$ARGUMENTS

If no arguments, ask the user what feature they want to ship.

---

## Step 1: Architecture — /architect

Run a four-pillar architecture review on the feature:
- Component boundaries, data architecture, failure modes, security boundaries
- Generate interactive HTML diagram if the feature involves system design
- Define implementation phases with review gates

**Gate:** If critical architectural issues are found, STOP and fix them before proceeding. Do NOT proceed with a flawed design.

Present the architecture review to the user. Wait for approval before proceeding.

---

## Step 2: Explore & Plan

### If this is a feature within an existing project:
Run `/explore-feature` logic — read the codebase, map the feature against existing architecture, identify what to reuse vs build new.

### Then plan:
Run `/plan` logic — create a surgical, reversible implementation plan:
- Specific files to create/modify
- Order of operations
- Rollback procedure
- Acceptance criteria per phase

**Gate:** Plan must be concrete and specific. No vague "implement the feature" steps. Every step names files, functions, and expected behavior.

Present the plan to the user. Wait for approval before proceeding.

---

## Step 3: Build

Execute the plan using the appropriate engineers:

### Determine who builds:
- **Backend/API/systems work** → spawn `@senior-engineer`
- **Frontend/UI work** → spawn `@frontend-engineer`
- **Both** → spawn `@senior-engineer` for backend first, then `@frontend-engineer` for UI
- **Full-stack single feature** → `@senior-engineer` handles it

### Build rules:
- Follow the plan from Step 2 — don't deviate without reason
- TDD when possible — write tests alongside implementation
- Use Context7 for any external library APIs
- After each implementation phase, run tests before moving to the next phase

---

## Step 4: Code Review (MANDATORY)

Spawn `@code-reviewer` for a full 4-pass review:
1. Bugs — logic errors, edge cases, race conditions
2. Logic — does the code do what it claims?
3. Engineering quality — architecture, abstractions, performance, error handling
4. Product alignment — does this match the original request?

**Gate:** ALL critical and high issues must be fixed before proceeding. Re-review only if structural changes were made.

---

## Step 5: QA Verification (if feature has UI)

If the feature has any user-facing UI:
1. Spawn `@qa-engineer` to verify all features against the original request
2. Use Playwright to screenshot every page/state affected
3. Verify: empty state, populated state, error state, loading state
4. Verify responsive: mobile (375px), desktop (1280px)
5. Accept user tweaks and iterate until satisfied

If the feature is backend-only, skip to Step 6.

---

## Step 6: Pre-ship Quality Gate

Run `/pre-ship` logic — the 7 final quality gates:
1. Build passes with zero warnings
2. Semantic audit — every function does what its name says
3. Edge cases — empty, null, max, concurrent
4. Security — OWASP top 10 check
5. Performance — no obvious bottlenecks
6. Developer experience — clean code, good naming, documented
7. Product alignment — feature matches the original request

**Gate:** All 7 gates must pass. If any fail, fix and re-check.

---

## Step 7: Report

```
## Ship Report: [feature name]

### Architecture
- [key design decisions]
- [diagram location if generated]

### What was built
- [files created/modified with one-line descriptions]

### Tests
- [test count, pass rate]

### Code review
- [issues found and fixed]

### QA verification
- [UI states verified, screenshots taken]

### Pre-ship
- [all 7 gates: pass/fail]

### Status: SHIPPED ✓
```

---

## Rules

- **Never skip the architecture step.** Even for "simple" features — 5 minutes of design prevents 2 hours of rework.
- **Never skip the code review.** Every feature, no exceptions. This is enforced by CLAUDE.md.
- **Wait for user approval** after architecture (Step 1) and plan (Step 2). Don't auto-proceed — the user may want to adjust direction.
- **Fix issues before proceeding.** Each gate is a hard stop. Don't accumulate tech debt across steps.
- **Use the right specialist.** Backend work → senior-engineer. Frontend → frontend-engineer. Don't make one agent do everything poorly.
- **If any step fails 3 times, STOP.** Report what happened and ask for guidance. Don't keep retrying.
