Prepare a complete handover so the next Claude Code session picks up exactly where this one left off. Follow these steps precisely:

## Step 1: Write the handover file

Create/overwrite `.claude/handover.md` in the project root with this structure:

```
# Session Handover
> Last updated: [current date and time]

## Current State
- What's working right now
- What branch we're on and its status
- Build/test status

## In Progress
- Tasks that are partially complete
- Current blockers or open questions
- Files actively being modified

## Next Steps
- Prioritized list of what to do next
- Any commands to run or checks to perform

## Key Context
- Non-obvious decisions made this session and WHY
- Gotchas or pitfalls discovered
- Things that almost worked but didn't (and why)
```

Keep it concise — only include information that can't be derived from git log or reading the code.

## Step 2: Ensure auto-loading

Check if the project has a `CLAUDE.md` (or `.claude/CLAUDE.md`) in its root. If it does, check whether it already contains a reference to the handover file (like `@.claude/handover.md`). If not, append this line to the end of the project CLAUDE.md:

```
@.claude/handover.md
```

If no project CLAUDE.md exists, create `.claude/CLAUDE.md` with:

```
@.claude/handover.md
```

This ensures the next session automatically loads the handover context.

## Step 3: Save durable lessons to memory

If any of the following were discovered this session, save them as memory files (using the memory system at ~/.claude/projects/):
- **Feedback**: Corrections to Claude's approach that should persist permanently
- **Project context**: Architecture decisions, constraints, or goals that won't change soon
- **References**: External resources, dashboards, or docs discovered

Do NOT save tactical/ephemeral state to memory — that belongs in the handover file.

## Step 4: Confirm

Tell the user:
1. What was written to `.claude/handover.md`
2. Whether CLAUDE.md was updated to auto-import it
3. What (if anything) was saved to memory
4. Remind them: for quick returns, `claude --continue` resumes the full conversation. The handover file is for when context is lost (new session, compaction, or handing off to a teammate).
