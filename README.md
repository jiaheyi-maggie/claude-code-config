# claude-code-config

Personal Claude Code configuration — commands, hooks, settings, and global instructions. Designed to be cloned and installed on any machine for a consistent Claude Code experience.

## The Pipeline

These commands map to a complete product development workflow:

```
/ideate              Think divergently, stress-test the idea
    ↓
/create-prd          Lock requirements into a PRD
    ↓
/architect           Review system design before writing code
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

Session utilities (use anytime):
/tbc                 Bookmark before stepping away
/catch-up            Summarize what you missed since /tbc
/summarize <topic>   Search past sessions for a topic
```

## Interactive Ecosystem Map

See **[`docs/claude-ecosystem.html`](docs/claude-ecosystem.html)** for a full interactive chart of every command, agent, skill, hook, and MCP server — with a development pipeline view and decision tree for when to use what. Open it in any browser:

```bash
open docs/claude-ecosystem.html
```

Or use `/route` in any session to get an instant recommendation for your current task.

## What's Included

### Commands (`commands/`)

| Command | Phase | Purpose |
|---|---|---|
| `/ideate` | Ideation | Creative exploration — challenges assumptions, proposes pivots, shapes the MVP |
| `/create-prd` | Planning | Generates a full PRD with features, acceptance criteria, risks, and launch plan |
| `/architect` | Design | Four-pillar architecture review (components, data, failure modes, security) |
| `/prime` | Context | Loads project structure, key files, and git state before starting work |
| `/tdd` | Building | Strict Red-Green-Refactor cycle with test quality checklist |
| `/generate-prompt` | Building | Expands a rough prompt into structured engineering requirements |
| `/review-feature` | Review | Three-pass post-implementation review (bugs, logic, product alignment) |
| `/security-audit` | Review | Comprehensive OWASP Top 10 security audit with auto-fix |
| `/pre-ship` | Shipping | Seven quality gates — build, semantics, edge cases, security, performance, DX, product alignment |
| `/bugfix <description>` | Debugging | Strict 5-phase bug fix protocol with mandatory reproduction, verification, and attempt tracking in `.claude/bugs.md` |
| `/handover` | Session mgmt | Saves session state to auto-loading file + persists lessons to memory |
| `/launch-multiagent-team` | Workflow | Decision framework for when/how to use multi-agent teams |
| `/summarize <topic>` | Session mgmt | Searches past conversation logs for a topic and produces a detailed summary with decisions, outcomes, and open items |
| `/tbc` | Session mgmt | Drops a bookmark in the current conversation — pair with `/catch-up` when you return |
| `/catch-up` | Session mgmt | Summarizes everything that happened since the last `/tbc` bookmark — messages, files changed, decisions, current state |

### Agents (`agents/`)

| Agent | Model | Purpose |
|---|---|---|
| `senior-engineer` | Opus (latest) | Principal software engineer with deep systems knowledge. Spawn for architecture decisions, complex implementations, technology selection, performance optimization, and system design. Backed by a comprehensive knowledge base (`agents/knowledge/engineering-kb.md`). |
| `code-reviewer` | Opus (latest) | Principal engineer 4-pass code review — automatically spawned after big feature implementations. Reviews bugs, logic, engineering quality, and product alignment. |
| `product-manager` | Opus (latest) | Senior PM who owns "what" and "why." Spawn during ideation, requirements definition, feature prioritization, or to challenge whether something should be built at all. |
| `frontend-engineer` | Opus (latest) | Staff frontend engineer specializing in React/Next.js, component architecture, responsive design, performance, and accessibility. Spawn for UI implementation and state management decisions. |
| `ux-engineer` | Opus (latest) | UX/UI design engineer who thinks in user flows, interaction patterns, and visual systems. Spawn for design decisions, wireframing, design system creation, and interface critique. |
| `tech-writer` | Sonnet (latest) | Technical writer for API docs, ADRs, changelogs, onboarding guides, and READMEs. Spawn when documentation needs to be created or updated alongside code changes. |

### Skills (`skills/`)

| Skill | Purpose |
|---|---|
| `/route` | Decision router — tells you exactly which command, agent, or skill to use for your current task |

### Hooks (`hooks/`)

| Hook | Event | Purpose |
|---|---|---|
| `block-dangerous.sh` | PreToolUse (Bash) | Blocks `rm -rf /`, force push, `sudo`, hard reset |
| `format-python.sh` | PostToolUse (Write/Edit) | Auto-formats `.py` files with `black` |
| `format-c.sh` | PostToolUse (Write/Edit) | Auto-formats C/C++ files with `clang-format` |
| `notify-macos.sh` | Notification | macOS desktop notifications when Claude needs attention |
| `reinject-context.sh` | SessionStart (compact) | Re-injects git state after context compaction |
| `statusline.sh` | StatusLine | Shows model, context usage bar, and session cost |
| `audit-config.sh` | ConfigChange | Logs config changes to `~/claude-config-audit.log` |

### Global Instructions (`CLAUDE.md`)

Loaded automatically in every session. Encodes Distinguished Engineer / Technical Fellow level coding principles:
- Product & design thinking (PMF lens, long-term architecture)
- DE-level engineering standards (failure-first thinking, deep modules, second-order reasoning, boring technology)
- Coding patterns and pitfalls (TS, React, Python, C)
- Security checklist
- Communication and teaching preferences

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
- Symlinks commands, hooks, and CLAUDE.md into `~/.claude/`
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
