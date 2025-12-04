---
name: language-learning
description: >
  Rapid acquisition protocol for new programming languages, frameworks, and paradigms.
  Activate when encountering unfamiliar technology or when explicitly learning new tools.
  Trigger phrases: "learn Rust", "new language", "how does X work?", "never used Y before",
  "teach me Z", "getting started with". Identifies paradigms, maps to known patterns,
  builds quick references, and transfers knowledge systematically through 5-phase protocol.
---

# Language Learning: The Polyglot's Advantage

## Core Principle

**Don't learn syntax. Learn paradigms, then map patterns.**

A 10X developer doesn't memorize documentation—they recognize that error handling in Go is just explicit Result types, that goroutines are lightweight threads, and that interfaces are structural contracts. Transfer knowledge from languages you know to accelerate learning what you don't.

---

## When to Invoke This Skill

Activate this skill when:
- Encountering a new programming language or framework
- User explicitly requests language learning ("teach me Rust")
- Implementation task requires unfamiliar technology
- Documentation references unknown paradigms or patterns
- Need to evaluate technology choices

**Do NOT invoke for:**
- Minor library additions in familiar languages
- Updating dependencies in known frameworks
- Minor syntax questions (use search instead)

---

## Rapid Learning Protocol (5 Phases)

### Phase 1: Exploration (30 minutes)

Get hands dirty immediately. Build understanding through doing.

**Steps:**
1. Hello World + build system
2. Variable declaration and types
3. Functions and methods
4. Control flow (if/for/while)
5. Error handling

**Example: Learning Rust (Phase 1)**

```rust
// src/main.rs - Your first 30 minutes
fn main() {
    // Variables
    let immutable = "Hello";
    let mut mutable = "World";
    mutable = "Rust";

    // Functions
    greet(immutable, mutable);

    // Control flow
    for i in 0..3 {
        println!("Count: {}", i);
    }

    // Error handling
    match divide(10, 0) {
        Ok(result) => println!("Result: {}", result),
        Err(e) => println!("Error: {}", e),
    }
}

fn greet(lang: &str, name: &str) {
    println!("{}, {}!", lang, name);
}

fn divide(a: i32, b: i32) -> Result<i32, String> {
    if b == 0 {
        Err("Division by zero".to_string())
    } else {
        Ok(a / b)
    }
}
```

**Key Observations (capture these):**
- How are types declared? (explicit, inferred, both?)
- How are functions defined? (keyword? syntax?)
- How does error handling work? (exceptions, return values, Result types?)
- What's the compilation/interpretation model?

See `references/phase-guides.md` for detailed checklists and setup scripts.

### Phase 2: Patterns (1-2 hours)

Identify core patterns and map to known equivalents.

**Quick Pattern Map:**
```yaml
iteration:  for item in items → items.forEach() → for _, item := range → .iter()
null_handling: None → null/undefined → nil → Option<T>
async: asyncio → Promises → goroutines → async/await
```

**Pattern Recognition Exercise:**

For each new language, complete the comparison table:
- Variables, constants, functions
- Error handling, null safety
- Iteration, collections
- Classes/types, methods
- Imports, testing, package manager

See `references/language-comparison-matrices.md` for comprehensive comparison tables across 10+ languages.

### Phase 3: Ecosystem (1 hour)

Understand tooling and community conventions.

**Essential Tools:**
```yaml
package_manager: cargo, go mod, npm, pip
testing_framework: Built-in vs external, test conventions
linter_formatter: clippy/rustfmt, golint/gofmt, eslint/prettier
ide_support: LSP server name, autocomplete setup
```

**Ecosystem Checklist:**
- [ ] Package manager configured
- [ ] Testing framework understood (write, run, coverage)
- [ ] Linter and formatter installed
- [ ] IDE/LSP configured
- [ ] Documentation source identified
- [ ] Community forum located

See `references/learning-templates.md` for setup script template.

### Phase 4: Idioms (2-3 hours)

Learn "the way things are done here"—conventions, patterns, anti-patterns.

**Idiom Discovery Process:**
1. Read official style guide (PEP 8, Effective Go, Rust API Guidelines)
2. Study standard library patterns
3. Review top 5 popular projects on GitHub
4. Capture anti-patterns from linters and code reviews

**Common Idioms by Language:**

**Rust:**
- Ownership: values have single owner, borrowing for access
- Error handling: `Result<T, E>`, `?` operator
- Iterators over manual loops
- Anti-patterns: unnecessary clones, unwrap() in production

**Go:**
- Error handling: `if err != nil { return err }`
- Small focused interfaces (io.Reader: 1 method)
- Cheap goroutines, channels for communication
- Anti-patterns: ignoring errors, panic() for normal errors

**Python:**
- List comprehensions over map/filter
- Context managers for cleanup
- Decorators for function modification
- Anti-patterns: mutable default arguments, broad Exception catching

See `references/language-comparison-matrices.md` for idioms across 10+ languages.

### Phase 5: Production (Ongoing)

Make code production-ready.

**Production Checklist:**
- [ ] Logging configured (structured, appropriate levels)
- [ ] Error handling comprehensive
- [ ] Graceful shutdown implemented
- [ ] Health check endpoint
- [ ] Metrics/monitoring integrated
- [ ] Configuration externalized
- [ ] Secrets management configured
- [ ] Resource limits set
- [ ] Deployment process documented
- [ ] Rollback procedure defined

**Deployment Patterns:**
```yaml
rust: Cross-compile, static binary, no runtime
go: Single binary, no dependencies, fast startup
python: Virtualenv, requirements.txt, WSGI server
javascript: Bundle, node_modules, PM2/systemd
```

See `references/phase-guides.md` for profiling and monitoring setup.

---

## Paradigm Recognition

### Identify the Core Paradigm

```
Language Analysis
│
├─ Object-Oriented (Java, C#, Python, Ruby)
│   • Classes and objects as primary abstraction
│   • Inheritance and polymorphism
│
├─ Functional (Haskell, Elixir, Clojure, Scala)
│   • Functions as first-class citizens
│   • Immutability by default
│
├─ Procedural (C, Go, Pascal)
│   • Procedures/functions as primary unit
│   • Explicit state management
│
├─ Multi-Paradigm (Python, Rust, JavaScript, Kotlin)
│   • Supports multiple approaches
│   • Developer chooses paradigm
│
└─ Declarative (SQL, HTML, CSS, Terraform)
    • Describe WHAT, not HOW
    • System determines execution
```

### Map to Known Patterns

**For each new concept, ask: "What's the equivalent in languages I know?"**

```yaml
concept: ownership (Rust)
similar_to:
  - Smart pointers in C++ (unique_ptr, shared_ptr)
  - Reference counting in Python
  - Garbage collection (but compile-time checked)
key_difference: Enforced at compile time, zero runtime cost

concept: goroutines (Go)
similar_to:
  - Threads, but 10-100x lighter
  - Async/await (but preemptive)
  - Green threads
key_difference: Multiplexed onto OS threads, extremely cheap

concept: decorators (Python)
similar_to:
  - Higher-order functions
  - Middleware pattern
  - Aspect-oriented programming
key_difference: Syntactic sugar, @ syntax
```

### Identify Unique Concepts

Some concepts don't have direct equivalents—these require deep understanding.

**Rust Ownership:**
- Concept: Values have one owner, borrowed with explicit lifetimes
- Why unique: Compile-time memory safety without GC
- Mastery signal: Stop fighting borrow checker, think in ownership

**Go Channels:**
- Concept: Share memory by communicating, not communicate by sharing
- Why unique: CSP model baked into language
- Mastery signal: Choose between sync.Mutex and channels correctly

**Elixir OTP:**
- Concept: Actor model with supervision trees
- Why unique: Fault tolerance as first-class feature
- Mastery signal: Design systems as supervision hierarchies

See `references/language-comparison-matrices.md` for comprehensive comparison across error handling, async models, memory management, type systems, and package management.

---

## Quick Reference Template

For every new language, create a cheat sheet:

```markdown
# [Language] Quick Reference

## Setup
[installation, project init, run, test commands]

## Basics
[variables, functions, control flow, error handling]

## Common Patterns
[map, filter, reduce, null handling, async]

## Ecosystem
[package manager, testing, linting, formatting, docs]

## Idioms
[language-specific best practices]

## Anti-Patterns
[common mistakes to avoid]

## Resources
[official docs, style guide, community, libraries]
```

See `references/learning-templates.md` for full template.

---

## Knowledge Transfer Protocol

Once you've learned the language, transfer knowledge to the Developer agent.

### Transfer Package Format

```yaml
knowledge_transfer:
  language: [Language Name]
  paradigm: [OOP/FP/Procedural/Multi/Declarative]
  quick_reference: "[Path to cheat sheet]"

  gotchas:
    - "Common mistake 1"
    - "Common mistake 2"

  production_notes:
    - "Deployment consideration"
    - "Performance characteristic"

  confidence_level: "beginner/intermediate/proficient"
```

### Transfer Message

```
LANGUAGE LEARNED: [Name]
QUICK REFERENCE: [Path to cheat sheet file]

KEY PATTERNS MAPPED:
- [Known pattern] → [New language equivalent]

UNIQUE CONCEPTS:
- [Concept]: [Brief explanation]

GOTCHAS:
- ⚠️ [Common mistake]

ECOSYSTEM READY:
- [Package manager configured]
- [Testing framework ready]

CONFIDENCE: [beginner/intermediate/proficient]
```

---

## Learning Velocity Metrics

Track your language learning effectiveness:

### Time to Productive

**Target**: < 4 hours from zero to implementing small features

**Phases**:
- 0-30 min: Hello World runs
- 30-90 min: Basic patterns understood
- 90-180 min: Ecosystem set up, tests passing
- 180-240 min: First real feature implemented

### Pattern Recognition Accuracy

**Target**: > 85% correctly identified equivalent patterns

**Example**:
```
Go channels → Async queues: ✅ Correct
Rust lifetimes → Python context managers: ❌ Incorrect
```

### Anti-Pattern Avoidance

**Target**: > 80% avoidance in first 10 implementations

---

## When NOT to Learn Everything

### Tactical Learning

Don't try to master everything. Learn what you need for the task at hand.

**Task**: Implement REST API in Go
- **Learn**: HTTP server, routing, JSON, error handling, testing
- **Skip** (for now): Generics, reflection, cgo, assembly

**Task**: Build CLI tool in Rust
- **Learn**: Clap (CLI parser), file I/O, error handling
- **Skip** (for now): Unsafe, macros, async

### Progressive Depth

```
Layer 1 (Day 1): Core syntax, basic patterns
Layer 2 (Week 1): Ecosystem, idioms, testing
Layer 3 (Month 1): Advanced features, performance tuning
Layer 4 (Month 3+): Language internals, contributing
```

Most tasks only require Layer 1-2. Progress deeper as needed.

---

## Integration with Other Skills

### With Developer Agent
```
Polyglot learns → Creates quick reference → Developer implements
```

### With Architect Agent
```
Polyglot evaluates language tradeoffs → Architect chooses → Developer implements
```

### With Pattern Transfer Skill
```
Identify similar problem in known language → Transfer solution → Adapt to new idioms
```

---

## Summary: The Polyglot Mindset

```
┌─────────────────────────────────────────────────────────┐
│  "Languages are tools, paradigms are skills."           │
│                                                          │
│  Master paradigms (OOP, FP, procedural), and            │
│  new languages become syntax variations.                │
│                                                          │
│  Transfer patterns, don't start from scratch.           │
└─────────────────────────────────────────────────────────┘
```

**Key Principles**:

1. **Recognize Before Memorize** - Identify paradigm, map to known patterns
2. **Build Mental Models** - Understand why, not just what
3. **Learn Through Doing** - Code from minute one, read docs second
4. **Capture Gotchas** - Mistakes are learning opportunities
5. **Transfer Knowledge** - Document for your future self and others

**The 10X Difference**:

- 1X Developer: Learns each language as if it's the first, memorizes syntax, takes months
- 10X Developer: Recognizes paradigms, maps patterns, productive in hours

The Polyglot skill is what separates developers who "know 5 languages" from those who "know programming and can use 50 languages."

---

## Reference Files

- `references/language-comparison-matrices.md` - Comprehensive comparison tables across 10+ languages
- `references/learning-templates.md` - Setup scripts, quick reference templates, phase checklists
- `references/phase-guides.md` - Detailed guides for each learning phase
