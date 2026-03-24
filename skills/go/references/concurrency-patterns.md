# Concurrency Patterns

Go's concurrency model is built on goroutines (lightweight threads) and channels
(typed communication pipes). The mantra: **don't communicate by sharing memory;
share memory by communicating.**

## Goroutines

```go
// Goroutines are cheap (~2KB stack, grows dynamically)
// Launch thousands without concern
go processItem(item)

// Always ensure goroutines can exit
// BAD: goroutine leak
go func() {
    for msg := range ch { // if ch is never closed, this blocks forever
        process(msg)
    }
}()

// GOOD: context-controlled exit
go func() {
    for {
        select {
        case msg := <-ch:
            process(msg)
        case <-ctx.Done():
            return
        }
    }
}()
```

## Channels

```go
// Unbuffered: synchronous handoff (sender blocks until receiver is ready)
ch := make(chan int)

// Buffered: async up to capacity (sender blocks when full)
ch := make(chan int, 100)

// Directional channels in function signatures
func producer(out chan<- int) { out <- 42 }  // send-only
func consumer(in <-chan int)  { v := <-in }  // receive-only

// Close signals "no more values" -- receivers get zero value after drain
close(ch)

// Range over channel until closed
for msg := range ch {
    process(msg)
}

// Check if channel was closed
val, ok := <-ch
if !ok {
    // channel is closed and drained
}
```

### Channel Patterns

```go
// Done channel (signal completion)
done := make(chan struct{})
go func() {
    defer close(done)
    doWork()
}()
<-done // wait for completion

// Semaphore (limit concurrency)
sem := make(chan struct{}, maxConcurrent)
for _, item := range items {
    sem <- struct{}{}  // acquire
    go func() {
        defer func() { <-sem }()  // release
        process(item)
    }()
}
// Wait for all to finish
for i := 0; i < maxConcurrent; i++ {
    sem <- struct{}{}
}
```

## Select Statement

```go
// Multiplex across channels -- first ready wins
select {
case msg := <-msgCh:
    handle(msg)
case err := <-errCh:
    return err
case <-time.After(5 * time.Second):
    return ErrTimeout
case <-ctx.Done():
    return ctx.Err()
}

// Non-blocking channel operations
select {
case msg := <-ch:
    handle(msg)
default:
    // ch not ready, do something else
}

// Priority select (check high-priority first)
for {
    // Always check cancellation first
    select {
    case <-ctx.Done():
        return ctx.Err()
    default:
    }

    select {
    case highPri := <-highCh:
        handleHigh(highPri)
    case <-ctx.Done():
        return ctx.Err()
    default:
        select {
        case lowPri := <-lowCh:
            handleLow(lowPri)
        case <-ctx.Done():
            return ctx.Err()
        }
    }
}
```

## errgroup (Structured Concurrency)

`golang.org/x/sync/errgroup` is the standard for managing groups of goroutines
that can fail. It handles waiting, error propagation, and context cancellation.

```go
import "golang.org/x/sync/errgroup"

// Basic: run N tasks, wait for all, return first error
func FetchAll(ctx context.Context, urls []string) ([]Response, error) {
    g, ctx := errgroup.WithContext(ctx)
    responses := make([]Response, len(urls))

    for i, url := range urls {
        g.Go(func() error {
            resp, err := fetch(ctx, url)
            if err != nil {
                return fmt.Errorf("fetching %s: %w", url, err)
            }
            responses[i] = resp
            return nil
        })
    }

    if err := g.Wait(); err != nil {
        return nil, err
    }
    return responses, nil
}

// With concurrency limit (Go 1.20+)
func ProcessBatch(ctx context.Context, items []Item) error {
    g, ctx := errgroup.WithContext(ctx)
    g.SetLimit(10)  // max 10 concurrent goroutines

    for _, item := range items {
        g.Go(func() error {
            return processItem(ctx, item)
        })
    }
    return g.Wait()
}

// TryGo: non-blocking submission (respects SetLimit)
g.SetLimit(5)
for _, item := range items {
    if !g.TryGo(func() error {
        return process(item)
    }) {
        // All slots full, handle backpressure
        log.Warn("worker pool full, waiting")
        g.Go(func() error { return process(item) })
    }
}
```

## Worker Pool

```go
// Fixed-size worker pool with input/output channels
func WorkerPool(ctx context.Context, jobs <-chan Job, workers int) <-chan Result {
    results := make(chan Result)
    var wg sync.WaitGroup

    for i := 0; i < workers; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            for {
                select {
                case job, ok := <-jobs:
                    if !ok {
                        return  // jobs channel closed
                    }
                    result := processJob(ctx, job)
                    select {
                    case results <- result:
                    case <-ctx.Done():
                        return
                    }
                case <-ctx.Done():
                    return
                }
            }
        }()
    }

    // Close results when all workers done
    go func() {
        wg.Wait()
        close(results)
    }()

    return results
}

// Usage
jobs := make(chan Job, 100)
results := WorkerPool(ctx, jobs, runtime.NumCPU())

// Feed jobs
go func() {
    defer close(jobs)
    for _, item := range items {
        jobs <- Job{Item: item}
    }
}()

// Collect results
for result := range results {
    fmt.Println(result)
}
```

## Fan-Out / Fan-In

```go
// Fan-out: distribute work from one source to N workers
func fanOut(ctx context.Context, input <-chan int, workers int) []<-chan int {
    channels := make([]<-chan int, workers)
    for i := 0; i < workers; i++ {
        channels[i] = worker(ctx, input)
    }
    return channels
}

func worker(ctx context.Context, input <-chan int) <-chan int {
    out := make(chan int)
    go func() {
        defer close(out)
        for val := range input {
            select {
            case out <- transform(val):
            case <-ctx.Done():
                return
            }
        }
    }()
    return out
}

// Fan-in: merge N channels into one
func fanIn(ctx context.Context, channels ...<-chan int) <-chan int {
    merged := make(chan int)
    var wg sync.WaitGroup

    for _, ch := range channels {
        wg.Add(1)
        go func() {
            defer wg.Done()
            for val := range ch {
                select {
                case merged <- val:
                case <-ctx.Done():
                    return
                }
            }
        }()
    }

    go func() {
        wg.Wait()
        close(merged)
    }()

    return merged
}
```

## Pipeline Pattern

```go
// Compose processing stages via channels
func pipeline(ctx context.Context, input []int) <-chan int {
    // Stage 1: generate
    gen := func() <-chan int {
        out := make(chan int)
        go func() {
            defer close(out)
            for _, v := range input {
                select {
                case out <- v:
                case <-ctx.Done():
                    return
                }
            }
        }()
        return out
    }

    // Stage 2: square
    square := func(in <-chan int) <-chan int {
        out := make(chan int)
        go func() {
            defer close(out)
            for v := range in {
                select {
                case out <- v * v:
                case <-ctx.Done():
                    return
                }
            }
        }()
        return out
    }

    // Stage 3: filter (keep even)
    filter := func(in <-chan int) <-chan int {
        out := make(chan int)
        go func() {
            defer close(out)
            for v := range in {
                if v%2 == 0 {
                    select {
                    case out <- v:
                    case <-ctx.Done():
                        return
                    }
                }
            }
        }()
        return out
    }

    // Compose: generate -> square -> filter
    return filter(square(gen()))
}
```

## Context Propagation

```go
import "context"

// Always pass context as first parameter
func ProcessRequest(ctx context.Context, req *Request) error {
    // Timeout: auto-cancel after deadline
    ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
    defer cancel()

    // Carry request-scoped values (use sparingly)
    ctx = context.WithValue(ctx, requestIDKey, req.ID)

    // Check cancellation in long loops
    for _, item := range req.Items {
        if err := ctx.Err(); err != nil {
            return fmt.Errorf("processing cancelled: %w", err)
        }
        if err := processItem(ctx, item); err != nil {
            return err
        }
    }
    return nil
}

// Context rules:
// 1. First parameter, named ctx
// 2. Never store in a struct
// 3. Never pass nil -- use context.TODO() if unsure
// 4. WithValue only for request-scoped data (trace IDs, auth),
//    not function parameters
```

## sync Package

```go
// Mutex for protecting shared state
type SafeCounter struct {
    mu sync.Mutex
    v  map[string]int
}

func (c *SafeCounter) Inc(key string) {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.v[key]++
}

func (c *SafeCounter) Get(key string) int {
    c.mu.Lock()
    defer c.mu.Unlock()
    return c.v[key]
}

// RWMutex: multiple concurrent readers, exclusive writer
type Cache struct {
    mu    sync.RWMutex
    items map[string]Item
}

func (c *Cache) Get(key string) (Item, bool) {
    c.mu.RLock()
    defer c.mu.RUnlock()
    item, ok := c.items[key]
    return item, ok
}

func (c *Cache) Set(key string, item Item) {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.items[key] = item
}

// sync.Once for one-time initialization
var (
    instance *Database
    once     sync.Once
)

func GetDB() *Database {
    once.Do(func() {
        instance = connectToDB()
    })
    return instance
}

// sync.WaitGroup for waiting on goroutines
var wg sync.WaitGroup
for _, url := range urls {
    wg.Add(1)
    go func() {
        defer wg.Done()
        fetch(url)
    }()
}
wg.Wait()

// sync.Map for concurrent map access (prefer regular map + mutex in most cases)
var m sync.Map
m.Store("key", "value")
val, ok := m.Load("key")
m.Range(func(key, value any) bool {
    fmt.Println(key, value)
    return true  // continue iteration
})

// sync.Pool for reusable temporary objects (reduces GC pressure)
var bufPool = sync.Pool{
    New: func() any { return new(bytes.Buffer) },
}

func process() {
    buf := bufPool.Get().(*bytes.Buffer)
    defer func() {
        buf.Reset()
        bufPool.Put(buf)
    }()
    // use buf...
}
```

## Atomic Operations

```go
import "sync/atomic"

// Atomic counter (lock-free)
var counter atomic.Int64

counter.Add(1)
counter.Add(-1)
val := counter.Load()

// Atomic pointer (Go 1.19+)
var current atomic.Pointer[Config]

current.Store(&Config{Debug: true})
cfg := current.Load()

// Atomic bool
var ready atomic.Bool
ready.Store(true)
if ready.Load() {
    // ...
}
```

## Common Pitfalls

### 1. Goroutine Leak
```go
// BAD: goroutine never exits if nobody reads result
go func() {
    result <- expensiveComputation()  // blocks forever
}()

// GOOD: use select with context
go func() {
    val := expensiveComputation()
    select {
    case result <- val:
    case <-ctx.Done():
    }
}()
```

### 2. Race Condition
```go
// BAD: concurrent map writes panic
go func() { m["a"] = 1 }()
go func() { m["b"] = 2 }()  // fatal: concurrent map writes

// GOOD: protect with mutex or use sync.Map
mu.Lock()
m["a"] = 1
mu.Unlock()
```

### 3. Closure Capture in Loops
```go
// Pre Go 1.22: variable captured by reference
for _, url := range urls {
    go func() {
        fetch(url)  // all goroutines see the LAST url
    }()
}

// Go 1.22+: loop variables are per-iteration (fixed)
// For pre-1.22: shadow the variable
for _, url := range urls {
    url := url  // shadow
    go func() {
        fetch(url)  // correct
    }()
}
```

### 4. Forgetting to Close Channels
```go
// BAD: consumer blocks forever on range
go func() {
    for _, v := range items {
        ch <- v
    }
    // missing close(ch)!
}()
for v := range ch { /* blocks forever */ }

// GOOD: always close when done sending
go func() {
    defer close(ch)
    for _, v := range items {
        ch <- v
    }
}()
```

## Decision Table

| Need | Use | Why |
|------|-----|-----|
| Wait for N tasks, stop on first error | `errgroup.WithContext` | Structured, cancellation built in |
| Fixed concurrency limit | `errgroup.SetLimit(N)` or semaphore channel | Prevent resource exhaustion |
| Protect shared state | `sync.Mutex` or `sync.RWMutex` | Simple, well-understood |
| One-time init | `sync.Once` | Thread-safe, lazy |
| Lock-free counters/flags | `sync/atomic` | No lock overhead |
| Stream processing | Channel pipeline | Composable stages |
| Request cancellation | `context.Context` | Propagates through call tree |
| Reuse temporary objects | `sync.Pool` | Reduce GC pressure |
| Timeout on operation | `context.WithTimeout` + `select` | Clean cancellation |
