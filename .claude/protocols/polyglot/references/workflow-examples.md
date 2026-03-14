# Workflow Examples

## Workflow 1: Learning a New Language

```
User: "We need to build a service in Rust. I've never used it."

Polyglot Agent:

Phase 1: Exploration (30 min)
  - Install rustc, cargo
  - cargo new hello-service
  - cargo run
  - Quick reference: basic syntax

Phase 2: Patterns (60 min)
  - Ownership and borrowing (unique to Rust)
  - Result<T, E> for error handling
  - Pattern matching
  - Iterators and closures

Phase 3: Ecosystem (60 min)
  - cargo test
  - tokio for async
  - serde for serialization
  - axum/actix-web for HTTP

Phase 4: Idioms (45 min)
  - rustfmt for formatting
  - clippy for linting
  - No null -- use Option<T>
  - Prefer iterators over loops

Phase 5: Production (45 min)
  - tracing for logging
  - Config via environment + config files
  - Cross-compilation for deployment
  - Common security patterns

Total: ~4 hours to productive

Return: Complete quick reference + handoff to Developer agent
```

## Workflow 2: Pattern Transfer

```
User: "How do I implement retry logic with exponential backoff in Go?"

Polyglot Agent:

1. Recognize Pattern Class: Retry with backoff
   - Common in distributed systems, API clients

2. Canonical Pattern:
   - Attempt operation
   - If failure, wait with exponential delay
   - Add jitter to prevent thundering herd
   - Max retries to prevent infinite loops
   - Return final error or success

3. Map to Go Idioms:
   - Error handling via error return
   - time.Sleep for delays
   - context.Context for cancellation
   - Functions as first-class values
```

### Go Implementation (Idiomatic)

```go
func RetryWithBackoff(
    ctx context.Context,
    operation func() error,
    maxRetries int,
    baseDelay time.Duration,
) error {
    var err error

    for attempt := 0; attempt < maxRetries; attempt++ {
        if ctx.Err() != nil {
            return ctx.Err()
        }

        err = operation()
        if err == nil {
            return nil
        }

        if attempt == maxRetries-1 {
            break
        }

        delay := baseDelay * time.Duration(1<<attempt)
        jitter := time.Duration(rand.Int63n(int64(delay / 2)))

        select {
        case <-time.After(delay + jitter):
            continue
        case <-ctx.Done():
            return ctx.Err()
        }
    }

    return fmt.Errorf("failed after %d attempts: %w", maxRetries, err)
}
```

## Workflow 3: Cross-Language Migration

```
User: "Port this Python data pipeline to Go"

Polyglot Agent:

1. Analyze Python Code
   - Read codebase (code-reading skill)
   - Identify patterns used
   - Map dependencies
   - Understand data flow

2. Map Patterns Python -> Go
   - List comprehensions -> for range with append
   - Generators -> channels or iterators
   - Decorators -> higher-order functions
   - Context managers -> defer
   - Exceptions -> error returns
   - asyncio -> goroutines + channels

3. Identify Go Equivalents
   - pandas -> gonum or custom structs
   - requests -> net/http
   - click -> cobra
   - pytest -> testing + testify

4. Create Migration Plan
   - Phase 1: Core data structures
   - Phase 2: Processing logic
   - Phase 3: I/O operations
   - Phase 4: Error handling
   - Phase 5: Testing

Return: Migration guide + pattern mappings + hand off to Developer
```

## Agent Interaction Flows

### With Developer Agent

```
Polyglot learns language/pattern
    |
    v
Transfers knowledge to Developer
    |
    v
Developer implements with new knowledge
    |
    v
QA validates with language-specific tests
```

### With Architect Agent

```
Architect identifies technology requirements
    |
    v
Polyglot evaluates language fit
    |
    v
Provides ecosystem analysis
    |
    v
Architect makes informed decision
```

### With Orchestrator

```
Orchestrator detects unknown language
    |
    v
Delegates to Polyglot for learning
    |
    v
Polyglot returns quick reference
    |
    v
Orchestrator delegates implementation to Developer
```
