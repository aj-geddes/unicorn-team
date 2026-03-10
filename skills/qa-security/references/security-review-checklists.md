# Security Review Checklists

Detailed security review procedures including STRIDE threat modeling, attack scenario enumeration, and defense-in-depth verification.

## STRIDE Threat Model

For every feature, perform threat modeling using STRIDE:

| Threat | Question | Example | Mitigation |
|--------|----------|---------|------------|
| **S**poofing | Can someone impersonate a user/system? | Impersonating another user | Strong authentication, MFA |
| **T**ampering | Can someone modify data in transit/at rest? | Modifying data in transit | HTTPS, message signing, integrity checks |
| **R**epudiation | Can someone deny actions they took? | Denying actions taken | Audit logging, digital signatures |
| **I**nformation Disclosure | Can someone access unauthorized data? | Exposing sensitive data | Encryption, access controls, data masking |
| **D**enial of Service | Can someone crash or slow the system? | Flooding with requests | Rate limiting, input validation, circuit breakers |
| **E**levation of Privilege | Can someone gain unauthorized access? | Gaining admin access | Least privilege, authorization checks, RBAC |

## Threat Modeling Steps

### Step 1: Identify Assets

What are we protecting?

- **Data**: User credentials, PII, financial data, business logic
- **Functionality**: Admin operations, payment processing, data access
- **Reputation**: Company brand, user trust

### Step 2: Map Trust Boundaries

Where does untrusted data enter the system?

- User input (forms, APIs, uploads)
- External APIs (third-party services)
- Database (compromised or malicious data)
- Configuration files (if user-editable)

### Step 3: Enumerate Threats

For each trust boundary, apply STRIDE:

```
Trust Boundary: Login Endpoint (/api/auth/login)
├── Spoofing: Brute force, credential stuffing
├── Tampering: MITM, session hijacking
├── Repudiation: Login without audit trail
├── Info Disclosure: Username enumeration, timing attacks
├── DoS: Brute force causing account lockout
└── Elevation: Privilege escalation via JWT manipulation
```

### Step 4: Attack Scenarios

Brainstorm how an attacker would exploit each threat:

```python
# Example: Login endpoint attack scenarios
attack_scenarios = [
    "Brute force password guessing -> Implement rate limiting + account lockout",
    "SQL injection in username field -> Use parameterized queries",
    "Session fixation -> Regenerate session ID after login",
    "Timing attack on password check -> Use constant-time comparison",
    "Credential stuffing with leaked passwords -> Check against haveibeenpwned API",
    "Enumerate valid usernames -> Generic error messages ('invalid credentials')",
]
```

### Step 5: Risk Assessment

For each threat, assess:

| Factor | Levels | Criteria |
|--------|--------|----------|
| Likelihood | Low / Medium / High | How easy to exploit? Required skill level? |
| Impact | Low / Medium / High | Data loss? Financial? Reputational? |
| Risk | Likelihood x Impact | LOW / MEDIUM / HIGH / CRITICAL |
| Action | Required if MEDIUM+ | Must document mitigation |

### Step 6: Defense in Depth

Verify multiple layers of protection:

```
Layer 1: Network     -> Firewall, WAF, DDoS protection
Layer 2: Application -> Input validation, authentication, authorization
Layer 3: Data        -> Encryption at rest, encryption in transit, access controls
Layer 4: Monitoring  -> Logging, alerting, incident response
```

If an attacker bypasses one layer, the next should stop them.

## Input Validation Checklist

- [ ] All user input validated (type, length, format, range)
- [ ] Validation happens on server side (never trust client)
- [ ] Allowlists preferred over denylists
- [ ] Input sanitized before use in:
  - [ ] SQL queries (parameterized queries)
  - [ ] HTML output (output encoding)
  - [ ] Shell commands (avoid; if unavoidable, strict allowlist)
  - [ ] LDAP queries (escape special characters)
  - [ ] File paths (no path traversal)

## Output Encoding Checklist

- [ ] All dynamic content encoded for context (HTML, JavaScript, URL, SQL)
- [ ] No direct string interpolation into queries
- [ ] Content-Security-Policy headers set (if web)
- [ ] CORS configured correctly (not `*` in production)
- [ ] X-Content-Type-Options: nosniff
- [ ] X-Frame-Options: DENY or SAMEORIGIN

## Secrets Management Checklist

- [ ] No hardcoded secrets (API keys, passwords, tokens)
- [ ] No secrets in logs or error messages
- [ ] Secrets loaded from environment or secure vault
- [ ] No secrets in version control (check git history too)
- [ ] Secrets rotated on regular schedule
- [ ] Minimum privilege for each secret

## Authentication & Authorization Checklist

- [ ] Authentication required for protected resources
- [ ] Authorization checked on every request (not just UI)
- [ ] No privilege escalation possible (horizontal or vertical)
- [ ] Session management secure:
  - [ ] Session timeout configured
  - [ ] Session ID rotated after login
  - [ ] Secure, HttpOnly, SameSite cookies
- [ ] Password storage uses bcrypt/argon2 (not MD5/SHA)
- [ ] Rate limiting on auth endpoints

## Data Protection Checklist

- [ ] Sensitive data encrypted at rest
- [ ] Sensitive data encrypted in transit (TLS 1.2+)
- [ ] PII handling compliant with regulations (GDPR, CCPA)
- [ ] Data minimization (only collect what is needed)
- [ ] Data retention policies enforced
- [ ] Secure deletion when data no longer needed
