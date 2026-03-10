---
name: pattern-transfer
description: >-
  Recognizes problem classes and transfers proven solutions across domains.
  ALWAYS trigger on "I've seen this before", "this is like X but in Y",
  "there must be a pattern", "how do I do X in Y", "equivalent of",
  "similar to", "same concept", "translate this approach", "port this to",
  "cross-language", "idiomatic way". Use when encountering familiar problems
  in unfamiliar contexts or applying concepts across languages/frameworks.
  Different from code-reading which builds mental models of existing code --
  this skill maps known solutions to new domains.
---
<!-- Last reviewed: 2026-03 -->

# Pattern Transfer

## Pattern Recognition Process

### 1. Identify the Problem Class

Ask: "What CATEGORY of problem is this?"

| Surface Symptom | Core Problem Class |
|-----------------|-------------------|
| Notify components when data changes | State observation |
| Multiple async operations need coordination | Async orchestration |
| Expensive computation called repeatedly | Caching |
| Too many requests overload system | Rate limiting |
| Operation fails sometimes | Retry/resilience |
| Transform collection of data | Data transformation |

### 2. Recall Prior Implementations

Ask: "Where have I encountered this problem class before?"

Map all known manifestations across languages, frameworks, and infrastructure layers.

### 3. Extract Canonical Solution

Ask: "What's the ESSENCE?" Strip language-specific syntax down to core steps.

```
Example -- State Management ESSENCE:
1. Central state container
2. Controlled mutation mechanism
3. Change notification system
4. Subscriber registration/unregistration
```

### 4. Map to Local Idioms

Ask: "How is this done HERE?" Translate essence into target domain's conventions, best practices, libraries, and naming.

## Common Pattern Classes

| Pattern Class | Problem | Key Implementations |
|--------------|---------|---------------------|
| State Management | Shared changing data | Redux, databases, event sourcing |
| Async Coordination | Multiple async operations | Promises, asyncio, goroutines |
| Caching | Expensive repeated operations | Memoization, Redis, HTTP cache |
| Rate Limiting | Prevent resource exhaustion | Token bucket, sliding window |
| Retry/Resilience | Handle transient failures | Backoff, circuit breaker |
| Data Transformation | Reshape data | Map/filter/reduce, pipes, LINQ |

See `references/pattern-catalog.md` for detailed essence, manifestations, and transfer examples.

## Transfer Protocol

### Step 1: Extract ESSENCE

Remove language-specific details. Find core idea as numbered steps.

### Step 2: Find IDIOMS

How does target language/framework express this? What libraries exist? What conventions apply?

### Step 3: REIFY

Implement using local conventions. Verify it solves the original problem, not a distorted version.

## Pattern Recognition Checklist

**Classification:**
- [ ] What CATEGORY is this problem?
- [ ] Have I seen this before?
- [ ] What's it called in different contexts?

**Recall:**
- [ ] Where have I solved this?
- [ ] What solutions exist elsewhere?
- [ ] What's the canonical implementation?

**Extraction:**
- [ ] What's the CORE idea?
- [ ] What's language-specific syntax vs essence?
- [ ] What constraints shaped the original?

**Adaptation:**
- [ ] What are idioms HERE?
- [ ] What conventions should I follow?
- [ ] What libraries/tools exist?

**Verification:**
- [ ] Does this solve the RIGHT problem?
- [ ] Is this the SIMPLEST solution?
- [ ] Have I introduced new problems?

## Anti-Patterns

| Anti-Pattern | Symptom | Instead |
|-------------|---------|---------|
| Pattern obsession | SingletonFactoryStrategyAdapter | Solve the actual problem simply |
| Inappropriate transfer | OOP patterns in functional languages | Use target paradigm's strengths |
| Cargo cult | "Saw Redux in tutorial, using everywhere" | Match tool to actual complexity |
| Premature abstraction | Extracting pattern from 1 use case | Wait for 2+ use cases |

## Quick Reference: Pattern Mapping

| When You See | Pattern | Implementations |
|--------------|---------|----------------|
| Notify on change | Observer | Events, hooks, pub/sub, triggers |
| Swap behavior | Strategy | Polymorphism, functions, DI |
| Add features | Decorator | @decorator, HOC, annotations |
| Expensive operation | Memoization | Cache, React.memo, materialized views |
| Too many requests | Rate Limit | Token bucket, throttle, semaphore |
| Transient failures | Retry | Backoff, circuit breaker, timeout |
| Object creation | Builder | Fluent API, config object |
| Single access | Singleton | Module pattern, DI, constants |
| Undo/redo | Command | Event sourcing, action history |
| Transform pipeline | Chain | Streams, LINQ, pipes, map/reduce |

## Integration with Other Skills

| Skill | Integration |
|-------|------------|
| Code Reading | Recognize patterns in unfamiliar codebases faster |
| Estimation | Known patterns have known complexity |
| Language Learning | Map known patterns to new language idioms |
| Debugging | Pattern violations often indicate bugs |

See `references/transfer-examples.md` for multi-scale examples and practice exercises.
