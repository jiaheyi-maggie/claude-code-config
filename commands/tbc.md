---
description: Drop a bookmark in the current conversation. Pair with /catch-up to summarize everything after this point.
---

# To Be Continued — Drop a Bookmark

The user is stepping away from this conversation. Drop a bookmark so `/catch-up` can later summarize everything that happened after this point.

## What to do

1. **Identify the current session's JSONL file.** Map the current working directory to the Claude Code project directory under `~/.claude/projects/` (cwd with `/` replaced by `-`, no leading `-`). Find the `.jsonl` file matching the current session ID.

2. **Count the current line position.** Run `wc -l` on the session's JSONL file to get the current line count. This is your bookmark — everything after this line is "new."

3. **Write the marker file.** Save to `.claude/tbc-marker.json` in the project root (the actual working directory, not `~/.claude`). If `.claude/` doesn't exist in the project root, create it.

```json
{
  "timestamp": "<current UTC ISO timestamp>",
  "session_id": "<current session JSONL filename>",
  "project_dir": "<project directory name under ~/.claude/projects/>",
  "line_number": <current line count>,
  "note": "<optional: any context about what was being worked on>"
}
```

4. **Confirm to the user.** Print a short confirmation:
   ```
   Bookmark dropped. When you're back, run /catch-up to see what you missed.
   ```

## Rules
- If a previous marker exists, overwrite it — only the most recent bookmark matters.
- Include a brief note about what was being discussed at the time of the bookmark (1 sentence, derived from recent conversation context).
- Do NOT summarize the conversation so far — the user is here and knows what happened. Just drop the marker.
