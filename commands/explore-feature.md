You are exploring a feature idea within an existing project. This is NOT greenfield ideation — this is scoped exploration that respects the existing codebase, architecture, data model, and constraints.

## What to explore
$ARGUMENTS

## Step 1: Load project context

Before thinking about the feature, understand the world it lives in:

1. **Read CLAUDE.md** (project-level if exists) for goals, conventions, architecture decisions
2. **Scan the codebase structure** — `ls src/`, key directories, existing patterns
3. **Read the data model** — schemas, migrations, types, entities. Understand what data already exists.
4. **Check the existing API surface** — routes, endpoints, services. What's already exposed?
5. **Look at recent git history** — `git log --oneline -20` — what's actively being worked on? Any related changes?

Summarize what you found in 5-10 bullet points under **"Project Context"** so the user can verify your understanding.

## Step 2: Map the feature against what exists

Now think about how this feature fits:

1. **What existing code can this build on?** Identify specific files, components, services, hooks, utilities that already do something similar or adjacent. Don't build from scratch what already exists at 80%.
2. **What data does this feature need?** Does the schema already support it? What migrations are needed? Are there existing fields that are close but not quite right?
3. **What existing UI patterns should this follow?** If the project has a settings page, a list view, a form pattern — the new feature should look like it belongs.
4. **What are the integration points?** Where does this feature touch existing code? Which files need changes vs which are new?
5. **What constraints exist?** Auth model, permissions, existing API contracts, performance budgets, tech stack choices that are already locked in.

## Step 3: Stress-test the idea

Challenge the feature from multiple angles:

### Product lens
- **Does this actually solve a user problem?** Or is it a solution looking for a problem?
- **What's the simplest version that delivers 90% of the value?** Define the MVP scope ruthlessly.
- **What should explicitly NOT be in v1?** Name the tempting additions that should wait.
- **How will we know it's working?** What does the user do differently after this ships?

### Engineering lens
- **What breaks if we build this wrong?** Identify the riskiest part — that's where to spend design time.
- **Is this a one-way or two-way door?** Data model changes are one-way. UI layout is two-way.
- **What's the blast radius?** How many existing files/features does this touch?
- **Does this create technical debt or reduce it?** If it creates debt, is that acceptable for the value delivered?

### Architecture lens
- **Does this fit the existing architecture, or fight it?** If it fights it, either the feature or the architecture needs to change — don't force a square peg.
- **At 10x scale, does this approach still work?** It doesn't need to handle 10x today, but the design shouldn't make 10x impossible.
- **What's the migration path?** If we add optional fields now, will they become required later? Plan for it.

## Step 4: Propose the approach

Don't present a menu of options. Synthesize the best approach:

```
## Feature Brief: [feature name]

### Context
[2-3 sentences: what exists today and why this feature matters]

### Approach
[The recommended approach — specific, concrete, opinionated]

### Builds on existing
- [existing file/component] — [how it's reused or extended]
- [existing pattern] — [how the feature follows it]

### New code needed
- [new file/component] — [what it does]
- [schema changes] — [specific fields/tables]

### Integration points
- [existing file] — [what changes and why]

### Scope (v1)
- [x] [feature A — in scope]
- [x] [feature B — in scope]
- [ ] [feature C — explicitly deferred to v2]
- [ ] [feature D — explicitly deferred to v2]

### Risks
1. [Risk] — [mitigation]

### Next step
[Exactly what to do next: `/architect`, `/plan`, or start building]
```

## Rules

- **Always read the codebase first.** Don't propose approaches that ignore what already exists. The best feature implementation builds on existing patterns, not around them.
- **Be opinionated.** Don't say "you could do A or B." Say "do A because [reason], and here's why B is worse in this context."
- **Scope ruthlessly.** The user asked about a feature, not a product. Keep v1 tight. Name what's deferred.
- **Never propose a rewrite when an extension works.** If existing code gets you 80% there, extend it. Don't rebuild.
- **Think about the user who maintains this later.** Will the feature feel native to the codebase, or bolted on?
