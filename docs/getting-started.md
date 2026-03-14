---
layout: default
title: "Getting Started - 10X Developer Unicorn"
description: "Install the unicorn-team plugin in one command and start using 18 specialized skills with Claude Code."
permalink: /getting-started/
---

# Getting Started

## Install

Two commands. No configuration files to edit, no manual setup.

```bash
# Add the marketplace
claude plugin marketplace add aj-geddes/unicorn-team

# Install the plugin
claude plugin install unicorn-team@unicorn-team
```

### What Happens After Install

1. **Agents registered** -- 5 agent definitions in `.claude/agents/` are available for subprocess spawning via the Agent tool, each with its own 200K context window.
2. **Skills discovered** -- All 18 SKILL.md files are registered with Claude Code. Agent protocol skills are preloaded into agents; meta and domain skills provide shared knowledge.
3. **Hooks registered** -- Pre-commit hooks are wired to enforce quality gates: tests must pass, coverage must meet threshold, no debug code, no secrets in staged files.
4. **Orchestrator activated** -- Claude Code now routes tasks through the orchestrator decision tree, delegating to agents instead of handling everything in a single context window.

You don't need to memorize trigger phrases or manually invoke skills. Just describe what you want. The orchestrator handles routing.

---

## Your First Task

Here's what happens when you ask Claude Code to build something after installing the plugin.

**You say:**
> "Add a password strength validator that checks length, complexity, and common passwords."

**The orchestrator:**
1. Analyzes the task -- single feature, moderate complexity, clear requirements
2. Routes to the **Developer agent** with TDD enforcement
3. Developer loads the **python** and **testing** domain skills

**The developer agent:**
1. **RED** -- Writes failing tests first:
   - `test_rejects_short_passwords`
   - `test_rejects_no_uppercase`
   - `test_rejects_common_passwords`
   - `test_accepts_strong_passwords`
2. **GREEN** -- Implements minimum code to pass all tests
3. **REFACTOR** -- Cleans up, extracts constants, improves names
4. **VERIFY** -- Runs the self-verification checklist, confirms coverage >= 80%

**You get:**
- Working implementation with comprehensive tests
- Coverage report
- Summary of decisions made
- Quality gate status (all passed)

The whole interaction looks the same as normal Claude Code usage -- you just get better results because the work flows through specialized agents with enforced discipline.

---

## Available Scripts

The plugin includes automation scripts for common workflows.

### TDD Workflow

Interactive guided TDD cycle for any feature:

```bash
./skills/developer/scripts/tdd.sh my-feature
```

Walks you through RED (write failing test), GREEN (make it pass), REFACTOR (improve), with automated verification at each phase.

### Self-Review

Pre-commit quality checklist:

```bash
./skills/self-verification/scripts/self-review.sh
```

Reviews your staged changes, runs the 6-step verification protocol, and asks for confirmation before proceeding. Catches issues before they reach code review.

### PERT Estimation

Interactive task estimation with risk analysis:

```bash
./skills/estimation/scripts/estimate.sh
```

Guides you through task decomposition, three-point estimates (optimistic/realistic/pessimistic), PERT formula calculation, and risk buffer application.

### Language Learning

Structured protocol for picking up a new programming language:

```bash
./skills/language-learning/scripts/new-language.sh rust
```

Walks through the 5-phase acquisition protocol: exploration, patterns, ecosystem, idioms, production readiness.

---

## Example Interactions

Here are tasks you can throw at Claude Code after installing the plugin:

| What You Say | What Happens |
|-------------|-------------|
| "Build a REST API for user management" | Architect designs API contract -> Developer implements with TDD -> QA reviews |
| "This code is confusing, help me understand it" | Code-reading skill activates with strategic reading protocol |
| "How long will the auth system take?" | Estimation skill runs PERT analysis with risk buffers |
| "Review this PR for security issues" | QA-Security runs OWASP analysis and threat modeling |
| "Set up CI/CD for this project" | DevOps agent creates GitHub Actions pipeline with quality gates |
| "I need to learn Go for this project" | Polyglot agent runs language-learning protocol, creates quick reference |
| "Refactor the payment module" | Code-reading first, then Developer with characterization tests |
| "We took a shortcut here, track it" | Technical-debt skill classifies, documents, and prioritizes |

---

## Development Setup (Contributors)

If you want to contribute to the unicorn-team plugin itself:

```bash
# Clone the repository
git clone https://github.com/aj-geddes/unicorn-team.git
cd unicorn-team

# Run the test suite
pytest tests/ -v

# Validate the plugin structure
./scripts/validate.sh

# Run all checks
pytest tests/ -v && ./scripts/validate.sh
```

### Project Structure

```
unicorn-team/
  .claude/
    agents/               # Agent definitions (spawn as subprocesses)
      developer.md        # TDD implementation agent (sonnet)
      architect.md        # System design agent (opus)
      qa-security.md      # Code review and security agent (sonnet)
      devops.md           # Infrastructure and deployment agent (sonnet)
      polyglot.md         # Language specialist agent (opus)
    skills/               # Symlinks to skills/ for discovery
  protocols/            # Agent reference materials
      developer/references/
      architect/references/
      qa-security/references/
      devops/references/
      polyglot/references/
  skills/
    orchestrator/         # Task routing and coordination (skill, not agent)
    code-reading/         # Codebase comprehension
    pattern-transfer/     # Cross-domain pattern recognition
    self-verification/    # Pre-commit self-review
    estimation/           # PERT-based estimation
    technical-debt/       # Debt tracking and management
    language-learning/    # Structured language acquisition
    hvs-skill-buddy/      # Skill creation and auditing
    python/               # Python domain patterns
    javascript/           # JS/TS domain patterns
    testing/              # Test strategy patterns
    security/             # Security domain patterns
    domain-devops/        # DevOps domain patterns
  scripts/
    install.sh            # Plugin installer
    validate.sh           # Structure validator
  tests/                  # Plugin test suite
  docs/                   # This site
```

### Contribution Guidelines

- Follow TDD: write the failing test first, always
- Every SKILL.md needs valid YAML frontmatter with trigger phrases
- Keep skills under 500 lines (target 150-300)
- Run `pytest tests/ -v` before committing
- Use conventional commits: `feat(scope):`, `fix(scope):`, `skill(scope):`

---

## Troubleshooting

Having issues? Check the [Troubleshooting guide]({{ site.baseurl }}/troubleshooting/) for solutions to common problems with installation, scripts, hooks, and test failures.
