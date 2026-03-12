#!/bin/bash
# Notification hook: macOS desktop notification
input=$(cat)
MESSAGE=$(echo "$input" | jq -r '.message // "Claude Code needs attention"')
TYPE=$(echo "$input" | jq -r '.notification_type // "unknown"')

TITLE="Claude Code"
case "$TYPE" in
    permission_prompt) TITLE="Claude Code - Permission Needed" ;;
    idle_prompt) TITLE="Claude Code - Waiting for Input" ;;
esac

osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\"" 2>/dev/null
exit 0
