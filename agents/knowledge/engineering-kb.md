# Senior Software Engineer Knowledge Base
# Reference material for the senior-engineer agent. Read on demand for deep dives.

---

## 1. Distributed Systems

### CAP / PACELC
- **CAP**: Since partitions are inevitable, the real choice is CP (reject requests to stay consistent) vs AP (serve stale data to stay available).
- **PACELC**: Extends CAP to normal operation — "If Partition, choose A or C; Else, choose Latency or Consistency." Two CP systems can have wildly different normal-mode latency.
- **Decision**: If a stale read causes business damage (financial, inventory, booking) → CP. If staleness is tolerable and uptime matters more → AP.

### Consistency Models (strongest to weakest)
1. **Linearizability**: Operations atomic at a single point in time. Use for: distributed locks, leader election, financial transactions. Cost: high latency.
2. **Sequential**: Per-client ordering guaranteed, no real-time cross-client guarantee.
3. **Causal**: If A causally precedes B, all nodes see A before B. Use for: social media (replies after posts), collaborative editing.
4. **Eventual**: All replicas converge given no new updates. Use for: DNS, CDN, session stores, analytics. Cheapest and fastest.

### Consensus: Raft vs Paxos
- **Raft**: Default choice. Understandable, well-documented. Used by etcd, CockroachDB, TiDB, Consul.
- **Paxos**: More flexible, harder to implement. Used by Spanner, Azure Storage.
- **Practical rule**: Use Raft. When choosing a database, the consensus algorithm matters less than operational maturity.

### Distributed Transactions
- **Single DB** → use ACID transactions (no distributed protocol needed)
- **2-3 services, same DC, <100ms** → 2PC is viable
- **3+ services, cross-DC, or long-running** → Saga pattern (orchestration preferred)
- **Modern trend (2026)**: Durable execution platforms (Temporal, Restate) replace hand-rolled sagas.

---

## 2. Scalability

### Horizontal vs Vertical
Scale vertically first until you hit: (a) hardware limits, (b) need fault tolerance across zones, or (c) superlinear cost. Most systems never need horizontal scaling — a single modern server handles millions of req/day.

### Sharding Strategies
| Strategy | Pro | Con | Use For |
|----------|-----|-----|---------|
| Range-based | Range queries efficient | Hot spots if skewed | Time-series, alphabetical |
| Hash-based | Even distribution | Range queries scatter | User data, sessions |
| Directory-based | Maximum flexibility | SPOF lookup service | Multi-tenant |
| Geo-based | Data locality, low latency | Cross-region queries expensive | GDPR compliance, global apps |

**Shard key rules**: High cardinality, even write distribution, queries route to single shard, immutable.

### Replication
- **Leader-Follower**: One writer, many readers. Use for most OLTP. PostgreSQL, MySQL, Redis Sentinel.
- **Multi-Leader**: Multiple writers, conflict resolution needed. Use for multi-DC with local write need. CouchDB, Cosmos DB.
- **Leaderless**: Any node reads/writes, quorum-based. Use for write-heavy high-availability. Cassandra, DynamoDB.

### Load Balancing
- **Round Robin**: Homogeneous servers, stateless requests
- **Least Connections**: Varying request durations
- **Consistent Hashing**: Caching layers, stateful routing. Use 150-250 virtual nodes per physical node.

---

## 3. Caching

### Strategies
| Pattern | How | Best For |
|---------|-----|----------|
| **Cache-Aside** (default) | Read: check cache → miss → read DB → populate cache. Write: write DB, invalidate cache. | General purpose, read-heavy |
| **Write-Through** | Write to cache, cache synchronously writes to DB | Must-be-consistent data (financial balances, inventory) |
| **Write-Back** | Write to cache only, async flush to DB | Write-heavy, some data loss acceptable (analytics, counters) |
| **Write-Around** | Write directly to DB, skip cache | Data written once, rarely re-read |

### Cache Invalidation (simplest to most robust)
1. **TTL**: Set expiration. Start with 60s, adjust. Good enough for 90% of cases.
2. **Event-driven**: Publish invalidation event on write. Near-real-time. Requires message bus.
3. **Versioned keys**: Append version counter. Old versions become unreachable.
4. **Cache tags**: Purge by logical group. CDN-friendly (Fastly, Cloudflare).

### CDN Edge Caching
- Static assets: long TTL + content-hash filenames
- Dynamic content: short TTL + `stale-while-revalidate`
- Personalized content: don't cache at CDN, or use edge compute for fragment assembly
- API responses: `Cache-Control: public, max-age=N, stale-while-revalidate=M`

---

## 4. Message Systems

### Queues vs Streams
| | Message Queue (RabbitMQ, SQS) | Event Stream (Kafka, Redpanda) |
|-|-------------------------------|-------------------------------|
| Semantics | "Task to be done" | "Fact that happened" |
| After consumption | Deleted | Retained (offset-tracked) |
| Replay | No | Yes |
| Throughput | 10K-100K msg/s | 1M+ msg/s |
| Multiple consumers | Competing (one gets each) | Consumer groups (each group sees all) |

**Decision**: Need replay or multiple independent consumers? → Event stream. Simple task distribution? → Message queue.

### Delivery Guarantees
- **At-most-once**: Fire and forget. For metrics/logging where loss OK.
- **At-least-once**: Ack + retry. **Default choice.** Pair with idempotent consumers.
- **Exactly-once**: Expensive. Use at-least-once + idempotency instead (cheaper, more reliable).

### Dead Letter Queues
- Max 3-5 retries with exponential backoff
- Route failures to DLQ with original message + error details + retry count
- Monitor DLQ depth — non-zero = production bug
- Build tooling to inspect, replay, or discard

---

## 5. API Design

### Protocol Selection
| Use Case | Protocol |
|----------|----------|
| Public API for third parties | REST |
| Mobile/SPA with complex data needs | GraphQL |
| Internal service-to-service | gRPC |
| Real-time bidirectional | WebSocket |
| Server-to-client real-time (one direction) | SSE |
| Async notifications | Webhooks |

Most production systems use REST (public) + gRPC (internal) + WebSocket/SSE (real-time).

### Pagination
- **Offset-based** (`?offset=40&limit=20`): Simple but O(offset) cost. Degrades past ~10K offset. Use for admin dashboards, small datasets.
- **Cursor-based** (`?cursor=abc&limit=20`): O(1) cost. Stable under concurrent writes. 17x faster at scale. **Default for production APIs.**
- Always enforce max page size (50-100). Return `next_cursor` + `has_more`.

### Rate Limiting
- **Token Bucket**: Default choice. Allows bursts. Used by AWS, Stripe.
- **Sliding Window Counter**: Best balance of precision and efficiency for high-volume APIs.
- Only retry on transient errors (5xx, timeouts). Never retry 4xx.

### Versioning
- URL path (`/v1/users`) for public APIs (explicitness wins)
- For internal APIs, evolve with additive-only changes

---

## 6. Database Selection

### Decision Tree
```
OLTP + SQL + joins needed?
  YES → Need horizontal write scaling?
    YES → CockroachDB (PG-compatible) or TiDB (MySQL-compatible)
    NO  → PostgreSQL (DEFAULT CHOICE)
  NO → Document model fits?
    YES → DynamoDB (serverless, AWS) or MongoDB (flexible schema)
    NO  → Key-value, ultra-low latency? → Valkey/Redis
          Wide-column, massive writes? → Cassandra/ScyllaDB

OLAP / Analytics?
  Time-series → TimescaleDB (PG extension) or ClickHouse
  General analytics → ClickHouse, BigQuery, DuckDB (embedded)

Search?
  Enterprise + logs → Elasticsearch/OpenSearch
  End-user instant search → Meilisearch
  Vector/AI embeddings → pgvector (<10M), Pinecone/Weaviate (>10M)

Graph?
  Deep traversals (4+ hops) → Neo4j
  Light graph queries → PostgreSQL recursive CTEs
```

### The Boring Default Stack (2026)
PostgreSQL (OLTP) + ClickHouse (analytics) + Valkey (caching) + Meilisearch (search). Covers 95% of applications.

### PostgreSQL 18 Highlights (2025)
- 3x storage read performance (new I/O subsystem)
- Native `uuidv7()` (timestamp-ordered UUIDs)
- Virtual generated columns, skip scan, temporal constraints

### Valkey vs Redis vs DragonflyDB (2026)
- **Valkey**: BSD license, Redis-compatible, backed by AWS/Google/Oracle. **Safe default for new projects.**
- **Redis**: AGPLv3 option added. Maximum ecosystem support.
- **DragonflyDB**: 5-10x throughput, 30% memory savings. Source-available license.

---

## 7. Reliability Patterns

### Circuit Breaker
```
CLOSED → [50% failure rate in 10s window] → OPEN → [5-10s timeout] → HALF-OPEN → [probe succeeds] → CLOSED
                                                                    → [probe fails] → OPEN
```

### Retry: Exponential Backoff + Jitter
```
delay = min(base * 2^attempt + random_jitter, max_delay)
```
- Only retry idempotent operations
- Max 3-5 retries
- Full jitter to prevent thundering herd
- Never retry 4xx errors

### Bulkhead
Isolate components so one failure doesn't consume all resources. Size = `peak_rps × p99_latency_seconds`.

### Health Checks
- **Liveness**: Is the process alive? Fast, no dependency checks. Fail → restart.
- **Readiness**: Can it serve traffic? Check DB, cache, critical deps. Fail → remove from LB.
- **Startup**: Has initialization finished? Prevents killing slow starters.

### Graceful Degradation Priority Stack
1. Core transactions (payments, orders)
2. Authentication/authorization
3. Primary read paths
4. Secondary features (recommendations, notifications)
5. Analytics/tracking

---

## 8. Microservices vs Monolith

### Decision Framework
- **1-10 devs** → Modular monolith. Microservices overhead will slow you down.
- **10-50 devs** → Modular monolith + 2-5 extracted services for independent scaling needs.
- **50+ devs** → Microservices justified. Architecture should mirror org structure.
- **Still discovering domain boundaries?** → Monolith. Refactoring modules is trivial; merging microservices is painful.

### Cost Reality
Microservices cost 3.75-6x more in infrastructure + require 2-5 platform engineers. 42% of organizations are moving back to modular monoliths in 2026.

### Modular Monolith Rules
1. Each module owns its tables. No cross-module table access.
2. Module dependencies are unidirectional and enforced.
3. Each module could theoretically become a service.
4. Shared code in a "platform" module with no business logic.

---

## 9. Performance

### Latency Numbers (2026 hardware)
```
L1 cache:           ~1 ns
Main memory:        ~100 ns      (100x L1)
NVMe SSD random:    ~15 us       (15,000x L1)
Datacenter RTT:     ~500 us      (500,000x L1)
Cross-continent:    ~150 ms      (150,000,000x L1)
```

### Common Pitfalls
**Database**: N+1 queries (use eager loading), missing indexes (every FK + WHERE column), connection pool exhaustion (pool size = cores × 2 + spindles), full table scans (expression indexes)

**Application**: Blocking I/O in async code, unbounded caches without eviction, JSON serialization of large payloads, GC pressure from object allocation in loops

**Network**: Chatty APIs (batch calls), missing compression (Brotli > gzip), no connection reuse, DNS resolution overhead (10-100ms per unique hostname)

**Frontend**: Bundle size (target <100KB gzipped initial JS), unnecessary re-renders, layout thrashing (batch reads then writes), no virtual scrolling for long lists

### Big-O in Practice
O(n²) is fine when n < 1000 and operation is simple. O(n) with network calls per element is 500,000x slower than O(n²) in L1 cache at n = 30. **I/O multiplied by N is the real performance killer.**

### Thread Pool Sizing
- CPU-bound: `threads = num_cores`
- I/O-bound: `threads = cores × (1 + wait_time/compute_time)`
- Separate pools for CPU and I/O work

---

## 10. Modern Tech Landscape (2026)

### Runtimes
- **Node.js** (v22 LTS): Most mature, 100% npm compat. Default for existing projects.
- **Bun** (v1.x): 3.7x faster HTTP, 8-15ms cold start. Best for greenfield performance-sensitive APIs.
- **Deno** (v2.x): Secure by default, best built-in tooling. For security-critical apps.

### Languages
- **TypeScript**: TS 7.0 (mid-2026) ships Go-based compiler — 10x faster compilation.
- **Python 3.14**: GIL now optional (PEP 703). 3.1x multi-threaded speedup. `uv` package manager (100x faster than pip).
- **Go 1.26**: Green Tea GC (30% latency improvement), SIMD package.
- **Rust**: Best for systems programming, security-critical code, WebAssembly. Not for MVPs or CRUD apps.

### Infrastructure
- **Serverless crossover**: At ~30-40M req/month, containers become cheaper than Lambda.
- **Cloudflare Workers**: Sub-ms cold starts, 300+ edge locations. Best for web-facing edge compute.
- **IaC**: Terraform/OpenTofu for ops teams, Pulumi for developer-managed infra.
- **Kubernetes**: Only if 15+ devs + dedicated platform team. Otherwise use a PaaS.

### AI Integration
- **LLM patterns**: Structured output (JSON mode/tool use), streaming (SSE), semantic caching, token budget management.
- **RAG**: Hybrid retrieval (BM25 + vector), query expansion, cross-encoder reranking.
- **Vector DBs**: pgvector (<10M docs, already on PG), Pinecone/Weaviate (>10M, managed).
- **Agent frameworks**: LangGraph for production, CrewAI for prototyping. Prototype in CrewAI → rewrite in LangGraph.

### Observability
- **OpenTelemetry**: The standard. Traces + Metrics + Logs. Vendor-neutral.
- **Structured logging**: JSON with traceId, spanId, correlation IDs. Log events not data. No PII.

### Technology Selection Framework
- **Innovation tokens**: ~3 per org. Spend on edges (feature layer), not foundations (DB, language).
- **Boring default stack**: TypeScript + Node.js/Bun + PostgreSQL 18 + Valkey + OpenTelemetry + GitHub Actions.
- **One-way doors** (DB, language, public API): Design twice, choose boring.
- **Two-way doors** (library, CI tool, internal API): Move fast, experiment.
- **Novel tech justified when**: Solves a problem boring tech literally cannot, 10x+ improvement, isolated and replaceable.
