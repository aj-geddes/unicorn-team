---
name: estimation
description: >-
  Guides the user through risk-based task estimation using decomposition,
  three-point estimates, and PERT formula. ALWAYS trigger on "estimate",
  "how long will this take", "time to complete", "sizing", "scope this",
  "effort estimate", "how many hours", "story points", "project timeline",
  "when will this be done", "cost estimate", "level of effort".
  Use when sizing any work item, feature, or project.
---
<!-- Last reviewed: 2026-03 -->

# Estimation

## Process

### 1. Decompose Exhaustively

Break tasks until each piece is < 8 hours and estimatable with confidence.

```
Task: "Add user authentication"
  ├─ Database schema (2h)
  ├─ API endpoints (16h) → decompose further
  ├─ Password handling (8h)
  ├─ JWT tokens (19h) → decompose further
  ├─ Middleware (14h) → decompose further
  ├─ Testing (23h) → decompose further
  └─ Integration (22h) → decompose further
```

**Rule**: If you can't estimate confidently, decompose further.

### 2. Identify Unknowns

```yaml
unknowns:
  technical:  ["Never used bcrypt", "Don't know JWT refresh pattern"]
  domain:     ["Password rules unspecified", "SSO needed later?"]
  external:   ["DBA review has 2-day SLA"]
  resource:   ["Frontend dev availability uncertain"]
```

Every unknown adds risk. Quantify it.

### 3. Three-Point Estimate

For each atomic task:

| Estimate | Meaning |
|----------|---------|
| **Optimistic (O)** | Everything goes perfectly |
| **Realistic (R)** | Normal conditions, typical hiccups |
| **Pessimistic (P)** | Murphy's Law applies |

```
"Implement password hashing"
O: 1h  (copy existing pattern)
R: 3h  (read docs, test, handle edge cases)
P: 8h  (version issues, need alternatives)
```

**Rule**: If P > 3x R, decompose further.

### 4. Calculate PERT

```
Expected = (O + 4*R + P) / 6

Example: (1 + 4*3 + 8) / 6 = 3.5h
```

### 5. Apply Risk Buffers

| Risk Level | Multiplier | When |
|------------|------------|------|
| Low | 1.0-1.2x | Well-understood, clear requirements |
| Medium | 1.2-1.5x | Some unknowns, moderate complexity |
| High | 1.5-2.0x | New tech, unclear requirements |
| Critical | 2.0-3.0x | Multiple unknowns, bleeding-edge |

**Risk categories:**

| Category | Multiplier | Triggers |
|----------|------------|----------|
| Technical | 1.3-2.0x | New lang/framework, complex algorithms, perf requirements |
| Domain | 1.4-2.5x | Unclear requirements, regulatory, stakeholder disagreement |
| External | 1.5-3.0x | Third-party deps, vendor timelines, cross-team |
| Resource | 1.2-2.0x | Availability uncertain, skills gap, access issues |

### 6. Add Integration Buffer

Integration is where 50% of bugs live. Always add 20-30%.

```
Subtasks total: 40h
Integration buffer (25%): 10h
Final: 50h
```

---

## Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| "2 Hours" | "I have no idea" | Use three-point + PERT |
| Secret Padding | Destroys trust | State explicit buffer: "5h + 5h buffer" |
| Ignoring Integration | Underestimate 30-50% | Always add integration buffer |
| Forgetting Testing | "Done" != done | Include test time (often 1:1 with dev) |
| No Confidence Level | False precision | Use ranges: "45h +/- 5h" |

---

## Communication Template

```
[ESTIMATE] (+/-[UNCERTAINTY]) assuming [ASSUMPTIONS]

Breakdown:
- Component 1: Xh
- Component 2: Yh
- Integration: Zh

Confidence: [High/Medium/Low] (XX%)

Assumptions:
1. [Critical assumption]

Risks:
- [Risk]: [impact] / [mitigation]

Dependencies:
- [External dependency]

Unknowns:
- [Unknown] - [how to resolve]
```

---

## Validation Checklist

Before finalizing any estimate:

- [ ] Decomposed into atomic units (< 8h each)
- [ ] Every subtask has O/R/P estimates
- [ ] PERT formula applied
- [ ] All unknowns identified
- [ ] Risk buffers applied
- [ ] Integration buffer added (20-30%)
- [ ] Confidence level assigned
- [ ] Assumptions stated
- [ ] Risks identified with mitigations
- [ ] Dependencies noted
- [ ] Estimate is a range (+/- X)

---

## When to Re-Estimate

- Requirements change -- re-decompose affected components
- Unknown resolved -- update with actual findings
- Overrun > 20% -- stop and reassess remaining work
- Dependency changes -- adjust timeline
- Team changes -- different skills = different estimates

---

## Script

Run the interactive PERT estimation helper:

```bash
skills/estimation/scripts/estimate.sh
# or
./scripts/estimate.sh [--output filename]
```

---

## References

- `references/decomposition-examples.md` -- full worked examples
- `references/risk-analysis.md` -- risk assessment framework
- `references/communication-guide.md` -- stakeholder communication patterns
- `scripts/estimate.sh` -- interactive PERT estimation script
