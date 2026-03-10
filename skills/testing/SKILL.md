---
name: testing
description: >-
  Guides the user through test-first development and test strategy decisions.
  ALWAYS trigger on "write tests", "TDD", "test coverage", "mock", "test fails",
  "flaky test", "how to test", "unit test", "integration test", "e2e test",
  "test structure", "what to test", "test organization", "coverage report",
  "testing strategy", "arrange act assert". Use when writing new tests, choosing
  test types, setting up mocking, debugging flaky tests, improving coverage, or
  designing testable code. Different from qa-security agent which focuses on
  code review and security audits rather than test authoring.
---

# Testing Domain Skill

## TDD Cycle: RED -> GREEN -> REFACTOR

1. **RED** - Write a failing test. Must fail for the right reason.
2. **GREEN** - Write minimum code to pass. No gold plating.
3. **REFACTOR** - Improve design. Tests stay green.

```python
# RED
def test_user_full_name():
    user = User(first="Jane", last="Doe")
    assert user.full_name() == "Jane Doe"

# GREEN
class User:
    def __init__(self, first, last):
        self.first = first
        self.last = last
    def full_name(self):
        return f"{self.first} {self.last}"

# REFACTOR: tests pass, clean up if needed
```

**See:** `references/tdd-deep-dive.md` for advanced TDD techniques.

## What to Test / What NOT to Test

**DO test (behavior):**
- Public API contracts
- Edge cases and boundaries
- Error conditions
- State transitions
- Business logic

**DON'T test (implementation):**
- Private methods (test through public API)
- Language features
- Third-party libraries (only verify integration)
- Trivial getters/setters
- Generated code, migrations, static config

## Test Types

### Unit Tests
- Run in milliseconds, no I/O, no external dependencies
- Deterministic, parallelizable
- Test single units of behavior

### Integration Tests
- Seconds to run, may involve I/O
- Test real component boundaries
- Run sequentially if stateful

### E2E Tests
- Slowest (seconds to minutes)
- Test complete user flows from user perspective
- Run against staging/test environment

### Characterization Tests
- Capture existing behavior of legacy code before refactoring
- Document current behavior (even if wrong), then refactor against it

**See:** `references/test-patterns-by-language.md` for language-specific frameworks and idioms.

## Test Structure: Arrange-Act-Assert

```python
def test_shopping_cart_total():
    # Arrange
    cart = ShoppingCart()
    cart.add_item(Item("Book", 10.00))

    # Act
    total = cart.calculate_total()

    # Assert
    assert total == 10.00
```

Prefer one assertion per test. Exception: related assertions on the same object.

## Coverage Requirements

| Metric | Threshold |
|--------|-----------|
| Line coverage | 80% minimum (CI-enforced) |
| Branch coverage | More important than line coverage |
| Critical paths | 100% |

### Coverage Commands

| Language | Command |
|----------|---------|
| Python | `pytest --cov=myapp --cov-report=html --cov-fail-under=80` |
| JavaScript | `jest --coverage --coverageThreshold='{"global":{"lines":80}}'` |
| Go | `go test -cover -coverprofile=coverage.out && go tool cover -html=coverage.out` |
| Rust | `cargo tarpaulin --out Html --output-dir coverage` |

**See:** `references/coverage-strategies.md` for branch coverage, mutation testing, and coverage-driven development.

## Mocking Strategy

### When to Mock

| Mock | Don't Mock |
|------|-----------|
| Network calls (APIs, databases) | Internal implementation details |
| Filesystem access | Value objects and data structures |
| Time/randomness dependencies | The code under test |
| Slow or unreliable dependencies | Simple collaborators (prefer real objects) |
| Paid third-party APIs | |

### Mock Types

- **Stub** - Returns predefined values. Use for simple dependency replacement.
- **Spy** - Records calls for verification. Use when you need to assert interactions.
- **Fake** - Simplified working implementation (e.g., in-memory repository). Use for complex dependencies.

### Cross-Language Mocking

| Language | Tool | Verify Call |
|----------|------|-------------|
| Python | `unittest.mock.Mock()` | `assert_called_once()` |
| JavaScript | `jest.fn()` | `expect().toHaveBeenCalled()` |
| Go | Interfaces + mock structs | Track call state manually |
| Rust | Traits + mock impls | `RefCell` for interior mutability |

**See:** `references/mocking-strategies.md` for comprehensive patterns and anti-patterns.

## Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| Testing implementation | Brittle tests that break on refactor | Test WHAT (outputs/behavior), not HOW (internal calls) |
| Flaky tests | Non-deterministic failures | Inject time deps, isolate state, use wait conditions for async |
| Over-mocking | Tests verify mocks, not behavior | Only mock external boundaries, use real objects internally |

## Test Organization

- **Structure:** Separate `unit/`, `integration/`, `e2e/` directories
- **Naming conventions:** `test_*.py`, `*.test.js`, `*_test.go`, `tests.rs`
- **Function names:** Descriptive -- `test_user_login_with_invalid_password_returns_error()` not `test_case_1()`

## Quick Reference

| Task | Python | JavaScript | Go | Rust |
|------|--------|------------|----|------|
| Run tests | `pytest -x` | `npm test -- --watch` | `go test ./...` | `cargo test` |
| Coverage | `pytest --cov=. --cov-fail-under=80` | `jest --coverage` | `go test -cover` | `cargo tarpaulin` |

## Remember

1. **RED -> GREEN -> REFACTOR** is mandatory
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

<!-- Last reviewed: 2026-03 -->
