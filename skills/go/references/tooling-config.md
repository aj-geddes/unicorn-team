# Go Tooling Configuration

Complete guide to the Go toolchain and ecosystem tooling.

## Go Modules

```bash
# Initialize a new module
go mod init github.com/org/project

# Add dependencies (automatically on import, or explicitly)
go get github.com/go-chi/chi/v5@latest
go get github.com/jackc/pgx/v5@v5.5.0      # specific version
go get golang.org/x/sync                     # latest

# Update dependencies
go get -u ./...                  # all direct deps to latest minor/patch
go get -u=patch ./...            # patch updates only
go get github.com/pkg/foo@latest # single dependency

# Remove unused dependencies
go mod tidy

# Vendor dependencies (for reproducible builds)
go mod vendor

# Show dependency graph
go mod graph

# Show why a dependency is needed
go mod why github.com/some/dep

# Download all dependencies
go mod download
```

### go.mod

```
module github.com/org/project

go 1.22

require (
    github.com/go-chi/chi/v5 v5.0.12
    github.com/jackc/pgx/v5 v5.5.3
    golang.org/x/sync v0.6.0
)

require (
    // indirect dependencies (managed by go mod tidy)
    github.com/jackc/pgpassfile v1.0.0 // indirect
    github.com/jackc/pgservicefile v0.0.0-20231201171823-440d19dc326d // indirect
)
```

## golangci-lint

The standard meta-linter for Go. Runs 50+ linters in parallel.

### Installation

```bash
# Recommended: binary install
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Or via package manager
brew install golangci-lint        # macOS
snap install golangci-lint        # Linux
```

### Full Configuration

```yaml
# .golangci.yml
run:
  timeout: 5m
  tests: true
  modules-download-mode: readonly

output:
  formats:
    - format: colored-line-number
  sort-results: true

linters:
  disable-all: true
  enable:
    # Bug detection
    - errcheck          # unchecked errors
    - govet             # go vet checks
    - staticcheck       # advanced static analysis
    - bodyclose         # unclosed HTTP response bodies
    - nilerr            # returning nil when err is not nil
    - sqlclosecheck     # unclosed sql.Rows

    # Code quality
    - unused            # unused code
    - ineffassign       # ineffective assignments
    - gosimple          # simplifications
    - gocritic          # opinionated checks
    - revive            # extensible linter (replaces golint)
    - unconvert         # unnecessary type conversions
    - unparam           # unused function parameters
    - wastedassign      # wasted variable assignments

    # Error handling
    - errname           # error naming conventions (ErrFoo)
    - wrapcheck         # errors from external packages wrapped

    # Style
    - gofumpt           # stricter gofmt
    - misspell          # common spelling mistakes
    - whitespace        # unnecessary whitespace

    # Security
    - gosec             # security issues

    # Performance
    - prealloc          # preallocate slices
    - copyloopvar       # loop variable copy issues

    # Complexity
    - cyclop            # cyclomatic complexity
    - funlen            # function length
    - gocognit          # cognitive complexity

linters-settings:
  govet:
    enable-all: true

  gocritic:
    enabled-tags:
      - diagnostic
      - style
      - performance
    disabled-checks:
      - commentedOutCode  # sometimes useful during development
      - hugeParam         # too noisy for request/response structs

  revive:
    rules:
      - name: blank-imports
      - name: context-as-argument
      - name: context-keys-type
      - name: error-naming
      - name: error-return
      - name: error-strings
      - name: exported
      - name: increment-decrement
      - name: indent-error-flow
      - name: range
      - name: receiver-naming
      - name: time-naming
      - name: unexported-return
      - name: var-declaration
      - name: var-naming

  errcheck:
    check-type-assertions: true

  cyclop:
    max-complexity: 15

  funlen:
    lines: 80
    statements: 50

  gocognit:
    min-complexity: 20

  gosec:
    excludes:
      - G104  # audit errors not checked (covered by errcheck)

  misspell:
    locale: US

issues:
  exclude-use-default: false
  max-issues-per-linter: 0
  max-same-issues: 0

  exclude-rules:
    # Allow fmt.Println in main package
    - path: cmd/
      linters: [forbidigo]

    # Relax complexity in tests
    - path: _test\.go
      linters: [cyclop, funlen, gocognit]

    # Don't check error wrapping in tests
    - path: _test\.go
      linters: [wrapcheck]
```

### Running

```bash
# Run all enabled linters
golangci-lint run ./...

# Run specific linters
golangci-lint run --enable=errcheck,govet ./...

# Fix auto-fixable issues
golangci-lint run --fix ./...

# Show which linters ran
golangci-lint run --verbose ./...

# New code only (great for CI on PRs)
golangci-lint run --new-from-rev=main ./...
```

## go vet

Built-in static analysis. Always run it.

```bash
go vet ./...

# Specific analyzers
go vet -vettool=$(which shadow) ./...
```

Common catches:
- Printf format mismatches
- Unreachable code
- Copying mutexes
- Goroutine variable capture bugs
- Struct tag format errors

## gofumpt (Stricter Formatting)

Superset of `gofmt` with additional formatting rules.

```bash
go install mvdan.cc/gofumpt@latest

# Format all files
gofumpt -w .

# Check formatting (useful in CI)
gofumpt -d . | head -1 && echo "formatting issues found" && exit 1
```

Additional rules beyond gofmt:
- Removes unnecessary empty lines
- Groups imports (stdlib, external, internal)
- Removes empty `func(){}` bodies
- Standardizes newlines around declarations

## Go Generate

```go
// Generate mocks, stringer methods, SQL queries, etc.
//go:generate mockgen -source=store.go -destination=mock_store_test.go -package=service
//go:generate stringer -type=Status
//go:generate sqlc generate
```

```bash
go generate ./...
```

## Build

```bash
# Build all binaries
go build ./cmd/...

# Build with version info
go build -ldflags="-X main.version=1.2.3 -X main.commit=$(git rev-parse HEAD)" ./cmd/api

# Cross-compile
GOOS=linux GOARCH=amd64 go build -o myapp-linux ./cmd/api
GOOS=darwin GOARCH=arm64 go build -o myapp-darwin ./cmd/api
GOOS=windows GOARCH=amd64 go build -o myapp.exe ./cmd/api

# Minimal binary (strip debug info)
go build -ldflags="-s -w" -o myapp ./cmd/api

# Build with CGO disabled (fully static binary)
CGO_ENABLED=0 go build -o myapp ./cmd/api
```

## Common Makefile

```makefile
# Project metadata
MODULE   := $(shell go list -m)
VERSION  := $(shell git describe --tags --always --dirty)
COMMIT   := $(shell git rev-parse HEAD)
LDFLAGS  := -ldflags="-X main.version=$(VERSION) -X main.commit=$(COMMIT) -s -w"

.PHONY: all build test lint fmt tidy generate clean

all: lint test build

## Build all binaries
build:
	CGO_ENABLED=0 go build $(LDFLAGS) -o bin/ ./cmd/...

## Run tests with race detection and coverage
test:
	go test -race -cover -coverprofile=coverage.out ./...
	@go tool cover -func=coverage.out | grep total | awk '{print "Coverage:", $$3}'

## Run integration tests
test-integration:
	go test -race -tags=integration -coverprofile=coverage-integration.out ./...

## Run linters
lint:
	golangci-lint run ./...

## Format code
fmt:
	gofumpt -w .

## Tidy and verify dependencies
tidy:
	go mod tidy
	go mod verify

## Generate code (mocks, etc.)
generate:
	go generate ./...

## Run the API server
run:
	go run ./cmd/api

## Full CI pipeline
ci: tidy fmt lint test build
	@echo "CI passed"

## Clean build artifacts
clean:
	rm -rf bin/ coverage*.out

## Show help
help:
	@grep -E '^## ' Makefile | sed 's/## //'
```

## CI/CD (GitHub Actions)

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-go@v5
        with:
          go-version: '1.22'

      - name: Verify dependencies
        run: go mod verify

      - name: Build
        run: go build ./...

      - name: Test
        run: go test -race -coverprofile=coverage.out ./...

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          files: coverage.out

  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-go@v5
        with:
          go-version: '1.22'

      - name: golangci-lint
        uses: golangci/golangci-lint-action@v4
        with:
          version: latest
```

## Debugging

```bash
# Delve debugger
go install github.com/go-delve/delve/cmd/dlv@latest

# Debug a binary
dlv debug ./cmd/api

# Attach to running process
dlv attach <pid>

# Debug a test
dlv test ./internal/service -- -run TestUserCreate

# Common delve commands:
# break main.main    -- set breakpoint
# continue           -- run until breakpoint
# next               -- step over
# step               -- step into
# print var          -- print variable
# goroutines         -- list goroutines
# stack              -- show stack trace
```

## Profiling

```go
import _ "net/http/pprof"

// In main():
go func() {
    log.Println(http.ListenAndServe("localhost:6060", nil))
}()
```

```bash
# CPU profile
go tool pprof http://localhost:6060/debug/pprof/profile?seconds=30

# Memory profile
go tool pprof http://localhost:6060/debug/pprof/heap

# Goroutine profile
go tool pprof http://localhost:6060/debug/pprof/goroutine

# Trace
curl -o trace.out http://localhost:6060/debug/pprof/trace?seconds=5
go tool trace trace.out

# Benchmark profiling
go test -bench=BenchmarkX -cpuprofile=cpu.out -memprofile=mem.out ./...
go tool pprof cpu.out
```

## Recommended Libraries

| Category | Library | Notes |
|----------|---------|-------|
| HTTP router | `github.com/go-chi/chi/v5` | Lightweight, stdlib-compatible |
| HTTP router | `net/http` (Go 1.22+) | Enhanced routing in stdlib |
| Database | `github.com/jackc/pgx/v5` | PostgreSQL driver + pool |
| Database | `github.com/jmoiron/sqlx` | Extensions to `database/sql` |
| SQL gen | `github.com/sqlc-dev/sqlc` | Generate type-safe Go from SQL |
| ORM | `gorm.io/gorm` | Full ORM (use when DX > perf) |
| Logging | `log/slog` (stdlib) | Structured logging (Go 1.21+) |
| Logging | `go.uber.org/zap` | High-performance structured logging |
| Config | `github.com/caarlos0/env/v11` | Struct-based env loading |
| CLI | `github.com/spf13/cobra` | CLI framework |
| Testing | `github.com/stretchr/testify` | Assertions and mocks |
| Mocking | `go.uber.org/mock` | Interface mock generation |
| HTTP client | `net/http` (stdlib) | Usually sufficient |
| Validation | `github.com/go-playground/validator/v10` | Struct tag validation |
| UUID | `github.com/google/uuid` | UUID generation |
| Migrations | `github.com/golang-migrate/migrate/v4` | Database migrations |
| Concurrency | `golang.org/x/sync/errgroup` | Structured goroutine groups |

## Tool Version Pinning

```bash
# Pin tool versions in go.mod with a tools.go file
```

```go
//go:build tools

package tools

import (
    _ "github.com/golangci/golangci-lint/cmd/golangci-lint"
    _ "go.uber.org/mock/mockgen"
    _ "github.com/sqlc-dev/sqlc/cmd/sqlc"
)
```

```bash
go mod tidy  # adds tool deps to go.mod
```
