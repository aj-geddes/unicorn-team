# Pattern Mapping

## Core Pattern Equivalence Table

### Data Structures

| Concept | Python | JavaScript | Go | Rust |
|---------|--------|------------|-----|------|
| Dictionary/Map | `dict` | `Object` or `Map` | `map[string]interface{}` | `HashMap<K, V>` |
| List/Array | `list` | `Array` | `[]T` (slice) | `Vec<T>` |
| Set | `set` | `Set` | `map[T]struct{}` | `HashSet<T>` |
| Tuple | `tuple` | N/A (use array) | N/A (use struct) | `(T1, T2)` |
| Optional | `None` / `Optional[T]` | `null` / `undefined` | `*T` (nil pointer) | `Option<T>` |

### Iteration

| Concept | Python | JavaScript | Go | Rust |
|---------|--------|------------|-----|------|
| List comprehension | `[x*2 for x in items]` | `items.map(x => x*2)` | `for range` + `append` | `iter().map().collect()` |
| Filter | `[x for x in items if pred(x)]` | `items.filter(pred)` | `for range` + `if` + `append` | `iter().filter().collect()` |
| Reduce | `functools.reduce(f, items)` | `items.reduce(f, init)` | manual loop | `iter().fold(init, f)` |
| Enumerate | `enumerate(items)` | `items.entries()` | `for i, v := range items` | `iter().enumerate()` |

### Error Handling

| Concept | Python | JavaScript | Go | Rust |
|---------|--------|------------|-----|------|
| Paradigm | Exceptions | Exceptions | Error values | Result types |
| Raise/throw | `raise Exception()` | `throw new Error()` | `return fmt.Errorf()` | `Err(e)` / `anyhow!()` |
| Catch/handle | `try/except` | `try/catch` | `if err != nil` | `match` / `?` operator |
| Wrap context | `raise X from e` | `new Error(msg, {cause})` | `fmt.Errorf("ctx: %w", err)` | `.context("msg")` |
| Propagate | `raise` (re-raise) | `throw` (re-throw) | `return err` | `?` operator |

### Async/Concurrency

| Concept | Python | JavaScript | Go | Rust |
|---------|--------|------------|-----|------|
| Model | `async/await` | `async/await` | goroutines + channels | `async/await` + tokio |
| Start async | `asyncio.create_task()` | `Promise` | `go func()` | `tokio::spawn()` |
| Wait all | `asyncio.gather()` | `Promise.all()` | `sync.WaitGroup` | `join!()` / `try_join!()` |
| Channel | `asyncio.Queue` | N/A (use events) | `chan T` | `tokio::sync::mpsc` |
| Mutex | `threading.Lock` | N/A (single-threaded) | `sync.Mutex` | `std::sync::Mutex` |

### Functions

| Concept | Python | JavaScript | Go | Rust |
|---------|--------|------------|-----|------|
| Decorator | `@decorator` | HOF or TC39 decorators | function returning function | proc macro (advanced) |
| Lambda | `lambda x: x*2` | `x => x*2` | `func(x int) int { return x*2 }` | `\|x\| x*2` |
| Default args | `def f(x=5)` | `function f(x=5)` | N/A (use variadic or options) | N/A (use `Option` or builder) |
| Multiple return | `return a, b` | `return [a, b]` or object | `return a, b` | `(a, b)` tuple |

### Resource Management

| Concept | Python | JavaScript | Go | Rust |
|---------|--------|------------|-----|------|
| Cleanup | `with` statement | `try/finally` or `using` | `defer` | RAII (Drop trait) |
| File I/O | `with open(f) as fh:` | `fs.readFile` (callback/promise) | `os.Open` + `defer Close` | `File::open` + `?` |

## Token Bucket Pattern (Cross-Language Example)

### Python (Canonical)

```python
class TokenBucket:
    def __init__(self, capacity, refill_rate):
        self.capacity = capacity
        self.tokens = capacity
        self.refill_rate = refill_rate
        self.last_refill = now()

    def consume(self, tokens=1):
        self._refill()
        if self.tokens >= tokens:
            self.tokens -= tokens
            return True
        return False

    def _refill(self):
        elapsed = now() - self.last_refill
        new_tokens = elapsed * self.refill_rate
        self.tokens = min(self.capacity, self.tokens + new_tokens)
        self.last_refill = now()
```

### Go (Idiomatic -- uses channels and goroutines)

```go
type TokenBucket struct {
    capacity    int
    tokens      chan struct{}
    refillRate  time.Duration
    done        chan struct{}
}

func NewTokenBucket(capacity int, refillRate time.Duration) *TokenBucket {
    tb := &TokenBucket{
        capacity:   capacity,
        tokens:     make(chan struct{}, capacity),
        refillRate: refillRate,
        done:       make(chan struct{}),
    }

    for i := 0; i < capacity; i++ {
        tb.tokens <- struct{}{}
    }

    go tb.refill()
    return tb
}

func (tb *TokenBucket) Consume() bool {
    select {
    case <-tb.tokens:
        return true
    default:
        return false
    }
}

func (tb *TokenBucket) refill() {
    ticker := time.NewTicker(tb.refillRate)
    defer ticker.Stop()

    for {
        select {
        case <-ticker.C:
            select {
            case tb.tokens <- struct{}{}:
            default: // bucket full
            }
        case <-tb.done:
            return
        }
    }
}
```

## Verification Checklist (After Pattern Transfer)

- [ ] Follows language naming conventions (camelCase vs snake_case)
- [ ] Uses idiomatic error handling (exceptions, error values, Result types)
- [ ] Applies standard library patterns (io.Reader, Iterator trait, etc.)
- [ ] Matches community testing conventions
- [ ] Includes appropriate documentation format
