# 10X Developer Unicorn

Build the complete 10X Developer Unicorn agent system for Claude Code.

## Project Overview

This project creates a comprehensive agent orchestration system with:
- Specialized subagents (Architect, Developer, QA, DevOps, Polyglot)
- Skills matrix (core, domain, meta)
- Quality enforcement (hooks, scripts, gates)
- TDD-first development workflow

**Model Strategy**: Opus everywhere for consistency and quality.

## Architecture Reference

Read these before implementation:
- `docs/10x-unicorn-architecture.md` - Agent specs, workflows, token management
- `docs/10x-hidden-skills.md` - The 80% skills (code reading, pattern transfer, etc.)
- `docs/10x-implementation-guide.md` - Directory structure, quickstart

## Project Structure

```
unicorn/
├── CLAUDE.md                          # This file
├── docs/                              # Architecture docs
├── skills/
│   ├── unicorn/                       # Meta-skills
│   │   ├── orchestrator/SKILL.md
│   │   ├── self-verification/SKILL.md
│   │   ├── code-reading/SKILL.md
│   │   ├── pattern-transfer/SKILL.md
│   │   ├── estimation/SKILL.md
│   │   ├── technical-debt/SKILL.md
│   │   └── language-learning/SKILL.md
│   ├── agents/                        # Subagent definitions
│   │   ├── developer.md
│   │   ├── architect.md
│   │   ├── qa-security.md
│   │   ├── devops.md
│   │   └── polyglot.md
│   └── domain/                        # Language/tool skills
│       ├── python/SKILL.md
│       ├── javascript/SKILL.md
│       ├── go/SKILL.md
│       ├── rust/SKILL.md
│       ├── testing/SKILL.md
│       ├── security/SKILL.md
│       └── devops/SKILL.md
├── hooks/
│   ├── pre-commit
│   └── pre-push
├── scripts/
│   ├── tdd.sh
│   ├── self-review.sh
│   ├── estimate.sh
│   ├── new-language.sh
│   └── install.sh
└── tests/
    ├── test_hooks.py
    ├── test_scripts.py
    └── test_skills_valid.py
```

## Development Rules

### TDD Always
```
RED → GREEN → REFACTOR

1. Write failing test first
2. Implement minimum to pass
3. Refactor without changing behavior
4. Self-review before commit
```

### Skill File Standards

Every SKILL.md must have:
```yaml
---
name: skill-name
description: >
  Clear description of what it does AND when to use it.
  Include trigger phrases. This is the only thing loaded
  before the skill activates.
---
```

Body guidelines:
- Under 500 lines (split to references/ if larger)
- Imperative voice ("Do X" not "You should do X")
- Concrete examples over explanations
- Scripts in scripts/, docs in references/

### Quality Gates

Before any commit:
- [ ] Tests pass (`pytest -v`)
- [ ] Scripts are executable and tested
- [ ] SKILL.md has valid frontmatter
- [ ] No TODO/FIXME/HACK markers
- [ ] Self-review checklist complete

### Commit Convention

```
type(scope): description

Types: feat, fix, docs, skill, script, test, refactor
Scope: orchestrator, developer, qa, devops, hooks, etc.

Examples:
- feat(orchestrator): add delegation matrix
- skill(code-reading): implement strategic reading protocol
- script(tdd): add coverage threshold check
```

## Implementation Order

### Phase 1: Foundation
1. [ ] Set up directory structure
2. [ ] Create `skills/unicorn/orchestrator/SKILL.md`
3. [ ] Create `skills/unicorn/self-verification/SKILL.md`
4. [ ] Create `hooks/pre-commit`
5. [ ] Create `scripts/install.sh`
6. [ ] Write validation tests

### Phase 2: Core Skills
1. [ ] `skills/unicorn/code-reading/SKILL.md`
2. [ ] `skills/unicorn/pattern-transfer/SKILL.md`
3. [ ] `skills/unicorn/estimation/SKILL.md`
4. [ ] `skills/unicorn/technical-debt/SKILL.md`
5. [ ] `skills/unicorn/language-learning/SKILL.md`

### Phase 3: Agent Definitions
1. [ ] `skills/agents/developer.md`
2. [ ] `skills/agents/architect.md`
3. [ ] `skills/agents/qa-security.md`
4. [ ] `skills/agents/devops.md`
5. [ ] `skills/agents/polyglot.md`

### Phase 4: Domain Skills
1. [ ] `skills/domain/python/SKILL.md`
2. [ ] `skills/domain/javascript/SKILL.md`
3. [ ] `skills/domain/testing/SKILL.md`
4. [ ] `skills/domain/security/SKILL.md`
5. [ ] `skills/domain/devops/SKILL.md`

### Phase 5: Scripts & Automation
1. [ ] `scripts/tdd.sh`
2. [ ] `scripts/self-review.sh`
3. [ ] `scripts/estimate.sh`
4. [ ] `scripts/new-language.sh`
5. [ ] `hooks/pre-push`

### Phase 6: Documentation & Polish
1. [ ] README.md with installation
2. [ ] Usage examples
3. [ ] Troubleshooting guide
4. [ ] Integration tests

## Key Patterns

### Orchestrator Delegation
```yaml
delegation:
  to: [agent-name]
  task: |
    Clear, focused task description
  context:
    - Only what's needed
  constraints:
    - Quality requirements
  expected_output:
    - Specific deliverables
```

### Skill Progressive Disclosure
```
Level 1: Metadata (name + description) - Always loaded (~100 words)
Level 2: SKILL.md body - When triggered (<500 lines)
Level 3: references/, scripts/ - As needed (unlimited)
```

### Self-Verification Protocol
```
Before EVERY commit:
1. git diff --staged (read as if someone else wrote it)
2. Run tests with coverage
3. Check for debug code, secrets, TODOs
4. Ask: "Would I approve this PR?"
```

## Testing Requirements

### Skill Validation Tests
```python
def test_skill_has_valid_frontmatter():
    """Every SKILL.md must have name and description."""
    
def test_skill_description_has_triggers():
    """Description must explain when to use the skill."""
    
def test_skill_under_500_lines():
    """Body must be under 500 lines (split if larger)."""
```

### Script Tests
```python
def test_scripts_are_executable():
    """All scripts in scripts/ must be chmod +x."""
    
def test_scripts_have_shebang():
    """All scripts must start with proper shebang."""
    
def test_tdd_script_enforces_red_first():
    """TDD script must fail if tests pass initially."""
```

### Hook Tests
```python
def test_precommit_catches_todos():
    """Pre-commit must reject files with TODO markers."""
    
def test_precommit_requires_coverage():
    """Pre-commit must enforce coverage threshold."""
```

## Commands

```bash
# Install the unicorn system
./scripts/install.sh

# Run TDD workflow for a feature
./scripts/tdd.sh <feature-name>

# Self-review before commit
./scripts/self-review.sh

# Estimate a task
./scripts/estimate.sh

# Learn a new language/framework
./scripts/new-language.sh <language>

# Validate all skills
pytest tests/test_skills_valid.py -v

# Full test suite
pytest -v --cov=. --cov-fail-under=80
```

## Context Management

### Token Budget
- Keep orchestrator context lean (coordination only)
- Delegate heavy work to subagents (each gets 200K)
- Skills lazy-load (body only when triggered)
- Return summaries, not full outputs

### When to Delegate
```
Simple question → Answer directly
Implementation → Developer subagent
Architecture decision → Architect subagent
Code review → QA subagent
Deployment → DevOps subagent
New language → Polyglot subagent
Complex (multi-domain) → Parallel delegation
```

## Success Criteria

### Functional
- [ ] All skills have valid frontmatter
- [ ] All scripts executable and tested
- [ ] Pre-commit hook catches quality issues
- [ ] TDD workflow enforces red-green-refactor
- [ ] Self-review checklist integrated

### Quality
- [ ] Test coverage ≥ 80%
- [ ] No TODO/FIXME/HACK in committed code
- [ ] All skills under 500 lines
- [ ] Documentation complete

### Usability
- [ ] Single-command installation
- [ ] Clear error messages
- [ ] Works with existing Claude Code setup
- [ ] Non-destructive (doesn't overwrite user config)

## Notes

- This project uses its own methodology to build itself (dogfooding)
- When in doubt, read the architecture docs
- Quality over speed—we're building the foundation
- Every skill should answer: "What would a 10X developer do here?"
