#!/bin/bash
# PreToolUse hook: Block dev servers outside tmux
# Ensures dev servers run in tmux so logs are accessible and processes don't get orphaned

set -euo pipefail

COMMAND=$(echo "$CLAUDE_TOOL_USE_INPUT" 2>/dev/null | head -c 5000)

# Only check Bash tool commands
[ -z "$COMMAND" ] && exit 0

# Dev server patterns
DEV_SERVER_PATTERNS="npm run dev|npm start|npx next dev|npx vite|npx remix dev|yarn dev|pnpm dev|uvicorn|gunicorn|flask run|python.*manage.py runserver|python.*-m http.server|cargo run.*--release|go run.*main.go"

if echo "$COMMAND" | grep -qE "$DEV_SERVER_PATTERNS"; then
    # Allow if already in tmux
    if [ -n "${TMUX:-}" ]; then
        exit 0
    fi

    # Allow if command includes & (backgrounded) or timeout
    if echo "$COMMAND" | grep -qE '&$|timeout |--timeout'; then
        exit 0
    fi

    echo "WARNING: Starting a dev server outside tmux. The server will block this session and logs may be lost. Consider running in tmux or backgrounding with &."
fi

exit 0
