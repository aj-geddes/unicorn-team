# TDD Examples by Language

Detailed examples of Test-Driven Development in each supported language, including edge cases, advanced patterns, and framework-specific techniques.

## Python TDD Examples

### Example 1: User Registration with Multiple Validation Rules

```python
# tests/test_user_registration.py
import pytest
from datetime import datetime, timedelta
from decimal import Decimal
from user_service import register_user, UserRegistrationError

class TestUserRegistration:
    """Comprehensive test suite for user registration."""

    def test_valid_registration(self):
        """User can register with valid details."""
        user = register_user(
            email="test@example.com",
            password="SecureP@ss123",
            age=25
        )
        assert user.email == "test@example.com"
        assert user.is_active is True
        assert user.created_at is not None

    def test_duplicate_email_rejected(self, existing_user):
        """Cannot register with existing email."""
        with pytest.raises(UserRegistrationError, match="Email already exists"):
            register_user(
                email=existing_user.email,
                password="SecureP@ss123",
                age=25
            )

    def test_invalid_email_format_rejected(self):
        """Invalid email format is rejected."""
        invalid_emails = [
            "notanemail",
            "@example.com",
            "user@",
            "user @example.com",
            "",
        ]
        for invalid_email in invalid_emails:
            with pytest.raises(UserRegistrationError, match="Invalid email"):
                register_user(email=invalid_email, password="SecureP@ss123", age=25)

    def test_weak_password_rejected(self):
        """Weak password is rejected."""
        weak_passwords = [
            "short",           # Too short
            "alllowercase",    # No uppercase
            "ALLUPPERCASE",    # No lowercase
            "NoNumbers!",      # No numbers
            "NoSpecial123",    # No special characters
        ]
        for weak_password in weak_passwords:
            with pytest.raises(UserRegistrationError, match="Password too weak"):
                register_user(
                    email="test@example.com",
                    password=weak_password,
                    age=25
                )

    def test_underage_user_rejected(self):
        """Users under 13 cannot register."""
        with pytest.raises(UserRegistrationError, match="Must be 13 or older"):
            register_user(
                email="kid@example.com",
                password="SecureP@ss123",
                age=12
            )

    def test_registration_sends_confirmation_email(self, mock_email_service):
        """Confirmation email sent on registration."""
        user = register_user(
            email="test@example.com",
            password="SecureP@ss123",
            age=25
        )
        mock_email_service.send.assert_called_once_with(
            to="test@example.com",
            subject="Confirm your email",
            template="email_confirmation",
            context={"user": user}
        )

    def test_registration_logs_event(self, mock_logger):
        """Registration event is logged."""
        register_user(email="test@example.com", password="SecureP@ss123", age=25)
        mock_logger.info.assert_called_with(
            "User registered",
            extra={"email": "test@example.com"}
        )

    def test_registration_creates_user_profile(self):
        """User profile is created on registration."""
        user = register_user(email="test@example.com", password="SecureP@ss123", age=25)
        assert user.profile is not None
        assert user.profile.display_name == ""
        assert user.profile.avatar_url is None

    @pytest.mark.parametrize("email,expected_normalized", [
        ("Test@Example.com", "test@example.com"),
        ("  spaces@example.com  ", "spaces@example.com"),
        ("CAPS@EXAMPLE.COM", "caps@example.com"),
    ])
    def test_email_normalization(self, email, expected_normalized):
        """Email addresses are normalized (lowercased, trimmed)."""
        user = register_user(email=email, password="SecureP@ss123", age=25)
        assert user.email == expected_normalized

# Implementation (write AFTER tests)
# src/user_service.py
import re
from typing import Optional
from datetime import datetime
from email_validator import validate_email

class UserRegistrationError(Exception):
    """Raised when user registration fails."""
    pass

def register_user(email: str, password: str, age: int) -> User:
    """Register a new user with validation.

    Args:
        email: User's email address
        password: User's password
        age: User's age in years

    Returns:
        Newly created User object

    Raises:
        UserRegistrationError: If registration fails validation
    """
    # Normalize email
    email = email.strip().lower()

    # Validate email format
    try:
        validate_email(email)
    except Exception:
        raise UserRegistrationError("Invalid email format")

    # Check for duplicate
    if User.objects.filter(email=email).exists():
        raise UserRegistrationError("Email already exists")

    # Validate age
    if age < 13:
        raise UserRegistrationError("Must be 13 or older")

    # Validate password strength
    if len(password) < 8:
        raise UserRegistrationError("Password too weak")
    if not re.search(r'[A-Z]', password):
        raise UserRegistrationError("Password too weak")
    if not re.search(r'[a-z]', password):
        raise UserRegistrationError("Password too weak")
    if not re.search(r'[0-9]', password):
        raise UserRegistrationError("Password too weak")
    if not re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
        raise UserRegistrationError("Password too weak")

    # Create user
    user = User.objects.create(
        email=email,
        password=hash_password(password),
        age=age,
        is_active=True,
        created_at=datetime.now()
    )

    # Create profile
    UserProfile.objects.create(user=user)

    # Send confirmation email
    email_service.send(
        to=email,
        subject="Confirm your email",
        template="email_confirmation",
        context={"user": user}
    )

    # Log event
    logger.info("User registered", extra={"email": email})

    return user
```

### Example 2: Price Calculator with Tax and Discounts

```python
# tests/test_price_calculator.py
import pytest
from decimal import Decimal
from price_calculator import PriceCalculator, Item

class TestPriceCalculator:
    """Test suite for price calculation with tax and discounts."""

    @pytest.fixture
    def calculator(self):
        return PriceCalculator(tax_rate=Decimal("0.1"))

    def test_empty_cart_returns_zero(self, calculator):
        """Empty cart should have zero total."""
        assert calculator.calculate_total([]) == Decimal("0")

    def test_single_item_with_tax(self, calculator):
        """Single item price includes tax."""
        items = [Item(price=Decimal("10.00"), quantity=1)]
        assert calculator.calculate_total(items) == Decimal("11.00")

    def test_multiple_items_with_tax(self, calculator):
        """Multiple items are summed correctly with tax."""
        items = [
            Item(price=Decimal("10.00"), quantity=2),
            Item(price=Decimal("15.00"), quantity=1),
        ]
        # (10*2 + 15) * 1.1 = 35 * 1.1 = 38.50
        assert calculator.calculate_total(items) == Decimal("38.50")

    def test_percentage_discount_applied_before_tax(self, calculator):
        """Percentage discount is applied before tax."""
        items = [Item(price=Decimal("100.00"), quantity=1)]
        discount = Decimal("0.20")  # 20% off
        # (100 - 20) * 1.1 = 80 * 1.1 = 88.00
        assert calculator.calculate_total(items, discount=discount) == Decimal("88.00")

    def test_fixed_discount_applied_before_tax(self, calculator):
        """Fixed discount is applied before tax."""
        items = [Item(price=Decimal("100.00"), quantity=1)]
        # (100 - 10) * 1.1 = 90 * 1.1 = 99.00
        total = calculator.calculate_total_with_fixed_discount(
            items,
            discount_amount=Decimal("10.00")
        )
        assert total == Decimal("99.00")

    def test_discount_cannot_make_price_negative(self, calculator):
        """Discount is capped at subtotal."""
        items = [Item(price=Decimal("10.00"), quantity=1)]
        # 100% discount should make price 0, not negative
        total = calculator.calculate_total(items, discount=Decimal("1.0"))
        assert total == Decimal("0")

    def test_negative_tax_rate_raises_error(self):
        """Negative tax rate is not allowed."""
        with pytest.raises(ValueError, match="Tax rate cannot be negative"):
            PriceCalculator(tax_rate=Decimal("-0.1"))

    def test_quantity_affects_price(self, calculator):
        """Item quantity is factored into price."""
        items = [Item(price=Decimal("5.00"), quantity=10)]
        # (5 * 10) * 1.1 = 50 * 1.1 = 55.00
        assert calculator.calculate_total(items) == Decimal("55.00")

    @pytest.mark.parametrize("price,tax_rate,expected", [
        (Decimal("10.00"), Decimal("0.1"), Decimal("11.00")),
        (Decimal("100.00"), Decimal("0.2"), Decimal("120.00")),
        (Decimal("99.99"), Decimal("0.15"), Decimal("114.99")),
    ])
    def test_various_tax_rates(self, price, tax_rate, expected):
        """Calculator works with various tax rates."""
        calculator = PriceCalculator(tax_rate=tax_rate)
        items = [Item(price=price, quantity=1)]
        assert calculator.calculate_total(items) == expected
```

## JavaScript/TypeScript TDD Examples

### Example 1: Shopping Cart with TypeScript

```typescript
// tests/shopping-cart.test.ts
import { describe, it, expect, beforeEach } from 'vitest';
import { ShoppingCart, Item, CartError } from '../src/shopping-cart';

describe('ShoppingCart', () => {
  let cart: ShoppingCart;

  beforeEach(() => {
    cart = new ShoppingCart();
  });

  describe('adding items', () => {
    it('adds item to empty cart', () => {
      const item: Item = { id: '1', name: 'Widget', price: 10 };
      cart.addItem(item, 1);
      expect(cart.getItemCount()).toBe(1);
    });

    it('increases quantity when adding same item', () => {
      const item: Item = { id: '1', name: 'Widget', price: 10 };
      cart.addItem(item, 2);
      cart.addItem(item, 3);
      expect(cart.getQuantity(item.id)).toBe(5);
    });

    it('adds different items separately', () => {
      const item1: Item = { id: '1', name: 'Widget', price: 10 };
      const item2: Item = { id: '2', name: 'Gadget', price: 20 };
      cart.addItem(item1, 1);
      cart.addItem(item2, 1);
      expect(cart.getItemCount()).toBe(2);
    });

    it('throws error for negative quantity', () => {
      const item: Item = { id: '1', name: 'Widget', price: 10 };
      expect(() => cart.addItem(item, -1)).toThrow(CartError);
      expect(() => cart.addItem(item, -1)).toThrow('Quantity must be positive');
    });

    it('throws error for zero quantity', () => {
      const item: Item = { id: '1', name: 'Widget', price: 10 };
      expect(() => cart.addItem(item, 0)).toThrow(CartError);
    });
  });

  describe('removing items', () => {
    it('removes item from cart', () => {
      const item: Item = { id: '1', name: 'Widget', price: 10 };
      cart.addItem(item, 1);
      cart.removeItem(item.id);
      expect(cart.getItemCount()).toBe(0);
    });

    it('decreases quantity when removing partial amount', () => {
      const item: Item = { id: '1', name: 'Widget', price: 10 };
      cart.addItem(item, 5);
      cart.removeItem(item.id, 2);
      expect(cart.getQuantity(item.id)).toBe(3);
    });

    it('removes item completely when removing all quantity', () => {
      const item: Item = { id: '1', name: 'Widget', price: 10 };
      cart.addItem(item, 3);
      cart.removeItem(item.id, 3);
      expect(cart.getItemCount()).toBe(0);
    });

    it('throws error when removing non-existent item', () => {
      expect(() => cart.removeItem('nonexistent')).toThrow(CartError);
      expect(() => cart.removeItem('nonexistent')).toThrow('Item not in cart');
    });
  });

  describe('total calculation', () => {
    it('calculates total for single item', () => {
      const item: Item = { id: '1', name: 'Widget', price: 10 };
      cart.addItem(item, 2);
      expect(cart.getTotal()).toBe(20);
    });

    it('calculates total for multiple items', () => {
      const item1: Item = { id: '1', name: 'Widget', price: 10 };
      const item2: Item = { id: '2', name: 'Gadget', price: 25 };
      cart.addItem(item1, 2);
      cart.addItem(item2, 3);
      expect(cart.getTotal()).toBe(95); // 20 + 75
    });

    it('returns zero for empty cart', () => {
      expect(cart.getTotal()).toBe(0);
    });

    it('applies discount code', () => {
      const item: Item = { id: '1', name: 'Widget', price: 100 };
      cart.addItem(item, 1);
      cart.applyDiscountCode('SAVE20'); // 20% off
      expect(cart.getTotal()).toBe(80);
    });
  });

  describe('cart state', () => {
    it('clears all items', () => {
      const item1: Item = { id: '1', name: 'Widget', price: 10 };
      const item2: Item = { id: '2', name: 'Gadget', price: 20 };
      cart.addItem(item1, 1);
      cart.addItem(item2, 1);
      cart.clear();
      expect(cart.getItemCount()).toBe(0);
      expect(cart.getTotal()).toBe(0);
    });

    it('checks if cart is empty', () => {
      expect(cart.isEmpty()).toBe(true);
      const item: Item = { id: '1', name: 'Widget', price: 10 };
      cart.addItem(item, 1);
      expect(cart.isEmpty()).toBe(false);
    });

    it('serializes to JSON', () => {
      const item: Item = { id: '1', name: 'Widget', price: 10 };
      cart.addItem(item, 2);
      const json = cart.toJSON();
      expect(json).toHaveProperty('items');
      expect(json).toHaveProperty('total');
      expect(json.total).toBe(20);
    });
  });
});

// Implementation
// src/shopping-cart.ts
export interface Item {
  id: string;
  name: string;
  price: number;
}

export class CartError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'CartError';
  }
}

interface CartItem {
  item: Item;
  quantity: number;
}

export class ShoppingCart {
  private items: Map<string, CartItem> = new Map();
  private discountMultiplier: number = 1.0;

  addItem(item: Item, quantity: number): void {
    if (quantity <= 0) {
      throw new CartError('Quantity must be positive');
    }

    const existing = this.items.get(item.id);
    if (existing) {
      existing.quantity += quantity;
    } else {
      this.items.set(item.id, { item, quantity });
    }
  }

  removeItem(itemId: string, quantity?: number): void {
    const cartItem = this.items.get(itemId);
    if (!cartItem) {
      throw new CartError('Item not in cart');
    }

    if (quantity === undefined || quantity >= cartItem.quantity) {
      this.items.delete(itemId);
    } else {
      cartItem.quantity -= quantity;
    }
  }

  getQuantity(itemId: string): number {
    return this.items.get(itemId)?.quantity ?? 0;
  }

  getItemCount(): number {
    return this.items.size;
  }

  getTotal(): number {
    let total = 0;
    for (const { item, quantity } of this.items.values()) {
      total += item.price * quantity;
    }
    return total * this.discountMultiplier;
  }

  applyDiscountCode(code: string): void {
    // Simplified: real implementation would look up code
    if (code === 'SAVE20') {
      this.discountMultiplier = 0.8;
    }
  }

  clear(): void {
    this.items.clear();
    this.discountMultiplier = 1.0;
  }

  isEmpty(): boolean {
    return this.items.size === 0;
  }

  toJSON(): object {
    return {
      items: Array.from(this.items.values()),
      total: this.getTotal(),
    };
  }
}
```

## Go TDD Examples

### Example 1: User Service with Table-Driven Tests

```go
// user_service_test.go
package user

import (
    "testing"
    "time"
)

func TestRegisterUser(t *testing.T) {
    tests := []struct {
        name    string
        email   string
        pass    string
        age     int
        want    *User
        wantErr bool
        errMsg  string
    }{
        {
            name:  "valid registration",
            email: "test@example.com",
            pass:  "SecureP@ss123",
            age:   25,
            want: &User{
                Email:    "test@example.com",
                Age:      25,
                IsActive: true,
            },
            wantErr: false,
        },
        {
            name:    "invalid email",
            email:   "notanemail",
            pass:    "SecureP@ss123",
            age:     25,
            want:    nil,
            wantErr: true,
            errMsg:  "invalid email format",
        },
        {
            name:    "weak password",
            email:   "test@example.com",
            pass:    "weak",
            age:     25,
            want:    nil,
            wantErr: true,
            errMsg:  "password too weak",
        },
        {
            name:    "underage user",
            email:   "kid@example.com",
            pass:    "SecureP@ss123",
            age:     12,
            want:    nil,
            wantErr: true,
            errMsg:  "must be 13 or older",
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := RegisterUser(tt.email, tt.pass, tt.age)

            if (err != nil) != tt.wantErr {
                t.Errorf("RegisterUser() error = %v, wantErr %v", err, tt.wantErr)
                return
            }

            if tt.wantErr && err != nil {
                if err.Error() != tt.errMsg {
                    t.Errorf("RegisterUser() error message = %v, want %v", err.Error(), tt.errMsg)
                }
                return
            }

            if !tt.wantErr {
                if got.Email != tt.want.Email {
                    t.Errorf("RegisterUser() email = %v, want %v", got.Email, tt.want.Email)
                }
                if got.Age != tt.want.Age {
                    t.Errorf("RegisterUser() age = %v, want %v", got.Age, tt.want.Age)
                }
                if got.IsActive != tt.want.IsActive {
                    t.Errorf("RegisterUser() isActive = %v, want %v", got.IsActive, tt.want.IsActive)
                }
                if got.CreatedAt.IsZero() {
                    t.Error("RegisterUser() createdAt should not be zero")
                }
            }
        })
    }
}

func TestUser_Validate(t *testing.T) {
    tests := []struct {
        name    string
        user    *User
        wantErr bool
    }{
        {
            name: "valid user",
            user: &User{
                Email:    "test@example.com",
                Age:      25,
                IsActive: true,
            },
            wantErr: false,
        },
        {
            name: "missing email",
            user: &User{
                Email:    "",
                Age:      25,
                IsActive: true,
            },
            wantErr: true,
        },
        {
            name: "negative age",
            user: &User{
                Email:    "test@example.com",
                Age:      -5,
                IsActive: true,
            },
            wantErr: true,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := tt.user.Validate()
            if (err != nil) != tt.wantErr {
                t.Errorf("User.Validate() error = %v, wantErr %v", err, tt.wantErr)
            }
        })
    }
}

// Implementation
// user_service.go
package user

import (
    "errors"
    "regexp"
    "strings"
    "time"
)

type User struct {
    ID        string
    Email     string
    Password  string
    Age       int
    IsActive  bool
    CreatedAt time.Time
}

var emailRegex = regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)

func RegisterUser(email, password string, age int) (*User, error) {
    // Normalize email
    email = strings.ToLower(strings.TrimSpace(email))

    // Validate email
    if !emailRegex.MatchString(email) {
        return nil, errors.New("invalid email format")
    }

    // Validate age
    if age < 13 {
        return nil, errors.New("must be 13 or older")
    }

    // Validate password
    if len(password) < 8 {
        return nil, errors.New("password too weak")
    }

    user := &User{
        Email:     email,
        Age:       age,
        IsActive:  true,
        CreatedAt: time.Now(),
    }

    return user, nil
}

func (u *User) Validate() error {
    if u.Email == "" {
        return errors.New("email is required")
    }
    if u.Age < 0 {
        return errors.New("age cannot be negative")
    }
    return nil
}
```

## Rust TDD Examples

### Example 1: Result-Based Error Handling

```rust
// tests/calculator_test.rs
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_add_two_numbers() {
        let calc = Calculator::new();
        assert_eq!(calc.add(2, 3), 5);
    }

    #[test]
    fn test_subtract_two_numbers() {
        let calc = Calculator::new();
        assert_eq!(calc.subtract(5, 3), 2);
    }

    #[test]
    fn test_divide_valid_numbers() {
        let calc = Calculator::new();
        let result = calc.divide(10.0, 2.0);
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), 5.0);
    }

    #[test]
    fn test_divide_by_zero_returns_error() {
        let calc = Calculator::new();
        let result = calc.divide(10.0, 0.0);
        assert!(result.is_err());
        assert_eq!(
            result.unwrap_err().to_string(),
            "Cannot divide by zero"
        );
    }

    #[test]
    fn test_sqrt_positive_number() {
        let calc = Calculator::new();
        let result = calc.sqrt(16.0);
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), 4.0);
    }

    #[test]
    fn test_sqrt_negative_number_returns_error() {
        let calc = Calculator::new();
        let result = calc.sqrt(-4.0);
        assert!(result.is_err());
        assert_eq!(
            result.unwrap_err().to_string(),
            "Cannot take square root of negative number"
        );
    }
}

// Implementation
// src/calculator.rs
use std::error::Error;
use std::fmt;

#[derive(Debug)]
pub enum CalculatorError {
    DivisionByZero,
    NegativeSquareRoot,
}

impl fmt::Display for CalculatorError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            CalculatorError::DivisionByZero => write!(f, "Cannot divide by zero"),
            CalculatorError::NegativeSquareRoot => {
                write!(f, "Cannot take square root of negative number")
            }
        }
    }
}

impl Error for CalculatorError {}

pub struct Calculator;

impl Calculator {
    pub fn new() -> Self {
        Calculator
    }

    pub fn add(&self, a: i32, b: i32) -> i32 {
        a + b
    }

    pub fn subtract(&self, a: i32, b: i32) -> i32 {
        a - b
    }

    pub fn divide(&self, a: f64, b: f64) -> Result<f64, CalculatorError> {
        if b == 0.0 {
            return Err(CalculatorError::DivisionByZero);
        }
        Ok(a / b)
    }

    pub fn sqrt(&self, n: f64) -> Result<f64, CalculatorError> {
        if n < 0.0 {
            return Err(CalculatorError::NegativeSquareRoot);
        }
        Ok(n.sqrt())
    }
}
```

## Advanced TDD Patterns

### Mocking and Test Doubles

```python
# Python: Using unittest.mock
from unittest.mock import Mock, patch, MagicMock

def test_email_service_integration():
    """Test that user registration sends email."""
    mock_email_service = Mock()
    mock_email_service.send.return_value = True

    with patch('user_service.email_service', mock_email_service):
        user = register_user("test@example.com", "SecureP@ss123", 25)
        mock_email_service.send.assert_called_once()

# TypeScript: Using Vitest mocks
import { vi } from 'vitest';

describe('EmailService', () => {
  it('sends email on registration', async () => {
    const mockSend = vi.fn().mockResolvedValue(true);
    const emailService = { send: mockSend };

    await registerUser('test@example.com', 'SecureP@ss123', emailService);
    expect(mockSend).toHaveBeenCalledWith(
      expect.objectContaining({
        to: 'test@example.com',
      })
    );
  });
});
```

### Testing Async Code

```typescript
// Async/await testing
describe('DataFetcher', () => {
  it('fetches user data', async () => {
    const fetcher = new DataFetcher();
    const user = await fetcher.getUser('123');
    expect(user).toHaveProperty('id', '123');
  });

  it('handles fetch errors', async () => {
    const fetcher = new DataFetcher();
    await expect(fetcher.getUser('invalid')).rejects.toThrow('User not found');
  });
});
```

### Property-Based Testing

```python
# Python: Using Hypothesis
from hypothesis import given, strategies as st

@given(st.integers(), st.integers())
def test_add_is_commutative(a, b):
    """Addition should be commutative."""
    assert add(a, b) == add(b, a)

@given(st.lists(st.integers(), min_size=1))
def test_sort_is_idempotent(lst):
    """Sorting twice should equal sorting once."""
    assert sorted(sorted(lst)) == sorted(lst)
```

## Coverage Techniques

### Branch Coverage

Ensure all code paths are tested:

```python
def determine_discount(user_type, purchase_amount):
    """Calculate discount based on user type and amount."""
    if user_type == "premium":
        if purchase_amount > 100:
            return 0.20  # Test: premium + high purchase
        else:
            return 0.10  # Test: premium + low purchase
    else:
        if purchase_amount > 100:
            return 0.05  # Test: regular + high purchase
        else:
            return 0.0   # Test: regular + low purchase

# Tests must cover all 4 branches
@pytest.mark.parametrize("user_type,amount,expected", [
    ("premium", 150, 0.20),
    ("premium", 50, 0.10),
    ("regular", 150, 0.05),
    ("regular", 50, 0.0),
])
def test_discount_calculation(user_type, amount, expected):
    assert determine_discount(user_type, amount) == expected
```

### Edge Case Testing

```python
def test_string_manipulation_edge_cases():
    """Test edge cases in string processing."""
    # Empty string
    assert process("") == ""

    # Single character
    assert process("a") == "A"

    # Whitespace only
    assert process("   ") == ""

    # Special characters
    assert process("!@#$%") == "!@#$%"

    # Very long string (performance test)
    long_string = "a" * 10000
    result = process(long_string)
    assert len(result) == 10000
```
