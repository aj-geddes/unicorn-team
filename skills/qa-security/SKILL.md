---
name: qa-security
description: >-
  Protocol skill preloaded by the QA-Security agent. Provides 4-layer code
  review protocol (automated, logic, design, security), quality gate criteria,
  STRIDE-based security audit workflow, and structured review report formats.
  Not triggered directly.
---

# QA-Security Agent

## Code Review Protocol

Execute reviews in four layers, each building on the previous.

### Layer 1: Automated Checks (Pre-Review Gate)

```bash
# All must pass before manual review
pytest -v --tb=short                                    # Tests: 100% pass
pytest --cov=. --cov-fail-under=80 --cov-report=term   # Coverage: >= 80%
ruff check . && ruff format --check .                   # Linting: clean
mypy . --ignore-missing-imports                         # Types: clean
bandit -r . -f json                                     # Security: no high/critical
```

If any fail: return to Developer with specific errors. Do not proceed.

### Layer 2: Logic Review

- [ ] Function/method names match behavior
- [ ] Tests verify stated requirements (not just run)
- [ ] No hidden side effects
- [ ] Empty inputs handled (null, empty string, empty list)
- [ ] Boundary values handled (min, max, zero, negative)
- [ ] All failure modes identified and handled
- [ ] Errors logged with context (not bare "error occurred")
- [ ] Resources cleaned up on error paths (files, locks, connections)

### Layer 3: Design Review

- [ ] Each function/class does ONE thing
- [ ] Cognitive complexity is low
- [ ] Cyclomatic complexity < 10 per function
- [ ] No deeply nested conditionals (> 3 levels)
- [ ] No functions > 50 lines
- [ ] Follows existing codebase patterns and naming conventions

### Layer 4: Security Review

- [ ] All user input validated (type, length, format, range)
- [ ] Validation on server side (never trust client)
- [ ] Allowlists over denylists
- [ ] Input sanitized before use (SQL, HTML, shell)
- [ ] No direct string interpolation into queries
- [ ] No hardcoded secrets (API keys, passwords, tokens)
- [ ] No secrets in logs or error messages
- [ ] Authentication required for protected resources
- [ ] Authorization checked on every request
- [ ] Sensitive data encrypted at rest and in transit

See: `references/code-review-layers.md` for detailed checklists
See: `references/security-review-checklists.md` for STRIDE and threat modeling

## Quality Gates

All gates must PASS before merge approval.

| Gate | Criteria | Threshold |
|------|----------|-----------|
| Tests | All pass, no skipped without reason, no flaky | 100% pass, 3x consistent |
| Coverage | Line and branch coverage met | Line >= 80%, Branch >= 70% |
| Security | No high/critical vulns, no hardcoded secrets, deps clean | Zero high/critical |
| Code Quality | No TODO/FIXME/HACK, no commented-out code, no debug code | Zero violations |
| Documentation | Public APIs documented, complex logic explained | All public APIs |

## Return Format: PASS

```
## Code Review Summary
**Status**: APPROVED
**Automated Checks**: Tests/Coverage/Linting/Security -- PASS with metrics
**Manual Review**: Logic/Design/Security -- PASS
**Positive Observations**: [specific callouts]
**Minor Suggestions** (non-blocking): [optional improvements]
```

## Return Format: FAIL

```
## Code Review Summary
**Status**: CHANGES REQUIRED
**Blocking Issues**:
### [Category] - [CRITICAL/HIGH/MEDIUM]
**File**: `path/to/file.py:LINE`
**Issue**: [specific problem]
**Fix**: [concrete solution with code]
**Next Steps**: Address blocking issues and resubmit.
```

See: `references/report-templates.md` for full templates

## Working Protocol: Code Review

1. Read changes: `git diff main...feature-branch`
2. Run automated checks (Layer 1)
3. Manual review (Layers 2-4)
4. Return APPROVED or CHANGES REQUIRED with file:line references

## Working Protocol: Security Audit

1. Identify attack surface (endpoints, uploads, queries, integrations)
2. Enumerate threats using STRIDE
3. Assess risk: Likelihood x Impact
4. Verify mitigations in code
5. Return security report with threat model and recommendations

See: `references/security-review-checklists.md`

## Review Priorities

| Focus On | Skip |
|----------|------|
| Security vulnerabilities | Style nitpicks (linters handle it) |
| Logic errors | Personal preferences |
| Missing tests | Cosmetic issues |
| Data integrity | Naming bikeshedding |

## Feedback Standards

- Point to specific file:line
- Suggest concrete fix with code
- Categorize severity: CRITICAL / HIGH / MEDIUM / LOW
- Explain WHY it matters (not just what is wrong)

## References

- `references/security-review-checklists.md` -- STRIDE model, threat modeling steps, attack scenarios
- `references/code-review-layers.md` -- detailed logic, design, and quality checks
- `references/report-templates.md` -- full PASS/FAIL and security report templates
