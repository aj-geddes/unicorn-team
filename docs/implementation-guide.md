# 10X Unicorn Implementation Guide

## Quick Start

### Step 1: Directory Structure

```bash
mkdir -p ~/.claude/{skills/unicorn,hooks,scripts}

# Create the structure
cat << 'STRUCTURE'
~/.claude/
├── CLAUDE.md                      # Lean orchestrator prompt
├── skills/
│   └── unicorn/
│       ├── orchestrator/
│       │   └── SKILL.md           # Task routing, delegation
│       ├── code-reading/
│       │   └── SKILL.md           # Codebase comprehension
│       ├── pattern-transfer/
│       │   └── SKILL.md           # Cross-domain patterns
│       ├── self-verification/
│       │   └── SKILL.md           # Pre-commit self-review
│       ├── estimation/
│       │   └── SKILL.md           # Task breakdown, risk
│       ├── technical-debt/
│       │   └── SKILL.md           # Debt tracking, paydown
│       └── language-learning/
│           └── SKILL.md           # Rapid paradigm acquisition
├── hooks/
│   ├── pre-commit                 # Quality gate hook
│   └── pre-push                   # Final verification
└── scripts/
    ├── tdd.sh                     # TDD workflow
    ├── self-review.sh             # Review checklist
    ├── new-language.sh            # Language learning
    └── estimate.sh                # Estimation helper
STRUCTURE
```

### Step 2: Core Files

#### CLAUDE.md (Lean Orchestrator)

```bash
cat > ~/.claude/CLAUDE.md << 'EOF'
# 10X Developer Unicorn

You are an orchestrating agent that delegates to specialized skills and subagents.

## Core Principles
- **TDD Always**: Tests define behavior before implementation
- **Self-Review**: Check your own work before submission  
- **Pattern Recognition**: Find the underlying problem class
- **Context Efficiency**: Delegate to preserve context budget

## Workflow
1. Analyze task complexity and route appropriately
2. For implementation: invoke developer subagent
3. For design: invoke architect skills
4. For debugging: invoke root-cause-debugger
5. Before any commit: run self-verification

## Skills (load on demand)
- `~/.claude/skills/unicorn/*/SKILL.md`
- `~/.claude/skills/domain/*/SKILL.md` 

## Quality Gates
- All tests pass
- Coverage ≥ 80%
- Self-review complete
- No TODO/FIXME/HACK

## Subagent Invocation Pattern
When delegating, provide:
1. Clear task description
2. Relevant context only
3. Expected output format
4. Quality constraints
EOF
```

### Step 3: Key Skills

#### Orchestrator Skill

```bash
mkdir -p ~/.claude/skills/unicorn/orchestrator
cat > ~/.claude/skills/unicorn/orchestrator/SKILL.md << 'EOF'
---
name: unicorn-orchestrator
description: >
  Routes tasks to appropriate skills/subagents. Use for any complex task
  requiring multiple capabilities. Analyzes complexity, delegates work,
  aggregates results, enforces quality gates.
---

# Task Orchestration

## Routing Decision Tree

```
Task arrives
│
├─ Is this a simple question? → Answer directly
├─ Is this code implementation?
│   ├─ New feature → TDD workflow → developer subagent
│   ├─ Bug fix → root-cause-debugger → developer
│   └─ Refactor → characterization tests first → developer
├─ Is this design/architecture? → architect skills
├─ Is this deployment/infra? → devops skills
├─ Is this a new language/framework? → language-learning skill
└─ Is this complex (multi-domain)?
    └─ Break down → parallel delegation → aggregate
```

## Delegation Template

```yaml
delegation:
  to: [subagent/skill name]
  task: |
    [Clear description of what to do]
  context:
    - [Only relevant information]
    - [No extra noise]
  constraints:
    - [Quality requirements]
    - [Time bounds if any]
  expected_output:
    - [What should come back]
```

## Quality Gate Checklist

Before returning any code:
- [ ] Tests written and passing
- [ ] Coverage meets threshold
- [ ] Self-review completed
- [ ] No technical debt markers
- [ ] Documentation updated
EOF
```

#### Self-Verification Skill

```bash
mkdir -p ~/.claude/skills/unicorn/self-verification
cat > ~/.claude/skills/unicorn/self-verification/SKILL.md << 'EOF'
---
name: self-verification
description: >
  Pre-commit self-review protocol. Run before ANY code submission.
  Catches issues before they reach review. Enforces quality standards.
---

# Self-Verification Protocol

## Before Every Commit

### 1. Diff Review
```bash
git diff --staged
```
Read as if someone else wrote it. Would you approve this PR?

### 2. Completeness Check
- [ ] Feature works as intended (manually verified)
- [ ] Edge cases handled
- [ ] Error cases handled gracefully
- [ ] Logging adequate for debugging
- [ ] No hardcoded values that should be config

### 3. Quality Check
- [ ] No TODO/FIXME/HACK comments
- [ ] No debug code (print, console.log, breakpoint)
- [ ] No commented-out code
- [ ] Names are clear and meaningful
- [ ] Functions are focused (<50 lines)

### 4. Test Verification
```bash
pytest --cov=. --cov-fail-under=80 -v
```
- [ ] All tests pass
- [ ] Coverage meets threshold
- [ ] Edge cases tested
- [ ] Error paths tested

### 5. Security Check
- [ ] No secrets in code
- [ ] Inputs validated
- [ ] Outputs encoded
- [ ] SQL parameterized

### 6. Documentation Check
- [ ] Public APIs documented
- [ ] Complex logic explained
- [ ] README updated if needed

## The "Fresh Eyes" Test

1. Wait 5+ minutes before review
2. Read code from bottom to top
3. Explain each function aloud
4. Ask: "What would break this?"
EOF
```

#### Code Reading Skill

```bash
mkdir -p ~/.claude/skills/unicorn/code-reading
cat > ~/.claude/skills/unicorn/code-reading/SKILL.md << 'EOF'
---
name: code-reading
description: >
  Strategic codebase comprehension. Use when exploring unfamiliar code,
  understanding legacy systems, or before making changes. Finds entry
  points, traces data flow, identifies patterns.
---

# Code Reading Protocol

## Strategic Reading (Not Linear)

### Step 1: Entry Points
Find where execution begins:
- `main()`, `if __name__ == '__main__'`
- Route handlers (Flask, FastAPI, Express)
- Event handlers, message consumers
- CLI entry points

### Step 2: Data Flow
Trace how data moves:
```
Input → Validation → Processing → Storage → Output
```
- Where does data enter?
- How is it validated?
- Where is it transformed?
- Where does it persist?
- How does it exit?

### Step 3: Error Paths
Find failure modes:
- Exception handlers
- Error responses
- Logging statements
- Retry logic

### Step 4: Integration Points
Find boundaries:
- External API calls
- Database queries
- Message queue interactions
- File system access

## Comprehension Levels

| Level | Question | Understanding |
|-------|----------|---------------|
| L1 | What does it DO? | Behavior |
| L2 | HOW does it work? | Mechanics |
| L3 | WHY this way? | Design decisions |
| L4 | What ELSE affected? | Impact radius |

## Legacy Code Protocol

Before modifying legacy code:
1. **Run existing tests** - Do they pass?
2. **Add characterization tests** - Capture current behavior
3. **Map dependencies** - What uses this?
4. **Find the seams** - Safe places to change
5. **Identify load-bearing walls** - Don't touch first
EOF
```

#### Pattern Transfer Skill

```bash
mkdir -p ~/.claude/skills/unicorn/pattern-transfer
cat > ~/.claude/skills/unicorn/pattern-transfer/SKILL.md << 'EOF'
---
name: pattern-transfer
description: >
  Cross-domain pattern recognition and transfer. Use when encountering
  problems that seem familiar, when learning new paradigms, or when
  seeking elegant solutions. Maps concepts across languages/domains.
---

# Pattern Transfer Protocol

## Pattern Recognition

When encountering a problem:
1. What problem CLASS is this?
2. Where have I seen this before?
3. What's the canonical solution?
4. How does it translate here?

## Common Problem Classes

### State Management
Manifestations:
- Redux/Vuex/MobX (frontend)
- Database transactions (backend)
- React useState/useReducer
- Actor model (Erlang/Elixir)
- Event sourcing

Core: Single source of truth, predictable updates

### Async Coordination
Manifestations:
- Promises/async-await (JS)
- asyncio (Python)
- goroutines/channels (Go)
- Actors (Akka, Elixir)
- Futures (Rust)

Core: Non-blocking, result handling, error propagation

### Caching
Manifestations:
- Memoization (functions)
- Redis/Memcached (distributed)
- HTTP caching (headers)
- React.memo/useMemo
- Query caching (React Query)

Core: Expensive computation → store result → reuse

### Rate Limiting
Manifestations:
- Token bucket
- Leaky bucket
- Sliding window
- Circuit breaker

Core: Protect resources from overload

### Retry/Resilience
Manifestations:
- Exponential backoff
- Circuit breaker
- Bulkhead
- Fallback

Core: Handle transient failures gracefully

## Transfer Protocol

```
Familiar Pattern + New Domain = Adapted Solution

1. Extract ESSENCE (what's the core idea?)
2. Find IDIOMS (how is it done here?)
3. REIFY (implement using local conventions)
```
EOF
```

### Step 4: Hooks

#### Pre-commit Hook

```bash
cat > ~/.claude/hooks/pre-commit << 'HOOK'
#!/bin/bash
set -euo pipefail

echo "🔍 Pre-commit verification..."

# Detect project type
if [[ -f "pyproject.toml" ]] || [[ -f "requirements.txt" ]]; then
    LANG="python"
elif [[ -f "package.json" ]]; then
    LANG="javascript"
elif [[ -f "go.mod" ]]; then
    LANG="go"
elif [[ -f "Cargo.toml" ]]; then
    LANG="rust"
else
    LANG="unknown"
fi

# Run language-specific checks
case $LANG in
    python)
        echo "  🐍 Python project detected"
        ruff check . || exit 1
        ruff format --check . || exit 1
        mypy . --ignore-missing-imports || true
        pytest --cov=. --cov-fail-under=80 -q || exit 1
        bandit -r . -q || exit 1
        ;;
    javascript)
        echo "  📦 JavaScript project detected"
        npm run lint || exit 1
        npm run type-check || true
        npm test || exit 1
        ;;
    go)
        echo "  🐹 Go project detected"
        go fmt ./... || exit 1
        go vet ./... || exit 1
        go test ./... -cover || exit 1
        ;;
    rust)
        echo "  🦀 Rust project detected"
        cargo fmt --check || exit 1
        cargo clippy || exit 1
        cargo test || exit 1
        ;;
esac

# Universal checks
echo "  🔒 Checking for secrets..."
if grep -rE "(password|secret|api_key|token)\s*=\s*['\"][^'\"]+['\"]" --include="*.py" --include="*.js" --include="*.ts" . 2>/dev/null; then
    echo "❌ Possible secrets in code!"
    exit 1
fi

echo "  📝 Checking for debug code..."
if grep -rE "breakpoint\(\)|console\.log|print\(" --include="*.py" --include="*.js" --include="*.ts" . 2>/dev/null | grep -v "test"; then
    echo "⚠️ Debug code detected (review before commit)"
fi

echo "  🗑️ Checking for TODOs in staged files..."
if git diff --cached --name-only | xargs grep -l "TODO\|FIXME\|HACK" 2>/dev/null; then
    echo "⚠️ TODO/FIXME/HACK found - resolve or document"
fi

echo "✅ Pre-commit passed!"
HOOK
chmod +x ~/.claude/hooks/pre-commit
```

### Step 5: Scripts

#### TDD Workflow

```bash
cat > ~/.claude/scripts/tdd.sh << 'SCRIPT'
#!/bin/bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: tdd.sh <feature-name>"
    exit 1
fi

FEATURE="$1"
TEST_FILE="tests/test_${FEATURE}.py"

echo "🔴🟢🔵 TDD Cycle: $FEATURE"
echo "════════════════════════════════════"

# RED Phase
echo ""
echo "🔴 RED: Write Failing Test"
echo "  → Create $TEST_FILE"
echo "  → Write test describing expected behavior"
echo "  → Test MUST fail initially"
echo ""
read -p "Press Enter when test is written..."

if [[ ! -f "$TEST_FILE" ]]; then
    echo "❌ Test file not found: $TEST_FILE"
    exit 1
fi

echo "Running tests (expecting failure)..."
if pytest "$TEST_FILE" -v 2>/dev/null; then
    echo "⚠️ Tests passing - write a FAILING test first!"
    exit 1
fi
echo "✅ Test fails as expected"

# GREEN Phase
echo ""
echo "🟢 GREEN: Make It Pass"
echo "  → Implement MINIMUM code to pass"
echo "  → No optimization, no extras"
echo ""
read -p "Press Enter when implementation ready..."

echo "Running tests (expecting success)..."
if ! pytest "$TEST_FILE" -v; then
    echo "❌ Tests still failing - continue implementation"
    exit 1
fi
echo "✅ Tests pass!"

# REFACTOR Phase
echo ""
echo "🔵 REFACTOR: Improve Quality"
echo "  → Clean up code"
echo "  → Remove duplication"
echo "  → Improve names"
echo "  → Tests must pass after EACH change"
echo ""
read -p "Press Enter when refactoring complete..."

echo "Final verification..."
pytest "$TEST_FILE" -v --cov=. --cov-report=term-missing

echo ""
echo "════════════════════════════════════"
echo "✅ TDD Cycle Complete for $FEATURE"
SCRIPT
chmod +x ~/.claude/scripts/tdd.sh
```

#### Estimation Helper

```bash
cat > ~/.claude/scripts/estimate.sh << 'SCRIPT'
#!/bin/bash

echo "📊 Task Estimation Helper"
echo "═══════════════════════════════════"

read -p "Task description: " TASK

echo ""
echo "📋 Breaking down: $TASK"
echo ""
echo "List subtasks (empty line to finish):"

SUBTASKS=()
while true; do
    read -p "  → " SUBTASK
    [[ -z "$SUBTASK" ]] && break
    SUBTASKS+=("$SUBTASK")
done

echo ""
echo "⚠️ Identify unknowns/risks (empty line to finish):"

RISKS=()
while true; do
    read -p "  ? " RISK
    [[ -z "$RISK" ]] && break
    RISKS+=("$RISK")
done

echo ""
echo "⏱️ Time estimates (hours):"
read -p "  Optimistic (everything goes right): " OPT
read -p "  Realistic (normal hiccups): " REAL
read -p "  Pessimistic (Murphy's Law): " PESS

# PERT calculation
PERT=$(echo "scale=1; ($OPT + 4*$REAL + $PESS) / 6" | bc)
BUFFER=$(echo "scale=1; ${#RISKS[@]} * 0.5" | bc)
TOTAL=$(echo "scale=1; $PERT + $BUFFER" | bc)

echo ""
echo "═══════════════════════════════════"
echo "📊 ESTIMATE SUMMARY"
echo "═══════════════════════════════════"
echo ""
echo "Task: $TASK"
echo ""
echo "Subtasks: ${#SUBTASKS[@]}"
for s in "${SUBTASKS[@]}"; do
    echo "  • $s"
done
echo ""
echo "Risks: ${#RISKS[@]}"
for r in "${RISKS[@]}"; do
    echo "  ⚠️ $r"
done
echo ""
echo "Time Estimates:"
echo "  Optimistic:  ${OPT}h"
echo "  Realistic:   ${REAL}h"
echo "  Pessimistic: ${PESS}h"
echo ""
echo "PERT Estimate: ${PERT}h"
echo "Risk Buffer:   ${BUFFER}h (${#RISKS[@]} risks × 0.5h)"
echo ""
echo "═══════════════════════════════════"
echo "📌 RECOMMENDED ESTIMATE: ${TOTAL} hours"
echo "═══════════════════════════════════"
SCRIPT
chmod +x ~/.claude/scripts/estimate.sh
```

---

## Integration with Claude Code

### Subagent Configuration

```yaml
# Example subagent definition for Claude Code
---
name: developer
description: >
  Full-stack implementation with TDD discipline. Handles Python, JS/TS,
  Go, Rust. Always writes tests first. Uses root-cause-debugger for bugs.
model: opus
tools: Bash, Read, Write, Edit, WebSearch
skills:
  - ~/.claude/skills/unicorn/self-verification
  - ~/.claude/skills/unicorn/code-reading
  - ~/.claude/skills/domain/python
  - ~/.claude/skills/domain/testing
---

## TDD Protocol

For EVERY implementation task:

1. **RED**: Write failing test first
   - Test describes expected behavior
   - Test MUST fail before implementation
   
2. **GREEN**: Minimum code to pass
   - No premature optimization
   - No extra features
   
3. **REFACTOR**: Improve without changing behavior
   - Clean up code
   - Remove duplication
   - Tests must pass after each change

## Self-Review Before Commit

Run self-verification skill checklist before ANY commit.
```

---

## Next Steps

1. **Create remaining skills**:
   - `estimation/SKILL.md`
   - `technical-debt/SKILL.md`
   - `language-learning/SKILL.md`
   
2. **Set up hooks in projects**:
   ```bash
   # In each project
   ln -s ~/.claude/hooks/pre-commit .git/hooks/pre-commit
   ```

3. **Test the workflow**:
   - Pick a small feature
   - Run through full TDD cycle
   - Verify quality gates work

4. **Iterate based on friction**:
   - What's slowing you down?
   - What's being skipped?
   - Adjust accordingly
