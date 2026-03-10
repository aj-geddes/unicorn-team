# Language Comparison Matrices

Comprehensive reference for comparing languages across multiple dimensions. Use this when learning a new language to quickly identify equivalent patterns and unique features.

---

## Error Handling Comparison

| Language   | Mechanism          | Example                                  | Pros                      | Cons                    |
|------------|--------------------|-----------------------------------------|---------------------------|-------------------------|
| Python     | Exceptions         | `try/except`                            | Clean happy path          | Hidden control flow     |
| JavaScript | Exceptions         | `try/catch`                             | Familiar to most          | Easy to ignore          |
| Go         | Error returns      | `if err != nil { return err }`          | Explicit, impossible to ignore | Verbose               |
| Rust       | Result<T, E>       | `match result { Ok() => ... Err() => }`| Type-safe, composable     | More syntax             |
| Java       | Checked exceptions | `throws IOException`                    | Forces handling           | Ceremony, often ignored |
| C          | Error codes        | `if (ret < 0) { ... }`                  | Simple, fast              | Easy to ignore          |
| Elixir     | Pattern matching   | `{:ok, value} / {:error, reason}`       | Pipeable, clean           | Requires discipline     |
| Haskell    | Either/Maybe       | `case either of Left e -> Right v ->`   | Pure, composable          | Steep learning curve    |
| Swift      | Result/throws      | `try catch`, `Result<T, Error>`         | Flexible, type-safe       | Two different systems   |
| Kotlin     | Exceptions         | `try/catch`, nullable types             | Null safety built-in      | Still has exceptions    |

### Error Handling Patterns by Language

**Python:**
```python
# Basic exception handling
try:
    result = risky_operation()
except ValueError as e:
    handle_error(e)
except Exception as e:
    log_error(e)
    raise
finally:
    cleanup()

# Context managers (automatic cleanup)
with open('file.txt') as f:
    content = f.read()
```

**Go:**
```go
// Explicit error handling (idiomatic)
result, err := riskyOperation()
if err != nil {
    return fmt.Errorf("operation failed: %w", err)
}

// Multiple return values
data, err := readFile("config.json")
if err != nil {
    log.Fatal(err)
}

// Defer for cleanup
defer file.Close()
```

**Rust:**
```rust
// Result type with ? operator
fn process() -> Result<Data, Error> {
    let file = File::open("data.txt")?;
    let data = parse_file(file)?;
    Ok(data)
}

// Pattern matching
match read_file("config.json") {
    Ok(data) => process(data),
    Err(e) => eprintln!("Error: {}", e),
}

// Option for nullable values
if let Some(value) = optional_value {
    println!("Got: {}", value);
}
```

**Elixir:**
```elixir
# Pattern matching on tuples
case File.read("config.json") do
  {:ok, content} -> process(content)
  {:error, reason} -> IO.puts("Error: #{reason}")
end

# Pipeline with error handling
"data.txt"
|> File.read()
|> case do
  {:ok, data} -> parse(data)
  error -> error
end
```

---

## Async/Concurrency Comparison

| Language   | Model              | Syntax                                  | Lightweight? | Difficulty | Max Concurrent |
|------------|--------------------|-----------------------------------------|--------------|------------|----------------|
| Python     | asyncio            | `async def`, `await`                    | No           | Medium     | ~10K           |
| JavaScript | Event loop         | `async/await`, Promises                 | Yes          | Medium     | ~100K+         |
| Go         | Goroutines         | `go func()`, channels                   | Yes          | Low        | ~1M+           |
| Rust       | async/await        | `async fn`, futures, tokio              | Yes          | High       | ~1M+           |
| Java       | Threads            | `new Thread()`, CompletableFuture       | No           | Medium     | ~1K            |
| C#         | async/await        | `async Task`, `await`                   | Yes          | Low        | ~100K+         |
| Elixir     | Actor model        | `spawn`, message passing                | Yes          | Medium     | ~10M+          |
| Kotlin     | Coroutines         | `suspend fun`, `launch`, `async`        | Yes          | Low        | ~100K+         |
| Swift      | async/await        | `async func`, `await`, actors           | Yes          | Medium     | ~100K+         |
| C++        | Threads/futures    | `std::thread`, `std::async`             | No           | High       | ~1K            |

### Async Patterns by Language

**JavaScript (Event Loop):**
```javascript
// Promise-based
fetch('https://api.example.com/data')
  .then(response => response.json())
  .then(data => process(data))
  .catch(error => console.error(error));

// Async/await
async function fetchData() {
  try {
    const response = await fetch('https://api.example.com/data');
    const data = await response.json();
    return process(data);
  } catch (error) {
    console.error(error);
  }
}

// Parallel execution
const [user, posts, comments] = await Promise.all([
  fetchUser(),
  fetchPosts(),
  fetchComments()
]);
```

**Go (Goroutines + Channels):**
```go
// Launch goroutine
go func() {
    result := expensiveOperation()
    resultChan <- result
}()

// Channels for communication
ch := make(chan int)
go producer(ch)
go consumer(ch)

// Select for multiplexing
select {
case msg := <-ch1:
    handle(msg)
case msg := <-ch2:
    handle(msg)
case <-timeout:
    handleTimeout()
}

// Worker pool pattern
jobs := make(chan Job, 100)
for i := 0; i < numWorkers; i++ {
    go worker(jobs)
}
```

**Rust (async/await + tokio):**
```rust
// Async function
async fn fetch_data(url: &str) -> Result<Data, Error> {
    let response = reqwest::get(url).await?;
    let data = response.json().await?;
    Ok(data)
}

// Spawn tasks
let handle1 = tokio::spawn(async { fetch_user() });
let handle2 = tokio::spawn(async { fetch_posts() });

// Join multiple futures
let (user, posts) = tokio::join!(fetch_user(), fetch_posts());

// Select first completed
tokio::select! {
    result = operation1() => handle(result),
    result = operation2() => handle(result),
}
```

**Python (asyncio):**
```python
# Async function
async def fetch_data(url):
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as response:
            return await response.json()

# Run multiple tasks
results = await asyncio.gather(
    fetch_user(),
    fetch_posts(),
    fetch_comments()
)

# Event loop
asyncio.run(main())
```

**Elixir (Actor Model):**
```elixir
# Spawn process
pid = spawn(fn -> worker() end)

# Send message
send(pid, {:process, data})

# Receive message
receive do
  {:process, data} -> handle(data)
  {:stop} -> :ok
after
  5000 -> :timeout
end

# GenServer (OTP abstraction)
GenServer.call(server, {:get, key})
GenServer.cast(server, {:set, key, value})
```

---

## Memory Management Comparison

| Language   | Strategy           | Developer Control | Performance | Safety     | GC Pause | Predictability |
|------------|--------------------|-------------------|-------------|------------|----------|----------------|
| Python     | GC (reference)     | None              | Slow        | Very safe  | Yes      | Low            |
| JavaScript | GC (mark-sweep)    | None              | Slow        | Very safe  | Yes      | Low            |
| Go         | GC (concurrent)    | Minimal           | Medium      | Very safe  | Minimal  | Medium         |
| Rust       | Ownership          | Full              | Fast        | Very safe  | None     | High           |
| C          | Manual             | Full              | Fast        | Unsafe     | None     | High           |
| C++        | Manual + RAII      | Full              | Fast        | Semi-safe  | None     | High           |
| Java       | GC (generational)  | Minimal           | Medium      | Very safe  | Yes      | Low            |
| C#         | GC (generational)  | Minimal           | Medium      | Very safe  | Yes      | Low            |
| Swift      | ARC                | Minimal           | Fast        | Safe       | None     | High           |
| Zig        | Manual + comptime  | Full              | Fast        | Semi-safe  | None     | High           |

### Memory Management Patterns

**Rust (Ownership):**
```rust
// Ownership transfer
let s1 = String::from("hello");
let s2 = s1; // s1 is now invalid

// Borrowing (immutable)
fn read_string(s: &String) {
    println!("{}", s);
}

// Mutable borrowing
fn modify_string(s: &mut String) {
    s.push_str(" world");
}

// Lifetimes
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() { x } else { y }
}

// RAII pattern
{
    let file = File::open("data.txt")?;
    // use file
} // file automatically closed
```

**C++ (RAII + Smart Pointers):**
```cpp
// Unique ownership
std::unique_ptr<Widget> widget = std::make_unique<Widget>();

// Shared ownership
std::shared_ptr<Data> data = std::make_shared<Data>();

// RAII pattern
{
    std::lock_guard<std::mutex> lock(mutex);
    // critical section
} // lock automatically released

// Custom deleter
auto deleter = [](FILE* fp) { fclose(fp); };
std::unique_ptr<FILE, decltype(deleter)> file(fopen("data.txt", "r"), deleter);
```

**Go (Garbage Collection):**
```go
// No manual memory management
data := make([]byte, 1024)

// Sync.Pool for object reuse
var bufferPool = sync.Pool{
    New: func() interface{} {
        return new(bytes.Buffer)
    },
}

// Get from pool
buffer := bufferPool.Get().(*bytes.Buffer)
defer bufferPool.Put(buffer)
```

**Swift (ARC):**
```swift
// Strong reference (default)
let object = MyClass()

// Weak reference (avoid cycles)
weak var delegate: Delegate?

// Unowned reference (known non-nil)
unowned let parent: Parent

// Capture list in closures
someFunction { [weak self] in
    self?.doSomething()
}
```

---

## Type Systems Comparison

| Language   | Type System        | Inference | Null Safety | Generic Support | Structural/Nominal |
|------------|--------------------|-----------|-------------|-----------------|--------------------|
| Python     | Dynamic, optional  | N/A       | No          | Yes (3.5+)      | Duck typing        |
| JavaScript | Dynamic            | N/A       | No          | No (TS: yes)    | Duck typing        |
| TypeScript | Static, structural | Yes       | Yes         | Yes             | Structural         |
| Go         | Static, nominal    | Limited   | No (nil)    | Yes (1.18+)     | Nominal            |
| Rust       | Static, algebraic  | Yes       | Yes (Option)| Yes             | Nominal            |
| Java       | Static, nominal    | Limited   | No (null)   | Yes             | Nominal            |
| C#         | Static, nominal    | Yes       | Partial     | Yes             | Nominal            |
| Swift      | Static, nominal    | Yes       | Yes (Optional)| Yes           | Nominal            |
| Kotlin     | Static, nominal    | Yes       | Yes         | Yes             | Nominal            |
| Haskell    | Static, algebraic  | Yes       | Yes (Maybe) | Yes             | Nominal            |
| OCaml      | Static, algebraic  | Yes       | Yes (option)| Yes             | Nominal            |
| Elixir     | Dynamic            | N/A       | No (nil)    | N/A             | Duck typing        |

### Type System Patterns

**Rust (Algebraic Types):**
```rust
// Enum with data
enum Result<T, E> {
    Ok(T),
    Err(E),
}

// Option for nullable
enum Option<T> {
    Some(T),
    None,
}

// Pattern matching
match user {
    Some(u) => println!("User: {}", u.name),
    None => println!("No user"),
}

// Generics with traits
fn largest<T: PartialOrd>(list: &[T]) -> &T {
    // implementation
}
```

**TypeScript (Structural Types):**
```typescript
// Interface
interface User {
  name: string;
  age: number;
}

// Union types
type Result = Success | Error;

// Generics
function identity<T>(arg: T): T {
  return arg;
}

// Nullable types
let maybeString: string | null = null;

// Type guards
if (typeof value === "string") {
  console.log(value.toUpperCase());
}
```

**Haskell (Algebraic Types):**
```haskell
-- Data types
data Maybe a = Nothing | Just a

-- Type classes
class Eq a where
  (==) :: a -> a -> Bool

-- Polymorphic functions
id :: a -> a
id x = x

-- Higher-kinded types
class Functor f where
  fmap :: (a -> b) -> f a -> f b
```

**Go (Structural Interfaces):**
```go
// Interface (implicit implementation)
type Reader interface {
    Read(p []byte) (n int, err error)
}

// Generics (1.18+)
func Map[T, U any](s []T, f func(T) U) []U {
    result := make([]U, len(s))
    for i, v := range s {
        result[i] = f(v)
    }
    return result
}

// Type assertion
if str, ok := value.(string); ok {
    fmt.Println(str)
}
```

---

## Package/Dependency Management

| Language   | Tool               | Config File         | Lock File           | Monorepo Support | Versioning      |
|------------|--------------------|---------------------|---------------------|------------------|-----------------|
| Python     | pip/poetry         | requirements.txt    | poetry.lock         | Limited          | SemVer          |
| JavaScript | npm/yarn/pnpm      | package.json        | package-lock.json   | Excellent        | SemVer          |
| Go         | go mod             | go.mod              | go.sum              | Good             | SemVer          |
| Rust       | cargo              | Cargo.toml          | Cargo.lock          | Excellent        | SemVer          |
| Java       | maven/gradle       | pom.xml/build.gradle| maven.lock          | Good             | SemVer          |
| C#         | NuGet              | .csproj             | packages.lock.json  | Good             | SemVer          |
| Ruby       | bundler            | Gemfile             | Gemfile.lock        | Limited          | SemVer          |
| Elixir     | mix                | mix.exs             | mix.lock            | Good             | SemVer          |
| Swift      | SPM/CocoaPods      | Package.swift       | Package.resolved    | Good             | SemVer          |
| PHP        | composer           | composer.json       | composer.lock       | Limited          | SemVer          |

### Package Management Patterns

**Cargo (Rust):**
```toml
# Cargo.toml
[package]
name = "my-project"
version = "0.1.0"

[dependencies]
serde = "1.0"
tokio = { version = "1.0", features = ["full"] }

[dev-dependencies]
criterion = "0.5"
```

**Go Modules:**
```go
// go.mod
module github.com/user/project

go 1.21

require (
    github.com/gin-gonic/gin v1.9.1
    gorm.io/gorm v1.25.5
)

// Commands
go mod init
go mod tidy
go mod download
```

**npm (JavaScript):**
```json
{
  "name": "my-project",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.18.0"
  },
  "devDependencies": {
    "jest": "^29.0.0"
  }
}
```

**Poetry (Python):**
```toml
# pyproject.toml
[tool.poetry]
name = "my-project"
version = "0.1.0"

[tool.poetry.dependencies]
python = "^3.11"
requests = "^2.31.0"

[tool.poetry.dev-dependencies]
pytest = "^7.4.0"
```

---

## Common Idioms by Language

### Rust Idioms

**Ownership Patterns:**
```rust
// Builder pattern
let server = Server::builder()
    .port(8080)
    .threads(4)
    .build()?;

// Iterator chains
let sum: i32 = vec![1, 2, 3, 4]
    .iter()
    .filter(|&x| x % 2 == 0)
    .map(|&x| x * 2)
    .sum();

// Error propagation
fn read_config() -> Result<Config, Error> {
    let file = File::open("config.toml")?;
    let config = parse(file)?;
    Ok(config)
}
```

**Anti-Patterns:**
- Using `.unwrap()` in production (can panic)
- Unnecessary `.clone()` (performance cost)
- Fighting the borrow checker instead of understanding it
- Using `Arc<Mutex<T>>` everywhere (usually overkill)

### Go Idioms

**Concurrency Patterns:**
```go
// Worker pool
func worker(id int, jobs <-chan Job, results chan<- Result) {
    for job := range jobs {
        results <- process(job)
    }
}

// Context for cancellation
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()

// Goroutine coordination
var wg sync.WaitGroup
wg.Add(2)
go func() { defer wg.Done(); task1() }()
go func() { defer wg.Done(); task2() }()
wg.Wait()
```

**Anti-Patterns:**
- Ignoring errors (`err` never checked)
- Using `panic()` for normal errors
- Creating goroutines without knowing when they end
- Not using `defer` for cleanup

### Python Idioms

**Pythonic Code:**
```python
# List comprehensions
squares = [x**2 for x in range(10) if x % 2 == 0]

# Context managers
with open('file.txt') as f:
    content = f.read()

# Decorators
@lru_cache(maxsize=128)
def expensive_function(n):
    return compute(n)

# Duck typing
def process(file_like):
    # Works with any object that has read()
    return file_like.read()
```

**Anti-Patterns:**
- Mutable default arguments (`def func(data=[]):`)
- Catching `Exception` broadly without reraising
- Using `exec()` or `eval()` with user input
- Not using virtual environments

### JavaScript/TypeScript Idioms

**Modern JavaScript:**
```javascript
// Destructuring
const { name, age } = user;

// Spread operator
const merged = { ...obj1, ...obj2 };

// Optional chaining
const name = user?.profile?.name;

// Promise chains
fetch(url)
  .then(r => r.json())
  .then(data => process(data))
  .catch(handleError);
```

**Anti-Patterns:**
- Not handling Promise rejections
- Mutating state directly (in React)
- Using `var` instead of `let`/`const`
- Callback hell (use async/await)

### Elixir Idioms

**Functional Patterns:**
```elixir
# Pipeline operator
"hello"
|> String.upcase()
|> String.split("")
|> Enum.reverse()

# Pattern matching
def process({:ok, data}), do: handle_success(data)
def process({:error, reason}), do: handle_error(reason)

# With for nested operations
with {:ok, user} <- fetch_user(id),
     {:ok, posts} <- fetch_posts(user),
     {:ok, comments} <- fetch_comments(posts) do
  {:ok, {user, posts, comments}}
end
```

**Anti-Patterns:**
- Not handling all pattern match cases
- Using processes where simple functions suffice
- Not using OTP behaviors (GenServer, Supervisor)
- Ignoring errors in pipelines

---

## Testing Patterns

| Language   | Framework          | Assertion Style     | Mocking            | Coverage Tool      |
|------------|--------------------|---------------------|--------------------|--------------------|
| Python     | pytest             | `assert x == y`     | unittest.mock      | coverage.py        |
| JavaScript | jest/mocha         | `expect(x).toBe(y)` | jest.fn()          | istanbul/nyc       |
| Go         | testing (built-in) | `if got != want`    | interfaces         | go test -cover     |
| Rust       | cargo test         | `assert_eq!(x, y)`  | mockall            | tarpaulin          |
| Java       | JUnit              | `assertEquals(x,y)` | Mockito            | JaCoCo             |
| C#         | xUnit/NUnit        | `Assert.Equal(x,y)` | Moq                | coverlet           |
| Elixir     | ExUnit             | `assert x == y`     | Mox                | mix test --cover   |
| Swift      | XCTest             | `XCTAssertEqual`    | protocols          | Xcode coverage     |

---

## Build Systems and Tooling

| Language   | Build Tool         | Task Runner        | Bundle/Compile     | Hot Reload         |
|------------|--------------------|--------------------|--------------------|-------------------|
| Python     | setuptools         | make, invoke       | N/A                | watchdog          |
| JavaScript | webpack/vite       | npm scripts        | webpack, rollup    | HMR (built-in)    |
| Go         | go build           | make, mage         | go build           | air, realize      |
| Rust       | cargo              | cargo make         | cargo build        | cargo watch       |
| Java       | maven/gradle       | gradle tasks       | javac, jar         | JRebel            |
| C#         | MSBuild            | dotnet CLI         | dotnet build       | dotnet watch      |
| Elixir     | mix                | mix tasks          | mix compile        | Phoenix LiveReload|

---

## When to Choose Each Language

### Performance-Critical
**Choose**: Rust, C, C++, Zig
- Rust: Memory safety + performance
- C/C++: Maximum control, mature ecosystem
- Zig: Modern alternative to C

### Web Services/APIs
**Choose**: Go, JavaScript/TypeScript, Python, Rust
- Go: Simple, fast, excellent concurrency
- JavaScript/Node: Huge ecosystem, full-stack JS
- Python: Rapid development, ML/data integration
- Rust: High performance, safety

### Systems Programming
**Choose**: Rust, C, C++, Zig
- Rust: Modern, safe systems programming
- C: OS, embedded, maximum portability
- C++: Complex systems, game engines

### Data Science/ML
**Choose**: Python, R, Julia
- Python: Dominant ecosystem (pandas, scikit-learn, PyTorch)
- R: Statistical analysis
- Julia: High-performance scientific computing

### Mobile Apps
**Choose**: Swift, Kotlin, Dart
- Swift: iOS native
- Kotlin: Android native
- Dart/Flutter: Cross-platform

### Distributed Systems
**Choose**: Elixir, Go, Java, Rust
- Elixir: Fault tolerance, OTP
- Go: Simple concurrency
- Java: Battle-tested enterprise
- Rust: Performance + safety
