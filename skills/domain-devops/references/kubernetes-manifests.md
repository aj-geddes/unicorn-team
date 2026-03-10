# Kubernetes Manifests Complete Reference

Comprehensive guide to Kubernetes resources, Helm charts, security configurations, and advanced patterns.

## Production-Ready Deployment

### Complete Deployment Manifest
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: production
  labels:
    app: myapp
    version: v1
    component: backend
  annotations:
    description: "Production API server"
spec:
  replicas: 3
  revisionHistoryLimit: 10
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  selector:
    matchLabels:
      app: myapp
      component: backend
  template:
    metadata:
      labels:
        app: myapp
        version: v1
        component: backend
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      serviceAccountName: myapp
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
        seccompProfile:
          type: RuntimeDefault

      # Pod anti-affinity for high availability
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - myapp
              topologyKey: kubernetes.io/hostname

      # Init container for migrations
      initContainers:
      - name: migrations
        image: ghcr.io/org/myapp:v1.0.0
        command: ["python", "manage.py", "migrate"]
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: myapp-secrets
              key: database-url
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL

      containers:
      - name: myapp
        image: ghcr.io/org/myapp:v1.0.0
        imagePullPolicy: IfNotPresent

        ports:
        - name: http
          containerPort: 8080
          protocol: TCP
        - name: metrics
          containerPort: 9090
          protocol: TCP

        env:
        - name: PORT
          value: "8080"
        - name: LOG_LEVEL
          value: "info"
        - name: ENVIRONMENT
          value: "production"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: myapp-secrets
              key: database-url
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: myapp-secrets
              key: redis-url
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: myapp-secrets
              key: api-key

        # ConfigMap for non-sensitive config
        envFrom:
        - configMapRef:
            name: myapp-config

        resources:
          requests:
            cpu: 100m
            memory: 128Mi
            ephemeral-storage: 1Gi
          limits:
            cpu: 500m
            memory: 512Mi
            ephemeral-storage: 2Gi

        livenessProbe:
          httpGet:
            path: /healthz
            port: http
            httpHeaders:
            - name: X-Probe
              value: liveness
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 3
          failureThreshold: 3
          successThreshold: 1

        readinessProbe:
          httpGet:
            path: /ready
            port: http
            httpHeaders:
            - name: X-Probe
              value: readiness
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 2
          failureThreshold: 3
          successThreshold: 2

        startupProbe:
          httpGet:
            path: /healthz
            port: http
          initialDelaySeconds: 0
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 30

        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1000
          capabilities:
            drop:
            - ALL

        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: cache
          mountPath: /app/cache
        - name: config
          mountPath: /app/config
          readOnly: true

      volumes:
      - name: tmp
        emptyDir: {}
      - name: cache
        emptyDir:
          sizeLimit: 1Gi
      - name: config
        configMap:
          name: myapp-config
          defaultMode: 0444

      # DNS configuration
      dnsPolicy: ClusterFirst
      dnsConfig:
        options:
        - name: ndots
          value: "2"
        - name: timeout
          value: "2"
        - name: attempts
          value: "2"

      # Tolerations for node taints
      tolerations:
      - key: "node.kubernetes.io/not-ready"
        operator: "Exists"
        effect: "NoExecute"
        tolerationSeconds: 300

      # Termination grace period
      terminationGracePeriodSeconds: 30
```

## Service Types and Patterns

### ClusterIP (Internal Only)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp
  namespace: production
  labels:
    app: myapp
spec:
  type: ClusterIP
  selector:
    app: myapp
  ports:
  - name: http
    port: 80
    targetPort: http
    protocol: TCP
  sessionAffinity: None
```

### LoadBalancer (External)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-external
  namespace: production
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-internal: "false"
spec:
  type: LoadBalancer
  selector:
    app: myapp
  ports:
  - name: https
    port: 443
    targetPort: 8080
    protocol: TCP
  externalTrafficPolicy: Local  # Preserve source IP
```

### Headless Service (Direct Pod Access)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-headless
  namespace: production
spec:
  clusterIP: None  # Headless
  selector:
    app: myapp
  ports:
  - name: http
    port: 8080
    targetPort: 8080
```

## Ingress Configurations

### NGINX Ingress with TLS
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp
  namespace: production
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "60"
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "https://example.com"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - api.example.com
    - www.example.com
    secretName: myapp-tls
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp
            port:
              number: 80
  - host: www.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp
            port:
              number: 80
```

### Path-Based Routing
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-service
  namespace: production
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  rules:
  - host: example.com
    http:
      paths:
      - path: /api(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 80
      - path: /auth(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: auth-service
            port:
              number: 80
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
```

## ConfigMap and Secrets

### ConfigMap with Multiple Data Types
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: myapp-config
  namespace: production
data:
  # Simple key-value
  LOG_LEVEL: "info"
  MAX_CONNECTIONS: "100"

  # Configuration file
  app.yaml: |
    server:
      port: 8080
      timeout: 30s
    database:
      max_connections: 100
      timeout: 5s
    cache:
      ttl: 3600

  # Script file
  startup.sh: |
    #!/bin/bash
    echo "Starting application..."
    exec /app/server
```

### External Secrets Operator
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: myapp-secrets
  namespace: production
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: myapp-secrets
    creationPolicy: Owner
    template:
      engineVersion: v2
      data:
        database-url: "postgresql://{{ .username }}:{{ .password }}@{{ .host }}:5432/{{ .database }}"
  data:
  - secretKey: username
    remoteRef:
      key: prod/myapp/database
      property: username
  - secretKey: password
    remoteRef:
      key: prod/myapp/database
      property: password
  - secretKey: host
    remoteRef:
      key: prod/myapp/database
      property: host
  - secretKey: database
    remoteRef:
      key: prod/myapp/database
      property: database
  - secretKey: api-key
    remoteRef:
      key: prod/myapp/api-key
```

### Sealed Secrets (GitOps-Safe)
```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: myapp-secrets
  namespace: production
spec:
  encryptedData:
    database-url: AgBqZ2F... # Encrypted value
    api-key: AgCyYmQ... # Encrypted value
  template:
    metadata:
      name: myapp-secrets
      namespace: production
    type: Opaque
```

Create sealed secret:
```bash
kubectl create secret generic myapp-secrets \
  --from-literal=database-url='postgresql://...' \
  --dry-run=client -o yaml | \
kubeseal -o yaml > sealed-secret.yaml
```

## Horizontal Pod Autoscaler (HPA)

### CPU and Memory Based
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300  # 5 minutes
      policies:
      - type: Percent
        value: 50  # Scale down max 50% at a time
        periodSeconds: 60
      - type: Pods
        value: 2  # Or max 2 pods at a time
        periodSeconds: 60
      selectPolicy: Min  # Choose most conservative
    scaleUp:
      stabilizationWindowSeconds: 0  # Scale up immediately
      policies:
      - type: Percent
        value: 100  # Double pods at a time
        periodSeconds: 30
      - type: Pods
        value: 4  # Or add 4 pods at a time
        periodSeconds: 30
      selectPolicy: Max  # Choose most aggressive
```

### Custom Metrics (Request Rate)
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-custom
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 3
  maxReplicas: 50
  metrics:
  # Custom metric from Prometheus
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "1000"
  # External metric
  - type: External
    external:
      metric:
        name: sqs_queue_depth
        selector:
          matchLabels:
            queue: "myapp-jobs"
      target:
        type: AverageValue
        averageValue: "30"
```

## StatefulSet for Stateful Applications

### Database with Persistent Storage
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: production
spec:
  serviceName: postgres
  replicas: 3
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        ports:
        - containerPort: 5432
          name: postgres
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secrets
              key: password
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            cpu: 500m
            memory: 1Gi
          limits:
            cpu: 2000m
            memory: 4Gi
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: fast-ssd
      resources:
        requests:
          storage: 100Gi
```

## Helm Charts

### Chart.yaml
```yaml
apiVersion: v2
name: myapp
description: Production-ready application deployment
type: application
version: 1.0.0
appVersion: "1.0.0"
kubeVersion: ">=1.25.0"
keywords:
  - web
  - api
  - microservice
home: https://github.com/org/myapp
sources:
  - https://github.com/org/myapp
maintainers:
  - name: DevOps Team
    email: devops@example.com
dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled
  - name: redis
    version: "17.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: redis.enabled
```

### values.yaml
```yaml
# Default values for myapp

replicaCount: 3

image:
  repository: ghcr.io/org/myapp
  pullPolicy: IfNotPresent
  tag: ""  # Defaults to .Chart.AppVersion

imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""

serviceAccount:
  create: true
  annotations: {}
  name: ""

podAnnotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8080"

podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault

securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
    - ALL

service:
  type: ClusterIP
  port: 80
  targetPort: 8080
  annotations: {}

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: myapp.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: myapp-tls
      hosts:
        - myapp.example.com

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80

nodeSelector: {}

tolerations: []

affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - key: app.kubernetes.io/name
            operator: In
            values:
            - myapp
        topologyKey: kubernetes.io/hostname

# Application configuration
config:
  logLevel: info
  environment: production

# External dependencies
postgresql:
  enabled: true
  auth:
    database: myapp
    username: myapp
  primary:
    persistence:
      size: 100Gi

redis:
  enabled: true
  architecture: standalone
  master:
    persistence:
      size: 10Gi
```

### values-production.yaml
```yaml
# Production overrides

replicaCount: 5

image:
  tag: "v1.0.0"  # Specific version

resources:
  requests:
    cpu: 200m
    memory: 256Mi
  limits:
    cpu: 1000m
    memory: 1Gi

autoscaling:
  minReplicas: 5
  maxReplicas: 20

postgresql:
  primary:
    persistence:
      size: 500Gi
    resources:
      requests:
        cpu: 1000m
        memory: 2Gi
      limits:
        cpu: 4000m
        memory: 8Gi

redis:
  master:
    resources:
      requests:
        cpu: 500m
        memory: 512Mi
      limits:
        cpu: 2000m
        memory: 2Gi
```

### templates/deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "myapp.fullname" . }}
  labels:
    {{- include "myapp.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "myapp.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      annotations:
        checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
        {{- with .Values.podAnnotations }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      labels:
        {{- include "myapp.selectorLabels" . | nindent 8 }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      serviceAccountName: {{ include "myapp.serviceAccountName" . }}
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}
      containers:
      - name: {{ .Chart.Name }}
        securityContext:
          {{- toYaml .Values.securityContext | nindent 12 }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - name: http
          containerPort: {{ .Values.service.targetPort }}
          protocol: TCP
        livenessProbe:
          httpGet:
            path: /healthz
            port: http
        readinessProbe:
          httpGet:
            path: /ready
            port: http
        resources:
          {{- toYaml .Values.resources | nindent 12 }}
        envFrom:
        - configMapRef:
            name: {{ include "myapp.fullname" . }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
```

### templates/_helpers.tpl
```yaml
{{/*
Expand the name of the chart.
*/}}
{{- define "myapp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "myapp.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "myapp.labels" -}}
helm.sh/chart: {{ include "myapp.chart" . }}
{{ include "myapp.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "myapp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "myapp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "myapp.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "myapp.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
```

## Helm Commands

```bash
# Install chart
helm install myapp ./myapp -n production

# Install with custom values
helm install myapp ./myapp \
  -n production \
  -f values-production.yaml \
  --set image.tag=v1.0.0

# Upgrade release
helm upgrade myapp ./myapp -n production

# Rollback
helm rollback myapp 1 -n production

# List releases
helm list -n production

# Get values
helm get values myapp -n production

# Test chart
helm lint ./myapp
helm template myapp ./myapp --debug

# Package chart
helm package ./myapp

# Dry run
helm install myapp ./myapp -n production --dry-run --debug
```

## Resource Quotas and Limits

### Namespace ResourceQuota
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: production-quota
  namespace: production
spec:
  hard:
    requests.cpu: "100"
    requests.memory: 200Gi
    limits.cpu: "200"
    limits.memory: 400Gi
    persistentvolumeclaims: "10"
    services.loadbalancers: "2"
    pods: "100"
```

### LimitRange
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: production-limits
  namespace: production
spec:
  limits:
  - max:
      cpu: "4"
      memory: 8Gi
    min:
      cpu: 50m
      memory: 64Mi
    default:
      cpu: 500m
      memory: 512Mi
    defaultRequest:
      cpu: 100m
      memory: 128Mi
    type: Container
  - max:
      storage: 100Gi
    min:
      storage: 1Gi
    type: PersistentVolumeClaim
```

## Pod Disruption Budget

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: myapp-pdb
  namespace: production
spec:
  minAvailable: 2  # Or use maxUnavailable: 1
  selector:
    matchLabels:
      app: myapp
```

## Network Policy

See `security-hardening.md` for complete network policy examples.

## RBAC Configuration

### ServiceAccount
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: myapp
  namespace: production
```

### Role
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: myapp
  namespace: production
rules:
- apiGroups: [""]
  resources: ["configmaps", "secrets"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
```

### RoleBinding
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: myapp
  namespace: production
subjects:
- kind: ServiceAccount
  name: myapp
  namespace: production
roleRef:
  kind: Role
  name: myapp
  apiGroup: rbac.authorization.k8s.io
```

## Best Practices Summary

1. **Resource Management**
   - Always set requests and limits
   - Use HPA for auto-scaling
   - Monitor resource usage

2. **High Availability**
   - Multiple replicas (minimum 3)
   - Pod anti-affinity
   - Pod disruption budgets
   - Readiness probes

3. **Security**
   - Run as non-root
   - Read-only filesystem
   - Network policies
   - RBAC
   - External secrets

4. **Observability**
   - Prometheus annotations
   - Structured logging
   - Health checks
   - Tracing enabled

5. **GitOps**
   - Version control all manifests
   - Use Helm for templating
   - Separate environment values
   - Validate before apply
