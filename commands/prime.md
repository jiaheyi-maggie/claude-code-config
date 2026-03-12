Load all critical project context before starting work. This command front-loads your understanding so you don't waste tokens rediscovering the codebase.

## Step 1: Project structure

Run: `find . -maxdepth 3 -type f -name "*.md" -o -name "*.json" -o -name "*.toml" -o -name "*.yaml" -o -name "*.yml" | grep -v node_modules | grep -v .git | head -50`

Run: `ls -la` to see root directory contents.

## Step 2: Read key files (in this order)

1. **CLAUDE.md** or **.claude/CLAUDE.md** — project instructions
2. **README.md** — project overview
3. **PRD.md** — product requirements (if exists)
4. **.claude/handover.md** — session state from last handover (if exists)
5. **package.json** / **pyproject.toml** / **Cargo.toml** — dependencies and scripts
6. **.env.example** — required environment variables

## Step 3: Understand the codebase shape

Run: `find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" -o -name "*.rs" -o -name "*.go" -o -name "*.c" -o -name "*.h" \) | grep -v node_modules | grep -v .git | grep -v __pycache__ | head -80`

Identify:
- Entry points (main, index, app, server)
- API routes
- Database models/schemas
- Key components/modules
- Test files and patterns

## Step 4: Git state

```bash
git branch --show-current
git log --oneline -10
git status
```

## Step 5: Summarize

Present a brief summary:
```
Project: [name]
Stack: [languages, frameworks, databases]
Structure: [monorepo/single-app, key directories]
Current branch: [branch] — [what's in progress based on recent commits]
Key files: [the most important files to know about]
Ready to work on: [what seems like the next task]
```

Then ask: "What would you like to work on?"

## Rules
- Do NOT write any code during this phase
- Do NOT modify any files
- This is read-only reconnaissance
