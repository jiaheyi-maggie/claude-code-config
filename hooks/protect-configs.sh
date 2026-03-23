#!/bin/bash
# PreToolUse hook: Prevent agents from modifying linter/formatter configs
# Blocks edits to config files that agents might weaken to "pass" instead of fixing code

set -euo pipefail

EVENT=$(echo "$CLAUDE_TOOL_USE_INPUT" 2>/dev/null | head -c 5000)
FILE_PATH=""

if echo "$EVENT" | grep -q '"file_path"'; then
    FILE_PATH=$(echo "$EVENT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
fi

[ -z "$FILE_PATH" ] && exit 0

BASENAME=$(basename "$FILE_PATH")

# Protected config files — agents should fix code, not weaken linters
case "$BASENAME" in
    .eslintrc*|eslint.config*|.prettierrc*|prettier.config*|\
    .stylelintrc*|stylelint.config*|\
    tsconfig.json|tsconfig.*.json|\
    .ruff.toml|ruff.toml|setup.cfg|pyproject.toml|\
    .clang-format|.clang-tidy|\
    .flake8|.pylintrc|.mypy.ini|mypy.ini|\
    biome.json|biome.jsonc|\
    .editorconfig)
        # Allow if pyproject.toml changes are to non-lint sections
        if [ "$BASENAME" = "pyproject.toml" ]; then
            # Check if the edit touches lint/ruff/mypy sections
            if echo "$EVENT" | grep -qi 'ruff\|mypy\|pylint\|flake8\|tool\.lint\|tool\.ruff'; then
                echo "BLOCK: Modifying linter config in $BASENAME. Fix the code instead of weakening the linter."
                exit 2
            fi
            exit 0
        fi
        echo "BLOCK: Modifying $BASENAME. Fix the code to pass the linter — don't weaken the rules."
        exit 2
        ;;
esac

exit 0
