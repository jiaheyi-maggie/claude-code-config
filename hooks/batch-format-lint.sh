#!/bin/bash
# Stop hook: Batch format and lint all files edited during this response.
# Runs once instead of per-edit — significant speedup for multi-file changes.

set -uo pipefail

# Find the batch file (try multiple PID strategies)
BATCH_FILE=""
for candidate in \
    "/tmp/claude-edited-files-${CLAUDE_SESSION_ID:-}" \
    "/tmp/claude-edited-files-$(ps -o ppid= -p $$ 2>/dev/null | tr -d ' ')" \
    "/tmp/claude-edited-files-$$"; do
    [ -f "$candidate" ] && BATCH_FILE="$candidate" && break
done

[ -z "$BATCH_FILE" ] && exit 0
[ ! -s "$BATCH_FILE" ] && rm -f "$BATCH_FILE" && exit 0

# Dedupe and filter to existing files
FILES=$(sort -u "$BATCH_FILE" | while read -r f; do [ -f "$f" ] && echo "$f"; done)
rm -f "$BATCH_FILE"

[ -z "$FILES" ] && exit 0

# Group files by extension
PY_FILES=""
C_FILES=""
TS_FILES=""
SH_FILES=""
OTHER_FILES=""

while IFS= read -r f; do
    case "$f" in
        *.py)                       PY_FILES="$PY_FILES $f" ;;
        *.c|*.h|*.cpp|*.hpp|*.cc)   C_FILES="$C_FILES $f" ;;
        *.ts|*.tsx|*.js|*.jsx)      TS_FILES="$TS_FILES $f" ;;
        *.sh|*.bash|*.zsh)          SH_FILES="$SH_FILES $f" ;;
        *)                          OTHER_FILES="$OTHER_FILES $f" ;;
    esac
done <<< "$FILES"

VIOLATIONS=""

# ── Python ─────────────────────────────────────────────────────────
if [ -n "$PY_FILES" ]; then
    # Format
    if command -v black &>/dev/null; then
        black --quiet $PY_FILES 2>/dev/null || true
    fi
    if command -v isort &>/dev/null; then
        isort --quiet $PY_FILES 2>/dev/null || true
    fi
    # Lint
    if command -v ruff &>/dev/null; then
        RUFF_OUT=$(ruff check $PY_FILES 2>/dev/null || true)
        [ -n "$RUFF_OUT" ] && VIOLATIONS="${VIOLATIONS}ruff: issues found\n"
    fi
    # Type check
    if command -v mypy &>/dev/null; then
        MYPY_OUT=$(mypy $PY_FILES --no-error-summary 2>/dev/null || true)
        if echo "$MYPY_OUT" | grep -q "error:" 2>/dev/null; then
            COUNT=$(echo "$MYPY_OUT" | grep -c "error:" || true)
            VIOLATIONS="${VIOLATIONS}mypy: ${COUNT} type error(s)\n"
        fi
    fi
    # Security
    if command -v bandit &>/dev/null; then
        BANDIT_OUT=$(bandit -q $PY_FILES 2>/dev/null || true)
        if echo "$BANDIT_OUT" | grep -q "Severity\|Issue" 2>/dev/null; then
            VIOLATIONS="${VIOLATIONS}bandit: security issue(s) found\n"
        fi
    fi
fi

# ── C/C++ ──────────────────────────────────────────────────────────
if [ -n "$C_FILES" ]; then
    if command -v clang-format &>/dev/null; then
        clang-format -i $C_FILES 2>/dev/null || true
    fi
    if command -v clang-tidy &>/dev/null && [ -f ".clang-tidy" ]; then
        TIDY_OUT=$(clang-tidy $C_FILES 2>/dev/null || true)
        if echo "$TIDY_OUT" | grep -q "warning:\|error:" 2>/dev/null; then
            COUNT=$(echo "$TIDY_OUT" | grep -c "warning:\|error:" || true)
            VIOLATIONS="${VIOLATIONS}clang-tidy: ${COUNT} issue(s)\n"
        fi
    fi
fi

# ── TypeScript/JavaScript ─────────────────────────────────────────
if [ -n "$TS_FILES" ]; then
    # Format: prefer biome, then prettier
    if [ -f "biome.json" ] || [ -f "biome.jsonc" ]; then
        npx --yes @biomejs/biome format --write $TS_FILES 2>/dev/null || true
        # Lint
        BIOME_OUT=$(npx @biomejs/biome check $TS_FILES 2>/dev/null || true)
        if echo "$BIOME_OUT" | grep -q "error\|warning" 2>/dev/null; then
            VIOLATIONS="${VIOLATIONS}biome: issues found\n"
        fi
    elif command -v npx &>/dev/null; then
        npx --yes prettier --write $TS_FILES 2>/dev/null || true
    fi

    # ESLint (if configured)
    if [ -f "eslint.config.js" ] || [ -f ".eslintrc.json" ] || [ -f ".eslintrc.js" ]; then
        ESLINT_OUT=$(npx eslint $TS_FILES --format compact 2>/dev/null || true)
        if echo "$ESLINT_OUT" | grep -q "Error\|Warning" 2>/dev/null; then
            COUNT=$(echo "$ESLINT_OUT" | grep -c "Error\|Warning" || true)
            VIOLATIONS="${VIOLATIONS}eslint: ${COUNT} issue(s)\n"
        fi
    fi

    # TypeScript type check (batch all .ts/.tsx files together)
    if [ -f "tsconfig.json" ]; then
        TS_ONLY=$(echo "$TS_FILES" | tr ' ' '\n' | grep -E '\.(ts|tsx)$' | tr '\n' ' ')
        if [ -n "$TS_ONLY" ]; then
            TSC_OUT=$(npx tsc --noEmit --pretty false 2>/dev/null || true)
            if echo "$TSC_OUT" | grep -q "error TS" 2>/dev/null; then
                COUNT=$(echo "$TSC_OUT" | grep -c "error TS" || true)
                VIOLATIONS="${VIOLATIONS}tsc: ${COUNT} type error(s)\n"
            fi
        fi
    fi
fi

# ── Shell ──────────────────────────────────────────────────────────
if [ -n "$SH_FILES" ]; then
    if command -v shellcheck &>/dev/null; then
        SC_OUT=$(shellcheck $SH_FILES 2>/dev/null || true)
        if [ -n "$SC_OUT" ]; then
            COUNT=$(echo "$SC_OUT" | grep -c "SC[0-9]" || true)
            VIOLATIONS="${VIOLATIONS}shellcheck: ${COUNT} issue(s)\n"
        fi
    fi
fi

# ── Report ─────────────────────────────────────────────────────────
FILE_COUNT=$(echo "$FILES" | wc -l | tr -d ' ')
if [ -n "$VIOLATIONS" ]; then
    echo -e "Batch quality check (${FILE_COUNT} files):\n${VIOLATIONS}Fix these before committing."
fi

exit 0
