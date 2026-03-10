# Debugging Protocols: Root-Cause Analysis

Systematic debugging methodologies for finding and fixing bugs through scientific hypothesis testing rather than trial-and-error.

## The Scientific Method of Debugging

Debugging is hypothesis testing. Each bug investigation follows:

1. **Observe** - Gather information about the failure
2. **Hypothesize** - Form testable theory about the cause
3. **Predict** - What would we see if hypothesis is true?
4. **Test** - Run experiments to confirm/deny hypothesis
5. **Conclude** - Fix root cause or revise hypothesis

## Root-Cause Debugging Protocol

### Phase 1: Reproduce Consistently

**Goal**: Create minimal, reliable reproduction of the bug.

```yaml
reproduction_checklist:
  minimal_case:
    - Strip away unrelated code
    - Reduce to smallest input that triggers bug
    - Remove dependencies when possible
    - Isolate from external state

  reliability:
    - Can you trigger it 100% of the time?
    - Does it depend on timing/state?
    - What are the preconditions?

  documentation:
    - Write reproduction steps
    - Note environmental factors
    - Save example inputs/outputs
```

**Example (Python)**:

```python
# Bug report: "User registration sometimes fails"
# Vague, can't debug this

# Minimal reproduction:
def test_bug_registration_fails_on_duplicate_email():
    """Registration fails silently when email exists."""
    # Setup: Create existing user
    existing = User.objects.create(email="test@example.com")

    # Reproduce: Try to register with same email
    result = register_user(email="test@example.com", password="secure")

    # Expected: Should raise UserRegistrationError
    # Actual: Returns None, no error
    assert result is None  # This is the bug!
```

### Phase 2: Form Hypothesis

**Goal**: Develop testable theory about what's causing the bug.

```yaml
hypothesis_framework:
  what_failed:
    - What function/module is involved?
    - What operation failed?
    - What was the unexpected outcome?

  possible_causes:
    - Logic error (wrong condition)
    - State error (wrong variable value)
    - Timing error (race condition)
    - Integration error (external service)
    - Data error (unexpected input)

  hypothesis_statement:
    format: "I think X is happening because Y, which causes Z"
    example: "I think registration is failing because the duplicate
             check is catching the exception but not re-raising it,
             which causes the function to return None"
```

**Hypothesis Quality Checklist**:
- [ ] Specific (not "something is wrong with registration")
- [ ] Testable (can be proven true/false)
- [ ] Explains the observed behavior
- [ ] Predicts what you'll see when debugging

### Phase 3: Test Hypothesis

**Goal**: Gather evidence to confirm or deny the hypothesis.

#### Strategy 1: Add Strategic Logging

```python
# Hypothesis: Duplicate check is swallowing the exception

def register_user(email, password):
    logger.debug(f"Starting registration for {email}")

    try:
        # Check for duplicate
        existing = User.objects.get(email=email)
        logger.debug(f"Found existing user: {existing.id}")  # ADD THIS
        raise UserRegistrationError("Email already exists")
    except User.DoesNotExist:
        logger.debug("No existing user, proceeding")  # ADD THIS
        pass
    except Exception as e:
        logger.error(f"Unexpected error: {e}")  # ADD THIS
        return None  # HYPOTHESIS: This is being hit!

    user = User.objects.create(email=email, password=hash_password(password))
    logger.debug(f"Created user: {user.id}")
    return user
```

Run test again and check logs:
```
DEBUG: Starting registration for test@example.com
DEBUG: Found existing user: 123
ERROR: Unexpected error: UserRegistrationError("Email already exists")
```

**Hypothesis confirmed!** The bare `except` is catching our intentional exception.

#### Strategy 2: Use Debugger with Breakpoints

```python
# Set breakpoint at suspected location
def register_user(email, password):
    try:
        existing = User.objects.get(email=email)
        breakpoint()  # Stop here and examine state
        raise UserRegistrationError("Email already exists")
    except User.DoesNotExist:
        pass
```

When debugger stops:
```python
(Pdb) print(existing)
<User: test@example.com>
(Pdb) print(type(e))
NameError: name 'e' is not defined  # No exception yet!
(Pdb) next
UserRegistrationError: Email already exists
(Pdb) next  # Steps into except block
(Pdb) print(e)  # Now exception is caught
UserRegistrationError("Email already exists")
```

#### Strategy 3: Add Assertions

```python
# Hypothesis: Variable X should never be None here

def process_payment(order):
    payment_method = order.get_payment_method()

    # Test hypothesis with assertion
    assert payment_method is not None, \
        f"Payment method is None for order {order.id}"

    # If assertion fails, hypothesis was right
    return payment_method.charge(order.total)
```

#### Strategy 4: Binary Search (Divide and Conquer)

```python
# Bug: Function returns wrong result
# Hypothesis: Error is in middle section

def complex_calculation(data):
    step1 = preprocess(data)
    print(f"After preprocess: {step1}")  # Checkpoint 1

    step2 = transform(step1)
    print(f"After transform: {step2}")   # Checkpoint 2

    step3 = aggregate(step2)
    print(f"After aggregate: {step3}")   # Checkpoint 3

    return step3

# Check which checkpoint shows wrong data
# Then narrow down to that section
```

### Phase 4: Fix Root Cause

**Goal**: Fix the underlying cause, not the symptom.

```yaml
root_cause_vs_symptom:
  symptom_fix:
    problem: "Variable is None"
    bad_fix: "if var is None: var = default_value"
    why_bad: "Doesn't explain WHY var is None"

  root_cause_fix:
    problem: "Variable is None because initialization failed"
    good_fix: "Ensure initialization always succeeds or fails fast"
    why_good: "Addresses why var is None in the first place"
```

**Example: Our Registration Bug**

```python
# SYMPTOM FIX (bad):
def register_user(email, password):
    try:
        existing = User.objects.get(email=email)
        raise UserRegistrationError("Email already exists")
    except:
        pass  # Keep bare except, just check result later

    user = User.objects.create(email=email, password=hash_password(password))

    # Symptom fix: Check if user is None
    if user is None:  # This never actually helps!
        raise UserRegistrationError("Registration failed")

    return user

# ROOT CAUSE FIX (good):
def register_user(email, password):
    try:
        existing = User.objects.get(email=email)
        raise UserRegistrationError("Email already exists")
    except User.DoesNotExist:
        # Only catch the specific exception we expect
        pass
    # Don't catch UserRegistrationError - let it propagate!

    user = User.objects.create(email=email, password=hash_password(password))
    return user
```

### Phase 5: Verify Fix and Prevent Recurrence

**Goal**: Ensure fix works and bug won't return.

```yaml
verification_steps:
  1_test_passes:
    - Run the failing test
    - Verify it now passes
    - Run multiple times (if flaky)

  2_no_regression:
    - Run full test suite
    - Ensure no other tests broke
    - Check related functionality

  3_edge_cases:
    - What similar bugs could exist?
    - Test variations of the fix
    - Add tests for edge cases

  4_documentation:
    - Document the bug cause
    - Explain why fix works
    - Note if refactoring needed
```

**Example: Complete Bug Fix with Tests**

```python
# tests/test_user_registration.py
def test_duplicate_email_raises_error():
    """Registration should raise error for duplicate email, not return None."""
    # Create existing user
    User.objects.create(email="test@example.com", password="hash1")

    # Attempt duplicate registration should raise error
    with pytest.raises(UserRegistrationError, match="Email already exists"):
        register_user(email="test@example.com", password="secure")

def test_similar_bug_duplicate_username():
    """Also test username duplicates (similar bug could exist)."""
    User.objects.create(username="testuser", password="hash1")

    with pytest.raises(UserRegistrationError, match="Username already exists"):
        register_user(username="testuser", password="secure")

# Implementation with fix
def register_user(email=None, username=None, password=None):
    """Register new user with email or username."""
    # Check email duplicate
    if email:
        try:
            User.objects.get(email=email)
            raise UserRegistrationError("Email already exists")
        except User.DoesNotExist:
            pass

    # Check username duplicate
    if username:
        try:
            User.objects.get(username=username)
            raise UserRegistrationError("Username already exists")
        except User.DoesNotExist:
            pass

    return User.objects.create(
        email=email,
        username=username,
        password=hash_password(password)
    )
```

## Language-Specific Debugging Tools

### Python Debugging

#### Using pdb (Python Debugger)

```python
import pdb

def buggy_function(data):
    processed = []
    for item in data:
        pdb.set_trace()  # Debugger stops here
        result = complex_processing(item)
        processed.append(result)
    return processed

# Or use breakpoint() in Python 3.7+
def buggy_function(data):
    processed = []
    for item in data:
        breakpoint()  # Cleaner syntax
        result = complex_processing(item)
        processed.append(result)
    return processed
```

**PDB Commands**:
```
n (next)      - Execute next line
s (step)      - Step into function
c (continue)  - Continue execution
l (list)      - Show code context
p var         - Print variable value
pp var        - Pretty-print variable
w (where)     - Show stack trace
u (up)        - Move up stack frame
d (down)      - Move down stack frame
```

#### Logging Levels

```python
import logging

logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

logger = logging.getLogger(__name__)

def process_order(order):
    logger.debug(f"Processing order {order.id}")
    logger.info(f"Order total: ${order.total}")

    try:
        payment = charge_payment(order)
        logger.info(f"Payment successful: {payment.id}")
    except PaymentError as e:
        logger.error(f"Payment failed: {e}", exc_info=True)
        raise

    logger.debug(f"Order {order.id} complete")
```

#### Python Assertions for Debugging

```python
def calculate_discount(price, discount_rate):
    # Defensive assertions during development
    assert price >= 0, f"Price cannot be negative: {price}"
    assert 0 <= discount_rate <= 1, f"Discount rate must be 0-1: {discount_rate}"

    discount = price * discount_rate

    assert discount <= price, "Discount exceeds price!"

    return price - discount
```

### JavaScript/TypeScript Debugging

#### Console Debugging

```typescript
function processData(data: DataItem[]): ProcessedData {
    console.log('Input data:', data);  // See input

    const filtered = data.filter(item => {
        console.log('Checking item:', item);  // See each item
        return item.isValid;
    });

    console.log('Filtered data:', filtered);  // See intermediate result

    const result = transform(filtered);

    console.log('Final result:', result);  // See output

    return result;
}

// Better: Use console methods
console.debug('Detailed debug info');
console.info('General information');
console.warn('Warning message');
console.error('Error occurred');
console.table(arrayOfObjects);  // Nice table view
console.time('operation');
// ... code ...
console.timeEnd('operation');  // Shows duration
```

#### Browser DevTools Debugging

```typescript
// Set breakpoint in code
function complexOperation(value: number) {
    debugger;  // Execution stops here in browser
    return value * 2;
}

// Conditional breakpoint (in DevTools):
// Right-click line number -> "Add conditional breakpoint"
// Condition: value > 100
```

#### Node.js Debugging

```bash
# Run with inspector
node --inspect-brk app.js

# Or in package.json
{
  "scripts": {
    "debug": "node --inspect-brk app.js"
  }
}

# Then open chrome://inspect in Chrome
```

### Go Debugging

#### Printf Debugging

```go
import "log"

func ProcessOrder(order Order) error {
    log.Printf("DEBUG: Processing order %d", order.ID)
    log.Printf("DEBUG: Order total: $%.2f", order.Total)

    err := validateOrder(order)
    if err != nil {
        log.Printf("ERROR: Validation failed: %v", err)
        return err
    }

    log.Printf("DEBUG: Order validated successfully")
    return nil
}
```

#### Using Delve Debugger

```bash
# Install delve
go install github.com/go-delve/delve/cmd/dlv@latest

# Debug a test
dlv test -- -test.run TestProcessOrder

# Debug an application
dlv debug main.go

# Delve commands:
# break main.ProcessOrder  - Set breakpoint
# continue                 - Continue execution
# next                     - Next line
# step                     - Step into
# print order              - Print variable
# locals                   - Show local variables
# stack                    - Show stack trace
```

#### Structured Logging

```go
import "go.uber.org/zap"

logger, _ := zap.NewDevelopment()
defer logger.Sync()

func ProcessOrder(order Order) error {
    logger.Debug("processing order",
        zap.Int("orderId", order.ID),
        zap.Float64("total", order.Total),
    )

    err := validateOrder(order)
    if err != nil {
        logger.Error("validation failed",
            zap.Int("orderId", order.ID),
            zap.Error(err),
        )
        return err
    }

    return nil
}
```

### Rust Debugging

#### Debug Printing

```rust
fn process_data(items: &[Item]) -> Vec<ProcessedItem> {
    // Quick debug print
    dbg!(items);

    let filtered: Vec<_> = items.iter()
        .filter(|item| {
            dbg!(item);  // Print each item
            item.is_valid
        })
        .collect();

    dbg!(&filtered);  // Print filtered results

    filtered.into_iter()
        .map(|item| process_item(item))
        .collect()
}

// Better formatting
println!("Debug: {:?}", value);  // Debug format
println!("Pretty: {:#?}", value);  // Pretty debug format
```

#### Using rust-gdb or rust-lldb

```bash
# Build with debug symbols
cargo build

# Debug with GDB
rust-gdb target/debug/myapp

# Or with LLDB
rust-lldb target/debug/myapp

# Commands:
# break main::process_data
# run
# print item
# next
# step
# continue
```

## Advanced Debugging Techniques

### Rubber Duck Debugging

Explain the problem out loud (to a rubber duck):

```markdown
"Okay, so this function is supposed to calculate the total price...
It takes in a list of items... wait, what if the list is empty?
Oh! I'm not handling the empty case. That's the bug!"
```

### Time-Travel Debugging (rr for Linux)

```bash
# Record execution
rr record ./myprogram

# Replay with reverse execution
rr replay

# In debugger:
# reverse-next     - Go backwards one line
# reverse-continue - Go backwards to previous breakpoint
```

### Differential Debugging

```python
# Compare working vs broken version

def working_version(data):
    """Known good implementation."""
    return sorted(data, key=lambda x: x.value)

def new_version(data):
    """Buggy new implementation."""
    return sorted(data, key=lambda x: x.value, reverse=True)

def test_compare_versions():
    """Find where they differ."""
    test_data = [Item(1), Item(3), Item(2)]

    working = working_version(test_data)
    new = new_version(test_data)

    print(f"Working: {working}")
    print(f"New: {new}")

    assert working == new  # Fails! Now we know the difference
```

### Memory Debugging (Python)

```python
import tracemalloc
import sys

def find_memory_leak():
    tracemalloc.start()

    # Take snapshot before
    snapshot1 = tracemalloc.take_snapshot()

    # Run suspect code
    suspect_function()

    # Take snapshot after
    snapshot2 = tracemalloc.take_snapshot()

    # Compare
    top_stats = snapshot2.compare_to(snapshot1, 'lineno')

    print("[ Top 10 memory increases ]")
    for stat in top_stats[:10]:
        print(stat)
```

### Race Condition Debugging

```python
import threading
import time

# Add synchronization logging
def thread_function(name):
    print(f"[{time.time()}] Thread {name}: starting")

    with lock:
        print(f"[{time.time()}] Thread {name}: acquired lock")
        # Critical section
        shared_data.append(name)
        time.sleep(0.1)
        print(f"[{time.time()}] Thread {name}: releasing lock")

    print(f"[{time.time()}] Thread {name}: done")

# Run multiple times to catch timing-dependent bugs
for i in range(100):
    shared_data = []
    threads = [threading.Thread(target=thread_function, args=(f"T{j}",))
               for j in range(5)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    # Check for corruption
    assert len(shared_data) == 5, f"Race condition detected: {shared_data}"
```

## Debugging Checklist

Before diving into complex debugging:

```markdown
- [ ] Can you reproduce the bug consistently?
- [ ] Have you read the error message completely?
- [ ] Have you checked the logs?
- [ ] Have you verified your assumptions about the data?
- [ ] Have you checked recent changes (git diff)?
- [ ] Have you tested with minimal input?
- [ ] Have you isolated the problem to a specific function?
- [ ] Have you formed a specific hypothesis?
- [ ] Have you written a failing test?
```

## Anti-Patterns

```markdown
❌ Random changes hoping something works
❌ Adding print statements without hypothesis
❌ Debugging in production
❌ Not cleaning up debug code
❌ Not writing a test for the bug
❌ Fixing symptoms instead of root cause
❌ Not verifying the fix works
❌ Not checking for similar bugs
```

## Remember

- Debugging is **hypothesis testing**, not guessing
- Always **reproduce first**, debug second
- **Write a test** that captures the bug
- Fix the **root cause**, not the symptom
- **Verify** the fix with tests
- **Clean up** debug code before committing
