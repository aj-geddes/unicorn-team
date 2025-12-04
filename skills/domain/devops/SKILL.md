---
name: devops
description: >
  DevOps expertise covering Docker, CI/CD pipelines, Kubernetes, observability,
  and deployment strategies. Use when containerizing applications, setting up
  CI/CD workflows, deploying to Kubernetes, implementing monitoring and logging,
  managing infrastructure as code, or troubleshooting deployment issues. Trigger
  phrases: "dockerize", "CI/CD", "kubernetes", "deploy", "monitoring", "logging",
  "metrics", "helm", "infrastructure", "observability", "rollback", "scaling".
---

# DevOps Domain Skill

Expert guidance for containerization, orchestration, deployment automation, and operational excellence.

## Docker Essentials

### Quick Commands
```bash
# Build optimized image
docker build -t myapp:v1.0.0 .

# Multi-stage build
docker build --target production -t myapp:prod .

# Run with resource limits
docker run --cpus=0.5 --memory=512m myapp:v1.0.0

# Inspect image layers
docker history myapp:v1.0.0

# Remove dangling images
docker image prune -f

# View container logs
docker logs -f --tail=100 container_id
```

### Dockerfile Best Practices Summary
- Use specific base image tags (never `:latest`)
- Multi-stage builds for minimal runtime images
- Copy dependency files first for layer caching
- Run as non-root user
- Use `.dockerignore` to exclude unnecessary files
- Minimize layers (combine RUN commands with `&&`)
- Use distroless or alpine for security
- Set health checks in Dockerfile
- Label images with metadata

Example minimal Dockerfile:
```dockerfile
FROM python:3.11-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM gcr.io/distroless/python3-debian11
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --chown=nonroot:nonroot . /app
WORKDIR /app
USER nonroot
CMD ["python", "app.py"]
```

See `references/docker-complete.md` for comprehensive Docker patterns, optimization techniques, and Compose configurations.

## CI/CD Pipeline Patterns

### Pipeline Stages
1. **Lint** - Code quality checks (parallel with tests)
2. **Test** - Unit/integration tests with coverage
3. **Build** - Container image build and push
4. **Deploy** - Environment-specific deployments
5. **Verify** - Smoke tests and health checks

### GitHub Actions Quick Reference
```yaml
# Essential workflow structure
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: pytest --cov

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: docker/build-push-action@v5
        with:
          push: true
          tags: ${{ env.IMAGE }}:${{ github.sha }}
```

### Pipeline Best Practices
- Cache dependencies between runs
- Use matrix builds for multi-version testing
- Separate fast checks (lint) from slow (integration tests)
- Fail fast on quality gates
- Tag images with commit SHA and semantic versions
- Store secrets in GitHub Secrets, never in code
- Use environments for staging/production approvals

See `references/github-actions.md` for complete CI/CD workflows, matrix builds, caching strategies, and deployment automation.

## Kubernetes Core Concepts

### Essential Resources
- **Deployment** - Manages replica sets and rolling updates
- **Service** - Stable networking endpoint for pods
- **Ingress** - HTTP(S) routing to services
- **ConfigMap** - Non-sensitive configuration
- **Secret** - Sensitive data (credentials, tokens)
- **HPA** - Horizontal Pod Autoscaler

### Key kubectl Commands
```bash
# Apply manifests
kubectl apply -f deployment.yaml

# Get resource status
kubectl get pods,svc,ing -n production

# View logs
kubectl logs -f deployment/myapp -n production

# Execute in container
kubectl exec -it pod/myapp-xxx -- /bin/sh

# Port forward for testing
kubectl port-forward svc/myapp 8080:80

# Rollout management
kubectl rollout status deployment/myapp
kubectl rollout undo deployment/myapp

# Scale manually
kubectl scale deployment/myapp --replicas=5

# View resource usage
kubectl top pods -n production
```

### Deployment Checklist
- [ ] Resource requests and limits defined
- [ ] Liveness and readiness probes configured
- [ ] Running as non-root user
- [ ] Secrets externalized (not in manifests)
- [ ] Labels for monitoring and service discovery
- [ ] Multiple replicas for high availability
- [ ] Rolling update strategy configured
- [ ] HPA configured for auto-scaling

See `references/kubernetes-manifests.md` for complete manifest examples, Helm charts, security configurations, and advanced patterns.

## Observability Three Pillars

### 1. Logging (What happened?)
- Use structured JSON logs
- Include context (request_id, user_id, service_name)
- Log levels: DEBUG < INFO < WARNING < ERROR < CRITICAL
- Centralize with Loki, ElasticSearch, or CloudWatch
- Never log sensitive data (passwords, tokens)

Quick Python logging:
```python
import logging
import json

logging.basicConfig(
    format='%(message)s',
    level=logging.INFO,
    handlers=[logging.StreamHandler()]
)

logger = logging.getLogger(__name__)
logger.info(json.dumps({
    "event": "user_login",
    "user_id": user.id,
    "timestamp": datetime.now().isoformat()
}))
```

### 2. Metrics (How much/how many?)
- Counter: Monotonically increasing (requests_total)
- Gauge: Current value (active_connections)
- Histogram: Distribution (request_duration_seconds)
- Summary: Quantiles (p95, p99 latency)

Essential metrics to track:
- Request rate (per endpoint, per method)
- Error rate (4xx, 5xx responses)
- Duration (latency percentiles)
- Saturation (CPU, memory, disk, connections)

### 3. Tracing (Where did time go?)
- Distributed tracing across services
- Track request path through system
- Identify bottlenecks and slow queries
- Use OpenTelemetry for vendor-neutral instrumentation

Quick trace setup:
```python
from opentelemetry import trace
from opentelemetry.instrumentation.flask import FlaskInstrumentor

FlaskInstrumentor().instrument_app(app)
tracer = trace.get_tracer(__name__)

@app.route('/api/data')
def get_data():
    with tracer.start_as_current_span("database_query"):
        data = db.query()
    return data
```

See `references/observability-stack.md` for complete Prometheus, Grafana, Loki, Jaeger, and OpenTelemetry configurations.

## Deployment Strategies

### Rolling Update (Default, Zero-Downtime)
- Gradually replace old pods with new ones
- Configure `maxSurge` and `maxUnavailable`
- Use readiness probes to ensure new pods are healthy
- Fast rollback with `kubectl rollout undo`

### Blue-Green (Instant Switch)
- Two identical environments (blue=current, green=new)
- Deploy to green, test thoroughly
- Switch traffic all at once
- Keep blue for instant rollback
- Higher resource cost (2x infrastructure)

### Canary (Gradual Traffic Shift)
- Route small percentage to new version
- Monitor metrics (error rate, latency)
- Gradually increase traffic if healthy
- Auto-rollback if metrics degrade
- Use Flagger or Argo Rollouts

### When to Use Each
- **Rolling**: Standard deployments, backward-compatible changes
- **Blue-Green**: Database migrations, major version updates
- **Canary**: High-risk changes, need validation with real traffic

See `references/deployment-strategies.md` for complete examples, rollback procedures, and automated canary configurations.

## Security Hardening

### Container Security
- Scan images for vulnerabilities (Trivy, Snyk)
- Use minimal base images (distroless, scratch)
- Run as non-root user
- Read-only root filesystem
- Drop all capabilities
- Regular image updates

### Kubernetes Security
- Network policies (deny-all by default)
- Pod Security Standards (restricted mode)
- RBAC for least privilege access
- External secrets management (Vault, AWS Secrets Manager)
- Encrypt secrets at rest
- Admission controllers for policy enforcement

### Secrets Management Rules
- Never commit secrets to Git
- Use external secret stores
- Rotate secrets regularly
- Audit secret access
- Mount secrets as files, not env vars (when possible)
- Scope secrets to namespaces

See `references/security-hardening.md` for network policies, secret management patterns, image scanning automation, and compliance configurations.

## Infrastructure as Code

### Principles
- Version control all manifests
- Declarative over imperative
- Separate environment configs (dev/staging/prod)
- Validate before apply (`kubectl dry-run`, `helm lint`)
- Use GitOps for deployment (ArgoCD, Flux)
- Document dependencies and prerequisites

### Helm Best Practices
- Use templating for environment differences
- Override values with environment-specific files
- Version charts semantically
- Include default values that work
- Use helper functions for repeated patterns
- Validate charts before release

### GitOps Workflow
1. Commit manifest changes to Git
2. ArgoCD/Flux detects changes
3. Automatic or manual sync to cluster
4. Declarative drift detection
5. Git as single source of truth

## Troubleshooting Checklist

### Pod Not Starting
```bash
kubectl describe pod <pod-name>  # Check events
kubectl logs <pod-name>          # Check application logs
kubectl get events --sort-by=.metadata.creationTimestamp
```
Common causes: image pull errors, resource limits, health check failures

### Service Not Reachable
```bash
kubectl get svc,endpoints <service-name>  # Check endpoints
kubectl describe svc <service-name>       # Check selectors
```
Common causes: label mismatch, port misconfiguration, network policies

### High Resource Usage
```bash
kubectl top pods                          # Check current usage
kubectl describe node <node-name>        # Check node capacity
```
Common causes: no resource limits, memory leaks, inefficient code

### Deployment Stuck
```bash
kubectl rollout status deployment/<name>
kubectl get events | grep <deployment-name>
```
Common causes: failing health checks, insufficient resources, image issues

## Quick Reference Links

Detailed documentation:
- `references/docker-complete.md` - Comprehensive Docker guide
- `references/kubernetes-manifests.md` - K8s manifests and Helm charts
- `references/github-actions.md` - Complete CI/CD workflows
- `references/observability-stack.md` - Monitoring and logging setup
- `references/deployment-strategies.md` - Deployment patterns and rollbacks
- `references/security-hardening.md` - Security best practices

## Key DevOps Principles

1. **Automate Everything** - Manual processes are error-prone
2. **Measure Everything** - Can't improve what you don't measure
3. **Fail Fast** - Catch issues early in pipeline
4. **Immutable Infrastructure** - Replace, don't modify
5. **Infrastructure as Code** - Version control all config
6. **Monitor Proactively** - Alert before users notice
7. **Practice Chaos** - Test failure scenarios regularly
8. **Document Runbooks** - Incident response should be scripted
