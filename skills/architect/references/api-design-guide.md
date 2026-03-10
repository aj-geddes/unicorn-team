# API Design Guide

## API Style Selection

| Style | When | Tradeoff |
|-------|------|----------|
| REST | CRUD-dominant, public APIs, broad client support | Simplicity vs flexibility |
| GraphQL | Complex queries, multiple clients needing different data shapes | Flexibility vs caching complexity |
| gRPC | Internal service-to-service, high performance, streaming | Performance vs browser support |

## REST Design Conventions

### URL Structure
```
GET    /resources              # List (paginated)
POST   /resources              # Create
GET    /resources/{id}         # Read
PUT    /resources/{id}         # Full update
PATCH  /resources/{id}         # Partial update
DELETE /resources/{id}         # Delete
GET    /resources/{id}/subresources  # Nested collection
```

### Versioning Strategies

| Strategy | Example | Pros | Cons |
|----------|---------|------|------|
| URL path | `/v1/users` | Explicit, easy routing | URL pollution |
| Header | `Accept: application/vnd.api.v1+json` | Clean URLs | Hidden, harder to test |
| Query param | `/users?version=1` | Simple | Easy to forget |

**Recommendation**: URL path for public APIs, header for internal.

### Error Response Format (RFC 7807)

```json
{
  "type": "https://api.example.com/errors/validation",
  "title": "Validation Error",
  "status": 400,
  "detail": "The 'email' field is not a valid email address",
  "instance": "/users/signup",
  "errors": [
    {
      "field": "email",
      "message": "Invalid email format",
      "value": "not-an-email"
    }
  ]
}
```

### Pagination

**Cursor-based** (recommended for large datasets):
```json
{
  "data": [...],
  "meta": {
    "has_more": true,
    "next_cursor": "eyJpZCI6MTAwfQ=="
  }
}
```

**Offset-based** (simpler, acceptable for small datasets):
```json
{
  "data": [...],
  "meta": {
    "total": 1000,
    "page": 2,
    "page_size": 20,
    "total_pages": 50
  }
}
```

### Rate Limiting Headers
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1609459200
Retry-After: 30
```

## OpenAPI Spec Template

```yaml
openapi: 3.0.0
info:
  title: {Service} API
  version: 1.0.0
  description: |
    {Description}

    **Design decisions**:
    - {Decision 1 with rationale}
    - {Decision 2 with rationale}

paths:
  /resources:
    get:
      summary: List resources
      operationId: listResources
      parameters:
        - name: page
          in: query
          schema:
            type: integer
            default: 1
        - name: page_size
          in: query
          schema:
            type: integer
            default: 20
            maximum: 100
      responses:
        '200':
          description: Success
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/Resource'
                  meta:
                    $ref: '#/components/schemas/PaginationMeta'
        '400':
          $ref: '#/components/responses/BadRequest'
        '429':
          $ref: '#/components/responses/RateLimited'

components:
  schemas:
    Resource:
      type: object
      required: [id, created_at]
      properties:
        id:
          type: string
          format: uuid
        created_at:
          type: string
          format: date-time

    PaginationMeta:
      type: object
      properties:
        total:
          type: integer
        page:
          type: integer
        page_size:
          type: integer
        total_pages:
          type: integer

  responses:
    BadRequest:
      description: Invalid request
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'

    RateLimited:
      description: Rate limit exceeded
      headers:
        X-RateLimit-Limit:
          schema:
            type: integer
        X-RateLimit-Remaining:
          schema:
            type: integer
        X-RateLimit-Reset:
          schema:
            type: integer
```

## API Design Principles

### Idempotency
- GET, PUT, DELETE: always idempotent
- POST: use idempotency keys for critical operations
- Header: `Idempotency-Key: {uuid}`

### Authentication
| Method | When |
|--------|------|
| API Key | Server-to-server, simple integrations |
| JWT Bearer | User-facing, stateless, microservices |
| OAuth2 | Third-party access, delegated auth |
| mTLS | High-security internal services |

### Content Negotiation
- Request: `Content-Type: application/json`
- Response: `Accept: application/json`
- Always return `Content-Type` header

### HATEOAS (Optional)
Include links for discoverability in public APIs:
```json
{
  "data": { "id": "123", "name": "Widget" },
  "links": {
    "self": "/products/123",
    "category": "/categories/electronics",
    "reviews": "/products/123/reviews"
  }
}
```
