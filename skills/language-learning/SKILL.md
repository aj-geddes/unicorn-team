---
name: language-learning
description: >-
  Guides rapid acquisition of new programming languages, frameworks, and paradigms
  through a structured 5-phase protocol. ALWAYS trigger on "learn Rust", "learn Go",
  "new language", "pick up a language", "never used X before", "getting started with",
  "how does X work", "teach me Y", "unfamiliar technology", "language comparison",
  "evaluate language", "switch to X", "polyglot", "first time using". Use when
  encountering unfamiliar technology, evaluating language choices, or onboarding
  to a new stack. Delegates to Polyglot agent for execution.
---
<!-- Last reviewed: 2026-03 -->

# Language Learning Protocol

## 5-Phase Protocol

| Phase | Duration | Goal | Key Deliverables |
|-------|----------|------|-----------------|
| 1. Exploration | 30 min | Run first program | Hello World, build system, basic syntax |
| 2. Patterns | 1-2 hr | Map to known equivalents | Comparison table, pattern mapping |
| 3. Ecosystem | 1 hr | Set up toolchain | Package manager, test framework, linter, LSP |
| 4. Idioms | 2-3 hr | Learn community conventions | Style guide notes, anti-patterns list |
| 5. Production | Ongoing | Ship production code | Logging, monitoring, deployment, security |

**Target**: Zero to implementing small features in < 4 hours.

Run `scripts/new-language.sh` with the target language to execute interactively.

## Phase 1: Exploration Checklist

- [ ] Install toolchain (compiler/interpreter/runtime)
- [ ] Hello World builds and runs
- [ ] Variable declaration (mutable vs immutable)
- [ ] Function definition and calling
- [ ] Control flow (if, for, match/switch)
- [ ] Error handling mechanism identified
- [ ] Entry point convention understood

## Phase 2: Pattern Mapping

Complete this comparison for the new language:

| Concept | Python | JavaScript | Go | New Language |
|---------|--------|------------|-----|-------------|
| Variables | `x = 5` | `let x = 5` | `x := 5` | ? |
| Constants | `X = 5` | `const X = 5` | `const X = 5` | ? |
| Functions | `def f():` | `function f()` | `func f()` | ? |
| Error handling | `try/except` | `try/catch` | `if err != nil` | ? |
| Null safety | `None` | `null/undefined` | `nil` | ? |
| Iteration | `for x in list:` | `list.forEach()` | `for _, x := range` | ? |
| Collections | `list, dict` | `Array, Object` | `slice, map` | ? |
| Types/Classes | `class Foo:` | `class Foo` | `type Foo struct` | ? |
| Imports | `import foo` | `import foo from` | `import "foo"` | ? |
| Testing | `pytest` | `jest` | `go test` | ? |
| Packages | `pip` | `npm` | `go mod` | ? |

For each concept, ask: "What's the equivalent in languages I know?"

## Phase 3: Ecosystem Setup

```yaml
identify:
  package_manager: cargo | go mod | npm | pip | ...
  test_framework:  built-in or external, conventions
  linter_formatter: clippy/rustfmt | golint/gofmt | eslint/prettier | ...
  lsp_server:      name, IDE integration
```

Ecosystem checklist:
- [ ] Package manager configured
- [ ] Can write, run, and get coverage for tests
- [ ] Linter and formatter installed
- [ ] IDE autocomplete working
- [ ] Official docs bookmarked

## Phase 4: Idioms

1. Read official style guide
2. Study standard library patterns
3. Review top 5 popular GitHub projects
4. Capture anti-patterns from linter warnings

## Phase 5: Production Readiness

- [ ] Structured logging configured
- [ ] Error handling comprehensive
- [ ] Graceful shutdown implemented
- [ ] Health check endpoint
- [ ] Metrics/monitoring integrated
- [ ] Configuration externalized
- [ ] Secrets management configured
- [ ] Resource limits set
- [ ] Deployment documented
- [ ] Rollback procedure defined

## Paradigm Recognition

```
Language Analysis
|
+-- Object-Oriented (Java, C#, Python, Ruby)
|   Classes, inheritance, polymorphism
|
+-- Functional (Haskell, Elixir, Clojure, Scala)
|   First-class functions, immutability
|
+-- Procedural (C, Go, Pascal)
|   Functions as primary unit, explicit state
|
+-- Multi-Paradigm (Python, Rust, JavaScript, Kotlin)
|   Developer chooses approach
|
+-- Declarative (SQL, HTML, CSS, Terraform)
    Describe WHAT, not HOW
```

## Quick Reference Template

For every new language, produce:

```markdown
# [Language] Quick Reference
## Setup        — install, project init, run, test commands
## Basics       — variables, functions, control flow, errors
## Patterns     — map, filter, reduce, null handling, async
## Ecosystem    — package manager, testing, linting, formatting
## Idioms       — language-specific best practices
## Anti-Patterns — common mistakes to avoid
## Resources    — official docs, style guide, community
```

See `references/learning-templates.md` for full template.

## Knowledge Transfer Format

```yaml
knowledge_transfer:
  language: "[Name]"
  paradigm: "[OOP | FP | Procedural | Multi | Declarative]"
  quick_reference: "[path to cheat sheet]"
  gotchas:
    - "Common mistake 1"
    - "Common mistake 2"
  production_notes:
    - "Deployment consideration"
    - "Performance characteristic"
  confidence_level: "beginner | intermediate | proficient"
```

## Learning Velocity Targets

| Metric | Target |
|--------|--------|
| Hello World running | < 30 min |
| Basic patterns mapped | < 90 min |
| Ecosystem set up, tests passing | < 3 hr |
| First real feature implemented | < 4 hr |
| Pattern recognition accuracy | > 85% |
| Anti-pattern avoidance (first 10 implementations) | > 80% |

## When NOT to Learn Everything

### Decision Criteria

Learn what the task requires. Skip the rest until needed.

| Task | Learn | Skip (for now) |
|------|-------|----------------|
| REST API in Go | HTTP server, routing, JSON, errors, testing | Generics, reflection, cgo |
| CLI tool in Rust | Clap, file I/O, error handling | Unsafe, macros, async |
| Data pipeline in Elixir | GenServer, streams, Ecto | NIFs, distributed Erlang |

### Progressive Depth

| Layer | Timeframe | Scope |
|-------|-----------|-------|
| 1 | Day 1 | Core syntax, basic patterns |
| 2 | Week 1 | Ecosystem, idioms, testing |
| 3 | Month 1 | Advanced features, performance |
| 4 | Month 3+ | Internals, contributing |

Most tasks require Layer 1-2 only.

## Reference Files

- `references/language-comparison-matrices.md` - Comparison tables across 10+ languages
- `references/learning-templates.md` - Setup scripts, quick reference templates
- `references/phase-guides.md` - Detailed guides for each learning phase
- `scripts/new-language.sh` - Interactive learning protocol script
