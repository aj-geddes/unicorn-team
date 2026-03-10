# Security Hardening Complete Reference

Network policies, secrets management, image scanning, RBAC, compliance, and security best practices.

## Network Policies

### Default Deny All Traffic
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

Apply to namespace:
```bash
kubectl apply -f default-deny-all.yaml -n production
```

### Allow Ingress from Specific Namespace
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-ingress
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: myapp
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8080
```

### Allow Egress to Database
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-to-database
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: myapp
  policyTypes:
  - Egress
  egress:
  # Database
  - to:
    - podSelector:
        matchLabels:
          app: postgres
    ports:
    - protocol: TCP
      port: 5432

  # DNS (required for service discovery)
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    - podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
```

### Complete Application Policy
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: myapp-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: myapp
  policyTypes:
  - Ingress
  - Egress

  ingress:
  # Allow from ingress controller
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8080

  # Allow from prometheus (metrics scraping)
  - from:
    - namespaceSelector:
        matchLabels:
          name: observability
    - podSelector:
        matchLabels:
          app: prometheus
    ports:
    - protocol: TCP
      port: 9090

  egress:
  # Database
  - to:
    - podSelector:
        matchLabels:
          app: postgres
    ports:
    - protocol: TCP
      port: 5432

  # Redis
  - to:
    - podSelector:
        matchLabels:
          app: redis
    ports:
    - protocol: TCP
      port: 6379

  # External APIs (specific IPs or CIDR)
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - 169.254.169.254/32  # Block metadata service
    ports:
    - protocol: TCP
      port: 443

  # DNS
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
```

### Cilium Network Policy (Advanced)
```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: myapp-l7-policy
  namespace: production
spec:
  endpointSelector:
    matchLabels:
      app: myapp

  ingress:
  - fromEndpoints:
    - matchLabels:
        name: ingress-nginx
    toPorts:
    - ports:
      - port: "8080"
        protocol: TCP
      rules:
        http:
        # Allow only specific HTTP paths
        - method: "GET"
          path: "/api/.*"
        - method: "POST"
          path: "/api/.*"
        # Block admin paths
        - method: ".*"
          path: "/admin/.*"
          deny: true

  egress:
  # Allow only specific external domains
  - toFQDNs:
    - matchName: "api.example.com"
    - matchPattern: "*.amazonaws.com"
    toPorts:
    - ports:
      - port: "443"
        protocol: TCP
```

## Secrets Management

### Kubernetes Secrets (Base64 Encoded)
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: myapp-secrets
  namespace: production
type: Opaque
stringData:  # Will be base64 encoded automatically
  database-url: postgresql://user:pass@db:5432/myapp
  api-key: super-secret-key
  jwt-secret: jwt-signing-key
```

### External Secrets Operator (AWS Secrets Manager)
```yaml
# SecretStore configuration
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets-manager
  namespace: production
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets

---
# ExternalSecret that syncs from AWS
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
        # Construct connection string from parts
        database-url: "postgresql://{{ .username }}:{{ .password }}@{{ .host }}:5432/{{ .database }}"

  dataFrom:
  - extract:
      key: prod/myapp/database

  data:
  - secretKey: api-key
    remoteRef:
      key: prod/myapp/api-key

  - secretKey: jwt-secret
    remoteRef:
      key: prod/myapp/jwt-secret
```

### HashiCorp Vault Integration
```yaml
# Vault authentication
apiVersion: v1
kind: ServiceAccount
metadata:
  name: myapp
  namespace: production

---
# Vault role binding
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: myapp-vault-auth
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: myapp
  namespace: production

---
# Deployment with Vault agent sidecar
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "myapp"
        vault.hashicorp.com/agent-inject-secret-database: "secret/data/myapp/database"
        vault.hashicorp.com/agent-inject-template-database: |
          {{- with secret "secret/data/myapp/database" -}}
          export DATABASE_URL="postgresql://{{ .Data.data.username }}:{{ .Data.data.password }}@{{ .Data.data.host }}:5432/{{ .Data.data.database }}"
          {{- end }}
    spec:
      serviceAccountName: myapp
      containers:
      - name: myapp
        image: myapp:latest
        command: ["/bin/sh"]
        args:
        - -c
        - source /vault/secrets/database && exec /app/server
```

### Sealed Secrets
```yaml
# Install Sealed Secrets controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Create sealed secret
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: myapp-secrets
  namespace: production
spec:
  encryptedData:
    database-url: AgBqZ2FzZG... # Encrypted
    api-key: AgCyYmQ0Zm... # Encrypted
  template:
    metadata:
      name: myapp-secrets
      namespace: production
    type: Opaque
```

Create sealed secret:
```bash
# Create regular secret
kubectl create secret generic myapp-secrets \
  --from-literal=database-url='postgresql://...' \
  --from-literal=api-key='secret-key' \
  --dry-run=client -o yaml | \
kubeseal --controller-namespace=kube-system -o yaml > sealed-secret.yaml

# Apply sealed secret (safe to commit to Git)
kubectl apply -f sealed-secret.yaml
```

## Pod Security Standards

### Namespace with Restricted Policy
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### Pod Security Policy (Deprecated, use PSS)
```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
  - ALL
  volumes:
  - 'configMap'
  - 'emptyDir'
  - 'projected'
  - 'secret'
  - 'downwardAPI'
  - 'persistentVolumeClaim'
  hostNetwork: false
  hostIPC: false
  hostPID: false
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'RunAsAny'
  fsGroup:
    rule: 'RunAsAny'
  readOnlyRootFilesystem: true
```

### Security Context Best Practices
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      # Pod-level security context
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
        seccompProfile:
          type: RuntimeDefault

      containers:
      - name: myapp
        image: myapp:latest

        # Container-level security context
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1000
          capabilities:
            drop:
            - ALL
            # Only add specific capabilities if needed
            # add:
            # - NET_BIND_SERVICE

        # Volumes for writable directories
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: cache
          mountPath: /app/cache

      volumes:
      - name: tmp
        emptyDir: {}
      - name: cache
        emptyDir: {}
```

## Image Scanning

### Trivy Scanner in CI/CD
```yaml
# GitHub Actions
- name: Run Trivy vulnerability scanner
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: 'myapp:${{ github.sha }}'
    format: 'sarif'
    output: 'trivy-results.sarif'
    severity: 'CRITICAL,HIGH'
    exit-code: '1'  # Fail build on vulnerabilities

- name: Upload Trivy results to GitHub Security
  uses: github/codeql-action/upload-sarif@v2
  if: always()
  with:
    sarif_file: 'trivy-results.sarif'
```

### Trivy in Kubernetes (Admission Controller)
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: trivy-operator
  namespace: trivy-system
data:
  trivy.repository: "ghcr.io/aquasecurity/trivy"
  trivy.tag: "latest"
  scanJob.podTemplateSecurityContext: |
    runAsUser: 1000
    runAsNonRoot: true
    fsGroup: 1000

---
# Scan job for running containers
apiVersion: batch/v1
kind: CronJob
metadata:
  name: trivy-scan
  namespace: trivy-system
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: trivy
            image: aquasec/trivy:latest
            args:
            - image
            - --severity
            - CRITICAL,HIGH
            - --exit-code
            - "1"
            - --no-progress
            - myapp:latest
          restartPolicy: OnFailure
```

### Snyk Integration
```yaml
# .github/workflows/security.yml
- name: Run Snyk to check for vulnerabilities
  uses: snyk/actions/docker@master
  env:
    SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
  with:
    image: myapp:latest
    args: --severity-threshold=high --fail-on=upgradable
```

### Image Policy Enforcement (Kyverno)
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: check-image-signature
spec:
  validationFailureAction: enforce
  background: false
  rules:
  - name: check-signature
    match:
      any:
      - resources:
          kinds:
          - Pod
    verifyImages:
    - imageReferences:
      - "ghcr.io/org/*"
      attestors:
      - count: 1
        entries:
        - keys:
            publicKeys: |-
              -----BEGIN PUBLIC KEY-----
              MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE...
              -----END PUBLIC KEY-----

---
# Block images with HIGH/CRITICAL vulnerabilities
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: block-vulnerable-images
spec:
  validationFailureAction: enforce
  background: false
  rules:
  - name: block-vulnerable
    match:
      any:
      - resources:
          kinds:
          - Pod
    validate:
      message: "Image has HIGH or CRITICAL vulnerabilities"
      deny:
        conditions:
          any:
          - key: "{{ images.*.vulnerabilities.critical }}"
            operator: GreaterThan
            value: 0
          - key: "{{ images.*.vulnerabilities.high }}"
            operator: GreaterThan
            value: 5
```

## RBAC (Role-Based Access Control)

### ServiceAccount for Application
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: myapp
  namespace: production
automountServiceAccountToken: true

---
# Role with minimal permissions
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: myapp
  namespace: production
rules:
# Read ConfigMaps
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "watch"]

# Read Secrets
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]

# Read own pod info
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]

---
# RoleBinding
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

### ClusterRole for Cross-Namespace Access
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-pods-global
subjects:
- kind: ServiceAccount
  name: myapp
  namespace: production
roleRef:
  kind: ClusterRole
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### Admin Access (Break-Glass)
```yaml
# Emergency admin access (time-limited)
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: emergency-admin
  namespace: production
  annotations:
    expires: "2024-12-31T23:59:59Z"
subjects:
- kind: User
  name: admin@example.com
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: admin
  apiGroup: rbac.authorization.k8s.io
```

## Admission Controllers

### OPA Gatekeeper Policies
```yaml
# Install Gatekeeper
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.14/deploy/gatekeeper.yaml

---
# Require labels
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
      validation:
        openAPIV3Schema:
          type: object
          properties:
            labels:
              type: array
              items:
                type: string
  targets:
  - target: admission.k8s.gatekeeper.sh
    rego: |
      package k8srequiredlabels

      violation[{"msg": msg, "details": {"missing_labels": missing}}] {
        provided := {label | input.review.object.metadata.labels[label]}
        required := {label | label := input.parameters.labels[_]}
        missing := required - provided
        count(missing) > 0
        msg := sprintf("Missing required labels: %v", [missing])
      }

---
# Apply constraint
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: require-app-label
spec:
  match:
    kinds:
    - apiGroups: ["apps"]
      kinds: ["Deployment"]
    namespaces:
    - production
  parameters:
    labels:
    - app
    - version
    - owner
```

### Block Privileged Containers
```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sPSPPrivilegedContainer
metadata:
  name: block-privileged-containers
spec:
  match:
    kinds:
    - apiGroups: [""]
      kinds: ["Pod"]
  parameters:
    excludedNamespaces:
    - kube-system
```

## Compliance and Auditing

### Audit Policy
```yaml
# /etc/kubernetes/audit-policy.yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
# Log secrets access
- level: RequestResponse
  resources:
  - group: ""
    resources: ["secrets"]

# Log exec into containers
- level: Request
  verbs: ["create"]
  resources:
  - group: ""
    resources: ["pods/exec"]

# Log authentication failures
- level: Metadata
  omitStages:
  - RequestReceived
  users:
  - system:anonymous

# Don't log health checks
- level: None
  userGroups:
  - system:serviceaccounts:kube-system
  nonResourceURLs:
  - /healthz*
  - /version
  - /swagger*
```

### Falco Runtime Security
```yaml
# Install Falco
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm install falco falcosecurity/falco \
  --namespace falco \
  --create-namespace \
  --set falco.grpc.enabled=true

---
# Custom Falco rules
apiVersion: v1
kind: ConfigMap
metadata:
  name: falco-rules
  namespace: falco
data:
  custom-rules.yaml: |
    - rule: Unauthorized Process in Container
      desc: Detect processes not in whitelist
      condition: >
        spawned_process and
        container and
        not proc.name in (node, npm, python, java)
      output: >
        Unauthorized process started
        (user=%user.name command=%proc.cmdline
        container=%container.name image=%container.image)
      priority: WARNING

    - rule: Write Below Binary Dir
      desc: Detect writes below binary directories
      condition: >
        bin_dir and
        evt.dir = < and
        open_write and
        not package_mgmt_procs
      output: >
        File opened for writing below binary directory
        (user=%user.name command=%proc.cmdline
        file=%fd.name container=%container.name)
      priority: ERROR
```

## Certificate Management

### cert-manager Installation
```yaml
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

---
# ClusterIssuer for Let's Encrypt
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
    - dns01:
        cloudflare:
          email: admin@example.com
          apiTokenSecretRef:
            name: cloudflare-api-token
            key: api-token

---
# Certificate for domain
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: myapp-tls
  namespace: production
spec:
  secretName: myapp-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - myapp.example.com
  - www.myapp.example.com
```

## Security Scanning Checklist

### Container Images
- [ ] Base image from trusted source
- [ ] No CRITICAL/HIGH vulnerabilities
- [ ] Regular updates (at least monthly)
- [ ] Signed images
- [ ] Minimal attack surface (distroless/scratch)

### Kubernetes Configuration
- [ ] Network policies enforced
- [ ] Pod Security Standards applied
- [ ] RBAC least privilege
- [ ] Secrets encrypted at rest
- [ ] Admission controllers active
- [ ] Audit logging enabled

### Application Security
- [ ] Non-root containers
- [ ] Read-only root filesystem
- [ ] No privileged containers
- [ ] Capabilities dropped
- [ ] Resource limits set
- [ ] Health checks configured

### Network Security
- [ ] TLS for all external traffic
- [ ] mTLS for internal services (optional)
- [ ] Network policies restrict traffic
- [ ] Ingress properly configured
- [ ] No host network/IPC/PID

### Secrets Management
- [ ] External secrets operator used
- [ ] No secrets in code
- [ ] Secrets rotated regularly
- [ ] Access audited
- [ ] Encryption at rest

## Best Practices

1. **Defense in Depth**
   - Multiple layers of security
   - Network policies + RBAC + Pod Security
   - Scanning + Runtime protection

2. **Least Privilege**
   - Minimal RBAC permissions
   - Drop all capabilities
   - Read-only filesystem when possible

3. **Regular Updates**
   - Patch base images monthly
   - Update dependencies weekly
   - Kubernetes version within 2 minor versions

4. **Monitoring & Auditing**
   - Enable audit logging
   - Monitor security events
   - Alert on suspicious activity
   - Regular security reviews

5. **Secrets Management**
   - Never commit secrets to Git
   - Use external secret stores
   - Rotate secrets regularly
   - Audit secret access

6. **Compliance**
   - Document security policies
   - Regular compliance audits
   - Security training for team
   - Incident response plan
