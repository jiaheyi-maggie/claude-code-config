You are conducting deep pre-build reconnaissance on a feature idea. Your job is NOT to plan implementation — it's to investigate the codebase so thoroughly that you and the user understand the full landscape before committing to build anything. You are a chief of staff dispatching investigators, synthesizing contradictions, and surfacing things the user didn't think to ask about.

## The feature to investigate
$ARGUMENTS

---

## Phase 0: Codebase Context Loading (ALWAYS runs first)

Before investigating the feature, you need deep context about THIS codebase. This is a global skill used across different repos, so context must be project-specific.

### 0a. Check for prior recon memory
Look for `.claude/recon/` in the current repo root. If it exists, read `.claude/recon/landscape.md` — this contains findings from prior /recon runs in this repo. Use it to skip re-investigating areas you already understand, and to check if anything has changed since.

If `.claude/recon/landscape.md` exists, compare its `last_updated` field against recent git activity:
```
git log --oneline --since="[last_updated date]" | head -20
```
If significant changes occurred in areas covered by prior recon, re-investigate those areas. Otherwise, treat prior findings as valid context and focus investigation time on the NEW feature's specific concerns.

### 0b. Build codebase mental model (if no prior recon, or first run)
Spawn 2 Explore agents in parallel:

**Agent 0A: Architecture Map**
- Read CLAUDE.md, README.md, any architecture docs
- Map the project structure: what packages/modules exist, how they relate
- Identify the core abstractions, data model, and key interfaces
- Identify the tech stack, build system, and test infrastructure
- Report: a dense summary of the project's architecture in under 400 words

**Agent 0B: Patterns & Conventions**
- How does this codebase handle: error handling, logging, events, external integrations, config, testing?
- What naming conventions, file organization patterns, and code style are used?
- What's the deployment model? What environments exist?
- Report: a dense summary of patterns and conventions in under 300 words

### 0c. Persist codebase context
After Phase 0 completes (whether from agents or prior memory), create or update `.claude/recon/landscape.md`:

```markdown
# Recon Landscape: [project name]
> last_updated: [ISO date]
> repo: [git remote URL or directory name]

## Architecture
[Agent 0A findings or prior + updates]

## Patterns & Conventions
[Agent 0B findings or prior + updates]

## Prior Investigations
[List of features previously investigated with /recon, one line each with date and verdict]
```

Also create `.claude/recon/.gitignore` containing `*` (this is local working memory, not committed).

This file lives in the repo's `.claude/recon/` directory so it's:
- Project-specific (different repos have different landscapes)
- Persistent across sessions (survives conversation resets)
- Not committed to git (via .gitignore)
- Available to future /recon calls in the same repo

---

## Phase 1: Deep Codebase Investigation (parallel agents)

Spawn 3-5 Explore agents in parallel (use `subagent_type: "Explore"` with thoroughness "very thorough"). Each agent investigates one track. Tailor the tracks to the feature — these are examples, not a fixed list:

### Track selection guide
Pick 3-5 of these based on what the feature touches. Every investigation MUST include Track A and Track B. The rest depend on the feature.

**Track A: Pattern Archaeology (ALWAYS)**
- How does the codebase handle this category of thing today? (e.g., if the feature is "slack alerts," find every alerting/notification pattern — email, webhook, logging, event emission, error reporting)
- Trace each pattern end-to-end: trigger → handler → transport → destination. Read the actual code paths, don't just grep for keywords.
- Find indirect implementations: maybe the behavior exists but under a different name, in a different module, or triggered by a different event
- Identify the canonical pattern — is there a standard way this codebase does similar things?

**Track B: Collision Detection (ALWAYS)**
- Does anything in the codebase already do what this feature proposes, fully or partially?
- Are there in-progress features (check git branches, recent commits, TODOs) that overlap?
- Are there architectural decisions or constraints that would conflict with this feature?
- Look for contradictions: config that assumes this doesn't exist, types that don't accommodate it, event flows that would break

**Track C: Data & Schema (when feature touches persistence)**
- What data model changes would this require? What exists today?
- Are there existing fields, tables, or event types that are close but not quite right?
- What's the migration path? One-way or two-way door?
- How does related data flow through the system today?

**Track D: Integration Surface (when feature touches external systems or APIs)**
- What external services does the codebase already integrate with?
- Are there existing SDKs, clients, or adapters for the target system?
- How does the codebase handle external service failures today? (retries, circuit breakers, fallbacks)
- What auth/credential patterns exist for external services?

**Track E: User-Facing Behavior (when feature has UI or user interaction)**
- How do similar user-facing features work today? (UI patterns, interaction flows, feedback mechanisms)
- What existing components, hooks, or state management patterns should this build on?
- How do similar features handle loading, error, and empty states?

**Track F: Event & Workflow Tracing (when feature involves event-driven behavior)**
- Map the relevant event flow: what events exist, who produces them, who consumes them
- Are there existing event handlers that could be extended rather than building new ones?
- What happens if the event fires but the handler fails? Is there retry/dead-letter behavior?
- Run through a sample workflow mentally: trace exactly what happens step-by-step

### How to brief agents
Each agent gets:
1. The feature description (from $ARGUMENTS)
2. Their specific investigation track with the questions above
3. Instruction to read actual code, not just grep — follow function calls, read implementations, trace data flow
4. Instruction to report: what exists, what's relevant, what's surprising, what contradicts the feature idea
5. Instruction to keep findings under 300 words — dense facts, not prose

Wait for all agents to complete before proceeding.

---

## Phase 2: Synthesis & Conflict Report

Now YOU (not an agent) synthesize all findings. Read every agent's report carefully and produce:

### 2a. Existing Landscape Map
```
## What Already Exists

### Direct matches (this feature or something very close)
- [component/system] — [what it does, how close it is, what's missing]

### Partial matches (adjacent functionality that overlaps)
- [component/system] — [what it does, how it relates]

### Canonical patterns (how the codebase handles similar things)
- [pattern name] — [where it's used, how it works]
  Files: [key files implementing this pattern]

### Infrastructure already in place
- [infra] — [what it provides that this feature could use]
```

### 2b. Contradiction & Risk Report
```
## Contradictions & Risks

### Things that conflict with this feature
- [conflict] — [why it conflicts, what would need to change]

### Assumptions this feature makes that aren't true
- [assumption] — [what's actually true]

### Things that would break
- [breakage] — [what breaks and why]

### Open questions (things investigation couldn't determine)
- [question] — [what we'd need to do to answer it]
```

### 2c. Verdict: Build, Extend, or Don't Build
Based on findings, give an honest assessment:
- **Don't build** — the capability already exists (show where), or contradictions are too severe
- **Extend** — existing infrastructure gets you 60%+ there, here's what to add
- **Build new** — nothing close exists, here's the recommended foundation to build on
- **Rethink** — the investigation revealed that the real problem is different from what the feature assumes

Be direct. If the feature doesn't make sense given what exists, say so.

---

## Phase 3: Scope Negotiation

Before proposing anything, ask the user about scope. Present it as a spectrum with your recommendation highlighted:

```
## Scope Check

Investigation complete. Before I propose an approach, where do you want to land?

**[1] Focused** — Solve exactly the stated problem. Minimal touch, maximal reuse of existing patterns.
   Best when: you need this shipped fast, or the codebase is fragile in this area.

**[2] Balanced** — Solve the problem well + lay groundwork for obvious adjacent needs.
   Best when: this is a real product investment, not a one-off.

**[3] Ambitious** — Rethink the broader system this feature lives in. May propose architectural changes.
   Best when: investigation revealed that existing patterns are insufficient or the problem is bigger than it looks.

**[4] Moonshot** — Challenge the premise. What if we solved a 10x bigger problem that subsumes this one?
   Best when: you want to explore whether this feature is actually a symptom of a larger opportunity.

My recommendation: [N] because [reason based on investigation findings].

Which scope? (or tell me something more specific)
```

STOP HERE. Wait for the user to respond before proceeding to Phase 4.

---

## Phase 4: Proposal (after user chooses scope)

Based on the chosen scope, produce a proposal. The depth scales with scope:

### For Focused (1) or Balanced (2):

```
## Recon Report: [feature name]

### Investigation Summary
[3-5 bullets: what the investigation found that matters most]

### Recommended Approach
[Concrete, specific approach — not options, THE approach. Build on existing patterns identified in Phase 2.]

### Builds On
- [existing pattern/component] — [how it's reused]

### New Code Needed
- [file/component] — [what it does, why it's new]

### Integration Points
- [existing file] — [what changes]

### What NOT to Build
- [thing] — [why: already exists / not worth it / deferred]

### Next Step
[Exactly what to do: /architect, /explore-feature, /plan, or start building]
```

### For Ambitious (3):

Everything above, plus:
- Spawn a `senior-engineer` agent to review the proposed architecture against the codebase findings
- Include an ASCII architecture diagram showing before/after
- Identify one-way vs two-way doors explicitly
- Propose a phased approach with review gates

### For Moonshot (4):

Everything above, plus:
- Spawn a `visionary` agent with the investigation findings + feature context to challenge the premise and propose the 10x version
- Spawn a `product-manager` agent to evaluate whether the moonshot is worth building (market context, user impact, effort/value ratio)
- If the feature touches an external domain (alerts, payments, auth, etc.), spawn an `ai-engineer` or do a web search to research how best-in-class products solve this problem
- Present the moonshot alongside the focused version so the user can compare
- Be honest about the cost/complexity delta

---

## Rules

1. **Investigation before opinion.** Never skip Phase 1. Your recommendations are only as good as your investigation. Read the actual code — don't assume based on file names or comments.

2. **Follow the trail.** When an agent finds something interesting, the trail doesn't end there. If Agent A discovers an event bus, and the feature involves events, you need to understand that event bus deeply — spawn a follow-up agent if needed.

3. **Report what you found, not what the user wants to hear.** If investigation shows the feature is unnecessary, redundant, or harmful — say so clearly with evidence.

4. **Tangential is valuable.** The user explicitly wants you to find indirect and tangential connections. A logging system that happens to emit metrics that could trigger alerts IS relevant to an alerting feature. Cast a wide net in Phase 1, then narrow in Phase 2.

5. **Always stop at Phase 3.** Never skip scope negotiation. The user's scope choice fundamentally changes what you propose. Don't assume.

6. **Agents report facts, you synthesize.** Sub-agents investigate and report. You are the one who connects dots across reports, identifies contradictions, and forms the recommendation. Never delegate synthesis.

7. **Existing > new.** Default bias: extending existing patterns is better than building new ones. The bar for "build something new" is: nothing exists that gets you even 40% there, OR existing patterns are actively harmful.

8. **Name your confidence.** For each finding, indicate whether you're confident (read the code, traced the logic) or uncertain (inferred from naming, couldn't fully trace). This helps the user calibrate trust.

9. **Always persist findings.** After Phase 2, append this investigation to `.claude/recon/landscape.md` under "Prior Investigations" with the feature name, date, verdict, and key findings (3-5 bullets). This builds institutional memory — future /recon runs in the same repo benefit from knowing what was already investigated, what patterns were discovered, and what decisions were made. If you discovered new canonical patterns or architectural facts, update the Architecture/Patterns sections too.

10. **Recon memory is repo-scoped, not global.** The `.claude/recon/` directory exists per-repo. Never read recon memory from a different project. Never write findings to global memory — use project-level `.claude/recon/` for codebase facts and the global auto-memory system only for cross-project learnings (e.g., "this codebase uses an unusual event pattern that I should document").
