# Language Profiles

## Primary Languages (Deep Expertise)

### Python

- **Paradigm**: Multi-paradigm (OOP + functional + procedural)
- **Sweet Spot**: Data processing, APIs, scripting, ML
- **Ecosystem**: pip/poetry, pytest, black, mypy
- **Gotchas**:
  - GIL limits true parallelism for CPU-bound work
  - Mutable default arguments shared across calls
  - Late binding closures in loops
  - Import circular dependencies
  - `is` vs `==` for comparisons

### JavaScript/TypeScript

- **Paradigm**: Multi-paradigm (prototypal OOP + functional)
- **Sweet Spot**: Web, Node.js services, full-stack
- **Ecosystem**: npm/pnpm, Jest, ESLint, Prettier
- **Gotchas**:
  - `this` binding depends on call site
  - Async surprises (unhandled promise rejections)
  - Type coercion (`==` vs `===`)
  - Prototype chain confusion
  - `var` hoisting (use `const`/`let`)

### Go

- **Paradigm**: Procedural with interfaces
- **Sweet Spot**: Services, CLIs, concurrent systems
- **Ecosystem**: go mod, testing package, gofmt, staticcheck
- **Gotchas**:
  - Range loop variable capture in goroutines
  - Nil interface vs nil value
  - Slice append aliasing (shared backing array)
  - No sum types / tagged unions (use interface)
  - Error handling verbosity

### Rust

- **Paradigm**: Multi-paradigm (functional + systems)
- **Sweet Spot**: Systems programming, high-performance services
- **Ecosystem**: cargo, rustfmt, clippy
- **Gotchas**:
  - Borrow checker learning curve
  - Async complexity (pinning, lifetimes)
  - String types (`String` vs `&str` vs `OsStr`)
  - Orphan rule for trait implementations
  - Compile times on large projects

## Secondary Languages (On-Demand)

| Language | Domain | Package Manager | Testing | Key Gotcha |
|----------|--------|----------------|---------|------------|
| Java | Enterprise, Android | Maven/Gradle | JUnit | Verbose boilerplate, checked exceptions |
| C# | .NET, Unity | NuGet | xUnit/NUnit | Value vs reference types, async void |
| Ruby | Rails, scripting | Bundler/gem | RSpec | Method missing magic, monkey patching |
| PHP | WordPress, web | Composer | PHPUnit | Inconsistent stdlib naming, type juggling |
| Swift | iOS, macOS | SPM | XCTest | Optional chaining, ARC retain cycles |
| Kotlin | Android, JVM | Gradle | JUnit/KotlinTest | Null safety interop with Java, coroutine scope |

## Ecosystem Quick Reference

| Language | Pkg Manager | Test Framework | Linter | Formatter | Docs |
|----------|------------|----------------|--------|-----------|------|
| Python | pip/poetry | pytest | ruff/pylint | black/ruff | Sphinx/docstrings |
| JS/TS | npm/pnpm | Jest/Vitest | ESLint | Prettier | JSDoc/TSDoc |
| Go | go mod | testing + testify | golangci-lint | gofmt/goimports | godoc |
| Rust | cargo | cargo test | clippy | rustfmt | rustdoc |
| Java | Maven/Gradle | JUnit 5 | SpotBugs/PMD | google-java-format | Javadoc |
| C# | NuGet | xUnit | Roslyn analyzers | dotnet format | XML comments |
| Ruby | Bundler | RSpec | RuboCop | RuboCop | YARD |

## Recommended Libraries by Domain

### Web/HTTP

| Language | Options |
|----------|---------|
| Python | FastAPI, Flask, Django |
| JS/TS | Express, Fastify, Next.js, Hono |
| Go | net/http (stdlib), chi, echo, gin |
| Rust | axum, actix-web, warp |

### Database

| Language | Options |
|----------|---------|
| Python | SQLAlchemy, asyncpg, psycopg |
| JS/TS | Prisma, Drizzle, knex |
| Go | database/sql (stdlib), sqlx, GORM |
| Rust | sqlx, diesel, sea-orm |

### Logging

| Language | Options |
|----------|---------|
| Python | structlog, loguru, stdlib logging |
| JS/TS | pino, winston |
| Go | log/slog (stdlib), zap, zerolog |
| Rust | tracing, log + env_logger |

### CLI

| Language | Options |
|----------|---------|
| Python | click, typer, argparse |
| JS/TS | commander, yargs, oclif |
| Go | cobra, urfave/cli, flag (stdlib) |
| Rust | clap, argh |
