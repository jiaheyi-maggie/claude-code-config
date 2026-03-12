# How to Launch Multi-Agent Teams Efficiently in Claude Code

## A Practical Guide Synthesized from Debate

*This guide was produced by synthesizing three expert perspectives: an ambitious pro-parallelism position, a cautious risk-aware position, and an analytical framework-driven position. Where the debaters agreed, recommendations are stated with high confidence. Where they disagreed, we present the consensus middle ground with context on the tradeoffs.*

---

## 1. Quick Decision Guide: Single Session vs. Subagents vs. Agent Teams

**The default is a single session.** Most tasks (roughly 70-80%) are handled more efficiently by one session, optionally with subagents. Multi-agent teams are a powerful tool for the right situations, not a general-purpose default.

### Decision Flowchart

**Use a SINGLE SESSION when:**
- The task has sequential dependencies (code -> tests -> docs)
- Most files are shared across sub-tasks
- The task requires deep context about one area of the codebase
- It is a bug fix (almost always)
- It is a small-to-medium feature (single API endpoint, UI component)
- A single session can finish in under ~15-20 minutes

**Use a SINGLE SESSION + SUBAGENTS (Task tool) when:**
- You need parallel research or exploration (reading, not writing)
- You want to decompose work but need to discover dependencies as you go
- The main session needs to maintain coordination context
- You have 2-3 independent read-only investigations

**Use a MULTI-AGENT TEAM when ALL of these are true:**
- You can identify 3+ truly independent workstreams
- Estimated single-session time exceeds 20 minutes
- File overlap between workstreams is below 20%
- Your complexity score (see Section 2) is 7 or higher
- The urgency or professional context justifies the token cost premium

---

## 2. Team Size Guide: How to Choose the Right Number of Teammates

### The Complexity Score Formula

```
Complexity Score = I x D

Where:
  I = number of independent modules/workstreams
  D = average depth per module (1=simple change, 2=moderate feature, 3=deep refactor)
```

### Sizing Table

| Complexity Score | File Overlap | Recommended Approach |
|---|---|---|
| < 4 | Any | Single session (no team) |
| 4-6 | < 40% | 1-2 subagents OR 1 teammate |
| 7-14 | < 20% | 2-3 teammates |
| 15-24 | < 20% | 3-4 teammates |
| 25+ | < 10% | 4-5 teammates (rare cases only) |

**Practical cap: 5 teammates.** Beyond this, coordination overhead and conflict risk outweigh marginal speedup gains. The efficiency per agent drops as team size grows:

| Team Size | Expected Speedup | Efficiency per Agent | Token Cost Multiple |
|---|---|---|---|
| 1 (baseline) | 1.0x | 100% | 1x |
| 2 agents | ~1.7x | 85% | 2x |
| 3 agents | ~2.3x | 77% | 3x |
| 4 agents | ~2.8x | 70% | 4x |
| 5 agents | ~3.2x | 64% | 5x |

**Sweet spot: 2-3 agents** for most team-worthy tasks. This delivers the best ratio of speedup to cost. 4-5 agents are justified only for large monorepo or multi-service work with high task independence.

### Research vs. Implementation: Different Configurations

| Dimension | Research/Review Tasks | Implementation Tasks |
|---|---|---|
| Recommended team size | 3-5 agents | 2-3 agents |
| Task assignment | Self-claiming | Lead-assigned |
| Plan approval | Not needed | Required |
| File overlap tolerance | High (read-only) | Must be < 20% |
| Conflict risk | Near zero | Moderate to high |
| Example use cases | Code exploration, doc review, codebase audit, competitive analysis | Multi-module features, refactors, migrations |

---

## 3. Task Design: How to Structure Tasks for Maximum Efficiency

### The Central Insight

**Task decomposition quality is the single most important variable determining team success.** Every failure mode — file conflicts, coordination overhead, wasted work — is primarily a function of how well tasks are decomposed, not how many agents you use.

### Task Granularity

**Target: 5-6 tasks per teammate, each taking 2-5 minutes.** This sweet spot:
- Maximizes parallelism (more tasks = more concurrent work)
- Creates natural checkpoints (failures are cheap to redo)
- Enables clear acceptance criteria per task
- Reduces blast radius of any single wrong-direction task

### Task Decomposition Checklist

Before creating tasks for your team, verify each task has:

- [ ] **Explicit file ownership** — List the specific files this agent will create or modify. No file should appear in two agents' task lists.
- [ ] **Clear acceptance criteria** — What does "done" look like? Be specific.
- [ ] **Proper dependencies** — Use `blockedBy` and `blocks` to encode the dependency graph.
- [ ] **Sufficient context** — Include relevant file paths, function names, interface definitions.
- [ ] **No hidden coupling** — If you are unsure whether two tasks are independent, they probably are not. Make them sequential.

### Task Assignment: The Hybrid Model

- **Lead assigns** implementation tasks on the critical path (~30-50% of tasks)
- **Agents self-claim** research tasks, follow-up work, review tasks, and independent leaf tasks
- **Rule of thumb**: Lead assigns the critical and structural ones; agents self-claim the rest.

### Plan Approval: When to Require It

Use `planModeRequired: true` for:
- All implementation teammates
- High-blast-radius tasks (architectural decisions, shared interfaces)
- Unfamiliar codebases where wrong directions are expensive

Skip plan approval for:
- Research-only teammates (read-only, no file conflicts possible)
- Well-scoped tasks with unambiguous acceptance criteria

---

## 4. Display Mode: When to Use In-Process vs. Split-Pane

| Team Size | Recommended Mode | Rationale |
|---|---|---|
| 1-3 agents | **In-process** | Simpler setup, fewer failure modes, sufficient visibility |
| 4-5 agents | **Split-pane (tmux/iTerm2)** | Real-time visibility into all agents; catch issues early |

Launch with split-pane mode: `claude --teammate-mode tmux`

**For headless/CI environments**: Always use in-process mode.

---

## 5. Launch Checklist: Before Spinning Up a Team

### Pre-Launch

- [ ] Calculated complexity score (I x D >= 7 for teams to be worthwhile)
- [ ] Verified file independence (< 20% file overlap for implementation)
- [ ] Created all tasks with explicit file ownership, acceptance criteria, and dependency graphs
- [ ] Identified shared interfaces/types — create these FIRST in a blocking task
- [ ] Chosen team size based on the sizing table (default: 2-3)
- [ ] Set plan approval appropriately (on for implementation, off for research)
- [ ] Chosen display mode (in-process for 1-3, split-pane for 4+)

### At Launch

- [ ] Verify all agents have joined before creating tasks
- [ ] Assign initial critical-path tasks to specific agents
- [ ] Leave independent leaf tasks unassigned for self-claiming

### During Execution

- [ ] Monitor task completion via TaskList periodically
- [ ] Watch for blocked agents — check dependencies or redirect
- [ ] Review plans promptly — you are the bottleneck
- [ ] Intervene early if an agent is going in the wrong direction

### Post-Completion

- [ ] Review all changes across agents for consistency
- [ ] Run integration tests — individual tasks may pass but fail together
- [ ] Check for silent conflicts — verify no file was modified by multiple agents

---

## 6. Common Pitfalls: What to Avoid

### Pitfall 1: Silent Overwrite
Two agents edit the same file. The second write overwrites the first agent's changes entirely.
**Prevention**: Enforce zero file overlap. List explicit file ownership in every task.

### Pitfall 2: Stale Context Cascade
Agent A refactors a module. Agent B reads the pre-refactor version and produces code against outdated interfaces.
**Prevention**: Use dependency graphs (blockedBy) so downstream agents only start after upstream changes complete.

### Pitfall 3: Idle Token Burn
Lead creates tasks with dependencies. Agents spin up but are immediately blocked, wasting tokens polling and "preparing."
**Prevention**: Only spin up agents for currently unblocked tasks. Launch additional agents as dependencies resolve.

### Pitfall 4: The Decomposition Trap
Mid-execution, an agent discovers two "independent" tasks are actually tightly coupled.
**Prevention**: When uncertain about independence, err toward sequential. Plan approval catches coupling issues early.

### Pitfall 5: The Runaway Agent
Without plan approval, an agent misinterprets its task and makes sweeping wrong changes.
**Prevention**: Enable `planModeRequired: true` for implementation agents. Review plans before execution.

### Pitfall 6: Over-Decomposition
Too many tiny tasks (20+). Task management overhead exceeds parallelism benefit.
**Prevention**: Target 5-6 tasks per agent. If total tasks exceed 6x team size, consolidate.

### Pitfall 7: Ignoring the Decomposition Cost
15-20 minutes decomposing a 30-minute task barely breaks even.
**Prevention**: Only invest in team decomposition for tasks >20 minutes solo.

---

## 7. Example Prompts: Ready-to-Use Templates

### Template 1: Full-Stack Feature (3 agents, implementation)

```
Create a team with 3 agents for parallel implementation:

Agent 1 — Frontend:
- Files: src/components/[Feature].tsx, src/components/[Feature]Card.tsx
- Task: Build the React component with [requirements]

Agent 2 — Backend:
- Files: src/api/routes/[feature].ts, src/services/[feature]Service.ts
- Task: Implement the API endpoint and service layer

Agent 3 — Tests (blocked by Agent 1 and 2):
- Files: src/tests/[feature].test.ts, src/tests/[feature]Service.test.ts
- Task: Write unit and integration tests

Use planModeRequired for all agents. In-process display mode.
Each agent owns ONLY its listed files — zero overlap.
```

### Template 2: Codebase Research/Exploration (4 agents, research)

```
Create a team of 4 research agents. No plan approval needed — read-only tasks.

Agent 1: Investigate the authentication flow
Agent 2: Map the database schema and ORM models
Agent 3: Audit the API layer — endpoints, middleware, error handling
Agent 4: Review the test suite — coverage gaps and CI configuration

Each agent produces a summary. Agents can self-claim tasks. In-process mode.
```

### Template 3: Large Refactor (4 agents, implementation)

```
Create a team of 4 agents for parallel refactoring:

Agent 1: Refactor [Module A] — files: [list]
Agent 2: Refactor [Module B] — files: [list]
Agent 3: Refactor [Module C] — files: [list]
Agent 4: Update all tests and docs (blocked by Agents 1-3)

planModeRequired: true. Shared types created FIRST by Agent 1.
Use tmux split-pane display for visibility.
```

### Template 4: Quick Parallel Tasks (2 agents, mixed)

```
Agent 1: [Task A] — files: [list]
Agent 2: [Task B] — files: [list]

Zero file overlap, no dependencies. planModeRequired: true. In-process mode.
```

---

## 8. Shutdown Protocol

**IMPORTANT: NEVER shut down agents without asking the user first.** The user may want agents to keep debating, iterating, or exploring further. When the team's initial task appears complete:

1. **Report findings/status to the user** — summarize what agents have produced so far
2. **Ask the user explicitly**: "Would you like the agents to continue, or should I shut them down?"
3. **Only send shutdown requests after user confirms** they want to end the session
4. If the user wants agents to keep going, give them new directions or let them continue their current work

This applies to all team types — debate teams, implementation teams, and research teams. The lead should never unilaterally decide the team is done.

---

## Summary of Key Principles

1. **Start simple, escalate when justified.** Default is single session. Use complexity score (I x D >= 7) and file overlap check (< 20%).
2. **Task decomposition quality is the master variable.** Invest in clear file boundaries, explicit dependencies, and unambiguous acceptance criteria.
3. **Size your team to the task, not your ambition.** 2-3 agents is the sweet spot. 4-5 for large, highly independent workloads. Never more than 5.
4. **Treat research and implementation differently.** Research teams can be larger and looser. Implementation teams must be smaller and tighter.
5. **Use plan approval for implementation, not research.** Prevents the costliest failure modes at minimal latency cost.
6. **Enforce zero file overlap for implementation teams.** The single most important rule.
7. **Monitor actively, intervene early.** Review plans promptly, unblock stuck agents, catch wrong-direction work before it burns tokens.
