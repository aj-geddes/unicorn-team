# ADR Examples

## Example 1: Notification System Architecture

```markdown
# ADR-010: Notification System Architecture

**Date**: 2024-01-20
**Status**: Accepted

## Context

Need to notify users of important events (orders, messages, payments) via
multiple channels (email, push, in-app). No notification infrastructure exists.

**Requirements**:
- 500K notifications/day (~6/sec avg, ~30/sec peak)
- Multi-channel (email, push, in-app)
- < 1 min latency for critical events
- User preferences (disable per-event-type)
- Template-based with personalization

## Options Considered

### Option 1: Synchronous Notifications
Send notifications directly in request handler.

**Pros**: Simple, immediate feedback
**Cons**: Slow requests (email 1-5s), no retry, tight coupling
**Decision**: Rejected (unacceptable latency)

### Option 2: Async with Message Queue
Use message queue (SQS) + worker processes.

**Pros**: Decoupled, reliable (retry), scales horizontally
**Cons**: Added complexity, eventual consistency
**Decision**: Selected (best fit for requirements)

### Option 3: Third-party SaaS Only
Use SendGrid/Twilio for all notification handling.

**Pros**: No infrastructure management, built-in analytics
**Cons**: Vendor lock-in, cost at scale, limited customization
**Decision**: Partial use (SendGrid for email transport only)

## Decision

Hybrid approach:
- AWS SQS for async processing
- Worker service for routing and template rendering
- SendGrid for email transport
- FCM for push notifications
- PostgreSQL for in-app notifications (poll-based)

```
Event Source -> SQS -> Notification Worker -> Channel Handlers
                                             |-- Email (SendGrid)
                                             |-- Push (FCM)
                                             |-- In-app (DB)
```

## Consequences

**Positive**:
- Scales to 100x volume without architectural changes
- Reliable delivery with retries and DLQ
- Decoupled from core services
- Can add channels without changing producers

**Negative**:
- Eventual consistency (notification delay)
- More moving parts (queue, workers, external APIs)
- Testing complexity (async flows)

**Risks**:
- Queue backlog during spikes -> Mitigation: Autoscaling workers
- External API failures -> Mitigation: Exponential backoff, circuit breaker
- Template rendering bugs -> Mitigation: Preview mode, automated tests

**Tech Debt**:
- In-app notifications use polling -> Future: WebSocket push
- No notification analytics -> Future: Event tracking

## Implementation Notes

Components:
1. **Event Publisher** - Publish to SQS on event occurrence (event_type, user_id, data)
2. **Notification Worker** - Poll SQS, load preferences, render template, route to channel
3. **Channel Handlers** - Email (SendGrid), Push (FCM), In-app (DB write)
4. **Notification API** - GET /notifications, PUT /notifications/:id/read, PUT /preferences

## Validation Criteria

- 99% delivered within 1 minute
- < 0.1% failure rate
- Zero impact on request latency
- User can disable any notification type

**Monitoring**: Queue depth, worker lag, delivery rate by channel, DLQ analysis
```

## Example 2: Primary Datastore Selection

```markdown
# ADR-001: Use PostgreSQL for Primary Datastore

**Date**: 2024-01-10
**Status**: Accepted

## Context

Greenfield application needs a primary datastore. Data is relational (users,
orders, products). Team has SQL experience. Expected scale: 10M rows in first
year, 100M in three years.

## Options Considered

### Option 1: PostgreSQL
**Pros**: ACID, rich query language, JSON support, mature ecosystem, free
**Cons**: Vertical scaling limits, schema migrations needed

### Option 2: MongoDB
**Pros**: Flexible schema, horizontal scaling built-in, document model
**Cons**: No ACID across documents, query limitations, team lacks experience

### Option 3: MySQL
**Pros**: Familiar, large community, good performance
**Cons**: Weaker JSON support, fewer advanced features than Postgres

## Decision

PostgreSQL because:
1. Data is fundamentally relational (orders reference users and products)
2. ACID guarantees critical for financial transactions
3. JSONB covers flexible attribute needs without separate document store
4. Team expertise reduces ramp-up time
5. Read replicas handle read scaling for projected growth

## Consequences

**Positive**: Strong consistency, powerful queries, team productivity
**Negative**: Schema migrations required for changes, vertical write scaling
**Risks**: Write bottleneck at scale -> Mitigation: Read replicas, connection pooling, consider sharding at 500M+ rows
```

## ADR Naming Convention

File: `docs/adr/ADR-{NNN}-{slug}.md`

Examples:
- `docs/adr/ADR-001-use-postgres-for-primary-datastore.md`
- `docs/adr/ADR-002-async-payment-processing.md`
- `docs/adr/ADR-003-jwt-authentication.md`
- `docs/adr/ADR-010-notification-architecture.md`

## ADR Status Lifecycle

```
Proposed -> Accepted -> [Deprecated | Superseded by ADR-NNN]
```

- **Proposed**: Under review, not yet approved
- **Accepted**: Approved, guides implementation
- **Deprecated**: No longer relevant (system retired)
- **Superseded**: Replaced by a newer ADR (link to replacement)
