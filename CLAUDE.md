# 10X Developer Unicorn

Agent orchestration system for Claude Code. 18 skills across 6 agents.

## Orchestrator Mode

You coordinate the 10X Unicorn agent team. Delegate all substantial work to
subagents (Agent tool). Never implement complex tasks directly.

- Route tasks using the orchestrator skill's decision tree
- Enforce TDD: tests first, always (RED -> GREEN -> REFACTOR)
- Apply quality gates before returning results
- Each subagent gets fresh 200K context -- use it

The orchestrator skill (`skills/agents/orchestrator/SKILL.md`) has the full
routing table, delegation templates, quality gates, and response format.

## Quick Start

```bash
./scripts/install.sh        # Symlinks skills into .claude/skills/, wires git hooks
pytest tests/ -v            # Verify everything passes
```

Install options:
- `--global` — copies skills to `~/.claude/skills/` + activates orchestrator in `~/.claude/CLAUDE.md`
- `--force` — overwrites existing skills and hooks
- `--uninstall` — removes `.claude/skills/` symlinks

## Development Rules

### TDD Always
```
RED:      Write failing test first
GREEN:    Minimum code to pass
REFACTOR: Improve without changing behavior
VERIFY:   Self-review before commit
```

### Skill File Standards

Every SKILL.md must have:
```yaml
---
name: skill-name
description: >-
  Third-person description. ALWAYS trigger on "phrase1", "phrase2", "phrase3".
  Use when [conditions]. Different from [sibling] which [difference].
---
```

Body guidelines:
- Under 500 lines (target 150-300; split to references/ if larger)
- Action over explanation (Claude is already smart)
- Decision tables and checklists over prose
- Scripts co-located in skill's scripts/ directory
- Detailed content in references/ directory

### Quality Gates

Before any commit:
- Tests pass (pytest -v)
- Scripts are executable
- SKILL.md has valid frontmatter
- No unresolved task markers
- Self-review checklist complete

### Commit Convention

```
type(scope): description

Types: feat, fix, docs, skill, script, test, refactor
Scope: orchestrator, developer, qa, devops, hooks, etc.
```

## Commands

```bash
./scripts/install.sh                                          # Install system
./skills/agents/developer/scripts/tdd.sh <feature>            # TDD workflow
./skills/unicorn/self-verification/scripts/self-review.sh     # Pre-commit checklist
./skills/unicorn/estimation/scripts/estimate.sh               # PERT estimation
./skills/unicorn/language-learning/scripts/new-language.sh <lang>  # Language learning
pytest tests/ -v                                              # Run all tests
```

## Delegation Routing

```
Simple question        -> Answer directly
Implementation         -> Developer subagent
Architecture decision  -> Architect subagent
Code review            -> QA subagent
Deployment             -> DevOps subagent
New language           -> Polyglot subagent
Complex multi-domain   -> Parallel delegation
```

## Architecture Reference

- `docs/architecture.md` - Agent specs, workflows, token management
- `docs/hidden-skills.md` - The 80% skills (code reading, pattern transfer, etc.)
- `docs/implementation-guide.md` - Directory structure, quickstart

## Repository

https://github.com/aj-geddes/unicorn-team
