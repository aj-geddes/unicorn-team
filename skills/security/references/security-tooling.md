# Security Tooling

## Static Analysis

```bash
# Python
bandit -r src/ -f json -o report.json

# Detects: Hardcoded passwords, SQL injection, weak crypto, shell injection
```

## Dependency Scanning

```bash
pip install safety --break-system-packages
safety check

npm audit
```

## Container Scanning

```bash
trivy image myapp:latest
```

## Pre-commit Hook

```bash
#!/bin/bash
# Scan for secrets
if git diff --cached | grep -i 'password\|secret\|api_key'; then
    echo "ERROR: Potential secret"
    exit 1
fi
bandit -r src/ || exit 1
```

## Security Headers

```python
@app.after_request
def security_headers(response):
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['X-XSS-Protection'] = '1; mode=block'
    response.headers['Strict-Transport-Security'] = 'max-age=31536000'
    response.headers['Content-Security-Policy'] = "default-src 'self'"
    return response
```
