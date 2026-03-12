#!/bin/bash
# PostToolUse hook: auto-format Python files after Write/Edit
input=$(cat)
FILE_PATH=$(echo "$input" | jq -r '.tool_input.file_path // empty')

[[ "$FILE_PATH" != *.py ]] && exit 0
[[ ! -f "$FILE_PATH" ]] && exit 0

command -v black &>/dev/null && black --quiet "$FILE_PATH" 2>/dev/null
exit 0
