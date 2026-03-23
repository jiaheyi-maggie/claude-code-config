#!/bin/bash
# PostToolUse hook: Audit edited files for forgotten debug statements
# Fires after Write/Edit tools — warns if console.log, print(), debugger, etc. are present

set -euo pipefail

# Only run on file write/edit events
EVENT=$(echo "$CLAUDE_TOOL_USE_INPUT" 2>/dev/null | head -c 5000)
FILE_PATH=""

# Extract file path from tool input
if echo "$EVENT" | grep -q '"file_path"'; then
    FILE_PATH=$(echo "$EVENT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
fi

[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

# Skip non-code files
case "$FILE_PATH" in
    *.md|*.txt|*.json|*.yaml|*.yml|*.toml|*.csv|*.html|*.css|*.svg|*.lock) exit 0 ;;
esac

# Check for debug statements
WARNINGS=""

if grep -n 'console\.log\b' "$FILE_PATH" 2>/dev/null | head -5 | grep -q .; then
    MATCHES=$(grep -nc 'console\.log\b' "$FILE_PATH" 2>/dev/null || true)
    WARNINGS="${WARNINGS}⚠ ${MATCHES} console.log statement(s) found in $(basename "$FILE_PATH")\n"
fi

if grep -n '^\s*debugger\b' "$FILE_PATH" 2>/dev/null | head -5 | grep -q .; then
    WARNINGS="${WARNINGS}⚠ debugger statement found in $(basename "$FILE_PATH")\n"
fi

if grep -n '^\s*print(' "$FILE_PATH" 2>/dev/null | head -5 | grep -q .; then
    case "$FILE_PATH" in
        *.py)
            MATCHES=$(grep -nc '^\s*print(' "$FILE_PATH" 2>/dev/null || true)
            WARNINGS="${WARNINGS}⚠ ${MATCHES} print() statement(s) found in $(basename "$FILE_PATH") — use structlog/logging instead\n"
            ;;
    esac
fi

if grep -n 'TODO\|FIXME\|HACK\|XXX' "$FILE_PATH" 2>/dev/null | head -5 | grep -q .; then
    MATCHES=$(grep -nc 'TODO\|FIXME\|HACK\|XXX' "$FILE_PATH" 2>/dev/null || true)
    WARNINGS="${WARNINGS}⚠ ${MATCHES} TODO/FIXME/HACK/XXX comment(s) in $(basename "$FILE_PATH")\n"
fi

if [ -n "$WARNINGS" ]; then
    echo -e "Debug statement audit:\n${WARNINGS}Remove before committing."
fi

exit 0
