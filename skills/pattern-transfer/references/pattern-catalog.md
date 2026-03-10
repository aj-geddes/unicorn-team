# Pattern Catalog

### STATE MANAGEMENT
**Problem**: Multiple components need shared, changing data

**Manifestations**: Redux, databases, useState, actors, event sourcing

**Essence**:
1. Single source of truth
2. Controlled mutation
3. Change notification

**Transfer Example**:
```python
# React -> Python
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
// Go channels -> Python asyncio
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
# HTTP ETag -> Application cache
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
# API rate limit -> Any resource
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
# Fetch retry -> Database retry
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
# Unix pipes -> Python
# cat data.txt | grep "error" | sort | uniq -c | sort -rn

from collections import Counter
errors = [line for line in open('data.txt') if 'error' in line]
Counter(errors).most_common()
```
