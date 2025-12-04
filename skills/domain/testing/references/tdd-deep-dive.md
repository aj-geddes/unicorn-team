# TDD Deep Dive

Comprehensive TDD methodology, advanced techniques, and when to break the rules.

## The TDD Philosophy

### Why TDD Works

TDD fundamentally changes how you think about code:

1. **Design before implementation** - Tests force you to think about the API first
2. **Executable documentation** - Tests show exactly how to use the code
3. **Safety net** - Refactoring becomes fearless
4. **Prevents over-engineering** - Only write what's needed to pass tests
5. **Fast feedback** - Know immediately when something breaks

### The Three Laws of TDD (Uncle Bob)

1. **Don't write production code** until you have a failing test
2. **Don't write more of a test** than is sufficient to fail
3. **Don't write more production code** than is sufficient to pass the test

These laws keep you in the RED-GREEN-REFACTOR cycle with iterations measured in minutes, not hours.

## The RED-GREEN-REFACTOR Cycle (Deep)

### RED Phase - The Failing Test

**Goals:**
- Fail for the RIGHT reason (not syntax errors, import errors)
- Document expected behavior clearly
- Keep test simple and focused

**RED phase checklist:**
```python
# 1. Write the test for behavior that doesn't exist yet
def test_user_can_calculate_age():
    user = User(birthdate=date(1990, 1, 1))
    # What's the cleanest API for this?
    age = user.calculate_age(as_of=date(2024, 1, 1))
    assert age == 34

# 2. Run the test - it MUST fail
# 3. Verify it fails for the RIGHT reason:
#    AttributeError: 'User' object has no attribute 'calculate_age'
#    NOT: ImportError, SyntaxError, etc.
```

**Common RED phase mistakes:**
- Test passes immediately (you're testing existing behavior)
- Test fails for wrong reason (typo, import error)
- Test is too complex (testing multiple things)

### GREEN Phase - Minimum Implementation

**Goals:**
- Make the test pass as simply as possible
- Resist the urge to add features
- Prove the approach works

**GREEN phase strategies:**

**1. Fake It:**
```python
# Simplest thing that could possibly work
def calculate_age(self, as_of):
    return 34  # Hard-coded! That's OK for now
```

**2. Obvious Implementation:**
```python
# If the solution is obvious, just write it
def calculate_age(self, as_of):
    return as_of.year - self.birthdate.year
```

**3. Triangulation:**
```python
# Write multiple tests to force generalization
def test_user_age_simple_case():
    user = User(birthdate=date(1990, 1, 1))
    assert user.calculate_age(as_of=date(2024, 1, 1)) == 34

def test_user_age_before_birthday():
    user = User(birthdate=date(1990, 6, 15))
    # Haven't hit birthday yet in 2024
    assert user.calculate_age(as_of=date(2024, 1, 1)) == 33

# Now we're forced to handle the birthday logic properly
def calculate_age(self, as_of):
    age = as_of.year - self.birthdate.year
    if as_of.month < self.birthdate.month or \
       (as_of.month == self.birthdate.month and as_of.day < self.birthdate.day):
        age -= 1
    return age
```

**GREEN phase checklist:**
- All tests pass (green)
- Implementation is simple
- No premature optimization
- No "while we're here" features

### REFACTOR Phase - Improve Design

**Goals:**
- Improve code quality WITHOUT changing behavior
- Remove duplication
- Clarify names and structure
- Tests must stay green throughout

**What to refactor:**
```python
# BEFORE refactor - duplication between test and implementation
def test_calculate_discount():
    price = 100
    discount_percent = 20
    expected = price - (price * discount_percent / 100)
    assert calculate_discount(price, discount_percent) == expected

def calculate_discount(price, discount_percent):
    return price - (price * discount_percent / 100)

# AFTER refactor - extract concept
def test_calculate_discount():
    assert calculate_discount(100, 20) == 80
    assert calculate_discount(50, 10) == 45

def calculate_discount(price, discount_percent):
    discount_amount = price * (discount_percent / 100)
    return price - discount_amount
```

**Refactoring checklist:**
- [ ] All tests still pass
- [ ] No duplication between tests
- [ ] No duplication in implementation
- [ ] Names clearly express intent
- [ ] Functions are small and focused
- [ ] No dead code
- [ ] Complexity is justified

## When to Break the Rules

### Rule: Always Write Tests First

**Break it when:**
- **Spiking/exploring** - Don't know if approach will work
- **Throwaway code** - Prototype that won't be committed
- **Learning new technology** - Still figuring out how it works

**Example:**
```python
# Spike: Exploring an API
# NO TESTS - This is exploratory code
import requests
response = requests.get('https://api.example.com/users')
print(response.json())  # Just seeing what the data looks like

# After exploring, DELETE spike code and start TDD:
def test_user_fetcher_returns_users():
    # Mock the external API
    mock_api = Mock()
    mock_api.get.return_value = {"users": [{"id": 1, "name": "Alice"}]}
    fetcher = UserFetcher(mock_api)

    users = fetcher.fetch_all()

    assert len(users) == 1
    assert users[0].name == "Alice"
```

### Rule: One Assertion Per Test

**Break it when:**
- **Related assertions on same object** - Testing object construction
- **Verifying complete state transition** - Setup/teardown overhead is high
- **Parameterized tests** - Multiple scenarios, same assertion pattern

**Example:**
```python
# OK to have multiple related assertions
def test_user_registration_creates_complete_user():
    user = User.register(
        email="test@example.com",
        password="SecurePass123!",
        first_name="Jane",
        last_name="Doe"
    )

    # All assertions verify the registration operation
    assert user.email == "test@example.com"
    assert user.first_name == "Jane"
    assert user.last_name == "Doe"
    assert user.is_active is True
    assert user.created_at is not None
    assert user.password_hash != "SecurePass123!"  # Verifies hashing
```

### Rule: Don't Mock What You Don't Own

**Break it when:**
- **Third-party API is unreliable** - Network issues, rate limits
- **Third-party API costs money** - Payment processors, SMS gateways
- **Third-party API is slow** - External services taking seconds
- **Testing error conditions** - Need to simulate failures

**Example:**
```python
# Mock external Stripe API even though we don't own it
@patch('stripe.Charge.create')
def test_payment_processor_handles_declined_card(mock_stripe):
    mock_stripe.side_effect = stripe.error.CardError(
        message="Card was declined",
        param="card",
        code="card_declined"
    )

    processor = PaymentProcessor()

    with pytest.raises(PaymentDeclinedError):
        processor.charge_customer(customer_id="cus_123", amount=1000)
```

**Better approach:** Integration tests with test mode:
```python
# Stripe provides test mode - use it!
def test_payment_processor_real_stripe():
    processor = PaymentProcessor(api_key=STRIPE_TEST_KEY)

    # Stripe's test card that always declines
    result = processor.charge_customer(
        card="4000000000000002",  # Test card
        amount=1000
    )

    assert result.status == "declined"
```

## Advanced TDD Techniques

### Test-Driven Bug Fixing

When a bug is found:

1. **Write a test that reproduces the bug** (test fails)
2. **Fix the bug** (test passes)
3. **Keep the test** (regression prevention)

```python
# Bug report: "User age calculation is wrong for leap years"
def test_age_calculation_handles_leap_year():
    # User born on leap day
    user = User(birthdate=date(2000, 2, 29))

    # Age on Feb 28, 2024 (day before birthday)
    assert user.calculate_age(as_of=date(2024, 2, 28)) == 23

    # Age on Feb 29, 2024 (birthday - leap year)
    assert user.calculate_age(as_of=date(2024, 2, 29)) == 24

    # Age on Feb 28, 2025 (non-leap year, "birthday")
    assert user.calculate_age(as_of=date(2025, 2, 28)) == 24

# This test fails, exposing the bug
# Fix the implementation
# Test now passes
# Keep test to prevent regression
```

### Outside-In TDD (London School)

Start with high-level acceptance test, work inward:

```python
# 1. Write acceptance test (fails - nothing exists)
def test_user_can_place_order():
    user = User(email="test@example.com")
    product = Product(name="Book", price=10.00)

    order = user.place_order([product])

    assert order.total == 10.00
    assert order.status == "pending"
    assert len(order.items) == 1

# 2. Write unit tests for User.place_order (fails)
def test_user_place_order_creates_order():
    user = User(email="test@example.com")
    mock_order_service = Mock()
    user.order_service = mock_order_service

    user.place_order([Product(name="Book", price=10.00)])

    mock_order_service.create.assert_called_once()

# 3. Implement User.place_order (unit test passes)
# 4. Write unit tests for OrderService.create (fails)
# 5. Implement OrderService.create (unit test passes)
# 6. Acceptance test now passes (everything integrated)
```

### Inside-Out TDD (Detroit School)

Start with low-level units, build up:

```python
# 1. Write test for OrderItem (lowest level)
def test_order_item_calculates_subtotal():
    item = OrderItem(product=Product(price=10.00), quantity=3)
    assert item.subtotal() == 30.00

# 2. Implement OrderItem.subtotal
# 3. Write test for Order using real OrderItem
def test_order_calculates_total():
    order = Order()
    order.add_item(OrderItem(product=Product(price=10.00), quantity=2))
    order.add_item(OrderItem(product=Product(price=5.00), quantity=1))

    assert order.total() == 25.00

# 4. Implement Order.total
# 5. Write test for User using real Order
def test_user_place_order():
    user = User(email="test@example.com")
    products = [Product(price=10.00)]

    order = user.place_order(products)

    assert order.total() == 10.00
    assert order.user == user
```

## TDD Anti-Patterns

### Test-First vs Test-After

**Anti-pattern:**
```python
# Write implementation first
def calculate_discount(price, discount_percent):
    if discount_percent < 0 or discount_percent > 100:
        raise ValueError("Invalid discount")
    return price * (1 - discount_percent / 100)

# Then write tests (test-after)
def test_calculate_discount():
    assert calculate_discount(100, 20) == 80
```

**Why it's bad:**
- Lost the design benefits of TDD
- Tests become confirmation bias (only test what you implemented)
- Miss edge cases and error conditions

**Fix:** Always write tests FIRST.

### Testing Implementation Details

**Anti-pattern:**
```python
class UserService:
    def register(self, email, password):
        # 1. Validate
        self._validate_email(email)
        # 2. Hash password
        hashed = self._hash_password(password)
        # 3. Save
        return self.repository.save(User(email, hashed))

def test_register_calls_validate_email():
    service = UserService(Mock())
    service._validate_email = Mock()

    service.register("test@example.com", "password")

    service._validate_email.assert_called_once()  # Testing implementation!
```

**Fix:** Test behavior, not steps:
```python
def test_register_rejects_invalid_email():
    service = UserService(FakeRepository())

    with pytest.raises(ValidationError):
        service.register("not-an-email", "password")

def test_register_stores_hashed_password():
    repo = FakeRepository()
    service = UserService(repo)

    user = service.register("test@example.com", "SecurePass123!")

    assert user.password_hash != "SecurePass123!"
    assert len(user.password_hash) > 20  # Verify it's hashed
```

### Slow Tests

**Anti-pattern:**
```python
# Test hits real database
def test_user_repository_save():
    # Starts Docker container, runs migrations, etc.
    db = Database(DATABASE_URL)
    repo = UserRepository(db)

    user = repo.save(User(email="test@example.com"))

    assert user.id is not None
    # Takes 5 seconds to run
```

**Fix:** Use in-memory database or fakes for unit tests:
```python
# Fast unit test with fake
def test_user_repository_save():
    repo = InMemoryUserRepository()

    user = repo.save(User(email="test@example.com"))

    assert user.id is not None
    # Takes 5 milliseconds

# Keep real database test as integration test
@pytest.mark.integration
def test_user_repository_real_database():
    # Real database, but marked as integration
    # Run separately from unit tests
    pass
```

### Brittle Tests

**Anti-pattern:**
```python
def test_user_profile_html():
    user = User(first="Jane", last="Doe")

    html = render_profile(user)

    # Breaks if we change spacing, CSS classes, order, etc.
    assert html == '<div class="profile"><h1>Jane Doe</h1></div>'
```

**Fix:** Test behavior, not exact output:
```python
def test_user_profile_contains_name():
    user = User(first="Jane", last="Doe")

    html = render_profile(user)

    assert "Jane Doe" in html
    assert '<div class="profile"' in html
    # Or use a proper HTML parser
    doc = BeautifulSoup(html, 'html.parser')
    assert doc.find('h1').text == "Jane Doe"
```

## TDD with Legacy Code

### The Legacy Code Dilemma

You can't refactor safely without tests, but you can't write tests without refactoring.

**Strategy: Characterization Tests**

1. **Write tests that document current behavior** (even if wrong)
2. **Get tests passing**
3. **Refactor** (tests ensure behavior doesn't change)
4. **Fix bugs** (update tests to expect correct behavior)

```python
# Legacy function with no tests
def calculate_legacy_price(base, discount, tax, customer_type):
    # 200 lines of spaghetti code
    # Multiple bugs, unclear logic
    # Returns wrong results in some cases
    pass

# Step 1: Characterization test (document current behavior)
def test_calculate_legacy_price_current_behavior():
    """Document current behavior before refactoring.

    Known issues:
    - VIP customers get wrong discount
    - Tax calculation rounds incorrectly
    """
    # Regular customer
    assert calculate_legacy_price(100, 10, 0.08, "regular") == 97.20

    # VIP customer (this is wrong but documenting current behavior)
    assert calculate_legacy_price(100, 10, 0.08, "vip") == 95.00  # Should be 90.72

    # Enterprise customer
    assert calculate_legacy_price(100, 10, 0.08, "enterprise") == 90.00

# Step 2: Refactor safely (tests prevent breaking current behavior)
def calculate_legacy_price(base, discount, tax, customer_type):
    # Refactor to clean code, tests ensure no behavior change
    price_after_discount = _apply_discount(base, discount, customer_type)
    final_price = _apply_tax(price_after_discount, tax)
    return final_price

# Step 3: Fix bugs (update tests to expect correct behavior)
def test_calculate_legacy_price_vip_customer():
    # Now fix the VIP bug
    result = calculate_legacy_price(100, 10, 0.08, "vip")
    assert result == 90.72  # Correct: (100 - 10) * 1.08 = 97.20, then VIP 7% = 90.72
```

### Seam-Based Testing

Find "seams" where you can insert tests without major refactoring:

```python
# Legacy code with hard-coded dependencies
class OrderProcessor:
    def process(self, order):
        # Hard-coded database access
        db = Database("production-db")
        db.save(order)

        # Hard-coded email service
        EmailService().send(order.customer_email, "Order confirmed")

# Find seam: Extract dependencies to make testable
class OrderProcessor:
    def __init__(self, db=None, email=None):
        # Seam: Now injectable
        self.db = db or Database("production-db")
        self.email = email or EmailService()

    def process(self, order):
        self.db.save(order)
        self.email.send(order.customer_email, "Order confirmed")

# Now we can test
def test_order_processor():
    fake_db = FakeDatabase()
    fake_email = FakeEmailService()
    processor = OrderProcessor(db=fake_db, email=fake_email)

    processor.process(Order(customer_email="test@example.com"))

    assert len(fake_db.saved_orders) == 1
    assert len(fake_email.sent_messages) == 1
```

## TDD Metrics

### Test Coverage

**Good:** 80%+ line coverage, focus on branch coverage
**Better:** 100% coverage of critical paths
**Best:** Mutation testing (verify tests actually catch bugs)

### Test Speed

**Unit tests:** < 100ms per test
**Integration tests:** < 1 second per test
**E2E tests:** < 10 seconds per test

**Target:** Full unit test suite runs in < 10 seconds

### Test Ratio

**Typical:** 2-3 lines of test code per 1 line of production code
**Range:** 1:1 (simple code) to 5:1 (complex logic)

### Test Pyramid

```
    /\
   /E2E\      10%  - Few, high-value end-to-end tests
  /------\
 /Integr.\ 20%  - Some integration tests
/----------\
|   Unit   | 70%  - Mostly fast, focused unit tests
------------
```

## Remember

1. **RED-GREEN-REFACTOR is a discipline**, not a suggestion
2. **Fast feedback loop** - Minutes, not hours
3. **Test behavior, not implementation**
4. **Refactor relentlessly** - Tests give you safety
5. **When in doubt, start with a test**
6. **Tests are documentation** - Make them readable
7. **Delete tests that don't add value**
8. **TDD is a skill** - It gets easier with practice
