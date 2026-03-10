# Communication Guide

Patterns for communicating estimates to stakeholders. Good estimates are useless if communicated poorly. Always present estimates as ranges with explicit context.

---

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

---

## Guidance for Stakeholder Communication

### Always Include
- **A range, not a point estimate.** "40-50 hours" is honest. "45 hours" is false precision.
- **Assumptions.** Every estimate is conditional. State the conditions.
- **Confidence level.** Let stakeholders know how much weight to place on the number.
- **Risks with mitigations.** Show you have thought about what could go wrong and how to handle it.

### Adjust Detail by Audience
- **Technical leads**: Full breakdown with per-component estimates, risk multipliers, and PERT calculations.
- **Product managers**: Summary estimate, top assumptions, key risks, and dependencies.
- **Executives**: Range, confidence level, and the one or two risks that could blow up the timeline.

### When Estimates Change
- Communicate early. Do not wait until the deadline.
- Explain what changed and why (new information, resolved unknown, scope change).
- Provide a revised estimate using the same format.

### Common Pitfalls
- Giving a single number without context.
- Hiding uncertainty behind false confidence.
- Failing to update when conditions change.
- Not separating effort (hours of work) from duration (calendar time).
