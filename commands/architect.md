Perform an architecture review before implementation begins. This command exists because the most expensive bugs are architectural — they're embedded in the foundation and require rewrites to fix.

## What to review
$ARGUMENTS

If no arguments, review the current project's architecture or the most recent PRD/plan.

## Step 1: Understand the system

Read the PRD (if exists), CLAUDE.md, and key source files. Build a mental model of:
- What the system does
- How data flows through it
- What the key entities and relationships are
- What external services it depends on

## Step 2: Architecture review — four pillars

### Pillar 1: Component boundaries
- Are responsibilities clearly separated? Can you describe what each module does in one sentence?
- Are there god objects/modules that do too much?
- Is the dependency graph clean? Draw it as ASCII:
  ```
  [Client] → [API Gateway] → [Service Layer] → [Data Layer]
                                    ↓
                              [External APIs]
  ```
- Are there circular dependencies?
- Can each component be tested in isolation?

### Pillar 2: Data architecture
- Is the data model normalized appropriately? (Not over-normalized, not under-normalized)
- Are there optional fields now that should be required later? Add them as optional NOW
- Is the schema designed so future features are a migration, not a rewrite?
- Where does state live? Is there a single source of truth for each piece of data?
- What happens when data is deleted? Is cleanup complete?

### Pillar 3: Failure modes
For each component, answer:
- What happens when it's slow? (Timeouts, backpressure, circuit breakers?)
- What happens when it's down? (Graceful degradation? Retry? Queue?)
- What happens when it returns bad data? (Validation at boundaries?)
- What happens at 100x current load? (Config change or rewrite?)
- What are the single points of failure?

### Pillar 4: Security boundaries
- Where does untrusted input enter the system? Is it validated at every entry point?
- Are auth/authz checks at the right layer? (Not in the UI only)
- What data is sensitive? Is it encrypted at rest and in transit?
- Are secrets managed properly? (Not in code, not in env vars that could leak)
- What's the blast radius if a component is compromised?

## Step 3: Design decisions audit

For each major design decision (DB choice, framework, auth strategy, deployment model):
- **Is this a one-way or two-way door?** One-way doors (hard to reverse) need more scrutiny
- **Does this optimize for the right thing?** (Developer speed vs. runtime performance vs. operational simplicity)
- **Is this "boring technology"?** Novel tech needs a very good justification
- **What's the operational cost?** (Monitoring, on-call burden, hiring, documentation)

## Step 4: Report

```
## Architecture Review: [system name]

### Diagram
[ASCII architecture diagram showing components, data flow, and boundaries]

### Strengths
- [What's well-designed]

### Issues
1. **[SEVERITY: critical/warning/suggestion]** — [description]
   Impact: [what goes wrong if not fixed]
   Fix: [specific recommendation]

### Design Decisions
| Decision | Classification | Verdict |
|----------|---------------|---------|
| [e.g., PostgreSQL] | Two-way door | Good — boring tech, fits the data model |
| [e.g., microservices] | One-way door | Reconsider — monolith is simpler at this scale |

### Scalability Assessment
Current design supports: [X users / Y requests per second]
Bottleneck at scale: [what breaks first]
Path to 100x: [config change / minor refactor / rewrite]

### Verdict
[PROCEED / REVISE — fix N issues before implementing]
```

If critical issues are found, do NOT proceed to implementation. Fix the architecture first — it's 100x cheaper to fix now than after code is written.
