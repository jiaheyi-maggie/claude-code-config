#!/bin/bash
# Notification hook: macOS desktop notification via terminal-notifier
# Sends clickable native notifications that focus the terminal on click.
input=$(cat)
MESSAGE=$(echo "$input" | jq -r '.message // "Claude Code needs attention"')
TYPE=$(echo "$input" | jq -r '.notification_type // "unknown"')

TITLE="Claude Code"
SUBTITLE=""
case "$TYPE" in
    permission_prompt) SUBTITLE="Permission Needed" ;;
    idle_prompt) SUBTITLE="Waiting for Input" ;;
esac

# Prefer terminal-notifier (clickable, custom icon, grouped)
if command -v terminal-notifier &>/dev/null; then
    ARGS=(
        -title "$TITLE"
        -message "$MESSAGE"
        -group "claude-code-$TYPE"
        -sound default
        -activate com.apple.Terminal
    )
    [ -n "$SUBTITLE" ] && ARGS+=(-subtitle "$SUBTITLE")

    # Use Claude icon if available
    ICON="$HOME/.claude/icon.png"
    [ -f "$ICON" ] && ARGS+=(-appIcon "$ICON")

    terminal-notifier "${ARGS[@]}" 2>/dev/null
else
    # Fallback to osascript
    osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\"" 2>/dev/null
fi
exit 0
