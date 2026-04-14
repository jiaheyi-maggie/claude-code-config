#!/bin/bash
# PostToolUse hook: Accumulate edited file paths for batch processing at Stop.
# Instead of formatting/linting after every Edit, we collect paths and process once.
input=$(cat)
FILE_PATH=$(echo "$input" | jq -r '.tool_input.file_path // empty')

[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

# Append to session-specific temp file (deduped at batch time)
BATCH_FILE="/tmp/claude-edited-files-$$"
# Fall back to parent PID if $$ doesn't persist across hook calls
[ -n "$CLAUDE_SESSION_ID" ] && BATCH_FILE="/tmp/claude-edited-files-${CLAUDE_SESSION_ID}"
[ -z "$CLAUDE_SESSION_ID" ] && BATCH_FILE="/tmp/claude-edited-files-$(ps -o ppid= -p $$ 2>/dev/null | tr -d ' ')"

echo "$FILE_PATH" >> "$BATCH_FILE"
exit 0
