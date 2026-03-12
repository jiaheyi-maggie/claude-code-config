Stop and perform a rigorous review of the feature you just implemented. Do NOT skip any step. This review exists because implementation momentum causes tunnel vision — you optimized for "getting it working" and may have missed bugs, broken assumptions, or drifted from the product intent.

## Step 1: Re-anchor on context

Before reviewing any code, re-establish WHO you are and WHAT you're building. Check these sources in order:

1. **Conversation history**: Find the original prompt, role definition, or product vision that started this task. Look for output from `/generate-prompt`, any "act as..." instructions, or product requirements the user gave you.
2. **Project CLAUDE.md / .claude/CLAUDE.md**: Check for project-level context, goals, or constraints.
3. **`.claude/handover.md`**: Check for session state from a prior handover.

Restate in 2-3 sentences: your role, the product vision, and the specific feature you just implemented. If you cannot find the original context, ask the user before proceeding.

## Step 2: Identify what changed

Run `git diff HEAD` (or `git diff` if nothing is committed yet) to see ALL changes since the last clean state. Also run `git diff --name-only` to get the list of modified files.

If $ARGUMENTS is provided, focus the review on that specific area: $ARGUMENTS

## Step 3: Review — three passes

Make THREE separate passes over the changed code. Each pass has a different lens. Do not combine them.

### Pass 1: Bug hunt
For every changed file, read the full diff and check:
- **Null/undefined access**: Are there any paths where a variable could be null/undefined when accessed?
- **Off-by-one errors**: Array indexing, loop bounds, pagination offsets
- **Async issues**: Missing `await`, unhandled promise rejections, race conditions
- **Error handling**: Are errors caught? Are they caught specifically (not swallowed)? Do bulk operations isolate per-item failures?
- **State mutations**: In React — are you mutating state during render? Missing dependency arrays in useEffect?
- **Type mismatches**: Is the data shape from the API actually what the frontend expects? Check the full chain: API response → parsing → state → render.
- **Security**: SQL injection, XSS, open redirects, leaked secrets, missing auth checks

### Pass 2: Logic verification
For every function/handler/component you touched:
- **Read the name, then read the body.** Does it actually do what the name says? (e.g., a function called `handleDelete` must actually delete, not archive)
- **Trace 3 critical user flows end-to-end**: user action → handler → API call → DB/state mutation → UI update. Verify each link.
- **Edge cases**: What happens with empty input? Zero items? One item? Maximum items? Duplicate items?
- **Boundary conditions**: What happens when the API returns an error? When the network is down? When the user double-clicks?

### Pass 3: Product alignment
Re-read the original requirements/vision from Step 1, then for each change ask:
- **Does this actually deliver what was asked for?** Not "is it close" — does it precisely match the intent?
- **Did I gold-plate?** Did I add complexity, features, or abstractions that weren't requested?
- **Did I cut corners?** Are there requirements I quietly dropped or deferred without telling the user?
- **User experience**: If I were the end user, would this feel right? Are there rough edges, confusing states, or missing feedback?

## Step 4: Report

Present findings as a structured list:

```
## Review: [feature name]
Context: [your role] building [product] — feature: [what was implemented]

### Issues Found
1. **[SEVERITY: bug/logic/alignment/nitpick]** file:line — description
   Fix: [specific fix]

2. ...

### Verified
- [x] [flow 1] works end-to-end
- [x] [flow 2] works end-to-end
- [ ] [flow 3] — issue found (see #N above)

### Verdict
[PASS — ship it | ISSUES — fix N items before shipping]
```

If you find issues, fix them immediately after presenting the report. Do not ask for permission to fix bugs — just fix them and show the diff.
