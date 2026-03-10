# Scaling Strategies Reference

## Scaling Decision Table

| Signal | Strategy | Notes |
|--------|----------|-------|
| CPU-bound, single service | Vertical (bigger instance) | Simplest, try first |
| Request volume growing | Horizontal (more instances) | Requires stateless design |
| Read-heavy DB | Read replicas | Route reads to replicas |
| Write-heavy DB | Sharding or write-ahead queue | Complex, last resort |
| Static content latency | CDN | Geographic distribution |
| Repeated expensive queries | Caching (Redis) | Watch invalidation |
| Bursty traffic | Auto-scaling + queue buffering | Smooth out spikes |

## Horizontal Scaling (Scale Out)

### Stateless Design Requirement

```python
# Bad: Stateful (won't scale horizontally)
class OrderService:
    def __init__(self):
        self.pending_orders = {}  # In-memory state

    def create_order(self, order):
        self.pending_orders[order.id] = order

# Good: Stateless (scales horizontally)
class OrderService:
    def __init__(self, db, cache):
        self.db = db
        self.cache = cache

    def create_order(self, order):
        self.db.save(order)  # External state
        self.cache.invalidate(f"user:{order.user_id}:orders")
```

### Load Balancing Strategies

| Strategy | When |
|----------|------|
| Round-robin | Simple, no affinity needed |
| Least connections | Uneven request durations |
| Consistent hashing | Cache affinity, session affinity |
| Geo-based | Latency optimization, multi-region |

### Data Partitioning (Sharding)

```yaml
sharding_strategies:
  by_user_id: User data, sessions, preferences
  by_tenant_id: Multi-tenant SaaS
  by_date: Time-series data (logs, metrics)
  by_geography: GDPR, data residency

considerations:
  - Avoid cross-shard joins
  - Handle rebalancing (add/remove shards)
  - Query routing logic
  - Transaction boundaries limited to single shard
```

## Vertical Scaling (Scale Up)

**When**:
- Cheaper initially (simpler operations)
- Database primary (write scaling)
- Stateful services (coordination overhead)
- Before investing in horizontal architecture

**Limits**:
- Hardware ceiling (largest available instance)
- Single point of failure
- Downtime for upgrades
- Cost grows non-linearly

## Caching Strategy

### Cache Layers

```
Request Flow:
|
|-- L1: Application cache (in-memory)
|   Hot data, microsecond latency
|
|-- L2: Distributed cache (Redis)
|   Shared state, sub-10ms latency
|
|-- L3: CDN edge cache
|   Static assets, geographic distribution
|
|-- L4: Database query cache
|   Expensive queries, automatic invalidation
```

### Invalidation Strategies

| Strategy | How | When |
|----------|-----|------|
| TTL (time-based) | `cache.set(key, val, ttl=300)` | Eventual consistency OK |
| Event-based | Delete on write | Strong consistency needed |
| Write-through | Update cache on write | Always-fresh reads |
| Cache-aside | Load on miss, set with TTL | Most common general pattern |

```python
# Cache-aside pattern
def get_user(user_id):
    cached = cache.get(f"user:{user_id}")
    if cached:
        return cached
    user = db.get(user_id)
    cache.set(f"user:{user_id}", user, ttl=300)
    return user

# Write-through pattern
def update_user(user_id, data):
    db.update(user_id, data)
    cache.set(f"user:{user_id}", data)

# Event-based invalidation
def update_user(user_id, data):
    db.update(user_id, data)
    cache.delete(f"user:{user_id}")
    cache.delete(f"user:{user_id}:profile")
```

## Async Processing Patterns

| Pattern | When | Tools |
|---------|------|-------|
| Task queue | CRUD ops, retries, ordering | Celery, Bull, Sidekiq |
| Event stream | Real-time, high throughput, fan-out | Kafka, Kinesis, Pulsar |
| Pub/sub | Decoupled, multiple consumers | Redis Pub/Sub, NATS |

**When to go async**:
- Long-running operations (>1s)
- Non-critical path (email, analytics)
- Rate-limited external APIs
- Bulk processing

## Security Architecture

### Trust Boundaries

```
Internet (Untrusted)
    |
    v
DMZ (Semi-trusted): Load Balancer (TLS termination) + WAF
    |
    v
Application Tier (Authenticated): API Gateway (rate limit) + Auth Service
    |
    v
Data Tier (Encrypted at rest): Database (TLS only) + Object Store
```

**Principles**:
- Never trust input crossing boundaries
- Validate at each boundary
- Encrypt in transit and at rest
- Least privilege for service accounts
- Audit all boundary crossings

### STRIDE Threat Model

| Threat | Example | Mitigation |
|--------|---------|------------|
| Spoofing | Fake identity, session hijack | Strong auth, MFA |
| Tampering | SQL injection, XSS, CSRF | Input validation, CSP |
| Repudiation | No audit trail | Immutable logging |
| Info Disclosure | Data leaks, verbose errors | Encryption, generic errors |
| Denial of Service | Resource exhaustion | Rate limiting, auto-scaling |
| Elevation of Privilege | AuthZ bypass | RBAC/ABAC, least privilege |

### Security Controls Checklist

```yaml
input_validation:
  - Whitelist allowed values (not blacklist)
  - Type checking (strong typing)
  - Length limits
  - Format validation (schemas)
  - Sanitization

authentication:
  - Strong password policy
  - MFA (TOTP, WebAuthn)
  - Secure session management (httpOnly, secure, SameSite)
  - Account lockout
  - Secure password reset flow

authorization:
  - RBAC or ABAC
  - Least privilege
  - Resource-level permissions
  - Time-based access expiration

data_protection:
  - Encryption at rest (AES-256)
  - Encryption in transit (TLS 1.3+)
  - Key rotation
  - PII masking in logs
  - Data retention policies

observability:
  - Auth events (success + failure)
  - AuthZ failures
  - Sensitive data access
  - Configuration changes
  - Anomaly detection
```

## Technical Debt Tracking

### Debt Quadrant (Martin Fowler)

| | Deliberate | Inadvertent |
|--|-----------|-------------|
| **Prudent** | "We know the shortcut, will fix later" (ACCEPT) | "We didn't know better at the time" (PLAN) |
| **Reckless** | "We don't have time for this" (NEVER) | "What's layering?" (NEVER) |

### When to Pay Down

| Pay now | Schedule | Leave alone |
|---------|----------|-------------|
| Security vulnerabilities | Affects velocity | One-off scripts |
| Data corruption risks | Causes bugs | Deprecated code |
| Production incidents from debt | Affects morale | Prototypes |
| Blocking new features | Before major refactor | Low-impact, documented |

### Debt Tracking Template

```yaml
debt_id: TD-{NNN}
title: "{description}"
type: architecture | code_quality | testing | documentation
status: accepted | planned | in_progress | resolved
created: YYYY-MM-DD

context: |
  Why the shortcut was taken.

impact:
  severity: low | medium | high
  affected_components: [list]
  estimated_hours_to_fix: N

paydown_plan:
  trigger: "When {condition}"
  steps: [list]

monitoring:
  metrics: [what to watch]
  alerts: [when to act]
```
