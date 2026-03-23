Analyze patterns from your development sessions and evolve them into reusable instincts, rules, or skills. This is the continuous learning system — it turns your habits into persistent knowledge.

## Action
$ARGUMENTS

### `/evolve analyze` — Analyze recent observations and suggest instincts
### `/evolve list` — Show all current instincts with confidence scores
### `/evolve promote [id]` — Promote a project instinct to global scope
### `/evolve prune` — Remove low-confidence instincts that haven't been reinforced

---

## What are instincts?

Instincts are small, learned behaviors extracted from how you work. They live in `.claude/instincts/` as markdown files:

```markdown
---
id: inst_[hash]
trigger: "when adding a new API endpoint"
action: "always add input validation with zod, error handling, and a test"
confidence: 0.65
scope: project
observed: 3
last_seen: 2026-03-23
source: observation
---

## Evidence
- 2026-03-20: Created /api/users endpoint → added zod validation + test
- 2026-03-21: Created /api/teams endpoint → added zod validation + test
- 2026-03-23: Created /api/billing endpoint → added zod validation + test
```

Confidence scores:
- **0.3** — First observation. Tentative.
- **0.5** — Seen 2-3 times. Emerging pattern.
- **0.7** — Seen 5+ times. Strong pattern.
- **0.85** — Max. Well-established behavior. Ready for promotion to global.

---

## Analyze (the main command)

1. **Read observations** from `.claude/observations.jsonl`
2. **Read existing instincts** from `.claude/instincts/`
3. **Detect patterns** — look for:

   ### File patterns
   - Same file types edited together (e.g., `.ts` + `.test.ts` always paired)
   - Certain tools always used on certain file types
   - Files that are always modified as a group

   ### Workflow patterns
   - Steps that always happen in sequence (e.g., edit → test → lint)
   - Tools that are always used before/after other tools
   - Common error-then-fix sequences

   ### Code patterns
   - Same types of changes made repeatedly
   - Recurring bug fixes in the same area
   - Patterns from `.claude/bugs.md` that keep appearing

4. **For each detected pattern:**
   - Check if an instinct already exists → increase confidence by 0.1
   - If new → create instinct with confidence 0.3
   - If instinct exists but not recently observed → decrease confidence by 0.05

5. **Report:**

```
## Learning Report

### New instincts discovered
- [trigger] → [action] (confidence: 0.3)

### Reinforced instincts (confidence increased)
- [trigger] → [action] (confidence: 0.5 → 0.6, seen 4 times)

### Fading instincts (not observed recently)
- [trigger] → [action] (confidence: 0.4 → 0.35, last seen 14 days ago)

### Ready for promotion (confidence > 0.8)
- [trigger] → [action] — promote to global with /evolve promote [id]

### Observation stats
- Total observations: [count]
- Unique file types: [list]
- Most common tool: [name] ([count] uses)
- Most edited file: [name] ([count] edits)
```

---

## List instincts

Read all files in `.claude/instincts/` and display:

```
## Project Instincts (scope: project)

| ID | Trigger | Action | Confidence | Observed |
|----|---------|--------|------------|----------|
| inst_abc | when adding API endpoint | add zod + test | 0.65 | 3x |
| inst_def | when editing React component | check accessibility | 0.45 | 2x |

## Global Instincts (scope: global, in ~/.claude/instincts/)

| ID | Trigger | Action | Confidence | Observed |
|----|---------|--------|------------|----------|
| inst_ghi | when fixing a bug | check bugs.md first | 0.80 | 8x |
```

---

## Promote

Move a high-confidence project instinct to global scope (applies to all projects):

1. Read the instinct file
2. Verify confidence >= 0.7
3. Copy to `~/.claude/instincts/[id].md`
4. Update scope to `global`
5. Report: "Instinct [id] promoted to global. It will now apply in all projects."

---

## Prune

Remove instincts that have low confidence and haven't been observed in 30+ days:

1. Read all instincts
2. Identify candidates: confidence < 0.4 AND last_seen > 30 days ago
3. List candidates and ask for confirmation
4. Delete confirmed instincts

---

## How instincts are used

Instincts don't auto-execute — they inform. When Claude starts a task:
1. Read `.claude/instincts/` for project instincts
2. Read `~/.claude/instincts/` for global instincts
3. Match the current task against instinct triggers
4. Apply matching instincts as additional context/rules

This is similar to how `.claude/bugs.md` informs bug fixing — instincts inform all work.

---

## Rules

- **Observations are append-only.** Never delete observation data.
- **Instincts need evidence.** Every instinct must link to at least one specific observation.
- **Confidence decays.** If a pattern stops being observed, its confidence drops. This prevents stale instincts.
- **Promotion requires high confidence.** Don't promote patterns you've seen twice. Wait for 0.7+.
- **User corrections override everything.** If the user says "stop doing X", set that instinct's confidence to 0 immediately.
- **Keep instincts atomic.** One trigger, one action. Don't create compound instincts.
