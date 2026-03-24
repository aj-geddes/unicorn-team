# Error Handling in Go

Go treats errors as values, not exceptions. This makes error paths explicit,
visible, and composable.

## Error Wrapping

```go
import (
    "errors"
    "fmt"
)

// Wrap with context using %w (preserves error chain)
func LoadUser(id string) (*User, error) {
    row, err := db.QueryRow("SELECT * FROM users WHERE id = $1", id)
    if err != nil {
        return nil, fmt.Errorf("loading user %s: %w", id, err)
    }

    var user User
    if err := row.Scan(&user.ID, &user.Name, &user.Email); err != nil {
        return nil, fmt.Errorf("scanning user %s: %w", id, err)
    }
    return &user, nil
}

// %v wraps WITHOUT preserving the chain (use when you want to hide internals)
return nil, fmt.Errorf("operation failed: %v", err)

// Multi-wrapping (Go 1.20+) -- join multiple errors
err := fmt.Errorf("failed: %w and %w", err1, err2)
// Both errors.Is(err, err1) and errors.Is(err, err2) return true
```

## Sentinel Errors

```go
// Package-level sentinel errors for callers to check
var (
    ErrNotFound     = errors.New("not found")
    ErrConflict     = errors.New("conflict")
    ErrUnauthorized = errors.New("unauthorized")
    ErrRateLimited  = errors.New("rate limited")
)

// Return sentinels from functions
func GetUser(id string) (*User, error) {
    user, ok := users[id]
    if !ok {
        return nil, ErrNotFound
    }
    return user, nil
}

// Callers check with errors.Is (works through wrapping)
user, err := GetUser(id)
if errors.Is(err, ErrNotFound) {
    http.Error(w, "user not found", http.StatusNotFound)
    return
}
if err != nil {
    http.Error(w, "internal error", http.StatusInternalServerError)
    return
}
```

## Custom Error Types

```go
// Custom error with structured data
type ValidationError struct {
    Field   string
    Value   any
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation failed on %s: %s (got %v)", e.Field, e.Message, e.Value)
}

// Wrappable custom error
type QueryError struct {
    Query string
    Err   error
}

func (e *QueryError) Error() string {
    return fmt.Sprintf("query %q: %v", e.Query, e.Err)
}

func (e *QueryError) Unwrap() error {
    return e.Err
}

// Multi-error (Go 1.20+)
type MultiError struct {
    Errors []error
}

func (e *MultiError) Error() string {
    msgs := make([]string, len(e.Errors))
    for i, err := range e.Errors {
        msgs[i] = err.Error()
    }
    return strings.Join(msgs, "; ")
}

func (e *MultiError) Unwrap() []error {
    return e.Errors
}
```

## errors.Is and errors.As

```go
// errors.Is: check if any error in chain matches a target value
if errors.Is(err, ErrNotFound) {
    // true even if err was wrapped: fmt.Errorf("...: %w", ErrNotFound)
}

if errors.Is(err, context.DeadlineExceeded) {
    // operation timed out
}

// errors.As: extract a specific error type from the chain
var ve *ValidationError
if errors.As(err, &ve) {
    fmt.Printf("field %s: %s\n", ve.Field, ve.Message)
}

var pathErr *os.PathError
if errors.As(err, &pathErr) {
    fmt.Printf("file operation failed on %s: %v\n", pathErr.Path, pathErr.Err)
}

// Custom Is/As behavior
type NotFoundError struct {
    Resource string
    ID       string
}

func (e *NotFoundError) Error() string {
    return fmt.Sprintf("%s %s not found", e.Resource, e.ID)
}

// Make errors.Is(err, ErrNotFound) return true for NotFoundError
func (e *NotFoundError) Is(target error) bool {
    return target == ErrNotFound
}
```

## Panic and Recover

```go
// Panic: truly unrecoverable situations ONLY
// - Programmer error (index out of bounds, nil dereference)
// - Invariant violation that means the program is corrupt
// - NEVER use for expected errors (file not found, bad input, network failure)

// Recover: catch panics at boundary layers
func SafeHandler(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        defer func() {
            if rec := recover(); rec != nil {
                // Log stack trace
                stack := debug.Stack()
                log.Error("panic recovered",
                    "error", rec,
                    "stack", string(stack),
                    "path", r.URL.Path,
                )
                http.Error(w, "internal server error", http.StatusInternalServerError)
            }
        }()
        next.ServeHTTP(w, r)
    })
}

// MustX pattern: panic on error for initialization-only code
func MustCompile(pattern string) *regexp.Regexp {
    re, err := regexp.Compile(pattern)
    if err != nil {
        panic(fmt.Sprintf("invalid regex %q: %v", pattern, err))
    }
    return re
}

// Only use Must* at package init time, never in request handlers
var emailRegex = regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+$`)
```

## Error Handling Strategies

### Strategy 1: Propagate with context

The most common pattern. Add context at each layer.

```go
func (s *Service) CreateOrder(ctx context.Context, req OrderRequest) (*Order, error) {
    user, err := s.users.Get(ctx, req.UserID)
    if err != nil {
        return nil, fmt.Errorf("getting user for order: %w", err)
    }

    if err := s.inventory.Reserve(ctx, req.Items); err != nil {
        return nil, fmt.Errorf("reserving inventory: %w", err)
    }

    order, err := s.orders.Create(ctx, user, req.Items)
    if err != nil {
        return nil, fmt.Errorf("creating order: %w", err)
    }

    return order, nil
}
```

### Strategy 2: Handle and recover

When you can meaningfully handle the error.

```go
func (s *Service) GetUserWithFallback(ctx context.Context, id string) (*User, error) {
    user, err := s.cache.Get(ctx, id)
    if err == nil {
        return user, nil
    }
    // Cache miss or error -- fall back to database
    log.Warn("cache lookup failed, falling back to DB", "error", err)

    user, err = s.db.GetUser(ctx, id)
    if err != nil {
        return nil, fmt.Errorf("getting user %s: %w", id, err)
    }

    // Populate cache on success (best effort)
    if cacheErr := s.cache.Set(ctx, id, user); cacheErr != nil {
        log.Warn("failed to populate cache", "error", cacheErr)
    }

    return user, nil
}
```

### Strategy 3: Translate at boundaries

Convert internal errors to API-appropriate responses at the HTTP/gRPC boundary.

```go
func (h *Handler) GetUser(w http.ResponseWriter, r *http.Request) {
    id := chi.URLParam(r, "id")

    user, err := h.service.GetUser(r.Context(), id)
    if err != nil {
        switch {
        case errors.Is(err, ErrNotFound):
            writeJSON(w, http.StatusNotFound, ErrorResponse{
                Code:    "NOT_FOUND",
                Message: "User not found",
            })
        case errors.Is(err, ErrForbidden):
            writeJSON(w, http.StatusForbidden, ErrorResponse{
                Code:    "FORBIDDEN",
                Message: "Access denied",
            })
        default:
            log.Error("unexpected error", "error", err, "user_id", id)
            writeJSON(w, http.StatusInternalServerError, ErrorResponse{
                Code:    "INTERNAL",
                Message: "An unexpected error occurred",
            })
        }
        return
    }

    writeJSON(w, http.StatusOK, user)
}
```

### Strategy 4: Collect errors

When processing a batch and you want all errors, not just the first.

```go
func ValidateUser(u User) error {
    var errs []error

    if u.Name == "" {
        errs = append(errs, &ValidationError{Field: "name", Message: "required"})
    }
    if !strings.Contains(u.Email, "@") {
        errs = append(errs, &ValidationError{Field: "email", Message: "invalid format"})
    }
    if u.Age < 0 || u.Age > 150 {
        errs = append(errs, &ValidationError{Field: "age", Message: "out of range"})
    }

    return errors.Join(errs...)  // nil if slice is empty
}
```

## Error Handling in Goroutines

```go
// Goroutine errors must be communicated via channels or errgroup

// Channel approach
errCh := make(chan error, 1)
go func() {
    errCh <- riskyOperation()
}()

if err := <-errCh; err != nil {
    // handle
}

// errgroup approach (preferred)
g, ctx := errgroup.WithContext(ctx)
g.Go(func() error {
    return riskyOperation(ctx)
})
if err := g.Wait(); err != nil {
    // handle first error, all goroutines cancelled via ctx
}
```

## Domain Error Design

```go
// Design errors as part of your API contract

// Package-level error interface for domain
type DomainError interface {
    error
    Code() string      // machine-readable code
    HTTPStatus() int   // maps to HTTP status
}

// Concrete domain errors
type notFoundError struct {
    resource string
    id       string
}

func (e *notFoundError) Error() string {
    return fmt.Sprintf("%s %q not found", e.resource, e.id)
}

func (e *notFoundError) Code() string      { return "NOT_FOUND" }
func (e *notFoundError) HTTPStatus() int    { return http.StatusNotFound }
func (e *notFoundError) Is(target error) bool { return target == ErrNotFound }

func NewNotFound(resource, id string) error {
    return &notFoundError{resource: resource, id: id}
}

// Usage at HTTP boundary
func errorToHTTP(w http.ResponseWriter, err error) {
    var domErr DomainError
    if errors.As(err, &domErr) {
        writeJSON(w, domErr.HTTPStatus(), map[string]string{
            "code":    domErr.Code(),
            "message": domErr.Error(),
        })
        return
    }
    // Unknown error
    writeJSON(w, http.StatusInternalServerError, map[string]string{
        "code":    "INTERNAL",
        "message": "unexpected error",
    })
}
```

## Best Practices

1. **Always handle errors** -- `_ = f()` is a code smell; if truly safe, add a comment explaining why
2. **Wrap with context** -- `fmt.Errorf("doing X: %w", err)` at each layer
3. **Use sentinel errors** for conditions callers need to branch on
4. **Use custom types** when callers need structured data from the error
5. **Translate at boundaries** -- internal errors should not leak to API consumers
6. **Never panic** for expected errors -- panics are for programmer bugs
7. **Log at the top** -- log once at the handler/boundary, not at every layer
8. **Test error paths** -- table-driven tests should include `wantErr` cases
9. **Use errors.Join** (Go 1.20+) for collecting multiple errors
10. **Design errors as API** -- your error types are part of your package contract
