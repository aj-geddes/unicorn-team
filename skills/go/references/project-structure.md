# Go Project Structure

Go projects use conventions rather than configuration. The toolchain
understands these layouts and rewards following them.

## Standard Layout

### Single Binary

```
myproject/
├── main.go                   # entry point (package main)
├── config.go                 # configuration
├── server.go                 # HTTP server
├── handlers.go               # request handlers
├── models.go                 # domain types
├── store.go                  # data access
├── go.mod
├── go.sum
├── Makefile
├── .golangci.yml
└── README.md
```

Best for: small services, tools, CLI apps.

### Multi-Package (Standard)

```
myproject/
├── cmd/
│   ├── api/
│   │   └── main.go           # API server entry point
│   ├── worker/
│   │   └── main.go           # background worker entry point
│   └── migrate/
│       └── main.go           # DB migration tool entry point
├── internal/
│   ├── server/
│   │   ├── server.go         # HTTP server setup, routing
│   │   ├── middleware.go      # HTTP middleware
│   │   └── server_test.go
│   ├── handler/
│   │   ├── user.go           # user endpoint handlers
│   │   ├── order.go          # order endpoint handlers
│   │   └── handler_test.go
│   ├── service/
│   │   ├── user.go           # user business logic
│   │   ├── order.go          # order business logic
│   │   └── service_test.go
│   ├── store/
│   │   ├── postgres/
│   │   │   ├── user.go       # user SQL queries
│   │   │   └── user_test.go
│   │   └── store.go          # store interfaces
│   ├── model/
│   │   └── model.go          # domain types
│   └── config/
│       └── config.go         # configuration loading
├── pkg/                       # importable by external projects (use sparingly)
│   └── httputil/
│       └── response.go
├── migrations/
│   ├── 001_create_users.up.sql
│   └── 001_create_users.down.sql
├── testdata/                  # test fixtures (ignored by go build)
├── go.mod
├── go.sum
├── Makefile
├── Dockerfile
└── .golangci.yml
```

## Key Directories

### cmd/

Each subdirectory is a separate `main` package producing one binary.
Keep `main.go` minimal -- wire dependencies and start the app.

```go
// cmd/api/main.go
package main

import (
    "log"
    "os"

    "myproject/internal/config"
    "myproject/internal/server"
    "myproject/internal/service"
    "myproject/internal/store/postgres"
)

func main() {
    cfg, err := config.Load()
    if err != nil {
        log.Fatalf("loading config: %v", err)
    }

    db, err := postgres.Connect(cfg.DatabaseURL)
    if err != nil {
        log.Fatalf("connecting to database: %v", err)
    }
    defer db.Close()

    userStore := postgres.NewUserStore(db)
    userService := service.NewUserService(userStore)

    srv := server.New(cfg, userService)

    log.Printf("starting server on %s", cfg.ListenAddr)
    if err := srv.ListenAndServe(); err != nil {
        log.Fatalf("server error: %v", err)
        os.Exit(1)
    }
}
```

### internal/

Compiler-enforced privacy. Code in `internal/` cannot be imported by other
modules. Use this for everything that isn't your public API.

```
internal/
├── service/     # business logic (depends on store interfaces)
├── store/       # data access (implements store interfaces)
├── handler/     # HTTP handlers (depends on services)
├── server/      # server setup, routing, middleware
├── model/       # domain types shared across packages
└── config/      # configuration loading
```

### pkg/

Code importable by other projects. Use sparingly -- most code belongs in
`internal/`. Only put code here if you explicitly want others to depend on it.

```go
// pkg/httputil/response.go -- reusable HTTP helpers
package httputil

func WriteJSON(w http.ResponseWriter, status int, v any) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    json.NewEncoder(w).Encode(v)
}
```

### testdata/

Test fixtures and golden files. Ignored by `go build` but accessible in tests
via relative paths.

```
testdata/
├── fixtures/
│   ├── valid_config.json
│   └── invalid_config.json
└── golden/
    ├── TestRender_basic.golden
    └── TestRender_empty.golden
```

## Dependency Injection

Go uses constructor injection. No frameworks needed -- just pass dependencies
as function/struct parameters.

```go
// Define interfaces where consumed (not where implemented)
// internal/service/user.go
package service

type UserStore interface {
    Get(ctx context.Context, id string) (*model.User, error)
    Create(ctx context.Context, user *model.User) error
    List(ctx context.Context, opts ListOptions) ([]*model.User, error)
}

type UserService struct {
    store  UserStore
    cache  Cache
    logger *slog.Logger
}

func NewUserService(store UserStore, cache Cache, logger *slog.Logger) *UserService {
    return &UserService{
        store:  store,
        cache:  cache,
        logger: logger,
    }
}

// Concrete implementation in another package
// internal/store/postgres/user.go
package postgres

type UserStore struct {
    db *sql.DB
}

func NewUserStore(db *sql.DB) *UserStore {
    return &UserStore{db: db}
}

func (s *UserStore) Get(ctx context.Context, id string) (*model.User, error) {
    // SQL query...
}

// Test with mock
// internal/service/user_test.go
type mockStore struct {
    users map[string]*model.User
}

func (m *mockStore) Get(ctx context.Context, id string) (*model.User, error) {
    user, ok := m.users[id]
    if !ok {
        return nil, ErrNotFound
    }
    return user, nil
}

func TestUserService_Get(t *testing.T) {
    store := &mockStore{users: map[string]*model.User{
        "1": {ID: "1", Name: "Alice"},
    }}
    svc := NewUserService(store, noopCache{}, slog.Default())

    user, err := svc.Get(context.Background(), "1")
    // ...
}
```

## Configuration

```go
// internal/config/config.go
package config

import (
    "fmt"
    "os"
    "strconv"
    "time"
)

type Config struct {
    ListenAddr    string
    DatabaseURL   string
    RedisURL      string
    ReadTimeout   time.Duration
    WriteTimeout  time.Duration
    MaxConns      int
    Debug         bool
}

func Load() (*Config, error) {
    cfg := &Config{
        ListenAddr:   envOrDefault("LISTEN_ADDR", ":8080"),
        DatabaseURL:  os.Getenv("DATABASE_URL"),
        RedisURL:     envOrDefault("REDIS_URL", "localhost:6379"),
        ReadTimeout:  envDurationOrDefault("READ_TIMEOUT", 10*time.Second),
        WriteTimeout: envDurationOrDefault("WRITE_TIMEOUT", 30*time.Second),
        MaxConns:     envIntOrDefault("MAX_CONNS", 25),
        Debug:        os.Getenv("DEBUG") == "true",
    }

    if cfg.DatabaseURL == "" {
        return nil, fmt.Errorf("DATABASE_URL is required")
    }

    return cfg, nil
}

func envOrDefault(key, fallback string) string {
    if v := os.Getenv(key); v != "" {
        return v
    }
    return fallback
}

func envIntOrDefault(key string, fallback int) int {
    if v := os.Getenv(key); v != "" {
        if i, err := strconv.Atoi(v); err == nil {
            return i
        }
    }
    return fallback
}

func envDurationOrDefault(key string, fallback time.Duration) time.Duration {
    if v := os.Getenv(key); v != "" {
        if d, err := time.ParseDuration(v); err == nil {
            return d
        }
    }
    return fallback
}
```

## Build Tags

```go
//go:build integration

package store_test

// Only included when: go test -tags=integration ./...
func TestPostgresIntegration(t *testing.T) {
    // ...
}
```

```go
//go:build !production

package debug

// Included in dev/test builds, excluded from production
func DebugHandler(w http.ResponseWriter, r *http.Request) {
    // dump internal state
}
```

## Makefile

```makefile
.PHONY: build test lint run clean

# Build all binaries
build:
	go build -o bin/ ./cmd/...

# Run tests with race detector and coverage
test:
	go test -race -cover -coverprofile=coverage.out ./...

# Run integration tests
test-integration:
	go test -race -tags=integration ./...

# Run linter
lint:
	golangci-lint run ./...

# Run the API server
run:
	go run ./cmd/api

# Format code
fmt:
	gofumpt -w .

# Tidy dependencies
tidy:
	go mod tidy

# Generate code (mocks, etc.)
generate:
	go generate ./...

# Full CI check
ci: lint test
	@echo "All checks passed"

# Clean build artifacts
clean:
	rm -rf bin/ coverage.out
```

## Package Design Guidelines

| Guideline | Why |
|-----------|-----|
| Name by what it provides, not what it contains | `user` not `models`, `store` not `dal` |
| No `util`, `common`, `misc` packages | Sign of wrong abstraction boundary |
| Avoid circular imports | Go won't compile them; redesign the boundary |
| One package = one responsibility | Package is the unit of encapsulation |
| Accept interfaces, return structs | Keeps packages loosely coupled |
| Keep `main` thin | Only wiring; logic goes in `internal/` |
| Use `internal/` by default | Expose to `pkg/` only when intentional |

## Multi-Module Repos

For large projects with independent release cycles:

```
monorepo/
├── go.work              # Go workspace (Go 1.18+)
├── services/
│   ├── api/
│   │   ├── go.mod       # module: github.com/org/monorepo/services/api
│   │   └── main.go
│   └── worker/
│       ├── go.mod       # module: github.com/org/monorepo/services/worker
│       └── main.go
└── libs/
    └── shared/
        ├── go.mod       # module: github.com/org/monorepo/libs/shared
        └── types.go
```

```
// go.work
go 1.22

use (
    ./services/api
    ./services/worker
    ./libs/shared
)
```
