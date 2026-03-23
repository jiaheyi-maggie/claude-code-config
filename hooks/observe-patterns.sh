#!/bin/bash
# PostToolUse hook: Observe tool usage patterns for continuous learning
# Captures what tools are used, on what files, and what the outcome was
# Feeds into the continuous learning system (/evolve command)

set -euo pipefail

# Skip if learning is disabled
[ "${ECC_DISABLE_LEARNING:-0}" = "1" ] && exit 0

# Only observe in git repos (need project identity)
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

CLAUDE_DIR=".claude"
OBS_FILE="$CLAUDE_DIR/observations.jsonl"
mkdir -p "$CLAUDE_DIR"

# Get project identity (hash of git remote or path)
PROJECT_ID=$(git remote get-url origin 2>/dev/null | shasum -a 256 | cut -c1-12 || echo "local-$(pwd | shasum -a 256 | cut -c1-12)")

# Extract tool info
TOOL_NAME="${CLAUDE_TOOL_NAME:-unknown}"
TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

# Extract file path if present
FILE_PATH=""
EVENT=$(echo "$CLAUDE_TOOL_USE_INPUT" 2>/dev/null | head -c 2000 || true)
if echo "$EVENT" | grep -q '"file_path"'; then
    FILE_PATH=$(echo "$EVENT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
fi

# Determine file type
FILE_EXT=""
if [ -n "$FILE_PATH" ]; then
    FILE_EXT="${FILE_PATH##*.}"
fi

# Write observation (append-only, one JSON line)
# Keep it minimal to avoid bloating the file
echo "{\"ts\":\"$TIMESTAMP\",\"project\":\"$PROJECT_ID\",\"tool\":\"$TOOL_NAME\",\"ext\":\"$FILE_EXT\",\"file\":\"$(basename "$FILE_PATH" 2>/dev/null || true)\"}" >> "$OBS_FILE"

# Rotate if file gets too large (keep last 1000 observations)
if [ -f "$OBS_FILE" ]; then
    LINE_COUNT=$(wc -l < "$OBS_FILE" | tr -d ' ')
    if [ "$LINE_COUNT" -gt 2000 ]; then
        tail -1000 "$OBS_FILE" > "$OBS_FILE.tmp"
        mv "$OBS_FILE.tmp" "$OBS_FILE"
    fi
fi

exit 0
