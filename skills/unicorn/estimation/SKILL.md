---
name: estimation
description: >
  Risk-based task estimation using decomposition, three-point estimates, and PERT formula.
  Use when asked to "estimate", "how long", "time to complete", or sizing work.
  Not prediction—risk analysis with explicit unknowns, assumptions, and confidence levels.
  Produces estimates in format: "X hours (±Y hours) assuming Z. Risks: A, B, C."
---

# Estimation Skill

## Core Principle

**Estimation is risk analysis, not prediction.**

Bad estimates destroy trust. Good estimates build careers. The difference lies in explicit decomposition, uncertainty quantification, and clear communication of assumptions.

## The Estimation Process

### 1. Decompose Exhaustively

Break tasks down until each piece is estimatable with confidence (<8 hours per unit).

```
Task: "Add user authentication"
↓
├─ Database schema (2h)
├─ API endpoints (16h)
├─ Password handling (8h)
├─ JWT tokens (19h)
├─ Middleware (14h)
├─ Testing (23h)
└─ Integration (22h)
```

**Rule**: If you can't estimate confidently, decompose further.

### 2. Identify Unknowns

Explicitly document what you DON'T know:

```yaml
unknowns:
  technical:
    - "Never used bcrypt library before"
    - "Don't know JWT refresh pattern"

  domain:
    - "Password complexity rules unspecified"
    - "Unclear if SSO needed later"

  external:
    - "Database migration needs DBA review (2-day SLA)"

  resource:
    - "Frontend dev availability uncertain"
```

Every unknown adds risk. Quantify it.

### 3. Three-Point Estimate

For each atomic task:

- **Optimistic (O)**: Everything goes perfectly
- **Realistic (R)**: Normal conditions, typical hiccups
- **Pessimistic (P)**: Murphy's Law applies

```
Example: "Implement password hashing"

O: 1h  (Know bcrypt, copy existing pattern)
R: 3h  (Read docs, test parameters, handle edge cases)
P: 8h  (Version incompatible, need alternatives, security issues)
```

**Rule**: If P > 3×R, decompose further.

### 4. Calculate PERT

Use Program Evaluation and Review Technique formula:

```
Expected Time = (O + 4*R + P) / 6

Example:
E = (1 + 4*3 + 8) / 6 = 21 / 6 = 3.5 hours
```

PERT provides probability-weighted estimate.

### 5. Apply Risk Buffers

```
Risk Level | Multiplier | When
-----------|------------|-----
Low        | 1.0-1.2x   | Well-understood, clear requirements
Medium     | 1.2-1.5x   | Some unknowns, moderate complexity
High       | 1.5-2.0x   | New tech, unclear requirements
Critical   | 2.0-3.0x   | Multiple unknowns, bleeding-edge
```

```
Example:
Base: 3.5h
Risk: Medium (unfamiliar library)
Buffer: 1.3x
Final: 4.5h
```

### 6. Add Integration Buffer

Integration is where 50% of bugs live. Always add 20-30%.

```
Subtasks total: 40h
Integration: 25% = 10h
Final: 50h
```

## Estimation Anti-Patterns

Recognize and avoid:

**"2 Hours"** = "I have no idea"
- Fix: Use three-point + PERT

**Secret Padding** = Destroys trust
- Fix: State explicit buffer: "5h + 5h buffer"

**Ignoring Integration** = Underestimate by 30-50%
- Fix: Always add integration buffer

**Forgetting Testing** = "Done" ≠ done
- Fix: Include test time (often 1:1 with dev)

**No Confidence** = False precision
- Fix: Use ranges: "45h ±5h"

## Risk Categories

### Technical Risk (1.3-2.0x)
- New language/framework/library
- Bleeding-edge technology
- Complex algorithms
- Performance requirements

### Domain Risk (1.4-2.5x)
- Unclear requirements
- Missing specifications
- Stakeholder disagreement
- Regulatory/compliance

### External Risk (1.5-3.0x)
- Third-party dependencies
- Vendor timelines
- Review processes
- Cross-team dependencies

### Resource Risk (1.2-2.0x)
- Availability uncertain
- Skills gap
- Shared resources
- Access issues

## Communication Template

```
[ESTIMATE] (±[UNCERTAINTY]) assuming [ASSUMPTIONS]

Breakdown:
- Component 1: Xh
- Component 2: Yh
- Integration: Zh

Confidence: [High/Medium/Low] (XX%)

Assumptions:
1. [Critical assumption]
2. [Critical assumption]

Risks:
- [Risk]: [impact] / [mitigation]

Dependencies:
- [External dependency]

Unknowns:
- [Unknown] - [how to resolve]
```

## Example: CSV Export Feature

### Decomposition

```
Backend:
  Library research:   O:0.5h R:1h   P:2h   → 1.1h
  CSV serializer:     O:2h   R:4h   P:8h   → 4.3h
  Export endpoint:    O:1h   R:2h   P:4h   → 2.2h
  Streaming:          O:2h   R:5h   P:12h  → 5.7h
  Subtotal: 13.3h × 1.4 (medium-high risk) = 18.6h

Frontend:
  Export button:      O:0.5h R:1h   P:2h   → 1.1h
  Progress indicator: O:1h   R:2h   P:4h   → 2.2h
  Download handling:  O:1h   R:3h   P:6h   → 3.2h
  Error handling:     O:1h   R:2h   P:4h   → 2.2h
  Subtotal: 8.7h × 1.2 (low-medium risk) = 10.4h

Testing:
  Unit tests:         O:2h   R:4h   P:8h   → 4.3h
  Integration:        O:2h   R:4h   P:6h   → 4.0h
  Performance:        O:1h   R:3h   P:8h   → 3.5h
  Subtotal: 11.8h × 1.2 (medium risk) = 14.2h

Integration:
  E2E testing:        O:2h   R:4h   P:8h   → 4.3h
  Edge cases:         O:2h   R:4h   P:10h  → 4.7h
  Subtotal: 9h × 1.3 (medium risk) = 11.7h

Buffered total: 54.9h
Integration buffer: 25% = 13.7h
Final: 68.6h → 65-70h
```

### Communication

```
68 hours (±8 hours) assuming standard Excel-compatible CSV

Breakdown:
- Backend API: 19h
- Frontend UI: 10h
- Testing: 14h
- Integration: 12h
- Buffer: 14h

Confidence: Medium (70%)

Assumptions:
1. Dataset size < 100K rows
2. Standard CSV format (RFC 4180)
3. Python csv module sufficient
4. Frontend supports File API

Risks:
- Dataset size unknown (High): If >100K rows → +10h
  Mitigation: Clarify max size before starting

- CSV format unclear (Medium): Excel issues → +5h
  Mitigation: Get sample approved

- Browser compat (Low): Polyfill needed → +2h
  Mitigation: Check analytics

Dependencies: None

Unknowns:
- Max dataset size - ask PM today
- Encoding preference - defaulting UTF-8
- Full export or column selection?
```

## Validation Checklist

Before finalizing:

- [ ] Decomposed into atomic units (<8h each)
- [ ] Every subtask has O/R/P estimates
- [ ] PERT formula applied
- [ ] All unknowns identified
- [ ] Risk buffers applied
- [ ] Integration buffer added (20-30%)
- [ ] Confidence level assigned
- [ ] Assumptions stated
- [ ] Risks identified with mitigations
- [ ] Dependencies noted
- [ ] Estimate is range (±X)

## When to Re-Estimate

Trigger re-estimation when:

1. **Requirements change** - Re-decompose affected components
2. **Unknown resolved** - Update with actual findings
3. **Overrun >20%** - Stop and reassess remaining work
4. **Dependency changes** - Adjust timeline
5. **Team changes** - Different skills = different estimates

## Confidence Levels

```
High (85-95%):
- Well-understood domain
- Familiar tech
- Clear requirements
- No external dependencies

Medium (60-80%):
- Some unknowns
- Moderate complexity
- Minor dependencies

Low (40-60%):
- Many unknowns
- New domain/tech
- Unclear requirements

Very Low (<40%):
- Exploratory work
- Recommend spike first
```

## Summary

Estimation process:

1. **Decompose** exhaustively
2. **Identify** unknowns explicitly
3. **Estimate** with O/R/P
4. **Calculate** PERT: (O + 4R + P) / 6
5. **Apply** risk buffers
6. **Add** integration buffer (20-30%)
7. **Communicate** as range with context

Quality of estimate = explicit unknowns + clear assumptions + honest confidence

Good estimates build trust. Bad estimates destroy it.

**When in doubt, be explicit about what you don't know.**

---

For detailed examples, decomposition templates, and advanced techniques, see:
- `references/decomposition-examples.md` - Full worked examples
- `references/risk-analysis.md` - Risk assessment framework
- `references/communication-guide.md` - Stakeholder communication patterns
