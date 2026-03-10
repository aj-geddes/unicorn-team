# Mocking Strategies

Comprehensive guide to when, how, and what to mock across languages and frameworks.

## Mock Fundamentals

### The Mocking Spectrum

```
Real Object → Fake → Stub → Spy → Mock → Total Isolation
(Least control)                            (Most control)
(Most realistic)                           (Most brittle)
```

**Choose based on:**
- Control needed over behavior
- Verification requirements
- Test speed requirements
- Complexity tolerance

## Mock Types Deep Dive

### 1. Stub - Returns Predefined Values

**Use when:** You need specific return values but don't care about interactions.

**Python:**
```python
class StubWeatherAPI:
    """Returns predetermined weather data."""

    def get_forecast(self, city):
        return {
            "temp": 72,
            "condition": "sunny",
            "humidity": 45
        }

def test_weather_display():
    display = WeatherDisplay(StubWeatherAPI())

    result = display.show_forecast("Seattle")

    assert "72°F" in result
    assert "sunny" in result
```

**JavaScript:**
```javascript
class StubWeatherAPI {
  getForecast(city) {
    return {
      temp: 72,
      condition: 'sunny',
      humidity: 45
    };
  }
}

test('weather display shows forecast', () => {
  const display = new WeatherDisplay(new StubWeatherAPI());

  const result = display.showForecast('Seattle');

  expect(result).toContain('72°F');
  expect(result).toContain('sunny');
});
```

**When to use stubs:**
- ✓ Testing data transformations
- ✓ Testing business logic with known inputs
- ✓ Don't care about interaction details
- ✗ Need to verify method calls
- ✗ Need different behaviors per call

### 2. Spy - Records Interactions

**Use when:** You need to verify that certain calls were made.

**Python:**
```python
class SpyEmailService:
    """Records all email sends for verification."""

    def __init__(self):
        self.sent_emails = []

    def send(self, to, subject, body):
        self.sent_emails.append({
            'to': to,
            'subject': subject,
            'body': body,
            'sent_at': datetime.now()
        })
        return True

def test_user_registration_sends_welcome_email():
    email_spy = SpyEmailService()
    service = UserService(email_service=email_spy)

    service.register("newuser@example.com")

    # Verify the interaction
    assert len(email_spy.sent_emails) == 1
    email = email_spy.sent_emails[0]
    assert email['to'] == "newuser@example.com"
    assert "Welcome" in email['subject']
```

**JavaScript:**
```javascript
class SpyEmailService {
  constructor() {
    this.sentEmails = [];
  }

  send(to, subject, body) {
    this.sentEmails.push({
      to,
      subject,
      body,
      sentAt: new Date()
    });
    return true;
  }
}

test('user registration sends welcome email', () => {
  const emailSpy = new SpyEmailService();
  const service = new UserService(emailSpy);

  service.register('newuser@example.com');

  expect(emailSpy.sentEmails).toHaveLength(1);
  expect(emailSpy.sentEmails[0].to).toBe('newuser@example.com');
  expect(emailSpy.sentEmails[0].subject).toContain('Welcome');
});
```

**When to use spies:**
- ✓ Verify method was called
- ✓ Check call order
- ✓ Inspect arguments passed
- ✓ Count number of calls
- ✗ Complex return value logic
- ✗ Need to change behavior per test

### 3. Fake - Simplified Working Implementation

**Use when:** You need realistic behavior but without external dependencies.

**Python:**
```python
class FakeUserRepository:
    """In-memory implementation of UserRepository interface."""

    def __init__(self):
        self.users = {}
        self._next_id = 1

    def save(self, user):
        if user.id is None:
            user.id = self._next_id
            self._next_id += 1
        self.users[user.id] = user
        return user

    def find_by_id(self, user_id):
        return self.users.get(user_id)

    def find_by_email(self, email):
        for user in self.users.values():
            if user.email == email:
                return user
        return None

    def delete(self, user_id):
        if user_id in self.users:
            del self.users[user_id]
            return True
        return False

def test_user_service_creates_and_retrieves_user():
    repo = FakeUserRepository()
    service = UserService(repo)

    # Create user
    created = service.create_user("test@example.com")

    # Retrieve user
    found = service.get_user(created.id)

    assert found.id == created.id
    assert found.email == "test@example.com"
```

**JavaScript:**
```javascript
class FakeUserRepository {
  constructor() {
    this.users = new Map();
    this.nextId = 1;
  }

  save(user) {
    if (!user.id) {
      user.id = this.nextId++;
    }
    this.users.set(user.id, user);
    return user;
  }

  findById(id) {
    return this.users.get(id);
  }

  findByEmail(email) {
    for (const user of this.users.values()) {
      if (user.email === email) return user;
    }
    return null;
  }

  delete(id) {
    return this.users.delete(id);
  }
}

test('user service creates and retrieves user', () => {
  const repo = new FakeUserRepository();
  const service = new UserService(repo);

  const created = service.createUser('test@example.com');
  const found = service.getUser(created.id);

  expect(found.id).toBe(created.id);
  expect(found.email).toBe('test@example.com');
});
```

**When to use fakes:**
- ✓ Complex business logic in tests
- ✓ Testing multiple operations together
- ✓ Need realistic state management
- ✓ Reusable across many tests
- ✗ Simple single-method dependency
- ✗ External API you don't control

### 4. Mock - Programmable Test Double

**Use when:** You need fine-grained control over behavior and verification.

**Python (unittest.mock):**
```python
from unittest.mock import Mock, call, ANY

def test_order_service_processes_payment_and_ships():
    # Create mocks
    mock_payment = Mock()
    mock_shipping = Mock()

    # Configure behavior
    mock_payment.charge.return_value = {"status": "success", "transaction_id": "txn_123"}
    mock_shipping.ship.return_value = {"tracking": "TRK-123"}

    # System under test
    service = OrderService(payment=mock_payment, shipping=mock_shipping)

    # Execute
    result = service.process_order(Order(amount=100, address="123 Main St"))

    # Verify interactions
    mock_payment.charge.assert_called_once_with(100)
    mock_shipping.ship.assert_called_once_with(address="123 Main St", priority="standard")

    # Verify return value
    assert result["transaction_id"] == "txn_123"
    assert result["tracking"] == "TRK-123"
```

**JavaScript (Jest):**
```javascript
test('order service processes payment and ships', () => {
  // Create mocks
  const mockPayment = {
    charge: jest.fn().mockResolvedValue({
      status: 'success',
      transactionId: 'txn_123'
    })
  };

  const mockShipping = {
    ship: jest.fn().mockResolvedValue({
      tracking: 'TRK-123'
    })
  };

  // System under test
  const service = new OrderService(mockPayment, mockShipping);

  // Execute
  const result = await service.processOrder({
    amount: 100,
    address: '123 Main St'
  });

  // Verify interactions
  expect(mockPayment.charge).toHaveBeenCalledWith(100);
  expect(mockShipping.ship).toHaveBeenCalledWith({
    address: '123 Main St',
    priority: 'standard'
  });

  // Verify return value
  expect(result.transactionId).toBe('txn_123');
  expect(result.tracking).toBe('TRK-123');
});
```

**When to use mocks:**
- ✓ Need to verify specific interactions
- ✓ Testing error conditions
- ✓ Complex return value scenarios
- ✓ Simulating external failures
- ✗ Testing internal implementation
- ✗ Too many mock setups (use fake instead)

## Cross-Language Mocking Patterns

### Python Mocking Tools

#### unittest.mock (Standard Library)

```python
from unittest.mock import Mock, MagicMock, patch, call

# Basic mock
mock = Mock()
mock.method.return_value = 42
assert mock.method() == 42

# Mock with side effects
mock = Mock()
mock.method.side_effect = [1, 2, 3]
assert mock.method() == 1
assert mock.method() == 2
assert mock.method() == 3

# Mock exceptions
mock = Mock()
mock.method.side_effect = ValueError("Invalid input")
with pytest.raises(ValueError):
    mock.method()

# Verify calls
mock.method.assert_called_once_with(arg1="value")
mock.method.assert_called_with(arg1="value")
assert mock.method.call_count == 1

# Patch (replace during test)
@patch('mymodule.external_api')
def test_with_patch(mock_api):
    mock_api.get_data.return_value = {"key": "value"}
    result = my_function()
    assert result == {"key": "value"}

# Context manager patch
def test_with_context_patch():
    with patch('mymodule.external_api') as mock_api:
        mock_api.get_data.return_value = {"key": "value"}
        result = my_function()
        assert result == {"key": "value"}
```

#### pytest-mock

```python
def test_with_pytest_mock(mocker):
    # Cleaner than unittest.mock
    mock_api = mocker.patch('mymodule.external_api')
    mock_api.get_data.return_value = {"key": "value"}

    result = my_function()

    assert result == {"key": "value"}
    mock_api.get_data.assert_called_once()
```

### JavaScript Mocking Tools

#### Jest

```javascript
// Mock function
const mockFn = jest.fn();
mockFn.mockReturnValue(42);
expect(mockFn()).toBe(42);

// Mock with implementation
const mockFn = jest.fn((x) => x * 2);
expect(mockFn(21)).toBe(42);

// Mock resolved value (promises)
const mockFn = jest.fn().mockResolvedValue({data: 'value'});
const result = await mockFn();
expect(result).toEqual({data: 'value'});

// Mock rejected value (promise errors)
const mockFn = jest.fn().mockRejectedValue(new Error('Failed'));
await expect(mockFn()).rejects.toThrow('Failed');

// Mock module
jest.mock('./api');
import { fetchData } from './api';
fetchData.mockResolvedValue({data: 'mocked'});

// Spy on existing method
const obj = {
  method: () => 'original'
};
jest.spyOn(obj, 'method').mockReturnValue('mocked');
expect(obj.method()).toBe('mocked');
```

#### Sinon.js

```javascript
const sinon = require('sinon');

// Stub
const stub = sinon.stub();
stub.returns(42);
expect(stub()).toBe(42);

// Spy
const spy = sinon.spy();
spy('arg1', 'arg2');
expect(spy.calledWith('arg1', 'arg2')).toBe(true);

// Fake timers
const clock = sinon.useFakeTimers();
setTimeout(() => console.log('called'), 1000);
clock.tick(1000);  // Advances time
clock.restore();
```

### Go Mocking Patterns

#### Interface-Based Mocking

```go
// Define interface
type UserRepository interface {
    Save(user *User) error
    FindByID(id int) (*User, error)
}

// Production implementation
type PostgresUserRepository struct {
    db *sql.DB
}

func (r *PostgresUserRepository) Save(user *User) error {
    // Real database logic
}

// Test implementation (fake)
type InMemoryUserRepository struct {
    users map[int]*User
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

// Test
func TestUserService_CreateUser(t *testing.T) {
    repo := &InMemoryUserRepository{
        users: make(map[int]*User),
        nextID: 1,
    }
    service := NewUserService(repo)

    user, err := service.CreateUser("test@example.com")

    assert.NoError(t, err)
    assert.Equal(t, 1, user.ID)
}
```

#### Using testify/mock

```go
import (
    "github.com/stretchr/testify/mock"
    "testing"
)

// Mock implementation
type MockUserRepository struct {
    mock.Mock
}

func (m *MockUserRepository) Save(user *User) error {
    args := m.Called(user)
    return args.Error(0)
}

func (m *MockUserRepository) FindByID(id int) (*User, error) {
    args := m.Called(id)
    return args.Get(0).(*User), args.Error(1)
}

// Test
func TestUserService_CreateUser(t *testing.T) {
    mockRepo := new(MockUserRepository)
    mockRepo.On("Save", mock.Anything).Return(nil)

    service := NewUserService(mockRepo)
    user, err := service.CreateUser("test@example.com")

    assert.NoError(t, err)
    mockRepo.AssertExpectations(t)
}
```

### Rust Mocking Patterns

#### Trait-Based Mocking

```rust
// Define trait
trait UserRepository {
    fn save(&self, user: User) -> Result<User, Error>;
    fn find_by_id(&self, id: i32) -> Result<Option<User>, Error>;
}

// Production implementation
struct PostgresUserRepository {
    pool: PgPool,
}

impl UserRepository for PostgresUserRepository {
    fn save(&self, user: User) -> Result<User, Error> {
        // Real database logic
    }

    fn find_by_id(&self, id: i32) -> Result<Option<User>, Error> {
        // Real database logic
    }
}

// Test implementation
struct InMemoryUserRepository {
    users: RefCell<HashMap<i32, User>>,
    next_id: RefCell<i32>,
}

impl UserRepository for InMemoryUserRepository {
    fn save(&self, mut user: User) -> Result<User, Error> {
        let id = *self.next_id.borrow();
        user.id = Some(id);
        self.users.borrow_mut().insert(id, user.clone());
        *self.next_id.borrow_mut() += 1;
        Ok(user)
    }

    fn find_by_id(&self, id: i32) -> Result<Option<User>, Error> {
        Ok(self.users.borrow().get(&id).cloned())
    }
}

// Test
#[test]
fn test_user_service_create_user() {
    let repo = InMemoryUserRepository {
        users: RefCell::new(HashMap::new()),
        next_id: RefCell::new(1),
    };
    let service = UserService::new(&repo);

    let user = service.create_user("test@example.com").unwrap();

    assert_eq!(user.id, Some(1));
}
```

#### Using mockall

```rust
use mockall::{automock, predicate::*};

#[automock]
trait UserRepository {
    fn save(&self, user: User) -> Result<User, Error>;
    fn find_by_id(&self, id: i32) -> Result<Option<User>, Error>;
}

#[test]
fn test_user_service_create_user() {
    let mut mock_repo = MockUserRepository::new();

    mock_repo
        .expect_save()
        .returning(|user| Ok(User { id: Some(1), ..user }));

    let service = UserService::new(mock_repo);
    let user = service.create_user("test@example.com").unwrap();

    assert_eq!(user.id, Some(1));
}
```

## Mocking Best Practices

### 1. Mock External Boundaries Only

**BAD - Over-mocking:**
```python
def test_user_service():
    mock_validator = Mock()
    mock_hasher = Mock()
    mock_logger = Mock()
    mock_formatter = Mock()
    mock_repo = Mock()

    # Too many mocks = testing implementation, not behavior
```

**GOOD - Mock external boundaries:**
```python
def test_user_service():
    mock_email = Mock()  # External service
    fake_repo = FakeUserRepository()  # Use fake for complex internal
    service = UserService(
        repo=fake_repo,
        email=mock_email,
        validator=Validator(),  # Real
        hasher=Hasher(),        # Real
        logger=Logger()         # Real or null logger
    )
```

### 2. Don't Mock What You Don't Own

**Problem:** External APIs change, mocks don't.

**Solution:** Create adapter layer and mock the adapter.

```python
# BAD - Mocking external library directly
@patch('stripe.Charge.create')
def test_payment(mock_stripe):
    mock_stripe.return_value = {"id": "ch_123"}
    # Brittle: Stripe API changes won't be caught

# GOOD - Mock your adapter
class StripeAdapter:
    """Our adapter around Stripe API."""

    def charge_customer(self, customer_id, amount):
        result = stripe.Charge.create(
            customer=customer_id,
            amount=amount
        )
        return PaymentResult(
            transaction_id=result["id"],
            status=result["status"]
        )

class FakePaymentAdapter:
    """Test double for StripeAdapter."""

    def charge_customer(self, customer_id, amount):
        return PaymentResult(
            transaction_id="test_txn_123",
            status="succeeded"
        )

def test_payment():
    service = PaymentService(FakePaymentAdapter())
    result = service.process_payment(customer_id="cus_123", amount=1000)
    assert result.status == "succeeded"

# Keep integration test with real Stripe (in test mode)
@pytest.mark.integration
def test_payment_real_stripe():
    service = PaymentService(StripeAdapter(api_key=TEST_KEY))
    result = service.process_payment(
        customer_id="cus_test",
        amount=1000
    )
    assert result.status in ["succeeded", "pending"]
```

### 3. Verify Behavior, Not Interactions

**BAD - Testing implementation:**
```python
def test_user_service_calls_repository():
    mock_repo = Mock()
    service = UserService(mock_repo)

    service.create_user("test@example.com")

    # Testing HOW it works, not WHAT it does
    mock_repo.save.assert_called_once()
```

**GOOD - Testing behavior:**
```python
def test_user_service_creates_user():
    fake_repo = FakeUserRepository()
    service = UserService(fake_repo)

    user = service.create_user("test@example.com")

    # Testing WHAT it does
    assert user.email == "test@example.com"
    assert user.id is not None
    assert fake_repo.find_by_email("test@example.com") is not None
```

**Exception:** When the interaction IS the behavior:
```python
def test_user_service_sends_welcome_email():
    mock_email = Mock()
    service = UserService(FakeUserRepository(), mock_email)

    service.create_user("test@example.com")

    # Interaction IS the behavior we care about
    mock_email.send.assert_called_once()
    call_args = mock_email.send.call_args[1]
    assert call_args['to'] == "test@example.com"
    assert "Welcome" in call_args['subject']
```

### 4. Keep Mocks Simple

**BAD - Complex mock setup:**
```python
mock = Mock()
mock.method.return_value.attribute.call.side_effect = [1, 2, 3]
mock.other.return_value.__enter__.return_value.data = "value"
# Unreadable and brittle
```

**GOOD - Simple mock or use fake:**
```python
# If setup is this complex, use a fake instead
fake = FakeObject()
fake.set_data("value")
```

### 5. Prefer Fakes for Complex State

**When you need:**
- Multiple operations in sequence
- State management
- Realistic behavior

**Use a fake, not a mock:**

```python
# BAD - Mock with complex state management
def test_shopping_cart():
    mock_cart = Mock()
    items = []
    mock_cart.add_item.side_effect = lambda item: items.append(item)
    mock_cart.get_items.return_value = items
    mock_cart.total.return_value = sum(item.price for item in items)
    # This is just a bad fake

# GOOD - Proper fake
class FakeShoppingCart:
    def __init__(self):
        self.items = []

    def add_item(self, item):
        self.items.append(item)

    def get_items(self):
        return self.items.copy()

    def total(self):
        return sum(item.price for item in self.items)

def test_shopping_cart():
    cart = FakeShoppingCart()
    cart.add_item(Item(price=10))
    cart.add_item(Item(price=20))
    assert cart.total() == 30
```

## Common Mocking Pitfalls

### 1. Mock Leakage

**Problem:** Mocks affect other tests.

```python
# BAD - Patch at module level
import mymodule
mymodule.external_api = Mock()  # Affects ALL tests

# GOOD - Patch per test
def test_with_patch():
    with patch('mymodule.external_api') as mock_api:
        # Only affects this test
        pass
```

### 2. Verifying the Mock Instead of Behavior

```python
# BAD
def test_something():
    mock = Mock(return_value=42)
    result = function_under_test(mock)
    assert result == 42  # Just testing the mock!

# GOOD
def test_something():
    fake = FakeObject(value=42)
    result = function_under_test(fake)
    assert result == expected_transformation(42)  # Testing real logic
```

### 3. Mocking Everything

**Symptom:** Tests pass but code is broken.

**Cause:** Mocked out all the real logic.

**Fix:** Only mock external boundaries.

## Remember

1. **Prefer real objects** when possible
2. **Use fakes** for complex internal dependencies
3. **Use mocks** for external boundaries and verification
4. **Don't mock what you don't own** (wrap it first)
5. **Keep mocks simple** (if complex, use fake)
6. **Test behavior, not interactions** (unless interaction IS the behavior)
7. **One mock per test** when possible
8. **Integration tests** should use real dependencies
