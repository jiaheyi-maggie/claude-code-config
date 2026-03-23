#!/bin/bash
# PreCompact hook: Save important state before context compaction
# Preserves working context that would otherwise be lost during auto-compact

set -euo pipefail

CLAUDE_DIR=".claude"
STATE_FILE="$CLAUDE_DIR/pre-compact-state.md"

mkdir -p "$CLAUDE_DIR"

# Collect current state
{
    echo "# Pre-Compaction State"
    echo "> Saved: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""

    # Git state
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "## Git State"
        echo '```'
        echo "Branch: $(git branch --show-current 2>/dev/null || echo 'detached')"
        echo ""
        echo "Recent commits:"
        git log --oneline -5 2>/dev/null || true
        echo ""
        echo "Modified files:"
        git diff --name-only 2>/dev/null || true
        echo ""
        echo "Staged files:"
        git diff --cached --name-only 2>/dev/null || true
        echo '```'
        echo ""
    fi

    # Bug tracking state
    if [ -f "$CLAUDE_DIR/bugs.md" ]; then
        echo "## Active Bugs"
        echo '```'
        # Get the last bug entry
        tail -20 "$CLAUDE_DIR/bugs.md" 2>/dev/null || true
        echo '```'
        echo ""
    fi

    # Task state from any task files
    if [ -f "$CLAUDE_DIR/tasks.md" ]; then
        echo "## Tasks"
        echo '```'
        cat "$CLAUDE_DIR/tasks.md" 2>/dev/null || true
        echo '```'
        echo ""
    fi

    # Handover state
    if [ -f "$CLAUDE_DIR/handover.md" ]; then
        echo "## Last Handover (summary)"
        echo '```'
        head -30 "$CLAUDE_DIR/handover.md" 2>/dev/null || true
        echo '```'
        echo ""
    fi

    echo "## Instruction"
    echo "This file was auto-saved before context compaction. Read it to restore working context."

} > "$STATE_FILE"

echo "State saved to $STATE_FILE before compaction"
exit 0
