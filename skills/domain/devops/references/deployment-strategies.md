# Deployment Strategies Complete Reference

Complete guide to deployment patterns, rollback procedures, canary releases, and GitOps automation.

## Rolling Update Deployment

### Kubernetes Rolling Update
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 10
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2        # Create 2 extra pods during update
      maxUnavailable: 1  # Allow 1 pod to be unavailable
  minReadySeconds: 30    # Wait 30s before considering pod ready
  progressDeadlineSeconds: 600  # Fail deployment after 10 minutes

  template:
    spec:
      containers:
      - name: myapp
        image: myapp:v2.0.0
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          periodSeconds: 5
          successThreshold: 2  # Must pass readiness twice
          failureThreshold: 3

        # Graceful shutdown
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 15"]  # Allow time for connections to drain

      terminationGracePeriodSeconds: 30
```

### Rolling Update Commands
```bash
# Apply new version
kubectl apply -f deployment.yaml

# Watch rollout progress
kubectl rollout status deployment/myapp

# View rollout history
kubectl rollout history deployment/myapp

# Pause rollout (if issues detected)
kubectl rollout pause deployment/myapp

# Resume rollout
kubectl rollout resume deployment/myapp

# Rollback to previous version
kubectl rollout undo deployment/myapp

# Rollback to specific revision
kubectl rollout undo deployment/myapp --to-revision=3

# View specific revision
kubectl rollout history deployment/myapp --revision=3
```

### Automated Rollback on Failure
```yaml
# Progressive rollout with automated rollback
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: myapp
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  progressDeadlineSeconds: 600
  service:
    port: 80
  analysis:
    interval: 1m
    threshold: 5  # Rollback after 5 failed checks
    iterations: 10
    metrics:
    - name: request-success-rate
      thresholdRange:
        min: 99  # Must maintain 99% success rate
      interval: 1m
    - name: request-duration
      thresholdRange:
        max: 500  # Max 500ms latency
      interval: 1m
```

## Blue-Green Deployment

### Kubernetes Blue-Green Pattern
```yaml
# Blue deployment (current production)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-blue
  namespace: production
spec:
  replicas: 5
  selector:
    matchLabels:
      app: myapp
      version: blue
  template:
    metadata:
      labels:
        app: myapp
        version: blue
    spec:
      containers:
      - name: myapp
        image: myapp:v1.0.0
        ports:
        - containerPort: 8080

---
# Green deployment (new version)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-green
  namespace: production
spec:
  replicas: 5
  selector:
    matchLabels:
      app: myapp
      version: green
  template:
    metadata:
      labels:
        app: myapp
        version: green
    spec:
      containers:
      - name: myapp
        image: myapp:v2.0.0
        ports:
        - containerPort: 8080

---
# Service (initially points to blue)
apiVersion: v1
kind: Service
metadata:
  name: myapp
  namespace: production
spec:
  selector:
    app: myapp
    version: blue  # Switch to 'green' to promote
  ports:
  - port: 80
    targetPort: 8080

---
# Internal service for testing green
apiVersion: v1
kind: Service
metadata:
  name: myapp-green-test
  namespace: production
spec:
  selector:
    app: myapp
    version: green
  ports:
  - port: 80
    targetPort: 8080
```

### Blue-Green Deployment Script
```bash
#!/bin/bash
set -euo pipefail

NAMESPACE="production"
APP_NAME="myapp"
NEW_VERSION="v2.0.0"

echo "Starting Blue-Green Deployment..."

# 1. Deploy green environment
echo "Deploying green environment with version $NEW_VERSION"
kubectl apply -f deployment-green.yaml

# 2. Wait for green to be ready
echo "Waiting for green deployment to be ready..."
kubectl rollout status deployment/${APP_NAME}-green -n $NAMESPACE --timeout=5m

# 3. Verify green is healthy
echo "Verifying green deployment health..."
kubectl wait --for=condition=available --timeout=5m \
  deployment/${APP_NAME}-green -n $NAMESPACE

# 4. Run smoke tests against green
echo "Running smoke tests against green..."
GREEN_IP=$(kubectl get svc ${APP_NAME}-green-test -n $NAMESPACE -o jsonpath='{.spec.clusterIP}')
./smoke-tests.sh http://$GREEN_IP || {
  echo "Smoke tests failed! Rolling back..."
  kubectl delete deployment/${APP_NAME}-green -n $NAMESPACE
  exit 1
}

# 5. Run integration tests
echo "Running integration tests..."
./integration-tests.sh http://$GREEN_IP || {
  echo "Integration tests failed! Rolling back..."
  kubectl delete deployment/${APP_NAME}-green -n $NAMESPACE
  exit 1
}

# 6. Switch traffic to green
echo "Switching traffic to green..."
kubectl patch service $APP_NAME -n $NAMESPACE \
  -p '{"spec":{"selector":{"version":"green"}}}'

echo "Traffic switched to green. Monitoring..."

# 7. Monitor for issues
MONITOR_TIME=600  # 10 minutes
echo "Monitoring green for $MONITOR_TIME seconds..."
sleep $MONITOR_TIME

# 8. Check error rate
ERROR_RATE=$(kubectl exec -n observability prometheus-0 -- \
  promtool query instant 'rate(http_requests_total{status=~"5..", service="myapp"}[5m]) / rate(http_requests_total{service="myapp"}[5m])' | \
  grep -oP '\d+\.\d+' | head -1)

if (( $(echo "$ERROR_RATE > 0.01" | bc -l) )); then
  echo "Error rate too high ($ERROR_RATE)! Rolling back..."
  kubectl patch service $APP_NAME -n $NAMESPACE \
    -p '{"spec":{"selector":{"version":"blue"}}}'
  exit 1
fi

# 9. Success - scale down blue
echo "Deployment successful! Scaling down blue..."
kubectl scale deployment/${APP_NAME}-blue -n $NAMESPACE --replicas=0

# 10. Keep blue for 24h before deletion
echo "Blue environment scaled to 0. Will be deleted after 24h."

echo "Blue-Green deployment completed successfully!"
```

## Canary Deployment

### Flagger Canary Configuration
```yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: myapp
  namespace: production
spec:
  # Target deployment
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp

  # Service configuration
  service:
    port: 80
    targetPort: 8080
    gateways:
    - public-gateway
    hosts:
    - myapp.example.com

  # Autoscaler reference
  autoscalerRef:
    apiVersion: autoscaling/v2
    kind: HorizontalPodAutoscaler
    name: myapp

  # Progressive traffic shifting
  analysis:
    interval: 1m
    threshold: 10
    maxWeight: 50
    stepWeight: 5
    stepWeightPromotion: 5

    # Metrics to check
    metrics:
    # Success rate must be > 99%
    - name: request-success-rate
      thresholdRange:
        min: 99
      interval: 1m

    # Request duration P99 must be < 500ms
    - name: request-duration
      thresholdRange:
        max: 500
      interval: 1m

    # Custom metric from Prometheus
    - name: error-rate
      templateRef:
        name: error-rate
        namespace: flagger-system
      thresholdRange:
        max: 0.01
      interval: 1m

  # Webhooks for testing
  webhooks:
  # Pre-rollout webhook (smoke tests)
  - name: pre-rollout
    type: pre-rollout
    url: http://flagger-loadtester.test/
    timeout: 15s
    metadata:
      type: bash
      cmd: "curl -sd 'test' http://myapp-canary/health | grep ok"

  # Load test during rollout
  - name: load-test
    type: rollout
    url: http://flagger-loadtester.test/
    timeout: 5s
    metadata:
      type: cmd
      cmd: "hey -z 1m -q 10 -c 2 http://myapp-canary/"

  # Post-rollout notification
  - name: slack
    type: post-rollout
    url: https://hooks.slack.com/services/xxx
    metadata:
      message: |
        {
          "text": "Canary deployment completed for myapp"
        }
```

### Manual Canary with Istio
```yaml
# VirtualService for traffic splitting
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - myapp.example.com
  gateways:
  - public-gateway
  http:
  - match:
    - headers:
        x-canary:
          exact: "true"
    route:
    - destination:
        host: myapp
        subset: canary
  - route:
    - destination:
        host: myapp
        subset: stable
      weight: 95
    - destination:
        host: myapp
        subset: canary
      weight: 5

---
# DestinationRule for subsets
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: myapp
spec:
  host: myapp
  subsets:
  - name: stable
    labels:
      version: stable
  - name: canary
    labels:
      version: canary
```

### Gradual Traffic Shift Script
```bash
#!/bin/bash
set -euo pipefail

APP="myapp"
NAMESPACE="production"

# Traffic percentages to shift
STEPS=(5 10 25 50 100)
MONITOR_TIME=300  # 5 minutes per step

for WEIGHT in "${STEPS[@]}"; do
  STABLE_WEIGHT=$((100 - WEIGHT))

  echo "Shifting traffic: Stable=$STABLE_WEIGHT%, Canary=$WEIGHT%"

  kubectl patch virtualservice $APP -n $NAMESPACE --type=json -p="[
    {
      \"op\": \"replace\",
      \"path\": \"/spec/http/0/route/0/weight\",
      \"value\": $STABLE_WEIGHT
    },
    {
      \"op\": \"replace\",
      \"path\": \"/spec/http/0/route/1/weight\",
      \"value\": $WEIGHT
    }
  ]"

  echo "Monitoring for $MONITOR_TIME seconds..."
  sleep $MONITOR_TIME

  # Check error rate
  ERROR_RATE=$(curl -s 'http://prometheus:9090/api/v1/query?query=rate(http_requests_total{status=~"5..",service="myapp",version="canary"}[5m])/rate(http_requests_total{service="myapp",version="canary"}[5m])' | \
    jq -r '.data.result[0].value[1]')

  if (( $(echo "$ERROR_RATE > 0.01" | bc -l) )); then
    echo "Error rate too high! Rolling back..."
    kubectl patch virtualservice $APP -n $NAMESPACE --type=json -p="[
      {\"op\": \"replace\", \"path\": \"/spec/http/0/route/0/weight\", \"value\": 100},
      {\"op\": \"replace\", \"path\": \"/spec/http/0/route/1/weight\", \"value\": 0}
    ]"
    exit 1
  fi

  echo "Step $WEIGHT% successful"
done

echo "Canary deployment completed successfully!"
```

## GitOps with ArgoCD

### ArgoCD Application
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  project: production

  source:
    repoURL: https://github.com/org/myapp
    targetRevision: main
    path: k8s/overlays/production
    helm:
      valueFiles:
      - values-production.yaml

  destination:
    server: https://kubernetes.default.svc
    namespace: production

  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
    - CreateNamespace=true
    - PruneLast=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m

  # Health checks
  ignoreDifferences:
  - group: apps
    kind: Deployment
    jsonPointers:
    - /spec/replicas  # Ignore HPA changes

  # Notifications
  annotations:
    notifications.argoproj.io/subscribe.on-sync-succeeded.slack: production-deploys
    notifications.argoproj.io/subscribe.on-sync-failed.slack: production-alerts
```

### Progressive Delivery with ArgoCD Rollouts
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: myapp
spec:
  replicas: 10
  strategy:
    canary:
      steps:
      - setWeight: 10
      - pause: {duration: 5m}
      - setWeight: 20
      - pause: {duration: 5m}
      - setWeight: 40
      - pause: {duration: 10m}
      - setWeight: 60
      - pause: {duration: 10m}
      - setWeight: 80
      - pause: {duration: 10m}

      # Analysis during rollout
      analysis:
        templates:
        - templateName: success-rate
        startingStep: 2  # Start after 20% traffic
        args:
        - name: service-name
          value: myapp

      # Automatic rollback
      maxUnavailable: 1
      maxSurge: 1

  template:
    spec:
      containers:
      - name: myapp
        image: myapp:v2.0.0

---
# Analysis template
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate
spec:
  args:
  - name: service-name
  metrics:
  - name: success-rate
    interval: 1m
    successCondition: result[0] >= 0.99
    failureLimit: 3
    provider:
      prometheus:
        address: http://prometheus:9090
        query: |
          sum(rate(http_requests_total{service="{{args.service-name}}",status!~"5.."}[5m]))
          /
          sum(rate(http_requests_total{service="{{args.service-name}}"}[5m]))
```

## GitOps with Flux

### Flux GitRepository
```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: myapp
  namespace: flux-system
spec:
  interval: 1m
  url: https://github.com/org/myapp
  ref:
    branch: main
  secretRef:
    name: git-credentials
  ignore: |
    # Ignore everything except k8s manifests
    /*
    !/k8s/
```

### Flux Kustomization
```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: myapp
  namespace: flux-system
spec:
  interval: 10m
  sourceRef:
    kind: GitRepository
    name: myapp
  path: ./k8s/overlays/production
  prune: true
  wait: true
  timeout: 5m

  # Health checks
  healthChecks:
  - apiVersion: apps/v1
    kind: Deployment
    name: myapp
    namespace: production

  # Post-deployment verification
  postBuild:
    substitute:
      ENVIRONMENT: "production"
    substituteFrom:
    - kind: ConfigMap
      name: cluster-vars
```

### Flux Image Automation
```yaml
# Image repository
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImageRepository
metadata:
  name: myapp
  namespace: flux-system
spec:
  image: ghcr.io/org/myapp
  interval: 1m

---
# Image policy
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImagePolicy
metadata:
  name: myapp
  namespace: flux-system
spec:
  imageRepositoryRef:
    name: myapp
  policy:
    semver:
      range: 1.x.x  # Only 1.x versions

---
# Image update automation
apiVersion: image.toolkit.fluxcd.io/v1beta1
kind: ImageUpdateAutomation
metadata:
  name: myapp
  namespace: flux-system
spec:
  interval: 1m
  sourceRef:
    kind: GitRepository
    name: myapp
  git:
    checkout:
      ref:
        branch: main
    commit:
      author:
        email: fluxcd@example.com
        name: Flux
      messageTemplate: |
        Update image to {{range .Updated.Images}}{{println .}}{{end}}
  update:
    path: ./k8s/overlays/production
    strategy: Setters
```

## Rollback Procedures

### Immediate Rollback
```bash
#!/bin/bash
# Emergency rollback script

DEPLOYMENT="myapp"
NAMESPACE="production"

echo "EMERGENCY ROLLBACK INITIATED"

# Rollback to previous version
kubectl rollout undo deployment/$DEPLOYMENT -n $NAMESPACE

# Wait for rollback to complete
kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE --timeout=5m

# Verify health
READY=$(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.status.readyReplicas}')
DESIRED=$(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.replicas}')

if [ "$READY" -eq "$DESIRED" ]; then
  echo "Rollback successful: $READY/$DESIRED pods ready"
else
  echo "Rollback FAILED: Only $READY/$DESIRED pods ready"
  exit 1
fi

# Notify team
curl -X POST -H 'Content-type: application/json' \
  --data "{\"text\":\"ROLLBACK: $DEPLOYMENT rolled back in $NAMESPACE\"}" \
  $SLACK_WEBHOOK_URL
```

### Database Migration Rollback
```bash
#!/bin/bash
set -euo pipefail

# Rollback with database migration handling

DEPLOYMENT="myapp"
NAMESPACE="production"
DB_BACKUP="myapp-backup-$(date +%Y%m%d-%H%M%S)"

echo "Creating database backup..."
kubectl exec -n $NAMESPACE deployment/postgres -- \
  pg_dump -U postgres myapp > $DB_BACKUP.sql

echo "Stopping application pods..."
kubectl scale deployment/$DEPLOYMENT -n $NAMESPACE --replicas=0

echo "Rolling back database migrations..."
kubectl exec -n $NAMESPACE deployment/$DEPLOYMENT -- \
  python manage.py migrate --fake previous_migration

echo "Rolling back deployment..."
kubectl rollout undo deployment/$DEPLOYMENT -n $NAMESPACE

echo "Scaling up application..."
kubectl scale deployment/$DEPLOYMENT -n $NAMESPACE --replicas=5

echo "Waiting for rollout..."
kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE

echo "Rollback complete. Database backup: $DB_BACKUP.sql"
```

## Deployment Checklist

### Pre-Deployment
- [ ] Code reviewed and approved
- [ ] Tests passing (unit, integration, e2e)
- [ ] Security scan completed
- [ ] Database migrations tested
- [ ] Configuration validated
- [ ] Rollback plan documented
- [ ] Team notified
- [ ] Monitoring alerts configured
- [ ] Load test completed (if needed)
- [ ] Backup created

### During Deployment
- [ ] Monitor error rates
- [ ] Monitor latency (P95, P99)
- [ ] Monitor resource usage
- [ ] Check logs for errors
- [ ] Verify health checks passing
- [ ] Test critical user paths
- [ ] Monitor database performance
- [ ] Watch for alerts

### Post-Deployment
- [ ] All pods healthy
- [ ] Traffic distributed correctly
- [ ] No errors in logs
- [ ] Metrics look normal
- [ ] No active alerts
- [ ] Smoke tests passing
- [ ] Team notified of success
- [ ] Documentation updated
- [ ] Runbook updated (if needed)
- [ ] Old version can be safely removed

## Deployment Comparison

| Strategy | Downtime | Resource Cost | Rollback Speed | Risk | Complexity |
|----------|----------|---------------|----------------|------|------------|
| Rolling Update | None | 1x + surge | Fast | Low | Low |
| Blue-Green | None | 2x | Instant | Low | Medium |
| Canary | None | 1x + canary | Medium | Very Low | High |
| Recreate | Yes | 1x | Medium | High | Low |

## Best Practices

1. **Always test rollback procedures**
   - Regularly practice rollbacks
   - Automate rollback triggers
   - Document rollback steps

2. **Monitor during deployments**
   - Error rates
   - Latency percentiles
   - Resource usage
   - Business metrics

3. **Use progressive delivery**
   - Start with small percentage
   - Increase gradually
   - Automated rollback on issues

4. **Database migrations**
   - Make migrations backward compatible
   - Deploy migrations separately
   - Test rollback migrations

5. **Communication**
   - Notify team before deployment
   - Use deployment windows
   - Document changes
   - Alert on completion/failure

6. **GitOps**
   - Git as single source of truth
   - Automated drift detection
   - Declarative configuration
   - Audit trail via Git history
