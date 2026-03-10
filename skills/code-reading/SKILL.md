---
name: code-reading
description: >-
  Strategic code comprehension protocol for navigating existing codebases.
  ALWAYS trigger on "understand this code", "how does this work", "refactor",
  "before changing", "legacy code", "code review", "what does this do",
  "explain this codebase", "walk me through", "unfamiliar code", "read through".
  Use when exploring unfamiliar code, preparing to modify legacy systems,
  debugging complex issues, or conducting code reviews. Different from
  pattern-transfer which maps known solutions across domains -- this skill
  builds accurate mental models of existing code.
---
<!-- Last reviewed: 2026-03 -->

# Code Reading

## Strategic Reading Protocol

### 1. Entry Points First

Start where execution begins. Never read alphabetically.

```bash
# Find entry points
grep -r "app.run\|app.listen\|@app.route\|def main\|if __name__" --include="*.py" --include="*.js"
```

**Read order:** Main entry -> route definitions -> request handlers -> business logic -> data layer -> utilities

### 2. Data Flow Tracing

Follow: INPUT -> VALIDATION -> PROCESSING -> STORAGE -> OUTPUT

At each step ask: Where does data enter? What validations? How transformed? Where stored? What side effects?

### 3. Error Path Mapping

```bash
grep -r "try:\|except\|catch\|raise\|throw" --include="*.py" --include="*.js"
```

Map: What fails? How detected? How handled (retry/fallback/propagate)? What messages returned? Errors logged with context?

### 4. Integration Points

Identify system boundaries (high-risk areas): APIs, databases, message queues, file systems, external services.

Document for each: expected format, return format, failure modes, retry logic, timeouts.

## Comprehension Levels

| Level | Question | Technique |
|-------|----------|-----------|
| L1: Behavior | What does it DO? (inputs, outputs, side effects) | Read signature + docstring + tests |
| L2: Mechanics | HOW does it work? (algorithm, data structures, steps) | Read implementation |
| L3: Design | WHY this way? (tradeoffs, constraints, optimization target) | Comments, git log/blame, issue tracker |
| L4: Impact | What ELSE affected? (callers, dependencies, blast radius) | `grep -r "function_name"`, check tests |

## Legacy Code Protocol

1. **Run existing tests** -- verify current behavior is captured
2. **Add characterization tests** -- document current behavior (even if "wrong")
3. **Map dependency graph** -- who calls this? what does this call?
4. **Identify load-bearing walls** -- critical code that MUST NOT break
5. **Find seams** -- safe change points (object, preprocessing, link seams)

See `references/legacy-code-protocol.md` for detailed steps and seam patterns.

## Reading Techniques

| Technique | Purpose |
|-----------|---------|
| Follow happy path first | Understand main flow before edge cases |
| Map side effects | Find hidden consequences (DB writes, API calls, emails) |
| Identify invariants | Assumptions that must ALWAYS hold |
| Note coupling points | High coupling = high risk areas |

See `references/reading-techniques.md` for detailed guidance and examples.

## Reading Checklist

Starting a new codebase:

- [ ] Find entry points (main, routes, handlers)
- [ ] Trace data flow for one request/feature
- [ ] Map error handling and failure modes
- [ ] Identify external dependencies
- [ ] Run existing tests
- [ ] Locate critical business logic
- [ ] Note high coupling points
- [ ] Document in 1-page architecture diagram

## Before Changing Legacy Code

- [ ] Run existing tests (capture baseline)
- [ ] Add characterization tests (document current behavior)
- [ ] Map dependency graph (who calls this? what does this call?)
- [ ] Identify load-bearing walls (critical paths)
- [ ] Find seams (safe change points)
- [ ] Make smallest change possible
- [ ] Verify behavior unchanged (tests pass)

## Common Patterns to Recognize

Predict structure without reading every line:

- **Model-View-Controller** -- separation of concerns
- **Repository Pattern** -- data access abstraction
- **Strategy Pattern** -- algorithm selection
- **Observer Pattern** -- event notification
- **Factory Pattern** -- object creation
- **Decorator Pattern** -- behavior extension
- **Adapter Pattern** -- interface translation
