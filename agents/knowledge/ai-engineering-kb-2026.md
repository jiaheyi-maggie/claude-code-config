# AI Engineering Knowledge Base -- March 2026

This document provides a comprehensive, technically detailed reference for AI engineering as of March 2026. It covers protocols, frameworks, models, infrastructure, UX patterns, safety, and market landscape with specific version numbers, API patterns, pricing, and benchmarks.

---

## Table of Contents

1. [MCP (Model Context Protocol) Integration Patterns](#1-mcp-model-context-protocol)
2. [AI Agent Architectures in Production](#2-ai-agent-architectures)
3. [AI Coding Assistants Landscape](#3-ai-coding-assistants)
4. [Compound AI Systems](#4-compound-ai-systems)
5. [AI Infrastructure](#5-ai-infrastructure)
6. [AI UX Patterns](#6-ai-ux-patterns)
7. [AI Startup Trends](#7-ai-startup-trends)
8. [Latest Model Capabilities](#8-model-capabilities)
9. [AI Safety and Governance](#9-ai-safety-and-governance)
10. [Emerging Patterns](#10-emerging-patterns)

---

## 1. MCP (Model Context Protocol)

### Protocol Overview

MCP is an open protocol (created by Anthropic, now governed by a multi-stakeholder community) that standardizes how LLM applications connect to external tools and data sources. Think of it as "USB-C for AI" -- a universal plug between AI models and the systems they interact with.

**Spec version**: 2025-11-25 (latest stable), with a draft spec for the next release
**Governance**: Working Groups, Spec Enhancement Proposals (SEPs), documented contributor ladder
**Adoption**: OpenAI, Microsoft, Google, Amazon, and 150+ organizations now support MCP

### Transport Layer

**Three transport modes:**

| Transport | Use Case | Scaling |
|-----------|----------|---------|
| **stdio** | Local tools, IDE plugins, CLI agents | Single process, no network |
| **SSE (Server-Sent Events)** | Legacy remote servers | Stateful, harder to scale |
| **Streamable HTTP** (recommended) | Production remote servers | Stateless, horizontally scalable |

Streamable HTTP (introduced spec version 2025-03-26) is the modern standard for remote MCP servers. It enables MCP servers to run as regular HTTP services behind load balancers without sticky sessions.

**Key challenge**: The 2026 roadmap focuses on evolving the session model so servers can scale horizontally without holding state. Stateful sessions currently fight with load balancers.

### Discovery and Registry

**MCP Server Cards** (SEP-1649): Servers expose structured metadata at `/.well-known/mcp/server-card.json`. This enables:
- Autoconfiguration: clients can discover server capabilities before connecting
- Registry crawling: the MCP Registry can index servers automatically
- Security validation: clients can inspect auth requirements statically
- UI hydration: IDEs can show tool listings without full initialization

**MCP Registry**: An open catalog and API for discovering publicly available MCP servers (preview since September 2025). Servers self-publish to the OSS MCP Community Registry, and listings automatically appear in the GitHub MCP Registry.

**Registry hierarchy**:
```
MCP Community Registry (canonical source of truth)
  |
  +-- GitHub MCP Registry (auto-synced)
  +-- Client-specific sub-registries (Cursor, Claude, etc.)
  +-- Enterprise registries (private, behind SSO)
```

**Status** (March 2026): SEP-1649 (server cards) and SEP-1960 (manifest at `/.well-known/mcp`) are active proposals with broad support, targeting June 2026 spec release.

### Authentication and Authorization

MCP uses **OAuth 2.1** for authorization of remote servers.

**Architecture**:
```
MCP Client --> Authorization Server (Okta, Auth0, Keycloak)
                     |
                     v (issues scoped tokens)
MCP Client --> MCP Server (validates bearer tokens)
```

**Key design decisions**:
- MCP servers are **OAuth Resource Servers** (they validate tokens, never issue them)
- Servers publish **Protected Resource Metadata** at `/.well-known/oauth-protected-resource` (RFC 9728)
- Clients must implement **Resource Indicators** (RFC 8707) -- tokens are scoped to a specific MCP server
- **Dynamic Client Registration (DCR)** is required -- each client registers a fresh OAuth client_id
- **PKCE** (Proof Key for Code Exchange) is mandatory for all token exchanges

**Enterprise patterns**:
- SSO integration via standard OAuth/OIDC flows
- Gateway-based auth: enterprise MCP gateways (e.g., `mcp-gateway-registry`) centralize tool access with Keycloak/Entra integration
- Audit trails: gateway logs all tool invocations with user identity, timestamp, tool name, parameters

### Tool Approval Patterns

**How clients handle tool approval**:

| Client | Approval Model |
|--------|---------------|
| Claude Code | Per-tool allow/deny in `~/.claude/settings.json`, session-level permissions |
| Cursor | MCP tools appear alongside native tools, configurable per-project |
| Windsurf | Cascade agent integrates MCP tools with approval flow |
| Claude.ai | Server-side tool approval, admin-configured |

**Production integration patterns**:

1. **Pre-baked servers**: Tools bundled with the application, configured at deploy time. Example: a customer support app with Zendesk + Stripe MCP servers always available.
2. **Dynamic discovery**: Client discovers servers at runtime via registry lookup or `.well-known` endpoints. Used for marketplace-style tool selection.
3. **Gateway pattern**: Enterprise deploys a single MCP gateway that proxies to internal MCP servers, handling auth, rate limiting, audit logging centrally.

### Building MCP Servers

**Recommended frameworks**:
- **Python**: `mcp` SDK (`pip install mcp`) -- official Anthropic SDK
- **TypeScript**: `@modelcontextprotocol/sdk` -- official SDK
- **FastMCP** (`pip install fastmcp`) -- higher-level Python framework with decorator-based tool definitions
- **Cloudflare Workers** -- deploy MCP servers as edge functions with built-in OAuth

**Example FastMCP server**:
```python
from fastmcp import FastMCP

mcp = FastMCP("Demo")

@mcp.tool()
def add(a: int, b: int) -> int:
    """Add two numbers"""
    return a + b

# Deploy via: fastmcp run server.py --transport http --port 8000
```

---

## 2. AI Agent Architectures

### Production Agent Patterns

**Dominant patterns in production (March 2026)**:

| Pattern | Description | When to Use | Cost Profile |
|---------|-------------|-------------|--------------|
| **ReAct** | Interleaved reasoning + action | General-purpose, most agent tasks | Moderate |
| **Plan-and-Execute** | Planner model creates strategy, executor models carry out steps | Complex multi-step tasks, cost optimization | Low (90% cost reduction: cheap models execute) |
| **Multi-Agent** | Multiple specialized agents collaborate | 3+ independent workstreams, <20% file overlap | High (3-4x single agent) |
| **Hierarchical** | Lead agent delegates to worker agents | Large-scale orchestration, parallel work | High |
| **Reflection** | Agent reviews and critiques its own output | Quality-critical tasks, self-improvement | Moderate |
| **Tool Use** | LLM selects and invokes tools | API integration, data retrieval | Low-moderate |

**Key insight**: While nearly two-thirds of organizations are experimenting with AI agents, fewer than one in four have successfully scaled them to production.

### Framework Comparison (March 2026)

#### LangGraph
- **Philosophy**: Explicit state machines with graph-based control flow
- **Killer feature**: Durable Execution -- if an agent crashes mid-execution, it resumes from the last checkpoint
- **Best for**: Complex stateful orchestration, long-running workflows, production reliability
- **GitHub**: 10K+ stars, active development
- **Production readiness**: Highest -- async execution, error recovery, observability built in
- **Persistence**: First-class checkpointing and state persistence
- **MCP support**: Yes, via LangChain tool integration

#### CrewAI
- **Philosophy**: Role-based agent teams with natural language configuration
- **Killer feature**: Idea-to-production in under a week -- abstraction minimizes setup
- **Best for**: Content generation, research, analysis, rapid prototyping
- **GitHub**: 44,600+ stars, v1.10.1 with native MCP and A2A support
- **Production readiness**: Good but less mature monitoring tooling
- **Pricing**: Open source core, CrewAI Enterprise for production

#### OpenAI Agents SDK
- **Philosophy**: Lightweight, provider-agnostic multi-agent framework
- **Core primitives**: Agents, Tools, Handoffs, Guardrails
- **Handoffs**: Represented as tools to the LLM (e.g., `transfer_to_refund_agent`), enabling agent delegation
- **Guardrails execution modes**:
  - Parallel (default): guardrail + agent run concurrently, fail-fast if check fails
  - Blocking: guardrail completes before agent starts, prevents token waste
- **Sessions**: Persistent memory layer for context within an agent loop
- **Built-in tracing**: Visualization, debugging, monitoring of workflows
- **Provider support**: OpenAI Responses/Chat Completions + 100+ LLMs via adapter

#### Pydantic AI
- **Philosophy**: Type-safe agent development, "the Pydantic way"
- **Killer feature**: Type safety catches agent logic errors at development time, not runtime
- **Durable Execution**: Preserves progress across API failures and restarts
- **Protocol support**: MCP, A2A, AG-UI -- all integrated
- **Graph definition**: Define agent graphs using type hints for complex workflows
- **Observability**: Seamless Pydantic Logfire integration for tracing and cost tracking
- **Best for**: Production Python teams who value type safety and clean architecture

#### AutoGen (Microsoft)
- **Philosophy**: Conversational multi-agent patterns
- **Best for**: Research, experimentation, Microsoft ecosystem integration
- **Production readiness**: Good -- async execution, error recovery
- **AG-UI support**: Native AG-UI protocol support via AG2

**Decision framework**:
```
Need reliable, long-running workflows? --> LangGraph
Need fast team assembly for content/research? --> CrewAI
Need lightweight multi-agent with guardrails? --> OpenAI Agents SDK
Need type-safe Python with clean architecture? --> Pydantic AI
Need Microsoft ecosystem integration? --> AutoGen/AG2
```

### Agent Memory Systems

**Memory types in production agents**:

| Type | Scope | Storage | Example |
|------|-------|---------|---------|
| **Short-term** | Single conversation | In-context window | Chat history |
| **Episodic** | Cross-conversation | Vector DB + graph | "Last time user asked about X..." |
| **Semantic** | Domain knowledge | Vector DB | Product documentation, FAQs |
| **Procedural** | Learned behaviors | Code/config | "When user says X, do Y" |

**Memory framework comparison (March 2026)**:

| Framework | Architecture | Best For | Pricing |
|-----------|-------------|----------|---------|
| **Mem0** | Bolt-on memory layer for any agent | Adding memory to existing agents quickly | Free OSS; Pro $249/mo for graph memory |
| **Zep / Graphiti** | Episodic + temporal graph memory | Tracking changes over time, temporal queries | Cloud-hosted |
| **Letta (MemGPT)** | Full agent runtime with OS-inspired memory tiers | Building agent-native apps from scratch | OSS + cloud |
| **LangMem** | LangChain-native memory | LangGraph workflows | Part of LangChain ecosystem |
| **Claude-Mem** | Anthropic-native memory | Claude-based agents | Built into Claude |

**Letta's tiered memory model** (most sophisticated):
- **Core memory**: Always in context window (system prompt, user profile)
- **Archival memory**: Searchable long-term vector store (agent explicitly saves/retrieves)
- **Recall memory**: Conversation history (auto-managed, paginated)

### Agent Communication Protocols

**The 2026 protocol stack**:

| Protocol | Purpose | Governs | Status |
|----------|---------|---------|--------|
| **MCP** | Agent-to-Tool | How agents invoke external tools and access data | Production (v2025-11-25) |
| **A2A** | Agent-to-Agent | How agents discover and communicate with each other | Production (v0.3, Linux Foundation) |
| **AG-UI** | Agent-to-User Interface | How agents stream results to frontends | Production (AWS Bedrock support) |
| **A2UI** | Agent-to-User Interface (Google) | Google's variant of agent UI protocol | Early adoption |

**A2A (Agent2Agent)**:
- Launched by Google, donated to Linux Foundation, 150+ supporting organizations
- Agents advertise capabilities via **Agent Cards** (JSON format)
- Client agent discovers remote agent, sends tasks, receives results
- v0.3 adds gRPC support, security card signing, extended Python SDK
- Modality-agnostic: supports text, audio, and video streaming

**AG-UI (Agent-User Interaction Protocol)**:
- Event-based protocol for streaming agent actions to frontends
- Transports: Server-Sent Events (SSE) and WebSocket
- Events: text chunks, reasoning steps, tool call results, state updates
- Amazon Bedrock AgentCore Runtime added AG-UI support (March 2026)
- CopilotKit is the primary framework implementing AG-UI
- Pydantic AI, AG2, and others have native AG-UI support

---

## 3. AI Coding Assistants

### Landscape Overview (March 2026)

The market has consolidated into three categories: **IDE-native agents**, **terminal agents**, and **autonomous cloud agents**.

### IDE-Native Agents

#### Cursor
- **Users**: 1M+, 360K+ paying customers
- **Architecture**: VS Code fork with deep AI integration
- **Key features**: Background Agents (cloud sandbox), Automations (event-triggered agents), parallel subagents, Tab completion
- **Automations**: Always-on agents triggered by Slack, Linear, GitHub, PagerDuty, webhooks. 35% of Cursor's internal PRs are created by background agents.
- **Pricing**: Hobby (free, limited), Pro ($20/mo), Business ($40/seat/mo), Ultra ($200/mo with max-mode)
- **Differentiation**: Strongest agentic IDE with cloud execution. Hundreds of automations run per hour.
- **MCP support**: Yes, per-project configuration

#### Windsurf
- **Ranking**: #1 in LogRocket AI Dev Tool Power Rankings (February 2026)
- **Architecture**: VS Code fork with Cascade agent
- **Key features**: Cascade (multi-step agent), 5 parallel agents, competitive with Cursor Composer
- **Pricing**: Free tier (genuinely useful), Pro $15/mo (undercuts Cursor by 25%)
- **Differentiation**: Best value-for-money in agentic IDE category. Free tier is actually usable.

#### GitHub Copilot
- **Architecture**: IDE extension (VS Code, JetBrains, Neovim, etc.)
- **Key features**: Code completion, chat, Copilot Workspace (agent), multi-model support
- **Pricing**: Free (2K completions/mo), Pro $10/mo (unlimited completions), Pro+ $39/mo
- **Differentiation**: Cheapest paid entry point. Ubiquitous. Best for autocomplete. Weaker agentic capabilities.
- **Agent mode**: Available but less capable than Cursor/Windsurf agents

#### Kiro (AWS)
- **Architecture**: VS Code fork, spec-driven AI IDE
- **Powered by**: Claude Sonnet (Anthropic)
- **Killer feature**: Spec-first development -- generates requirements.md with user stories using EARS syntax before writing code
- **Agent Hooks**: Automation system that triggers actions (regenerate tests, update docs) on file save
- **Pricing**: Free (50 interactions/mo), Pro $19/mo
- **Languages**: Python and JavaScript (more planned)
- **Differentiation**: Only IDE that enforces spec-before-code workflow. Strong for teams that value planning.

### Terminal Agents

#### Claude Code
- **Architecture**: Terminal-native agentic tool (not an IDE fork)
- **Model**: Claude Opus 4.6 (1M context, 128K output)
- **Key features**: Agent Teams (multi-agent orchestration), subagents, MCP integration, computer use, CLAUDE.md configuration
- **Agent Teams** (February 2026): One session acts as team lead, teammates work independently in their own context windows, can communicate directly with each other (not just through lead)
- **Subagents vs Agent Teams**: Subagents run within a single session and can only report back. Agent Teams can share findings, challenge each other, coordinate autonomously.
- **Spawning**: Teammates spawn within 20-30 seconds, produce results within first minute
- **Cost**: 3-4x tokens of single session for 3-teammate team
- **Differentiation**: Best for complex tasks requiring deep codebase understanding. 1M token context handles large-scale refactors. Only tool with Agent Teams for competitive debugging.

#### Gemini CLI
- **Architecture**: Open-source terminal agent using Gemini models
- **Install**: `npm install -g @google/gemini-cli`
- **Model**: Gemini 2.5 Pro (free with Google account, 60 RPM), Gemini 3 with 1M context
- **Key features**: Plan Mode (March 2026), Google Search grounding, MCP support, ReAct loop
- **Pricing**: Free tier is the best in class -- 60 requests/minute on Gemini 2.5 Pro
- **Differentiation**: Best free terminal agent. Google Search grounding for up-to-date information.

#### Aider
- **Architecture**: Open-source terminal pair programming tool
- **Model support**: Any LLM (Claude, GPT, Gemini, local models via Ollama)
- **Key features**: Repo-map for codebase understanding, auto-commits with sensible messages, linter/test integration, 100+ language support
- **Pricing**: BYOK (bring your own key), no subscription, no markup
- **Differentiation**: Most flexible -- works with any model, any project. Best for developers who want full control.

#### OpenAI Codex CLI
- **Architecture**: Terminal agent with cloud sandbox execution
- **Execution modes**: Local (in project dir), Worktree (isolated git worktree), Cloud (OpenAI containers)
- **Differentiation**: Fire-and-forget cloud execution for autonomous tasks

### VS Code Extensions

#### Cline
- **Installs**: 5M+ VS Code installs (most adopted open-source coding extension)
- **Architecture**: Autonomous agent with Plan/Act modes, MCP integration, browser use
- **Key features**: BYOM (Bring Your Own Model), no markup on API costs, diff/command approval before execution
- **Differentiation**: Fully open-source, local-first, zero vendor lock-in. Works with any model including local.

### Autonomous Cloud Agents

#### Devin (Cognition)
- **Architecture**: Fully sandboxed cloud environment with own IDE, browser, terminal, shell
- **Integration**: Accepts tasks via Slack, Microsoft Teams
- **Performance**: 67% PR merge rate on well-defined tasks (migrations, upgrades). ~85% failure rate on complex/ambiguous tasks.
- **Pricing**: Usage-based, premium
- **Differentiation**: Most autonomous -- assign task, get PR. Best for repetitive, well-defined tasks.

#### Augment Code / Intent
- **Architecture**: Multi-agent coordination on local git worktrees with living specifications
- **Key feature**: Living spec acts as shared, continuously updated plan that keeps multiple agents aligned
- **Differentiation**: Best multi-agent coordination for team codebases

### Multi-Agent is Table Stakes

In February 2026, every major tool shipped multi-agent in the same two-week window:
- Grok Build: 8 agents
- Windsurf: 5 parallel agents
- Claude Code: Agent Teams
- Codex CLI: Agents SDK integration
- Devin: Parallel sessions
- Cursor: Cloud background agents

### Recommended Stack (March 2026)

Most professional developers combine tools:
1. **GitHub Copilot** for autocomplete (cheap, ubiquitous)
2. **Cursor or Claude Code** for complex tasks (IDE vs terminal preference)
3. **Codex or Devin** for autonomous fire-and-forget work

---

## 4. Compound AI Systems

### RAG in Production

**The #1 cause of RAG failures** (80% of cases) traces to the ingestion and chunking layer, not the LLM.

#### Chunking Strategies

| Strategy | When to Use | Typical Chunk Size |
|----------|-------------|-------------------|
| **Fixed-size** | Default starting point, structured text | 256-512 tokens with 10-20% overlap |
| **Sentence-aware** | Prose, articles, documentation | Variable, respects sentence boundaries |
| **Semantic** | Unstructured text with messy boundaries | Variable, splits on topic shifts |
| **Document-aware** | Structured docs (tables, headers, code) | Respects document structure |
| **Hierarchical** | Production default (recommended) | Parent chunks (512-1024) + child chunks (128-256) |

**Production default**: Start with **hierarchical chunking + hybrid search + reranking**. This is the most robust configuration for production systems.

#### Retrieval Architecture

```
Query --> [Keyword Search (BM25)] --> Candidate Set (20-50 docs)
      |                                     |
      +--> [Vector Search (embeddings)] ----+
                                            |
                                            v
                                    [Reranker] --> Top 5 docs --> LLM
```

**Hybrid search with reranking achieves 66.43% MRR** vs 56.72% for semantic-only (+9.3 percentage points).

**Key rules for production RAG**:
- **Retrieve more than you return**: Retrieve 20 candidates, rerank, return top 5 to the LLM
- **Keep assembled context under 8K tokens** for most queries. If consistently hitting limit, reranking threshold is too loose.
- **Make retrieval observable**: Log query, retrieved chunk IDs, and filters applied. Separate retrieval failure from generation failure.
- **Context Precision**: What fraction of retrieved chunks were actually relevant
- **Context Recall**: Whether the retrieved set contained all information needed to answer

#### Embedding Models (March 2026)

| Model | Dimensions | Max Tokens | Best For |
|-------|-----------|------------|----------|
| OpenAI `text-embedding-3-large` | 3072 | 8191 | General purpose, highest quality |
| OpenAI `text-embedding-3-small` | 1536 | 8191 | Cost-optimized |
| Cohere `embed-v4` | 1024 | 512 | Multilingual, search |
| Voyage AI `voyage-3` | 1024 | 32000 | Long documents |
| Jina `jina-embeddings-v3` | 1024 | 8192 | Open-source alternative |

#### Vector Databases

| Database | Best For | Managed Option |
|----------|----------|---------------|
| **pgvector** (PostgreSQL) | <10M vectors, existing Postgres infrastructure | Supabase, Neon |
| **Pinecone** | Managed, serverless, large scale | Pinecone Serverless |
| **Weaviate** | Hybrid search, multi-modal | Weaviate Cloud |
| **Qdrant** | High performance, filtering | Qdrant Cloud |
| **Chroma** | Local development, prototyping | ChromaDB Cloud |
| **Milvus** | Very large scale (billions of vectors) | Zilliz Cloud |

### Fine-Tuning vs RAG vs Prompt Engineering

**Decision framework**:

```
Does your data change frequently (weekly+)?
  YES --> RAG (retrieval keeps context current)
  NO  --> Does the model need different behavior (tone, format, domain)?
            YES --> Fine-tuning (changes how the model behaves)
            NO  --> Is knowledge base < 200K tokens?
                      YES --> Full-context prompting + prompt caching
                      NO  --> RAG
```

**Key mental model**: RAG changes what the model can see right now. Fine-tuning changes how the model tends to behave every time.

**2026 best practice: Hybrid**. Use retrieval for facts, fine-tuning for style/policy/decision behavior.

**Cost escalation ladder**:
1. **Prompt engineering**: Hours/days of effort, zero infrastructure cost
2. **RAG**: $70-1000/month for vector DB + embedding API
3. **Fine-tuning**: Months of effort + 6x inference cost (dedicated compute)

### Evaluation Frameworks

| Framework | Type | Differentiator | Pricing |
|-----------|------|---------------|---------|
| **Braintrust** | Commercial | CI/CD quality gates (blocks merge on eval failure), AI-assisted scorer generation, production traces become test cases | Usage-based |
| **Langfuse** | Open-source + Cloud | Self-hostable, observability-first, LLM-as-a-judge support | Free OSS; Cloud plans available |
| **Arize Phoenix** | Commercial + OSS | Real-time monitoring, drift detection, production debugging | Free tier; Enterprise plans |
| **DeepEval** | Open-source | 14+ metrics (faithfulness, hallucination, toxicity), CI/CD integration | Free OSS |
| **Maxim AI** | Commercial | Comprehensive evaluation + observability platform | Enterprise pricing |

**Braintrust vs Langfuse**: Braintrust blocks bad merges automatically in CI/CD. Langfuse requires manual review. Choose Braintrust for automated quality gates; choose Langfuse for open-source control and self-hosting.

**Observability stack**:
- **Tracing**: Captures LLM calls, tool invocations, retrieval steps as structured spans
- **Key metrics**: Token-level costs, step-level latency, error rates, evaluation scores
- **Production pattern**: Log every LLM call with input/output/tokens/latency/cost, sample for detailed tracing

### Structured Output

**Three levels of reliability**:

| Level | Method | Success Rate | Use When |
|-------|--------|-------------|----------|
| 1 | Prompt engineering ("respond in JSON") | 80-95% | Prototyping only |
| 2 | Function calling / tool use | 95-99% | Most production use |
| 3 | Native structured output | 100% schema-valid | Critical production paths |

**Level 3 is the 2026 standard**. Every major provider now offers it:
- **OpenAI**: `response_format={"type": "json_schema", "json_schema": {...}}` or `.parse()` method
- **Anthropic**: Tool use with strict JSON schema
- **Google**: `response_schema` parameter in Gemini API
- **Open-source**: Outlines, Instructor, or vLLM's guided decoding

**Always validate with Pydantic (Python) or Zod (TypeScript)** even when provider guarantees schema compliance. Business logic validation catches what JSON Schema cannot.

**Production pitfalls**: Complex schemas are expensive (more constrained tokens = slower). Break into smaller, parallelized calls. Handle refusals, truncation, empty arrays, and enum confusion.

### Function Calling Best Practices

1. **Keep tool descriptions concise but precise** -- the model reads them every call
2. **Use enums over free-text parameters** where possible
3. **Return structured errors, not exceptions** -- the model needs to reason about failures
4. **Limit to 10-20 tools** per agent context -- too many degrades selection accuracy
5. **Use Tool Search** (Anthropic) or function selection layers for 100+ tools
6. **Validate tool inputs server-side** -- never trust LLM-generated parameters
7. **Log every tool call** with input/output/duration for debugging and evaluation

---

## 5. AI Infrastructure

### Model Serving

#### Production Serving Frameworks

| Framework | Best For | Key Feature | Scale |
|-----------|----------|-------------|-------|
| **vLLM** | Production GPU serving | PagedAttention, continuous batching, speculative decoding | Enterprise-scale |
| **TGI (Text Generation Inference)** | Hugging Face ecosystem | Flash Attention, quantization, Hugging Face integration | Medium-large |
| **SGLang** | High-throughput serving | RadixAttention, efficient KV cache management | Research-to-production |
| **Ollama** | Local/development | One-command model pull and run, Docker-like UX | Single machine |
| **LM Studio** | Desktop GUI | Visual model management, chat UI | Single machine |
| **TensorRT-LLM** | NVIDIA GPUs (maximum performance) | NVIDIA-optimized kernels, quantization | Enterprise |

**Ollama** has become the "Docker for LLMs" -- the default development tool for local inference.
- Install: `curl -fsSL https://ollama.com/install.sh | sh`
- Run: `ollama run llama4`
- Performance: 20-50 tok/s CPU, 80-200 tok/s GPU for 7B models
- RAM: 8GB minimum for 7B models
- **Ollama Cloud** (public beta January 2026): `ollama serve --cloud` for globally distributed inference endpoints

### Inference Optimization

#### Speculative Decoding
Now a production standard in vLLM, SGLang, and TensorRT-LLM. A small "draft" model generates K candidate tokens in one forward pass; the large "target" model verifies them in parallel.

- **P-EAGLE** (Parallel Speculative Decoding): Integrated into vLLM v0.16.0+, generates K draft tokens in a single forward pass
- **Typical speedup**: 2-3x on latency-sensitive workloads
- **Stacks with quantization**: AMD MI300X benchmarks show 3.6x total improvement combining FP8 quantization + speculative decoding on Llama 3.1-405B

#### Quantization
- **FP8**: Production standard for large models, minimal quality loss
- **NVFP4**: NVIDIA's 4-bit format, available for Nemotron-3-Super on Hugging Face
- **GPTQ/AWQ**: 4-bit quantization for consumer GPUs
- **GGUF**: Ollama's quantization format for CPU/edge inference

**Cost impact**: Combining speculative decoding + FP8 quantization achieves 84% lower cost per serving in prefill-heavy scenarios.

#### KV Cache Optimization
- **PagedAttention** (vLLM): Manages KV cache like virtual memory pages, reducing waste by 60-80%
- **RadixAttention** (SGLang): Reuses KV cache across requests sharing common prefixes

### Inference Providers (Pricing, March 2026)

#### Frontier Model APIs

| Provider | Model | Input $/1M tok | Output $/1M tok | Context |
|----------|-------|----------------|-----------------|---------|
| Anthropic | Claude Opus 4.6 | $15 | $75 | 1M |
| Anthropic | Claude Sonnet 4.6 | $3 | $15 | 1M |
| OpenAI | GPT-5.4 | $2.50 | $15 | 128K |
| OpenAI | GPT-4.1 | $2 | $8 | 1M |
| OpenAI | o3 (reasoning) | $2 | $8 | 200K |
| OpenAI | o4-mini (reasoning) | $1.10 | $4.40 | 200K |
| Google | Gemini 3.1 Pro | $2 | $12 | 1M |
| Google | Gemini 2.5 Flash | $0.15 | $0.60 | 1M |

**Cost optimization levers**:
- **Prompt caching**: OpenAI GPT-4.1 cached input at $0.50/1M (75% discount)
- **Batch API**: 50% flat discount on all token costs (input + output) across all OpenAI models
- **Anthropic prompt caching**: Write $3.75/1M, read $0.30/1M for Sonnet 4.6

#### Open-Source Model Inference

| Provider | Specialty | Pricing Model | Key Feature |
|----------|-----------|---------------|-------------|
| **Together AI** | Budget open-source | LoRA fine-tuning from $0.48/1M | Best budget option for open-source |
| **Fireworks AI** | Ultra-fast inference | Free at 10 RPM; paid tiers | ~747 TPS, 0.17s latency |
| **Groq** | Fastest inference | Free tier available | Groq LPU, lowest latency |
| **Cerebras** | Wafer-scale inference | Enterprise | Fastest raw inference speed |
| **Nebius** | European infrastructure | Competitive pricing | EU data residency |

**NVIDIA Blackwell impact**: Together AI and Fireworks AI report up to 10x cost per token reduction using Blackwell GPUs vs Hopper.

### Local vs Cloud Decision Framework

```
Data privacy requirements?
  STRICT (regulated, PII) --> Local inference (Ollama/vLLM + open-source model)
  FLEXIBLE --> Latency requirements?
    < 100ms --> Local or edge inference
    > 100ms acceptable --> Cloud API
      Budget-sensitive? --> Open-source model via Together/Fireworks
      Quality-critical? --> Frontier model API (Claude/GPT/Gemini)
```

**Hybrid pattern** (emerging as default in 2026):
- Local Ollama for development and testing
- Open-source via Fireworks/Together for cost-sensitive production
- Frontier APIs (Claude/GPT) for quality-critical paths
- Prompt caching + batch API for cost optimization on frontier models

---

## 6. AI UX Patterns

### Beyond Chat: The 2026 Interface Taxonomy

Research shows users struggle to form effective queries in chat-only interfaces and miss important details in the chat stream. The future is multi-modal interfaces combining chat, embedded AI, and ambient AI.

| Pattern | Description | Best For | Example |
|---------|-------------|----------|---------|
| **Chat** | Conversational back-and-forth | Open-ended tasks, exploration | ChatGPT, Claude.ai |
| **Embedded AI** | AI integrated into existing workflows | Autocomplete, inline suggestions | Copilot in VS Code |
| **Ambient AI** | AI that acts proactively without prompting | Background monitoring, automated tasks | Cursor Automations |
| **Generative UI** | AI generates custom UI components | Data visualization, dynamic forms | Vercel v0, Artifacts |
| **Command palette** | AI-powered command execution | Power users, keyboard-first workflows | Claude Code |

### Agentic UX Design Patterns

1. **Governor Pattern**: Human-in-the-loop feedback loop -- AI proposes, human approves. Maintains user's sense of ownership while leveraging AI capabilities.

2. **Progressive Disclosure**: Start with simple output, let users drill into reasoning steps, tool calls, intermediate results.

3. **Milestone Markers**: Show progress through multi-step agent workflows. Users need to see where the agent is, not just the final result.

4. **Dynamic Blocks**: Content that updates in real-time as the agent works -- progress bars, live code diffs, streaming tool results.

5. **Confidence Indicators**: Signal to users when AI is certain vs uncertain. Reduce over-trust and under-trust.

6. **Approval Flows**: Show steps the agent will take before executing. Critical for destructive operations (file edits, API calls, deployments).

### UI Component Libraries

#### Vercel AI SDK
- **Downloads**: 20M+ monthly
- **Architecture**: TypeScript toolkit with React hooks (`useChat`, `useCompletion`, `useObject`)
- **AI SDK 6**: Latest version with enhanced streaming and tool use support
- **AI Elements**: Open-source React components (built on shadcn/ui) -- message threads, input boxes, reasoning panels, response actions
- **Install**: `npm install ai @ai-sdk/openai`

#### CopilotKit
- **Adoption**: 10%+ of Fortune 500 companies
- **Architecture**: Agentic application framework with AG-UI protocol support
- **Key feature**: Connect any LLM or agent framework to React frontends
- **Best for**: Adding AI copilot features to existing applications

#### assistant-ui
- **Architecture**: Lightweight React components for chat interfaces
- **Best for**: Brownfield projects where architecture already exists
- **Less friction than CopilotKit/Vercel for existing apps**

#### Deep Chat
- **Architecture**: Web component (framework-agnostic)
- **Best for**: Quick integration regardless of frontend framework

**Decision**: Heavy frameworks (CopilotKit, Vercel) accelerate greenfield. Thin layers (assistant-ui, Deep Chat) cause less friction on brownfield.

### Streaming Implementation

**Table stakes for 2026 AI UIs**:
- Token-by-token streaming without UI glitches
- Markdown + code blocks with syntax highlighting
- Auto-growing composer textarea
- Reasoning trace display (collapsible thinking steps)
- Tool execution visualization (show what tools are being called)
- Cost transparency (show token usage)
- Interrupt/cancel mid-stream
- Approval flows for agent actions

---

## 7. AI Startup Trends

### Funding Landscape (March 2026)

- AI startups attract **33% of total VC funding**
- 17 US AI companies raised $100M+ in 2026 so far; three crossed $1B
- VCs predict enterprises will spend more on AI in 2026 through **fewer vendors** (consolidation)

### Top Investment Categories

| Category | CAGR | Share of Funding | Signal |
|----------|------|-----------------|--------|
| **Foundation Models & Infrastructure** | -- | $80B+ (2025) | OpenAI + Anthropic absorbed $140B in Q1 alone |
| **Autonomous AI Agents** | 41% | 40%+ enterprise budgets | Moving beyond chatbots to action-taking |
| **Developer Tools** | -- | 20% of new startups | AI coding tools growing fastest, rapid ARR |
| **Enterprise/Vertical AI** | -- | 40%+ of funding | Healthcare, legal, enterprise workflows |
| **Humanoid Robotics** | -- | Large rounds | Figure AI (Amazon), SkildAI ($1.4B Series C) |
| **AI Safety** | -- | Growing | Becoming table stakes, not optional |

### "Picks and Shovels" Opportunities

The AI infrastructure layer -- the platforms that make AI cheaper and faster to deploy:

1. **Inference infrastructure**: GPU cloud (CoreWeave, Lambda, Nscale at $2B raise/$14.6B valuation)
2. **Evaluation and observability**: Braintrust, Langfuse, Arize
3. **Data infrastructure**: Unstructured.io, LlamaIndex, vector databases
4. **Security and guardrails**: Lakera (acquired by Check Point), LLM Guard
5. **Agent development platforms**: LangChain/LangSmith, CrewAI Enterprise
6. **Fine-tuning platforms**: Together AI, Fireworks AI

### Market Dynamics

- **Saturation**: Generic chatbot wrappers, basic RAG applications, simple prompt-engineering tools
- **White space**: Agent reliability/observability, multi-modal pipelines, domain-specific agents (legal, medical, financial), AI-native security
- **Consolidation signal**: Enterprise customers prefer fewer, more capable vendors over point solutions

---

## 8. Model Capabilities

### Frontier Models (March 2026)

#### SWE-Bench Verified Scores (coding benchmark)

| Rank | Model | Score | Notes |
|------|-------|-------|-------|
| 1 | Claude Opus 4.5 | 80.9% | Highest ever |
| 2 | Claude Opus 4.6 | 80.8% | 1M context, 128K output |
| 3 | Gemini 3.1 Pro | 80.6% | Native multimodal |
| 4 | MiniMax M2.5 | 80.2% | Open-weight! |
| 5 | GPT-5.2 | 80.0% | OpenAI flagship |
| 6 | Claude Sonnet 4.6 | 79.6% | Mid-tier, near-flagship |

**Key trend**: Top SWE-bench jumped from ~65% (early 2025) to 80.9% (March 2026). The scaffolding/agent framework matters as much as the model.

#### Claude Family (Anthropic)

| Model | Context | Max Output | Pricing (in/out per 1M) | Best For |
|-------|---------|-----------|------------------------|----------|
| Opus 4.6 | 1M | 128K | $15/$75 | Complex coding, agentic work, deep analysis |
| Sonnet 4.6 | 1M | 64K | $3/$15 | Balanced performance/cost, daily coding |
| Haiku 3.5 | 200K | 8K | $0.80/$4 | Fast responses, high-volume tasks |

**Opus 4.6 features**: Extended/adaptive thinking, Agent Teams, computer use, MCP integration, code execution, 120+ skills ecosystem

**Adaptive thinking** (`thinking: {type: "adaptive"}`): Claude dynamically decides when and how much to think. Recommended mode for both Opus 4.6 and Sonnet 4.6.

#### OpenAI Family

| Model | Context | Pricing (in/out per 1M) | Best For |
|-------|---------|------------------------|----------|
| GPT-5.4 | 128K | $2.50/$15 | Flagship general-purpose |
| GPT-5.4 Pro | 128K | $30/$180 | Maximum quality |
| GPT-4.1 | 1M | $2/$8 | Cost-effective with long context |
| o3 | 200K | $2/$8 | Deep reasoning |
| o4-mini | 200K | $1.10/$4.40 | Cost-effective reasoning |

**GPT-4.1**: Best cost/quality ratio in the OpenAI lineup with 1M context and 75% cache discount.

#### Google Family

| Model | Context | Pricing (in/out per 1M) | Best For |
|-------|---------|------------------------|----------|
| Gemini 3.1 Pro | 1M | $2/$12 | Price-performance king, native multimodal |
| Gemini 2.5 Flash | 1M | $0.15/$0.60 | Speed + cost optimization |

**Gemini 3.1 Pro**: Only frontier model with **native multimodal input** (text, image, audio, video in single model). Claude and GPT support image input but neither handles audio or video natively at the API level.

### Open-Source Models (March 2026)

The gap between open-source and proprietary models has **nearly closed** on most benchmarks.

#### Tier 1: Frontier-competitive

| Model | Parameters | Active | Context | Best For |
|-------|-----------|--------|---------|----------|
| **DeepSeek V3.2** | 685B | MoE | 128K | Best overall open-source; outperforms GPT-5 on reasoning |
| **DeepSeek V3.2-Speciale** | 685B | MoE | 128K | Math + coding; gold-medal IMO and IOI 2025 |
| **Qwen 3.5** | -- | -- | -- | Best multilingual; MMLU-Pro 87.8, GPQA Diamond 88.4 |
| **MiniMax M2.5** | -- | -- | -- | 80.2% SWE-bench (open-weight!) |

#### Tier 2: Production workhorses

| Model | Parameters | Context | Best For |
|-------|-----------|---------|----------|
| **Llama 4 Scout** | 109B (17B active) | 10M | Best for long context (10M window!) |
| **Llama 4 Maverick** | 400B (2x 8192 experts) | 1M | General purpose, MoE architecture |
| **Qwen3-Coder-Next** | 80B (3B active) | -- | Coding; on par with Claude Sonnet 4.5 on SWE-bench Pro |
| **Mistral Large 2** | -- | -- | Best for European deployment |

**Architectural note**: Llama 4 Maverick uses fewer but larger experts (2 active, 8192 hidden each) vs DeepSeek V3's many small experts (9 active, 2048 hidden each). Llama 4 alternates MoE and dense modules.

### What You Can Build Now That You Couldn't 6 Months Ago

1. **1M+ token context is standard**: Analyze entire codebases, long documents, multi-file refactors in a single context
2. **128K output tokens** (Opus 4.6): Generate entire applications, comprehensive documentation, full test suites in one call
3. **Multi-agent orchestration**: Agent Teams, parallel subagents, agent-to-agent communication (A2A) are production-ready
4. **Native multimodal** (Gemini 3.1): Process video + audio + text in a single API call
5. **10M token context** (Llama 4 Scout): Process book-length documents locally
6. **Open-source at frontier quality**: DeepSeek V3.2 beats GPT-5 on reasoning, runs on your own infrastructure
7. **Always-on AI agents**: Cursor Automations run continuously, triggered by events
8. **Browser and computer use**: Production-ready agents that navigate GUIs and web apps

---

## 9. AI Safety and Governance

### Threat Landscape (March 2026)

**Real-world incidents**:
- **Slack AI** (August 2024): Indirect prompt injection exfiltrated data from private channels
- **Salesforce Agentforce** "ForcedLeak" (September 2025): Malicious inputs leaked CRM data
- **UK NCSC** (December 2025): Formal assessment warning that prompt injection may **never** be fully mitigated

**Governance gap**: Only 20% of organizations have mature AI governance models (Deloitte 2026).

### Defense-in-Depth Architecture

```
Layer 1: Input Screening (pre-model)
  |
  +-- Prompt injection detection (Lakera Guard, LLM Guard, Arcjet)
  +-- PII detection and redaction
  +-- Content policy enforcement
  |
Layer 2: Model-Level Controls (at inference)
  |
  +-- System prompt hardening
  +-- Spotlighting (delimiting, datamarking, encoding)
  +-- Structured output enforcement
  +-- Tool permission boundaries
  |
Layer 3: Output Validation (post-model)
  |
  +-- Output scanning (factuality, toxicity, PII leakage)
  +-- Guardrails enforcement (NeMo Guardrails, Guardrails AI)
  +-- Human review for high-risk actions
  |
Layer 4: Runtime Monitoring (in production)
  |
  +-- Audit logging (who, what, when, with what parameters)
  +-- Anomaly detection
  +-- Rate limiting and circuit breakers
```

### Guardrails Frameworks

| Framework | Type | Key Feature | Latency |
|-----------|------|-------------|---------|
| **NeMo Guardrails** (NVIDIA) | OSS | Programmable rails via Colang DSL, 6 guardrail types | Variable |
| **Guardrails AI** | OSS + Commercial | Cross-LLM governance, validator hub | Variable |
| **Lakera Guard** (now Check Point) | Commercial | AI firewall, proprietary threat intelligence | <200ms |
| **LLM Guard** | OSS (MIT) | 15 input scanners, 20 output scanners, fully self-hosted | Variable |
| **Arcjet** | Commercial | Inline prompt injection defense, zero-config | Inline |
| **Llama Guard** | OSS (Meta) | Content safety classifier, runs as separate model | ~100ms |

### Prompt Injection Defenses

#### Spotlighting (Microsoft Research)
Reduces attack success rate from >50% to <2% with three techniques:
- **Delimiting**: Randomized text delimiters around untrusted input
- **Datamarking**: Special tokens throughout untrusted text
- **Encoding**: Transform untrusted text via base64 or ROT13

#### Other Production Defenses

| Defense | Attack Success Rate | Notes |
|---------|-------------------|-------|
| **DataFilter** | 2.2% | Strongest individual defense |
| **Spotlighting** | <2% | Microsoft Research, production-proven |
| **Sandwich prompting** | 22.8% | Weak alone, useful in combination |
| **Instruction hierarchy** | Varies | OpenAI's approach, system > user > tool |

**Best practice**: Combine multiple layers. No single defense is sufficient. Input screening + spotlighting + output validation + audit logging.

### Production Safety Checklist

- [ ] SQL uses parameterized queries (never string interpolation, even for LIMIT/OFFSET)
- [ ] HTML output is sanitized/escaped
- [ ] File paths validated against directory traversal
- [ ] Redirect URLs validated (relative paths only, matching `/^\/[a-zA-Z]/`)
- [ ] Auth checked before authz
- [ ] Secrets from env vars, never hardcoded
- [ ] PII never logged (return IDs, not emails, in non-user-facing responses)
- [ ] All LLM inputs pass through prompt injection scanner
- [ ] All LLM outputs pass through content policy validator
- [ ] Tool calls are audit-logged with user identity + parameters
- [ ] Rate limiting on LLM endpoints
- [ ] Circuit breaker on LLM providers (fail open to cached/fallback, not to raw user input)
- [ ] Human approval required for destructive agent actions
- [ ] Token budgets enforced per-request and per-user

---

## 10. Emerging Patterns

### Computer Use and Browser Agents

**Computer use** is the ability for AI to interact with software through its graphical interface -- clicking buttons, typing into fields, reading screens. It bridges AI and legacy enterprise software without APIs.

**Key players**:
- **Claude Computer Use**: Anthropic's API for GUI interaction (Opus 4.6, Sonnet 4.6)
- **Microsoft Copilot Studio Computer Use**: Interact with any application via GUI (April 2025)
- **Amazon Nova Act**: SDK for browser agents, 0.939 ScreenSpot Web Text score
- **Stagehand v3** (February 2026): AI-native browser automation, 44% faster, communicates directly via Chrome DevTools Protocol
- **Playwright + AI**: Traditional browser automation enhanced with LLM decision-making

**Enterprise use cases**: Form filling, workflow automation between systems (log into vendor portals, download CSVs, upload to other systems), legacy software interaction.

**Agentic browsers** (dedicated browsers for AI agents):
- Every major tech company now has AI-powered browser automation
- Used for QA testing, data extraction, workflow automation
- The most impactful use cases involve high-volume, repetitive, multi-step processes spanning multiple systems

### Voice Agents

- **Salesforce Agentforce Voice**: Phone-based AI agents for customer service
- **Zoom AI Companion**: Agentic workflows -- drafts emails, sends summaries, orchestrates across Salesforce/Slack/ServiceNow
- **OpenAI Realtime API**: WebSocket-based voice with function calling
- **ElevenLabs**: Text-to-speech and voice cloning for agent interfaces
- **Vapi, Retell**: Voice agent platforms for building phone-based AI

### Agentic Workflows in Enterprise

**Enterprise adoption** (March 2026): Virtually every forward-looking enterprise is at least piloting agents. Key patterns:

1. **Event-driven agents**: Trigger on Slack message, GitHub PR, PagerDuty alert, schedule
2. **Multi-system orchestration**: Agents that span CRM + ticketing + email + calendar
3. **Human-in-the-loop**: Agents propose, humans approve, agents execute
4. **Self-improving agents**: Memory tools learn from past runs (Cursor Automations pattern)

### Real-Time Multimodal

**Gemini 3.1 Pro** is the only frontier model with native text+image+audio+video processing in a single API call. This enables:
- Video understanding (analyze meeting recordings, security footage, product demos)
- Audio analysis (transcription + sentiment + speaker identification)
- Real-time multimodal (process camera feed + microphone + text simultaneously)

### Video Understanding

- **Gemini 3.1 Pro**: Native video input at API level
- **GPT-5.4**: Frame extraction + analysis (not native video)
- **Twelve Labs**: Specialized video understanding API
- Use cases: content moderation, meeting analysis, surveillance, product analytics

### Agent-to-Agent Communication

A2A protocol enables agents built with different frameworks by different vendors to discover each other, negotiate capabilities, and collaborate on tasks. This is the beginning of an "agent economy" where specialized agents trade services.

**Example flow**:
1. Client agent discovers remote agent via Agent Card
2. Client sends task request with parameters
3. Remote agent processes, streams progress updates
4. Client receives results, integrates into workflow
5. Billing/usage tracked per-task

### What's New and Weird That Might Be Big

1. **Agent Automations** (Cursor): Always-on coding agents that run on schedules/events. Not just "ask for code" but "code that writes itself continuously."

2. **Living Specifications** (Augment/Intent): Specs that update as implementation progresses, keeping multiple agents aligned. The spec is the source of truth, not the code.

3. **Tool Search** (Anthropic): Agents searching through thousands of tools without putting them all in context. Like a search engine for capabilities.

4. **Programmatic Tool Calling** (Anthropic): LLMs invoking tools inside a code execution environment, not just via API. The model writes and runs code that uses tools.

5. **10M Token Context** (Llama 4 Scout): Process an entire codebase or book in one context. Changes the RAG vs in-context tradeoff entirely.

6. **Open-Source at Frontier Quality**: DeepSeek V3.2-Speciale beats GPT-5 on reasoning. The moat for proprietary models is shrinking.

7. **Agent Memory as a Product**: Mem0, Zep, Letta -- purpose-built memory layers for agents. Agents that remember and learn across sessions.

8. **Protocol Stack Maturation**: MCP + A2A + AG-UI forming a complete standard stack. Like HTTP + REST + HTML for the agent era.

---

## Quick Reference: Decision Frameworks

### "Which model should I use?"
```
Complex reasoning + coding --> Claude Opus 4.6
Daily development --> Claude Sonnet 4.6 or GPT-4.1
Cost-sensitive high-volume --> Gemini 2.5 Flash ($0.15/1M in)
Reasoning-heavy --> o3 or DeepSeek V3.2-Speciale
Multimodal (audio/video) --> Gemini 3.1 Pro
Privacy-critical / self-hosted --> DeepSeek V3.2 or Llama 4
Long context (>1M) --> Llama 4 Scout (10M) or Gemini (1M)
Speed-critical --> Groq or Cerebras (fastest inference)
```

### "Which agent framework should I use?"
```
Complex stateful orchestration --> LangGraph
Fast role-based teams --> CrewAI
Lightweight multi-agent --> OpenAI Agents SDK
Type-safe Python production --> Pydantic AI
Microsoft ecosystem --> AutoGen/AG2
Custom / maximum control --> Build your own with ReAct loop
```

### "Which coding tool should I use?"
```
Autocomplete (cheap, everywhere) --> GitHub Copilot ($10/mo)
IDE-based agentic coding --> Cursor ($20-200/mo) or Windsurf ($15/mo)
Terminal-based deep work --> Claude Code or Gemini CLI (free)
Open-source, any model --> Cline (VS Code) or Aider (terminal)
Autonomous fire-and-forget --> Devin or Codex CLI (cloud)
Spec-driven development --> Kiro ($19/mo)
```

### "RAG, fine-tuning, or prompt engineering?"
```
Knowledge < 200K tokens --> Full-context prompting + cache
Knowledge changes weekly+ --> RAG
Need different behavior/tone --> Fine-tuning
Need accuracy >95% --> RAG + fine-tuning (hybrid)
Just starting out --> Prompt engineering first, always
```

### "Which guardrails framework?"
```
Strong DevOps, custom policies --> NeMo Guardrails or LLM Guard (OSS)
Fast time-to-value, compliance --> Lakera Guard / Check Point (commercial)
Structured output validation --> Guardrails AI
Content safety classification --> Llama Guard
Inline prompt injection defense --> Arcjet
```

---

## Sources and Further Reading

### MCP
- [MCP 2026 Roadmap](https://blog.modelcontextprotocol.io/posts/2026-mcp-roadmap/)
- [MCP Specification](https://modelcontextprotocol.io/specification/2025-11-25)
- [MCP Authorization](https://modelcontextprotocol.io/specification/draft/basic/authorization)
- [MCP Registry Preview](https://blog.modelcontextprotocol.io/posts/2025-09-08-mcp-registry-preview/)
- [GitHub MCP Registry](https://github.blog/ai-and-ml/github-copilot/meet-the-github-mcp-registry-the-fastest-way-to-discover-mcp-servers/)
- [MCP Auth on Stack Overflow](https://stackoverflow.blog/2026/01/21/is-that-allowed-authentication-and-authorization-in-model-context-protocol/)
- [MCP Enterprise Gateway](https://github.com/agentic-community/mcp-gateway-registry)

### Agent Frameworks
- [LangGraph vs CrewAI vs Pydantic AI 2026](https://dev.to/linou518/the-2026-ai-agent-framework-decision-guide-langgraph-vs-crewai-vs-pydantic-ai-b2h)
- [OpenAI Agents SDK](https://openai.github.io/openai-agents-python/)
- [Pydantic AI](https://ai.pydantic.dev/)
- [Agent Memory Frameworks 2026](https://machinelearningmastery.com/the-6-best-ai-agent-memory-frameworks-you-should-try-in-2026/)
- [A2A Protocol](https://a2a-protocol.org/latest/)
- [AG-UI Protocol](https://docs.ag-ui.com/)
- [Agent Protocols Overview](https://medium.com/google-cloud/agent-protocols-mcp-a2a-a2ui-ag-ui-3ed8b356f1bc)

### Coding Assistants
- [AI Coding Agents Comparison 2026](https://lushbinary.com/blog/ai-coding-agents-comparison-cursor-windsurf-claude-copilot-kiro-2026/)
- [Cursor Automations](https://cursor.com/blog/automations)
- [Claude Code Agent Teams](https://claudefa.st/blog/guide/agents/agent-teams)
- [Kiro IDE](https://kiro.dev/)
- [Gemini CLI](https://github.com/google-gemini/gemini-cli)
- [Cline](https://cline.bot)
- [Aider](https://aider.chat/)

### Compound AI Systems
- [Production RAG Architecture Guide](https://blog.premai.io/building-production-rag-architecture-chunking-evaluation-monitoring-2026-guide/)
- [RAG vs Fine-tuning 2026](https://umesh-malik.com/blog/rag-vs-fine-tuning-llms-2026/)
- [Braintrust](https://www.braintrust.dev)
- [Langfuse](https://langfuse.com/docs/security-and-guardrails)
- [Structured Output Guide](https://agenta.ai/blog/the-guide-to-structured-outputs-and-function-calling-with-llms)

### Infrastructure
- [vLLM Speculative Decoding](https://docs.vllm.ai/en/latest/features/speculative_decoding/)
- [NVIDIA Model Optimizer](https://github.com/NVIDIA/Model-Optimizer)
- [Ollama](https://ollama.com)
- [Ollama vs vLLM Benchmark 2026](https://www.sitepoint.com/ollama-vs-vllm-performance-benchmark-2026/)
- [OpenAI API Pricing](https://openai.com/api/pricing/)
- [Fireworks Pricing](https://fireworks.ai/pricing)

### Models
- [SWE-Bench Verified Leaderboard](https://llm-stats.com/benchmarks/swe-bench-verified)
- [Best LLM for Coding 2026](https://smartscope.blog/en/generative-ai/chatgpt/llm-coding-benchmark-comparison-2026/)
- [DeepSeek V3.2 Technical Tour](https://magazine.sebastianraschka.com/p/technical-deepseek)
- [Open-Source LLM Leaderboard](https://onyx.app/open-llm-leaderboard)
- [Claude 4.6 What's New](https://platform.claude.com/docs/en/about-claude/models/whats-new-claude-4-6)

### Safety
- [AI Agent Guardrails Guide 2026](https://galileo.ai/blog/best-ai-agent-guardrails-solutions)
- [Prompt Injection Defenses Repository](https://github.com/tldrsec/prompt-injection-defenses)
- [Spotlighting Paper](https://arxiv.org/abs/2403.14720)
- [NeMo Guardrails](https://github.com/NVIDIA-NeMo/Guardrails)
- [LLM Guard](https://langfuse.com/docs/security-and-guardrails)
- [Arcjet Prompt Injection Protection](https://www.helpnetsecurity.com/2026/03/19/arcjet-ai-prompt-injection-protection/)

### Emerging Patterns
- [Agentic Browser Landscape 2026](https://www.nohackspod.com/blog/agentic-browser-landscape-2026)
- [Computer Use Guide 2026](https://o-mega.ai/articles/agentic-computer-use-the-ultimate-deep-guide-2026)
- [Rise of Agentic Coworkers (a16z)](https://a16z.com/the-rise-of-computer-use-and-agentic-coworkers/)
- [AI Agent Trends 2026 (Google Cloud)](https://cloud.google.com/resources/content/ai-agent-trends-2026)
- [Vercel AI SDK](https://ai-sdk.dev/docs/introduction)
- [CopilotKit](https://www.copilotkit.ai/ag-ui)

---

*Last updated: March 20, 2026*
*Compiled from web research across 50+ sources. Verify pricing and version numbers before production decisions -- this landscape moves fast.*
