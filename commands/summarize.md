---
description: Search past conversation logs for a topic and produce a detailed summary. Usage: /summarize <topic>
---

# Summarize Past Conversations

You are searching past Claude Code conversation logs to find and summarize everything discussed about a specific topic.

**Topic to summarize:** $ARGUMENTS

---

## Step 1: Identify the project

Determine the current working directory. Map it to the Claude Code project directory under `~/.claude/projects/`. The project directory name is the cwd with `/` replaced by `-` and no leading `-`. For example:
- `/Users/maggieyi/p/agentOS` → `-Users-maggieyi-p-agentOS`

Also check parent directory mappings — e.g., if cwd is `/Users/maggieyi/p/agentOS/ui`, check both `-Users-maggieyi-p-agentOS-ui` AND `-Users-maggieyi-p-agentOS`.

## Step 2: Search conversation logs

The conversation logs are `.jsonl` files in the project directory. Each line is a JSON object with a `type` field (`user`, `assistant`, `progress`, `file-history-snapshot`, etc.).

Run a search across ALL `.jsonl` files in the project directory for the topic keywords. Use multiple search terms — break the topic into individual keywords and also try the full phrase. For example, for "hive optimizer idea", search for:
- "hive optimizer"
- "hive" (in context of optimizer/optimization)
- "optimizer" (in context of hive)

Use `grep -l` first to identify which session files contain the topic, then extract the relevant messages from those sessions.

## Step 3: Extract relevant conversation segments

For each session file that matches, extract the conversation in chronological order. For each message:

- **type `user`**: The `message.content` field contains the user's message. If it's a string, use it directly. If it's a list, look for objects with `type: "text"` and extract the `text` field.
- **type `assistant`**: The `message.content` field contains Claude's response. It's typically a list — extract `text` from objects with `type: "text"`.
- Skip `file-history-snapshot`, `progress`, and tool result messages unless they contain directly relevant text.

Extract a window of messages around each match — enough to capture the full context of the discussion (typically 5-10 messages before and after the match).

## Step 4: Produce the summary

Organize your output as follows:

### Overview
A 2-3 sentence high-level summary of what was discussed about this topic across all sessions.

### Detailed Summary
For each session where the topic was discussed (chronological order):

**Session: [date if available, or session ID]**
- **Context:** What was the user working on when this came up?
- **Key points discussed:**
  - Bullet points covering the substantive content — decisions made, approaches considered, tradeoffs discussed, conclusions reached
- **Outcomes:** What was decided, built, or left unresolved?

### Key Decisions & Open Items
- Bullet list of concrete decisions that were made
- Bullet list of anything left unresolved or flagged for future work

### Relevant Code/Files
- List any files, functions, or components that were mentioned or modified in relation to this topic

---

## Rules

- **Be thorough.** Search ALL session files, not just the most recent one. The user is asking because they don't remember which session it was in.
- **Be specific.** Don't paraphrase vaguely — include actual details, numbers, names, and decisions from the conversations.
- **Distinguish your sources.** If information came from different sessions, make that clear so the user knows the chronology.
- **If nothing is found,** say so clearly and suggest alternative search terms the user might try.
- **Handle large sessions efficiently.** Some sessions have thousands of lines. Use grep to find relevant sections rather than reading entire files.
- **Privacy:** Only summarize conversations from the current project's directory. Do not search other projects.
