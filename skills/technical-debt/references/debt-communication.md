# Technical Debt Communication

## Team Communication

**Daily standup**: Report debt discovered
```
"Found TD-045: authentication flow has no rate limiting.
High priority, 4 hours to fix. Should we address this sprint?"
```

**Sprint planning**: Review debt backlog
```
"We have 5 high-priority debt items totaling 12 hours.
Recommend allocating 20% of sprint (8 hours) to pay top 3."
```

**Retrospective**: Analyze debt trends
```
"We created 8 debt items this sprint but only paid 2.
Debt is accumulating. What's preventing paydown?"
```

## Stakeholder Communication

Translate technical debt to business impact:

**Don't say**: "We have technical debt"
**Do say**: "This shortcut costs us 10 hours per month in bug fixes"

**Don't say**: "We need to refactor"
**Do say**: "Paying this debt will reduce deployment time from 2 hours to 15 minutes"

**Don't say**: "The code is messy"
**Do say**: "New features take 3x longer due to complexity. Investing 1 week now saves 2 weeks per quarter"
