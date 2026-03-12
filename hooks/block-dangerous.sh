#!/bin/bash
# PreToolUse hook: block dangerous Bash commands
input=$(cat)
COMMAND=$(echo "$input" | jq -r '.tool_input.command // empty')

# Block rm -rf on root or home
if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*f[a-zA-Z]*\s+)*(\/|\/\*|~\/\*|~)\s*$'; then
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Blocked: destructive rm on root or home directory"}}'
    exit 0
fi

# Block force push
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*(-f|--force)\b'; then
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Blocked: force push not allowed. Use --force-with-lease if needed."}}'
    exit 0
fi

# Block hard reset
if echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard'; then
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"Warning: git reset --hard will discard uncommitted changes."}}'
    exit 0
fi

# Block sudo
if echo "$COMMAND" | grep -qE '^\s*sudo\s'; then
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Blocked: sudo not allowed in Claude Code sessions"}}'
    exit 0
fi

exit 0
