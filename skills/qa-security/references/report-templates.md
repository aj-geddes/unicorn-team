# Report Templates

Full templates for code review and security reports.

## Code Review: PASS Template

```markdown
## Code Review Summary

**Status**: APPROVED

**Automated Checks**:
- Tests: X/X passed
- Coverage: XX% (target: 80%)
- Linting: No issues
- Security Scan: No vulnerabilities

**Manual Review**:
- Logic: Correct and clear
- Design: Well-structured
- Security: No concerns
- Documentation: Complete

**Positive Observations**:
- [Specific callout about good patterns used]
- [Specific callout about test quality]
- [Specific callout about documentation]

**Minor Suggestions** (non-blocking):
- [Optional improvement with rationale]
- [Optional improvement with rationale]

**Approval**: This code is ready to merge.
```

## Code Review: FAIL Template

```markdown
## Code Review Summary

**Status**: CHANGES REQUIRED

**Blocking Issues**:

### [Category] - CRITICAL
**File**: `path/to/file.py:LINE`
```[language]
# VULNERABLE / BROKEN code
offending_code_here
```
**Fix**: [Description of what to do]
```[language]
# FIXED code
corrected_code_here
```

### [Category] - HIGH
**File**: `path/to/file.py:LINE`
**Issue**: [Description of the problem]
**Fix**: [Concrete steps to resolve]

### [Category] - MEDIUM
**Issue**: [Description]
**Fix**: [Steps, including specific test cases to add]

### [Category] - LOW
**File**: `path/to/file.py`
**Issue**: [Description]
**Fix**: [Suggestion]

**Next Steps**: Address blocking issues and resubmit for review.
```

## Security Analysis Report Template

```markdown
## Security Analysis Report

**Feature**: [Feature name]
**Reviewer**: QA-Security Agent
**Date**: [Date]

### Threat Model

**Assets**:
- [What data/functionality are we protecting]

**Trust Boundaries**:
- [Endpoint/interface]: [What untrusted input enters here]

### Identified Threats

| ID | Threat | Likelihood | Impact | Risk | Status |
|----|--------|------------|--------|------|--------|
| T1 | [Threat description] | High/Med/Low | High/Med/Low | CRITICAL/HIGH/MED/LOW | Mitigated / Open / Accepted |

### Mitigations Applied

**T1: [Threat Name]**
- [Specific mitigation implemented]
- [How it was verified]

**T2: [Threat Name]** (Accepted Risk)
- [Why risk is accepted]
- [Compensating controls]
- [Documented for future improvement]

### Security Checklist

- [x] Input validation on all endpoints
- [x] Output encoding (escaped HTML, parameterized SQL)
- [x] No secrets in code or logs
- [x] Authentication required for protected resources
- [x] Authorization checked on every request
- [x] Audit logging for security events
- [x] TLS enforced
- [x] Dependencies scanned for CVEs

### Recommendations

1. **High Priority**: [Action item]
2. **Medium Priority**: [Action item]
3. **Low Priority**: [Action item]

**Conclusion**: [Overall security posture assessment]
```

## Severity Classification

| Severity | Definition | SLA |
|----------|-----------|-----|
| CRITICAL | Exploitable vulnerability, data breach risk | Block merge, fix immediately |
| HIGH | Logic error causing data loss or security weakness | Block merge, fix before next review |
| MEDIUM | Missing tests, incomplete error handling | Fix within sprint |
| LOW | Documentation gap, minor style issue | Fix when convenient |
