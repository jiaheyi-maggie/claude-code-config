#!/bin/bash
set -euo pipefail

# Claude Code Config Installer
# Symlinks commands, hooks, and CLAUDE.md into ~/.claude/
# Safe to re-run — backs up existing files before overwriting.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
BACKUP_DIR="$CLAUDE_DIR/backup-$(date +%Y%m%d-%H%M%S)"

GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

info()  { printf "${GREEN}[ok]${RESET} %s\n" "$1"; }
warn()  { printf "${YELLOW}[skip]${RESET} %s\n" "$1"; }
err()   { printf "${RED}[error]${RESET} %s\n" "$1"; }

# Ensure ~/.claude exists
mkdir -p "$CLAUDE_DIR/commands" "$CLAUDE_DIR/hooks" "$CLAUDE_DIR/agents"

backed_up=false
backup_if_exists() {
    local target="$1"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        if [ "$backed_up" = false ]; then
            mkdir -p "$BACKUP_DIR"
            backed_up=true
        fi
        cp -a "$target" "$BACKUP_DIR/"
        info "Backed up $(basename "$target") to backup dir"
    fi
}

# --- Commands ---
echo ""
echo "=== Installing commands ==="
for cmd in "$SCRIPT_DIR"/commands/*.md; do
    name="$(basename "$cmd")"
    target="$CLAUDE_DIR/commands/$name"
    backup_if_exists "$target"
    ln -sf "$cmd" "$target"
    info "$name"
done

# --- Hooks ---
echo ""
echo "=== Installing hooks ==="
for hook in "$SCRIPT_DIR"/hooks/*.sh; do
    name="$(basename "$hook")"
    target="$CLAUDE_DIR/hooks/$name"
    backup_if_exists "$target"
    ln -sf "$hook" "$target"
    chmod +x "$hook"
    info "$name"
done

# --- Agents ---
echo ""
echo "=== Installing agents ==="
for agent in "$SCRIPT_DIR"/agents/*.md; do
    [ -e "$agent" ] || continue
    name="$(basename "$agent")"
    target="$CLAUDE_DIR/agents/$name"
    backup_if_exists "$target"
    ln -sf "$agent" "$target"
    info "$name"
done

# --- Agent knowledge base ---
if [ -d "$SCRIPT_DIR/agents/knowledge" ]; then
    mkdir -p "$CLAUDE_DIR/agents/knowledge"
    for kb in "$SCRIPT_DIR"/agents/knowledge/*.md; do
        [ -e "$kb" ] || continue
        name="$(basename "$kb")"
        target="$CLAUDE_DIR/agents/knowledge/$name"
        backup_if_exists "$target"
        ln -sf "$kb" "$target"
        info "knowledge/$name"
    done
fi

# --- Skills ---
echo ""
echo "=== Installing skills ==="
if [ -d "$SCRIPT_DIR/skills" ]; then
    for skill_dir in "$SCRIPT_DIR"/skills/*/; do
        [ -d "$skill_dir" ] || continue
        name="$(basename "$skill_dir")"
        target_dir="$CLAUDE_DIR/skills/$name"
        mkdir -p "$target_dir"
        for skill_file in "$skill_dir"*; do
            [ -e "$skill_file" ] || continue
            fname="$(basename "$skill_file")"
            target="$target_dir/$fname"
            backup_if_exists "$target"
            ln -sf "$skill_file" "$target"
        done
        info "$name"
    done
fi

# --- CLAUDE.md ---
echo ""
echo "=== Installing CLAUDE.md ==="
target="$CLAUDE_DIR/CLAUDE.md"
backup_if_exists "$target"
ln -sf "$SCRIPT_DIR/CLAUDE.md" "$target"
info "CLAUDE.md"

# --- Settings (merge guidance, not overwrite) ---
echo ""
echo "=== Settings ==="
if [ -f "$CLAUDE_DIR/settings.json" ]; then
    warn "settings.json already exists — not overwriting"
    echo "     Review settings.reference.json and manually merge:"
    echo "     - hooks config (requires hook scripts to be installed first)"
    echo "     - env vars"
    echo "     - statusLine config"
    echo ""
    echo "     Diff your current settings against the reference:"
    echo "     diff <(jq -S . $CLAUDE_DIR/settings.json) <(jq -S . $SCRIPT_DIR/settings.reference.json)"
else
    cp "$SCRIPT_DIR/settings.reference.json" "$CLAUDE_DIR/settings.json"
    info "settings.json installed (fresh install)"
fi

# --- Summary ---
echo ""
echo "=== Done ==="
if [ "$backed_up" = true ]; then
    echo "Backups saved to: $BACKUP_DIR"
fi
echo ""
echo "Installed:"
echo "  Commands: $(ls "$SCRIPT_DIR"/commands/*.md | wc -l | tr -d ' ')"
echo "  Agents:   $(ls "$SCRIPT_DIR"/agents/*.md 2>/dev/null | wc -l | tr -d ' ')"
echo "  Skills:   $(find "$SCRIPT_DIR/skills" -name 'SKILL.md' 2>/dev/null | wc -l | tr -d ' ')"
echo "  Hooks:    $(ls "$SCRIPT_DIR"/hooks/*.sh | wc -l | tr -d ' ')"
echo "  CLAUDE.md: symlinked"
echo ""
echo "To verify: claude /help  (commands should appear as slash commands)"
