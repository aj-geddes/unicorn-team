---
name: technical-debt
description: >
  Manage technical debt deliberately: recognize, track, and pay down shortcuts
  and compromises. Use when you need to take a shortcut, see "just for now"
  comments, copy-paste code, hardcoded values, missing tests, or when planning
  debt paydown. Tracks deliberate tradeoffs, calculates ongoing interest cost,
  and prioritizes repayment by impact/effort ratio.
---

# Technical Debt Management

Technical debt isn't just "bad code"—it's a deliberate tradeoff between speed and quality. This skill helps you recognize, track, and systematically pay down debt.

## The Debt Quadrant

```
                    Reckless                    Prudent
              ┌─────────────────────┬─────────────────────┐
              │                     │                     │
 Deliberate   │  "We don't have    │  "We must ship      │
              │   time for tests"   │   now and deal      │
              │                     │   with consequences"│
              │   [DANGEROUS]       │   [STRATEGIC]       │
              ├─────────────────────┼─────────────────────┤
              │                     │                     │
 Inadvertent  │  "What's a         │  "Now we know how   │
              │   design pattern?"  │   we should have    │
              │                     │   done it"          │
              │   [INCOMPETENCE]    │   [LEARNING]        │
              └─────────────────────┴─────────────────────┘
```

**Target quadrant**: Prudent + Deliberate (strategic tradeoffs)
**Acceptable**: Inadvertent + Prudent (learning experiences)
**Dangerous**: Reckless + Deliberate (shortcuts without planning)
**Unacceptable**: Reckless + Inadvertent (lack of skill)

## Debt Recognition Signals

Recognize debt before it compounds:

### Code Smells
- "Just for now" or "temporary" comments
- Copy-paste code blocks (DRY violation)
- Commented-out code
- TODOs, FIXMEs, HACKs without tracking
- Magic numbers or hardcoded configuration
- Broad exception catching (`except: pass`)
- Missing error handling
- No input validation

### Test Smells
- Missing test coverage
- Tests disabled or skipped
- No edge case tests
- No integration tests
- Manual-only testing

### Architecture Smells
- Tight coupling between modules
- Circular dependencies
- God objects/classes
- Feature envy (method uses another class more than its own)
- Data clumps (same group of variables passed together)

### Infrastructure Smells
- Outdated dependencies
- Security vulnerabilities
- No monitoring/logging
- Manual deployment steps
- Secrets in code
- No backup/recovery plan

## Debt Tracking Template

Document every debt item using this format:

```yaml
technical_debt_item:
  id: TD-042
  type: deliberate  # deliberate or inadvertent
  quadrant: prudent-deliberate  # quadrant from matrix above

  location: src/auth/login.py:45-89

  description: >
    Hardcoded session timeout to 30 minutes. Should be configurable
    per environment (dev=long, prod=short).

  why_taken: >
    Needed to ship authentication feature for demo. Configuration
    system not ready yet.

  impact:
    - Cannot adjust timeout without redeployment
    - Different environments need different values
    - Users complain about frequent re-logins in dev
    - Security team wants shorter timeout in prod

  interest: >
    Every timeout-related issue requires code change, build, and deploy.
    Approximately 2 hours per incident. Estimated 3 incidents per month.

  payoff_plan:
    effort: 2 hours
    tasks:
      - Add timeout config to settings file
      - Update login.py to read from config
      - Add tests for different timeout values
      - Document configuration option
      - Deploy to all environments

  priority: high  # high/medium/low (based on interest cost)

  created: 2025-01-15
  owner: @developer
  due_date: 2025-02-01  # when must this be paid

  dependencies:
    - Configuration system (PR #123)

  status: tracked  # tracked/scheduled/in_progress/paid
```

## Debt Lifecycle Protocol

### 1. Identification

Identify debt when:
- Taking a shortcut to meet deadline
- Discovering suboptimal code during review
- Encountering "surprising" behavior
- Seeing repeated patterns that should be abstracted
- Finding security or performance issues

Ask:
- Is this deliberate or inadvertent?
- Is this prudent or reckless?
- What's the ongoing cost (interest)?
- When will this hurt us?

### 2. Documentation

Create debt entry immediately:
- Assign unique ID (TD-XXX)
- Document location precisely (file:line-line)
- Explain WHY the debt was taken
- List concrete impacts
- Calculate interest (ongoing cost)
- Estimate payoff effort

Add inline comment with debt ID:
```python
# TODO(TD-042): Hardcoded timeout, see debt tracker
SESSION_TIMEOUT = 1800  # 30 minutes
```

### 3. Interest Calculation

Calculate ongoing cost (interest):

```python
def calculate_interest(debt_item):
    """
    Interest = frequency of pain × cost per incident
    """
    frequency = {
        'daily': 365,
        'weekly': 52,
        'monthly': 12,
        'quarterly': 4,
        'yearly': 1,
    }

    cost_per_incident = estimate_time_cost()  # hours
    incidents_per_year = frequency[debt_item.frequency]

    annual_interest = cost_per_incident * incidents_per_year
    return annual_interest
```

Examples:
- Hardcoded config: 2 hours per incident × 3/month = 72 hours/year
- Missing tests: 1 hour per bug × 10/month = 120 hours/year
- Copy-paste code: 30 min per change × 20/month = 120 hours/year

### 4. Prioritization

Prioritize by ROI (return on investment):

```
Priority Score = (Annual Interest) / (Payoff Effort)

High Priority:    Score > 10   (pays back in < 1 month)
Medium Priority:  Score 3-10   (pays back in 3-4 months)
Low Priority:     Score < 3    (pays back in > 4 months)
```

Examples:
- Missing validation: 120 hours interest ÷ 2 hours effort = **60** (HIGH)
- Hardcoded config: 72 hours interest ÷ 2 hours effort = **36** (HIGH)
- Refactor structure: 20 hours interest ÷ 16 hours effort = **1.25** (LOW)

### 5. Payment Planning

Schedule debt payment:

**Sprint 0 Rule**: Address high-priority debt before new features
**20% Rule**: Allocate 20% of sprint capacity to debt reduction
**Boy Scout Rule**: Fix small debt when you touch nearby code

Payment workflow:
```bash
# 1. Create branch for debt payment
git checkout -b debt/TD-042-configurable-timeout

# 2. Write tests first (characterize current behavior)
pytest test_login.py -v

# 3. Make incremental changes
# - Add configuration option
# - Update code to use config
# - Update tests
# - Update documentation

# 4. Verify behavior unchanged (except intended improvements)
pytest test_login.py -v
pytest test_integration.py -v

# 5. Update debt tracker
# status: tracked → paid
# paid_date: 2025-01-20
# actual_effort: 2.5 hours

# 6. Commit with debt ID in message
git commit -m "fix(TD-042): make session timeout configurable

- Add TIMEOUT_SECONDS to settings
- Update login to read from config
- Add tests for custom timeouts
- Document configuration option

Closes TD-042"
```

### 6. Verification

Verify debt is actually paid:
- [ ] Root cause addressed (not just symptom)
- [ ] Tests added to prevent regression
- [ ] Documentation updated
- [ ] No new debt introduced
- [ ] Debt tracker updated to "paid"
- [ ] Inline TODO comments removed

## The Boy Scout Rule

> Leave the code better than you found it.

Apply when touching existing code:

### Small Improvements (Do These)
```python
# Before: Unclear variable name
x = get_data()

# After: Clear variable name
user_sessions = get_data()
```

```python
# Before: Missing docstring
def process(data):
    return transform(data)

# After: Add docstring
def process(data):
    """Transform raw data into normalized format."""
    return transform(data)
```

```python
# Before: Magic number
if elapsed > 1800:
    expire_session()

# After: Named constant
SESSION_TIMEOUT_SECONDS = 1800
if elapsed > SESSION_TIMEOUT_SECONDS:
    expire_session()
```

### Large Changes (Don't Mix With Features)
- Don't refactor entire module while adding feature
- Don't change architecture during bug fix
- Don't rewrite code you don't understand

Separate commits:
1. First commit: Feature/fix only
2. Second commit: Refactoring only

## Debt Prevention Strategies

### 1. Definition of Done

Require before marking work complete:
- [ ] Tests written and passing
- [ ] Code reviewed
- [ ] Documentation updated
- [ ] Error handling added
- [ ] Logging/monitoring added
- [ ] Security reviewed
- [ ] Performance acceptable
- [ ] No TODOs without debt tracking

### 2. Review Checklist

Check in every code review:
- Are there "temporary" solutions?
- Are there hardcoded values?
- Is error handling present?
- Are edge cases tested?
- Is the code understandable?
- Would you want to maintain this?

### 3. Automated Detection

Use tools to catch debt:

```bash
# Find untracked TODOs
grep -r "TODO\|FIXME\|HACK" src/ | grep -v "TD-[0-9]"

# Find hardcoded values
pylint --disable=all --enable=C0103,C0326

# Find missing docstrings
pydocstyle src/

# Find security issues
bandit -r src/

# Find outdated dependencies
pip list --outdated
```

### 4. Debt Budget

Set limits:
- Maximum 10 open debt items per module
- Maximum 30 days for high-priority debt
- Maximum 90 days for medium-priority debt
- Review low-priority debt quarterly (pay or close)

If budget exceeded: **Stop new features, pay debt first**

## Debt Communication

### Team Communication

**Daily standup**: Report debt discovered
```
"Found TD-045: authentication flow has no rate limiting.
High priority, 4 hours to fix. Should we address this sprint?"
```

**Sprint planning**: Review debt backlog
```
"We have 5 high-priority debt items totaling 12 hours.
Recommend allocating 20% of sprint (8 hours) to pay top 3."
```

**Retrospective**: Analyze debt trends
```
"We created 8 debt items this sprint but only paid 2.
Debt is accumulating. What's preventing paydown?"
```

### Stakeholder Communication

Translate technical debt to business impact:

**Don't say**: "We have technical debt"
**Do say**: "This shortcut costs us 10 hours per month in bug fixes"

**Don't say**: "We need to refactor"
**Do say**: "Paying this debt will reduce deployment time from 2 hours to 15 minutes"

**Don't say**: "The code is messy"
**Do say**: "New features take 3x longer due to complexity. Investing 1 week now saves 2 weeks per quarter"

## Metrics and Tracking

Track these metrics:

```yaml
debt_metrics:
  # Volume
  total_items: 23
  by_priority:
    high: 5
    medium: 12
    low: 6

  # Financial
  total_annual_interest: 450 hours  # ongoing cost
  total_payoff_effort: 180 hours    # one-time cost

  # Velocity
  created_this_month: 8
  paid_this_month: 3
  net_change: +5  # DANGER: accumulating

  # Age
  average_age_days: 45
  oldest_item_days: 120
  overdue_items: 2  # past due_date

  # ROI
  highest_roi_item: TD-023  # score: 50
  total_paid_this_quarter: 45 hours effort
  estimated_savings: 180 hours/year interest
```

**Red flags**:
- Net change positive (more created than paid)
- Overdue high-priority items
- Average age increasing
- Total interest > 20% of team capacity

## Anti-Patterns

### Debt Bankruptcy

**Symptom**: "Let's just rewrite it from scratch"

**Problem**:
- Throws away working (if ugly) code
- Loses tribal knowledge
- Takes 3x longer than estimated
- Introduces new bugs
- Creates new debt

**Solution**: Incremental refactoring with tests

### Hidden Debt

**Symptom**: Shortcuts without documentation

**Problem**:
- No one knows debt exists until it breaks
- Can't prioritize or plan paydown
- Accumulates silently

**Solution**: Make debt visible immediately

### Eternal TODOs

**Symptom**: TODO comments from years ago

**Problem**:
- No tracking or accountability
- No effort estimate
- No priority
- Noise in codebase

**Solution**: Convert to tracked debt items or delete

### Debt as Excuse

**Symptom**: "We can't add features because of technical debt"

**Problem**:
- Debt used to avoid work
- No data on actual impact
- No plan to pay down

**Solution**: Quantify impact, prioritize, schedule paydown

## Examples

### Example 1: Configuration Hardcoded

```python
# BEFORE (debt created)
# TODO: Make this configurable
DATABASE_URL = "postgresql://localhost:5432/mydb"
```

```yaml
# Debt tracking
technical_debt_item:
  id: TD-050
  type: deliberate
  location: src/config.py:12
  description: Database URL hardcoded
  why_taken: Needed for MVP demo
  impact:
    - Cannot deploy to staging/prod
    - Cannot test with different databases
  interest: 5 hours/month (env issues)
  payoff_effort: 1 hour
  priority: high
```

```python
# AFTER (debt paid)
import os

DATABASE_URL = os.getenv(
    'DATABASE_URL',
    'postgresql://localhost:5432/mydb'  # dev default
)
```

### Example 2: Missing Tests

```python
# BEFORE (debt exists)
def process_payment(amount, card):
    # TODO: Add tests
    response = gateway.charge(amount, card)
    return response.success
```

```yaml
technical_debt_item:
  id: TD-051
  type: inadvertent
  location: src/payments.py:34-38
  description: process_payment has no tests
  impact:
    - Cannot refactor safely
    - Bugs caught in production
    - No validation of edge cases
  interest: 8 hours/month (bug fixes)
  payoff_effort: 3 hours
  priority: high
```

```python
# AFTER (debt paid)
def process_payment(amount, card):
    """
    Process payment through gateway.

    Args:
        amount: Payment amount in cents (positive integer)
        card: Card token from payment form

    Returns:
        bool: True if payment successful

    Raises:
        ValueError: If amount invalid
        PaymentError: If gateway rejects
    """
    if amount <= 0:
        raise ValueError("Amount must be positive")

    response = gateway.charge(amount, card)
    return response.success

# tests/test_payments.py
def test_process_payment_success():
    assert process_payment(1000, valid_card) == True

def test_process_payment_rejects_negative():
    with pytest.raises(ValueError):
        process_payment(-100, valid_card)

def test_process_payment_handles_gateway_error():
    with pytest.raises(PaymentError):
        process_payment(1000, invalid_card)
```

### Example 3: Copy-Paste Code

```python
# BEFORE (debt exists)
def format_user_name(user):
    # TODO(TD-052): DRY violation
    if user.middle_name:
        return f"{user.first_name} {user.middle_name} {user.last_name}"
    return f"{user.first_name} {user.last_name}"

def format_author_name(author):
    # TODO(TD-052): Same logic as format_user_name
    if author.middle_name:
        return f"{author.first_name} {author.middle_name} {author.last_name}"
    return f"{author.first_name} {author.last_name}"
```

```yaml
technical_debt_item:
  id: TD-052
  type: inadvertent
  location: src/formatters.py:10-20
  description: Name formatting duplicated
  impact:
    - Must change in two places
    - Inconsistent formatting
  interest: 1 hour/month (bug fixes)
  payoff_effort: 0.5 hours
  priority: medium
```

```python
# AFTER (debt paid)
def format_full_name(person):
    """
    Format person's full name with optional middle name.

    Args:
        person: Object with first_name, last_name, middle_name

    Returns:
        str: Formatted full name
    """
    parts = [person.first_name]
    if person.middle_name:
        parts.append(person.middle_name)
    parts.append(person.last_name)
    return " ".join(parts)

# Use for all name formatting
format_user_name = format_full_name
format_author_name = format_full_name
```

## Summary

Technical debt is inevitable. The key is making it:
1. **Deliberate** - Conscious tradeoffs, not accidents
2. **Tracked** - Visible and quantified
3. **Prioritized** - Paid based on impact/effort
4. **Temporary** - Scheduled for paydown
5. **Communicated** - Team and stakeholders aware

Remember:
- Not all shortcuts are bad (strategic debt can be good)
- Track interest cost, not just existence
- Pay high-ROI debt first
- Prevent new debt through quality practices
- Never let debt accumulate silently
