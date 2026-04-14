# claude-code-config

Personal Claude Code configuration — commands, hooks, agents, skills, rules, settings, and global instructions. Designed to be cloned and installed on any machine for a consistent Claude Code experience.

**[Interactive Ecosystem Map](docs/claude-ecosystem.html)** — open in any browser to see every command, agent, skill, hook, and MCP server with a development pipeline view and decision tree.

```bash
open docs/claude-ecosystem.html
```

## The Pipeline

These commands map a complete product development workflow:

```
/ideate              Think divergently, stress-test the idea (greenfield)
/explore-feature     Explore a feature within an existing project (scoped)
    ↓
/create-prd          Lock requirements into a PRD
    ↓
/architect           Review system design before writing code
    ↓
/recon <feature>     Deep pre-build investigation — dispatch research agents
    ↓
/prime               Load project context at session start
    ↓
/tdd                 Build with strict Red-Green-Refactor
    ↓
/bugfix <desc>       Fix bugs with mandatory repro + verification
    ↓
/review-feature      Three-pass review (bugs, logic, product alignment)
    ↓
/security-audit      OWASP Top 10 audit
    ↓
/pre-ship            Final quality gate — 7 gates, all must pass
    ↓
/handover            Save session state for next session

Full pipeline (one command):
/ship <feature>      Architect → plan → build → review → QA → pre-ship

Session utilities (use anytime):
/tbc                 Bookmark before stepping away
/catch-up            Summarize what you missed since /tbc
/summarize <topic>   Search past sessions for a topic
/route               Get an instant recommendation for your current task
```

## What's Included

### Commands (`commands/`)

| Command | Phase | Purpose |
|---|---|---|
| `/ideate` | Ideation | Creative exploration — challenges assumptions, proposes pivots, shapes the MVP (greenfield) |
| `/explore-feature <desc>` | Ideation | Scoped feature exploration within an existing project — reads codebase, maps against existing architecture, proposes approach |
| `/create-prd` | Planning | Generates a full PRD with features, acceptance criteria, risks, and launch plan |
| `/architect` | Design | Four-pillar architecture review (components, data, failure modes, security) |
| `/recon <feature>` | Investigation | Deep pre-build reconnaissance — dispatches research agents to investigate the codebase before committing to build |
| `/prime` | Context | Loads project structure, key files, and git state before starting work |
| `/tdd` | Building | Strict Red-Green-Refactor cycle with test quality checklist |
| `/generate-prompt` | Building | Expands a rough prompt into structured engineering requirements |
| `/search-first <need>` | Building | Search npm/PyPI/GitHub/MCP before building anything custom. Scores candidates, recommends adopt/wrap/reference/build |
| `/eval <action>` | Quality | Eval-driven development — define success criteria before building, run evals continuously, track regressions |
| `/checkpoint <action>` | Quality | Save/restore known-good states during development. Create, list, restore, verify, diff |
| `/bugfix <description>` | Debugging | Strict 5-phase bug fix protocol with mandatory reproduction, verification, and attempt tracking in `.claude/bugs.md` |
| `/review-feature` | Review | Three-pass post-implementation review (bugs, logic, product alignment) |
| `/security-audit` | Review | Comprehensive OWASP Top 10 security audit with auto-fix |
| `/pre-ship` | Shipping | Seven quality gates — build, semantics, edge cases, security, performance, DX, product alignment |
| `/ship <feature>` | Orchestration | Full pipeline for a single feature: architect → plan → build → review → QA → pre-ship |
| `/build-features <list>` | Orchestration | Takes a feature list, builds dependency DAG, designs shared contracts, then coordinates parallel agents through build-review cycles |
| `/launch-multiagent-team` | Workflow | Decision framework for when/how to use multi-agent teams |
| `/evolve` | Learning | Analyze development patterns from observations, create/manage instincts (learned behaviors with confidence scores) |
| `/handover` | Session mgmt | Saves session state to auto-loading file + persists lessons to memory |
| `/tbc` | Session mgmt | Drops a bookmark in the current conversation — pair with `/catch-up` |
| `/catch-up` | Session mgmt | Summarizes everything since the last `/tbc` bookmark |
| `/summarize <topic>` | Session mgmt | Searches past conversation logs for a topic and produces a detailed summary |

### Agents (`agents/`)

| Agent | Model | Purpose |
|---|---|---|
| `senior-engineer` | Opus | Principal software engineer — architecture decisions, complex implementations, performance optimization. Backed by `agents/knowledge/engineering-kb.md` |
| `code-reviewer` | Opus | 4-pass code review — bugs, logic, engineering quality, product alignment. Auto-spawned after big features |
| `chief-architect` | Opus | Master orchestrator for complex multi-faceted projects. Coordinates specialist agents for cross-domain work (frontend + backend + devops) |
| `product-manager` | Opus | Senior PM — owns "what" and "why." Ideation, requirements, prioritization, or challenging whether something should be built |
| `frontend-engineer` | Opus | Staff frontend — React/Next.js, component architecture, responsive design, performance, accessibility |
| `ux-engineer` | Opus | UX/UI design — user flows, interaction patterns, visual systems, wireframing, interface critique |
| `ai-engineer` | Opus | Staff AI engineer — models, agent architectures, MCP, RAG, evals, AI UX, competitive landscape. Backed by `agents/knowledge/ai-engineering-kb-2026.md` |
| `debugger` | Opus | Systematic deep debugger — reads full project context, builds mental model, traces exact logic chain. Never guesses |
| `systems-debugger` | Opus | Low-level systems specialist — C, memory issues, crashes, performance. Uses sanitizers, valgrind, lldb |
| `qa-engineer` | Opus | Post-implementation QA — verifies against requirements, finds and fixes bugs, iterates until solid |
| `test-writer` | Opus | Test generation specialist — writes comprehensive tests (pytest/vitest/jest) for existing code |
| `tech-writer` | Sonnet | Technical writer — API docs, ADRs, changelogs, onboarding guides, READMEs |
| `ui-mockup` | Opus | Generates interactive HTML mockups with all states (empty/loading/populated/error), then produces implementation specs |
| `pitch-deck` | Opus | Builds polished interactive HTML pitch decks from codebase understanding |
| `brand-strategist` | Opus | Brand/marketing strategist — pitch decks, one-pagers, exec summaries, landing page copy, investor memos |
| `visionary` | Opus | Visionary CTO / product futurist — brainstorming, challenging assumptions, moonshot thinking |

### Skills (`skills/`)

| Skill | Purpose |
|---|---|
| `/route` | Decision router — tells you exactly which command, agent, or skill to use for your current task |

### Hooks (`hooks/`)

| Hook | Event | Purpose |
|---|---|---|
| `block-dangerous.sh` | PreToolUse (Bash) | Blocks `rm -rf /`, force push, `sudo`, hard reset |
| `block-dev-server.sh` | PreToolUse (Bash) | Warns about dev servers started outside tmux |
| `protect-configs.sh` | PreToolUse (Write/Edit) | Blocks modifications to linter/formatter configs |
| `collect-edited-files.sh` | PostToolUse (Write/Edit) | Accumulates edited file paths for batch processing |
| `batch-format-lint.sh` | Stop | Batch-formats and lints all files edited during a response (runs once instead of per-edit) |
| `format-python.sh` | PostToolUse (Write/Edit) | Auto-formats `.py` files with `black` |
| `format-c.sh` | PostToolUse (Write/Edit) | Auto-formats C/C++ files with `clang-format` |
| `plankton-quality.sh` | PostToolUse (Write/Edit) | Runs language-appropriate linters (eslint, tsc, ruff, mypy, bandit, shellcheck) on every file edit |
| `audit-debug-statements.sh` | PostToolUse (Write/Edit) | Warns about `console.log`, `debugger`, `print()`, TODO/FIXME |
| `observe-patterns.sh` | PostToolUse | Captures tool usage patterns to `.claude/observations.jsonl` for `/evolve` |
| `audit-config.sh` | ConfigChange | Logs config changes to `~/claude-config-audit.log` |
| `notify-macos.sh` | Notification | macOS desktop notifications when Claude needs attention |
| `pre-compact-save.sh` | PreCompact | Saves git state, bugs, tasks, and handover to `.claude/pre-compact-state.md` |
| `reinject-context.sh` | SessionStart (compact) | Re-injects git state after context compaction |
| `statusline.sh` | StatusLine | Shows model, context usage bar, and session cost |

### Rules (`rules/`)

Language-specific and cross-cutting rules loaded automatically via the rules system:

| Rule File | Scope |
|---|---|
| `c/patterns.md` | C11 standards, memory safety, naming conventions |
| `python/patterns.md` | Type hints, pathlib, pytest, structlog, ruff |
| `typescript/patterns.md` | Strict typing, Buffer handling, async generators |
| `typescript/react-nextjs.md` | Server Components, auth flows, accessibility, mobile-first |
| `common/error-handling.md` | No broad try/catch, Promise.allSettled, delete mirrors create |
| `common/git-workflow.md` | Conventional commits, atomic changes, never commit secrets |
| `common/security.md` | SQL parameterization, redirect validation, PII protection |
| `common/testing.md` | Behavior tests, real DBs, coverage targets, regression tests |

### Global Instructions (`CLAUDE.md`)

Loaded automatically in every session. Encodes Distinguished Engineer / Technical Fellow level coding principles:
- Product & design thinking (PMF lens, long-term architecture)
- DE-level engineering standards (failure-first thinking, deep modules, second-order reasoning, boring technology)
- Coding patterns and pitfalls (TS, React, Python, C)
- Post-implementation review, milestone verification, and bug fixing protocols
- Compaction recovery and proactive learning
- Security checklist and communication preferences

### Dotfiles (`dotfiles/`)

| File | Purpose |
|---|---|
| `starship.toml` | Starship prompt configuration |
| `ssh-config` | SSH configuration template |

### Notifier (`notifier/`)

Google Calendar/Gmail notification service built with Bun. Sends macOS native notifications for upcoming events and important emails. Includes a LaunchAgent plist for auto-start.

### Settings Reference (`settings.reference.json`)

Reference configuration for hooks wiring, env vars, and status line. Not installed automatically on machines that already have `settings.json` — merge manually.

## Installation

```bash
git clone git@github.com:jiaheyi-maggie/claude-code-config.git ~/claude-code-config
cd ~/claude-code-config
chmod +x install.sh
./install.sh
```

The installer:
- Symlinks commands, hooks, agents, skills, and CLAUDE.md into `~/.claude/`
- Backs up any existing files before overwriting
- Skips `settings.json` if it already exists (prints merge instructions instead)

### Updating
```bash
cd ~/claude-code-config
git pull
# Symlinks update automatically — no re-install needed
```

### Adding a New Command
1. Create `commands/my-command.md` in this repo
2. Run `./install.sh` (or manually symlink)
3. Use `/my-command` in any Claude Code session
4. Commit and push so other machines get it on `git pull`

## Prerequisites
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- `gh` CLI authenticated (for pushing)
- `black` (for Python formatting hook)
- `clang-format` (for C/C++ formatting hook)
