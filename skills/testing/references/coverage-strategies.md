# Coverage Strategies

Advanced coverage techniques, mutation testing, and coverage-driven development strategies.

## Understanding Coverage Types

### Line Coverage

**Definition:** Percentage of code lines executed during tests.

**Example:**
```python
def calculate_discount(price, customer_type):
    if customer_type == "vip":        # Line 1 - Executed
        discount = 0.20               # Line 2 - Executed if VIP
    else:
        discount = 0.10               # Line 3 - Executed if not VIP
    return price * (1 - discount)     # Line 4 - Always executed

# Test with VIP customer
def test_vip_discount():
    assert calculate_discount(100, "vip") == 80

# Line coverage: 75% (3 of 4 lines executed)
# Line 3 not executed
```

**Problem:** High line coverage doesn't mean good testing.

### Branch Coverage

**Definition:** Percentage of decision branches (if/else, switch) executed.

**Example:**
```python
def calculate_discount(price, customer_type):
    if customer_type == "vip":
        discount = 0.20
    else:
        discount = 0.10
    return price * (1 - discount)

# Test only VIP path
def test_vip_discount():
    assert calculate_discount(100, "vip") == 80

# Line coverage: 100% (all lines executed)
# Branch coverage: 50% (only if-true branch, not else)
```

**Why better:** Ensures all decision paths are tested.

### Statement Coverage

**Definition:** Each statement executed at least once.

Similar to line coverage but counts statements, not lines:

```python
# One line, two statements
x = 1; y = 2

# Line coverage: 100% (1 line)
# Statement coverage: could be 50% if only x executed
```

### Path Coverage

**Definition:** All possible paths through the code.

**Example:**
```python
def process_order(order):
    if order.is_valid():           # Decision 1
        if order.has_stock():      # Decision 2
            return "processed"
        else:
            return "out of stock"
    else:
        return "invalid"

# Possible paths:
# 1. valid=True, stock=True   -> "processed"
# 2. valid=True, stock=False  -> "out of stock"
# 3. valid=False, (stock=?)   -> "invalid"

# Need 3 tests for 100% path coverage
```

**Problem:** Exponential growth with conditions.

```python
# 4 independent conditions = 2^4 = 16 paths
if condition1:
    if condition2:
        if condition3:
            if condition4:
                # ...
```

**Solution:** Focus on important paths, use branch coverage.

### Condition Coverage

**Definition:** Each boolean sub-expression evaluated to both true and false.

**Example:**
```python
def should_process(is_valid, has_stock):
    if is_valid and has_stock:
        return True
    return False

# Condition coverage requires:
# - is_valid = True
# - is_valid = False
# - has_stock = True
# - has_stock = False

# But not necessarily all combinations
```

### Modified Condition/Decision Coverage (MC/DC)

**Definition:** Each condition independently affects the decision.

**Used in:** Safety-critical software (aviation, medical devices).

**Example:**
```python
def can_fly(weather_ok, fuel_ok, crew_ready):
    return weather_ok and fuel_ok and crew_ready

# MC/DC tests (each condition independently changes outcome):
# weather  fuel  crew  | result
#   T      T     T     |   T     (baseline)
#   F      T     T     |   F     (weather matters)
#   T      F     T     |   F     (fuel matters)
#   T      T     F     |   F     (crew matters)
```

## Coverage Tools by Language

### Python Coverage Tools

#### pytest-cov (Recommended)

```bash
# Install
pip install pytest-cov

# Basic usage
pytest --cov=myapp tests/

# HTML report
pytest --cov=myapp --cov-report=html tests/
# Opens coverage/index.html

# Terminal report with missing lines
pytest --cov=myapp --cov-report=term-missing tests/

# Fail if coverage below threshold
pytest --cov=myapp --cov-fail-under=80 tests/

# Branch coverage
pytest --cov=myapp --cov-branch tests/
```

#### Configuration (.coveragerc)

```ini
[run]
source = myapp
omit =
    */tests/*
    */venv/*
    */migrations/*
    */__pycache__/*

[report]
precision = 2
show_missing = True
skip_covered = False

[html]
directory = coverage_html

[coverage:report]
exclude_lines =
    pragma: no cover
    def __repr__
    raise AssertionError
    raise NotImplementedError
    if __name__ == .__main__.:
    if TYPE_CHECKING:
    @abstractmethod
```

#### Coverage.py (Low-level)

```bash
# Collect coverage
coverage run -m pytest tests/

# Report
coverage report

# HTML report
coverage html

# Combine multiple coverage files
coverage combine

# Erase coverage data
coverage erase
```

### JavaScript Coverage Tools

#### Jest Coverage

```bash
# Run with coverage
jest --coverage

# Coverage for specific files
jest --coverage --collectCoverageFrom='src/**/*.js'

# Watch mode with coverage
jest --coverage --watch
```

#### Configuration (jest.config.js)

```javascript
module.exports = {
  collectCoverage: true,
  collectCoverageFrom: [
    'src/**/*.{js,jsx,ts,tsx}',
    '!src/**/*.d.ts',
    '!src/**/*.test.{js,jsx,ts,tsx}',
    '!src/index.js',
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80,
    },
    './src/critical/': {
      branches: 100,
      functions: 100,
      lines: 100,
      statements: 100,
    },
  },
  coverageReporters: ['text', 'html', 'lcov'],
};
```

#### c8 (V8 Native Coverage)

```bash
# Install
npm install --save-dev c8

# Run with coverage
c8 npm test

# HTML report
c8 --reporter=html npm test

# Multiple reporters
c8 --reporter=text --reporter=html npm test

# Coverage threshold
c8 --check-coverage --lines 80 --functions 80 npm test
```

### Go Coverage

```bash
# Basic coverage
go test -cover ./...

# Coverage profile
go test -coverprofile=coverage.out ./...

# View coverage in browser
go tool cover -html=coverage.out

# Function-level coverage report
go tool cover -func=coverage.out

# Coverage by package
go test -cover ./... -coverprofile=coverage.out
go tool cover -func=coverage.out

# Coverage mode
go test -covermode=count ./...   # Count how many times each statement runs
go test -covermode=atomic ./...  # Thread-safe counting
go test -covermode=set ./...     # Default: was it executed?
```

### Rust Coverage

#### cargo-tarpaulin (Recommended)

```bash
# Install
cargo install cargo-tarpaulin

# Basic coverage
cargo tarpaulin

# HTML report
cargo tarpaulin --out Html

# Multiple formats
cargo tarpaulin --out Xml --out Html

# Coverage threshold
cargo tarpaulin --fail-under 80

# Exclude files
cargo tarpaulin --exclude-files src/generated/*
```

#### llvm-cov (Nightly Rust)

```bash
# Install components
rustup component add llvm-tools-preview

# Install cargo-llvm-cov
cargo install cargo-llvm-cov

# Run coverage
cargo llvm-cov

# HTML report
cargo llvm-cov --html

# Open in browser
cargo llvm-cov --open
```

## Advanced Coverage Strategies

### Coverage-Driven Development

**Process:**
1. Write tests
2. Check coverage
3. Identify uncovered branches
4. Write tests for uncovered code
5. Repeat until target coverage

**Example workflow:**
```bash
# Run tests with coverage
pytest --cov=myapp --cov-report=term-missing

# Output shows:
# myapp/users.py    45      8    82%   23-25, 45-47

# Lines 23-25 and 45-47 not covered
# Write tests for those lines

def test_user_edge_case():
    # Covers lines 23-25
    user = User(email="")
    with pytest.raises(ValidationError):
        user.validate()

# Re-run coverage
pytest --cov=myapp --cov-report=term-missing
# Now: myapp/users.py    45      5    89%   45-47
```

### Mutation Testing

**Concept:** Introduce bugs (mutations) to verify tests catch them.

**If tests still pass after mutation → Test is weak**

#### Python - mutmut

```bash
# Install
pip install mutmut

# Run mutation testing
mutmut run

# Show results
mutmut results

# Show specific mutation
mutmut show 1

# Apply mutation to see what changed
mutmut apply 1

# HTML report
mutmut html
```

**Example:**
```python
# Original code
def is_adult(age):
    return age >= 18

# Mutant 1: Change >= to >
def is_adult(age):
    return age > 18  # Bug: 18-year-old not considered adult

# Test
def test_is_adult():
    assert is_adult(25) is True
    # This passes for both original and mutant!
    # Test is weak - doesn't test boundary

# Better test
def test_is_adult():
    assert is_adult(17) is False
    assert is_adult(18) is True   # Catches mutant
    assert is_adult(19) is True
```

#### JavaScript - Stryker

```bash
# Install
npm install --save-dev @stryker-mutator/core @stryker-mutator/jest-runner

# Initialize
npx stryker init

# Run
npx stryker run
```

**stryker.conf.json:**
```json
{
  "mutate": ["src/**/*.js"],
  "testRunner": "jest",
  "reporters": ["html", "clear-text", "progress"],
  "coverageAnalysis": "perTest",
  "thresholds": {
    "high": 80,
    "low": 60,
    "break": 50
  }
}
```

#### Mutation Operators

Common mutations:
- **Arithmetic:** `+` → `-`, `*` → `/`
- **Relational:** `>` → `>=`, `==` → `!=`
- **Logical:** `&&` → `||`, `!x` → `x`
- **Constant:** `0` → `1`, `true` → `false`
- **Statement deletion:** Remove line
- **Return value:** `return x` → `return null`

### Differential Coverage

**Concept:** Only check coverage for changed code.

**Use case:** Pull request reviews - ensure new code is tested.

#### Python - diff-cover

```bash
# Install
pip install diff-cover

# Generate coverage report
pytest --cov=myapp --cov-report=xml

# Check coverage for changed files
diff-cover coverage.xml --compare-branch=main --fail-under=100

# HTML report
diff-cover coverage.xml --compare-branch=main --html-report=diff-cover.html
```

#### JavaScript - jest-diff-coverage

```bash
# Install
npm install --save-dev jest-coverage-comment

# In CI (GitHub Actions)
- name: Jest Coverage Comment
  uses: ArtiomTr/jest-coverage-report-action@v2
```

### Critical Path Coverage

**Strategy:** Ensure 100% coverage for critical code, 80% overall.

**Example configuration:**
```javascript
// jest.config.js
module.exports = {
  coverageThreshold: {
    global: {
      lines: 80,
      branches: 80,
    },
    './src/payment/': {
      lines: 100,
      branches: 100,
      functions: 100,
    },
    './src/auth/': {
      lines: 100,
      branches: 100,
      functions: 100,
    },
  },
};
```

```python
# pytest.ini
[coverage:run]
source = myapp

[coverage:report]
fail_under = 80

# Critical paths require 100% - enforced in CI
# pytest --cov=myapp/payment --cov-fail-under=100
```

### Coverage Exclusions

**What to exclude:**
- Debug code
- Abstract methods
- Defensive assertions
- Type checking code
- `__repr__`, `__str__`

**Python:**
```python
def process_data(data):
    if not data:  # pragma: no cover
        # Should never happen, defensive check
        raise ValueError("Data required")

    # Normal processing
    return transform(data)

def __repr__(self):  # pragma: no cover
    return f"User({self.email})"

if TYPE_CHECKING:  # pragma: no cover
    from typing import Optional
```

**JavaScript:**
```javascript
function processData(data) {
  /* istanbul ignore next */
  if (!data) {
    // Should never happen
    throw new Error('Data required');
  }

  return transform(data);
}
```

## Coverage Anti-Patterns

### Chasing 100% Coverage

**Problem:**
```python
# Pointless test just for coverage
def test_user_repr():
    user = User(email="test@example.com")
    repr(user)  # Just calling it for coverage
    # Not asserting anything useful
```

**Solution:** Focus on behavior, not coverage number.

### Testing Getters/Setters

**Problem:**
```python
class User:
    def __init__(self, name):
        self.name = name

    def get_name(self):
        return self.name

# Pointless test
def test_get_name():
    user = User("Alice")
    assert user.get_name() == "Alice"
```

**Solution:** Only test complex getters/setters with logic.

### Coverage Without Assertions

**Problem:**
```python
def test_user_creation():
    user = User("test@example.com")
    # No assertions!
    # Coverage shows line executed, but not tested
```

**Solution:** Always assert expected behavior.

### Ignoring Branch Coverage

**Problem:**
```python
def calculate_discount(price, is_vip):
    if is_vip:
        return price * 0.8
    return price * 0.9

# Only tests VIP path
def test_vip_discount():
    assert calculate_discount(100, True) == 80
# Line coverage: 100%
# Branch coverage: 50% (missing else branch)
```

**Solution:** Check branch coverage, not just line coverage.

## Coverage Best Practices

### 1. Set Realistic Thresholds

```bash
# Start where you are
pytest --cov=myapp
# Current coverage: 65%

# Set threshold slightly higher
pytest --cov=myapp --cov-fail-under=70

# Gradually increase
# 70% → 75% → 80% → 85%
```

### 2. Track Coverage Over Time

```bash
# Save coverage to file
pytest --cov=myapp --cov-report=json:coverage.json

# In CI, compare to previous coverage
# Fail if coverage decreases
```

### 3. Focus on Branch Coverage

```bash
# Python
pytest --cov=myapp --cov-branch

# JavaScript
jest --coverage --coverageReporters=text-summary

# Go (use multiple test cases for branches)
go test -cover -covermode=count
```

### 4. Use Coverage as Guide, Not Goal

**Good:**
- Coverage shows untested code paths
- Use to find missing tests
- Ensure critical paths are covered

**Bad:**
- Chase 100% coverage
- Write meaningless tests for coverage
- Ignore test quality for coverage metric

### 5. Combine with Mutation Testing

```bash
# High coverage doesn't mean good tests
# Use mutation testing to verify test quality

# Python
mutmut run

# JavaScript
npx stryker run
```

### 6. Different Standards for Different Code

```
Critical code (payment, auth): 100% coverage
Business logic: 90% coverage
Utilities: 80% coverage
UI components: 70% coverage
Scripts/tools: 60% coverage
```

### 7. Review Coverage in PRs

```bash
# Diff coverage in CI
diff-cover coverage.xml --compare-branch=main --fail-under=100

# Ensure new code is fully tested
# Don't decrease overall coverage
```

## Coverage in CI/CD

### GitHub Actions Example

```yaml
name: Tests with Coverage

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v2

      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.10'

      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install pytest pytest-cov

      - name: Run tests with coverage
        run: |
          pytest --cov=myapp --cov-report=xml --cov-report=term-missing --cov-fail-under=80

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v2
        with:
          file: ./coverage.xml
          fail_ci_if_error: true

      - name: Check coverage diff
        run: |
          pip install diff-cover
          diff-cover coverage.xml --compare-branch=origin/main --fail-under=100
```

### Coverage Badges

```markdown
# README.md

[![codecov](https://codecov.io/gh/username/repo/branch/main/graph/badge.svg)](https://codecov.io/gh/username/repo)

![Coverage](https://img.shields.io/badge/coverage-85%25-green)
```

## Remember

1. **Branch coverage > Line coverage**
2. **80% is a good target**, 100% often wasteful
3. **Critical paths need 100% coverage**
4. **Coverage doesn't guarantee quality** (use mutation testing)
5. **Track coverage over time** (don't decrease)
6. **Focus on untested behavior**, not uncovered lines
7. **Different standards for different code**
8. **Coverage in CI/CD** to maintain standards
9. **Exclude trivial code** (getters, repr, type checking)
10. **Test quality > Coverage percentage**
