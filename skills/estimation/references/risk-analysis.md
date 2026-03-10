# Risk Analysis Framework

Risk categories used to determine estimation multipliers. Each category captures a different source of uncertainty that impacts task duration.

---

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

---

## Applying Risk Multipliers

When multiple risk categories apply, use the highest single multiplier rather than multiplying them together. If risks compound significantly, consider bumping one level higher.

```
Risk Level | Multiplier | When
-----------|------------|-----
Low        | 1.0-1.2x   | Well-understood, clear requirements
Medium     | 1.2-1.5x   | Some unknowns, moderate complexity
High       | 1.5-2.0x   | New tech, unclear requirements
Critical   | 2.0-3.0x   | Multiple unknowns, bleeding-edge
```

Identify the dominant risk category for each subtask and apply the corresponding multiplier to the PERT-calculated estimate.
