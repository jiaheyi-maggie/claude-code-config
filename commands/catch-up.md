---
description: Summarize everything that happened since the last /tbc bookmark. Shows what you missed while away.
---

# Catch Up — Summarize What You Missed

The user stepped away and someone else (or Claude) continued working. Summarize everything that happened since the last `/tbc` bookmark.

## Step 1: Find the bookmark

Look for `.claude/tbc-marker.json` in the current project root directory. If it doesn't exist, tell the user: "No bookmark found. Use `/tbc` to drop a bookmark before stepping away, then `/catch-up` when you return."

Read the marker to get:
- `session_id` — the JSONL filename
- `project_dir` — the project directory under `~/.claude/projects/`
- `line_number` — where the bookmark was dropped

## Step 2: Extract new messages

Read the session's JSONL file starting from the bookmarked line number. Use `tail -n +<line_number>` to get everything after the bookmark.

For each line, parse the JSON and extract messages:
- **type `user`**: Extract the user's message text. If `message.content` is a string, use it directly. If it's a list, look for `type: "text"` objects and extract the `text` field. Skip tool result messages (content that is a list of objects with `type: "tool_result"`).
- **type `assistant`**: Extract Claude's response text from `message.content` — look for `type: "text"` objects in the content list.
- **Skip**: `file-history-snapshot`, `progress`, and other non-conversation types.

If the session ID in the marker doesn't match any current JSONL file, check if the conversation continued in a different session. List all JSONL files in the project directory, find any created after the bookmark timestamp, and search those too.

## Step 3: Produce the catch-up summary

Format your output as:

### What happened while you were away

**Duration:** [time between bookmark and last message]
**Messages exchanged:** [approximate count of user + assistant turns]

### Summary
A concise but thorough narrative of what was discussed and done. Organize by topic/task if multiple things were worked on. Include:
- What the other person asked for
- What decisions were made
- What code was written or modified (list files changed)
- What problems came up and how they were resolved
- What's currently in progress or left unfinished

### Files Changed
- Bullet list of files that were created, modified, or deleted

### Current State
Where things stand right now — what's working, what's broken, what needs attention. This is the most important section: it tells the returning user what they need to know to pick up where things are.

### Open Questions / Next Steps
- Anything that was left unresolved or needs the returning user's input

---

## Rules
- **Be specific, not vague.** Include actual function names, file paths, error messages, and decisions — not "some code was changed."
- **Distinguish user requests from Claude's actions.** Make it clear what the other person asked for vs. what Claude did in response.
- **If a LOT happened** (>100 message turns), provide a high-level summary first, then offer to drill into specific sections.
- **Don't delete the marker** after catching up — the user might want to run `/catch-up` again. The marker gets overwritten next time `/tbc` is used.
- **If no new messages exist** after the bookmark, tell the user: "Nothing happened since your bookmark — you're all caught up."
