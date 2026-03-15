Stop and perform a rigorous review of the feature you just implemented. Do NOT skip any step. This review exists because implementation momentum causes tunnel vision — you optimized for "getting it working" and may have missed bugs, broken assumptions, or drifted from the product intent.

## Step 1: Re-anchor on context

Before reviewing any code, re-establish WHO you are and WHAT you're building. Check these sources in order:

1. **Conversation history**: Find the original prompt, role definition, or product vision that started this task. Look for output from `/generate-prompt`, any "act as..." instructions, or product requirements the user gave you.
2. **Project CLAUDE.md / .claude/CLAUDE.md**: Check for project-level context, goals, or constraints.
3. **`.claude/handover.md`**: Check for session state from a prior handover.

Restate in 2-3 sentences: your role, the product vision, and the specific feature you just implemented. If you cannot find the original context, ask the user before proceeding.

For this review, adopt **two perspectives simultaneously**: (1) a senior CPM evaluating product-market fit, user experience, and whether the feature delivers on the vision, and (2) a principal software engineer evaluating architecture, performance, maintainability, and engineering rigor.

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

### Pass 3: Engineering quality (principal engineer lens)
Review the implementation as a principal/staff engineer would in a design review:
- **Architecture**: Does the code belong where it is? Is responsibility correctly separated, or is business logic leaking into UI components / API routes / utilities?
- **Abstractions**: Are they at the right level? Too many layers for a simple feature? Or raw duplication that should be extracted? Apply the "rule of three" — don't abstract until the third use, but do abstract at the third.
- **Performance**: Are there N+1 queries, unnecessary re-renders, O(n²) loops on data that could grow, missing indexes, or unbounded fetches? Would this hold up at 100x the current data volume?
- **Data model**: Are the types/schemas correct and complete? Are fields named consistently? Will this schema support the next 2-3 features without migration?
- **API design**: Are endpoints/function signatures intuitive, consistent with existing patterns, and hard to misuse? Do they return the right shape and status codes?
- **Error boundaries**: Are errors surfaced to the right level? Does the caller get enough context to act on the error, or just a generic "something went wrong"?
- **Testability**: Could someone write a test for this without mocking half the system? If not, the design likely has coupling problems.
- **Observability**: Can you debug this in production? Are there logs at decision points with enough context (IDs, counts, durations)?

### Pass 4: Product alignment
Re-read the original requirements/vision from Step 1, then for each change ask:
- **Does this actually deliver what was asked for?** Not "is it close" — does it precisely match the intent?
- **Did I gold-plate?** Did I add complexity, features, or abstractions that weren't requested?
- **Did I cut corners?** Are there requirements I quietly dropped or deferred without telling the user?
- **User experience**: If I were the end user, would this feel right? Are there rough edges, confusing states, or missing feedback?

## Step 4: End-to-end verification (MANDATORY — actually run the code)

This is not a code-reading exercise. You must **run the system and verify every feature works**.

### 4a: Build the feature table
Find the feature list / acceptance criteria from Step 1 (PRD, CLAUDE.md, conversation history, or the current phase's scope). List every feature in a table:

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 1 | [feature name] | PENDING | |
| 2 | ... | PENDING | |

### 4b: Test every feature
For EACH feature in the table:
1. **Start the application** (dev server, build, or whatever is needed)
2. **Execute the feature's happy path** — trigger it exactly as a user would. Verify it produces the correct result.
3. **Stress test the boundaries:**
   - What happens with empty/missing input?
   - What happens with maximum/oversized input?
   - What happens when you do it twice rapidly (double-click, double-submit)?
   - What happens when a dependency is unavailable (API down, DB unreachable)?
   - What happens with concurrent usage (if applicable)?
4. **Run the existing test suite** — `npm test`, `pytest`, `cargo test`, whatever the project uses. All tests must pass.
5. **Update the table** — mark each feature as PASS, FAIL, or PARTIAL with specific notes on what broke.

### 4c: Regression check
Verify that features from PREVIOUS phases still work. New code can break old features — test at least the 3 most critical existing flows.

### 4d: Results
If ANY feature is FAIL or PARTIAL:
- Fix it immediately
- Re-run the verification for that feature AND any features that could be affected
- Update the table

Do NOT proceed to the report until all features are PASS.

## Step 5: Report

Present findings as a structured list:

```
## Review: [feature name]
Context: [your role] building [product] — feature: [what was implemented]

### Issues Found
1. **[SEVERITY: bug/logic/alignment/nitpick]** file:line — description
   Fix: [specific fix]

2. ...

### Feature Verification
| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 1 | [feature] | PASS | verified end-to-end |
| 2 | [feature] | PASS | stress tested with empty/max input |
| 3 | [feature] | FIXED | failed on double-submit, added debounce |

### Regression Check
- [x] [prior feature 1] — still works
- [x] [prior feature 2] — still works

### Verdict
[PASS — ship it | ISSUES — fix N items before shipping]
```

If you find issues, fix them immediately after presenting the report. Do not ask for permission to fix bugs — just fix them and show the diff.
