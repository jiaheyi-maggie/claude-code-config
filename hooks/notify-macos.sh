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

# Prefer terminal-notifier (clickable, grouped, with icon)
if command -v terminal-notifier &>/dev/null; then
    ICON="$HOME/setup/claude-code-config/notifier/icons/claude.png"
    ARGS=(
        -title "$TITLE"
        -message "$MESSAGE"
        -group "claude-code-$TYPE"
        -sound default
        -activate dev.commandline.waveterm
    )
    [ -n "$SUBTITLE" ] && ARGS+=(-subtitle "$SUBTITLE")
    [ -f "$ICON" ] && ARGS+=(-contentImage "$ICON")

    terminal-notifier "${ARGS[@]}" 2>/dev/null
else
    # Fallback to osascript
    osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\"" 2>/dev/null
fi
exit 0
