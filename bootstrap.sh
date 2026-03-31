#!/bin/bash
set -euo pipefail

# ══════════════════════════════════════════════════════════════════════
# bootstrap.sh — Full machine setup from zero to productive
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/jiaheyi-maggie/claude-code-config/main/bootstrap.sh | bash
#   OR
#   git clone git@github.com:jiaheyi-maggie/claude-code-config.git ~/setup/claude-code-config
#   cd ~/setup/claude-code-config && ./bootstrap.sh
# ══════════════════════════════════════════════════════════════════════

GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
BOLD='\033[1m'
RESET='\033[0m'

info()  { printf "${GREEN}[ok]${RESET} %s\n" "$1"; }
warn()  { printf "${YELLOW}[skip]${RESET} %s\n" "$1"; }
step()  { printf "\n${BOLD}=== %s ===${RESET}\n" "$1"; }
err()   { printf "${RED}[error]${RESET} %s\n" "$1"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES="$SCRIPT_DIR/dotfiles"

# ── 1. Homebrew ────────────────────────────────────────────────────
step "Homebrew"
if command -v brew &>/dev/null; then
    info "Homebrew already installed"
else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv zsh)"' >> "$HOME/.zprofile"
    eval "$(/opt/homebrew/bin/brew shellenv zsh)"
    info "Homebrew installed"
fi

# ── 2. Brew packages ──────────────────────────────────────────────
step "CLI tools"
PACKAGES=(
    # Core replacements
    eza bat fd fzf ripgrep zoxide git-delta dust tldr btop
    # Shell & prompt
    starship neovim
    # Git & GitHub
    gh lazygit git-absorb difftastic
    # Runtime & environment
    mise direnv
    # Data processing
    jq yq
    # HTTP & benchmarking
    xh hyperfine
    # Text processing & file watching
    sd watchexec
    # Code stats
    scc
    # Shell history
    atuin
)

installed=$(brew list --formula 2>/dev/null | tr '\n' ' ')
to_install=()
for pkg in "${PACKAGES[@]}"; do
    if echo "$installed" | grep -qw "$pkg"; then
        continue
    fi
    to_install+=("$pkg")
done

if [ ${#to_install[@]} -eq 0 ]; then
    info "All packages already installed"
else
    echo "Installing: ${to_install[*]}"
    brew install "${to_install[@]}"
    info "Packages installed"
fi

# ── 3. Bun ─────────────────────────────────────────────────────────
step "Bun"
if command -v bun &>/dev/null || [ -x "$HOME/.bun/bin/bun" ]; then
    info "Bun already installed"
else
    BUN_VERSION="1.3.10"
    BUN_INSTALL_SHA="bab8acfb046aac8c72407bdcce903957665d655d7acaa3e11c7c4616beae68dd"
    tmpfile=$(mktemp)
    curl -fsSL "https://bun.sh/install" -o "$tmpfile"
    actual_sha=$(shasum -a 256 "$tmpfile" | awk '{print $1}')
    if [ "$actual_sha" != "$BUN_INSTALL_SHA" ]; then
        err "Bun install script checksum mismatch (expected: $BUN_INSTALL_SHA, got: $actual_sha)"
    fi
    BUN_VERSION="$BUN_VERSION" bash "$tmpfile"
    rm "$tmpfile"
    info "Bun $BUN_VERSION installed"
fi

# ── 4. SSH key ─────────────────────────────────────────────────────
step "SSH key"
mkdir -p ~/.ssh
if [ -f "$HOME/.ssh/id_ed25519" ]; then
    info "ED25519 key already exists"
else
    ssh-keygen -t ed25519 -C "$(whoami)" -f "$HOME/.ssh/id_ed25519" -N ""
    info "ED25519 key generated"
fi

# SSH config
if [ -f "$DOTFILES/ssh-config" ]; then
    if [ -f "$HOME/.ssh/config" ]; then
        if grep -q "github.com" "$HOME/.ssh/config"; then
            info "SSH config already has github.com"
        else
            cat "$DOTFILES/ssh-config" >> "$HOME/.ssh/config"
            info "Appended GitHub SSH config"
        fi
    else
        cp "$DOTFILES/ssh-config" "$HOME/.ssh/config"
        info "SSH config installed"
    fi
    chmod 600 "$HOME/.ssh/config"
fi

# ── 5. GitHub CLI auth ────────────────────────────────────────────
step "GitHub CLI"
if gh auth status &>/dev/null 2>&1; then
    info "Already authenticated with GitHub"
else
    echo ""
    echo "  Your public key:"
    echo "  $(cat "$HOME/.ssh/id_ed25519.pub")"
    echo ""
    echo "  Run this after bootstrap completes:"
    echo "    gh auth login -p ssh -h github.com -w"
    echo ""
    warn "GitHub CLI not yet authenticated (manual step required)"
fi

# ── 6. Dotfiles ───────────────────────────────────────────────────
step "Dotfiles"

# .zprofile
if [ -f "$DOTFILES/.zprofile" ]; then
    if [ -f "$HOME/.zprofile" ] && grep -q "brew shellenv" "$HOME/.zprofile"; then
        info ".zprofile already configured"
    else
        cp "$DOTFILES/.zprofile" "$HOME/.zprofile"
        info ".zprofile installed"
    fi
fi

# .zshrc
if [ -f "$DOTFILES/.zshrc" ]; then
    if [ -f "$HOME/.zshrc" ]; then
        # Back up existing
        cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d-%H%M%S)"
        info "Backed up existing .zshrc"
    fi
    cp "$DOTFILES/.zshrc" "$HOME/.zshrc"
    info ".zshrc installed"
fi

# starship.toml
if [ -f "$DOTFILES/starship.toml" ]; then
    mkdir -p "$HOME/.config"
    cp "$DOTFILES/starship.toml" "$HOME/.config/starship.toml"
    info "starship.toml installed"
fi

# ── 7. Git config ────────────────────────────────────────────────
step "Git config"

# Delta as pager
git config --global core.pager delta
git config --global interactive.diffFilter 'delta --color-only'
git config --global delta.navigate true
git config --global delta.side-by-side true
git config --global delta.line-numbers true

# Merge conflict style
git config --global merge.conflictstyle zdiff3

# Difftastic as difftool
git config --global diff.tool difftastic
git config --global difftool.prompt false
git config --global difftool.difftastic.cmd 'difft "$LOCAL" "$REMOTE"'

# Git absorb
git config --global absorb.maxStack 50

info "Git configured (delta + difftastic + absorb + zdiff3)"

# ── 8. Claude Code config ────────────────────────────────────────
step "Claude Code"

# Run the existing install.sh (symlinks commands, hooks, agents, skills, CLAUDE.md)
if [ -x "$SCRIPT_DIR/install.sh" ]; then
    bash "$SCRIPT_DIR/install.sh"
fi

# Merge settings.json
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"
REFERENCE="$SCRIPT_DIR/settings.reference.json"

if [ -f "$SETTINGS" ]; then
    # Preserve existing settings, merge reference keys that are missing
    if command -v jq &>/dev/null && [ -f "$REFERENCE" ]; then
        # Ensure effortLevel is max
        tmp=$(mktemp)
        jq '.effortLevel = "max"' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
        info "settings.json updated (effortLevel=max)"
    fi
else
    if [ -f "$REFERENCE" ]; then
        cp "$REFERENCE" "$SETTINGS"
        # Set effort to max
        tmp=$(mktemp)
        jq '.effortLevel = "max"' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
        info "settings.json installed from reference"
    fi
fi

# ── 9. gstack setup ──────────────────────────────────────────────
step "gstack"
GSTACK_DIR="$CLAUDE_DIR/skills/gstack"
if [ -d "$GSTACK_DIR" ] && [ -x "$GSTACK_DIR/setup" ]; then
    export PATH="$HOME/.bun/bin:$PATH"
    if command -v bun &>/dev/null; then
        (cd "$GSTACK_DIR" && ./setup)
        info "gstack built"
    else
        warn "bun not found in PATH, skipping gstack build"
    fi
else
    warn "gstack not found at $GSTACK_DIR"
fi

# ── 10. Atuin ─────────────────────────────────────────────────────
step "Atuin"
export PATH="/opt/homebrew/bin:$PATH"
if command -v atuin &>/dev/null; then
    atuin import auto 2>/dev/null || true
    if brew services list 2>/dev/null | grep -q "atuin.*started"; then
        info "Atuin daemon already running"
    else
        brew services start atuin 2>/dev/null || true
        info "Atuin daemon started"
    fi
fi

# ── 11. Remove Oh My Zsh (if present) ────────────────────────────
step "Cleanup"
if [ -d "$HOME/.oh-my-zsh" ]; then
    warn "Oh My Zsh found at ~/.oh-my-zsh — not needed with Zinit"
    echo "     Remove manually if desired: rm -rf ~/.oh-my-zsh"
fi

# ── Summary ───────────────────────────────────────────────────────
step "Done"
echo ""
echo "  Installed:"
echo "    Brew packages: ${#PACKAGES[@]}"
echo "    Bun:           $(bun --version 2>/dev/null || echo 'pending PATH reload')"
echo "    SSH key:       ~/.ssh/id_ed25519"
echo "    Dotfiles:      .zshrc, .zprofile, starship.toml"
echo "    Git:           delta + difftastic + absorb + zdiff3"
echo "    Claude Code:   commands, hooks, agents, skills, CLAUDE.md"
echo ""
echo "  Manual steps remaining:"
if ! gh auth status &>/dev/null 2>&1; then
    echo "    1. gh auth login -p ssh -h github.com -w"
fi
echo "    2. exec zsh  (reload shell)"
echo ""
