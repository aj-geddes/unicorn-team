---
name: security
description: >
  Security-focused development and code review expertise using defense-in-depth
  and attacker's mindset. Use when implementing authentication/authorization,
  handling user input, storing sensitive data, reviewing code for vulnerabilities,
  or deploying to production. Triggers: "security review", "vulnerability",
  "authentication", "authorization", "input validation", "XSS", "SQL injection",
  "secrets", "OWASP", "threat model", "security scan". Covers OWASP Top 10,
  input validation, output encoding, secrets management, and security tooling.
---

# Security: Think Like an Attacker

Security is not a checklist. It's a mindset. Every feature is an attack surface. Every input is malicious until proven otherwise.

## Core Principle

**Defense in Depth + Least Privilege**

Layer multiple security controls. Grant minimum necessary permissions. Assume every layer can fail.

---

## Security Mindset

### Six Critical Questions (Every Feature)

1. **Who can access this?** (Authentication)
2. **Are they allowed to?** (Authorization)
3. **Can they see more than they should?** (Data exposure)
4. **Can they do more than they should?** (Privilege escalation)
5. **Can they break it for others?** (Denial of service)
6. **Will we know if they do?** (Audit logging)

### Think Like an Attacker

**Assets:** User data, business data, system integrity, reputation

**Threat Actors:** Bored teenager, disgruntled user, competitor, nation state, our bugs

**Attack Vectors:** Input manipulation, auth bypass, privilege escalation, data exposure, DoS

**Impact:** Data breach, financial loss, service disruption, legal liability, reputation damage

---

## OWASP Top 10 (Quick Reference)

### 1. Broken Access Control

**Bad:**
```python
@app.route('/user/<user_id>/profile')
def get_profile(user_id):
    # VULNERABLE: No authorization check
    return jsonify(db.get_user(user_id).to_dict())
```

**Good:**
```python
@app.route('/user/<user_id>/profile')
@require_auth
def get_profile(user_id):
    current_user = get_current_user()
    if current_user.id != user_id and not current_user.is_admin:
        abort(403, "Access denied")
    return jsonify(db.get_user(user_id).safe_dict(viewer=current_user))
```

### 2. Cryptographic Failures

**Bad:**
```python
user.password = md5(password)  # WEAK
```

**Good:**
```python
from argon2 import PasswordHasher
user.password_hash = PasswordHasher().hash(password)  # STRONG
```

### 3. Injection

**SQL Injection:**
```python
# BAD: String concatenation
query = f"SELECT * FROM users WHERE id = {user_id}"

# GOOD: Parameterized
query = "SELECT * FROM users WHERE id = ?"
db.execute(query, [user_id])
```

**Command Injection:**
```python
# BAD: shell=True with user input
os.system(f"cat {filename}")

# GOOD: List form, validated input
if not re.match(r'^[a-zA-Z0-9_-]+\.txt$', filename):
    abort(400)
subprocess.run(['cat', filename], timeout=5)
```

**XSS:**
```html
<!-- BAD: Unescaped -->
<div>{{ username }}</div>

<!-- GOOD: Auto-escaped -->
<div>{{ username | escape }}</div>
```

### 4. Insecure Design

**Rate Limiting:**
```python
@limiter.limit("5 per minute")
@app.route('/login', methods=['POST'])
def login():
    # Prevent brute force
```

**Threat Modeling (STRIDE):**
- **S**poofing: Can they impersonate?
- **T**ampering: Can they modify data?
- **R**epudiation: Can they deny actions?
- **I**nformation Disclosure: Can they see secrets?
- **D**enial of Service: Can they break availability?
- **E**levation of Privilege: Can they gain admin access?

### 5. Security Misconfiguration

```python
# BAD: Debug in production
app.run(debug=True)

# GOOD: Environment-aware
app.config['DEBUG'] = os.environ.get('ENV') != 'production'

# Generic errors
@app.errorhandler(500)
def error(e):
    logger.error(f"Error: {e}", exc_info=True)  # Log internally
    return {"error": "Internal server error"}, 500  # Generic response
```

### 6. Vulnerable Components

```bash
# Scan dependencies
pip install safety
safety check

npm audit
npm audit fix
```

### 7. Authentication Failures

```python
import secrets

# Secure session config
app.config['SESSION_COOKIE_SECURE'] = True      # HTTPS only
app.config['SESSION_COOKIE_HTTPONLY'] = True    # No JS access
app.config['SESSION_COOKIE_SAMESITE'] = 'Lax'   # CSRF protection
app.config['PERMANENT_SESSION_LIFETIME'] = 3600 # Timeout

# Crypto-random session IDs
session_id = secrets.token_urlsafe(32)
```

### 8. Data Integrity Failures

```python
# BAD: Pickle (arbitrary code execution)
data = pickle.loads(request.data)

# GOOD: JSON with validation
from jsonschema import validate

data = json.loads(request.data)
validate(instance=data, schema=schema)
```

### 9. Logging Failures

```python
# Log security events
logger.info("api_access", user_id=user.id, ip=request.remote_addr)
logger.warning("failed_login", username=username, ip=request.remote_addr)
logger.error("authorization_failure", user_id=user.id, resource=resource)
```

**Log:** Login attempts, auth failures, admin actions, sensitive data access, config changes

### 10. Server-Side Request Forgery (SSRF)

```python
# BAD: User-controlled URL
response = requests.get(request.args.get('url'))

# GOOD: Allowlist validation
from urllib.parse import urlparse

url = request.args.get('url')
parsed = urlparse(url)

ALLOWED_DOMAINS = ['api.example.com']
if parsed.netloc not in ALLOWED_DOMAINS:
    abort(400, "Invalid URL")

BLOCKED_IPS = ['127.0.0.1', 'localhost', '169.254.169.254']
if parsed.hostname in BLOCKED_IPS:
    abort(400, "Access denied")

response = requests.get(url, timeout=5)
```

---

## Input Validation

**Allowlist over Denylist:**

```python
# BAD: Denylist (easy to bypass)
if username in ['admin', 'root']:
    raise ValueError()

# GOOD: Allowlist (explicit)
if not re.match(r'^[a-zA-Z0-9_]{3,20}$', username):
    raise ValueError("Invalid format")
```

**Layered Validation:**

```python
from pydantic import BaseModel, validator, constr

class UserInput(BaseModel):
    username: constr(min_length=3, max_length=20, regex=r'^[a-zA-Z0-9_]+$')
    email: str
    age: int

    @validator('email')
    def validate_email(cls, v):
        if not re.match(r'^[\w\.-]+@[\w\.-]+\.\w+$', v):
            raise ValueError('Invalid email')
        return v.lower()

    @validator('age')
    def validate_age(cls, v):
        if not (0 <= v <= 150):
            raise ValueError('Age 0-150')
        return v
```

---

## Output Encoding

**Context-Aware:**

```python
from markupsafe import escape
from urllib.parse import quote

# HTML
html = f"<div>{escape(username)}</div>"

# URL
url = f"https://example.com/search?q={quote(term)}"

# JavaScript
js = f"var name = {json.dumps(username)};"

# SQL (parameterized, not escaped)
query = "SELECT * FROM users WHERE name = ?"
db.execute(query, [username])
```

---

## Secrets Management

**Never commit secrets:**

```python
# BAD: Hardcoded
API_KEY = "sk_live_abc123"

# GOOD: Environment
import os
API_KEY = os.environ['API_KEY']

# Verify required
for secret in ['API_KEY', 'DATABASE_URL', 'SECRET_KEY']:
    if secret not in os.environ:
        raise RuntimeError(f"Missing: {secret}")
```

**.env (Never Commit):**
```bash
# .env (add to .gitignore)
API_KEY=sk_live_abc123

# .env.example (commit this)
API_KEY=your_api_key_here
```

**Production: Secret Managers**
```python
# AWS Secrets Manager
import boto3
secret = boto3.client('secretsmanager').get_secret_value(SecretId='myapp/config')

# HashiCorp Vault
import hvac
secret = hvac.Client().secrets.kv.v2.read_secret_version(path='myapp/config')
```

---

## Common Vulnerability Fixes

### Path Traversal

```python
# BAD
with open(f'/var/data/{filename}') as f:  # Attack: ../../etc/passwd

# GOOD
from pathlib import Path
BASE_DIR = Path('/var/data')
file_path = (BASE_DIR / filename).resolve()
if not file_path.is_relative_to(BASE_DIR):
    abort(403)
```

### Mass Assignment

```python
# BAD
user.update(**request.json)  # Attack: {"is_admin": true}

# GOOD
ALLOWED = ['name', 'email', 'bio']
for field in ALLOWED:
    if field in request.json:
        setattr(user, field, request.json[field])
```

### CSRF Protection

```python
from flask_wtf.csrf import CSRFProtect
csrf = CSRFProtect(app)
app.config['SESSION_COOKIE_SAMESITE'] = 'Strict'
```

---

## Security Scanning

### Static Analysis
```bash
# Python
bandit -r src/ -f json -o report.json

# Detects: Hardcoded passwords, SQL injection, weak crypto, shell injection
```

### Dependency Scanning
```bash
pip install safety
safety check

npm audit
```

### Container Scanning
```bash
trivy image myapp:latest
```

### Pre-commit Hook
```bash
#!/bin/bash
# Scan for secrets
if git diff --cached | grep -i 'password\|secret\|api_key'; then
    echo "ERROR: Potential secret"
    exit 1
fi
bandit -r src/ || exit 1
```

---

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

---

## Quick Checklist

**Authentication & Authorization:**
- [ ] Auth required for protected endpoints
- [ ] Authorization checked per resource
- [ ] Secure session management
- [ ] Password hashing (bcrypt/argon2)
- [ ] MFA for sensitive operations

**Input Handling:**
- [ ] All inputs validated
- [ ] Allowlist validation
- [ ] Parameterized queries
- [ ] No shell injection
- [ ] File upload restrictions

**Output Handling:**
- [ ] Context-aware encoding
- [ ] Auto-escaping templates
- [ ] CSP headers
- [ ] No sensitive data in responses
- [ ] Generic error messages

**Secrets & Crypto:**
- [ ] No secrets in code
- [ ] Environment variables
- [ ] Strong encryption (AES-256)
- [ ] TLS everywhere
- [ ] Secure random (secrets module)

**Monitoring:**
- [ ] Security events logged
- [ ] Failed auth logged
- [ ] Suspicious patterns detected
- [ ] Audit trail
- [ ] Alerts configured

**Configuration:**
- [ ] Debug off in production
- [ ] Security headers
- [ ] Default credentials changed
- [ ] Unnecessary features disabled
- [ ] Dependencies updated

---

## Summary

**Key Principles:**

1. **Defense in Depth** - Multiple security layers
2. **Least Privilege** - Minimum necessary permissions
3. **Fail Secure** - Deny by default
4. **Never Trust Input** - Validate everything
5. **Assume Breach** - Monitor and audit
6. **Security is Everyone's Job** - Not just security team

**The 10X Difference:**

- 1X Developer: Treats security as afterthought
- 10X Developer: Builds security in from the start

Security flaws in production cost 30x more than catching them in development. Build it secure the first time.
