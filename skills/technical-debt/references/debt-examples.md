# Technical Debt Examples

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
