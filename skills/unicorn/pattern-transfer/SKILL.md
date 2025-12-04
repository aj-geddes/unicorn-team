---
name: pattern-transfer
description: >
  Recognize when a problem belongs to a known class and transfer proven solutions across domains.
  Use when encountering problems that "feel familiar", need to apply concepts from one language/framework
  to another, or want to avoid reinventing existing solutions. Triggers: "I've seen this before",
  "This is like X but in Y", "There must be a pattern for this".
---

# Pattern Transfer: The 10X Multiplier

## Core Principle

**A 10X developer sees the SAME problem in different clothes.**

Don't solve problems individually. Recognize problem CLASSES and transfer proven solutions across domains.

When you learn ONE pattern deeply, you know FIVE implementations.

---

## The Pattern Recognition Process

### 1. Identify the Problem Class

Ask: "What CATEGORY of problem is this?"

```
SURFACE SYMPTOM → CORE PROBLEM CLASS

"Need to notify components when data changes" → STATE OBSERVATION
"Multiple async operations need coordination" → ASYNC ORCHESTRATION
"Expensive computation called repeatedly" → CACHING
"Too many requests overload the system" → RATE LIMITING
"Operation fails sometimes" → RETRY/RESILIENCE
"Transform collection of data" → DATA TRANSFORMATION
```

### 2. Recall Where You've Seen This

Ask: "Where have I encountered this problem class before?"

Example: State Management appears as:
- Redux/Vuex/MobX (frontend)
- Observer pattern (OOP)
- Event emitters (Node.js)
- Reactive streams (RxJS)
- Database triggers
- Git (version control)

### 3. Extract the Canonical Solution

Ask: "What's the ESSENCE of how this is solved?"

Strip away language-specific syntax:

```
SURFACE (Redux):
  dispatch(action) → reducer → notify subscribers

ESSENCE:
  1. Central state container
  2. Controlled mutation mechanism
  3. Change notification system
  4. Subscriber registration/unregistration
```

### 4. Map to Local Idioms

Ask: "How is this done HERE?"

Translate essence into target domain's conventions. Use local best practices, libraries, and naming.

---

## Common Pattern Classes

### STATE MANAGEMENT
**Problem**: Multiple components need shared, changing data

**Manifestations**: Redux, databases, useState, actors, event sourcing

**Essence**:
1. Single source of truth
2. Controlled mutation
3. Change notification

**Transfer Example**:
```python
# React → Python
# useState(initial) becomes:

class Stateful:
    def __init__(self, initial):
        self._state = initial
        self._listeners = []

    def set_state(self, new_state):
        self._state = new_state
        for listener in self._listeners:
            listener(self._state)
```

### ASYNC COORDINATION
**Problem**: Multiple async operations working together

**Manifestations**: Promises, asyncio, goroutines, actors, futures

**Essence**:
1. Deferred computation
2. Composition of operations
3. Error propagation
4. Cancellation/timeout

**Transfer Example**:
```go
// Go channels → Python asyncio
// ch := make(chan Result) becomes:

queue = asyncio.Queue()
await queue.put(result)
result = await queue.get()
```

### CACHING
**Problem**: Expensive operations repeated with same inputs

**Manifestations**: Memoization, Redis, HTTP caching, React.memo

**Essence**:
1. Key-value storage
2. Lookup before computation
3. Eviction policy
4. Invalidation strategy

**Transfer Example**:
```python
# HTTP ETag → Application cache
# Cache-Control: max-age=3600 becomes:

from functools import lru_cache

@lru_cache(maxsize=128)
def expensive_operation(key):
    return compute(key)
```

### RATE LIMITING
**Problem**: Prevent resource exhaustion

**Manifestations**: Token bucket, leaky bucket, sliding window, API limits, connection pools

**Essence**:
1. Capacity limit
2. Refill mechanism
3. Rejection strategy
4. Time-based recovery

**Transfer Example**:
```python
# API rate limit → Any resource
class TokenBucket:
    def __init__(self, capacity, refill_rate):
        self.tokens = capacity
        self.capacity = capacity
        self.refill_rate = refill_rate
        self.last_refill = time.time()

    def consume(self, count=1):
        self._refill()
        if self.tokens >= count:
            self.tokens -= count
            return True
        return False  # Rate limited

    def _refill(self):
        elapsed = time.time() - self.last_refill
        new_tokens = elapsed * self.refill_rate
        self.tokens = min(self.capacity, self.tokens + new_tokens)
        self.last_refill = time.time()
```

### RETRY/RESILIENCE
**Problem**: Handle transient failures gracefully

**Manifestations**: Exponential backoff, circuit breaker, bulkhead, TCP retransmission

**Essence**:
1. Detect failure
2. Decide if retryable
3. Wait with increasing delay
4. Eventually give up

**Transfer Example**:
```python
# Fetch retry → Database retry
def retry_with_backoff(max_retries=3, base_delay=1):
    def decorator(func):
        def wrapper(*args, **kwargs):
            for attempt in range(max_retries):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    if attempt == max_retries - 1:
                        raise
                    time.sleep(base_delay * (2 ** attempt))
        return wrapper
    return decorator

@retry_with_backoff()
def db_query(sql):
    return database.execute(sql)
```

### DATA TRANSFORMATION
**Problem**: Transform data from one shape to another

**Manifestations**: Map/filter/reduce, LINQ, streams, list comprehensions, Unix pipes

**Essence**:
1. Pipeline of transformations
2. Composable operations
3. Declarative over imperative

**Transfer Example**:
```bash
# Unix pipes → Python
# cat data.txt | grep "error" | sort | uniq -c | sort -rn

from collections import Counter
errors = [line for line in open('data.txt') if 'error' in line]
Counter(errors).most_common()
```

---

## Patterns Are Fractal

Same pattern at different scales:

### Observer Pattern Everywhere

```
"Notify interested parties when something changes"

Object-level (OOP):     class Subject: attach(observer), notify()
Component-level (React): useEffect(() => {...}, [dependency])
Service-level (Pub/Sub): redis.subscribe('events', callback)
System-level (Webhooks): POST https://site.com/webhook
Database-level (SQL):    CREATE TRIGGER notify_on_change...

ALL ARE THE SAME PATTERN
```

### Producer-Consumer Everywhere

```
"Decouple production from consumption with buffer"

Python threads:  queue.put(item) / queue.get()
RabbitMQ:        channel.basic_publish() / basic_consume()
Kafka:           producer.send() / consumer.subscribe()
Go channels:     ch <- value / value := <-ch

ALL SOLVE SAME PROBLEM
```

### Strategy Pattern Everywhere

```
"Swap algorithm at runtime"

Sorting:        sorter.set_strategy(QuickSort())
Payment:        checkout.set_payment_method(CreditCard())
Compression:    compressor = GzipCompressor()  # or Zip
React:          const View = isMobile ? Mobile : Desktop

SAME PATTERN, DIFFERENT DOMAINS
```

---

## The Transfer Protocol

### Step 1: Extract ESSENCE

Remove language-specific details. Find core idea.

```python
# CONCRETE (React)
const [count, setCount] = useState(0);
useEffect(() => { document.title = `Count: ${count}`; }, [count]);

# ESSENCE
"""
1. Store mutable value
2. Provide setter
3. Run side effect on change
4. Declare dependencies
"""
```

### Step 2: Find IDIOMS

How does target language/framework do this?

```go
// Go idioms: channels + goroutines
type State struct {
    count int
    onChange chan int
}

func (s *State) SetCount(n int) {
    s.count = n
    s.onChange <- n
}

go func() {
    for count := range state.onChange {
        fmt.Printf("Count: %d\n", count)
    }
}()
```

### Step 3: REIFY

Implement using local conventions.

```python
# Python idioms: properties + callbacks
class ReactiveState:
    def __init__(self, initial: int):
        self._value = initial
        self._effects = []

    @property
    def value(self) -> int:
        return self._value

    @value.setter
    def value(self, new: int) -> None:
        self._value = new
        for effect in self._effects:
            effect(self._value)

    def use_effect(self, effect):
        self._effects.append(effect)

state = ReactiveState(0)
state.use_effect(lambda v: print(f"Value: {v}"))
state.value = 42  # Triggers effect
```

---

## Pattern Recognition Checklist

Before implementing, ask:

**Classification**:
- What CATEGORY is this problem?
- Have I seen this before?
- What's it called in different contexts?

**Recall**:
- Where have I solved this?
- What solutions exist elsewhere?
- What's the canonical implementation?

**Extraction**:
- What's the CORE idea?
- What's language-specific syntax?
- What constraints shaped the original?

**Adaptation**:
- What are idioms HERE?
- What conventions should I follow?
- What libraries/tools exist?

**Verification**:
- Does this solve the RIGHT problem?
- Is this the SIMPLEST solution?
- Have I introduced new problems?

---

## Anti-Patterns

### Pattern Obsession
```python
# BAD: Patterns for sake of patterns
class SingletonFactoryStrategyAdapter: pass

# GOOD: Solve actual problem
def get_config(): return {"key": "value"}
```

### Inappropriate Transfer
Don't import OOP patterns into functional languages. Use target paradigm's strengths.

### Cargo Cult Pattern
```javascript
// BAD: Using without understanding
// "Saw Redux in tutorial, using everywhere"

// GOOD: Use appropriate tool
const [state, setState] = useState(initial);  // Simple state
// Redux only when actually needed
```

### Premature Abstraction
Wait for 2+ use cases before extracting pattern.

---

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

---

## Integration with Other Skills

**With Code Reading**: Recognize patterns in unfamiliar codebases faster

**With Estimation**: Known patterns have known complexity

**With Language Learning**: Map known patterns to new language idioms

**With Debugging**: Pattern violations often indicate bugs

---

## Remember

```
You don't need 1000 solutions memorized.
You need to recognize 20 problem classes
and know where to find implementations.

The 10X multiplier is RECOGNITION, not RECALL.
```

---

## Practice Examples

### Recognize the Pattern

**Debounce function**:
```javascript
function debounce(fn, delay) {
    let timer;
    return (...args) => {
        clearTimeout(timer);
        timer = setTimeout(() => fn(...args), delay);
    };
}
```
**Answer**: RATE LIMITING / BATCHING (limits execution frequency)

**SQL Transaction**:
```sql
BEGIN TRANSACTION;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;
```
**Answer**: ATOMIC OPERATIONS (all or nothing)

**Python Decorator**:
```python
def log_calls(func):
    def wrapper(*args):
        print(f"Calling {func.__name__}")
        return func(*args)
    return wrapper
```
**Answer**: ASPECT-ORIENTED / DECORATOR (add behavior without modifying original)

Transfer these patterns to different contexts using the 3-step protocol: Extract, Find Idioms, Reify.
