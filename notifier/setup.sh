#!/bin/bash
set -euo pipefail

# Google Notifier Setup
# Installs dependencies, guides through OAuth, starts the launchd daemon.

GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
BOLD='\033[1m'
RESET='\033[0m'

info()  { printf "${GREEN}[ok]${RESET} %s\n" "$1"; }
warn()  { printf "${YELLOW}[!]${RESET} %s\n" "$1"; }
err()   { printf "${RED}[error]${RESET} %s\n" "$1"; exit 1; }
step()  { printf "\n${BOLD}=== %s ===${RESET}\n" "$1"; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="$HOME/.google-notifier"
PLIST_NAME="com.user.google-notifier"
PLIST_SRC="$SCRIPT_DIR/$PLIST_NAME.plist"
PLIST_DST="$HOME/Library/LaunchAgents/$PLIST_NAME.plist"

# ── 1. Dependencies ───────────────────────────────────────────────
step "Dependencies"
command -v bun &>/dev/null || err "bun not found. Install: curl -fsSL https://bun.sh/install | bash"
command -v terminal-notifier &>/dev/null || err "terminal-notifier not found. Install: brew install terminal-notifier"
info "bun and terminal-notifier found"

cd "$SCRIPT_DIR"
bun install --frozen-lockfile 2>/dev/null || bun install
info "Node dependencies installed"

# ── 2. State directory ────────────────────────────────────────────
mkdir -p "$STATE_DIR"
info "State directory: $STATE_DIR"

# ── 3. Credentials check ─────────────────────────────────────────
step "Google OAuth2 Credentials"
if [ ! -f "$SCRIPT_DIR/credentials.json" ]; then
    echo ""
    echo "  You need OAuth2 credentials from Google Cloud Console."
    echo ""
    echo "  Quick setup (5 minutes):"
    echo "    1. Go to https://console.cloud.google.com/projectcreate"
    echo "       Create a project named 'Notifier'"
    echo ""
    echo "    2. Enable APIs:"
    echo "       https://console.cloud.google.com/apis/library/gmail.googleapis.com"
    echo "       https://console.cloud.google.com/apis/library/calendar-json.googleapis.com"
    echo ""
    echo "    3. Configure OAuth consent screen:"
    echo "       https://console.cloud.google.com/apis/credentials/consent"
    echo "       - User Type: External"
    echo "       - App name: Notifier"
    echo "       - Add your email as a test user"
    echo "       - Leave in 'Testing' mode (no verification needed)"
    echo ""
    echo "    4. Create credentials:"
    echo "       https://console.cloud.google.com/apis/credentials"
    echo "       - Create OAuth 2.0 Client ID"
    echo "       - Application type: Desktop app"
    echo "       - Download JSON"
    echo "       - Save as: $SCRIPT_DIR/credentials.json"
    echo ""
    echo "  Then re-run this script."
    exit 1
else
    info "credentials.json found"
fi

# ── 4. OAuth authorization ────────────────────────────────────────
step "OAuth Authorization"
# Check if tokens exist in Keychain
if security find-generic-password -s "google-notifier" -a "oauth-tokens" -w &>/dev/null 2>&1; then
    info "OAuth tokens found in Keychain"
else
    warn "No tokens found — starting authorization flow..."
    bun run auth.ts
fi

# ── 5. Test ───────────────────────────────────────────────────────
step "Test Run"
echo "Running single check..."
bun run notifier.ts --once
info "Test passed"

# ── 6. Install launchd daemon ─────────────────────────────────────
step "Install Background Service"

# Update plist with correct paths for this machine
PLIST_CONTENT=$(cat "$PLIST_SRC")
PLIST_CONTENT="${PLIST_CONTENT//\/Users\/maggieyi/$HOME}"

# Unload existing if present
launchctl unload "$PLIST_DST" 2>/dev/null || true

echo "$PLIST_CONTENT" > "$PLIST_DST"
launchctl load "$PLIST_DST"
info "launchd daemon installed and started"

# ── Summary ───────────────────────────────────────────────────────
step "Done"
echo ""
echo "  Google Notifier is running in the background."
echo ""
echo "  Gmail:    polling every 30 seconds"
echo "  Calendar: polling every 60 seconds (notifies 10 min before events)"
echo ""
echo "  Notifications: click to open Gmail/Calendar in browser"
echo ""
echo "  Commands:"
echo "    Status:  launchctl list | grep google-notifier"
echo "    Logs:    tail -f ~/.google-notifier/notifier.log"
echo "    Stop:    launchctl unload ~/Library/LaunchAgents/$PLIST_NAME.plist"
echo "    Start:   launchctl load ~/Library/LaunchAgents/$PLIST_NAME.plist"
echo "    Re-auth: cd $SCRIPT_DIR && bun run auth.ts"
echo ""
