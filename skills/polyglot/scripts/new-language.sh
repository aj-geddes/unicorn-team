#!/usr/bin/env bash
#
# new-language.sh - Rapid language learning protocol
# Implements the 5-phase language learning framework from the 10X Unicorn system
#
# Usage:
#   ./new-language.sh <language>           # Start fresh
#   ./new-language.sh <language> --resume  # Continue from saved state
#
# Phases:
#   1. EXPLORATION (30 min) - Hello World, basic syntax
#   2. PATTERNS (60 min) - Map to known language patterns
#   3. ECOSYSTEM (30 min) - Tooling, package manager, testing
#   4. IDIOMS (60 min) - Community conventions, anti-patterns
#   5. PRODUCTION (60 min) - Deployment, monitoring, security

set -euo pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly BOLD='\033[1m'
readonly RESET='\033[0m'

# Phase configuration
readonly TOTAL_PHASES=5
readonly PHASE_NAMES=(
    "EXPLORATION"
    "PATTERNS"
    "ECOSYSTEM"
    "IDIOMS"
    "PRODUCTION"
)
readonly PHASE_DURATIONS=(30 60 30 60 60)  # Minutes

# Language extension mapping
declare -A LANG_EXTENSIONS=(
    [python]=py
    [javascript]=js
    [typescript]=ts
    [go]=go
    [rust]=rs
    [java]=java
    [kotlin]=kt
    [c]=c
    [cpp]=cpp
    [csharp]=cs
    [ruby]=rb
    [php]=php
    [swift]=swift
    [elixir]=ex
    [haskell]=hs
    [scala]=scala
    [clojure]=clj
    [dart]=dart
    [lua]=lua
    [zig]=zig
)

# State file for resume functionality
STATE_FILE=""
LEARNING_DIR=""
LANGUAGE=""
CURRENT_PHASE=1
START_TIME=""
PHASE_TIMES=()

#------------------------------------------------------------------------------
# Utility Functions
#------------------------------------------------------------------------------

print_header() {
    echo -e "\n${BOLD}${MAGENTA}═══════════════════════════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}${MAGENTA}$1${RESET}"
    echo -e "${BOLD}${MAGENTA}═══════════════════════════════════════════════════════════════════${RESET}\n"
}

print_phase_header() {
    local phase_num=$1
    local phase_name=$2
    local duration=$3

    echo -e "\n${BOLD}${CYAN}╔═══════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║${RESET}  ${BOLD}Phase ${phase_num}/${TOTAL_PHASES}: ${phase_name}${RESET} ${CYAN}(~${duration} minutes)${RESET}"
    echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════════════════╝${RESET}\n"
}

print_success() {
    echo -e "${GREEN}✓${RESET} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${RESET} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${RESET} $1"
}

print_error() {
    echo -e "${RED}✗${RESET} $1" >&2
}

print_checklist_item() {
    echo -e "  ${CYAN}[ ]${RESET} $1"
}

format_time() {
    local seconds=$1
    local minutes=$((seconds / 60))
    local remaining_seconds=$((seconds % 60))

    if [ $minutes -gt 0 ]; then
        echo "${minutes}m ${remaining_seconds}s"
    else
        echo "${remaining_seconds}s"
    fi
}

#------------------------------------------------------------------------------
# State Management
#------------------------------------------------------------------------------

save_state() {
    cat > "$STATE_FILE" <<EOF
LANGUAGE=$LANGUAGE
CURRENT_PHASE=$CURRENT_PHASE
START_TIME=$START_TIME
PHASE_TIMES=(${PHASE_TIMES[@]:-})
EOF
    print_info "State saved to $STATE_FILE"
}

load_state() {
    if [ -f "$STATE_FILE" ]; then
        # shellcheck source=/dev/null
        source "$STATE_FILE"
        return 0
    fi
    return 1
}

#------------------------------------------------------------------------------
# Language Setup
#------------------------------------------------------------------------------

get_language_extension() {
    local lang_lower
    lang_lower=$(echo "$LANGUAGE" | tr '[:upper:]' '[:lower:]')

    if [ -n "${LANG_EXTENSIONS[$lang_lower]:-}" ]; then
        echo "${LANG_EXTENSIONS[$lang_lower]}"
    else
        # Default to language name if not in mapping
        echo "$lang_lower"
    fi
}

setup_learning_directory() {
    print_info "Setting up learning directory: $LEARNING_DIR"

    if [ -d "$LEARNING_DIR" ]; then
        print_warning "Directory already exists, using existing directory"
    else
        mkdir -p "$LEARNING_DIR"
        print_success "Created $LEARNING_DIR"
    fi

    # Create subdirectories
    mkdir -p "$LEARNING_DIR/phase1-exploration"
    mkdir -p "$LEARNING_DIR/phase2-patterns"
    mkdir -p "$LEARNING_DIR/phase3-ecosystem"
    mkdir -p "$LEARNING_DIR/phase4-idioms"
    mkdir -p "$LEARNING_DIR/phase5-production"
}

#------------------------------------------------------------------------------
# Phase 1: EXPLORATION (30 min)
#------------------------------------------------------------------------------

phase1_exploration() {
    local ext
    ext=$(get_language_extension)
    local phase_start
    phase_start=$(date +%s)

    print_phase_header 1 "EXPLORATION - Get Your Hands Dirty" 30

    echo -e "${BOLD}Goal:${RESET} Run your first ${LANGUAGE} program and understand basics\n"

    # Create hello world template
    local hello_file="$LEARNING_DIR/phase1-exploration/hello.$ext"
    cat > "$hello_file" <<EOF
# ${LANGUAGE} Hello World
# TODO: Implement a simple program that demonstrates:
# - Variable declaration (mutable and immutable if applicable)
# - Function definition and calling
# - Basic output (print/console.log/println)
# - Control flow (if statement, for loop)
# - Error handling basics

# Your code here...
EOF

    print_success "Created template: $hello_file"

    echo -e "\n${BOLD}${YELLOW}CHECKLIST:${RESET}\n"
    print_checklist_item "Install ${LANGUAGE} toolchain (compiler/interpreter/runtime)"
    print_checklist_item "Create a new project/initialize workspace"
    print_checklist_item "Write Hello World program"
    print_checklist_item "Successfully build/compile the program"
    print_checklist_item "Successfully run the program"
    print_checklist_item "Declare variables (understand mutable vs immutable)"
    print_checklist_item "Define and call a function"
    print_checklist_item "Implement basic control flow (if, for loop)"
    print_checklist_item "Handle a simple error/exception"
    print_checklist_item "Understand the build/run command"

    echo -e "\n${BOLD}Key Questions to Answer:${RESET}"
    echo "  • How are types declared? (explicit, inferred, dynamic?)"
    echo "  • How are functions defined? (keyword? syntax?)"
    echo "  • How does error handling work? (exceptions, Result types, error codes?)"
    echo "  • What's the compilation/interpretation model?"
    echo "  • What's the entry point? (main function, top-level code?)"

    echo -e "\n${CYAN}${BOLD}═══════════════════════════════════════════════════════════════════${RESET}"
    echo -e "${CYAN}Complete the checklist above, then press ${BOLD}ENTER${RESET}${CYAN} to continue...${RESET}"
    echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════════════════${RESET}"
    read -r

    local phase_end
    phase_end=$(date +%s)
    local duration=$((phase_end - phase_start))
    PHASE_TIMES+=("$duration")

    print_success "Phase 1 completed in $(format_time $duration)"
    save_state
}

#------------------------------------------------------------------------------
# Phase 2: PATTERNS (60 min)
#------------------------------------------------------------------------------

phase2_patterns() {
    local ext
    ext=$(get_language_extension)
    local phase_start
    phase_start=$(date +%s)

    print_phase_header 2 "PATTERNS - Map to Known Languages" 60

    echo -e "${BOLD}Goal:${RESET} Understand ${LANGUAGE} patterns by mapping to languages you know\n"

    # Create patterns template
    local patterns_file="$LEARNING_DIR/phase2-patterns/patterns.$ext"
    cat > "$patterns_file" <<EOF
# ${LANGUAGE} Pattern Mapping
# Map each ${LANGUAGE} pattern to equivalent patterns in Python, JavaScript, Go, etc.

# TODO: Implement examples for each pattern:

# 1. ITERATION
# How do I loop over collections?
# Python: for item in items:
# JavaScript: items.forEach(item => ...)
# ${LANGUAGE}: ???

# 2. COLLECTIONS
# What data structures exist?
# Python: list, dict, set, tuple
# JavaScript: Array, Object, Map, Set
# ${LANGUAGE}: ???

# 3. NULL/OPTIONAL HANDLING
# How do I handle missing values?
# Python: None, if x is not None:
# JavaScript: null/undefined, x?.property
# ${LANGUAGE}: ???

# 4. ASYNC/CONCURRENCY
# How do I handle asynchronous operations?
# Python: async/await
# JavaScript: Promises, async/await
# ${LANGUAGE}: ???

# 5. ERROR PROPAGATION
# How do I propagate errors up the call stack?
# Python: raise Exception
# JavaScript: throw Error
# ${LANGUAGE}: ???
EOF

    print_success "Created template: $patterns_file"

    # Create comparison table
    local comparison_file="$LEARNING_DIR/phase2-patterns/comparison.md"
    cat > "$comparison_file" <<EOF
# ${LANGUAGE} Pattern Comparison

Fill in the ${LANGUAGE} column as you learn:

| Concept           | Python                | JavaScript          | Go                  | ${LANGUAGE}       |
|-------------------|-----------------------|---------------------|---------------------|-------------------|
| Variables         | \`x = 5\`               | \`let x = 5\`         | \`x := 5\`            | ?                 |
| Constants         | \`X = 5\` (convention)  | \`const X = 5\`       | \`const X = 5\`       | ?                 |
| Functions         | \`def func():\`         | \`function func()\`   | \`func func()\`       | ?                 |
| Error handling    | \`try/except\`          | \`try/catch\`         | \`if err != nil\`     | ?                 |
| Null safety       | \`None\`                | \`null/undefined\`    | \`nil\`               | ?                 |
| Iteration         | \`for x in list:\`      | \`list.forEach()\`    | \`for _, x := range\` | ?                 |
| Collections       | \`list, dict\`          | \`Array, Object\`     | \`slice, map\`        | ?                 |
| Classes/Types     | \`class Foo:\`          | \`class Foo\`         | \`type Foo struct\`   | ?                 |
| Methods           | \`def method(self):\`   | \`method() {}\`       | \`func (f *Foo)\`     | ?                 |
| Imports           | \`import foo\`          | \`import foo from\`   | \`import "foo"\`      | ?                 |
| Testing           | \`pytest\`              | \`jest/mocha\`        | \`go test\`           | ?                 |
| Package manager   | \`pip/poetry\`          | \`npm/yarn\`          | \`go mod\`            | ?                 |

## Pattern Recognition Notes

### Similar Patterns (What maps directly?)

- Pattern 1: [Known language pattern] → [${LANGUAGE} equivalent]
- Pattern 2: [Known language pattern] → [${LANGUAGE} equivalent]

### Unique Concepts (What's different?)

- Concept 1: [${LANGUAGE}-specific feature with no direct equivalent]
- Concept 2: [${LANGUAGE}-specific feature with no direct equivalent]

### Paradigm

- [ ] Object-Oriented (classes, inheritance, polymorphism)
- [ ] Functional (immutability, higher-order functions, composition)
- [ ] Procedural (functions, explicit state)
- [ ] Multi-Paradigm (supports multiple approaches)
- [ ] Declarative (describe what, not how)
EOF

    print_success "Created comparison table: $comparison_file"

    echo -e "\n${BOLD}${YELLOW}CHECKLIST:${RESET}\n"
    print_checklist_item "Understand variable declaration patterns"
    print_checklist_item "Map function/method definitions to known languages"
    print_checklist_item "Identify control flow patterns (if, for, while, switch)"
    print_checklist_item "Understand error handling mechanism"
    print_checklist_item "Map collection types (arrays, maps, sets, etc.)"
    print_checklist_item "Understand null/optional value handling"
    print_checklist_item "Identify async/concurrency model (if applicable)"
    print_checklist_item "Map class/struct/type definitions"
    print_checklist_item "Complete the comparison table above"
    print_checklist_item "Note at least 3 unique concepts with no direct equivalents"

    echo -e "\n${BOLD}Pattern Discovery Process:${RESET}"
    echo "  1. For each concept, implement it in ${LANGUAGE}"
    echo "  2. Compare to how you'd do it in Python/JavaScript/Go"
    echo "  3. Note similarities and differences"
    echo "  4. Identify the paradigm (OOP, FP, Procedural, etc.)"

    echo -e "\n${CYAN}${BOLD}═══════════════════════════════════════════════════════════════════${RESET}"
    echo -e "${CYAN}Complete the pattern mapping, then press ${BOLD}ENTER${RESET}${CYAN} to continue...${RESET}"
    echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════════════════${RESET}"
    read -r

    local phase_end
    phase_end=$(date +%s)
    local duration=$((phase_end - phase_start))
    PHASE_TIMES+=("$duration")

    print_success "Phase 2 completed in $(format_time $duration)"
    save_state
}

#------------------------------------------------------------------------------
# Phase 3: ECOSYSTEM (30 min)
#------------------------------------------------------------------------------

phase3_ecosystem() {
    local phase_start
    phase_start=$(date +%s)

    print_phase_header 3 "ECOSYSTEM - Tooling & Community" 30

    echo -e "${BOLD}Goal:${RESET} Set up development environment and understand the toolchain\n"

    # Create ecosystem notes file
    local ecosystem_file="$LEARNING_DIR/phase3-ecosystem/ecosystem.md"
    cat > "$ecosystem_file" <<EOF
# ${LANGUAGE} Ecosystem

## Package Manager

**Tool**: ???
**Config File**: ???
**Lock File**: ???

\`\`\`bash
# Install dependencies
[command here]

# Add a new dependency
[command here]

# Update dependencies
[command here]
\`\`\`

## Testing Framework

**Framework**: ???
**Test File Pattern**: ???
**Command to Run Tests**: ???

\`\`\`bash
# Run all tests
[command here]

# Run specific test
[command here]

# Run with coverage
[command here]
\`\`\`

## Linter

**Tool**: ???
**Config File**: ???

\`\`\`bash
# Run linter
[command here]

# Auto-fix issues
[command here]
\`\`\`

## Formatter

**Tool**: ???
**Config File**: ???

\`\`\`bash
# Format code
[command here]

# Check formatting
[command here]
\`\`\`

## IDE/Editor Support

**Language Server**: ???
**Popular Editors**: ???
**Extensions**: ???

## Build System

**Tool**: ???
**Config File**: ???

\`\`\`bash
# Build project
[command here]

# Build for production/release
[command here]
\`\`\`

## Documentation

- Official Docs: ???
- Standard Library Reference: ???
- Style Guide: ???
- Community Forum: ???
- Package Registry: ???

## Quick Setup Script

\`\`\`bash
#!/bin/bash
# setup-${LANGUAGE}.sh

# Install toolchain
# [command here]

# Create new project
# [command here]

# Install development tools
# [command here]

# Run hello world
# [command here]

# Run tests
# [command here]

echo "✅ ${LANGUAGE} environment ready!"
\`\`\`
EOF

    print_success "Created ecosystem guide: $ecosystem_file"

    echo -e "\n${BOLD}${YELLOW}CHECKLIST:${RESET}\n"
    print_checklist_item "Package manager installed and configured"
    print_checklist_item "Can add/install dependencies"
    print_checklist_item "Testing framework set up"
    print_checklist_item "Can write and run tests"
    print_checklist_item "Linter installed and running"
    print_checklist_item "Formatter installed and configured"
    print_checklist_item "IDE/editor has autocomplete working"
    print_checklist_item "Know where to find official documentation"
    print_checklist_item "Identified community resources (forums, chat, etc.)"
    print_checklist_item "Can build/compile the project"

    echo -e "\n${BOLD}Essential Tools to Identify:${RESET}"
    echo "  • Package manager (pip, npm, cargo, go mod, etc.)"
    echo "  • Testing framework (pytest, jest, cargo test, etc.)"
    echo "  • Linter (pylint, eslint, clippy, golint, etc.)"
    echo "  • Formatter (black, prettier, rustfmt, gofmt, etc.)"
    echo "  • Language server (for IDE support)"

    echo -e "\n${CYAN}${BOLD}═══════════════════════════════════════════════════════════════════${RESET}"
    echo -e "${CYAN}Complete the ecosystem setup, then press ${BOLD}ENTER${RESET}${CYAN} to continue...${RESET}"
    echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════════════════${RESET}"
    read -r

    local phase_end
    phase_end=$(date +%s)
    local duration=$((phase_end - phase_start))
    PHASE_TIMES+=("$duration")

    print_success "Phase 3 completed in $(format_time $duration)"
    save_state
}

#------------------------------------------------------------------------------
# Phase 4: IDIOMS (60 min)
#------------------------------------------------------------------------------

phase4_idioms() {
    local ext
    ext=$(get_language_extension)
    local phase_start
    phase_start=$(date +%s)

    print_phase_header 4 "IDIOMS - The ${LANGUAGE} Way" 60

    echo -e "${BOLD}Goal:${RESET} Learn community conventions, patterns, and anti-patterns\n"

    # Create idioms file
    local idioms_file="$LEARNING_DIR/phase4-idioms/idioms.$ext"
    cat > "$idioms_file" <<EOF
# ${LANGUAGE} Idioms and Best Practices

# TODO: Implement examples of idiomatic ${LANGUAGE} code

# IDIOM 1: [Name of idiom]
# Description: How this pattern works in ${LANGUAGE}
# Example:
# [code here]

# IDIOM 2: [Name of idiom]
# Description: How this pattern works in ${LANGUAGE}
# Example:
# [code here]

# IDIOM 3: [Name of idiom]
# Description: How this pattern works in ${LANGUAGE}
# Example:
# [code here]

# ANTI-PATTERN 1: [What NOT to do]
# Why it's bad:
# Bad example:
# [code here]
# Good alternative:
# [code here]

# ANTI-PATTERN 2: [What NOT to do]
# Why it's bad:
# Bad example:
# [code here]
# Good alternative:
# [code here]
EOF

    print_success "Created idioms template: $idioms_file"

    # Create idioms notes
    local idioms_notes="$LEARNING_DIR/phase4-idioms/conventions.md"
    cat > "$idioms_notes" <<EOF
# ${LANGUAGE} Conventions & Idioms

## Naming Conventions

- Variables: ???
- Constants: ???
- Functions: ???
- Classes/Types: ???
- Files: ???
- Packages/Modules: ???

## Common Idioms

### Idiom 1: [Name]

**What**: Brief description
**Why**: Why this pattern is preferred
**Example**:
\`\`\`${ext}
# Code example here
\`\`\`

### Idiom 2: [Name]

**What**: Brief description
**Why**: Why this pattern is preferred
**Example**:
\`\`\`${ext}
# Code example here
\`\`\`

### Idiom 3: [Name]

**What**: Brief description
**Why**: Why this pattern is preferred
**Example**:
\`\`\`${ext}
# Code example here
\`\`\`

## Anti-Patterns

### ❌ Anti-Pattern 1: [Name]

**What NOT to do**:
\`\`\`${ext}
# Bad example
\`\`\`

**Why it's bad**: Explanation

**Do this instead**:
\`\`\`${ext}
# Good example
\`\`\`

### ❌ Anti-Pattern 2: [Name]

**What NOT to do**:
\`\`\`${ext}
# Bad example
\`\`\`

**Why it's bad**: Explanation

**Do this instead**:
\`\`\`${ext}
# Good example
\`\`\`

### ❌ Anti-Pattern 3: [Name]

**What NOT to do**:
\`\`\`${ext}
# Bad example
\`\`\`

**Why it's bad**: Explanation

**Do this instead**:
\`\`\`${ext}
# Good example
\`\`\`

## Resources Referenced

- Official Style Guide: ???
- Popular Projects Reviewed: ???
- Community Discussions: ???
EOF

    print_success "Created conventions guide: $idioms_notes"

    echo -e "\n${BOLD}${YELLOW}CHECKLIST:${RESET}\n"
    print_checklist_item "Read official style guide (if exists)"
    print_checklist_item "Identify naming conventions (snake_case, camelCase, etc.)"
    print_checklist_item "Document at least 5 common idioms"
    print_checklist_item "Document at least 5 anti-patterns to avoid"
    print_checklist_item "Review standard library code for patterns"
    print_checklist_item "Review 2-3 popular open source projects"
    print_checklist_item "Understand error handling conventions"
    print_checklist_item "Understand concurrency patterns (if applicable)"
    print_checklist_item "Note what linters commonly warn about"
    print_checklist_item "Identify community best practices"

    echo -e "\n${BOLD}Discovery Process:${RESET}"
    echo "  1. Read official style guide (PEP 8, Effective Go, Rust Book, etc.)"
    echo "  2. Study standard library implementations"
    echo "  3. Review popular projects on GitHub"
    echo "  4. Note recurring patterns in community code"
    echo "  5. Check what linters flag as issues"
    echo "  6. Read code review comments on popular projects"

    echo -e "\n${CYAN}${BOLD}═══════════════════════════════════════════════════════════════════${RESET}"
    echo -e "${CYAN}Document idioms and anti-patterns, then press ${BOLD}ENTER${RESET}${CYAN} to continue...${RESET}"
    echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════════════════${RESET}"
    read -r

    local phase_end
    phase_end=$(date +%s)
    local duration=$((phase_end - phase_start))
    PHASE_TIMES+=("$duration")

    print_success "Phase 4 completed in $(format_time $duration)"
    save_state
}

#------------------------------------------------------------------------------
# Phase 5: PRODUCTION (60 min)
#------------------------------------------------------------------------------

phase5_production() {
    local phase_start
    phase_start=$(date +%s)

    print_phase_header 5 "PRODUCTION - Ship It!" 60

    echo -e "${BOLD}Goal:${RESET} Understand how to deploy and maintain ${LANGUAGE} applications\n"

    # Create production notes
    local production_file="$LEARNING_DIR/phase5-production/production.md"
    cat > "$production_file" <<EOF
# ${LANGUAGE} Production Readiness

## Deployment

### Build for Production

\`\`\`bash
# Production build command
[command here]
\`\`\`

### Deployment Options

- **Containerization**: Docker? Native binary?
- **Dependencies**: Runtime requirements? Bundling?
- **Startup Time**: Cold start considerations?
- **Resource Usage**: Memory footprint? CPU usage?

### Deployment Checklist

- [ ] Production build optimized (size, performance)
- [ ] Dependencies bundled or documented
- [ ] Configuration externalized (env vars, config files)
- [ ] Secrets management configured
- [ ] Health check endpoint implemented
- [ ] Graceful shutdown implemented

## Logging

### Logging Library

**Library**: ???
**Configuration**: ???

\`\`\`${LANGUAGE}
// Logging example
[code here]
\`\`\`

### Logging Best Practices

- [ ] Structured logging configured
- [ ] Log levels used appropriately (DEBUG, INFO, WARN, ERROR)
- [ ] Sensitive data NOT logged
- [ ] Request IDs/trace IDs included
- [ ] Log aggregation considered

## Monitoring & Observability

### Metrics

**Library/Service**: ???

- [ ] Application metrics exposed
- [ ] Error rates tracked
- [ ] Latency tracked (p50, p95, p99)
- [ ] Resource usage monitored

### Tracing

**Library/Service**: ???

- [ ] Distributed tracing configured
- [ ] Critical paths instrumented

### Health Checks

\`\`\`${LANGUAGE}
// Health check endpoint example
[code here]
\`\`\`

## Performance

### Profiling Tools

- **CPU Profiler**: ???
- **Memory Profiler**: ???
- **Benchmarking**: ???

\`\`\`bash
# Run profiler
[command here]

# Run benchmarks
[command here]
\`\`\`

### Performance Considerations

- [ ] Hot paths identified
- [ ] Benchmarks written for critical code
- [ ] Memory allocations profiled
- [ ] Caching strategy considered
- [ ] Database query optimization reviewed

## Security

### Security Checklist

- [ ] Input validation implemented
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention (output encoding)
- [ ] CSRF protection (if web app)
- [ ] Authentication implemented correctly
- [ ] Authorization checked
- [ ] Secrets not hardcoded
- [ ] Dependencies scanned for vulnerabilities
- [ ] Security headers configured (if web app)
- [ ] Rate limiting implemented

### Security Tools

- **Dependency Scanner**: ???
- **SAST Tool**: ???
- **Security Linter**: ???

## Error Handling

### Error Handling Strategy

- [ ] All errors caught and handled
- [ ] Errors logged with context
- [ ] User-friendly error messages
- [ ] Internal errors don't leak to users
- [ ] Error reporting/tracking configured

## Resource Management

### Resource Limits

- [ ] Connection pools configured
- [ ] Timeout values set appropriately
- [ ] Memory limits configured
- [ ] File descriptor limits considered
- [ ] Circuit breakers implemented (if microservice)

## Rollback Strategy

- [ ] Rollback procedure documented
- [ ] Database migrations reversible
- [ ] Feature flags considered
- [ ] Deployment automation tested

## Documentation

- [ ] API documentation complete
- [ ] Deployment guide written
- [ ] Troubleshooting guide created
- [ ] Runbook for on-call created
EOF

    print_success "Created production guide: $production_file"

    echo -e "\n${BOLD}${YELLOW}CHECKLIST:${RESET}\n"
    print_checklist_item "Understand production build process"
    print_checklist_item "Configure logging appropriately"
    print_checklist_item "Set up error tracking/monitoring"
    print_checklist_item "Implement health check endpoint"
    print_checklist_item "Configure graceful shutdown"
    print_checklist_item "Externalize configuration (env vars)"
    print_checklist_item "Implement secrets management"
    print_checklist_item "Set resource limits (connections, timeouts, memory)"
    print_checklist_item "Understand profiling tools"
    print_checklist_item "Document deployment procedure"
    print_checklist_item "Define rollback strategy"
    print_checklist_item "Review security checklist"

    echo -e "\n${BOLD}Production-Ready Means:${RESET}"
    echo "  • Logs are structured and meaningful"
    echo "  • Errors are caught and reported"
    echo "  • Health checks and metrics are exposed"
    echo "  • Configuration is externalized"
    echo "  • Secrets are managed securely"
    echo "  • Resource limits are set"
    echo "  • Deployment and rollback are documented"

    echo -e "\n${CYAN}${BOLD}═══════════════════════════════════════════════════════════════════${RESET}"
    echo -e "${CYAN}Complete production readiness review, then press ${BOLD}ENTER${RESET}${CYAN} to finish...${RESET}"
    echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════════════════${RESET}"
    read -r

    local phase_end
    phase_end=$(date +%s)
    local duration=$((phase_end - phase_start))
    PHASE_TIMES+=("$duration")

    print_success "Phase 5 completed in $(format_time $duration)"
    save_state
}

#------------------------------------------------------------------------------
# Quick Reference Generation
#------------------------------------------------------------------------------

generate_quick_reference() {
    local ext
    ext=$(get_language_extension)
    local quick_ref="$LEARNING_DIR/quick-reference.md"

    print_header "Generating Quick Reference"

    cat > "$quick_ref" <<EOF
# ${LANGUAGE} Quick Reference

> Generated from 5-phase learning protocol on $(date +"%Y-%m-%d")

## Learning Summary

**Total Learning Time**: $(format_time $(($(date +%s) - START_TIME)))

**Phase Breakdown**:
EOF

    for i in {0..4}; do
        local phase_num=$((i + 1))
        local phase_name="${PHASE_NAMES[$i]}"
        local duration="${PHASE_TIMES[$i]:-0}"
        echo "- Phase $phase_num ($phase_name): $(format_time $duration)" >> "$quick_ref"
    done

    cat >> "$quick_ref" <<EOF

## Setup

\`\`\`bash
# Install
[See phase3-ecosystem/ecosystem.md]

# Create project
[See phase3-ecosystem/ecosystem.md]

# Run
[See phase1-exploration/hello.${ext}]

# Test
[See phase3-ecosystem/ecosystem.md]
\`\`\`

## Basic Syntax

\`\`\`${ext}
// See phase1-exploration/hello.${ext} for examples

// Variables
[Fill in from exploration phase]

// Functions
[Fill in from exploration phase]

// Control flow
[Fill in from exploration phase]

// Error handling
[Fill in from exploration phase]
\`\`\`

## Common Patterns

See [phase2-patterns/comparison.md](phase2-patterns/comparison.md) for detailed pattern mappings.

| Python | JavaScript | ${LANGUAGE} |
|--------|-----------|-------------|
| \`for x in list:\` | \`list.forEach()\` | ??? |
| \`try/except\` | \`try/catch\` | ??? |
| \`None\` | \`null/undefined\` | ??? |

## Ecosystem

- **Package Manager**: [See phase3-ecosystem/ecosystem.md]
- **Testing**: [See phase3-ecosystem/ecosystem.md]
- **Linting**: [See phase3-ecosystem/ecosystem.md]
- **Formatting**: [See phase3-ecosystem/ecosystem.md]

## Idioms

See [phase4-idioms/conventions.md](phase4-idioms/conventions.md) for detailed idioms and anti-patterns.

**Key Idioms**:
- [Fill in from idioms phase]
- [Fill in from idioms phase]
- [Fill in from idioms phase]

**Anti-Patterns to Avoid**:
- ❌ [Fill in from idioms phase]
- ❌ [Fill in from idioms phase]
- ❌ [Fill in from idioms phase]

## Production

See [phase5-production/production.md](phase5-production/production.md) for deployment and monitoring.

**Deployment**:
- Build: ???
- Deploy: ???
- Monitor: ???

**Security Checklist**:
- [ ] Input validation
- [ ] SQL injection prevention
- [ ] XSS prevention
- [ ] Secrets not hardcoded
- [ ] Dependencies scanned

## Resources

- Official Docs: ???
- Style Guide: ???
- Community: ???
- Package Registry: ???

## Comparison to Known Languages

### Similar to...

- **Python**: [Similarities]
- **JavaScript**: [Similarities]
- **Go**: [Similarities]

### Different because...

- **Unique Feature 1**: [Explanation]
- **Unique Feature 2**: [Explanation]
- **Unique Feature 3**: [Explanation]

## Next Steps

- [ ] Build a small CLI tool
- [ ] Implement a REST API
- [ ] Write comprehensive tests
- [ ] Deploy to production
- [ ] Read 2-3 popular open source projects
- [ ] Contribute to an open source project

## Confidence Level

Self-assessed confidence: **[beginner/intermediate/proficient]**

**Ready for**:
- [ ] Small features in existing projects
- [ ] New projects from scratch
- [ ] Code reviews
- [ ] Teaching others

**Need more practice with**:
- [Area 1]
- [Area 2]
- [Area 3]
EOF

    print_success "Generated quick reference: $quick_ref"

    # Generate comparison notes
    local comparison_file="$LEARNING_DIR/comparison-notes.md"
    cat > "$comparison_file" <<EOF
# ${LANGUAGE} vs Other Languages

## vs Python

**Similarities**:
- [Fill in]

**Differences**:
- [Fill in]

**When to use ${LANGUAGE} instead of Python**:
- [Fill in]

**When to use Python instead of ${LANGUAGE}**:
- [Fill in]

## vs JavaScript

**Similarities**:
- [Fill in]

**Differences**:
- [Fill in]

**When to use ${LANGUAGE} instead of JavaScript**:
- [Fill in]

**When to use JavaScript instead of ${LANGUAGE}**:
- [Fill in]

## vs Go

**Similarities**:
- [Fill in]

**Differences**:
- [Fill in]

**When to use ${LANGUAGE} instead of Go**:
- [Fill in]

**When to use Go instead of ${LANGUAGE}**:
- [Fill in]

## Paradigm Analysis

**${LANGUAGE} paradigm**: [OOP/FP/Procedural/Multi/Declarative]

**Best suited for**:
- [Use case 1]
- [Use case 2]
- [Use case 3]

**Not ideal for**:
- [Use case 1]
- [Use case 2]
- [Use case 3]

## Performance Characteristics

- **Startup time**: ???
- **Memory footprint**: ???
- **CPU efficiency**: ???
- **Concurrency model**: ???
- **Best performance profile**: ???

## Ecosystem Maturity

- **Package ecosystem**: [Excellent/Good/Growing/Limited]
- **Community size**: [Large/Medium/Small/Niche]
- **Corporate backing**: [Yes/No - Company name]
- **Stability**: [Mature/Stable/Evolving/Experimental]
- **Breaking changes**: [Rare/Occasional/Frequent]
EOF

    print_success "Generated comparison notes: $comparison_file"
}

#------------------------------------------------------------------------------
# Summary Report
#------------------------------------------------------------------------------

print_summary() {
    local total_time=$(($(date +%s) - START_TIME))

    print_header "Learning Complete! 🎉"

    echo -e "${BOLD}Language:${RESET} ${GREEN}${LANGUAGE}${RESET}"
    echo -e "${BOLD}Total Time:${RESET} ${GREEN}$(format_time $total_time)${RESET}"
    echo ""

    echo -e "${BOLD}Phase Breakdown:${RESET}"
    for i in {0..4}; do
        local phase_num=$((i + 1))
        local phase_name="${PHASE_NAMES[$i]}"
        local expected="${PHASE_DURATIONS[$i]}"
        local actual_seconds="${PHASE_TIMES[$i]:-0}"
        local actual_minutes=$((actual_seconds / 60))

        echo -e "  ${CYAN}Phase $phase_num${RESET} ($phase_name):"
        echo -e "    Expected: ~${expected} min"
        echo -e "    Actual:   ${actual_minutes} min ($(format_time $actual_seconds))"
    done

    echo ""
    echo -e "${BOLD}Generated Files:${RESET}"
    echo -e "  ${GREEN}✓${RESET} $LEARNING_DIR/quick-reference.md"
    echo -e "  ${GREEN}✓${RESET} $LEARNING_DIR/comparison-notes.md"
    echo -e "  ${GREEN}✓${RESET} Phase-specific files in subdirectories"

    echo ""
    echo -e "${BOLD}Next Steps:${RESET}"
    echo -e "  1. Review and complete the quick reference"
    echo -e "  2. Build a small project to solidify learning"
    echo -e "  3. Read 2-3 popular open source projects in ${LANGUAGE}"
    echo -e "  4. Implement a real feature or tool"
    echo ""

    echo -e "${BOLD}Learning Directory:${RESET} ${BLUE}$LEARNING_DIR${RESET}"
    echo ""

    print_success "You're now ready to develop in ${LANGUAGE}!"
    echo ""
    echo -e "${YELLOW}Remember: Languages are tools, paradigms are skills.${RESET}"
    echo -e "${YELLOW}Transfer patterns, don't start from scratch.${RESET}"
}

#------------------------------------------------------------------------------
# Main Script
#------------------------------------------------------------------------------

usage() {
    cat <<EOF
Usage: $0 <language> [--resume]

Learn a new programming language using the 5-phase rapid learning protocol.

Arguments:
  language        Name of the language to learn (e.g., rust, go, python)

Options:
  --resume        Resume from the last saved phase

Examples:
  $0 rust
  $0 go --resume
  $0 python

Phases:
  1. EXPLORATION (30 min) - Hello World, basic syntax
  2. PATTERNS (60 min) - Map to known language patterns
  3. ECOSYSTEM (30 min) - Tooling, package manager, testing
  4. IDIOMS (60 min) - Community conventions, anti-patterns
  5. PRODUCTION (60 min) - Deployment, monitoring, security

Total time: ~4 hours to productive development
EOF
    exit 1
}

main() {
    # Parse arguments
    if [ $# -lt 1 ]; then
        usage
    fi

    LANGUAGE="$1"
    local resume_mode=false

    if [ "${2:-}" = "--resume" ]; then
        resume_mode=true
    fi

    # Set up paths
    LEARNING_DIR="learn-${LANGUAGE}"
    STATE_FILE="$LEARNING_DIR/.learning-state"

    # Welcome message
    print_header "10X Language Learning Protocol"
    echo -e "${BOLD}Language:${RESET} ${GREEN}${LANGUAGE}${RESET}"
    echo -e "${BOLD}Mode:${RESET} $([ "$resume_mode" = true ] && echo "Resume" || echo "New")"
    echo ""

    # Resume or start fresh
    if [ "$resume_mode" = true ]; then
        if load_state; then
            print_success "Resumed from Phase $CURRENT_PHASE"
        else
            print_warning "No saved state found, starting fresh"
            resume_mode=false
        fi
    fi

    # Start fresh if not resuming
    if [ "$resume_mode" = false ]; then
        START_TIME=$(date +%s)
        CURRENT_PHASE=1
        PHASE_TIMES=()
        setup_learning_directory
    fi

    # Execute phases
    case $CURRENT_PHASE in
        1)
            phase1_exploration
            CURRENT_PHASE=2
            ;&
        2)
            phase2_patterns
            CURRENT_PHASE=3
            ;&
        3)
            phase3_ecosystem
            CURRENT_PHASE=4
            ;&
        4)
            phase4_idioms
            CURRENT_PHASE=5
            ;&
        5)
            phase5_production
            ;;
    esac

    # Generate final artifacts
    generate_quick_reference

    # Print summary
    print_summary

    # Clean up state file
    rm -f "$STATE_FILE"
}

# Run main function
main "$@"
