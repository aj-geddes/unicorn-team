# 10X Developer Unicorn Agent Architecture

## Executive Summary

The 10X Developer Unicorn is an orchestrated agent system for Claude Code that maximizes context window efficiency through intelligent subagent delegation, enforces proven development methodologies, and delivers production-ready code through systematic quality gates.

**Core Philosophy**: Workflows provide stability, agents provide flexibility. Start with deterministic workflows, invoke agents for creative reasoning.

---

## What Makes a 10X Developer?

### The Multiplier Effect

A 10X developer isn't just faster—they're a force multiplier:

| Trait | 1X Developer | 10X Developer |
|-------|--------------|---------------|
| **Code Reading** | Reads to understand | Reads to refactor, improve, extend |
| **Pattern Recognition** | Solves one problem | Recognizes problem class, applies pattern |
| **Debugging** | Trial and error | Systematic hypothesis testing |
| **Architecture** | Builds what's asked | Anticipates scale, change, failure modes |
| **Testing** | Tests after coding | Tests define the contract first (TDD) |
| **Communication** | Documents code | Documents decisions, tradeoffs, context |
| **Learning** | Learns one language | Learns language paradigms, transfers knowledge |
| **Estimation** | Guesses | Breaks down, identifies risks, buffers |
| **Quality** | Works on their machine | Works in production, at scale, under load |

### The Missing Skills (What Most AI Agents Lack)

1. **Code Comprehension** - Understanding existing codebases (80% of real work)
2. **Pattern Transfer** - Applying solutions from one domain to another
3. **Self-Verification** - Reviewing own work before submission
4. **Refactoring Discipline** - Improving without changing behavior
5. **Estimation & Risk** - Breaking down and identifying unknowns
6. **Technical Debt Awareness** - Knowing when to pay it down
7. **Security Mindset** - Threat modeling, not just checklist compliance
8. **Observability Design** - Logging, metrics, tracing from day one

---

## Agent Architecture

### Design Principles

```
┌─────────────────────────────────────────────────────────────────┐
│  Token Economy: Context Window is a Public Good                  │
│  • Each subagent gets its own 200K context                       │
│  • Main orchestrator stays lean (coordination only)              │
│  • Skills lazy-load (metadata always, body on trigger)           │
│  • Subagents return Z tokens, not (X + Y + Z) × N               │
└─────────────────────────────────────────────────────────────────┘
```

### The Unicorn Squad (5+1 Architecture)

```
                    ┌─────────────────────┐
                    │    ORCHESTRATOR     │
                    │  (The Unicorn CEO)  │
                    │   Model: Haiku/Fast │
                    │   Context: Lean     │
                    └──────────┬──────────┘
                               │
       ┌───────────┬───────────┼───────────┬───────────┐
       │           │           │           │           │
       ▼           ▼           ▼           ▼           ▼
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│ ARCHITECT│ │ DEVELOPER│ │    QA    │ │  DEVOPS  │ │ POLYGLOT │
│          │ │          │ │          │ │          │ │          │
│ System   │ │ Full-    │ │ Security │ │ Infra    │ │ Language │
│ Design   │ │ Stack    │ │ Testing  │ │ CI/CD    │ │ Expert   │
│ Patterns │ │ TDD      │ │ Review   │ │ Deploy   │ │ Learner  │
│          │ │          │ │          │ │          │ │          │
│ Model:   │ │ Model:   │ │ Model:   │ │ Model:   │ │ Model:   │
│ Opus     │ │ Opus     │ │ Sonnet   │ │ Sonnet   │ │ Opus     │
└──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘
```

### Agent Specifications

#### 1. Orchestrator (The Unicorn CEO)

```yaml
---
name: unicorn-orchestrator
description: >
  Lightweight coordinator for all development tasks. Routes to specialized
  subagents, aggregates results, enforces quality gates. Uses Haiku for
  speed and token efficiency. Never implements directly—delegates everything.
model: haiku
tools: subagent-invoke, task-breakdown, quality-gate
skills: orchestration-patterns, delegation-matrix
---
```

**Responsibilities**:
- Analyze incoming task complexity
- Break down into delegatable units
- Route to appropriate subagent(s)
- Aggregate and synthesize results
- Enforce quality gates between phases
- Manage context budget

**Decision Matrix**:
```
Task Analysis
│
├─ Single-language, < 200 lines → Developer
├─ Multi-service, distributed → Architect → Developer
├─ "Fix this bug" → root-cause-debugger skill → Developer
├─ "Add tests" → QA
├─ "Deploy to prod" → DevOps
├─ New language/framework → Polyglot → Developer
├─ Security audit → QA (security mode)
└─ Complex (multi-domain) → Parallel delegation
```

#### 2. Architect Agent

```yaml
---
name: architect
description: >
  System design, patterns, tradeoffs, scalability. Invoked for new systems,
  major refactors, or when Developer encounters architectural decisions.
  Produces design docs, not code.
model: opus
tools: Read, Write, WebSearch, diagram-generator
skills: system-design, design-patterns, architecture-decision-records
---
```

**Outputs**:
- Architecture Decision Records (ADRs)
- System diagrams (Mermaid)
- API contracts (OpenAPI)
- Data models (ERD)
- Scalability analysis
- Tradeoff documentation

#### 3. Developer Agent

```yaml
---
name: developer
description: >
  Full-stack implementation with TDD discipline. Handles all code:
  backend, frontend, mobile, scripts. Always writes tests first.
  Uses mode-switching for different domains.
model: opus
tools: Bash, Read, Write, Edit, WebSearch
skills: python, javascript, testing, git, security
modes:
  backend: APIs, services, data processing
  frontend: React, Vue, CSS, accessibility
  mobile: iOS/Android, React Native
  scripts: CLI tools, automation
---
```

**TDD Enforcement**:
```
Every feature request:
1. Write failing test first (RED)
2. Implement minimum code to pass (GREEN)
3. Refactor without changing behavior (REFACTOR)
4. Self-review diff before commit
5. Quality gate: coverage > 80%
```

#### 4. QA Agent

```yaml
---
name: qa-security
description: >
  Quality assurance, security analysis, code review. Reviews all code
  before merge. Runs security scans, performance tests, accessibility
  audits. Acts as the final quality gate.
model: sonnet
tools: Bash, Read, WebSearch, security-scanner
skills: testing, security, code-review-patterns
modes:
  review: Code review with detailed feedback
  security: OWASP analysis, threat modeling
  performance: Load testing, profiling
  accessibility: WCAG compliance
---
```

**Quality Gates**:
- [ ] All tests pass
- [ ] Coverage ≥ 80%
- [ ] No security vulnerabilities (high/critical)
- [ ] Type checking passes
- [ ] Linting passes
- [ ] Documentation complete

#### 5. DevOps Agent

```yaml
---
name: devops
description: >
  Infrastructure, deployment, monitoring. Handles CI/CD pipelines,
  Kubernetes, Terraform, observability. Makes things run in production.
model: sonnet
tools: Bash, Read, Write, Edit, kubectl, terraform
skills: devops, docker-build-expert, kubernetes
---
```

**Capabilities**:
- CI/CD pipeline creation (GitHub Actions, GitLab)
- Infrastructure as Code (Terraform, Pulumi)
- Container orchestration (Kubernetes, Helm)
- Monitoring setup (Prometheus, Grafana)
- Security hardening
- Deployment strategies (blue-green, canary)

#### 6. Polyglot Agent

```yaml
---
name: polyglot
description: >
  Language learning and cross-domain pattern transfer. Invoked when
  encountering new languages, frameworks, or paradigms. Rapidly builds
  expertise and transfers it to Developer agent.
model: opus
tools: Read, WebSearch, documentation-fetcher
skills: language-learning, pattern-transfer
---
```

**Learning Protocol**:
```
New Language/Framework:
1. Identify paradigm (OOP, FP, procedural, etc.)
2. Map to known patterns (what's similar?)
3. Identify unique concepts (what's different?)
4. Find canonical examples
5. Build mental model
6. Create quick reference
7. Transfer knowledge to Developer
```

---

## Skills Matrix

### Core Skills (Required)

| Skill | Purpose | Agents |
|-------|---------|--------|
| `python` | Python idioms, stdlib, ecosystem | Developer, QA |
| `javascript` | JS/TS, Node, browsers | Developer, QA |
| `testing` | TDD, pytest, Jest, coverage | Developer, QA |
| `git` | Workflow, commits, history | All |
| `security` | OWASP, input validation, secrets | Developer, QA |
| `devops` | CI/CD, containers, infra | DevOps |
| `root-cause-debugger` | Systematic debugging | All |

### Domain Skills (On-Demand)

| Skill | Purpose | Triggered By |
|-------|---------|--------------|
| `docker-build-expert` | Container optimization | Dockerfile work |
| `kubernetes` | K8s patterns | K8s resources |
| `api-design` | REST/GraphQL patterns | API work |
| `database-design` | Schema, queries, optimization | DB work |
| `performance` | Profiling, optimization | Perf issues |
| `accessibility` | WCAG, a11y patterns | UI work |

### Meta Skills (Always Active)

| Skill | Purpose |
|-------|---------|
| `orchestration-patterns` | Task delegation, aggregation |
| `self-verification` | Pre-commit self-review |
| `estimation` | Task breakdown, risk identification |
| `technical-debt` | Debt tracking, paydown decisions |

---

## Workflow: New Feature Development

### Phase 1: Planning (Orchestrator)

```
User Request → Orchestrator
│
├─ Complexity Analysis
│   ├─ Lines of code estimate
│   ├─ Services affected
│   ├─ New technologies?
│   └─ Risk assessment
│
├─ Delegation Plan
│   ├─ Which agents needed?
│   ├─ What order?
│   └─ Quality gates?
│
└─ Execute Plan
```

### Phase 2: Design (if complex)

```
Orchestrator → Architect
│
├─ System context analysis
├─ Pattern selection
├─ API contract design
├─ Data model design
└─ ADR creation
│
Architect → Orchestrator
├─ Design artifacts
├─ Implementation guidance
└─ Risk notes
```

### Phase 3: Implementation

```
Orchestrator → Developer (with Architect guidance if provided)
│
├─ TDD Cycle
│   ├─ RED: Write failing tests
│   ├─ GREEN: Implement minimum
│   └─ REFACTOR: Clean up
│
├─ Self-Review
│   ├─ git diff --staged
│   ├─ Check for TODOs
│   └─ Verify coverage
│
└─ Commit (atomic, conventional)
│
Developer → Orchestrator
├─ Implementation complete
├─ Test results
└─ Coverage report
```

### Phase 4: Review

```
Orchestrator → QA
│
├─ Code Review
│   ├─ Logic correctness
│   ├─ Error handling
│   └─ Edge cases
│
├─ Security Scan
│   ├─ Vulnerability check
│   └─ Secrets exposure
│
└─ Quality Gate Check
│
QA → Orchestrator
├─ Approval / Rejection
├─ Feedback for Developer
└─ Security report
```

### Phase 5: Deployment (if approved)

```
Orchestrator → DevOps
│
├─ CI/CD execution
├─ Environment deployment
└─ Monitoring verification
│
DevOps → Orchestrator
├─ Deployment status
└─ Observability links
```

---

## Hooks & Scripts

### Pre-Commit Hook

```bash
#!/bin/bash
# .hooks/pre-commit
set -euo pipefail

echo "🔍 Pre-commit validation..."

# 1. Lint check
echo "  📋 Linting..."
if [[ -f "pyproject.toml" ]]; then
    ruff check . || exit 1
    ruff format --check . || exit 1
fi

# 2. Type check
echo "  🔍 Type checking..."
if [[ -f "pyproject.toml" ]]; then
    mypy . --ignore-missing-imports || exit 1
fi

# 3. Test with coverage
echo "  🧪 Running tests..."
pytest --cov=. --cov-fail-under=80 -q || exit 1

# 4. Security scan
echo "  🔒 Security scan..."
bandit -r . -q || exit 1

# 5. No debug artifacts
echo "  🗑️ Checking for debug code..."
if grep -r "breakpoint()\|import pdb\|console\.log" --include="*.py" --include="*.js" --include="*.ts" .; then
    echo "❌ Found debug code!"
    exit 1
fi

# 6. No TODO in staged files
echo "  📝 Checking for TODOs..."
if git diff --cached --name-only | xargs grep -l "TODO\|FIXME\|HACK" 2>/dev/null; then
    echo "⚠️ Found TODO/FIXME/HACK - resolve before commit"
    exit 1
fi

echo "✅ Pre-commit passed!"
```

### Self-Review Script

```bash
#!/bin/bash
# scripts/self-review.sh
set -euo pipefail

echo "🔄 Self-Review Checklist"
echo "========================"

# Show staged changes
echo ""
echo "📝 Staged Changes:"
git diff --cached --stat

echo ""
echo "🔍 Detailed diff:"
git diff --cached

echo ""
echo "📋 Checklist:"
echo "  [ ] Does this change do ONE thing well?"
echo "  [ ] Are all edge cases handled?"
echo "  [ ] Is error handling complete?"
echo "  [ ] Are tests comprehensive?"
echo "  [ ] Is documentation updated?"
echo "  [ ] Would I approve this in code review?"

read -p "Proceed with commit? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "✅ Proceeding..."
else
    echo "❌ Commit cancelled"
    exit 1
fi
```

### TDD Workflow Script

```bash
#!/bin/bash
# scripts/tdd.sh
set -euo pipefail

feature="$1"

echo "🔴🟢🔵 TDD Cycle: $feature"
echo "================================"

# RED Phase
echo ""
echo "🔴 PHASE 1: RED (Write Failing Test)"
echo "  → Create test in tests/test_${feature}.py"
echo "  → Test should describe expected behavior"
echo "  → Test MUST fail initially"

read -p "Press Enter when test is written..."

echo "Running tests (expecting FAILURE)..."
if pytest "tests/test_${feature}.py" -v; then
    echo "⚠️ Tests are passing! Write a failing test first."
    exit 1
fi
echo "✅ Test fails as expected"

# GREEN Phase
echo ""
echo "🟢 PHASE 2: GREEN (Make It Pass)"
echo "  → Implement MINIMUM code to pass"
echo "  → No premature optimization"
echo "  → No extra features"

read -p "Press Enter when implementation is ready..."

echo "Running tests (expecting SUCCESS)..."
if ! pytest "tests/test_${feature}.py" -v; then
    echo "❌ Tests still failing. Continue implementation."
    exit 1
fi
echo "✅ Tests pass!"

# REFACTOR Phase
echo ""
echo "🔵 PHASE 3: REFACTOR"
echo "  → Improve code quality"
echo "  → Remove duplication"
echo "  → Improve naming"
echo "  → Tests must still pass after each change"

read -p "Press Enter when refactoring is complete..."

echo "Final verification..."
pytest "tests/test_${feature}.py" -v --cov=. --cov-report=term-missing

echo ""
echo "✅ TDD Cycle Complete!"
```

---

## Context Window Management

### Token Budget Strategy

```
Total Context: 200K tokens

Orchestrator Budget:
├─ System Prompt: ~5K
├─ Conversation History: ~10K
├─ Skill Metadata (all): ~2K
├─ Active Skill Body: ~5K
├─ Working Memory: ~10K
└─ Response Buffer: ~5K
    Total: ~37K (leaving room for growth)

Subagent Delegation:
├─ Each subagent gets fresh 200K context
├─ Orchestrator passes:
│   ├─ Task description (~500 tokens)
│   ├─ Relevant context (~2K tokens)
│   └─ Constraints (~500 tokens)
└─ Subagent returns:
    ├─ Result summary (~1K tokens)
    └─ Artifacts (files, not context)
```

### Context Compression Techniques

1. **Summarize, Don't Copy**: Subagents return summaries, not full outputs
2. **Artifacts Over Context**: Write to files, reference by path
3. **Progressive Disclosure**: Load skill bodies only when triggered
4. **Checkpoint & Reset**: For long tasks, checkpoint state and reset context
5. **Parallel Delegation**: Multiple subagents work independently

---

## Language Learning Framework

### Paradigm Recognition

```
Language Encounter:
│
├─ Identify Paradigm
│   ├─ OOP (Java, C#, Python)
│   ├─ Functional (Haskell, Elixir, Clojure)
│   ├─ Procedural (C, Go)
│   ├─ Multi-paradigm (Python, Scala, Rust)
│   └─ Declarative (SQL, Prolog, HTML)
│
├─ Map to Known Patterns
│   ├─ "This is like X in Python"
│   ├─ "This is a monad (like Optional)"
│   └─ "This is pattern matching (like match/case)"
│
├─ Identify Unique Concepts
│   ├─ Ownership (Rust)
│   ├─ Goroutines (Go)
│   ├─ Actors (Elixir)
│   └─ Protocols (Clojure)
│
└─ Build Quick Reference
    ├─ Syntax basics
    ├─ Common patterns
    ├─ Ecosystem tools
    └─ Gotchas/footguns
```

### Rapid Learning Protocol

```yaml
new_language_protocol:
  1_exploration:
    - "Hello World" + build system
    - Variable declaration, types
    - Functions, methods
    - Control flow
    - Error handling
  
  2_patterns:
    - Iteration (for, while, map, filter)
    - Collections (list, map, set)
    - Null handling
    - Async patterns
  
  3_ecosystem:
    - Package manager
    - Testing framework
    - Linter/formatter
    - IDE support
  
  4_idioms:
    - "The way things are done here"
    - Community conventions
    - Anti-patterns to avoid
  
  5_production:
    - Deployment patterns
    - Monitoring/logging
    - Performance characteristics
```

---

## Quality Assurance Matrix

### Code Review Checklist

```markdown
## Automated Checks (Pre-Review)
- [ ] All tests pass
- [ ] Coverage ≥ 80%
- [ ] Linting passes
- [ ] Type checking passes
- [ ] Security scan clean
- [ ] No TODO/FIXME/HACK

## Logic Review
- [ ] Does the code do what it claims?
- [ ] Are edge cases handled?
- [ ] Are error conditions handled gracefully?
- [ ] Is the logic clear and followable?

## Design Review
- [ ] Single responsibility principle?
- [ ] Appropriate abstraction level?
- [ ] No unnecessary complexity?
- [ ] Consistent with codebase patterns?

## Security Review
- [ ] Input validated?
- [ ] Output encoded?
- [ ] No hardcoded secrets?
- [ ] Least privilege applied?

## Documentation Review
- [ ] Public APIs documented?
- [ ] Complex logic explained?
- [ ] README updated if needed?
- [ ] CHANGELOG updated?
```

### Security Threat Model

```
For every feature:
│
├─ What data does it handle?
│   └─ Sensitive? PII? Credentials?
│
├─ What are the trust boundaries?
│   └─ User input? External API? Database?
│
├─ What could go wrong?
│   ├─ Injection attacks
│   ├─ Authentication bypass
│   ├─ Authorization failure
│   ├─ Data exposure
│   └─ Denial of service
│
└─ How do we prevent it?
    ├─ Input validation
    ├─ Output encoding
    ├─ Parameterized queries
    ├─ Rate limiting
    └─ Audit logging
```

---

## Implementation Roadmap

### Phase 1: Foundation (Week 1)

- [ ] Create `unicorn-orchestrator` skill
- [ ] Create `self-verification` skill
- [ ] Create `delegation-matrix` skill
- [ ] Set up hooks (pre-commit, pre-push)
- [ ] Create TDD workflow script

### Phase 2: Core Agents (Week 2)

- [ ] Refine `developer` agent spec
- [ ] Refine `qa-security` agent spec
- [ ] Create `architect` agent spec
- [ ] Create `devops` agent spec
- [ ] Integration testing

### Phase 3: Advanced Skills (Week 3)

- [ ] Create `language-learning` skill
- [ ] Create `pattern-transfer` skill
- [ ] Create `estimation` skill
- [ ] Create `technical-debt` skill

### Phase 4: Optimization (Week 4)

- [ ] Context window profiling
- [ ] Token efficiency tuning
- [ ] Workflow refinement
- [ ] Documentation complete

---

## Success Metrics

### Efficiency Metrics

| Metric | Target |
|--------|--------|
| Token efficiency | < 50% of naive approach |
| Time to first test | < 5 minutes |
| Test coverage | ≥ 80% |
| Self-review catch rate | > 90% of issues |

### Quality Metrics

| Metric | Target |
|--------|--------|
| CI pass rate | > 95% |
| Security vulnerabilities | 0 high/critical |
| Code review iterations | < 2 on average |
| Production incidents | < 1/month |

### Learning Metrics

| Metric | Target |
|--------|--------|
| New language proficiency | < 4 hours to productive |
| Pattern recognition accuracy | > 85% |
| Documentation completeness | 100% public APIs |

---

## Appendix: File Structure

```
~/.claude/
├── CLAUDE.md                    # Main system prompt (lean)
├── skills/
│   ├── unicorn/
│   │   ├── orchestration/
│   │   │   └── SKILL.md
│   │   ├── self-verification/
│   │   │   └── SKILL.md
│   │   ├── delegation-matrix/
│   │   │   └── SKILL.md
│   │   └── estimation/
│   │       └── SKILL.md
│   ├── agents/
│   │   ├── developer.md
│   │   ├── architect.md
│   │   ├── qa-security.md
│   │   ├── devops.md
│   │   └── polyglot.md
│   └── domain/
│       ├── python/
│       ├── javascript/
│       ├── security/
│       ├── testing/
│       └── devops/
├── hooks/
│   ├── pre-commit
│   └── pre-push
└── scripts/
    ├── tdd.sh
    ├── self-review.sh
    ├── quality-gate.sh
    └── new-language.sh
```
