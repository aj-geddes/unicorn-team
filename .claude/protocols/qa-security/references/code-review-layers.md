# Code Review Layers: Detailed Checklists

Expanded checklists for each of the four review layers referenced in the QA-Security SKILL.md.

## Layer 2: Logic Review (Expanded)

### Does It Do What It Claims?

- [ ] Function/method names match behavior
- [ ] Comments align with implementation (or are they outdated?)
- [ ] Tests actually verify the stated requirements
- [ ] No hidden side effects
- [ ] Return values match documentation

### Edge Cases Handled?

- [ ] Empty inputs (null, empty string, empty list)
- [ ] Boundary values (min, max, zero, negative)
- [ ] Concurrent access (if stateful)
- [ ] Resource exhaustion (memory, disk, connections)
- [ ] Unicode and special characters
- [ ] Very large inputs (performance)
- [ ] Very small inputs (single element, single character)

### Error Handling Complete?

- [ ] All failure modes identified
- [ ] Errors logged with context (not just "error occurred")
- [ ] User-facing errors are helpful (not stack traces)
- [ ] Resources cleaned up on error paths (files closed, locks released)
- [ ] Retries with backoff for transient failures
- [ ] Timeouts configured for external calls
- [ ] Circuit breakers for cascading failure prevention

### Data Flow Clear?

- [ ] Trace input -> processing -> output
- [ ] No data loss or corruption possible
- [ ] Transformations are reversible (if needed)
- [ ] State transitions are valid
- [ ] No race conditions in shared state

## Layer 3: Design Review (Expanded)

### Single Responsibility

- [ ] Each function/class does ONE thing well
- [ ] If you can describe it with "and", it is doing too much
- [ ] Easy to name without using "Manager", "Helper", "Utility"
- [ ] Changes to one concern don't ripple to unrelated code

### Appropriate Abstraction Level

- [ ] Low-level details hidden behind clear interfaces
- [ ] Not over-engineered (no patterns for pattern's sake)
- [ ] Not under-engineered (no copy-paste code)
- [ ] Interfaces are minimal and focused
- [ ] Dependencies flow in one direction

### Complexity Analysis

- [ ] Cognitive complexity is low (can understand without mental gymnastics)
- [ ] Cyclomatic complexity < 10 per function
- [ ] No deeply nested conditionals (> 3 levels)
- [ ] No functions > 50 lines (split if larger)
- [ ] No files > 500 lines (split if larger)

### Consistency

- [ ] Follows existing codebase patterns
- [ ] Naming conventions match project style
- [ ] Error handling matches project patterns
- [ ] Logging format consistent
- [ ] Import ordering consistent

## Layer 4: Security Review (Expanded)

See: `security-review-checklists.md` for comprehensive security checklists.

Quick security scan during code review:

- [ ] No SQL injection vectors (string interpolation in queries)
- [ ] No XSS vectors (unescaped user input in HTML)
- [ ] No command injection (user input in shell commands)
- [ ] No path traversal (user input in file paths)
- [ ] No hardcoded secrets
- [ ] No insecure deserialization
- [ ] No open redirects
- [ ] No SSRF vectors (user-controlled URLs in server requests)
