#!/bin/bash
# PreCompact hook: Save structured state before context compaction
# Generates a summary template that Claude reads post-compaction to restore context
# Based on Anthropic's compaction cookbook — structured summaries preserve critical info

set -euo pipefail

CLAUDE_DIR=".claude"
STATE_FILE="$CLAUDE_DIR/pre-compact-state.md"

mkdir -p "$CLAUDE_DIR"

{
    echo "<compaction-state>"
    echo "# Pre-Compaction State"
    echo "> Saved: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "> IMPORTANT: Read this file in full after compaction to restore working context."
    echo ""

    # === Section 1: Task Overview ===
    echo "## 1. Task Overview"
    echo ""
    echo "<!-- Claude: Fill this section from your current context before compaction completes -->"
    echo "<!-- What is the user trying to accomplish? One sentence. -->"
    echo "<!-- What phase are we in? (ideation / planning / building / debugging / reviewing / shipping) -->"
    echo ""

    # === Section 2: Current State ===
    echo "## 2. Current State"
    echo ""

    # Git state (factual, captured by script)
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        BRANCH=$(git branch --show-current 2>/dev/null || echo 'detached')
        echo "### Git"
        echo '```'
        echo "Branch: $BRANCH"
        echo ""

        # Recent commits (what was just done)
        echo "Recent commits:"
        git log --oneline -5 2>/dev/null || true
        echo ""

        # What's changed (work in progress)
        MODIFIED=$(git diff --name-only 2>/dev/null || true)
        STAGED=$(git diff --cached --name-only 2>/dev/null || true)
        UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | head -10 || true)

        if [ -n "$MODIFIED" ]; then
            echo "Modified (unstaged):"
            echo "$MODIFIED"
            echo ""
        fi

        if [ -n "$STAGED" ]; then
            echo "Staged:"
            echo "$STAGED"
            echo ""
        fi

        if [ -n "$UNTRACKED" ]; then
            echo "Untracked (new files):"
            echo "$UNTRACKED"
            echo ""
        fi
        echo '```'
        echo ""
    fi

    # === Section 3: Files That Matter ===
    echo "## 3. Files That Matter"
    echo ""
    echo "<!-- These are the files most recently touched — re-read them after compaction -->"
    echo ""

    # Last 5 files modified by timestamp
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "### Recently modified files (by git)"
        echo '```'
        git diff --name-only HEAD~3 HEAD 2>/dev/null | head -10 || true
        echo '```'
        echo ""
    fi

    # Files currently in the diff (actively being worked on)
    if [ -n "${MODIFIED:-}" ] || [ -n "${STAGED:-}" ]; then
        echo "### Actively being worked on"
        echo '```'
        echo "${MODIFIED:-}" | head -10
        echo "${STAGED:-}" | head -10
        echo '```'
        echo ""
    fi

    # === Section 4: Decisions Made ===
    echo "## 4. Decisions Made"
    echo ""
    echo "<!-- Claude: Before compaction, list the key decisions made in this session -->"
    echo "<!-- Format: DECISION: [what] — REASON: [why] -->"
    echo "<!-- These are the hardest things to reconstruct from code alone -->"
    echo ""

    # === Section 5: What Remains ===
    echo "## 5. What Remains"
    echo ""
    echo "<!-- Claude: What still needs to be done? Be specific. -->"
    echo "<!-- Format: [ ] task description — in [file] -->"
    echo ""

    # === Section 6: Important Discoveries ===
    echo "## 6. Important Discoveries"
    echo ""
    echo "<!-- Claude: Anything surprising found during this session? -->"
    echo "<!-- Bugs found, performance issues, architectural concerns, gotchas -->"
    echo ""

    # === Section 7: Test Results ===
    echo "## 7. Test Results"
    echo ""
    # Try to find last test run results
    if [ -f "test-results.xml" ] || [ -f "coverage/lcov.info" ]; then
        echo "Test artifacts found — re-run tests after compaction to verify state."
    fi
    echo "<!-- Claude: Record pass/fail counts and any failing test names -->"
    echo ""

    # === Section 8: Bug Tracking ===
    if [ -f "$CLAUDE_DIR/bugs.md" ]; then
        echo "## 8. Active Bugs"
        echo ""
        # Get the last 2 bug entries (most recent context)
        echo '```'
        tail -30 "$CLAUDE_DIR/bugs.md" 2>/dev/null || true
        echo '```'
        echo ""
    fi

    # === Section 9: Eval State ===
    if [ -d "$CLAUDE_DIR/evals" ]; then
        echo "## 9. Eval State"
        echo ""
        echo '```'
        for eval_file in "$CLAUDE_DIR"/evals/*.md; do
            [ -e "$eval_file" ] || continue
            NAME=$(basename "$eval_file" .md)
            RESULT=$(grep -m1 "^## Result" "$eval_file" 2>/dev/null | head -1 || echo "NOT RUN")
            echo "  $NAME: $RESULT"
        done
        echo '```'
        echo ""
    fi

    # === Section 10: Checkpoint State ===
    if [ -d "$CLAUDE_DIR/checkpoints" ]; then
        echo "## 10. Checkpoints"
        echo ""
        echo '```'
        for cp_file in "$CLAUDE_DIR"/checkpoints/*.md; do
            [ -e "$cp_file" ] || continue
            NAME=$(basename "$cp_file" .md)
            CREATED=$(grep -m1 "Created:" "$cp_file" 2>/dev/null || echo "unknown")
            echo "  $NAME — $CREATED"
        done
        echo '```'
        echo ""
    fi

    # === Section 11: Handover Context ===
    if [ -f "$CLAUDE_DIR/handover.md" ]; then
        echo "## 11. Last Handover (first 40 lines)"
        echo ""
        echo '```'
        head -40 "$CLAUDE_DIR/handover.md" 2>/dev/null || true
        echo '```'
        echo ""
    fi

    echo "## Recovery Instructions"
    echo ""
    echo "After compaction, Claude should:"
    echo "1. Read this file in full"
    echo "2. Re-read every file listed in Section 3 (Files That Matter)"
    echo "3. Resume work from Section 5 (What Remains)"
    echo "4. Do NOT re-do any work listed in Section 2 (git commits) or Section 4 (Decisions Made)"
    echo "5. If tests were passing before compaction (Section 7), verify they still pass"
    echo "</compaction-state>"

} > "$STATE_FILE"

echo "Structured state saved to $STATE_FILE before compaction"
exit 0
