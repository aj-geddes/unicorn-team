# Pipeline Templates

## GitHub Actions: Full CI/CD Pipeline

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Secret Scanning
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./
          base: ${{ github.event.repository.default_branch }}

      - name: Dependency Audit
        run: |
          npm audit --audit-level=high
          # or: pip-audit
          # or: go list -json -m all | nancy sleuth

  build:
    needs: validate
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and Push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

      - name: Scan Image
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH'

  test:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Tests
        run: |
          pytest --cov=. --cov-fail-under=80 --cov-report=xml

      - name: Upload Coverage
        uses: codecov/codecov-action@v3

  deploy-staging:
    needs: test
    if: github.ref == 'refs/heads/develop'
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - uses: actions/checkout@v4

      - name: Deploy to Staging
        run: |
          kubectl set image deployment/app \
            app=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }} \
            --namespace=staging

      - name: Verify Deployment
        run: |
          kubectl rollout status deployment/app --namespace=staging
          kubectl wait --for=condition=ready pod -l app=myapp --namespace=staging

      - name: Smoke Tests
        run: |
          ./scripts/smoke-tests.sh $STAGING_URL

  deploy-production:
    needs: deploy-staging
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4

      - name: Deploy to Production (Blue-Green)
        run: |
          # Deploy to green
          kubectl apply -f k8s/deployment-green.yaml
          kubectl wait --for=condition=ready pod -l version=green

          # Run health checks
          ./scripts/health-check.sh green

          # Switch traffic
          kubectl patch service myapp -p '{"spec":{"selector":{"version":"green"}}}'

          # Keep blue for rollback (10 min)
          sleep 600
          kubectl delete -f k8s/deployment-blue.yaml
```

## Image Scanning Step

```yaml
- name: Scan Docker Image
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: myapp:latest
    format: 'table'
    exit-code: '1'
    ignore-unfixed: true
    vuln-type: 'os,library'
    severity: 'CRITICAL,HIGH'

- name: Scan Dependencies
  run: |
    # Python
    pip-audit --strict

    # Node.js
    npm audit --audit-level=high

    # Go
    govulncheck ./...
```

## Automated Dependency Updates

```yaml
name: Dependency Update
on:
  schedule:
    - cron: '0 0 * * 1'  # Weekly on Monday

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Update Dependencies
        run: |
          npm update
          npm audit fix

      - name: Run Tests
        run: npm test

      - name: Create PR
        uses: peter-evans/create-pull-request@v5
        with:
          title: "chore: update dependencies"
          body: "Automated dependency update with security patches"
          branch: deps/update-dependencies
```
