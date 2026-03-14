---
layout: default
title: "Skills - 10X Developer Unicorn"
description: "Deep dive into the 13 composable skills that encode senior engineering expertise: code reading, pattern transfer, estimation, self-verification, and more."
permalink: /skills/
---

# Skills

The 10X Developer Unicorn plugin has 13 composable skills in `skills/` -- all user-invocable via slash commands. Agent protocol content (TDD workflows, review checklists, deployment procedures) is inlined directly in agent definitions (`.claude/agents/*.md`), keeping the skill list clean and unambiguous.

```
skills/
  orchestrator/
    SKILL.md           # Activation rules + core logic
    scripts/           # Automation scripts
    references/        # Detailed docs, examples
```

Skills compose. The developer agent draws on `python`, `testing`, and `security` domain skills during implementation. The polyglot agent uses `language-learning` and `pattern-transfer`. The orchestrator routes to all of them.

---

## Skill Categories

<div class="diagram">
  <div class="skill-map">
    <div class="skill-group" style="border-color: var(--blue);">
      <div class="skill-group-title text-blue">Coordination</div>
      <span class="skill-tag bg-blue">orchestrator</span>
    </div>
    <div class="skill-group" style="border-color: var(--mauve);">
      <div class="skill-group-title text-mauve">Meta Skills</div>
      <span class="skill-tag bg-mauve">code-reading</span>
      <span class="skill-tag bg-mauve">pattern-transfer</span>
      <span class="skill-tag bg-mauve">self-verification</span>
      <span class="skill-tag bg-mauve">estimation</span>
      <span class="skill-tag bg-mauve">technical-debt</span>
      <span class="skill-tag bg-mauve">language-learning</span>
      <span class="skill-tag bg-mauve">hvs-skill-buddy</span>
    </div>
    <div class="skill-group" style="border-color: var(--green);">
      <div class="skill-group-title text-green">Domain Skills</div>
      <span class="skill-tag bg-green">python</span>
      <span class="skill-tag bg-green">javascript</span>
      <span class="skill-tag bg-green">testing</span>
      <span class="skill-tag bg-green">security</span>
      <span class="skill-tag bg-green">domain-devops</span>
    </div>
  </div>
</div>

---

## Agents (Protocol Inlined)

Each agent in `.claude/agents/` has its protocol content inlined directly in its definition body. This keeps agent protocols out of the slash command list while making them self-contained. Agent reference materials live in `.claude/protocols/{agent}/references/`.

| Agent Definition | Composable Skills | Role |
|-----------------|-------------------|------|
| `.claude/agents/developer.md` | self-verification, testing, python, javascript | TDD implementation (Python, JS/TS, Go, Rust) |
| `.claude/agents/architect.md` | pattern-transfer, code-reading, technical-debt | System design, ADRs, API contracts |
| `.claude/agents/qa-security.md` | security, testing | 4-layer code review, STRIDE security audit |
| `.claude/agents/devops.md` | domain-devops, security | CI/CD, IaC, deployment, monitoring |
| `.claude/agents/polyglot.md` | language-learning, pattern-transfer, code-reading | Language acquisition, pattern transfer |

---

## Orchestrator

**Triggers**: "implement", "build", "create", "design system", "deploy", "refactor", "fix bug", "estimate", "architecture"

The brain of the system. Analyzes incoming tasks, routes them to the right agent, and enforces quality gates at every handoff. Never implements directly -- it coordinates.

- Routes simple features to Developer, complex ones through Architect first
- Breaks multi-domain tasks into parallel delegations
- Enforces TDD and self-verification on every implementation
- Manages context budgets across subagents

---

## Meta Skills

Meta skills encode the engineering judgment that separates senior developers from junior ones. These are the skills that most AI tools lack entirely.

### Code Reading

**Triggers**: "understand this code", "how does this work", "legacy code", "what does this do", "explain this codebase"

Professional developers spend 80% of their time reading code, not writing it. This skill provides a strategic reading protocol: find entry points, trace data flow, identify error paths, map integration boundaries. Four comprehension levels from "what does it DO?" to "what ELSE does this affect?"

### Pattern Transfer

**Triggers**: "I've seen this before", "this is like X but in Y", "there must be a pattern", "equivalent of", "idiomatic way"

A 10X developer sees the same problem in different clothes. The Observer pattern in OOP is event emitters in JS is pub/sub in messaging is webhooks in APIs. This skill recognizes problem classes (state management, async coordination, caching, rate limiting, retry logic) and transfers proven solutions across domains.

### Self-Verification

**Triggers**: "review my code", "check my work", "before commit", "self-review", "quality check"

The biggest gap in AI coding: generating code and considering it done. This skill enforces a 6-step pre-commit protocol -- diff review, completeness check, quality check, test verification, security check, documentation check. Includes the "fresh eyes" technique for catching what your brain glosses over.

### Estimation

**Triggers**: "estimate", "how long will this take", "sizing", "scope this", "story points", "project timeline"

Bad estimates destroy trust. This skill uses risk-based estimation with decomposition into atomic units, three-point estimates (optimistic/realistic/pessimistic), PERT formula calculation, explicit risk buffers, and integration buffers. Outputs include confidence levels, stated assumptions, and identified risks.

### Technical Debt

**Triggers**: "technical debt", "code shortcut", "pay down debt", "temporary hack", "missing tests", "refactor plan"

Every shortcut has a cost. This skill classifies debt using the debt quadrant (deliberate vs. inadvertent, reckless vs. prudent), tracks it with structured records, quantifies ongoing interest, and prioritizes paydown. Helps teams make deliberate decisions about when to take shortcuts and when to pay them back.

### Language Learning

**Triggers**: "learn Rust", "learn Go", "new language", "getting started with", "never used X before"

A structured 5-phase protocol for rapidly acquiring new programming languages: exploration (syntax, types, control flow), patterns (iteration, collections, null handling, async), ecosystem (package manager, testing, linting), idioms (community conventions, anti-patterns), and production (deployment, monitoring, performance).

### HVS Skill Buddy

**Triggers**: "skill buddy", "audit my skills", "create a new skill", "build a skill", "skill system"

The meta-skill for the skill system itself. Audits existing skills for drift and inconsistency, creates new skills that fit the system standard, and keeps skills current with the latest patterns. Your guide to extending the unicorn team.

---

## Domain Skills

Domain skills provide language-specific and technology-specific patterns that agent skills draw on during execution.

### Python

**Triggers**: "python project", "pyproject.toml", "ruff", "mypy", "pytest", "type hints", "pydantic"

Modern Python development: project structure with pyproject.toml, ruff for linting/formatting, mypy for type checking, pytest patterns (fixtures, parametrize, conftest), dataclasses vs. Pydantic, async patterns with asyncio.

### JavaScript

**Triggers**: "typescript", "javascript", "tsconfig", "eslint", "react", "node.js", "vitest", "jest"

JavaScript and TypeScript development: project setup, ESLint/Prettier configuration, vitest/jest testing patterns, React hooks and component patterns, Node.js backend patterns, type guards and discriminated unions.

### Testing

**Triggers**: "write tests", "TDD", "test coverage", "mock", "flaky test", "unit test", "integration test", "e2e test"

Cross-language test strategy: choosing between unit/integration/e2e tests, Arrange-Act-Assert structure, effective mocking, handling flaky tests, coverage targets, designing testable code. The patterns that apply regardless of language.

### Security

**Triggers**: "security review", "vulnerability", "authentication", "input validation", "XSS", "SQL injection", "OWASP"

Application-level security with an attacker's mindset: defense-in-depth, input validation, output encoding, authentication and authorization patterns, secrets management, threat modeling with STRIDE, dependency auditing.

### DevOps (Domain)

**Triggers**: "dockerize", "CI/CD", "kubernetes", "monitoring", "logging", "metrics", "helm", "GitOps"

Infrastructure patterns and practices: Dockerfile optimization, CI/CD pipeline design, Kubernetes deployment patterns, observability (structured logging, metrics, distributed tracing), health checks, scaling strategies.

---

## How Skills Compose

Skills don't work in isolation. When the Developer agent implements a Python feature:

1. The agent's **inlined protocol** provides the TDD workflow and implementation discipline
2. **python** skill provides language-specific idioms, tooling, and project structure
3. **testing** skill provides test strategy and pattern guidance
4. **security** skill flags potential vulnerabilities during implementation
5. **self-verification** skill runs the pre-commit checklist before finishing
6. **code-reading** skill activates if the developer needs to understand existing code first

The orchestrator decides which agent to invoke. Each agent's composable skills are loaded into its 200K context window alongside its inlined protocol.

---

## Create Your Own Skill

Every skill follows the same structure:

```yaml
---
name: my-skill
description: >-
  Third-person description. ALWAYS trigger on "phrase1", "phrase2", "phrase3".
  Use when [conditions]. Different from [sibling] which [difference].
---
```

Guidelines:
- **Under 500 lines** (target 150-300; split large content to `references/`)
- **Action over explanation** -- decision tables and checklists over prose
- **Co-locate scripts** in the skill's `scripts/` directory
- **Valid frontmatter** with trigger phrases and differentiation from related skills

Use the [HVS Skill Buddy](#hvs-skill-buddy) to create skills that fit the system standard, or read the [Getting Started guide]({{ site.baseurl }}/getting-started/) for contributor setup.
