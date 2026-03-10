# Decomposition Examples

Full worked examples demonstrating the estimation skill's decomposition, three-point estimation, PERT calculation, and communication workflow.

---

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
