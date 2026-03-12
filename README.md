# claude-code-config

Personal Claude Code configuration — commands, hooks, settings, and global instructions. Designed to be cloned and installed on any machine for a consistent Claude Code experience.

## What's Included

### Commands (`commands/`)
Custom slash commands available in every Claude Code session.

| Command | Purpose |
|---|---|
| `/generate-prompt` | Expands a rough prompt into a structured, engineering-focused prompt with requirements, edge cases, and acceptance criteria |
| `/handover` | Saves session state to a file that auto-loads in the next session, plus persists durable lessons to memory |
| `/launch-multiagent-team` | Decision framework and templates for when/how to use multi-agent teams |

### Hooks (`hooks/`)
Shell scripts triggered by Claude Code events.

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
Loaded automatically in every session. Covers:
- Product & design thinking standards
- Engineering standards and milestone verification
- Coding patterns and pitfalls (TS, React, Python, C)
- Security checklist
- Communication preferences

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
