---
name: domain-devops
description: >-
  Guides the user through containerization, CI/CD pipelines, Kubernetes
  deployments, observability, and infrastructure management. ALWAYS trigger on
  "dockerize", "CI/CD", "kubernetes", "deploy", "monitoring", "logging",
  "metrics", "helm", "infrastructure", "observability", "rollback", "scaling",
  "pipeline", "container", "k8s", "GitOps", "Dockerfile", "health check",
  "troubleshoot deployment". Use when containerizing applications, building
  pipelines, deploying services, setting up monitoring, or debugging
  infrastructure issues. Different from agent-devops which handles orchestration
  and runbook execution rather than pattern guidance.
---

# DevOps Domain Skill

## Docker

### Quick Commands
```bash
docker build -t myapp:v1.0.0 .                          # Build image
docker build --target production -t myapp:prod .         # Multi-stage build
docker run --cpus=0.5 --memory=512m myapp:v1.0.0         # Run with limits
docker history myapp:v1.0.0                              # Inspect layers
docker image prune -f                                    # Remove dangling
docker logs -f --tail=100 container_id                   # Tail logs
```

### Dockerfile Best Practices
- Use specific base image tags (never `:latest`)
- Multi-stage builds for minimal runtime images
- Copy dependency files first for layer caching
- Run as non-root user
- Use `.dockerignore` to exclude unnecessary files
- Minimize layers (combine RUN commands with `&&`)
- Use distroless or alpine for production
- Set health checks
- Label images with metadata

**See:** `references/docker-complete.md` for optimization techniques and Compose configurations.

## CI/CD Pipelines

### Pipeline Stages
1. **Lint** - Code quality checks (parallel with tests)
2. **Test** - Unit/integration tests with coverage
3. **Build** - Container image build and push
4. **Deploy** - Environment-specific deployments
5. **Verify** - Smoke tests and health checks

### Best Practices
- Cache dependencies between runs
- Matrix builds for multi-version testing
- Separate fast checks (lint) from slow (integration)
- Fail fast on quality gates
- Tag images with commit SHA and semantic versions
- Store secrets in CI secret store, never in code
- Use environments for staging/production approvals

**See:** `references/github-actions.md` for complete workflows, matrix builds, caching, and deployment automation.

## Kubernetes

### Essential Resources

| Resource | Purpose |
|----------|---------|
| Deployment | Manages replica sets and rolling updates |
| Service | Stable networking endpoint for pods |
| Ingress | HTTP(S) routing to services |
| ConfigMap | Non-sensitive configuration |
| Secret | Sensitive data (credentials, tokens) |
| HPA | Horizontal Pod Autoscaler |

### Key kubectl Commands
```bash
kubectl apply -f deployment.yaml                         # Apply manifests
kubectl get pods,svc,ing -n production                   # Resource status
kubectl logs -f deployment/myapp -n production           # View logs
kubectl exec -it pod/myapp-xxx -- /bin/sh                # Shell into pod
kubectl port-forward svc/myapp 8080:80                   # Port forward
kubectl rollout status deployment/myapp                  # Rollout status
kubectl rollout undo deployment/myapp                    # Rollback
kubectl scale deployment/myapp --replicas=5              # Manual scale
kubectl top pods -n production                           # Resource usage
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

**See:** `references/kubernetes-manifests.md` for manifest examples, Helm charts, and security configurations.

## Observability

### 1. Logging (What happened?)
- Structured JSON logs with context (request_id, user_id, service_name)
- Levels: DEBUG < INFO < WARNING < ERROR < CRITICAL
- Centralize with Loki, ElasticSearch, or CloudWatch
- Never log sensitive data

### 2. Metrics (How much/how many?)
- **Counter:** Monotonically increasing (requests_total)
- **Gauge:** Current value (active_connections)
- **Histogram:** Distribution (request_duration_seconds)
- **Summary:** Quantiles (p95, p99 latency)
- Track: request rate, error rate (4xx/5xx), latency percentiles, saturation (CPU/memory/disk)

### 3. Tracing (Where did time go?)
- Distributed tracing across services with OpenTelemetry
- Track request path, identify bottlenecks and slow queries

**See:** `references/observability-stack.md` for Prometheus, Grafana, Loki, Jaeger, and OpenTelemetry configurations.

## Deployment Strategies

| Strategy | How It Works | When to Use | Trade-off |
|----------|-------------|-------------|-----------|
| **Rolling** | Gradually replace old pods | Standard deploys, backward-compatible changes | Slower rollout |
| **Blue-Green** | Two environments, instant switch | DB migrations, major version updates | 2x infrastructure cost |
| **Canary** | Route small % to new version, increase if healthy | High-risk changes, need real-traffic validation | Complexity, needs metrics |

All strategies: use readiness probes, have rollback plan, monitor error rate and latency during rollout.

**See:** `references/deployment-strategies.md` for rollback procedures and automated canary configurations.

## Security Hardening

### Container Security
- Scan images for vulnerabilities (Trivy, Snyk)
- Minimal base images (distroless, scratch)
- Non-root user, read-only root filesystem, drop all capabilities
- Regular image updates

### Kubernetes Security
- Network policies (deny-all by default)
- Pod Security Standards (restricted mode)
- RBAC for least privilege access
- External secrets management (Vault, AWS Secrets Manager)
- Encrypt secrets at rest
- Admission controllers for policy enforcement

### Secrets Management
- Never commit to Git
- Use external secret stores, rotate regularly
- Audit access, mount as files (not env vars when possible)
- Scope to namespaces

**See:** `references/security-hardening.md` for network policies, image scanning automation, and compliance configurations.

## Infrastructure as Code

### Principles
- Version control all manifests
- Declarative over imperative
- Separate environment configs (dev/staging/prod)
- Validate before apply (`kubectl dry-run`, `helm lint`)
- Use GitOps (ArgoCD, Flux) -- Git as single source of truth

### Helm Best Practices
- Template for environment differences, override with env-specific values files
- Version charts semantically
- Include sane defaults, validate before release

## Troubleshooting Checklist

| Symptom | Commands | Common Causes |
|---------|----------|---------------|
| Pod not starting | `kubectl describe pod <name>`, `kubectl logs <name>`, `kubectl get events --sort-by=.metadata.creationTimestamp` | Image pull errors, resource limits, health check failures |
| Service unreachable | `kubectl get svc,endpoints <name>`, `kubectl describe svc <name>` | Label mismatch, port misconfiguration, network policies |
| High resource usage | `kubectl top pods`, `kubectl describe node <name>` | No resource limits, memory leaks, inefficient code |
| Deployment stuck | `kubectl rollout status deployment/<name>`, `kubectl get events \| grep <name>` | Failing health checks, insufficient resources, image issues |

## Quick Reference Links

- `references/docker-complete.md` - Comprehensive Docker guide
- `references/kubernetes-manifests.md` - K8s manifests and Helm charts
- `references/github-actions.md` - Complete CI/CD workflows
- `references/observability-stack.md` - Monitoring and logging setup
- `references/deployment-strategies.md` - Deployment patterns and rollbacks
- `references/security-hardening.md` - Security best practices

## Key Principles

1. **Automate Everything** - Manual processes are error-prone
2. **Measure Everything** - Can't improve what you don't measure
3. **Fail Fast** - Catch issues early in pipeline
4. **Immutable Infrastructure** - Replace, don't modify
5. **Infrastructure as Code** - Version control all config
6. **Monitor Proactively** - Alert before users notice
7. **Practice Chaos** - Test failure scenarios regularly
8. **Document Runbooks** - Incident response should be scripted

<!-- Last reviewed: 2026-03 -->
