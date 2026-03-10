---
name: security
description: >-
  Guides secure development using defense-in-depth and attacker's mindset.
  ALWAYS trigger on "security review", "vulnerability", "authentication",
  "authorization", "input validation", "XSS", "SQL injection", "CSRF",
  "secrets management", "OWASP", "threat model", "security scan", "path
  traversal", "mass assignment", "privilege escalation", "security headers",
  "bandit", "dependency audit", "hardening". Use when implementing auth,
  handling user input, storing secrets, reviewing code for vulnerabilities,
  or preparing for production deployment. Different from devops skill which
  covers infrastructure; this covers application-level security patterns.
---
<!-- Last reviewed: 2026-03 -->

# Security: Think Like an Attacker

## Core Principle

**Defense in Depth + Least Privilege.** Layer multiple controls. Grant minimum permissions. Assume every layer can fail.

## Security Mindset

### Six Questions (Every Feature)

1. **Who can access this?** (Authentication)
2. **Are they allowed to?** (Authorization)
3. **Can they see more than they should?** (Data exposure)
4. **Can they do more than they should?** (Privilege escalation)
5. **Can they break it for others?** (Denial of service)
6. **Will we know if they do?** (Audit logging)

---

## OWASP Top 10 (Quick Reference)

| # | Vulnerability | Key Defense |
|---|--------------|-------------|
| 1 | Broken Access Control | Auth check per resource, deny by default |
| 2 | Cryptographic Failures | Argon2/bcrypt, never MD5/SHA1 for passwords |
| 3 | Injection (SQL, XSS, Command) | Parameterized queries, escaping, allowlists |
| 4 | Insecure Design | Rate limiting, STRIDE threat modeling |
| 5 | Security Misconfiguration | Debug off in prod, generic error messages |
| 6 | Vulnerable Components | `safety check` / `npm audit` |
| 7 | Authentication Failures | Secure cookies, crypto-random session IDs |
| 8 | Data Integrity Failures | JSON with validation, never pickle |
| 9 | Logging Failures | Log security events, failed auth, admin actions |
| 10 | SSRF | URL allowlist, block internal IPs |

See `references/owasp-top-10.md` for detailed bad/good code examples per vulnerability.

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

html = f"<div>{escape(username)}</div>"          # HTML context
url = f"https://example.com/search?q={quote(term)}"  # URL context
js = f"var name = {json.dumps(username)};"        # JS context
db.execute("SELECT * FROM users WHERE name = ?", [username])  # SQL: parameterize
```

---

## Secrets Management

```python
# BAD: Hardcoded
API_KEY = "sk_live_abc123"

# GOOD: Environment with verification
import os
for secret in ['API_KEY', 'DATABASE_URL', 'SECRET_KEY']:
    if secret not in os.environ:
        raise RuntimeError(f"Missing: {secret}")
```

```bash
# .env (add to .gitignore, NEVER commit)
API_KEY=sk_live_abc123

# .env.example (commit this)
API_KEY=your_api_key_here
```

**Production:** Use AWS Secrets Manager, HashiCorp Vault, or platform-native secret stores.

---

## Common Vulnerability Fixes

### Path Traversal

```python
from pathlib import Path
BASE_DIR = Path('/var/data')
file_path = (BASE_DIR / filename).resolve()
if not file_path.is_relative_to(BASE_DIR):
    abort(403)
```

### Mass Assignment

```python
# BAD: user.update(**request.json)  # Attack: {"is_admin": true}
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

## Security Tooling

```bash
bandit -r src/ -f json -o report.json   # Static analysis
safety check                            # Python dependency scan
npm audit                               # Node dependency scan
trivy image myapp:latest                # Container scan
```

See `references/security-tooling.md` for pre-commit hooks, security headers config, and CI/CD integration.

---

## Quick Checklist

**Auth:**
- [ ] Auth required for protected endpoints
- [ ] Authorization checked per resource
- [ ] Password hashing (bcrypt/argon2)
- [ ] Secure session management
- [ ] MFA for sensitive operations

**Input/Output:**
- [ ] All inputs validated (allowlist)
- [ ] Parameterized queries
- [ ] Context-aware output encoding
- [ ] CSP headers set
- [ ] Generic error messages (no stack traces)

**Secrets & Crypto:**
- [ ] No secrets in code or git
- [ ] Environment variables or secret manager
- [ ] TLS everywhere
- [ ] `secrets` module for random tokens

**Monitoring:**
- [ ] Security events logged
- [ ] Failed auth attempts tracked
- [ ] Audit trail for admin actions
- [ ] Alerts configured

**Config:**
- [ ] Debug off in production
- [ ] Security headers (HSTS, CSP, X-Frame-Options)
- [ ] Default credentials changed
- [ ] Dependencies updated
