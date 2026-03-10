# Deployment Runbooks

## Rollback Script

```bash
#!/bin/bash
# scripts/rollback.sh

set -euo pipefail

ENVIRONMENT="$1"
PREVIOUS_VERSION="$2"

echo "Rolling back $ENVIRONMENT to $PREVIOUS_VERSION"

case "$ENVIRONMENT" in
  staging|production)
    # Kubernetes rollback
    kubectl rollout undo deployment/app --namespace="$ENVIRONMENT"
    kubectl rollout status deployment/app --namespace="$ENVIRONMENT"

    # Verify health
    ./scripts/health-check.sh "$ENVIRONMENT"

    # Notify team
    curl -X POST "$SLACK_WEBHOOK" -d "{\"text\":\"Rolled back $ENVIRONMENT to $PREVIOUS_VERSION\"}"
    ;;
  *)
    echo "Unknown environment: $ENVIRONMENT"
    exit 1
    ;;
esac

echo "Rollback complete"
```

## Environment Promotion Strategy

```
Development -> Staging -> Production

Development:
  - Deploy on every commit to develop
  - Automatic, no approval
  - Optimized for speed

Staging:
  - Deploy after tests pass
  - Production-like configuration
  - Integration/E2E tests run here
  - Security scanning mandatory

Production:
  - Deploy only from main branch
  - Requires approval (manual gate)
  - Blue-green or canary deployment
  - Automatic rollback on failure
  - Monitoring alerts active
```

## Secrets Management Procedures

```bash
# Create K8s secrets (never commit to git)
kubectl create secret generic myapp-secrets \
  --from-literal=DATABASE_URL="postgresql://..." \
  --from-literal=API_KEY="..." \
  --dry-run=client -o yaml | kubectl apply -f -
```

### Secret Store Options

| Store | Use When |
|-------|----------|
| GitHub Secrets | GitHub Actions CI/CD variables |
| K8s Secrets | Runtime secrets for pods |
| HashiCorp Vault | Centralized multi-service secret management |
| AWS Secrets Manager | AWS-native workloads |
| GCP Secret Manager | GCP-native workloads |

### Secret Rotation Checklist

- [ ] Identify all secrets and their locations
- [ ] Generate new secret values
- [ ] Update secret store
- [ ] Restart/redeploy affected services
- [ ] Verify services healthy with new secrets
- [ ] Revoke old secret values
- [ ] Update rotation schedule

## Deployment Verification Script

```bash
#!/bin/bash
# scripts/verify-deployment.sh

set -euo pipefail

ENVIRONMENT="$1"
TIMEOUT="${2:-300}"  # 5 min default

echo "Verifying deployment in $ENVIRONMENT..."

# 1. Health checks
echo "Checking health endpoints..."
kubectl wait --for=condition=ready pod -l app=myapp \
  --namespace="$ENVIRONMENT" --timeout="${TIMEOUT}s"

# 2. Smoke tests
echo "Running smoke tests..."
./scripts/smoke-tests.sh "$ENVIRONMENT"

# 3. Error rate check (via Prometheus)
echo "Checking error rate..."
ERROR_RATE=$(curl -s "http://prometheus:9090/api/v1/query?query=rate(errors_total[5m])" \
  | jq '.data.result[0].value[1] // "0"' -r)

if (( $(echo "$ERROR_RATE > 0.01" | bc -l) )); then
  echo "ERROR: Error rate ${ERROR_RATE} exceeds threshold 0.01"
  exit 1
fi

echo "Deployment verified successfully"
```

## Rollback Trigger Conditions

Initiate rollback immediately if any condition is met:

| Condition | Threshold | Detection |
|-----------|-----------|-----------|
| Error rate | > 1% | Prometheus alert |
| P95 latency | > 2x baseline | Prometheus alert |
| Health checks | Failing | K8s liveness probe |
| Critical bug | Reported | Manual trigger |
| Memory leak | OOM kills observed | K8s events |

## Post-Incident Review Template

```markdown
## Incident: [Title]
- **Date**: YYYY-MM-DD
- **Duration**: X minutes
- **Severity**: P1/P2/P3
- **On-call**: [Name]

### Timeline
- HH:MM - [Event]
- HH:MM - [Event]

### Root Cause
[Description]

### Resolution
[What fixed it]

### Action Items
- [ ] [Prevention measure]
- [ ] [Monitoring improvement]
- [ ] [Process change]
```
