---
name: technical-debt
description: >-
  Guides deliberate management of technical debt: recognition, tracking, prioritization,
  and paydown. ALWAYS trigger on "technical debt", "code shortcut", "pay down debt",
  "debt tracking", "just for now", "temporary hack", "hardcoded value", "copy-paste code",
  "missing tests", "TODO cleanup", "refactor plan", "debt priority", "interest cost",
  "boy scout rule", "code quality backlog". Use when taking a shortcut, discovering
  suboptimal code, planning debt paydown, or quantifying ongoing cost of compromises.
---
<!-- Last reviewed: 2026-03 -->

# Technical Debt Management

## Debt Quadrant (Classification)

```
                    Reckless                    Prudent
              +---------------------+---------------------+
 Deliberate   |  "We don't have    |  "We must ship      |
              |   time for tests"   |   now and deal      |
              |   [DANGEROUS]       |   with consequences"|
              |                     |   [STRATEGIC]       |
              +---------------------+---------------------+
 Inadvertent  |  "What's a         |  "Now we know how   |
              |   design pattern?"  |   we should have    |
              |   [INCOMPETENCE]    |   done it"          |
              |                     |   [LEARNING]        |
              +---------------------+---------------------+
```

| Quadrant | Action |
|----------|--------|
| Prudent + Deliberate | Target. Track and schedule paydown. |
| Inadvertent + Prudent | Acceptable. Convert to tracked item. |
| Reckless + Deliberate | Dangerous. Escalate; requires paydown plan before merge. |
| Reckless + Inadvertent | Unacceptable. Training issue, not debt. |

## Debt Recognition Signals

### Code Smells
- "Just for now" / "temporary" comments
- Copy-paste blocks (DRY violation)
- Commented-out code
- TODO/FIXME/HACK without tracking ID
- Magic numbers, hardcoded config
- Broad exception catching (`except: pass`)
- Missing error handling or input validation

### Test Smells
- Missing coverage, disabled/skipped tests
- No edge case or integration tests
- Manual-only testing

### Architecture Smells
- Tight coupling, circular dependencies
- God objects, feature envy, data clumps

### Infrastructure Smells
- Outdated dependencies, known CVEs
- No monitoring/logging, manual deploys
- Secrets in code, no backup plan

## Debt Tracking Template

```yaml
technical_debt_item:
  id: TD-042
  type: deliberate        # deliberate | inadvertent
  quadrant: prudent-deliberate
  location: src/auth/login.py:45-89
  description: >
    Hardcoded session timeout to 30 minutes. Should be
    configurable per environment.
  why_taken: >
    Config system not ready; needed auth for demo.
  impact:
    - Cannot adjust without redeploy
    - Different envs need different values
  interest: >
    ~2 hours per incident, ~3 incidents/month = 72 hours/year
  payoff_plan:
    effort: 2 hours
    tasks:
      - Add timeout config to settings
      - Update login.py to read config
      - Add tests for timeout values
      - Deploy to all environments
  priority: high
  created: 2025-01-15
  owner: "@developer"
  due_date: 2025-02-01
  status: tracked  # tracked | scheduled | in_progress | paid
```

Inline marker format: `# TODO(TD-042): Hardcoded timeout, see debt tracker`

## Debt Lifecycle

### 1. Identify

Trigger: shortcut taken, suboptimal code found, surprising behavior, repeated patterns.

Classify immediately:
- Deliberate or inadvertent?
- Prudent or reckless?
- What is the ongoing cost (interest)?

### 2. Document

- Assign ID (TD-XXX)
- Record location (file:line-line)
- Capture WHY debt was taken
- List concrete impacts
- Estimate interest and payoff effort
- Add inline `TODO(TD-XXX)` comment

### 3. Calculate Interest

```
Annual Interest = Cost per Incident x Incidents per Year
```

| Frequency | Multiplier |
|-----------|-----------|
| Daily | x 365 |
| Weekly | x 52 |
| Monthly | x 12 |
| Quarterly | x 4 |

Examples:
- Hardcoded config: 2h/incident x 36/year = **72 hours/year**
- Missing tests: 1h/bug x 120/year = **120 hours/year**
- Copy-paste code: 0.5h/change x 240/year = **120 hours/year**

### 4. Prioritize

```
Priority Score = Annual Interest / Payoff Effort
```

| Score | Priority | Payback Period |
|-------|----------|---------------|
| > 10 | HIGH | < 1 month |
| 3-10 | MEDIUM | 1-4 months |
| < 3 | LOW | > 4 months |

Examples:
- Missing validation: 120h / 2h = **60** (HIGH)
- Hardcoded config: 72h / 2h = **36** (HIGH)
- Refactor structure: 20h / 16h = **1.25** (LOW)

### 5. Plan Payment

- **Sprint 0 Rule**: Address high-priority debt before new features
- **20% Rule**: Allocate 20% of sprint capacity to debt
- **Boy Scout Rule**: Fix small debt when touching nearby code

Payment workflow:
1. Branch: `debt/TD-042-description`
2. Write characterization tests first
3. Make incremental changes
4. Verify behavior preserved
5. Update tracker: `status: paid`, record `actual_effort`
6. Commit: `fix(TD-042): make session timeout configurable`

### 6. Verify Payment

- [ ] Root cause addressed (not just symptom)
- [ ] Tests added to prevent regression
- [ ] Documentation updated
- [ ] No new debt introduced
- [ ] Tracker updated to "paid"
- [ ] Inline TODO comments removed

## Boy Scout Rule

> Leave the code better than you found it.

**Small improvements (do these inline):**
- Rename unclear variables
- Add missing docstrings
- Extract magic numbers to named constants
- Add type hints to untyped signatures

**Large changes (separate commits):**
- Do NOT refactor entire modules while adding features
- Do NOT change architecture during bug fixes
- Commit 1: feature/fix only; Commit 2: refactoring only

## Debt Prevention Checklist

### Definition of Done
- [ ] Tests written and passing
- [ ] Error handling added
- [ ] No hardcoded values
- [ ] No TODOs without debt tracking ID
- [ ] Code reviewed
- [ ] Documentation updated

### Review Gate
- [ ] Any "temporary" solutions?
- [ ] Any hardcoded values?
- [ ] Edge cases tested?
- [ ] Would you want to maintain this?

### Automated Detection
```bash
grep -r "TODO\|FIXME\|HACK" src/ | grep -v "TD-[0-9]"  # Untracked TODOs
bandit -r src/                                            # Security issues
pip list --outdated                                       # Stale dependencies
```

### Debt Budget
- Max 10 open items per module
- High-priority: pay within 30 days
- Medium-priority: pay within 90 days
- Low-priority: review quarterly (pay or close)
- Budget exceeded: **stop new features, pay debt first**

## Debt Communication

| Don't Say | Do Say |
|-----------|--------|
| "We have technical debt" | "This shortcut costs us 10 hours/month in bug fixes" |
| "We need to refactor" | "Paying this debt reduces deployment from 2h to 15min" |
| "The code is messy" | "New features take 3x longer; investing 1 week saves 2 weeks/quarter" |
| "We should rewrite it" | "Incremental fixes over 3 sprints eliminate 80% of incidents" |

See `references/debt-communication.md` for standup, sprint planning, and retrospective templates.

## Anti-Patterns

| Anti-Pattern | Fix |
|-------------|-----|
| Debt Bankruptcy ("rewrite from scratch") | Incremental refactoring with tests |
| Hidden Debt (shortcuts without docs) | Document immediately, assign ID |
| Eternal TODOs (years-old comments) | Convert to tracked items or delete |
| Debt as Excuse ("can't add features") | Quantify impact, prioritize, schedule |

## Reference Files

- `references/debt-examples.md` - Before/after examples (TD-050, TD-051, TD-052)
- `references/debt-communication.md` - Team communication templates
