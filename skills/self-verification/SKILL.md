---
name: self-verification
description: >-
  Guides the user through systematic pre-commit quality verification. ALWAYS
  trigger on "review my code", "check my work", "before commit", "self-review",
  "quality check", "am I ready to commit", "pre-commit review", "code quality",
  "verify my changes", "sanity check", "review before merge", "is this ready".
  Use before any commit, merge, or code review submission.
---
<!-- Last reviewed: 2026-03 -->

# Self-Verification

Run `scripts/self-review.sh` or execute these 6 steps manually before every commit.

---

## 1. Review Staged Changes

```bash
git diff --staged
```

- [ ] Would I approve this in code review?
- [ ] Does this change do ONE thing well?
- [ ] Is the change focused or sprawling?

## 2. Completeness Check

- [ ] Functionality does what was requested
- [ ] Edge cases handled or documented as out-of-scope
- [ ] All failure paths covered with clear error messages
- [ ] Key operations logged at appropriate level
- [ ] All inputs validated at boundaries
- [ ] Outputs properly encoded/sanitized

## 3. Quality Check

- [ ] No TODOs/FIXMEs/HACKs (resolve or file tickets)
- [ ] No debug code (print, console.log, breakpoint, pdb)
- [ ] No commented-out code (it's in git history)
- [ ] Variables/functions/classes are self-documenting
- [ ] Functions each do one thing well (< 50 lines ideal)
- [ ] No magic numbers (extract to named constants)
- [ ] Follows project style conventions

```bash
# Automated scan for debug artifacts
git diff --cached | grep -E "breakpoint|pdb|console\.log|debugger|TODO|FIXME|HACK"
```

## 4. Test Verification

- [ ] All tests pass
- [ ] Coverage >= 80% on new code
- [ ] Edge cases tested (not just happy path)
- [ ] Error paths tested
- [ ] Test names describe what they verify
- [ ] No flaky tests

```bash
# Python
pytest --cov=. --cov-report=term-missing --cov-fail-under=80

# JavaScript
npm test -- --coverage --coverageThreshold='{"global":{"lines":80}}'

# Go
go test -cover ./...
```

## 5. Security Check

- [ ] No secrets (API keys, passwords, tokens) in code
- [ ] No PII or credentials in logs
- [ ] All external inputs validated
- [ ] SQL params parameterized, HTML escaped, URLs encoded
- [ ] Protected endpoints enforce auth
- [ ] Code runs with minimum required permissions

```bash
# Scan for leaked secrets
git diff --cached | grep -iE "api[_-]?key|password|secret|token"

# Python security scan
bandit -r . -q

# JavaScript
npm audit
```

**Security questions to answer:**

| # | Question |
|---|----------|
| 1 | Who can call this? (Authentication) |
| 2 | Are they allowed to? (Authorization) |
| 3 | What if they send malicious input? (Validation) |
| 4 | What if they send huge input? (Resource limits) |
| 5 | Can they see data they shouldn't? (Data exposure) |
| 6 | Will we know if they try? (Audit logging) |

## 6. Documentation Check

- [ ] Public APIs/functions have docstrings
- [ ] Complex logic has comments explaining WHY
- [ ] Usage examples for complex APIs
- [ ] README updated if external behavior changed
- [ ] CHANGELOG updated for user-visible changes
- [ ] Migration guide if breaking changes exist

---

## Fresh Eyes Techniques

Use these to break the "see what you intended" bias:

1. **Time Gap** (10+ min) -- let your brain forget what you meant
2. **Context Switch** -- work on something else, then return
3. **Read Aloud** -- speaking forces slower processing
4. **Rubber Duck** -- explain code to an imaginary colleague
5. **Reverse Review** -- read diff from last line to first

See `references/fresh-eyes-techniques.md` for detailed guides.

---

## Common Self-Review Failures

| Failure | Symptom | Prevention |
|---------|---------|------------|
| "Works on My Machine" | Fails in CI/production | Test in clean environment |
| Missing Edge Cases | Breaks with unexpected input | Test null, empty, negative, huge |
| Unclear Intent | Can't explain without reading | Extract to well-named functions |
| Incomplete Error Handling | Crashes on first error | Identify all failure points |

See `references/self-review-failures.md` for detailed prevention strategies.

---

## Script

Run the interactive self-review protocol:

```bash
skills/self-verification/scripts/self-review.sh
# or
./scripts/self-review.sh && git commit -m "your message"
```

---

## References

- `references/fresh-eyes-techniques.md` -- detailed technique guides
- `references/self-review-failures.md` -- prevention strategies with examples
- `scripts/self-review.sh` -- interactive self-review script
