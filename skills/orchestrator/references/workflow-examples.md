# Orchestrator Workflow Examples

Concrete examples showing how the orchestrator routes, delegates, and synthesizes
results for different task types.

---

## New Feature Implementation

```
User: "Add user authentication with JWT"

Analysis:
- Complex feature, needs architecture first
- Multiple components, parallel delegation possible
- Security-sensitive, needs QA review

Execution:
1. Delegate to Architect: "Design JWT auth architecture, API contracts"
2. Wait for architecture ADR
3. Delegate in parallel:
   - Developer: "Implement auth service with TDD" (context: ADR from step 1)
   - Developer: "Implement auth middleware with TDD"
   - DevOps: "Add secrets management configuration"
4. Delegate to QA: "Security review of auth implementation"
5. Verify all quality gates
6. Return summary to user
```

---

## Bug Fix

```
User: "Users can't log in after password reset"

Analysis:
- Bug fix, needs root cause analysis
- Single domain, one Developer agent

Execution:
1. Delegate to Developer:
   "Debug login failure after password reset.
   Use root-cause protocol:
   1. Reproduce the issue
   2. Form hypotheses
   3. Test hypotheses systematically
   4. Fix with TDD (write failing test first)
   5. Verify fix doesn't break other flows"
2. Verify quality gates on return
3. Return fix summary to user
```

---

## Code Review

```
User: "Review this PR for the payment service"

Analysis:
- Review task, QA agent
- Payment = security focus

Execution:
1. Delegate to QA:
   "Review payment service PR.
   Apply 4-layer review:
   - Layer 1: Automated (tests, coverage, linting)
   - Layer 2: Logic (correctness, edge cases)
   - Layer 3: Design (SRP, complexity)
   - Layer 4: Security (inputs, auth, data handling)
   Return: approval/rejection with specific feedback"
2. Synthesize and present to user
```

---

## Parallel Multi-Service Task

```
User: "Set up monitoring for all three microservices"

Analysis:
- Infrastructure task, DevOps agent
- Could parallelize per service, but shared monitoring stack
- Single DevOps delegation is cleaner

Execution:
1. Delegate to DevOps:
   "Set up observability stack for auth-service, billing-service,
   notification-service. Include:
   - Prometheus metrics per service
   - Grafana dashboards (one per service + overview)
   - Structured logging with correlation IDs
   - Health check endpoints"
2. Verify quality gates
3. Return summary with dashboard URLs and runbook
```
