# Code Reading Techniques

### Follow the Happy Path First

Understand the main flow before edge cases.

1. Trace one successful execution start to finish
2. Ignore error handling initially
3. Note main data transformations
4. Document happy path flow
5. THEN read error paths

### Map Side Effects

Find hidden consequences.

**Side Effects:**
- Database writes
- File system changes
- API calls
- Email/notification sending
- Event publishing
- Cache updates

**Mark them:**
```python
def place_order(user_id, items):
    user = db.get_user(user_id)              # READ
    order = Order(user=user, items=items)

    db.save(order)                           # WRITE <- side effect
    inventory.reserve(items)                 # WRITE <- side effect
    payment.charge(user.card, order.total)   # WRITE <- side effect
    email.send_confirmation(user.email)      # WRITE <- side effect

    return order
```

### Identify Invariants

Assumptions that must ALWAYS be true.

**Common Invariants:**
- Balance never negative
- Email unique per user
- Order total = sum of items
- Enum values match database

**Example:**
```python
class BankAccount:
    def withdraw(self, amount):
        # INVARIANT: balance >= 0
        if self.balance - amount < 0:
            raise InsufficientFunds()
        self.balance -= amount
```

**When Refactoring:** Preserve all invariants. Add tests to verify them.

### Note Coupling Points

Coupling = where modules depend on each other. High coupling = hard to change.

**Loose Coupling (good):**
```python
def calculate_tax(amount, rate):
    return amount * rate
```

**Tight Coupling (bad):**
```python
GLOBAL_CONFIG = {}

def process():
    return GLOBAL_CONFIG['api_key']  # Depends on global
```

**Document high coupling areas.** They're risky to change.
