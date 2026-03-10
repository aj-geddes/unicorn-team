# Common Self-Review Failures

## Failure: "Works on My Machine"

**Symptom**: Code works locally but fails in CI/CD or production.

**Prevention**:
- Run tests in clean environment (docker, new virtualenv)
- Verify all dependencies declared
- Check for hardcoded paths or environment assumptions
- Test with production-like data

## Failure: Missing Edge Cases

**Symptom**: Tests pass but code breaks with unexpected input.

**Prevention**:
- Test with: null, empty, negative, huge, invalid types
- Fuzz test with random inputs
- Ask "what would break this?"

**Edge Case Checklist:**
```python
# For every function, test:
- None/null input
- Empty collection ([], {}, "")
- Single item
- Boundary values (0, -1, MAX_INT)
- Invalid types
- Concurrent access
- Resource exhaustion
```

## Failure: Unclear Intent

**Symptom**: You can't explain what the code does without looking at it.

**Prevention**:
- If you have to read the code to understand it, add comments
- Extract complex logic to well-named functions
- Use descriptive variable names

**Example:**
```python
# UNCLEAR
if t > 86400 and t < 604800:
    return True

# CLEAR
SECONDS_PER_DAY = 86400
SECONDS_PER_WEEK = 604800

def is_within_week(timestamp_seconds: int) -> bool:
    """Check if timestamp is between 1 day and 1 week ago."""
    return SECONDS_PER_DAY < timestamp_seconds < SECONDS_PER_WEEK
```

## Failure: Incomplete Error Handling

**Symptom**: Code works until first error, then crashes ungracefully.

**Prevention**:
- Identify all failure points
- Handle or propagate each one
- Log errors with context
- Return meaningful error messages

**Error Handling Checklist:**
- [ ] Network failures
- [ ] Database failures
- [ ] Invalid input
- [ ] Missing resources
- [ ] Timeout/slow response
- [ ] Concurrent modification
- [ ] Resource exhaustion
