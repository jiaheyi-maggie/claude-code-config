Eval-driven development — define what "good" looks like before building, then measure against it continuously.

## Action
$ARGUMENTS

If no arguments, show the current eval status for the project.

## Usage

### `/eval create [name]` — Define a new eval
### `/eval run` — Run all evals
### `/eval run [name]` — Run a specific eval
### `/eval status` — Show pass/fail status of all evals
### `/eval regression` — Run regression evals against baseline

---

## Philosophy

Evals are unit tests for AI-assisted development. Before implementing a feature:
1. Define what "correct" looks like (the eval)
2. Implement the feature
3. Run the eval to verify
4. Track regressions as you keep building

---

## Create an eval

Write to `.claude/evals/[name].md`:

```markdown
# Eval: [name]

## Type
[capability | regression | quality]

## What it tests
[One sentence: what behavior or quality is being verified]

## Success criteria
[Specific, measurable criteria — not vague "should work well"]

## Grader

### Code-based checks
- [ ] `npm run build` exits 0
- [ ] `npm test -- --grep "[pattern]"` passes
- [ ] `grep -r "console.log" src/ | wc -l` returns 0
- [ ] Response time < 200ms (measure with `time curl ...`)

### Behavioral checks (manually verify)
- [ ] [Description of expected behavior]
- [ ] [Description of edge case handling]
- [ ] [Description of error state]

### Quality checks
- [ ] Code coverage > 80% for new code
- [ ] No TypeScript `any` types in new code
- [ ] All new functions have error handling

## Baseline
[If regression eval: the current known-good state to compare against]

## Result
[PASS / FAIL / NOT RUN — updated by /eval run]
[Last run: timestamp]
```

---

## Run evals

For each eval in `.claude/evals/`:

1. **Read the eval definition**
2. **Run code-based checks:**
   - Execute each command
   - Record pass/fail with output
3. **Run behavioral checks:**
   - If automated (has a command), run it
   - If manual, report what needs human verification
4. **Run quality checks:**
   - Execute coverage, lint, type checks
5. **Update the eval result:**
   - Set result to PASS or FAIL
   - Record timestamp
   - If FAIL, record which specific checks failed

Report:
```
## Eval Results

| Eval | Type | Result | Failed checks |
|------|------|--------|---------------|
| [name] | capability | PASS | — |
| [name] | regression | FAIL | build, test-auth |
| [name] | quality | PASS | — |

Overall: X/Y passing
```

---

## Regression evals

Compare current state against a baseline (usually the last checkpoint):

1. **Read baseline** from eval definition or most recent checkpoint
2. **Run the same eval suite** that passed at baseline
3. **Compare results:**
   - Tests that passed before but fail now = **REGRESSION**
   - Tests that failed before but pass now = **IMPROVEMENT**
   - New tests = **NEW COVERAGE**

Report:
```
## Regression Check (vs baseline: [checkpoint name])

Regressions: [count]
  - [eval name]: [what broke]

Improvements: [count]
  - [eval name]: [what got fixed]

New coverage: [count]
  - [eval name]: [what's newly tested]
```

**If any regressions are found, flag them as P0 — regressions must be fixed before shipping.**

---

## Integrate with development workflow

### Before implementation
```
/eval create user-notifications
```
Define what success looks like before writing code.

### During implementation
```
/eval run user-notifications
```
Check progress — are we meeting the criteria yet?

### Before shipping
```
/eval run
/eval regression
```
Full eval suite + regression check. All must pass.

### After shipping
```
/checkpoint create post-notifications
```
Save the passing state as the new baseline.

---

## Rules

- **Define evals BEFORE building.** If you define them after, you're testing what you built, not what you should have built.
- **Code-based checks are mandatory.** Every eval must have at least one automated check (build, test, lint, grep). Manual-only evals are unreliable.
- **Regressions are P0.** A failing regression means you broke something that was working. Fix it before continuing.
- **Evals are append-only.** Never delete an eval. If a feature is removed, mark the eval as `[DEPRECATED]`, not deleted.
- **Keep evals fast.** Each eval should run in under 30 seconds. If it takes longer, break it into smaller evals.
