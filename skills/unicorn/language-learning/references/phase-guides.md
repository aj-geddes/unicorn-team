# Detailed Phase Guides

In-depth walkthroughs for each phase of the language learning protocol.

---

## Phase 1: Exploration (30 minutes) - Deep Dive

### The First 5 Minutes

**Goal**: Get something running immediately.

```bash
# 1. Install (use version manager if available)
# Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Go
brew install go  # or download from golang.org

# Node.js
nvm install node  # or download from nodejs.org

# Python
pyenv install 3.11  # or download from python.org

# 2. Verify installation
rustc --version
go version
node --version
python --version

# 3. Create project
cargo new hello-world
# or
mkdir hello-world && cd hello-world && go mod init hello
# or
mkdir hello-world && cd hello-world && npm init -y
# or
mkdir hello-world && cd hello-world && python -m venv venv
```

### Minutes 5-15: Hello World

Don't just copy-paste. Type it out and change things.

**Experiment with:**
1. Change the message
2. Print multiple lines
3. Use a variable for the message
4. Call a function that prints

**Example exploration session (Rust):**

```rust
// Try 1: Basic
fn main() {
    println!("Hello, world!");
}

// Try 2: With variable
fn main() {
    let message = "Hello, Rust!";
    println!("{}", message);
}

// Try 3: With function
fn main() {
    greet("World");
}

fn greet(name: &str) {
    println!("Hello, {}!", name);
}

// Try 4: Break it (learn from errors)
fn main() {
    let message = "Hello";
    message = "Goodbye";  // Error! Learn about mutability
    println!("{}", message);
}
```

**Capture observations:**
- Compiler messages (helpful or cryptic?)
- Error messages (what do they tell you?)
- Build time (fast or slow?)
- Binary size (if compiled)

### Minutes 15-25: Variables and Types

**Systematic exploration:**

```rust
// Rust example - adapt pattern to any language
fn main() {
    // Immutable (default)
    let x = 5;
    // x = 6;  // Try this - what happens?

    // Mutable
    let mut y = 5;
    y = 6;  // This works

    // Type inference
    let inferred = "hello";

    // Explicit types
    let explicit: i32 = 42;

    // Different types
    let integer: i32 = 42;
    let float: f64 = 3.14;
    let boolean: bool = true;
    let character: char = 'x';
    let string: String = String::from("hello");

    // Collections
    let array = [1, 2, 3, 4, 5];
    let vector = vec![1, 2, 3];

    println!("x: {}, y: {}", x, y);
    println!("Types: {} {} {} {} {}", integer, float, boolean, character, string);
}
```

**Try breaking things:**
- Mix types in operations (int + float)
- Reassign immutable variables
- Access out-of-bounds array elements
- Use variables before initialization

**Document:**
- Default mutability (mutable or immutable?)
- Type inference (strong or weak?)
- Type conversion (explicit or implicit?)
- Surprising behaviors

### Minutes 25-30: Functions and Control Flow

**Quick function exploration:**

```rust
// Different function signatures
fn no_params() {
    println!("No params");
}

fn with_params(x: i32, y: i32) {
    println!("Params: {} {}", x, y);
}

fn with_return(x: i32) -> i32 {
    x * 2  // Note: no semicolon = return value
}

fn multiple_return() -> (i32, i32) {
    (1, 2)
}

// Control flow
fn control_flow_demo(n: i32) {
    // If/else
    if n > 0 {
        println!("Positive");
    } else if n < 0 {
        println!("Negative");
    } else {
        println!("Zero");
    }

    // Match (if language supports)
    match n {
        0 => println!("Zero"),
        1..=10 => println!("Small"),
        _ => println!("Large"),
    }

    // For loop
    for i in 0..5 {
        println!("Loop: {}", i);
    }

    // While loop
    let mut counter = 0;
    while counter < 3 {
        println!("While: {}", counter);
        counter += 1;
    }
}
```

**Phase 1 Output:**
By minute 30, you should have:
- Working development environment
- Hello World that you've modified multiple times
- Understanding of basic syntax
- List of questions about things you don't understand yet

---

## Phase 2: Patterns (1-2 hours) - Deep Dive

### Hour 1: Core Patterns

**Pattern Discovery Workflow:**

1. **Pick a pattern from known language**
2. **Search documentation for equivalent**
3. **Implement it**
4. **Compare syntax and semantics**
5. **Note differences**

**Example: Iteration Pattern**

```python
# Python (known)
numbers = [1, 2, 3, 4, 5]
doubled = [x * 2 for x in numbers if x % 2 == 0]
```

```javascript
// JavaScript (learning)
const numbers = [1, 2, 3, 4, 5];
const doubled = numbers
  .filter(x => x % 2 === 0)
  .map(x => x * 2);
```

```go
// Go (learning)
numbers := []int{1, 2, 3, 4, 5}
var doubled []int
for _, x := range numbers {
    if x%2 == 0 {
        doubled = append(doubled, x*2)
    }
}
```

```rust
// Rust (learning)
let numbers = vec![1, 2, 3, 4, 5];
let doubled: Vec<i32> = numbers
    .iter()
    .filter(|&x| x % 2 == 0)
    .map(|&x| x * 2)
    .collect();
```

**Observations:**
- Python: List comprehension, concise
- JavaScript: Method chaining, functional style
- Go: Explicit loops, imperative
- Rust: Iterator chains, ownership-aware

### Pattern Categories to Explore

**1. Collection Operations**
- Creating collections
- Adding/removing elements
- Accessing elements
- Iterating
- Transforming (map)
- Filtering
- Reducing/folding
- Sorting
- Finding elements

**2. Error Handling**
- Basic try/catch or equivalent
- Multiple error types
- Error propagation
- Custom errors
- Recovery strategies
- Resource cleanup (defer, finally, RAII)

**3. Null/Optional Handling**
- Representing absence
- Checking for null
- Default values
- Safe navigation
- Unwrapping safely

**4. Async Operations**
- Basic async function
- Awaiting results
- Error handling in async
- Parallel execution
- Timeouts and cancellation

**5. String Operations**
- Concatenation
- Interpolation
- Splitting/joining
- Searching/replacing
- Formatting

**6. File I/O**
- Reading entire file
- Reading line by line
- Writing file
- Checking existence
- Directory operations

**7. Data Serialization**
- JSON parsing
- JSON generation
- Other formats (YAML, TOML, XML)

**8. HTTP Operations**
- GET requests
- POST requests
- Headers and authentication
- Error handling
- Response parsing

### Hour 2: Advanced Patterns

**Concurrency Patterns:**

Compare how languages handle:
- Creating lightweight tasks (threads, goroutines, async tasks)
- Communication between tasks (channels, queues, shared memory)
- Synchronization (locks, semaphores, atomic operations)
- Cancellation and timeouts

**Type System Patterns:**

- Generic functions/types
- Trait/interface implementation
- Type inference limits
- Type conversions
- Algebraic data types (if applicable)

**Memory Patterns:**

- Allocation (stack vs heap)
- Copying vs moving
- Reference vs value semantics
- Lifetime management
- Resource cleanup

**Phase 2 Output:**
By end of phase 2, you should have:
- Comparison table filled in
- 20+ patterns mapped to known languages
- Code examples for each pattern
- Understanding of what's similar vs different

---

## Phase 3: Ecosystem (1 hour) - Deep Dive

### Package Manager Deep Dive (20 min)

**Experiment with:**

```bash
# 1. Search for packages
cargo search serde
go get github.com/gin-gonic/gin
npm search express
pip search requests

# 2. Add dependency
cargo add serde
# or edit Cargo.toml manually
go get -u github.com/gin-gonic/gin
npm install express
pip install requests

# 3. List dependencies
cargo tree
go list -m all
npm list
pip list

# 4. Update dependencies
cargo update
go get -u ./...
npm update
pip install --upgrade requests

# 5. Remove dependency
cargo remove serde
go mod tidy  # removes unused
npm uninstall express
pip uninstall requests

# 6. Lock file
# Observe Cargo.lock, go.sum, package-lock.json, poetry.lock
# Understand when it changes
```

**Understand:**
- Where packages come from (registry URL)
- How versioning works (SemVer usually)
- How to specify version constraints
- What the lock file does
- When to commit lock file

### Testing Framework Deep Dive (20 min)

**Create comprehensive test:**

```rust
// Rust example
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_basic() {
        assert_eq!(2 + 2, 4);
    }

    #[test]
    fn test_string() {
        let result = format_greeting("World");
        assert_eq!(result, "Hello, World!");
    }

    #[test]
    #[should_panic]
    fn test_panic() {
        divide(10, 0);
    }

    #[test]
    fn test_result() -> Result<(), String> {
        let result = parse_int("42")?;
        assert_eq!(result, 42);
        Ok(())
    }
}
```

**Learn:**
- How to write tests (function attributes, naming)
- How to run tests (`cargo test`, `go test`, `npm test`)
- How to run specific tests
- How to see output from passing tests
- How to measure coverage
- How to setup/teardown
- How to mock/stub dependencies

### Tooling Setup (20 min)

**Linter:**

```bash
# Install
rustup component add clippy
go install golang.org/x/lint/golint@latest
npm install -g eslint
pip install ruff

# Run
cargo clippy
golint ./...
eslint .
ruff check .

# Configure
# Create .clippy.toml, .golangci.yml, .eslintrc, ruff.toml
# Understand warning levels
# Learn common warnings
```

**Formatter:**

```bash
# Install
rustup component add rustfmt
# gofmt is built-in
npm install -g prettier
pip install black

# Run
cargo fmt
gofmt -w .
prettier --write .
black .

# Configure
# Create rustfmt.toml, .prettierrc, pyproject.toml
# Understand auto-format on save
```

**IDE Integration:**

```bash
# Install language server
# Rust: rust-analyzer (usually auto-installed)
# Go: gopls (usually auto-installed)
# JavaScript: typescript-language-server
# Python: pyright or pylance

# Configure VS Code
# Install extension
# Verify autocomplete works
# Verify go-to-definition works
# Verify hover documentation works
# Verify inline errors show
```

**Phase 3 Output:**
By end of phase 3, you should have:
- Package manager fluency
- Testing framework working
- Linter catching issues
- Formatter auto-formatting
- IDE fully integrated
- First "real" project with tests passing

---

## Phase 4: Idioms (2-3 hours) - Deep Dive

### Reading Official Style Guide (30-45 min)

**Key style guides:**
- Python: PEP 8 (https://peps.python.org/pep-0008/)
- Go: Effective Go (https://go.dev/doc/effective_go)
- Rust: Rust API Guidelines (https://rust-lang.github.io/api-guidelines/)
- JavaScript: Airbnb Style Guide (https://github.com/airbnb/javascript)

**What to capture:**
- Naming conventions (functions, variables, types, files)
- Code organization (file structure, module patterns)
- Error handling patterns
- Documentation patterns
- Testing patterns
- Common idioms recommended
- Explicit anti-patterns listed

### Studying Standard Library (45-60 min)

**Example: Rust std lib study**

```rust
// How does std::fs handle errors?
// Study this pattern
pub fn read_to_string<P: AsRef<Path>>(path: P) -> Result<String, Error>

// How does std::collections::HashMap work?
// Study the API design
let mut map = HashMap::new();
map.insert(key, value);
if let Some(value) = map.get(&key) {
    // ...
}

// How does std::iter work?
// Study the iterator trait
pub trait Iterator {
    type Item;
    fn next(&mut self) -> Option<Self::Item>;
}
```

**Questions to ask:**
- How are common operations named? (get vs fetch vs retrieve)
- How is mutability handled? (mut, mutable, etc.)
- How are errors returned? (Result, exceptions, error codes)
- What patterns appear repeatedly?
- How are resources managed? (RAII, defer, finally)

### Reviewing Popular Projects (45-60 min)

**Find top projects:**
```bash
# GitHub search
# "[language] stars:>10000"
# Look for well-maintained, idiomatic projects
```

**For each project:**
1. Read main entry point (main.rs, main.go, index.js)
2. Read 2-3 core modules
3. Read tests
4. Note patterns that appear repeatedly
5. Note project structure

**Capture:**
- How are modules organized?
- How are dependencies injected?
- How are errors handled at boundaries?
- How is configuration managed?
- How are tests structured?
- What libraries are commonly used?

### Anti-Pattern Recognition (30 min)

**Sources:**
- Linter warnings (what does clippy/golint/eslint catch?)
- Code review comments (search GitHub PRs)
- Blog posts about common mistakes
- "Common pitfalls" sections in docs

**Document:**
- The anti-pattern (code example)
- Why it's bad (performance, safety, readability)
- The correct pattern
- How to detect it (linter rule?)

**Phase 4 Output:**
By end of phase 4, you should have:
- Style guide internalized
- 5+ idioms documented with examples
- 5+ anti-patterns documented
- Understanding of "the X way" of doing things
- Code that looks like it was written by experienced developer

---

## Phase 5: Production (Ongoing) - Deep Dive

### Logging Setup (30 min)

**Structured logging example:**

```rust
// Rust with env_logger
use log::{info, warn, error};

fn main() {
    env_logger::init();

    info!("Starting application");
    warn!("Low disk space: {}%", disk_usage);
    error!("Failed to connect: {}", error);
}
```

```go
// Go with zap
logger, _ := zap.NewProduction()
defer logger.Sync()

logger.Info("Starting application")
logger.Warn("Low disk space", zap.Int("usage", diskUsage))
logger.Error("Failed to connect", zap.Error(err))
```

```python
# Python with structlog
import structlog

logger = structlog.get_logger()

logger.info("Starting application")
logger.warning("Low disk space", usage=disk_usage)
logger.error("Failed to connect", error=str(error))
```

**Configure:**
- Log levels (debug, info, warn, error)
- Output format (JSON for production)
- Output destination (stdout, file, both)
- Rotation (if logging to file)

### Error Handling Audit (30 min)

**Checklist:**
- [ ] All errors have context (what was being done when error occurred)
- [ ] No errors are silently ignored
- [ ] Errors are logged at appropriate level
- [ ] User-facing errors are friendly
- [ ] Internal errors include debug details
- [ ] Errors are wrapped with context (not just passed up)

**Example audit:**

```rust
// Bad
fn process_file(path: &str) -> Result<(), Error> {
    let content = fs::read_to_string(path)?;  // Lost context
    Ok(())
}

// Good
fn process_file(path: &str) -> Result<(), Error> {
    let content = fs::read_to_string(path)
        .map_err(|e| Error::FileRead {
            path: path.to_string(),
            source: e,
        })?;
    Ok(())
}
```

### Monitoring and Observability (45 min)

**Health check endpoint:**

```rust
// Actix-web example
#[get("/health")]
async fn health() -> impl Responder {
    // Check dependencies
    let db_ok = check_database().await;
    let cache_ok = check_cache().await;

    if db_ok && cache_ok {
        HttpResponse::Ok().json(json!({
            "status": "healthy",
            "database": "connected",
            "cache": "connected"
        }))
    } else {
        HttpResponse::ServiceUnavailable().json(json!({
            "status": "unhealthy",
            "database": if db_ok { "connected" } else { "disconnected" },
            "cache": if cache_ok { "connected" } else { "disconnected" }
        }))
    }
}
```

**Metrics:**
- Request count and latency
- Error rate
- Active connections
- Resource usage (memory, CPU)
- Business metrics

### Profiling and Optimization (60 min)

**Learn profiling tools:**

```bash
# Rust: flamegraph
cargo install flamegraph
cargo flamegraph

# Go: pprof
import _ "net/http/pprof"
go tool pprof http://localhost:6060/debug/pprof/profile

# Python: cProfile
python -m cProfile -o output.pstats script.py
python -m pstats output.pstats

# JavaScript: clinic.js
clinic doctor -- node server.js
```

**Optimization workflow:**
1. Measure first (profile, don't guess)
2. Identify hot paths (where is time spent?)
3. Optimize hot paths (focus on 80/20)
4. Benchmark (verify improvement)
5. Repeat

### Deployment (60 min)

**Understand deployment target:**

```bash
# Rust: static binary
cargo build --release
# Binary at target/release/myapp
# No runtime dependencies needed

# Go: static binary
go build -o myapp
# Single binary, no dependencies

# Python: containerized
# Dockerfile with dependencies
pip install -r requirements.txt

# JavaScript: containerized or platform
npm run build
# Deploy dist/ folder
```

**Create deployment checklist:**
- [ ] Build for production (optimizations enabled)
- [ ] Environment variables documented
- [ ] Secrets management configured
- [ ] Database migrations automated
- [ ] Health checks working
- [ ] Logging to centralized system
- [ ] Metrics exposed
- [ ] Graceful shutdown implemented
- [ ] Resource limits configured (memory, CPU)
- [ ] Rollback procedure documented

**Phase 5 Output:**
By end of phase 5, you should have:
- Production-ready application
- Comprehensive logging
- Monitoring and health checks
- Deployment pipeline
- Rollback procedure
- Performance profiled and optimized
- Confidence to deploy to production

---

## Continuous Learning

### After Phase 5

**Week 1-2:**
- Build small features daily
- Read code from popular projects
- Contribute to documentation
- Answer questions (Stack Overflow, Discord)

**Month 1:**
- Build medium-sized project
- Read language blog posts
- Follow language updates (RFCs, proposals)
- Join community discussions

**Month 3:**
- Contribute to open source
- Write about what you learned
- Mentor others learning the language
- Dive into advanced topics (unsafe, macros, reflection)

**Year 1:**
- Achieve proficiency
- Understand internals (compiler, runtime)
- Recognize when language is/isn't good fit
- Transfer knowledge to next language
