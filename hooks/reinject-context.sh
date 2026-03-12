#!/bin/bash
# SessionStart (compact) hook: re-inject critical context after compaction
# Stdout is added to Claude's context

echo "=== Post-compaction context ==="

# Show current git state
if git rev-parse --git-dir &>/dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
    echo "Git branch: $BRANCH"
    echo "Recent commits:"
    git log --oneline -5 2>/dev/null
    echo ""
    DIFF_STAT=$(git diff --stat 2>/dev/null)
    if [ -n "$DIFF_STAT" ]; then
        echo "Uncommitted changes:"
        echo "$DIFF_STAT"
    fi
fi

echo "=== End context ==="
