# Learning Templates and Checklists

Ready-to-use templates and checklists for rapid language acquisition.

---

## Quick Reference Template

Use this template when learning a new language. Fill it in during Phases 1-4.

```markdown
# [Language Name] Quick Reference

## Overview
- **Paradigm**: [OOP/FP/Procedural/Multi/Declarative]
- **Type System**: [Static/Dynamic, Strong/Weak]
- **Memory Management**: [GC/Manual/Ownership/ARC]
- **Compilation**: [Compiled/Interpreted/JIT]
- **Primary Use Cases**: [Web/Systems/Data/Mobile/etc]

## Setup

### Installation
```bash
# macOS
[brew/package manager command]

# Linux
[apt/yum/package manager command]

# Windows
[chocolatey/scoop/installer]

# Version manager (if applicable)
[asdf/nvm/rustup/etc command]
```

### Create New Project
```bash
[cargo new/go mod init/npm init/django-admin startproject]

cd project-name
```

### Project Structure
```
project/
├── src/           # [description]
├── tests/         # [description]
├── config/        # [description]
└── [other dirs]
```

### Build and Run
```bash
# Build (if compiled)
[cargo build/go build/javac]

# Run
[cargo run/go run/python/node]

# Development mode
[cargo run/npm run dev/python manage.py runserver]
```

### Test
```bash
# Run all tests
[cargo test/go test ./.../pytest/npm test]

# Run specific test
[specific test command]

# Coverage
[coverage command]
```

---

## Basics

### Hello World
```[language]
[complete hello world program]
```

### Variables and Constants
```[language]
// Immutable
[let/const/val declaration]

// Mutable
[let mut/var/let declaration]

// Constants
[const/final declaration]

// Type inference
[inferred type example]

// Explicit types
[explicit type example]
```

### Data Types
```[language]
// Primitives
[int/float/bool/string examples]

// Collections
[array/list example]
[map/dict/hash example]
[set example]

// Custom types
[struct/class/record example]
```

### Functions
```[language]
// Basic function
[function definition]

// With parameters
[function with params]

// With return value
[function with return]

// Multiple return values (if supported)
[multiple return example]

// Higher-order functions
[function as parameter]
[function returning function]
```

### Control Flow
```[language]
// If/else
[if statement]

// Switch/match
[switch or pattern match]

// For loop
[for loop over range]
[for loop over collection]

// While loop
[while loop]

// Break/continue
[break/continue examples]
```

### Error Handling
```[language]
// Basic error handling
[try/catch or Result or error return]

// Custom errors
[custom error type]

// Error propagation
[? operator or throw or return err]

// Recovering from errors
[recovery mechanism]
```

### Null/None Handling
```[language]
// Null/None/nil representation
[null equivalent]

// Checking for null
[null check pattern]

// Optional/Maybe type (if applicable)
[Optional<T> or Maybe or similar]

// Default values
[default value pattern]
```

---

## Common Patterns

### Iteration
```[language]
// Map
[transform collection elements]

// Filter
[select elements matching condition]

// Reduce/Fold
[aggregate collection to single value]

// Find
[find first matching element]

// All/Any
[check if all/any match condition]
```

### String Operations
```[language]
// Concatenation
[string concat]

// Interpolation
[string interpolation]

// Split/Join
[split string, join array]

// Substring
[substring extraction]

// Case conversion
[uppercase/lowercase]
```

### File I/O
```[language]
// Read file
[read entire file]
[read line by line]

// Write file
[write to file]

// Append to file
[append to file]

// File exists check
[check file existence]
```

### JSON Handling
```[language]
// Parse JSON
[deserialize JSON]

// Generate JSON
[serialize to JSON]

// Access nested values
[navigate JSON structure]
```

### HTTP Requests
```[language]
// GET request
[HTTP GET example]

// POST request
[HTTP POST example]

// With headers
[add headers to request]

// Error handling
[handle HTTP errors]
```

### Async Operations
```[language]
// Define async function
[async function definition]

// Await result
[await syntax]

// Parallel execution
[run multiple async operations in parallel]

// Timeout
[set timeout for operation]
```

---

## Object-Oriented Patterns (if applicable)

### Classes
```[language]
// Class definition
[basic class]

// Constructor
[constructor/init method]

// Methods
[instance method]
[static/class method]

// Properties
[property definition]
[computed property]

// Inheritance
[extend/implement]

// Interfaces/Protocols
[interface definition]
[implementing interface]
```

---

## Functional Patterns (if applicable)

### Higher-Order Functions
```[language]
// Map
[map example]

// Filter
[filter example]

// Reduce
[reduce example]

// Compose
[function composition]
```

### Immutability
```[language]
// Immutable data structures
[immutable collection]

// Update without mutation
[update pattern]
```

---

## Ecosystem

### Package Manager
- **Tool**: [cargo/npm/pip/go mod]
- **Config**: [Cargo.toml/package.json/requirements.txt]
- **Lock File**: [Cargo.lock/package-lock.json/poetry.lock]

```bash
# Add dependency
[add command]

# Install dependencies
[install command]

# Update dependencies
[update command]

# Remove dependency
[remove command]

# List dependencies
[list command]
```

### Testing Framework
- **Framework**: [pytest/jest/go test/cargo test]
- **Test File Convention**: [test_*.py/*_test.go/*.test.js]

```[language]
// Basic test
[test function/method]

// Assertions
[assert/expect syntax]

// Setup/Teardown
[before/after hooks]

// Mocking
[mock example]
```

### Linting
- **Tool**: [clippy/eslint/pylint/golint]

```bash
# Run linter
[lint command]

# Fix auto-fixable issues
[fix command]
```

### Formatting
- **Tool**: [rustfmt/prettier/black/gofmt]

```bash
# Format files
[format command]

# Check formatting
[check command]
```

### Documentation
- **Tool**: [rustdoc/JSDoc/Sphinx/godoc]
- **Official Docs**: [URL]
- **Standard Library Docs**: [URL]

```[language]
// Document function
[doc comment example]

// Generate docs
[doc generation command]
```

### IDE/Editor Support
- **LSP Server**: [rust-analyzer/gopls/pyright]
- **Popular Extensions**: [list]

---

## Idioms and Best Practices

### Naming Conventions
- **Variables**: [snake_case/camelCase]
- **Functions**: [snake_case/camelCase]
- **Types/Classes**: [PascalCase/snake_case]
- **Constants**: [SCREAMING_SNAKE_CASE/UPPER_CASE]
- **Files**: [snake_case/kebab-case]

### Code Organization
```
[Language-specific project organization patterns]
```

### Common Idioms
1. **[Idiom 1]**: [Explanation and example]
2. **[Idiom 2]**: [Explanation and example]
3. **[Idiom 3]**: [Explanation and example]

### Performance Tips
1. **[Tip 1]**: [Explanation]
2. **[Tip 2]**: [Explanation]
3. **[Tip 3]**: [Explanation]

### Security Considerations
1. **[Consideration 1]**: [Explanation]
2. **[Consideration 2]**: [Explanation]
3. **[Consideration 3]**: [Explanation]

---

## Anti-Patterns

1. ❌ **[Anti-pattern 1]**: [Why it's bad and what to do instead]
2. ❌ **[Anti-pattern 2]**: [Why it's bad and what to do instead]
3. ❌ **[Anti-pattern 3]**: [Why it's bad and what to do instead]
4. ❌ **[Anti-pattern 4]**: [Why it's bad and what to do instead]
5. ❌ **[Anti-pattern 5]**: [Why it's bad and what to do instead]

---

## Resources

### Official Resources
- **Official Website**: [URL]
- **Documentation**: [URL]
- **Tutorial**: [URL]
- **API Reference**: [URL]
- **Style Guide**: [URL]

### Community Resources
- **Forum/Discord**: [URL]
- **Stack Overflow Tag**: [tag]
- **Reddit**: [r/subreddit]
- **Awesome List**: [awesome-language URL]

### Learning Resources
- **Book**: [Recommended book]
- **Interactive Tutorial**: [URL]
- **Video Course**: [URL]
- **Exercises**: [URL]

### Popular Libraries/Frameworks
- **[Category 1]**: [library names]
- **[Category 2]**: [library names]
- **[Category 3]**: [library names]

---

## Notes and Gotchas

### [Note 1]
[Description of surprising behavior or important concept]

### [Note 2]
[Description of surprising behavior or important concept]

### [Note 3]
[Description of surprising behavior or important concept]

---

## Progress Checklist

Phase 1 (30 min):
- [ ] Toolchain installed
- [ ] Hello World runs
- [ ] Basic syntax understood
- [ ] IDE/editor configured

Phase 2 (1-2 hours):
- [ ] Pattern comparison table filled
- [ ] Common patterns identified
- [ ] Equivalent patterns mapped

Phase 3 (1 hour):
- [ ] Package manager configured
- [ ] Testing framework working
- [ ] Linter and formatter set up
- [ ] Documentation bookmarked

Phase 4 (2-3 hours):
- [ ] Style guide read
- [ ] 3+ popular projects reviewed
- [ ] Idioms documented
- [ ] Anti-patterns noted

Phase 5 (Ongoing):
- [ ] Logging configured
- [ ] Error handling comprehensive
- [ ] Deployment process understood
- [ ] First feature shipped
```

---

## Setup Script Template

Create this script for each new language to automate environment setup:

```bash
#!/bin/bash
# setup-[language].sh - Automated environment setup

set -e

LANGUAGE="[Language Name]"
echo "🚀 Setting up $LANGUAGE development environment..."

# 1. Install toolchain
echo "📦 Installing toolchain..."
[installation commands]

# Verify installation
if ! command -v [tool] &> /dev/null; then
    echo "❌ Installation failed"
    exit 1
fi

echo "✅ Toolchain installed: $(tool --version)"

# 2. Create sample project
echo "📁 Creating sample project..."
mkdir -p ~/learning-$LANGUAGE
cd ~/learning-$LANGUAGE

[project init command]

# 3. Create Hello World
echo "📝 Creating Hello World..."
cat > [main file] << 'EOF'
[Hello World code]
EOF

# 4. Build and run
echo "🔨 Building and running..."
[build command]
[run command]

# 5. Install development tools
echo "🔧 Installing development tools..."
[linter install]
[formatter install]
[test framework install if needed]

# 6. Configure IDE/Editor
echo "⚙️  Configuring IDE support..."
[LSP server install if needed]

# 7. Create test file
echo "🧪 Creating test file..."
cat > [test file] << 'EOF'
[basic test code]
EOF

# 8. Run tests
echo "🧪 Running tests..."
[test command]

# 9. Create .gitignore
echo "📋 Creating .gitignore..."
cat > .gitignore << 'EOF'
[language-specific gitignore entries]
EOF

# 10. Create cheat sheet
echo "📖 Creating quick reference..."
cat > QUICK_REFERENCE.md << 'EOF'
[Quick reference template content]
EOF

# Done!
echo ""
echo "✅ $LANGUAGE environment ready!"
echo ""
echo "Next steps:"
echo "  cd ~/learning-$LANGUAGE"
echo "  [command to run project]"
echo "  [command to run tests]"
echo "  [command to open docs]"
echo ""
echo "Quick reference: ~/learning-$LANGUAGE/QUICK_REFERENCE.md"
```

---

## Phase Completion Checklists

### Phase 1: Exploration Checklist

```yaml
setup:
  - [ ] Install toolchain (rustup, go install, npm, pip, etc.)
  - [ ] Verify installation (--version command works)
  - [ ] Create new project (cargo new, go mod init, npm init)
  - [ ] Understand project structure (where files go)
  - [ ] IDE/editor autocomplete working

first_program:
  - [ ] Print "Hello World" to console
  - [ ] Declare immutable variable
  - [ ] Declare mutable variable
  - [ ] Define function with parameters
  - [ ] Call function and see output
  - [ ] Use if/else statement
  - [ ] Use for loop
  - [ ] Handle an error (try/catch or equivalent)

observations:
  - [ ] Types: explicit, inferred, or both?
  - [ ] Functions: what's the syntax?
  - [ ] Errors: exceptions or return values?
  - [ ] Compilation: compiled, interpreted, JIT?
  - [ ] Surprising behaviors noted
```

### Phase 2: Patterns Checklist

```yaml
pattern_mapping:
  - [ ] How do I iterate over a collection?
  - [ ] How do I transform a collection (map)?
  - [ ] How do I filter a collection?
  - [ ] How do I reduce/aggregate a collection?
  - [ ] How do I handle missing values (null/nil/None)?
  - [ ] How do I handle errors?
  - [ ] How do I perform async operations?
  - [ ] What collections exist (array, dict, set)?
  - [ ] How do I define custom types?
  - [ ] How do I read/write files?
  - [ ] How do I make HTTP requests?
  - [ ] How do I parse JSON?

comparison_table:
  - [ ] Filled in variables row
  - [ ] Filled in functions row
  - [ ] Filled in error handling row
  - [ ] Filled in null safety row
  - [ ] Filled in iteration row
  - [ ] Filled in collections row
  - [ ] Filled in testing row
  - [ ] Filled in package manager row

equivalents_identified:
  - [ ] Mapped 10+ patterns to known languages
  - [ ] Identified unique concepts (if any)
  - [ ] Noted surprising differences
```

### Phase 3: Ecosystem Checklist

```yaml
package_manager:
  - [ ] Know how to add dependency
  - [ ] Know how to install dependencies
  - [ ] Know how to update dependencies
  - [ ] Know where config file is
  - [ ] Know where lock file is
  - [ ] Can search for packages

testing:
  - [ ] Testing framework identified
  - [ ] Can write basic test
  - [ ] Can run tests
  - [ ] Know assertion syntax
  - [ ] Can see test coverage
  - [ ] Know how to mock/stub

tooling:
  - [ ] Linter installed and configured
  - [ ] Formatter installed and configured
  - [ ] Know how to run linter
  - [ ] Know how to auto-format
  - [ ] IDE integration working

documentation:
  - [ ] Found official documentation
  - [ ] Found standard library reference
  - [ ] Bookmarked API docs
  - [ ] Found community forum/Discord
  - [ ] Found "awesome" list of libraries

project_setup:
  - [ ] Created sample project
  - [ ] Tests passing
  - [ ] Linter passing
  - [ ] Can build/run project
  - [ ] .gitignore configured
```

### Phase 4: Idioms Checklist

```yaml
style_guide:
  - [ ] Official style guide read
  - [ ] Naming conventions noted
  - [ ] Code organization patterns noted
  - [ ] Formatting conventions noted

standard_library:
  - [ ] Explored std lib docs
  - [ ] Identified common patterns
  - [ ] Noted how core team writes code

popular_projects:
  - [ ] Found 3-5 top projects on GitHub
  - [ ] Read code (not just docs)
  - [ ] Noted recurring patterns
  - [ ] Identified what feels idiomatic

idioms_captured:
  - [ ] Documented 5+ language-specific idioms
  - [ ] Examples written for each
  - [ ] Rationale understood

anti_patterns:
  - [ ] Documented 5+ anti-patterns
  - [ ] Why they're bad understood
  - [ ] Better alternatives identified
  - [ ] Common mistakes noted
```

### Phase 5: Production Checklist

```yaml
deployment:
  - [ ] Understand deployment model
  - [ ] Know how to build for production
  - [ ] Know how to run in production
  - [ ] Understand resource requirements
  - [ ] Know where to deploy (platform)

logging:
  - [ ] Logging library identified
  - [ ] Structured logging configured
  - [ ] Log levels understood
  - [ ] Can log to file and stdout

error_handling:
  - [ ] All errors handled gracefully
  - [ ] No uncaught exceptions
  - [ ] Errors logged appropriately
  - [ ] Error context preserved

monitoring:
  - [ ] Health check endpoint created
  - [ ] Metrics exposed (if applicable)
  - [ ] Know how to profile performance
  - [ ] Resource usage can be monitored

configuration:
  - [ ] Config externalized (env vars or file)
  - [ ] Secrets not hardcoded
  - [ ] Different envs supported (dev/prod)

reliability:
  - [ ] Graceful shutdown implemented
  - [ ] Resource limits set
  - [ ] Timeouts configured
  - [ ] Retry logic where appropriate

deployment_docs:
  - [ ] How to build documented
  - [ ] How to deploy documented
  - [ ] How to rollback documented
  - [ ] Monitoring documented
```

---

## Learning Time Tracker

Track your progress toward the < 4 hour target:

```markdown
# [Language] Learning Log

## Time Tracking

| Phase | Start Time | End Time | Duration | Status |
|-------|------------|----------|----------|--------|
| 1: Exploration | [timestamp] | [timestamp] | [X min] | ✅ |
| 2: Patterns | [timestamp] | [timestamp] | [X min] | ✅ |
| 3: Ecosystem | [timestamp] | [timestamp] | [X min] | 🔄 |
| 4: Idioms | [timestamp] | [timestamp] | [X min] | ⏸️ |
| 5: Production | [timestamp] | [timestamp] | [X min] | ⏸️ |

**Total Time**: [X hours Y minutes]

## Milestones

- [ ] Hello World (target: 10 min)
- [ ] First test passes (target: 30 min)
- [ ] Pattern table complete (target: 90 min)
- [ ] Ecosystem ready (target: 180 min)
- [ ] First feature implemented (target: 240 min)

## Blockers

1. [Blocker description] - [Resolution]
2. [Blocker description] - [Resolution]

## Aha Moments

1. [Insight that clicked]
2. [Pattern recognition moment]
3. [Understanding unique concept]

## Confusion Points

1. [What was confusing] - [Current understanding]
2. [What was confusing] - [Current understanding]

## Next Steps

1. [What to learn next]
2. [What to practice]
3. [What to build]
```

---

## First Project Ideas

Start with these to solidify learning:

### Beginner Projects (Phase 1-2)
1. **CLI Calculator**: Basic arithmetic, input parsing, error handling
2. **TODO List**: CRUD operations, file I/O, data structures
3. **URL Shortener**: Hash functions, data persistence, HTTP basics
4. **Weather CLI**: API calls, JSON parsing, formatting output

### Intermediate Projects (Phase 3-4)
1. **REST API**: Web framework, routing, database, testing
2. **File Sync Tool**: File I/O, concurrency, error handling
3. **Chat Server**: WebSockets/networking, concurrency, state management
4. **Static Site Generator**: File processing, templating, build system

### Advanced Projects (Phase 5)
1. **Distributed Cache**: Networking, concurrency, performance
2. **Database**: Storage engine, query parser, transactions
3. **Container Runtime**: System calls, process management
4. **Game Engine**: Graphics, physics, event loop, optimization
