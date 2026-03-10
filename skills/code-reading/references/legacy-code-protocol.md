# Legacy Code Protocol

Before touching old code, understand it. Legacy code evolved under pressure---respect that.

### 1. Run Existing Tests

**First action: Verify current behavior is captured.**

```bash
pytest tests/ -v
npm test
go test ./...
```

If tests don't exist: Add characterization tests (step 2).
If tests fail: Fix tests first, understand why.

### 2. Add Characterization Tests

Capture current behavior, even if it's "wrong".

```python
def test_process_data_current_behavior():
    """Characterization test: captures current behavior.

    DO NOT change this test when refactoring.
    It documents the original behavior.
    """
    input_1 = {"id": 123, "value": "test"}
    output_1 = process_data(input_1)
    assert output_1 == {"processed": True, "id": 123}

    # Test edge cases discovered in code
    input_2 = {"id": 0}
    output_2 = process_data(input_2)
    assert output_2 == {"processed": False}
```

### 3. Map Dependency Graph

Understand what depends on what.

```bash
# Who calls this function?
grep -r "process_data\(" --include="*.py"

# What does this function call?
# Read the function, list all function calls
```

**Document:**
- Dependencies (what it uses)
- Dependents (who uses it)
- Impact of changes

### 4. Identify Load-Bearing Walls

Find code that MUST NOT break.

**Load-bearing code:**
- Core business logic
- Financial calculations
- Security checks
- Data integrity validations
- Public APIs

**Red flags:**
- Comments like "DO NOT CHANGE"
- Complex validation logic
- Financial/tax calculations
- Referenced in many places

**Don't touch load-bearing walls first.** Start with safer areas.

### 5. Find Seams (Safe Change Points)

Identify where you can make changes safely.

**Seams are boundaries where you can:**
- Insert new behavior
- Test components in isolation
- Replace implementations
- Add observability

**Types:**

**Object Seam:**
```python
class PaymentProcessor(ABC):
    @abstractmethod
    def charge(self, amount): pass

# Safe to change implementations
class StripeProcessor(PaymentProcessor): ...
```

**Preprocessing Seam:**
```python
def safe_process(data):
    normalized_data = normalize_input(data)  # <- Seam: safe to change
    return legacy_process(normalized_data)   # <- Don't change
```

**Link Seam (dependency injection):**
```python
def process_order(order, payment_processor=None):
    processor = payment_processor or StripeProcessor()  # <- Seam
    return processor.charge(order.total)
```
