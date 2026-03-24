---
name: go
description: >-
  Guides Go development with idiomatic patterns, tooling, and project structure.
  ALWAYS trigger on "go project", "go module", "go mod", "goroutine", "channel",
  "go test", "go build", "golangci-lint", "go interface", "go error handling",
  "go concurrency", "go struct", "go anti-pattern", "go best practices",
  "go tooling", "go lint". Use when setting up Go projects, writing idiomatic Go,
  choosing concurrency patterns, or configuring tooling. Different from testing
  skill which covers general test strategy; this covers Go-specific testing
  patterns and tooling configs.
---
<!-- Last reviewed: 2026-03 -->

# Go Domain Skill

## Error Handling

Go uses explicit error returns, not exceptions. Every error is a value you handle at the call site.

```go
// Return errors, don't panic
func ParseConfig(path string) (*Config, error) {
    data, err := os.ReadFile(path)
    if err != nil {
        return nil, fmt.Errorf("reading config %s: %w", path, err)
    }

    var cfg Config
    if err := json.Unmarshal(data, &cfg); err != nil {
        return nil, fmt.Errorf("parsing config: %w", err)
    }
    return &cfg, nil
}

// Sentinel errors for callers to check
var (
    ErrNotFound   = errors.New("not found")
    ErrForbidden  = errors.New("forbidden")
)

// Custom error types for rich context
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation: %s: %s", e.Field, e.Message)
}

// Callers use errors.Is / errors.As
if errors.Is(err, ErrNotFound) { /* handle */ }

var ve *ValidationError
if errors.As(err, &ve) { /* access ve.Field */ }
```

**See references/error-handling.md for** wrapping strategies, panic/recover, error handling in goroutines, domain error design.

## Interfaces

Go interfaces are satisfied implicitly -- no `implements` keyword. Define them where they're consumed, not where they're implemented.

```go
// Small interfaces at the consumer site
type UserStore interface {
    GetUser(ctx context.Context, id string) (*User, error)
}

// Accept interfaces, return structs
func NewUserService(store UserStore) *UserService {
    return &UserService{store: store}
}

// Common stdlib interfaces to know
// io.Reader, io.Writer      -- streaming data
// fmt.Stringer               -- string representation
// sort.Interface             -- custom sorting
// encoding.BinaryMarshaler  -- serialization
// context.Context            -- cancellation and deadlines
// http.Handler               -- HTTP request handling
```

| Guideline | Why |
|-----------|-----|
| 1-3 method interfaces | Easier to implement, compose, mock |
| Define at consumer | Decouples packages, avoids import cycles |
| Accept interface, return struct | Callers get flexibility, producers stay concrete |
| Embed for composition | `io.ReadWriter` = `io.Reader` + `io.Writer` |

## Concurrency

```go
// Goroutines + channels for concurrent work
func FetchAll(ctx context.Context, urls []string) ([]Result, error) {
    g, ctx := errgroup.WithContext(ctx)
    results := make([]Result, len(urls))

    for i, url := range urls {
        g.Go(func() error {
            res, err := fetch(ctx, url)
            if err != nil {
                return err
            }
            results[i] = res  // safe: each goroutine owns its index
            return nil
        })
    }

    if err := g.Wait(); err != nil {
        return nil, err
    }
    return results, nil
}

// Context for cancellation and timeouts
ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
defer cancel()

// Select for multiplexing channels
select {
case msg := <-msgCh:
    handle(msg)
case <-ctx.Done():
    return ctx.Err()
}
```

**See references/concurrency-patterns.md for** worker pools, fan-out/fan-in, pipelines, sync primitives, context propagation.

## Testing

```go
// Table-driven tests -- the Go standard
func TestParseSize(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        want    int64
        wantErr bool
    }{
        {name: "bytes", input: "100B", want: 100},
        {name: "kilobytes", input: "2KB", want: 2048},
        {name: "empty", input: "", wantErr: true},
        {name: "invalid", input: "abc", wantErr: true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := ParseSize(tt.input)
            if tt.wantErr {
                if err == nil {
                    t.Fatal("expected error, got nil")
                }
                return
            }
            if err != nil {
                t.Fatalf("unexpected error: %v", err)
            }
            if got != tt.want {
                t.Errorf("ParseSize(%q) = %d, want %d", tt.input, got, tt.want)
            }
        })
    }
}

// HTTP handler testing
func TestHealthHandler(t *testing.T) {
    req := httptest.NewRequest(http.MethodGet, "/health", nil)
    w := httptest.NewRecorder()

    HealthHandler(w, req)

    if w.Code != http.StatusOK {
        t.Errorf("status = %d, want %d", w.Code, http.StatusOK)
    }
}
```

**Coverage target: 80%+**

```bash
go test -cover -coverprofile=coverage.out ./...
go tool cover -func=coverage.out       # summary
go tool cover -html=coverage.out       # visual report
```

**See references/testing-go.md for** subtests, benchmarks, fuzz testing, testify, httptest patterns, test helpers.

## Tooling

### Go Modules

```bash
go mod init github.com/org/project   # initialize
go mod tidy                          # sync deps
go mod vendor                        # vendored deps (optional)
go get github.com/pkg/errors@v0.9.1  # add/update dep
```

### golangci-lint (Linting)

Runs 50+ linters in parallel. Single tool replaces go vet, staticcheck, errcheck, gosec, and more.

```yaml
# .golangci.yml
linters:
  enable:
    - errcheck       # unchecked errors
    - govet          # suspicious constructs
    - staticcheck    # advanced analysis
    - unused         # unused code
    - gosimple       # simplifications
    - ineffassign    # ineffective assignments
    - gocritic       # opinionated checks
    - gosec          # security issues
    - errname        # error naming conventions
    - exhaustive     # enum exhaustiveness

linters-settings:
  govet:
    enable-all: true
  gocritic:
    enabled-tags: [diagnostic, style, performance]

issues:
  exclude-use-default: false
  max-issues-per-linter: 0
  max-same-issues: 0
```

```bash
golangci-lint run ./...
```

**See references/tooling-config.md for** complete linter configs, Makefile patterns, CI setup, build tags.

## Structs and Methods

```go
// Struct with tags for serialization
type User struct {
    ID        string    `json:"id" db:"id"`
    Name      string    `json:"name" db:"name"`
    Email     string    `json:"email" db:"email"`
    CreatedAt time.Time `json:"created_at" db:"created_at"`
}

// Constructor function (not a Go "constructor" -- just convention)
func NewUser(name, email string) *User {
    return &User{
        ID:        uuid.NewString(),
        Name:      name,
        Email:     email,
        CreatedAt: time.Now(),
    }
}

// Value receiver: doesn't modify receiver, safe on copies
func (u User) DisplayName() string {
    return fmt.Sprintf("%s <%s>", u.Name, u.Email)
}

// Pointer receiver: modifies receiver or is large
func (u *User) SetEmail(email string) error {
    if !strings.Contains(email, "@") {
        return &ValidationError{Field: "email", Message: "invalid format"}
    }
    u.Email = email
    return nil
}
```

| Use | Receiver | Why |
|-----|----------|-----|
| Read-only, small struct | Value `(u User)` | No mutation, safe copy |
| Mutates state | Pointer `(u *User)` | Changes visible to caller |
| Large struct (>3 fields) | Pointer `(u *User)` | Avoid copy overhead |
| Implements interface with pointer methods | Pointer `(u *User)` | Consistency required |

## Project Structure

```
myproject/
├── cmd/
│   └── myapp/
│       └── main.go          # entry point, wiring only
├── internal/                 # private to this module
│   ├── server/               # HTTP server setup
│   ├── user/                 # user domain logic
│   └── storage/              # database layer
├── pkg/                      # importable by other projects (use sparingly)
├── go.mod
├── go.sum
├── Makefile
└── .golangci.yml
```

**See references/project-structure.md for** multi-binary repos, dependency injection, config patterns, build tags.

## Anti-patterns Quick Reference

| Anti-pattern | Fix |
|-------------|-----|
| `panic()` for expected errors | Return `error` |
| Ignoring errors `_ = f()` | Handle or explicitly document why safe |
| `interface{}` / `any` everywhere | Use generics (1.18+) or specific types |
| Goroutine leak (no exit path) | Use `context.Context` + `select` |
| Shared state without sync | `sync.Mutex`, channels, or `atomic` |
| `init()` with side effects | Explicit initialization in `main()` |
| Giant interfaces (>5 methods) | Split into focused 1-3 method interfaces |
| Package-level mutable state | Dependency injection |
| Premature channel/goroutine use | Start sequential, add concurrency when needed |
| `log.Fatal` in library code | Return errors, let caller decide |
| Naked returns in long functions | Named returns only for short functions or godoc |
| Missing `defer` for cleanup | `defer f.Close()` immediately after open |

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Package | short, lowercase, singular | `user`, `http`, `json` |
| Exported function | PascalCase, verb-noun | `ParseConfig`, `NewServer` |
| Unexported function | camelCase | `validateInput`, `buildQuery` |
| Interface (1 method) | Method + "er" | `Reader`, `Stringer`, `Handler` |
| Interface (multi) | Descriptive noun | `UserStore`, `EventBus` |
| Error variable | `Err` + description | `ErrNotFound`, `ErrTimeout` |
| Error type | Description + `Error` | `ValidationError`, `TimeoutError` |
| Constants | PascalCase (exported) or camelCase | `MaxRetries`, `defaultTimeout` |
| Acronyms | All caps | `HTTPServer`, `userID`, `xmlParser` |

## Project Setup Checklist

```bash
# 1. Initialize module
go mod init github.com/org/project

# 2. Create directory structure
mkdir -p cmd/myapp internal/{server,storage}

# 3. Install tooling
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# 4. Create .golangci.yml (see Tooling section)

# 5. Create Makefile
# make build, make test, make lint, make run

# 6. Full quality check
go vet ./... && golangci-lint run ./... && go test -race -cover ./...
```

## Commands

```bash
go build ./...                                      # Build all packages
go test -v -race -cover ./...                       # Test with race detector + coverage
go test -run TestSpecific ./internal/user/           # Run specific test
go vet ./...                                        # Static analysis
golangci-lint run ./...                             # Lint (50+ linters)
go mod tidy                                         # Sync dependencies
```

## Reference Files

- **references/concurrency-patterns.md** - Goroutines, channels, select, errgroup, worker pools, pipelines
- **references/error-handling.md** - Wrapping, sentinel errors, custom types, panic/recover, strategies
- **references/testing-go.md** - Table-driven tests, subtests, benchmarks, fuzz, testify, httptest
- **references/project-structure.md** - Module layout, cmd/internal/pkg, DI, config, build tags
- **references/tooling-config.md** - golangci-lint, go vet, gofumpt, Makefile, CI/CD configs
