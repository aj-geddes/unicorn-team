# GitHub Actions Complete Reference

Complete CI/CD workflows, matrix builds, caching strategies, deployment automation, and advanced patterns.

## Production-Ready CI/CD Pipeline

### Complete Workflow with All Stages
```yaml
# .github/workflows/ci-cd.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
    tags:
      - 'v*'
  pull_request:
    branches: [main, develop]
  workflow_dispatch:  # Manual trigger

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}
  PYTHON_VERSION: '3.11'
  NODE_VERSION: '20'

jobs:
  # Security scanning
  security-scan:
    name: Security Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'

      - name: Upload Trivy results to GitHub Security
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'

  # Linting
  lint:
    name: Lint Code
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'

      - name: Install linters
        run: |
          pip install ruff black mypy
          pip install -r requirements.txt

      - name: Run ruff
        run: ruff check .

      - name: Run black
        run: black --check .

      - name: Run mypy
        run: mypy .

  # Unit tests
  test:
    name: Test
    runs-on: ubuntu-latest
    needs: [security-scan, lint]

    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: testpass
          POSTGRES_DB: testdb
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

      redis:
        image: redis:7
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379

    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'

      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install -r requirements-dev.txt

      - name: Run tests
        env:
          DATABASE_URL: postgresql://postgres:testpass@localhost:5432/testdb
          REDIS_URL: redis://localhost:6379
        run: |
          pytest \
            --cov=. \
            --cov-fail-under=80 \
            --cov-report=xml \
            --cov-report=html \
            --junit-xml=junit.xml \
            -v

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage.xml
          flags: unittests
          name: codecov-umbrella

      - name: Upload test results
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: test-results
          path: |
            junit.xml
            htmlcov/

  # Integration tests
  integration-test:
    name: Integration Test
    runs-on: ubuntu-latest
    needs: test

    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Start services
        run: docker-compose -f docker-compose.test.yml up -d

      - name: Wait for services
        run: |
          timeout 60 bash -c 'until docker-compose -f docker-compose.test.yml ps | grep -q healthy; do sleep 2; done'

      - name: Run integration tests
        run: docker-compose -f docker-compose.test.yml exec -T app pytest tests/integration/

      - name: Collect logs
        if: failure()
        run: docker-compose -f docker-compose.test.yml logs

      - name: Cleanup
        if: always()
        run: docker-compose -f docker-compose.test.yml down -v

  # Build and push Docker image
  build:
    name: Build Image
    runs-on: ubuntu-latest
    needs: [test, integration-test]
    permissions:
      contents: read
      packages: write
      id-token: write

    outputs:
      image-digest: ${{ steps.build.outputs.digest }}
      image-tags: ${{ steps.meta.outputs.tags }}

    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=semver,pattern={{major}}
            type=sha,prefix={{branch}}-
            type=raw,value=latest,enable={{is_default_branch}}

      - name: Build and push
        id: build
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:buildcache
          cache-to: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:buildcache,mode=max
          platforms: linux/amd64,linux/arm64
          provenance: false

  # Scan built image
  scan-image:
    name: Scan Image
    runs-on: ubuntu-latest
    needs: build
    permissions:
      security-events: write

    steps:
      - name: Run Trivy scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          format: 'sarif'
          output: 'trivy-image-results.sarif'
          severity: 'CRITICAL,HIGH'

      - name: Upload results
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-image-results.sarif'

  # Deploy to staging
  deploy-staging:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    needs: [build, scan-image]
    if: github.ref == 'refs/heads/develop'
    environment:
      name: staging
      url: https://staging.example.com

    steps:
      - uses: actions/checkout@v4

      - name: Set up kubectl
        uses: azure/setup-kubectl@v3
        with:
          version: 'v1.28.0'

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN_STAGING }}
          aws-region: us-east-1

      - name: Update kubeconfig
        run: |
          aws eks update-kubeconfig --name staging-cluster --region us-east-1

      - name: Deploy with Helm
        run: |
          helm upgrade --install myapp ./helm/myapp \
            --namespace staging \
            --create-namespace \
            --set image.tag=${{ github.sha }} \
            --set environment=staging \
            --values ./helm/values-staging.yaml \
            --wait \
            --timeout 10m

      - name: Verify deployment
        run: |
          kubectl rollout status deployment/myapp -n staging --timeout=10m

      - name: Run smoke tests
        run: |
          ./scripts/smoke-test.sh https://staging.example.com

  # Deploy to production
  deploy-production:
    name: Deploy to Production
    runs-on: ubuntu-latest
    needs: [build, scan-image]
    if: startsWith(github.ref, 'refs/tags/v')
    environment:
      name: production
      url: https://example.com

    steps:
      - uses: actions/checkout@v4

      - name: Set up kubectl
        uses: azure/setup-kubectl@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN_PRODUCTION }}
          aws-region: us-east-1

      - name: Update kubeconfig
        run: |
          aws eks update-kubeconfig --name production-cluster --region us-east-1

      - name: Deploy with Helm (Blue-Green)
        run: |
          # Deploy green
          helm upgrade --install myapp-green ./helm/myapp \
            --namespace production \
            --set image.tag=${{ github.ref_name }} \
            --set environment=production \
            --set color=green \
            --values ./helm/values-production.yaml \
            --wait \
            --timeout 10m

      - name: Run production smoke tests
        run: |
          ./scripts/smoke-test.sh https://green.example.com

      - name: Switch traffic to green
        run: |
          kubectl patch service myapp -n production \
            -p '{"spec":{"selector":{"color":"green"}}}'

      - name: Monitor deployment
        run: |
          sleep 300  # Monitor for 5 minutes

      - name: Scale down blue
        if: success()
        run: |
          kubectl scale deployment/myapp-blue -n production --replicas=0

      - name: Rollback on failure
        if: failure()
        run: |
          kubectl patch service myapp -n production \
            -p '{"spec":{"selector":{"color":"blue"}}}'
          kubectl delete deployment/myapp-green -n production

  # Create GitHub release
  release:
    name: Create Release
    runs-on: ubuntu-latest
    needs: deploy-production
    if: startsWith(github.ref, 'refs/tags/v')
    permissions:
      contents: write

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Generate changelog
        id: changelog
        uses: metcalfc/changelog-generator@v4.1.0
        with:
          myToken: ${{ secrets.GITHUB_TOKEN }}

      - name: Create Release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref }}
          release_name: Release ${{ github.ref }}
          body: ${{ steps.changelog.outputs.changelog }}
          draft: false
          prerelease: false

  # Notify on failure
  notify:
    name: Notify Team
    runs-on: ubuntu-latest
    needs: [test, build, deploy-staging, deploy-production]
    if: failure()

    steps:
      - name: Send Slack notification
        uses: slackapi/slack-github-action@v1.24.0
        with:
          payload: |
            {
              "text": "Pipeline failed for ${{ github.repository }}",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": ":x: *Pipeline Failed*\n*Repository:* ${{ github.repository }}\n*Branch:* ${{ github.ref }}\n*Commit:* ${{ github.sha }}\n*Author:* ${{ github.actor }}"
                  }
                },
                {
                  "type": "actions",
                  "elements": [
                    {
                      "type": "button",
                      "text": {
                        "type": "plain_text",
                        "text": "View Run"
                      },
                      "url": "${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
                    }
                  ]
                }
              ]
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

## Matrix Builds

### Test Across Multiple Versions
```yaml
name: Matrix Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
        python-version: ['3.9', '3.10', '3.11', '3.12']
        exclude:
          # Exclude specific combinations
          - os: macos-latest
            python-version: '3.9'
        include:
          # Add specific combinations
          - os: ubuntu-latest
            python-version: 'pypy-3.10'
            experimental: true

    continue-on-error: ${{ matrix.experimental || false }}

    steps:
      - uses: actions/checkout@v4

      - name: Set up Python ${{ matrix.python-version }}
        uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}
          cache: 'pip'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
          pip install pytest

      - name: Run tests
        run: pytest -v

      - name: Upload results
        uses: actions/upload-artifact@v3
        if: failure()
        with:
          name: test-results-${{ matrix.os }}-${{ matrix.python-version }}
          path: test-results/
```

### Multi-Architecture Builds
```yaml
name: Multi-Arch Build

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        platform:
          - linux/amd64
          - linux/arm64
          - linux/arm/v7

    steps:
      - uses: actions/checkout@v4

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Build for ${{ matrix.platform }}
        uses: docker/build-push-action@v5
        with:
          context: .
          platforms: ${{ matrix.platform }}
          tags: myapp:${{ matrix.platform }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

## Caching Strategies

### Dependency Caching
```yaml
name: Caching Example

on: [push]

jobs:
  python-cache:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'
          cache: 'pip'  # Automatic caching

      - run: pip install -r requirements.txt

  node-cache:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'  # Automatic caching

      - run: npm ci

  custom-cache:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Cache build artifacts
        uses: actions/cache@v3
        with:
          path: |
            ~/.cache/go-build
            ~/go/pkg/mod
          key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}
          restore-keys: |
            ${{ runner.os }}-go-

      - run: go build
```

### Docker Layer Caching
```yaml
name: Docker Cache

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Build with cache
        uses: docker/build-push-action@v5
        with:
          context: .
          cache-from: type=gha
          cache-to: type=gha,mode=max
          tags: myapp:latest
```

## Reusable Workflows

### Callable Workflow
```yaml
# .github/workflows/reusable-test.yml
name: Reusable Test

on:
  workflow_call:
    inputs:
      python-version:
        required: true
        type: string
      coverage-threshold:
        required: false
        type: number
        default: 80
    secrets:
      CODECOV_TOKEN:
        required: true
    outputs:
      coverage:
        description: "Test coverage percentage"
        value: ${{ jobs.test.outputs.coverage }}

jobs:
  test:
    runs-on: ubuntu-latest
    outputs:
      coverage: ${{ steps.coverage.outputs.percentage }}

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with:
          python-version: ${{ inputs.python-version }}

      - run: pip install -r requirements.txt -r requirements-dev.txt

      - name: Run tests
        run: |
          pytest --cov --cov-fail-under=${{ inputs.coverage-threshold }}

      - id: coverage
        run: |
          COVERAGE=$(coverage report | tail -1 | awk '{print $4}' | sed 's/%//')
          echo "percentage=$COVERAGE" >> $GITHUB_OUTPUT
```

### Using Reusable Workflow
```yaml
# .github/workflows/ci.yml
name: CI

on: [push]

jobs:
  test-python-3-11:
    uses: ./.github/workflows/reusable-test.yml
    with:
      python-version: '3.11'
      coverage-threshold: 80
    secrets:
      CODECOV_TOKEN: ${{ secrets.CODECOV_TOKEN }}

  test-python-3-12:
    uses: ./.github/workflows/reusable-test.yml
    with:
      python-version: '3.12'
      coverage-threshold: 85
    secrets:
      CODECOV_TOKEN: ${{ secrets.CODECOV_TOKEN }}
```

## Composite Actions

### Custom Action
```yaml
# .github/actions/setup-environment/action.yml
name: 'Setup Environment'
description: 'Set up Python and install dependencies'

inputs:
  python-version:
    description: 'Python version to use'
    required: true
  install-dev:
    description: 'Install dev dependencies'
    required: false
    default: 'false'

outputs:
  cache-hit:
    description: 'Whether cache was hit'
    value: ${{ steps.cache.outputs.cache-hit }}

runs:
  using: 'composite'
  steps:
    - name: Set up Python
      uses: actions/setup-python@v5
      with:
        python-version: ${{ inputs.python-version }}

    - name: Cache dependencies
      id: cache
      uses: actions/cache@v3
      with:
        path: ~/.cache/pip
        key: pip-${{ runner.os }}-${{ inputs.python-version }}-${{ hashFiles('**/requirements*.txt') }}

    - name: Install dependencies
      shell: bash
      run: |
        pip install -r requirements.txt
        if [ "${{ inputs.install-dev }}" == "true" ]; then
          pip install -r requirements-dev.txt
        fi
```

### Using Custom Action
```yaml
name: Use Custom Action

on: [push]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup environment
        uses: ./.github/actions/setup-environment
        with:
          python-version: '3.11'
          install-dev: 'true'

      - run: pytest
```

## Secrets Management

### Using GitHub Secrets
```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production

    steps:
      - uses: actions/checkout@v4

      - name: Deploy
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
        run: ./deploy.sh
```

### Using Environments
```yaml
name: Multi-Environment Deploy

on:
  push:
    branches: [main, develop]

jobs:
  deploy-staging:
    if: github.ref == 'refs/heads/develop'
    runs-on: ubuntu-latest
    environment:
      name: staging
      url: https://staging.example.com
    steps:
      - run: echo "Deploying to staging"
        env:
          API_KEY: ${{ secrets.API_KEY }}  # Environment-specific secret

  deploy-production:
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://example.com
    steps:
      - run: echo "Deploying to production"
        env:
          API_KEY: ${{ secrets.API_KEY }}  # Different value in production
```

## Advanced Patterns

### Conditional Execution
```yaml
name: Conditional Jobs

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Always runs"

  deploy:
    needs: test
    if: |
      github.event_name == 'push' &&
      github.ref == 'refs/heads/main' &&
      !contains(github.event.head_commit.message, '[skip ci]')
    runs-on: ubuntu-latest
    steps:
      - run: echo "Conditional deployment"
```

### Dynamic Matrix
```yaml
name: Dynamic Matrix

on: [push]

jobs:
  setup:
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.set-matrix.outputs.matrix }}
    steps:
      - id: set-matrix
        run: |
          # Generate matrix from code
          MATRIX=$(cat << EOF
          {
            "include": [
              {"python": "3.9", "django": "3.2"},
              {"python": "3.10", "django": "4.0"},
              {"python": "3.11", "django": "4.1"}
            ]
          }
          EOF
          )
          echo "matrix=$MATRIX" >> $GITHUB_OUTPUT

  test:
    needs: setup
    runs-on: ubuntu-latest
    strategy:
      matrix: ${{ fromJSON(needs.setup.outputs.matrix) }}
    steps:
      - run: echo "Testing Python ${{ matrix.python }} with Django ${{ matrix.django }}"
```

### Monorepo Path Filtering
```yaml
name: Monorepo CI

on:
  push:
    paths:
      - 'services/api/**'
      - 'shared/**'

jobs:
  api-test:
    if: |
      contains(github.event.commits.*.modified, 'services/api') ||
      contains(github.event.commits.*.modified, 'shared')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: cd services/api && npm test
```

### Workflow Artifacts
```yaml
name: Build and Test

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: make build
      - uses: actions/upload-artifact@v3
        with:
          name: build-artifacts
          path: dist/
          retention-days: 5

  test:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/download-artifact@v3
        with:
          name: build-artifacts
          path: dist/
      - run: make test
```

## Performance Optimization

### Job Concurrency
```yaml
name: CI

on: [push, pull_request]

# Cancel in-progress runs for same branch
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Only latest run continues"
```

### Parallel Jobs
```yaml
name: Fast Pipeline

on: [push]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Linting (fast)"

  test:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Testing (parallel with lint)"

  build:
    needs: [lint, test]  # Wait for both
    runs-on: ubuntu-latest
    steps:
      - run: echo "Building"
```

## Best Practices

1. **Use latest action versions** - Pin to major version (v4, not v4.1.0)
2. **Cache dependencies** - Speed up builds with caching
3. **Fail fast** - Set fail-fast: true in matrix
4. **Use environments** - Separate staging/production secrets
5. **Conditional execution** - Skip unnecessary jobs
6. **Reusable workflows** - DRY principle
7. **Security scanning** - Integrate Trivy, CodeQL
8. **Notifications** - Alert team on failures
9. **Artifacts** - Store build outputs, test results
10. **Monitoring** - Track pipeline performance
