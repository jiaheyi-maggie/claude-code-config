#!/bin/bash
# Notification hook: macOS desktop notification with Claude icon.
input=$(cat)
MESSAGE=$(echo "$input" | jq -r '.message // "Claude Code needs attention"')
TYPE=$(echo "$input" | jq -r '.notification_type // "unknown"')

TITLE="Claude Code"
SUBTITLE=""
case "$TYPE" in
    permission_prompt) SUBTITLE="Permission Needed" ;;
    idle_prompt) SUBTITLE="Waiting for Input" ;;
esac

# Use native Swift app (shows Claude icon)
CLAUDE_NOTIFY="$HOME/Applications/Notifiers/ClaudeNotify.app/Contents/MacOS/ClaudeNotify"
if [ -x "$CLAUDE_NOTIFY" ]; then
    "$CLAUDE_NOTIFY" "$TITLE" "$SUBTITLE" "$MESSAGE" 2>/dev/null
elif command -v terminal-notifier &>/dev/null; then
    # Fallback to terminal-notifier
    terminal-notifier -title "$TITLE" -message "$MESSAGE" -group "claude-code-$TYPE" -sound default -activate dev.commandline.waveterm 2>/dev/null
else
    osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\"" 2>/dev/null
fi
exit 0
