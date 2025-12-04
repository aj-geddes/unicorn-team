---
name: testing
description: >
  Cross-language testing expertise for TDD-first development. Use when writing
  tests, implementing test-first workflow, improving test coverage, debugging
  flaky tests, or designing testable code. Covers unit/integration/E2E testing,
  mocking strategies, coverage requirements, and anti-patterns across Python,
  JavaScript, Go, and Rust. Trigger phrases: "write tests", "TDD", "test coverage",
  "mock", "test fails", "flaky test", "how to test".
---

# Testing Domain Skill

## TDD Fundamentals

### The Iron Law: RED → GREEN → REFACTOR

This is non-negotiable. Always follow this cycle:

1. **RED**: Write a failing test first
   - Test must fail for the right reason
   - Proves the test actually tests something
   - Documents expected behavior

2. **GREEN**: Write minimum code to pass
   - No gold plating
   - Simplest implementation that works
   - Proves the approach is viable

3. **REFACTOR**: Improve without changing behavior
   - Tests stay green
   - Clean up duplication
   - Improve design

```python
# RED: Write failing test
def test_user_full_name():
    user = User(first="Jane", last="Doe")
    assert user.full_name() == "Jane Doe"
    # This fails because full_name() doesn't exist yet

# GREEN: Minimum implementation
class User:
    def __init__(self, first, last):
        self.first = first
        self.last = last

    def full_name(self):
        return f"{self.first} {self.last}"

# REFACTOR: Tests pass, improve design if needed
```

**See:** `references/tdd-deep-dive.md` for comprehensive TDD methodology, when to break rules, and advanced techniques.

### Test-First Mindset

Write tests before implementation because:
- Forces you to think about interface design
- Documents expected behavior
- Prevents over-engineering
- Makes code testable by default

### What to Test

**DO test behavior:**
- Public API contracts
- Edge cases and boundaries
- Error conditions
- State transitions
- Business logic

**DON'T test implementation:**
- Private methods (test through public API)
- Language features (trust the language)
- Third-party libraries (trust but verify integration)
- Trivial getters/setters

## Test Types

### Unit Tests

Fast, isolated, test single units of behavior.

**Characteristics:**
- Run in milliseconds
- No I/O (network, disk, database)
- No external dependencies
- Can run in parallel
- Deterministic results

**Python (pytest):**
```python
def test_calculate_discount():
    # Arrange
    price = 100
    discount_percent = 20

    # Act
    result = calculate_discount(price, discount_percent)

    # Assert
    assert result == 80
```

**JavaScript (Jest):**
```javascript
test('applies discount correctly', () => {
  const result = calculateDiscount(100, 20);
  expect(result).toBe(80);
});
```

**See:** `references/test-patterns-by-language.md` for comprehensive language-specific examples, frameworks, and idioms.

### Integration Tests

Test component boundaries and interactions.

**Characteristics:**
- Slower than unit tests (seconds)
- May involve I/O
- Test real integrations
- Run sequentially if stateful

**Python (database integration):**
```python
@pytest.fixture
def db_session():
    engine = create_engine('sqlite:///:memory:')
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    session = Session()
    yield session
    session.close()

def test_user_repository_save(db_session):
    repo = UserRepository(db_session)
    user = User(email="test@example.com")

    saved_user = repo.save(user)

    assert saved_user.id is not None
    assert repo.find_by_id(saved_user.id).email == "test@example.com"
```

### E2E Tests

Test complete user flows through the system.

**Characteristics:**
- Slowest (seconds to minutes)
- Test from user perspective
- May involve UI, API, database
- Run against staging/test environment

**Python (playwright):**
```python
def test_user_signup_flow(browser):
    browser.goto("http://localhost:3000/signup")
    browser.fill('input[name="email"]', "newuser@example.com")
    browser.fill('input[name="password"]', "SecurePass123!")
    browser.click('button[type="submit"]')

    assert browser.url == "http://localhost:3000/dashboard"
    assert "Welcome" in browser.text_content('h1')
```

### Characterization Tests

Capture existing behavior of legacy code before refactoring.

**Strategy:**
1. Write tests that document current behavior (even if wrong)
2. Run tests to establish baseline
3. Refactor code
4. Adjust tests if behavior should change
5. Keep tests as regression suite

```python
def test_legacy_calculation_current_behavior():
    """Documents current behavior before refactoring.

    Note: This calculation appears incorrect (should be 42?)
    but preserving current behavior during refactor.
    """
    result = legacy_calculate(10, 5)
    assert result == 48  # Current behavior
```

## Test Structure

### Arrange-Act-Assert (AAA)

Standard pattern for clear, readable tests:

```python
def test_shopping_cart_total():
    # Arrange: Set up test data and dependencies
    cart = ShoppingCart()
    cart.add_item(Item("Book", 10.00))

    # Act: Execute the behavior under test
    total = cart.calculate_total()

    # Assert: Verify the outcome
    assert total == 10.00
```

### One Assertion Per Test

**Prefer this:**
```python
def test_user_creation_sets_email():
    user = User("test@example.com")
    assert user.email == "test@example.com"

def test_user_creation_generates_id():
    user = User("test@example.com")
    assert user.id is not None
```

**Exception:** Related assertions on same object are acceptable:
```python
def test_coordinate_creation():
    coord = Coordinate(10, 20)
    assert coord.x == 10
    assert coord.y == 20
```

## Coverage Requirements

### Minimum Standards

- **80% line coverage** (enforced by CI)
- **Branch coverage** more important than line coverage
- **Critical paths** must have 100% coverage

### Measure Coverage

**Python:**
```bash
pytest --cov=myapp --cov-report=html --cov-fail-under=80
```

**JavaScript:**
```bash
jest --coverage --coverageThreshold='{"global":{"lines":80}}'
```

**Go:**
```bash
go test -cover -coverprofile=coverage.out
go tool cover -html=coverage.out
```

**Rust:**
```bash
cargo tarpaulin --out Html --output-dir coverage
```

**See:** `references/coverage-strategies.md` for comprehensive coverage techniques including branch coverage, mutation testing, and coverage-driven development.

### What NOT to Test

Don't waste time testing:
- **Trivial code:** Simple getters, setters, constructors
- **Framework code:** Trust the framework
- **Generated code:** Generated clients, migrations
- **Configuration:** Static configuration files

## Mocking Strategy

### When to Mock

Mock external dependencies that:
- Make network calls (APIs, databases)
- Access filesystem
- Use current time/randomness
- Are slow or unreliable
- Cost money (third-party APIs)

### When NOT to Mock

Don't mock:
- Internal implementation details
- Value objects and data structures
- Code under test
- Simple collaborators (prefer real objects)

### Mock Types

**Stub:** Returns predefined values
```python
class StubEmailService:
    def send(self, to, subject, body):
        return True  # Always succeeds
```

**Spy:** Records calls for verification
```python
class SpyEmailService:
    def __init__(self):
        self.calls = []

    def send(self, to, subject, body):
        self.calls.append((to, subject, body))
        return True
```

**Fake:** Simplified working implementation
```python
class FakeUserRepository:
    def __init__(self):
        self.users = {}
        self._next_id = 1

    def save(self, user):
        user.id = self._next_id
        self.users[user.id] = user
        self._next_id += 1
        return user
```

**See:** `references/mocking-strategies.md` for comprehensive mocking patterns, when to use each type, cross-language examples, and avoiding over-mocking.

### Cross-Language Mocking

**Python:** `unittest.mock.Mock()` with `assert_called_once()`
**JavaScript:** `jest.fn()` with `expect().toHaveBeenCalled()`
**Go:** Interfaces with mock structs tracking call state
**Rust:** Traits with mock implementations using `RefCell` for interior mutability

See `references/mocking-strategies.md` for detailed cross-language examples.

## Anti-Patterns

### Testing Implementation Details

**BAD:** Testing HOW (verifying mock.find_by_id was called)

**GOOD:** Testing WHAT (verifying correct user is returned with expected email)

### Flaky Tests

**Causes:** Non-deterministic inputs (time, random), shared state, async timing, external dependencies.

**Fixes:** Inject time dependencies, isolate state with fixtures, use wait conditions for async code.

### Over-Mocking

**BAD:** Mocking everything (repo, email, logger, validator, hasher) makes tests brittle and meaningless.

**GOOD:** Only mock external boundaries (email service), use real implementations for internal logic.

## Test Organization

**Structure:** Separate unit/integration/e2e tests. Python uses `tests/` directory, JavaScript often colocates.

**Naming:** `test_*.py`, `*.test.js`, `*_test.go`, `tests.rs`

**Functions:** Descriptive names like `test_user_login_with_invalid_password_returns_error()` not `test_case_1()`

## Quick Reference

**TDD Commands:** `pytest -x` (Python), `npm test -- --watch` (JS), `go test ./...` (Go), `cargo test` (Rust)

**Coverage:** `pytest --cov=. --cov-fail-under=80` (Python), `jest --coverage` (JS), `go test -cover` (Go), `cargo tarpaulin` (Rust)

## Remember

1. **RED → GREEN → REFACTOR** is mandatory
2. **Test behavior, not implementation**
3. **80% coverage minimum**, critical paths 100%
4. **Mock external boundaries only**
5. **Fast, isolated, deterministic tests**
6. **One clear assertion per test** (when practical)
7. **Arrange-Act-Assert** for clarity
8. **Descriptive test names** document behavior
9. **Fix flaky tests immediately** (never ignore)
10. **Tests are first-class code** (refactor them too)

## Additional Resources

- `references/tdd-deep-dive.md` - Advanced TDD techniques and when to break rules
- `references/mocking-strategies.md` - Comprehensive mocking patterns and anti-patterns
- `references/test-patterns-by-language.md` - Language-specific testing patterns
- `references/coverage-strategies.md` - Advanced coverage techniques and mutation testing
