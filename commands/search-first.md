Before building anything custom, search for existing solutions. This prevents reinventing wheels and ensures we adopt battle-tested code when it exists.

## What to search for
$ARGUMENTS

If no arguments, infer from the current conversation context — what is the user about to build?

## Step 1: Define the need

In one sentence, what capability do we need? Be specific:
- NOT: "we need authentication"
- YES: "we need OAuth 2.0 login with Google and GitHub providers for a Next.js 15 app with JWT session management"

List the hard requirements:
- Language/framework compatibility
- License requirements (MIT, Apache, no GPL?)
- Must-have features
- Nice-to-have features
- Performance requirements
- Bundle size constraints (for frontend)

## Step 2: Search across sources (parallel)

Search ALL of these — don't stop at the first result:

### Package registries
- **npm** (for JS/TS): web search `npm [capability] [framework]`
- **PyPI** (for Python): web search `pypi [capability]`
- **crates.io** (for Rust): web search `crates.io [capability]`

### MCP servers
- Search for MCP servers that provide this capability: web search `MCP server [capability]`
- Check if Context7 has docs for relevant libraries

### GitHub
- Web search `github [capability] [language] stars:>100`
- Look for actively maintained repos (commits in last 3 months)

### Existing codebase
- Grep the current project — does something similar already exist?
- Check if a dependency already provides this (many libraries have sub-features people don't know about)

## Step 3: Evaluate candidates

For each candidate, score on these criteria:

```
## [Package/Library Name]

| Criteria | Score (1-5) | Notes |
|----------|-------------|-------|
| Functionality match | | Does it do what we need? |
| Maintenance | | Last commit, open issues, release cadence |
| Community | | Stars, downloads, Stack Overflow presence |
| Documentation | | Docs quality, examples, API reference |
| License | | Compatible with our project? |
| Bundle size | | Acceptable for our constraints? |
| Dependencies | | How many transitive deps? Any conflicts? |
| Type safety | | TypeScript types included/DefinitelyTyped? |
| **Total** | **/40** | |
```

## Step 4: Decide

Based on scores:

- **Score 32+** → **Adopt as-is.** Install the package, use it directly.
- **Score 24-31** → **Adopt and wrap.** Install but create a thin wrapper for our specific needs. This lets us swap later.
- **Score 16-23** → **Use as reference.** Read their code for patterns, but build our own implementation.
- **Score <16** → **Build custom.** Nothing suitable exists.

## Step 5: Report

```
## Search Results: [capability]

### Recommendation: [Adopt / Wrap / Reference / Build Custom]

### Best candidate: [name]
- Score: X/40
- Install: `npm install X` / `pip install X`
- Why: [1-2 sentences]
- Caveat: [any limitations]

### Runner-up: [name]
- Score: X/40
- Why not chosen: [reason]

### Decision
[Adopt/Wrap/Reference/Build] because [specific reasoning].
[If Build: what we learned from the search that informs our implementation]
```

## Rules

- **Always search before building.** Even if you're "pretty sure" nothing exists. You'd be surprised how often a well-maintained library does exactly what you need.
- **Prefer boring, popular packages over clever, niche ones.** 10K stars with monthly releases beats 200 stars with "last commit 8 months ago."
- **Check the dependency tree.** A package with 200 transitive dependencies is a supply chain risk.
- **License matters.** GPL in a commercial project is a legal problem. Check before adopting.
- **Wrapping is often the right answer.** Even a great library might change its API. A thin wrapper isolates you.
- **Search time is bounded.** Spend max 5 minutes searching. If nothing obvious appears, build custom.
