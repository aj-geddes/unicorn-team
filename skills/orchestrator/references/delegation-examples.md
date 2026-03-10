# Delegation Examples

Detailed examples of delegation using the orchestrator's YAML template format. Each example demonstrates how to route a specific scenario to the appropriate subagent with clear context, constraints, and expected output.

---

## Example 1: Architecture Decision with Constraints

```yaml
delegation:
  to: architect
  task: |
    Design authentication system for multi-tenant SaaS application.
    Must support SSO (SAML 2.0 + OIDC), per-tenant password policies,
    and API key management. Produce an ADR with tradeoff analysis.

  context:
    - Existing monolith at src/app/ being decomposed into services
    - Current auth is session-based, stored in PostgreSQL
    - 200+ enterprise tenants, some require HIPAA compliance
    - Target: extract auth into standalone service

  constraints:
    - Must maintain backward compatibility with existing session auth during migration
    - Latency budget: < 50ms for token validation
    - No vendor lock-in (rule out proprietary SSO platforms)
    - HIPAA audit logging required for healthcare tenants

  expected_output:
    - ADR document with decision, context, alternatives considered, and consequences
    - Mermaid sequence diagram for auth flow (login, token refresh, SSO)
    - API contract (OpenAPI) for the auth service
    - Migration strategy from session-based to token-based auth
```

---

## Example 2: Security Audit

```yaml
delegation:
  to: qa
  mode: security
  task: |
    Perform security audit on the payment processing module.
    Focus on OWASP Top 10 vulnerabilities, input validation,
    and secrets management.

  context:
    - Payment module at src/payments/
    - Uses Stripe API (keys in environment variables)
    - Handles PCI-scoped card data in transit (not stored)
    - Recently added webhook endpoint at src/payments/webhooks.py

  constraints:
    - Flag all high/critical findings as blockers
    - Check for hardcoded secrets, SQL injection, SSRF, and IDOR
    - Verify webhook signature validation
    - Assess rate limiting on payment endpoints

  expected_output:
    - Security findings report (severity: critical/high/medium/low)
    - Specific file paths and line numbers for each finding
    - Recommended fix for each finding
    - Pass/fail determination for deployment readiness
```

---

## Example 3: Multi-Service Deployment

```yaml
delegation:
  to: devops
  task: |
    Set up CI/CD pipeline and deployment configuration for three
    new microservices: auth-service, billing-service, and
    notification-service. All deploy to Kubernetes.

  context:
    - Monorepo structure: services/{auth,billing,notification}/
    - Each service has its own Dockerfile
    - Existing cluster on AWS EKS (us-east-1)
    - Current CD uses ArgoCD with GitOps pattern
    - Shared PostgreSQL RDS, per-service logical databases

  constraints:
    - Blue-green deployment strategy for auth-service (zero downtime)
    - Canary deployment for billing-service (5% → 25% → 100%)
    - Standard rolling update for notification-service
    - All services must pass health checks before traffic shift
    - Resource limits required (CPU/memory) per pod

  expected_output:
    - Kubernetes manifests (Deployment, Service, Ingress) per service
    - ArgoCD Application CRDs for GitOps
    - CI pipeline config (GitHub Actions) with build, test, push stages
    - Deployment runbook documenting rollback procedures
```

---

## Example 4: Legacy Code Refactoring

```yaml
delegation:
  to: developer
  task: |
    Refactor the report generation module from synchronous to
    async processing. Reports currently time out for large datasets.
    Use Celery task queue with Redis broker.

  context:
    - Report module at src/reports/generator.py (1,200 lines, single class)
    - Currently called synchronously from API endpoint src/api/reports.py
    - Generates PDF via WeasyPrint, CSV via pandas
    - Largest reports process 500K+ rows, timeout after 30s
    - code-reading skill has already produced analysis at docs/reports-analysis.md

  constraints:
    - TDD required (tests first)
    - Coverage >= 80%
    - Must maintain existing API contract (same request/response shape)
    - Add polling endpoint GET /api/reports/{id}/status
    - Report results stored in S3 with signed URL for download
    - Maximum task execution time: 5 minutes with progress tracking

  expected_output:
    - src/reports/tasks.py (Celery task definitions)
    - src/reports/generator.py (refactored, async-compatible)
    - src/api/reports.py (updated endpoints)
    - tests/test_reports_async.py (tests)
    - Test results + coverage report
```
