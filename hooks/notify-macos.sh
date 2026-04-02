#!/bin/bash
# Notification hook: macOS desktop notification with Claude icon.
# Detects which terminal is running the session and activates it on click.
input=$(cat)
MESSAGE=$(echo "$input" | jq -r '.message // "Claude Code needs attention"')
TYPE=$(echo "$input" | jq -r '.notification_type // "unknown"')

TITLE="Claude Code"
SUBTITLE=""
case "$TYPE" in
    permission_prompt) SUBTITLE="Permission Needed" ;;
    idle_prompt) SUBTITLE="Waiting for Input" ;;
esac

# Detect the current terminal app
detect_terminal_bundle() {
    # VS Code
    if [ -n "$VSCODE_PID" ] || [ "$TERM_PROGRAM" = "vscode" ]; then
        echo "com.microsoft.VSCode"
        return
    fi
    # Cursor
    if [ -n "$CURSOR_PID" ] || [ "$TERM_PROGRAM" = "cursor" ]; then
        echo "com.todesktop.230313mzl4w4u92"
        return
    fi
    # Wave Terminal
    if [ -n "$WAVETERM_DEV" ] || [ "$TERM_PROGRAM" = "WaveTerm" ] || [ -n "$WAVETERM_BLOCKID" ]; then
        echo "dev.commandline.waveterm"
        return
    fi
    # iTerm2
    if [ "$TERM_PROGRAM" = "iTerm.app" ]; then
        echo "com.googlecode.iterm2"
        return
    fi
    # Warp
    if [ "$TERM_PROGRAM" = "WarpTerminal" ]; then
        echo "dev.warp.Warp-Stable"
        return
    fi
    # Kitty
    if [ "$TERM_PROGRAM" = "kitty" ]; then
        echo "net.kovidgoyal.kitty"
        return
    fi
    # Alacritty
    if [ "$TERM_PROGRAM" = "alacritty" ]; then
        echo "org.alacritty"
        return
    fi
    # JetBrains IDEs
    if [ -n "$JETBRAINS_IDE" ] || [ "$TERMINAL_EMULATOR" = "JetBrains-JediTerm" ]; then
        # Try to find the specific JetBrains app from parent process
        local jetbrains_app
        jetbrains_app=$(ps -o comm= -p "$PPID" 2>/dev/null | grep -oE '(idea|webstorm|pycharm|goland|clion|rider|rubymine|phpstorm|datagrip)' | head -1)
        case "$jetbrains_app" in
            idea)      echo "com.jetbrains.intellij" ;;
            webstorm)  echo "com.jetbrains.WebStorm" ;;
            pycharm)   echo "com.jetbrains.pycharm" ;;
            goland)    echo "com.jetbrains.goland" ;;
            clion)     echo "com.jetbrains.CLion" ;;
            *)         echo "com.jetbrains.intellij" ;;
        esac
        return
    fi
    # Apple Terminal (fallback)
    if [ "$TERM_PROGRAM" = "Apple_Terminal" ]; then
        echo "com.apple.Terminal"
        return
    fi
    # Last resort: check parent process
    local parent_app
    parent_app=$(ps -o comm= -p "$PPID" 2>/dev/null)
    case "$parent_app" in
        *waveterm*) echo "dev.commandline.waveterm" ;;
        *Code*)     echo "com.microsoft.VSCode" ;;
        *cursor*)   echo "com.todesktop.230313mzl4w4u92" ;;
        *)          echo "dev.commandline.waveterm" ;;  # default
    esac
}

ACTIVATE_BUNDLE=$(detect_terminal_bundle)

# Use native Swift app (shows Claude icon)
CLAUDE_NOTIFY="$HOME/Applications/Notifiers/ClaudeNotify.app/Contents/MacOS/ClaudeNotify"
if [ -x "$CLAUDE_NOTIFY" ]; then
    "$CLAUDE_NOTIFY" "$TITLE" "$SUBTITLE" "$MESSAGE" "$ACTIVATE_BUNDLE" 2>/dev/null &
elif command -v terminal-notifier &>/dev/null; then
    terminal-notifier -title "$TITLE" -message "$MESSAGE" -group "claude-code-$TYPE" -sound default -activate "$ACTIVATE_BUNDLE" 2>/dev/null
else
    osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\"" 2>/dev/null
fi
exit 0
