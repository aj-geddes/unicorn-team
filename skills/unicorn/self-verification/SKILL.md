---
name: self-verification
description: >
  Quality assurance protocol for code before every commit. Use this skill
  when preparing to commit changes. Triggers: "review my code", "before commit",
  "self-review", "quality check", "am I ready to commit?". Enforces comprehensive
  verification of functionality, quality, testing, security, and documentation
  through systematic checklist and fresh-eyes techniques.
---

# Self-Verification: The Quality Multiplier

## Core Principle

**Never commit code you wouldn't approve in a code review.**

Your brain lies. It sees what it expects to see, not what's actually there. Self-verification breaks this pattern through systematic review protocols and cognitive techniques that force careful inspection.

---

## Before Every Commit Checklist

Execute this checklist before EVERY commit. No exceptions.

### 1. Review the Staged Changes

```bash
# View what you're about to commit
git diff --staged

# Read it as if someone else wrote it
# Pretend you're the reviewer, not the author
```

**Ask yourself:**
- [ ] Would I approve this in code review?
- [ ] Does this change do ONE thing well?
- [ ] Is the change focused or sprawling?

### 2. Completeness Check

Verify the implementation is actually complete:

- [ ] **Functionality**: Does it do what was requested?
- [ ] **Edge Cases**: Handled or explicitly documented as out-of-scope?
- [ ] **Error Handling**: All failure paths covered?
- [ ] **Error Messages**: Clear, actionable, no stack traces to users?
- [ ] **Logging**: Key operations logged with appropriate level?
- [ ] **Input Validation**: All inputs validated at boundaries?
- [ ] **Output Encoding**: Outputs properly encoded/sanitized?

**Common Incompleteness Traps:**
```python
# INCOMPLETE: Only happy path
def process_user(user_id):
    user = db.get_user(user_id)
    return user.email

# COMPLETE: Handles edge cases
def process_user(user_id):
    """Get user email by ID.

    Returns:
        str: User email address

    Raises:
        ValueError: If user_id is invalid
        UserNotFoundError: If user doesn't exist
    """
    if not user_id or user_id < 0:
        raise ValueError(f"Invalid user_id: {user_id}")

    user = db.get_user(user_id)
    if not user:
        logger.warning(f"User not found: {user_id}")
        raise UserNotFoundError(f"No user with id {user_id}")

    logger.info(f"Retrieved user email for {user_id}")
    return user.email
```

### 3. Quality Check

Scan for quality issues that slip through during implementation:

- [ ] **No TODOs/FIXMEs/HACKs**: Resolve or file tickets, don't commit
- [ ] **No Debug Code**: Remove print(), console.log(), breakpoint(), pdb
- [ ] **No Commented Code**: Delete it (it's in git history)
- [ ] **Clear Names**: Variables, functions, classes are self-documenting
- [ ] **Focused Functions**: Each does one thing well (< 50 lines ideal)
- [ ] **No Magic Numbers**: Extract to named constants
- [ ] **Consistent Style**: Follows project conventions

**Automatic Checks:**
```bash
# Search for debug artifacts
git diff --cached | grep -E "breakpoint|pdb|console\.log|debugger|TODO|FIXME|HACK"

# If anything found, clean it up before committing
```

### 4. Test Verification

Tests are your safety net. Verify it's strong:

- [ ] **All Tests Pass**: Run the full test suite
- [ ] **Coverage ≥ 80%**: New code is adequately tested
- [ ] **Edge Cases Tested**: Not just happy path
- [ ] **Error Paths Tested**: Verify error handling works
- [ ] **Tests Are Clear**: Test names describe what they verify
- [ ] **No Flaky Tests**: Tests pass consistently, not randomly

**TDD Red-Green-Refactor Verification:**
```bash
# Verify you followed TDD
git log --oneline -5 | grep -E "test|feat"

# Should see pattern: test → implementation → refactor
```

**Coverage Command:**
```bash
# Python
pytest --cov=. --cov-report=term-missing --cov-fail-under=80

# JavaScript
npm test -- --coverage --coverageThreshold='{"global":{"lines":80}}'

# Go
go test -cover ./... | grep -E "coverage: [0-9]+\.[0-9]+%"
```

### 5. Security Check

Think like an attacker before they do:

- [ ] **No Secrets**: No API keys, passwords, tokens in code
- [ ] **No Sensitive Data**: No PII, credentials in logs
- [ ] **Inputs Validated**: All external inputs validated
- [ ] **Outputs Encoded**: SQL params, HTML escaped, URL encoded
- [ ] **Auth Required**: Protected endpoints enforce authentication
- [ ] **Least Privilege**: Code runs with minimum required permissions
- [ ] **Audit Logging**: Security-relevant actions are logged

**Security Scan:**
```bash
# Python
bandit -r . -q

# JavaScript
npm audit

# Check for leaked secrets
git diff --cached | grep -iE "api[_-]?key|password|secret|token"
```

**Security Questions:**
1. Who can call this? (Authentication)
2. Are they allowed to? (Authorization)
3. What if they send malicious input? (Validation)
4. What if they send huge input? (Resource limits)
5. Can they see data they shouldn't? (Data exposure)
6. Will we know if they try? (Audit logging)

### 6. Documentation Check

Code is written once, read hundreds of times:

- [ ] **Public APIs Documented**: All public functions/classes have docstrings
- [ ] **Complex Logic Explained**: Non-obvious code has comments explaining WHY
- [ ] **Examples Provided**: Usage examples for complex APIs
- [ ] **README Updated**: If external behavior changed
- [ ] **CHANGELOG Updated**: User-visible changes noted
- [ ] **Migration Guide**: If breaking changes exist

**Documentation Standards:**
```python
def transform_data(input_data: dict, config: Config) -> dict:
    """Transform input data according to configuration.

    Args:
        input_data: Raw input dictionary with keys 'id', 'name', 'values'
        config: Configuration object specifying transformation rules

    Returns:
        Transformed dictionary with normalized keys and filtered values

    Raises:
        ValueError: If input_data missing required keys
        ConfigError: If config has invalid transformation rules

    Example:
        >>> config = Config(normalize=True, filter_nulls=True)
        >>> transform_data({'id': 1, 'name': 'test'}, config)
        {'id': 1, 'name': 'test'}
    """
    # Implementation...
```

---

## The "Fresh Eyes" Technique

Your brain fills in gaps and sees what you intended, not what you wrote. Break this pattern:

### 1. Time Gap (10+ Minutes)

**Why**: Your brain needs to "forget" what you meant to write.

**How**:
- Write code
- Commit to staging: `git add .`
- Take a break (coffee, walk, different task)
- Return and review `git diff --staged` with fresh perspective

### 2. Context Switch

**Why**: Breaking mental context reveals assumptions and gaps.

**How**:
- Work on feature A
- Switch to different task for 15+ minutes
- Return to feature A for review
- Notice things you missed while "in the zone"

### 3. Read Aloud

**Why**: Speaking forces slower, more deliberate processing.

**How**:
- Read your code out loud
- Explain what each section does
- If you stumble or have to re-read, that's a red flag
- Simplify or add comments to clarify

**Example:**
```python
# Hard to read aloud without stumbling
data = [x for x in map(lambda y: y**2 if y%2 else y**3, filter(lambda z: z>0, vals))]

# Easy to read aloud
positive_values = [v for v in vals if v > 0]
data = [v**2 if v % 2 else v**3 for v in positive_values]
```

### 4. Rubber Duck Debugging

**Why**: Teaching forces you to be explicit about logic and assumptions.

**How**:
- Explain the code to an imaginary colleague (or rubber duck)
- Walk through the logic step by step
- Justify each decision
- Often reveals bugs during explanation

**Template:**
```
"This function takes [X] and returns [Y].
First it validates [Z] because...
Then it processes [A] by...
The tricky part is [B] which handles the case where...
It could fail if [C], which we handle by...
I chose this approach over [D] because..."
```

### 5. Reverse Review

**Why**: Breaking narrative flow reveals bugs your brain glosses over.

**How**:
- Start reading from the LAST line of the diff
- Work backwards to the first line
- Breaks the "story" your brain constructed
- Forces evaluation of each line independently

---

## Self-Review Script

Use this script before every commit:

```bash
#!/bin/bash
# scripts/self-review.sh

set -euo pipefail

echo "🔄 Self-Review Protocol"
echo "======================"

# 1. Show what's staged
echo ""
echo "📝 Staged Changes:"
git diff --cached --stat

# 2. Completeness verification
echo ""
echo "✅ COMPLETENESS CHECK"
echo "  [ ] Functionality complete?"
echo "  [ ] Edge cases handled?"
echo "  [ ] Error handling complete?"
echo "  [ ] Logging added?"

read -p "Completeness verified? (y/n) " -n 1 -r
echo
[[ ! $REPLY =~ ^[Yy]$ ]] && echo "❌ Complete the implementation first" && exit 1

# 3. Quality scan
echo ""
echo "🔍 QUALITY CHECK"
echo "Scanning for debug code and markers..."

if git diff --cached | grep -E "breakpoint|pdb|console\.log|debugger|TODO|FIXME|HACK"; then
    echo "❌ Found debug code or markers - clean up before commit"
    exit 1
fi
echo "✅ No debug code or markers found"

# 4. Test verification
echo ""
echo "🧪 TEST VERIFICATION"
echo "Running tests with coverage..."

if command -v pytest &> /dev/null; then
    pytest --cov=. --cov-fail-under=80 -q || {
        echo "❌ Tests failed or coverage too low"
        exit 1
    }
elif command -v npm &> /dev/null && [ -f "package.json" ]; then
    npm test || {
        echo "❌ Tests failed"
        exit 1
    }
fi
echo "✅ Tests passed"

# 5. Security scan
echo ""
echo "🔒 SECURITY CHECK"
echo "Scanning for secrets and vulnerabilities..."

if git diff --cached | grep -iE "api[_-]?key|password|secret|token" | grep -v "^-"; then
    echo "⚠️  Possible secrets detected - verify these are safe"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

# 6. Final review
echo ""
echo "👀 FINAL CHECKLIST"
echo "  [ ] Does this change do ONE thing well?"
echo "  [ ] Are all edge cases handled?"
echo "  [ ] Is error handling complete?"
echo "  [ ] Are tests comprehensive?"
echo "  [ ] Is documentation updated?"
echo "  [ ] Would I approve this in code review?"

echo ""
echo "🔍 Review the detailed diff:"
git diff --cached

echo ""
read -p "Ready to commit? (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "✅ Self-review complete - proceed with commit"
    exit 0
else
    echo "❌ Self-review incomplete - continue working"
    exit 1
fi
```

**Usage:**
```bash
# Before commit
./scripts/self-review.sh && git commit -m "your message"
```

---

## Common Self-Review Failures

### Failure: "Works on My Machine"

**Symptom**: Code works locally but fails in CI/CD or production.

**Prevention**:
- Run tests in clean environment (docker, new virtualenv)
- Verify all dependencies declared
- Check for hardcoded paths or environment assumptions
- Test with production-like data

### Failure: Missing Edge Cases

**Symptom**: Tests pass but code breaks with unexpected input.

**Prevention**:
- Test with: null, empty, negative, huge, invalid types
- Fuzz test with random inputs
- Ask "what would break this?"

**Edge Case Checklist:**
```python
# For every function, test:
- None/null input
- Empty collection ([], {}, "")
- Single item
- Boundary values (0, -1, MAX_INT)
- Invalid types
- Concurrent access
- Resource exhaustion
```

### Failure: Unclear Intent

**Symptom**: You can't explain what the code does without looking at it.

**Prevention**:
- If you have to read the code to understand it, add comments
- Extract complex logic to well-named functions
- Use descriptive variable names

**Example:**
```python
# UNCLEAR
if t > 86400 and t < 604800:
    return True

# CLEAR
SECONDS_PER_DAY = 86400
SECONDS_PER_WEEK = 604800

def is_within_week(timestamp_seconds: int) -> bool:
    """Check if timestamp is between 1 day and 1 week ago."""
    return SECONDS_PER_DAY < timestamp_seconds < SECONDS_PER_WEEK
```

### Failure: Incomplete Error Handling

**Symptom**: Code works until first error, then crashes ungracefully.

**Prevention**:
- Identify all failure points
- Handle or propagate each one
- Log errors with context
- Return meaningful error messages

**Error Handling Checklist:**
- [ ] Network failures
- [ ] Database failures
- [ ] Invalid input
- [ ] Missing resources
- [ ] Timeout/slow response
- [ ] Concurrent modification
- [ ] Resource exhaustion

---

## Integration with Pre-Commit Hook

Automate as much as possible:

```bash
#!/bin/bash
# hooks/pre-commit

set -euo pipefail

echo "🔍 Pre-commit validation..."

# 1. Lint check
if command -v ruff &> /dev/null; then
    ruff check . || exit 1
fi

# 2. Type check
if command -v mypy &> /dev/null; then
    mypy . --ignore-missing-imports || exit 1
fi

# 3. Tests with coverage
pytest --cov=. --cov-fail-under=80 -q || exit 1

# 4. Security scan
if command -v bandit &> /dev/null; then
    bandit -r . -q || exit 1
fi

# 5. No debug code
if git diff --cached | grep -E "breakpoint\(\)|import pdb|console\.log|debugger"; then
    echo "❌ Found debug code!"
    exit 1
fi

# 6. No TODO markers
if git diff --cached --name-only | xargs grep -l "TODO\|FIXME\|HACK" 2>/dev/null; then
    echo "⚠️  Found TODO/FIXME/HACK - resolve before commit"
    exit 1
fi

echo "✅ Pre-commit validation passed!"
```

**Install:**
```bash
chmod +x hooks/pre-commit
ln -sf ../../hooks/pre-commit .git/hooks/pre-commit
```

---

## Self-Verification Metrics

Track your self-review effectiveness:

### Catch Rate

**Metric**: Percentage of bugs caught in self-review vs. code review.

**Target**: > 90%

**Track**:
```yaml
self_review_log:
  date: 2025-01-15
  feature: user-authentication
  issues_found_self: 4
  issues_found_review: 0
  catch_rate: 100%
```

### Review Time

**Metric**: Time spent in self-review per commit.

**Target**: 5-10 minutes per commit

**Track**: Too fast = shallow review, too slow = need better techniques

### Commit Revisions

**Metric**: How often you amend commits after self-review.

**Target**: < 10%

**Track**: High rate indicates rushing through self-review

---

## When NOT to Self-Review

Self-review is essential, but timing matters:

**Don't Review Immediately:**
- Right after writing code (brain still in "write" mode)
- When tired or rushed (quality suffers)
- When distracted (you'll miss things)

**Do Review:**
- After a break (fresh perspective)
- In the morning (if wrote code at night)
- Before asking for code review (respect others' time)
- Before deploying (last safety check)

---

## Summary: The Self-Review Mindset

```
┌─────────────────────────────────────────────────────────┐
│  "Would I approve this in code review?"                 │
│                                                          │
│  If the answer isn't an immediate "YES", keep working.  │
│                                                          │
│  Self-review is not a formality.                        │
│  It's your reputation on the line.                      │
└─────────────────────────────────────────────────────────┘
```

**Key Principles:**

1. **Be Your Own Harshest Critic** - You should find bugs before reviewers do
2. **Use Fresh Eyes** - Time gap, context switch, read aloud
3. **Systematic, Not Random** - Follow the checklist every time
4. **Automate What You Can** - Let tools catch mechanical issues
5. **Quality Over Speed** - 10 minutes now saves hours later

**The 10X Difference:**

- 1X Developer: Writes code and commits immediately
- 10X Developer: Writes code, reviews it carefully, catches issues, commits quality code

The self-review step is what separates good code from great code. It's the difference between "works on my machine" and "works in production."
