#!/bin/bash
# ConfigChange hook: log configuration changes for audit
input=$(cat)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SOURCE=$(echo "$input" | jq -r '.source // "unknown"')
FILE_PATH=$(echo "$input" | jq -r '.file_path // "unknown"')

echo "{\"timestamp\":\"$TIMESTAMP\",\"source\":\"$SOURCE\",\"file\":\"$FILE_PATH\"}" >> ~/claude-config-audit.log
exit 0
