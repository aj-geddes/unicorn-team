# OWASP Top 10 Quick Reference

## 1. Broken Access Control

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

## 2. Cryptographic Failures

**Bad:**
```python
user.password = md5(password)  # WEAK
```

**Good:**
```python
from argon2 import PasswordHasher
user.password_hash = PasswordHasher().hash(password)  # STRONG
```

## 3. Injection

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

## 4. Insecure Design

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

## 5. Security Misconfiguration

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

## 6. Vulnerable Components

```bash
# Scan dependencies
pip install safety --break-system-packages
safety check

npm audit
npm audit fix
```

## 7. Authentication Failures

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

## 8. Data Integrity Failures

```python
# BAD: Pickle (arbitrary code execution)
data = pickle.loads(request.data)

# GOOD: JSON with validation
from jsonschema import validate

data = json.loads(request.data)
validate(instance=data, schema=schema)
```

## 9. Logging Failures

```python
# Log security events
logger.info("api_access", user_id=user.id, ip=request.remote_addr)
logger.warning("failed_login", username=username, ip=request.remote_addr)
logger.error("authorization_failure", user_id=user.id, resource=resource)
```

**Log:** Login attempts, auth failures, admin actions, sensitive data access, config changes

## 10. Server-Side Request Forgery (SSRF)

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
