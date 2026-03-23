#!/bin/bash
# PostToolUse hook: Plankton code quality enforcement
# Runs language-appropriate linters on every file edit
# Phase 1: Auto-format silently | Phase 2: Collect violations | Phase 3: Report

set -euo pipefail

EVENT=$(echo "$CLAUDE_TOOL_USE_INPUT" 2>/dev/null | head -c 5000)
FILE_PATH=""

if echo "$EVENT" | grep -q '"file_path"'; then
    FILE_PATH=$(echo "$EVENT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
fi

[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

VIOLATIONS=""
BASENAME=$(basename "$FILE_PATH")
EXT="${FILE_PATH##*.}"

case "$EXT" in
    ts|tsx|js|jsx)
        # Phase 1: Auto-format with prettier (if available)
        if command -v npx >/dev/null 2>&1; then
            npx --yes prettier --write "$FILE_PATH" 2>/dev/null || true
        fi

        # Phase 2: Collect violations
        # ESLint
        if [ -f "node_modules/.bin/eslint" ] || [ -f "eslint.config.js" ] || [ -f ".eslintrc.json" ] || [ -f ".eslintrc.js" ]; then
            ESLINT_OUT=$(npx eslint "$FILE_PATH" --format compact 2>/dev/null || true)
            if [ -n "$ESLINT_OUT" ] && echo "$ESLINT_OUT" | grep -q "Error\|Warning"; then
                COUNT=$(echo "$ESLINT_OUT" | grep -c "Error\|Warning" || true)
                VIOLATIONS="${VIOLATIONS}eslint: ${COUNT} issue(s) in $(basename "$FILE_PATH")\n"
            fi
        fi

        # TypeScript type check
        if [ -f "tsconfig.json" ] && ([ "$EXT" = "ts" ] || [ "$EXT" = "tsx" ]); then
            TSC_OUT=$(npx tsc --noEmit --pretty false "$FILE_PATH" 2>/dev/null || true)
            if [ -n "$TSC_OUT" ] && echo "$TSC_OUT" | grep -q "error TS"; then
                COUNT=$(echo "$TSC_OUT" | grep -c "error TS" || true)
                VIOLATIONS="${VIOLATIONS}tsc: ${COUNT} type error(s) in $(basename "$FILE_PATH")\n"
            fi
        fi

        # Biome (if configured)
        if [ -f "biome.json" ] || [ -f "biome.jsonc" ]; then
            BIOME_OUT=$(npx biome check "$FILE_PATH" 2>/dev/null || true)
            if echo "$BIOME_OUT" | grep -q "error\|warning"; then
                VIOLATIONS="${VIOLATIONS}biome: issues found in $(basename "$FILE_PATH")\n"
            fi
        fi
        ;;

    py)
        # Phase 1: Auto-format
        if command -v black >/dev/null 2>&1; then
            black --quiet "$FILE_PATH" 2>/dev/null || true
        fi
        if command -v isort >/dev/null 2>&1; then
            isort --quiet "$FILE_PATH" 2>/dev/null || true
        fi

        # Phase 2: Collect violations
        # Ruff (fast linter + formatter)
        if command -v ruff >/dev/null 2>&1; then
            RUFF_OUT=$(ruff check "$FILE_PATH" 2>/dev/null || true)
            if [ -n "$RUFF_OUT" ]; then
                COUNT=$(echo "$RUFF_OUT" | grep -c "Found" || echo "$RUFF_OUT" | wc -l | tr -d ' ')
                VIOLATIONS="${VIOLATIONS}ruff: issues in $(basename "$FILE_PATH")\n"
            fi
        fi

        # Mypy type check
        if command -v mypy >/dev/null 2>&1; then
            MYPY_OUT=$(mypy "$FILE_PATH" --no-error-summary 2>/dev/null || true)
            if [ -n "$MYPY_OUT" ] && echo "$MYPY_OUT" | grep -q "error:"; then
                COUNT=$(echo "$MYPY_OUT" | grep -c "error:" || true)
                VIOLATIONS="${VIOLATIONS}mypy: ${COUNT} type error(s) in $(basename "$FILE_PATH")\n"
            fi
        fi

        # Bandit security check
        if command -v bandit >/dev/null 2>&1; then
            BANDIT_OUT=$(bandit -q "$FILE_PATH" 2>/dev/null || true)
            if [ -n "$BANDIT_OUT" ] && echo "$BANDIT_OUT" | grep -q "Severity\|Issue"; then
                VIOLATIONS="${VIOLATIONS}bandit: security issue(s) in $(basename "$FILE_PATH")\n"
            fi
        fi
        ;;

    c|h|cpp|hpp|cc)
        # Phase 1: Auto-format
        if command -v clang-format >/dev/null 2>&1 && [ -f ".clang-format" ]; then
            clang-format -i "$FILE_PATH" 2>/dev/null || true
        fi

        # Phase 2: Collect violations
        # clang-tidy
        if command -v clang-tidy >/dev/null 2>&1 && [ -f ".clang-tidy" ]; then
            TIDY_OUT=$(clang-tidy "$FILE_PATH" 2>/dev/null || true)
            if echo "$TIDY_OUT" | grep -q "warning:\|error:"; then
                COUNT=$(echo "$TIDY_OUT" | grep -c "warning:\|error:" || true)
                VIOLATIONS="${VIOLATIONS}clang-tidy: ${COUNT} issue(s) in $(basename "$FILE_PATH")\n"
            fi
        fi

        # cppcheck
        if command -v cppcheck >/dev/null 2>&1; then
            CPP_OUT=$(cppcheck --quiet --enable=warning,style "$FILE_PATH" 2>&1 || true)
            if [ -n "$CPP_OUT" ]; then
                VIOLATIONS="${VIOLATIONS}cppcheck: issues in $(basename "$FILE_PATH")\n"
            fi
        fi
        ;;

    sh|bash|zsh)
        # ShellCheck
        if command -v shellcheck >/dev/null 2>&1; then
            SC_OUT=$(shellcheck "$FILE_PATH" 2>/dev/null || true)
            if [ -n "$SC_OUT" ]; then
                COUNT=$(echo "$SC_OUT" | grep -c "SC[0-9]" || true)
                VIOLATIONS="${VIOLATIONS}shellcheck: ${COUNT} issue(s) in $(basename "$FILE_PATH")\n"
            fi
        fi
        ;;

    yaml|yml)
        if command -v yamllint >/dev/null 2>&1; then
            YML_OUT=$(yamllint -f parsable "$FILE_PATH" 2>/dev/null || true)
            if [ -n "$YML_OUT" ]; then
                VIOLATIONS="${VIOLATIONS}yamllint: issues in $(basename "$FILE_PATH")\n"
            fi
        fi
        ;;

    json)
        # Validate JSON syntax
        if command -v python3 >/dev/null 2>&1; then
            if ! python3 -m json.tool "$FILE_PATH" >/dev/null 2>&1; then
                VIOLATIONS="${VIOLATIONS}json: invalid JSON syntax in $(basename "$FILE_PATH")\n"
            fi
        fi
        ;;

    md)
        if command -v markdownlint >/dev/null 2>&1; then
            MD_OUT=$(markdownlint "$FILE_PATH" 2>/dev/null || true)
            if [ -n "$MD_OUT" ]; then
                VIOLATIONS="${VIOLATIONS}markdownlint: issues in $(basename "$FILE_PATH")\n"
            fi
        fi
        ;;

    Dockerfile|dockerfile)
        if command -v hadolint >/dev/null 2>&1; then
            DK_OUT=$(hadolint "$FILE_PATH" 2>/dev/null || true)
            if [ -n "$DK_OUT" ]; then
                VIOLATIONS="${VIOLATIONS}hadolint: issues in $(basename "$FILE_PATH")\n"
            fi
        fi
        ;;
esac

# Phase 3: Report violations
if [ -n "$VIOLATIONS" ]; then
    echo -e "Plankton quality check:\n${VIOLATIONS}Fix these before committing."
fi

exit 0
