Save or restore a known-good state during development. Checkpoints let you mark a working point, continue building, and roll back if things go wrong.

## Action
$ARGUMENTS

If no arguments, show the current checkpoint status.

## Usage

### `/checkpoint create [name]` — Save current state
### `/checkpoint list` — Show all checkpoints
### `/checkpoint restore [name]` — Restore to a checkpoint
### `/checkpoint verify` — Run full verification on current state
### `/checkpoint diff [name]` — Show changes since checkpoint

---

## Create a checkpoint

1. **Verify current state is clean:**
   ```bash
   # Build passes
   npm run build 2>&1 || python -m pytest 2>&1 || make build 2>&1
   # Tests pass
   npm test 2>&1 || python -m pytest 2>&1 || make test 2>&1
   # Lint passes
   npm run lint 2>&1 || ruff check . 2>&1 || true
   ```

2. **Save the checkpoint:**
   ```bash
   mkdir -p .claude/checkpoints
   ```

   Write to `.claude/checkpoints/[name].md`:
   ```
   # Checkpoint: [name]
   > Created: [timestamp]
   > Git commit: [hash]
   > Branch: [branch]
   > Build: PASS
   > Tests: PASS ([count] passing)
   > Lint: PASS

   ## What's working
   - [list of features/modules that are verified working]

   ## Files at this state
   [output of git diff --stat from last commit]

   ## How to restore
   git stash && git checkout [hash]
   ```

3. **Create a git tag** for easy restoration:
   ```bash
   git tag "checkpoint/[name]" HEAD
   ```

4. Report: `Checkpoint "[name]" saved at [hash]. Restore with /checkpoint restore [name]`

---

## List checkpoints

Read all files in `.claude/checkpoints/` and display:
```
Checkpoints:
  [name] — [date] — [git hash] — [build/test status]
  [name] — [date] — [git hash] — [build/test status]
```

---

## Restore a checkpoint

1. **Warn the user:** "This will stash current changes and checkout [hash]. Proceed?"
2. Wait for confirmation.
3. Execute:
   ```bash
   git stash push -m "pre-restore-[name]"
   git checkout [hash from checkpoint file]
   ```
4. Run verification to confirm the restored state is still good:
   ```bash
   npm run build && npm test || python -m pytest
   ```
5. Report result.

---

## Verify current state

Run the full verification pipeline:
```
1. Build: [PASS/FAIL]
2. Tests: [PASS/FAIL] ([count] passing, [count] failing)
3. Lint: [PASS/FAIL] ([count] warnings)
4. Type check: [PASS/FAIL]
5. Security: no known vulnerabilities in dependencies
```

Compare against the most recent checkpoint:
```
Changes since checkpoint "[name]":
  [files changed]
  [tests added/removed]
  [build status comparison]
```

---

## Diff since checkpoint

Show what changed since a named checkpoint:
```bash
git diff [checkpoint-hash]..HEAD --stat
git diff [checkpoint-hash]..HEAD
```

---

## Rules

- **Only checkpoint verified states.** Build and tests must pass before creating a checkpoint. Don't checkpoint broken states.
- **Name checkpoints meaningfully.** "checkpoint-1" is useless. "auth-working" or "pre-refactor" tells you what state you're saving.
- **Checkpoint before risky changes.** About to refactor a core module? Checkpoint first.
- **Checkpoint after each `/ship` or `/build-features` phase.** The phase gate is a natural checkpoint.
