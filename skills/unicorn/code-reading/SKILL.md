---
name: code-reading
description: >
  Strategic code comprehension protocol for understanding existing codebases.
  Use when exploring unfamiliar code, preparing to modify legacy systems, debugging
  complex issues, or conducting code reviews. Triggers: "understand this code",
  "how does this work", "refactor", "before changing", "legacy code", "code review".
  Implements structural reading patterns, comprehension levels, and legacy code
  protocols to build accurate mental models efficiently.
---

# Code Reading: The 80% Skill

Developers spend 80% of their time reading code. Master strategic reading to understand systems quickly and accurately.

## Core Principle

**Read code structurally, not linearly.**

Build an accurate mental model: what the code does, how it works, why it exists this way, and what would break if you change it.

---

## Strategic Reading Protocol

### 1. Entry Points First

Start where execution begins. Don't read files alphabetically.

**Find Entry Points:**
```bash
# Web services: main(), app.run(), serve()
# CLI: main.py, index.js, main.go
# Routes: @app.route, app.get, @router
grep -r "app.run\|app.listen\|@app.route" --include="*.py" --include="*.js"
```

**Read Order:**
1. Main entry point
2. Route definitions
3. Request handlers
4. Business logic
5. Data layer
6. Utilities

### 2. Data Flow Tracing

Follow data through the system.

**Pattern:**
```
INPUT → VALIDATION → PROCESSING → STORAGE → OUTPUT
```

**Questions:**
- Where does data enter?
- What validations are applied?
- How is data transformed?
- Where is data stored?
- What format is returned?
- What side effects occur?

### 3. Error Path Mapping

Understand failure modes.

**Find Error Handling:**
```bash
grep -r "try:\|except\|catch\|raise\|throw" --include="*.py" --include="*.js"
```

**Map:**
- What can go wrong at each step?
- How are errors detected?
- How are errors handled? (retry, fallback, propagate)
- What error messages are returned?
- Are errors logged with context?

### 4. Integration Points

Identify system boundaries (high-risk areas).

**External Dependencies:**
- APIs (REST, GraphQL, gRPC)
- Databases (SQL, NoSQL, cache)
- Message queues
- File systems
- External services

**Document:**
- Expected format
- Return format
- Failure modes
- Retry logic
- Timeouts

---

## Comprehension Levels

Build understanding progressively.

### L1: What Does It DO? (Behavior)

Observable behavior from the outside.

- What inputs does it accept?
- What outputs does it produce?
- What side effects does it have?
- What is the happy path?

**Technique:** Read function signature + docstring + tests.

### L2: HOW Does It Work? (Mechanics)

Implementation logic.

- What algorithm is used?
- What data structures?
- What are the steps?
- What are key variables/functions?

**Technique:** Read the implementation code.

### L3: WHY This Way? (Design Decisions)

Reasoning behind choices.

- Why this algorithm over alternatives?
- What constraints shaped this?
- What tradeoffs were made?
- What did the author optimize for?

**Sources:**
- Inline comments
- Commit messages (`git log -p filename`)
- Git blame
- Issue tracker references
- Team knowledge

### L4: What ELSE Affected? (Impact Radius)

Dependencies and blast radius.

- What code calls this?
- What does this code call?
- What data structures does it depend on?
- What invariants must be maintained?
- What would break if I change this?

**Technique:**
```bash
# Find callers
grep -r "function_name" --include="*.py"

# Check tests
grep -r "test.*function_name" --include="test_*.py"
```

---

## Legacy Code Protocol

Before touching old code, understand it. Legacy code evolved under pressure—respect that.

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
    normalized_data = normalize_input(data)  # ← Seam: safe to change
    return legacy_process(normalized_data)   # ← Don't change
```

**Link Seam (dependency injection):**
```python
def process_order(order, payment_processor=None):
    processor = payment_processor or StripeProcessor()  # ← Seam
    return processor.charge(order.total)
```

---

## Reading Techniques

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

    db.save(order)                           # WRITE ← side effect
    inventory.reserve(items)                 # WRITE ← side effect
    payment.charge(user.card, order.total)   # WRITE ← side effect
    email.send_confirmation(user.email)      # WRITE ← side effect

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

---

## Quick Reference

### Reading Checklist

Starting a new codebase?

- [ ] Find entry points (main, routes, handlers)
- [ ] Trace data flow for one request/feature
- [ ] Map error handling and failure modes
- [ ] Identify external dependencies
- [ ] Run existing tests
- [ ] Locate critical business logic
- [ ] Note high coupling points
- [ ] Document in 1-page architecture diagram

### Before Changing Legacy Code

- [ ] Run existing tests (capture baseline)
- [ ] Add characterization tests (document current behavior)
- [ ] Map dependency graph (who calls this? what does this call?)
- [ ] Identify load-bearing walls (critical paths)
- [ ] Find seams (safe change points)
- [ ] Make smallest change possible
- [ ] Verify behavior unchanged (tests pass)

### Comprehension Levels Quick Guide

- **L1 (Behavior)**: What does it do? (inputs, outputs, side effects)
- **L2 (Mechanics)**: How does it work? (algorithm, data structures)
- **L3 (Design)**: Why this way? (decisions, tradeoffs, constraints)
- **L4 (Impact)**: What else affected? (callers, dependencies, blast radius)

### Common Patterns to Recognize

When you see these patterns, predict structure without reading every line:

- **Model-View-Controller**: Separation of concerns
- **Repository Pattern**: Data access abstraction
- **Strategy Pattern**: Algorithm selection
- **Observer Pattern**: Event notification
- **Factory Pattern**: Object creation
- **Decorator Pattern**: Behavior extension
- **Adapter Pattern**: Interface translation

---

## Summary

```
┌─────────────────────────────────────────────────────────┐
│  "Code is read 10x more than it's written"              │
│                                                          │
│  Master reading to:                                     │
│  • Understand systems faster                            │
│  • Make safer changes                                   │
│  • Debug more effectively                               │
│  • Write better code                                    │
└─────────────────────────────────────────────────────────┘
```

**Key Principles:**

1. **Read Structurally** - Entry points → data flow → errors → boundaries
2. **Build Progressive Understanding** - Behavior → mechanics → design → impact
3. **Legacy Code Requires Protocol** - Tests → characterization → map → seams
4. **Follow the Happy Path First** - Main flow before edge cases
5. **Make Side Effects Visible** - Track all writes
6. **Identify Invariants** - Assumptions that must always hold
7. **Note Coupling** - High coupling = high risk

**The 10X Difference:**

- 1X Developer: Reads linearly, gets lost, makes risky changes
- 10X Developer: Reads strategically, understands quickly, changes safely

Code reading is not about speed. It's about building an accurate mental model for informed decisions.
