# Test Patterns by Language

Language-specific testing patterns, frameworks, and idioms for Python, JavaScript, Go, and Rust.

## Python Testing

### Frameworks

#### pytest (Recommended)

**Why pytest:**
- Simple, clean syntax
- Powerful fixtures
- Excellent plugin ecosystem
- Great failure reporting
- Parameterized tests built-in

**Installation:**
```bash
pip install pytest pytest-cov pytest-mock
```

**Basic patterns:**
```python
# test_calculator.py
import pytest

# Simple test
def test_addition():
    assert 2 + 2 == 4

# Test with setup
def test_user_creation():
    user = User("test@example.com")
    assert user.email == "test@example.com"
    assert user.is_active

# Test exceptions
def test_division_by_zero():
    with pytest.raises(ZeroDivisionError):
        1 / 0

# Test exception message
def test_invalid_email():
    with pytest.raises(ValueError, match="Invalid email"):
        User("not-an-email")

# Parameterized tests
@pytest.mark.parametrize("a,b,expected", [
    (2, 3, 5),
    (0, 0, 0),
    (-1, 1, 0),
    (100, 200, 300),
])
def test_addition_parameterized(a, b, expected):
    assert a + b == expected
```

#### pytest Fixtures

```python
# conftest.py - Shared fixtures
import pytest

@pytest.fixture
def user():
    """Create a test user."""
    return User(email="test@example.com", name="Test User")

@pytest.fixture
def db_session():
    """Provide a database session."""
    engine = create_engine('sqlite:///:memory:')
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    session = Session()
    yield session
    session.close()

@pytest.fixture
def client(db_session):
    """Flask test client with database."""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

# test_users.py - Using fixtures
def test_user_has_email(user):
    assert "@" in user.email

def test_save_user(db_session):
    user = User(email="test@example.com")
    db_session.add(user)
    db_session.commit()

    saved = db_session.query(User).filter_by(email="test@example.com").first()
    assert saved is not None

def test_api_endpoint(client):
    response = client.get('/api/users')
    assert response.status_code == 200
```

#### Advanced pytest Patterns

```python
# Fixture scope
@pytest.fixture(scope="module")
def expensive_resource():
    """Created once per module."""
    resource = setup_expensive_thing()
    yield resource
    teardown_expensive_thing(resource)

# Fixture with parameters
@pytest.fixture(params=["sqlite", "postgres"])
def db_engine(request):
    """Test with multiple database backends."""
    if request.param == "sqlite":
        return create_engine('sqlite:///:memory:')
    elif request.param == "postgres":
        return create_engine('postgresql://test:test@localhost/testdb')

# Auto-use fixture
@pytest.fixture(autouse=True)
def reset_cache():
    """Runs before every test automatically."""
    cache.clear()

# Markers
@pytest.mark.slow
def test_slow_operation():
    # Takes a long time
    pass

@pytest.mark.integration
def test_database_integration():
    # Requires database
    pass

# Run specific markers
# pytest -m "not slow"  # Skip slow tests
# pytest -m integration  # Only integration tests
```

#### unittest (Standard Library)

```python
import unittest

class TestCalculator(unittest.TestCase):
    def setUp(self):
        """Run before each test."""
        self.calc = Calculator()

    def tearDown(self):
        """Run after each test."""
        self.calc = None

    def test_addition(self):
        result = self.calc.add(2, 3)
        self.assertEqual(result, 5)

    def test_division_by_zero(self):
        with self.assertRaises(ZeroDivisionError):
            self.calc.divide(1, 0)

    @unittest.skip("Not implemented yet")
    def test_future_feature(self):
        pass

if __name__ == '__main__':
    unittest.main()
```

### Python-Specific Testing Patterns

#### Testing Async Code

```python
import pytest
import asyncio

# pytest-asyncio plugin
@pytest.mark.asyncio
async def test_async_function():
    result = await async_operation()
    assert result == expected_value

# Test async with mock
@pytest.mark.asyncio
async def test_async_with_mock():
    mock_api = AsyncMock()
    mock_api.fetch_data.return_value = {"data": "value"}

    service = AsyncService(mock_api)
    result = await service.get_data()

    assert result == {"data": "value"}
    mock_api.fetch_data.assert_called_once()
```

#### Testing Context Managers

```python
def test_file_context_manager():
    with patch('builtins.open', mock_open(read_data='test data')) as mock_file:
        with open('test.txt') as f:
            content = f.read()

        assert content == 'test data'
        mock_file.assert_called_once_with('test.txt')

# Testing custom context manager
def test_custom_context_manager():
    with DatabaseTransaction() as transaction:
        transaction.execute("INSERT INTO users VALUES (1, 'test')")
        # Transaction commits on exit

    # Verify transaction was committed
    assert user_exists(1)
```

#### Testing Decorators

```python
def test_decorator():
    @require_auth
    def protected_function(user):
        return f"Hello {user.name}"

    # Test with authenticated user
    user = User(name="Alice", authenticated=True)
    assert protected_function(user) == "Hello Alice"

    # Test without authentication
    user = User(name="Bob", authenticated=False)
    with pytest.raises(AuthenticationError):
        protected_function(user)
```

#### Property-Based Testing (Hypothesis)

```python
from hypothesis import given, strategies as st

@given(st.integers(), st.integers())
def test_addition_commutative(a, b):
    """Addition should be commutative for all integers."""
    assert a + b == b + a

@given(st.lists(st.integers()))
def test_reverse_twice_is_identity(lst):
    """Reversing twice should give original list."""
    assert list(reversed(list(reversed(lst)))) == lst

@given(st.text())
def test_encode_decode(text):
    """Encoding then decoding should give original text."""
    encoded = base64.b64encode(text.encode('utf-8'))
    decoded = base64.b64decode(encoded).decode('utf-8')
    assert decoded == text
```

## JavaScript Testing

### Frameworks

#### Jest (Recommended for React/Node)

**Installation:**
```bash
npm install --save-dev jest @types/jest
```

**Configuration (jest.config.js):**
```javascript
module.exports = {
  testEnvironment: 'node',
  coverageDirectory: 'coverage',
  collectCoverageFrom: ['src/**/*.js'],
  testMatch: ['**/__tests__/**/*.js', '**/*.test.js'],
  coverageThreshold: {
    global: {
      lines: 80,
      branches: 80,
    },
  },
};
```

**Basic patterns:**
```javascript
// calculator.test.js

// Simple test
test('adds 2 + 2 to equal 4', () => {
  expect(2 + 2).toBe(4);
});

// Describe block (grouping)
describe('Calculator', () => {
  test('addition', () => {
    expect(add(2, 3)).toBe(5);
  });

  test('subtraction', () => {
    expect(subtract(5, 3)).toBe(2);
  });
});

// Test objects
test('user object', () => {
  const user = { name: 'Alice', email: 'alice@example.com' };
  expect(user).toEqual({ name: 'Alice', email: 'alice@example.com' });
  expect(user).toHaveProperty('email');
  expect(user.name).toBe('Alice');
});

// Test arrays
test('array contains value', () => {
  const arr = [1, 2, 3, 4];
  expect(arr).toContain(3);
  expect(arr).toHaveLength(4);
});

// Test exceptions
test('throws on invalid input', () => {
  expect(() => divide(1, 0)).toThrow();
  expect(() => divide(1, 0)).toThrow('Cannot divide by zero');
});

// Async tests
test('async function', async () => {
  const data = await fetchData();
  expect(data).toBeDefined();
});

// Promises
test('promise resolves', () => {
  return expect(fetchData()).resolves.toEqual({ data: 'value' });
});

test('promise rejects', () => {
  return expect(fetchData()).rejects.toThrow('Error');
});
```

#### Jest Setup and Teardown

```javascript
// Before/after hooks
describe('Database tests', () => {
  let db;

  beforeAll(async () => {
    // Runs once before all tests in this describe block
    db = await setupDatabase();
  });

  afterAll(async () => {
    // Runs once after all tests
    await db.close();
  });

  beforeEach(() => {
    // Runs before each test
    db.clear();
  });

  afterEach(() => {
    // Runs after each test
    // Cleanup if needed
  });

  test('saves user', async () => {
    const user = await db.saveUser({ email: 'test@example.com' });
    expect(user.id).toBeDefined();
  });

  test('finds user by email', async () => {
    await db.saveUser({ email: 'test@example.com' });
    const user = await db.findByEmail('test@example.com');
    expect(user).toBeDefined();
  });
});
```

#### Jest Mocking

```javascript
// Mock function
const mockFn = jest.fn();
mockFn.mockReturnValue(42);
expect(mockFn()).toBe(42);

// Mock implementation
const mockFn = jest.fn((x) => x * 2);
expect(mockFn(21)).toBe(42);

// Mock module
jest.mock('./api');
import { fetchData } from './api';
fetchData.mockResolvedValue({ data: 'mocked' });

// Spy on method
const obj = {
  method: () => 'original',
};
jest.spyOn(obj, 'method').mockReturnValue('mocked');
expect(obj.method()).toBe('mocked');

// Clear/reset mocks
mockFn.mockClear();  // Clear call history
mockFn.mockReset();  // Clear call history and implementation
mockFn.mockRestore(); // Restore original implementation
```

#### Snapshot Testing

```javascript
// Component snapshot
test('renders correctly', () => {
  const tree = renderer.create(<Button>Click me</Button>).toJSON();
  expect(tree).toMatchSnapshot();
});

// Update snapshots: jest -u

// Inline snapshots
test('object matches snapshot', () => {
  const user = { name: 'Alice', age: 30 };
  expect(user).toMatchInlineSnapshot(`
    Object {
      "age": 30,
      "name": "Alice",
    }
  `);
});
```

#### Vitest (Modern Alternative)

```javascript
// vitest.config.js
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html'],
    },
  },
});

// Similar API to Jest
import { describe, it, expect, beforeEach } from 'vitest';

describe('Calculator', () => {
  it('adds numbers', () => {
    expect(add(2, 3)).toBe(5);
  });
});
```

### JavaScript-Specific Patterns

#### Testing React Components

```javascript
import { render, screen, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

test('button click increments counter', () => {
  render(<Counter />);

  const button = screen.getByRole('button', { name: /increment/i });
  const count = screen.getByText(/count:/i);

  expect(count).toHaveTextContent('Count: 0');

  fireEvent.click(button);
  expect(count).toHaveTextContent('Count: 1');
});

// User event (more realistic)
test('form submission', async () => {
  render(<LoginForm />);

  await userEvent.type(screen.getByLabelText(/email/i), 'test@example.com');
  await userEvent.type(screen.getByLabelText(/password/i), 'password123');
  await userEvent.click(screen.getByRole('button', { name: /submit/i }));

  expect(await screen.findByText(/welcome/i)).toBeInTheDocument();
});
```

#### Testing Async/Promises

```javascript
// Async/await
test('fetches data', async () => {
  const data = await fetchUserData(1);
  expect(data.name).toBe('Alice');
});

// waitFor from testing-library
test('loading state', async () => {
  render(<UserProfile userId={1} />);

  expect(screen.getByText(/loading/i)).toBeInTheDocument();

  await waitFor(() => {
    expect(screen.queryByText(/loading/i)).not.toBeInTheDocument();
  });

  expect(screen.getByText(/alice/i)).toBeInTheDocument();
});
```

#### Testing Timers

```javascript
test('delays execution', () => {
  jest.useFakeTimers();
  const callback = jest.fn();

  setTimeout(callback, 1000);

  expect(callback).not.toHaveBeenCalled();

  jest.advanceTimersByTime(1000);

  expect(callback).toHaveBeenCalledTimes(1);

  jest.useRealTimers();
});
```

## Go Testing

### Standard Library Testing

**File naming:** `*_test.go`

```go
// calculator_test.go
package calculator

import "testing"

// Basic test
func TestAdd(t *testing.T) {
    result := Add(2, 3)
    expected := 5

    if result != expected {
        t.Errorf("Add(2, 3) = %d; want %d", result, expected)
    }
}

// Table-driven tests (idiomatic Go)
func TestAdd_TableDriven(t *testing.T) {
    tests := []struct {
        name     string
        a, b     int
        expected int
    }{
        {"positive numbers", 2, 3, 5},
        {"zeros", 0, 0, 0},
        {"negative numbers", -1, -2, -3},
        {"mixed signs", -5, 10, 5},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := Add(tt.a, tt.b)
            if result != tt.expected {
                t.Errorf("Add(%d, %d) = %d; want %d",
                    tt.a, tt.b, result, tt.expected)
            }
        })
    }
}

// Test with helper function
func TestDivide(t *testing.T) {
    result, err := Divide(10, 2)

    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }

    if result != 5 {
        t.Errorf("got %d, want 5", result)
    }
}

// Test error case
func TestDivide_ByZero(t *testing.T) {
    _, err := Divide(10, 0)

    if err == nil {
        t.Error("expected error for division by zero")
    }
}
```

### Using testify

```go
import (
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
    "testing"
)

func TestUser_Create(t *testing.T) {
    user := NewUser("test@example.com")

    // assert continues on failure
    assert.Equal(t, "test@example.com", user.Email)
    assert.NotNil(t, user.ID)
    assert.True(t, user.IsActive)

    // require stops on failure
    require.NotNil(t, user)
    require.NoError(t, user.Validate())
}

func TestUser_Save(t *testing.T) {
    user := NewUser("test@example.com")
    err := user.Save()

    require.NoError(t, err)
    assert.NotEqual(t, 0, user.ID)
}
```

### Go Testing Patterns

#### Setup and Teardown

```go
func TestMain(m *testing.M) {
    // Setup
    setup()

    // Run tests
    code := m.Run()

    // Teardown
    teardown()

    os.Exit(code)
}

// Per-test setup
func setupTest(t *testing.T) func() {
    // Setup
    db := createTestDB()

    // Return teardown function
    return func() {
        db.Close()
    }
}

func TestWithSetup(t *testing.T) {
    teardown := setupTest(t)
    defer teardown()

    // Test code
}
```

#### Testing Interfaces

```go
type UserRepository interface {
    Save(user *User) error
    FindByID(id int) (*User, error)
}

// Fake implementation for testing
type InMemoryUserRepository struct {
    users  map[int]*User
    nextID int
}

func (r *InMemoryUserRepository) Save(user *User) error {
    user.ID = r.nextID
    r.users[user.ID] = user
    r.nextID++
    return nil
}

func (r *InMemoryUserRepository) FindByID(id int) (*User, error) {
    user, ok := r.users[id]
    if !ok {
        return nil, errors.New("user not found")
    }
    return user, nil
}

func TestUserService(t *testing.T) {
    repo := &InMemoryUserRepository{
        users:  make(map[int]*User),
        nextID: 1,
    }
    service := NewUserService(repo)

    user, err := service.CreateUser("test@example.com")

    require.NoError(t, err)
    assert.Equal(t, 1, user.ID)
}
```

#### Benchmarks

```go
func BenchmarkAdd(b *testing.B) {
    for i := 0; i < b.N; i++ {
        Add(2, 3)
    }
}

// Run: go test -bench=.
// Output: BenchmarkAdd-8   1000000000   0.25 ns/op
```

#### Examples (Testable Documentation)

```go
func ExampleAdd() {
    result := Add(2, 3)
    fmt.Println(result)
    // Output: 5
}

func ExampleUser_FullName() {
    user := User{FirstName: "Alice", LastName: "Smith"}
    fmt.Println(user.FullName())
    // Output: Alice Smith
}
```

## Rust Testing

### Built-in Testing

```rust
// lib.rs or calculator.rs

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_add() {
        assert_eq!(add(2, 3), 5);
    }

    #[test]
    fn test_divide() {
        let result = divide(10.0, 2.0).unwrap();
        assert_eq!(result, 5.0);
    }

    #[test]
    fn test_divide_by_zero() {
        let result = divide(10.0, 0.0);
        assert!(result.is_err());
    }

    #[test]
    #[should_panic]
    fn test_panic() {
        panic!("This test should panic");
    }

    #[test]
    #[should_panic(expected = "divide by zero")]
    fn test_panic_with_message() {
        panic!("divide by zero");
    }

    #[test]
    #[ignore]
    fn expensive_test() {
        // Run with: cargo test -- --ignored
    }
}
```

### Result-Based Testing

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_with_result() -> Result<(), String> {
        let result = add(2, 3);

        if result == 5 {
            Ok(())
        } else {
            Err(format!("Expected 5, got {}", result))
        }
    }
}
```

### Using assert Macros

```rust
#[test]
fn test_assertions() {
    // Equality
    assert_eq!(add(2, 3), 5);
    assert_ne!(add(2, 3), 6);

    // Boolean
    assert!(is_even(4));
    assert!(!is_even(3));

    // Custom message
    assert_eq!(
        add(2, 3),
        5,
        "Addition failed: 2 + 3 should equal 5"
    );
}
```

### Testing with mockall

```rust
use mockall::{automock, predicate::*};

#[automock]
trait UserRepository {
    fn save(&self, user: &User) -> Result<User, Error>;
    fn find_by_id(&self, id: i32) -> Result<Option<User>, Error>;
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_user_service_create() {
        let mut mock_repo = MockUserRepository::new();

        mock_repo
            .expect_save()
            .with(predicate::always())
            .returning(|user| Ok(User { id: 1, ..user.clone() }));

        let service = UserService::new(mock_repo);
        let user = service.create_user("test@example.com").unwrap();

        assert_eq!(user.id, 1);
    }
}
```

### Property-Based Testing (proptest)

```rust
use proptest::prelude::*;

proptest! {
    #[test]
    fn test_add_commutative(a: i32, b: i32) {
        // Addition should be commutative
        prop_assert_eq!(add(a, b), add(b, a));
    }

    #[test]
    fn test_reverse_twice(v in prop::collection::vec(any::<i32>(), 0..100)) {
        // Reversing twice should give original vector
        let reversed_twice: Vec<_> = v.iter().rev().rev().cloned().collect();
        prop_assert_eq!(v, reversed_twice);
    }
}
```

## Cross-Language Testing Comparison

| Feature | Python | JavaScript | Go | Rust |
|---------|--------|------------|----|----- |
| Test runner | pytest | Jest/Vitest | go test | cargo test |
| Assertions | assert | expect/toBe | if/t.Error | assert_eq! |
| Mocking | unittest.mock | jest.fn() | interfaces | mockall |
| Coverage | pytest-cov | jest --coverage | go test -cover | tarpaulin |
| Async | @pytest.mark.asyncio | async/await | goroutines | tokio |
| Parameterized | @pytest.mark.parametrize | test.each | table-driven | proptest |

## Remember

1. **Use idiomatic patterns** for each language
2. **Table-driven tests** are powerful (especially Go)
3. **Property-based testing** catches edge cases
4. **Snapshot testing** is useful but use sparingly
5. **Test async code** with proper async testing tools
6. **Benchmarks** should be in test files
7. **Examples** are tests and documentation (Go, Rust)
