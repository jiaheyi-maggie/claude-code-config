#!/bin/bash
# PostToolUse hook: auto-format C/C++ files after Write/Edit
input=$(cat)
FILE_PATH=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# Only process C/C++ files
case "$FILE_PATH" in
    *.c|*.h|*.cpp|*.hpp|*.cc|*.hh) ;;
    *) exit 0 ;;
esac

[[ ! -f "$FILE_PATH" ]] && exit 0

command -v clang-format &>/dev/null && clang-format -i "$FILE_PATH" 2>/dev/null
exit 0
