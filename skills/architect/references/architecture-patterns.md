# Architecture Patterns Reference

## Service Architecture Patterns

### Monolith

**When**: Small team (<5 devs), early stage, rapid iteration needed.

**Pros**:
- Simple deployment and debugging
- No network overhead between components
- Easy refactoring across boundaries
- Lower operational cost

**Cons**:
- Scaling is all-or-nothing
- Deployment couples all features
- Technology lock-in (single stack)
- Growing codebase complexity

**Tradeoff**: Simplicity vs independent scalability.

### Modular Monolith

**When**: Growing team, clear domain boundaries, not ready for microservices.

**Pros**:
- Clear module boundaries without network overhead
- Can extract to microservices later
- Single deployment, simpler ops
- Enforced boundaries via module interfaces

**Cons**:
- Discipline required to maintain boundaries
- Still single deployment unit
- Shared database (coupling risk)

**Tradeoff**: Structured growth path vs full independence.

### Microservices

**When**: Large team (>10 devs), independent deploy cycles needed, different scaling requirements per service.

**Pros**:
- Independent deployment and scaling
- Technology diversity per service
- Team autonomy
- Fault isolation

**Cons**:
- Network complexity (latency, failures)
- Data consistency challenges (distributed transactions)
- Operational overhead (monitoring, tracing, deployment)
- Service discovery, load balancing

**Tradeoff**: Independence and scalability vs operational complexity.

## Data Patterns

### Event Sourcing

**When**: Financial systems, compliance-heavy, complex domain workflows, audit trail required.

**Pros**:
- Complete audit trail
- Temporal queries (state at any point in time)
- Event replay for debugging
- Enables CQRS

**Cons**:
- Complexity (event schema evolution)
- Storage overhead (all events kept)
- Query complexity (rebuild state from events)
- Learning curve

**Tradeoff**: Auditability and time-travel vs simplicity and immediate queries.

### CQRS (Command Query Responsibility Segregation)

**When**: Read/write patterns differ significantly, complex queries, event-sourced systems.

**Pros**:
- Optimize read and write models independently
- Scale reads and writes separately
- Simplified query logic (denormalized read models)

**Cons**:
- Eventual consistency between read/write
- Dual model maintenance
- Increased codebase complexity

**Tradeoff**: Performance optimization vs consistency and simplicity.

### Saga Pattern

**When**: Distributed transactions across services, long-running business processes.

**Pros**:
- No distributed locks
- Each service manages its own data
- Compensating transactions for rollback

**Cons**:
- Compensation logic complexity
- Difficult to debug
- Eventual consistency

**Tradeoff**: Loose coupling vs transaction simplicity.

## Communication Patterns

### Synchronous (REST/gRPC)

**When**: Simple request-response, low latency required, strong consistency needed.

**Tradeoff**: Simplicity vs resilience (caller blocks on callee).

### Asynchronous (Message Queue)

**When**: Decoupled systems, retry needed, ordering matters, load leveling.

**Tradeoff**: Reliability and decoupling vs eventual consistency and debugging complexity.

### Event-Driven (Pub/Sub)

**When**: Fan-out to multiple consumers, loosely coupled systems, analytics/audit.

**Tradeoff**: Extensibility vs traceability.

## Scenario-Based Selection

### User Authentication
```yaml
options:
  - pattern: Session-based (cookies)
    when: Traditional web app, server-side rendering
    pros: Simple, secure, mature ecosystem
    cons: Doesn't scale horizontally (sticky sessions)

  - pattern: JWT (stateless tokens)
    when: API-first, mobile apps, microservices
    pros: Scales horizontally, no server state
    cons: Revocation complexity, token size

  - pattern: OAuth2 + OpenID Connect
    when: Third-party auth, SSO, enterprise
    pros: Industry standard, delegated auth
    cons: Complexity, vendor dependencies

decision_process:
  1. Who are the users? (internal, external, third-party)
  2. What clients? (web, mobile, API)
  3. Scale requirements? (<1K users vs >100K)
  4. Security requirements? (compliance, MFA)
  5. Choose pattern that fits 80%, handle edge cases separately
```

### Data Caching
```yaml
options:
  - pattern: In-memory (app-level)
    when: Single instance, small dataset (<1GB)

  - pattern: Redis (external)
    when: Multiple instances, shared state

  - pattern: CDN
    when: Static assets, geo-distributed users

  - pattern: Database query cache
    when: Read-heavy, complex queries

decision_matrix:
  - read/write ratio > 10:1 -> Cache
  - data changes frequently -> Short TTL or invalidation
  - consistency critical -> Write-through or skip caching
  - multi-region -> Edge caching
```

### Background Jobs
```yaml
options:
  - pattern: Cron jobs
    when: Scheduled, simple, low volume

  - pattern: Message queue (RabbitMQ, SQS)
    when: Async processing, decoupled, retries

  - pattern: Stream processing (Kafka)
    when: High throughput, event-driven, real-time

  - pattern: Serverless (Lambda)
    when: Sporadic, event-triggered

decision_factors:
  - Volume: <100/min -> cron, <10K/min -> queue, >10K/min -> stream
  - Latency: Real-time -> stream, minutes -> queue, hours -> cron
  - Reliability: Critical -> queue with DLQ, optional -> fire-and-forget
  - Cost: High volume -> self-hosted, sporadic -> serverless
```

## Pattern Documentation Template

```markdown
## Pattern: {Name}

**Context**: What problem does this solve?
**Decision**: We chose {pattern} because {reasons}.
**Alternatives considered**:
- {Alt 1}: Rejected because {reason}
- {Alt 2}: Rejected because {reason}
**Implementation notes**: Key components, configuration, dependencies
**Risks**: Known limitations, monitoring needed, fallback plan
```
