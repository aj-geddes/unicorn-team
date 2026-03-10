# Docker Complete Reference

Comprehensive Docker guide covering Dockerfiles, multi-stage builds, Compose, optimization, and best practices.

## Multi-Stage Build Patterns

### Go Application with Minimal Image
```dockerfile
# Build stage
FROM golang:1.21-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates

WORKDIR /app

# Cache dependencies
COPY go.mod go.sum ./
RUN go mod download

# Build
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s" \
    -o /server \
    ./cmd/server

# Runtime stage - distroless for security
FROM gcr.io/distroless/static-debian11

# Copy certificates
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy binary
COPY --from=builder /server /server

# Non-root user
USER nonroot:nonroot

EXPOSE 8080

ENTRYPOINT ["/server"]
```

Result: 10MB vs 300MB with golang base image

### Python Application with Dependencies
```dockerfile
# Build stage
FROM python:3.11-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Runtime stage
FROM python:3.11-slim

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1000 appuser

WORKDIR /app

# Copy Python packages from builder
COPY --from=builder /root/.local /home/appuser/.local

# Copy application
COPY --chown=appuser:appuser . .

# Update PATH
ENV PATH=/home/appuser/.local/bin:$PATH

USER appuser

EXPOSE 8000

CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:8000", "--workers", "4"]
```

### Node.js with Build Artifacts
```dockerfile
# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Cache dependencies
COPY package*.json ./
RUN npm ci

# Build application
COPY . .
RUN npm run build

# Production dependencies only
RUN npm ci --only=production

# Runtime stage
FROM node:20-alpine

# Create non-root user
RUN addgroup -g 1000 appgroup && \
    adduser -D -u 1000 -G appgroup appuser

WORKDIR /app

# Copy production dependencies
COPY --from=builder --chown=appuser:appuser /app/node_modules ./node_modules

# Copy build artifacts
COPY --from=builder --chown=appuser:appuser /app/dist ./dist
COPY --from=builder --chown=appuser:appuser /app/package.json ./

USER appuser

EXPOSE 3000

CMD ["node", "dist/server.js"]
```

### Rust with Cargo Cache
```dockerfile
# Chef stage for caching dependencies
FROM rust:1.75-alpine AS chef
RUN apk add --no-cache musl-dev
RUN cargo install cargo-chef
WORKDIR /app

# Planner stage
FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

# Builder stage
FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
# Build dependencies (cached layer)
RUN cargo chef cook --release --recipe-path recipe.json
# Build application
COPY . .
RUN cargo build --release

# Runtime stage
FROM alpine:latest
RUN apk add --no-cache libgcc
COPY --from=builder /app/target/release/myapp /usr/local/bin/myapp
USER nobody
ENTRYPOINT ["myapp"]
```

## Dockerfile Optimization Techniques

### Layer Caching Strategy
```dockerfile
# Bad - rebuilds everything on any change
FROM python:3.11-slim
COPY . .
RUN pip install -r requirements.txt
CMD ["python", "app.py"]

# Good - caches dependencies
FROM python:3.11-slim
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "app.py"]
```

### Minimize Layer Size
```dockerfile
# Bad - creates large layers
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y git
RUN apt-get clean

# Good - single layer, cleanup in same command
RUN apt-get update && apt-get install -y \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*
```

### Use .dockerignore
```
# .dockerignore
.git
.gitignore
.env
.env.*
node_modules
npm-debug.log
coverage
.pytest_cache
__pycache__
*.pyc
*.pyo
*.pyd
.Python
.venv
venv/
*.md
!README.md
Dockerfile*
docker-compose*
.dockerignore
```

### BuildKit Features
```dockerfile
# syntax=docker/dockerfile:1

# Enable BuildKit cache mounts
FROM python:3.11-slim

WORKDIR /app

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt

# Secret mounting (never stored in layer)
RUN --mount=type=secret,id=github_token \
    GITHUB_TOKEN=$(cat /run/secrets/github_token) \
    pip install git+https://${GITHUB_TOKEN}@github.com/private/repo.git
```

Build with secrets:
```bash
docker buildx build --secret id=github_token,src=token.txt -t myapp .
```

## Docker Compose Advanced Patterns

### Development Environment with Hot Reload
```yaml
version: '3.9'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.dev
      target: development
    ports:
      - "3000:3000"
      - "9229:9229"  # Node.js debugger
    volumes:
      - .:/app
      - /app/node_modules  # Prevent overwrite
      - /app/.next         # Persist build cache
    environment:
      - NODE_ENV=development
      - DATABASE_URL=postgresql://user:pass@db:5432/myapp
      - REDIS_URL=redis://redis:6379
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    networks:
      - backend
    command: npm run dev

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: myapp
    volumes:
      - db-data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user"]
      interval: 5s
      timeout: 3s
      retries: 5
      start_period: 10s
    networks:
      - backend

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5
    networks:
      - backend

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - app
    networks:
      - backend
      - frontend

volumes:
  db-data:
  redis-data:

networks:
  backend:
  frontend:
```

### Testing Override
```yaml
# docker-compose.test.yml
version: '3.9'

services:
  app:
    command: npm test
    environment:
      - NODE_ENV=test
      - DATABASE_URL=postgresql://user:pass@db:5432/myapp_test
    volumes:
      - ./coverage:/app/coverage

  db:
    environment:
      POSTGRES_DB: myapp_test
```

Run tests:
```bash
docker-compose -f docker-compose.yml -f docker-compose.test.yml up \
  --abort-on-container-exit \
  --exit-code-from app
```

### Production Configuration
```yaml
# docker-compose.prod.yml
version: '3.9'

services:
  app:
    image: ghcr.io/org/myapp:${VERSION:-latest}
    restart: unless-stopped
    environment:
      - NODE_ENV=production
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  db:
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
```

### Microservices Stack
```yaml
version: '3.9'

x-logging: &default-logging
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"

services:
  api-gateway:
    build: ./services/gateway
    ports:
      - "80:8080"
    environment:
      - SERVICE_AUTH_URL=http://auth:8080
      - SERVICE_USER_URL=http://users:8080
      - SERVICE_ORDER_URL=http://orders:8080
    depends_on:
      - auth
      - users
      - orders
    logging: *default-logging

  auth:
    build: ./services/auth
    environment:
      - DATABASE_URL=postgresql://postgres:pass@postgres:5432/auth
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - postgres
      - redis
    logging: *default-logging

  users:
    build: ./services/users
    environment:
      - DATABASE_URL=postgresql://postgres:pass@postgres:5432/users
      - MESSAGE_QUEUE_URL=amqp://rabbitmq:5672
    depends_on:
      - postgres
      - rabbitmq
    logging: *default-logging

  orders:
    build: ./services/orders
    environment:
      - DATABASE_URL=postgresql://postgres:pass@postgres:5432/orders
      - MESSAGE_QUEUE_URL=amqp://rabbitmq:5672
    depends_on:
      - postgres
      - rabbitmq
    logging: *default-logging

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_PASSWORD: pass
    volumes:
      - postgres-data:/var/lib/postgresql/data
    logging: *default-logging

  redis:
    image: redis:7-alpine
    volumes:
      - redis-data:/data
    logging: *default-logging

  rabbitmq:
    image: rabbitmq:3-management-alpine
    ports:
      - "15672:15672"  # Management UI
    volumes:
      - rabbitmq-data:/var/lib/rabbitmq
    logging: *default-logging

volumes:
  postgres-data:
  redis-data:
  rabbitmq-data:
```

## Docker Security Hardening

### Non-Root User Pattern
```dockerfile
FROM python:3.11-slim

# Create user with specific UID/GID
RUN groupadd -r -g 1000 appgroup && \
    useradd -r -u 1000 -g appgroup -m -s /sbin/nologin appuser

WORKDIR /app

# Install as root
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Change ownership
COPY --chown=appuser:appgroup . .

# Switch to non-root
USER appuser

CMD ["python", "app.py"]
```

### Read-Only Root Filesystem
```dockerfile
FROM node:20-alpine

RUN adduser -D -u 1000 appuser

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy application
COPY --chown=appuser:appuser . .

# Create writable directories
RUN mkdir -p /tmp/app-cache /tmp/app-logs && \
    chown appuser:appuser /tmp/app-cache /tmp/app-logs

USER appuser

# Run with read-only root filesystem
# Mount volumes for writable areas
CMD ["node", "server.js"]
```

Run with:
```bash
docker run --read-only \
  -v /tmp/app-cache:/tmp/app-cache \
  -v /tmp/app-logs:/tmp/app-logs \
  myapp:latest
```

### Minimal Base Images Comparison
```dockerfile
# Comparison of base image sizes

# 1. Full Debian (largest, most compatibility)
FROM python:3.11
# Size: ~900MB

# 2. Slim variant (good balance)
FROM python:3.11-slim
# Size: ~120MB

# 3. Alpine (smallest, may have compatibility issues)
FROM python:3.11-alpine
# Size: ~50MB

# 4. Distroless (no shell, most secure)
FROM gcr.io/distroless/python3-debian11
# Size: ~60MB
# No shell, only Python runtime
```

### Health Check in Dockerfile
```dockerfile
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

USER node

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD node healthcheck.js

CMD ["node", "server.js"]
```

healthcheck.js:
```javascript
const http = require('http');

const options = {
  host: 'localhost',
  port: 3000,
  path: '/health',
  timeout: 2000
};

const request = http.request(options, (res) => {
  process.exit(res.statusCode === 200 ? 0 : 1);
});

request.on('error', () => process.exit(1));
request.end();
```

## Image Optimization Checklist

- [ ] Use multi-stage builds
- [ ] Specific base image tags (never `:latest`)
- [ ] Minimal base image (alpine, distroless)
- [ ] Layer caching optimized (dependencies first)
- [ ] Combined RUN commands
- [ ] Cleanup in same layer (`rm -rf`, `apt-get clean`)
- [ ] .dockerignore configured
- [ ] Non-root user
- [ ] Read-only root filesystem (when possible)
- [ ] Health check defined
- [ ] Metadata labels added
- [ ] No secrets in layers
- [ ] Image size < 200MB (target)

## Docker BuildKit Advanced Features

### Parallel Builds
```dockerfile
# syntax=docker/dockerfile:1

FROM golang:1.21-alpine AS base
WORKDIR /app

# Build stage 1
FROM base AS service1
COPY service1/ .
RUN go build -o /service1 .

# Build stage 2 (parallel)
FROM base AS service2
COPY service2/ .
RUN go build -o /service2 .

# Combine
FROM alpine:latest
COPY --from=service1 /service1 /usr/local/bin/
COPY --from=service2 /service2 /usr/local/bin/
```

### Conditional Stages
```dockerfile
# syntax=docker/dockerfile:1

FROM python:3.11-slim AS base

# Development dependencies
FROM base AS dev-deps
RUN pip install pytest black mypy

# Development image
FROM dev-deps AS development
COPY . .
CMD ["python", "-m", "pytest"]

# Production dependencies
FROM base AS prod-deps
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Production image
FROM prod-deps AS production
COPY . .
CMD ["gunicorn", "app:app"]
```

Build specific target:
```bash
docker build --target development -t myapp:dev .
docker build --target production -t myapp:prod .
```

### Cross-Platform Builds
```bash
# Create builder
docker buildx create --name multiarch --use

# Build for multiple platforms
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -t ghcr.io/org/myapp:latest \
  --push \
  .
```

## Docker Commands Reference

### Build
```bash
# Build with tag
docker build -t myapp:v1.0.0 .

# Build with build args
docker build --build-arg VERSION=1.0.0 -t myapp:v1.0.0 .

# Build specific target
docker build --target production -t myapp:prod .

# Build with no cache
docker build --no-cache -t myapp:latest .

# View build history
docker history myapp:latest
```

### Run
```bash
# Basic run
docker run -d --name myapp -p 8080:8080 myapp:latest

# With environment variables
docker run -e DATABASE_URL=postgres://... myapp:latest

# With volume mount
docker run -v $(pwd)/data:/data myapp:latest

# With resource limits
docker run --cpus=0.5 --memory=512m myapp:latest

# With read-only filesystem
docker run --read-only myapp:latest

# With security options
docker run --security-opt=no-new-privileges:true myapp:latest
```

### Manage
```bash
# List containers
docker ps -a

# View logs
docker logs -f --tail=100 container_id

# Execute command
docker exec -it container_id /bin/sh

# Inspect
docker inspect container_id

# Stats
docker stats container_id

# Stop/Start
docker stop container_id
docker start container_id

# Remove
docker rm -f container_id
```

### Images
```bash
# List images
docker images

# Remove image
docker rmi image_id

# Prune unused images
docker image prune -a

# Tag image
docker tag myapp:latest ghcr.io/org/myapp:v1.0.0

# Push to registry
docker push ghcr.io/org/myapp:v1.0.0

# Pull from registry
docker pull ghcr.io/org/myapp:v1.0.0

# Save/Load
docker save myapp:latest -o myapp.tar
docker load -i myapp.tar
```

### System
```bash
# View disk usage
docker system df

# Prune everything
docker system prune -a --volumes

# View system info
docker info
```

## Best Practices Summary

1. **Build Time**
   - Use multi-stage builds
   - Order Dockerfile for layer caching
   - Use .dockerignore
   - Minimize layer count

2. **Runtime**
   - Run as non-root user
   - Use minimal base images
   - Set resource limits
   - Define health checks

3. **Security**
   - Scan images for vulnerabilities
   - No secrets in images
   - Read-only root filesystem
   - Drop capabilities

4. **Maintenance**
   - Tag images semantically
   - Regular base image updates
   - Clean up unused resources
   - Monitor image sizes
