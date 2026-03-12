---
description: Fix a bug with mandatory reproduction, verification, and attempt tracking. Use when a bug needs to be fixed and you want to ensure it actually gets resolved.
---

# Strict Bug Fix Protocol

You are fixing a bug. Follow this protocol EXACTLY. Do not skip steps. Do not declare victory without verification.

**Bug description:** $ARGUMENTS

---

## Phase 1: Understand (do NOT write any code yet)

1. **Parse the bug report.** Restate the bug in your own words: what is the expected behavior vs actual behavior?
2. **Find the code.** Locate the exact file(s) and function(s) involved. Read them fully — do not skim.
3. **Check history.** Look for a bug tracking file at `.claude/bugs.md` in the project root. If this bug was reported before, read what was already tried and EXPLICITLY avoid repeating failed approaches. If the file doesn't exist, create it.
4. **Trace the data flow.** Starting from the entry point (button click, API call, CLI command), trace the full path the data takes through the code until the point of failure. Write down each step. Do NOT skip this — most failed fixes happen because Claude pattern-matches on the error message instead of tracing the actual execution path.

## Phase 2: Reproduce

5. **Reproduce the bug.** Run the code and trigger the bug. If you cannot reproduce it, ask the user for exact reproduction steps. Do NOT proceed to fixing without reproduction — a fix you can't verify is not a fix.
6. **Capture the error output.** Save the exact error message, stack trace, or incorrect behavior.

## Phase 3: Diagnose

7. **State your hypothesis.** In one sentence, what is the root cause? Not "X is broken" — explain WHY it's broken. What value is wrong? What condition is missed? What assumption is violated?
8. **Validate the hypothesis BEFORE coding.** Add a temporary log/print at the suspected failure point. Run the code again. Does the log confirm your theory? If not, revise your hypothesis. Do NOT start coding a fix based on an unvalidated guess.

## Phase 4: Fix

9. **Make the minimal fix.** Change as little as possible. Do NOT refactor surrounding code. Do NOT "improve" things while you're in here.
10. **Log the attempt.** Append to `.claude/bugs.md`:
    ```
    ## [date] Bug: <one-line description>
    - **Hypothesis:** <what you thought was wrong>
    - **Fix:** <what you changed>
    - **Files:** <files modified>
    - **Result:** PENDING
    ```

## Phase 5: Verify (MANDATORY — do NOT skip)

11. **Re-run the exact reproduction from Phase 2.** Does the bug still occur?
    - **YES → the fix failed.** Update the bug log result to `FAILED - <why>`. Go back to Phase 3 with a new hypothesis. You have a maximum of 3 attempts before you must stop and escalate to the user with a detailed report of what you tried.
    - **NO → proceed to step 12.**
12. **Run the broader test suite** (if one exists). Check for regressions.
13. **Update the bug log** result to `FIXED`.
14. **Report to the user:** One-line root cause, one-line fix, files changed.

---

## Rules

- **NEVER say "fixed" without running the code and confirming.** The word "fixed" means verified.
- **NEVER add try/catch or error suppression as a "fix".** That's hiding the bug, not fixing it.
- **If your second attempt fails**, you MUST re-read the code from scratch — your mental model is wrong. Don't keep tweaking the same area.
- **If your third attempt fails**, STOP. Report to the user: "I've tried 3 approaches and none worked. Here's what I tried and what I learned: [...]". Ask for guidance.
- **Never delete or reduce the bug log.** It's an append-only record.
