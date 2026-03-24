# Testing in Go

Go has first-class testing built into the toolchain. No external framework
required -- `go test` discovers and runs tests, benchmarks, fuzz tests, and
examples automatically.

## Table-Driven Tests

The canonical Go testing pattern. One test function, many cases.

```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name string
        a, b int
        want int
    }{
        {name: "positive", a: 2, b: 3, want: 5},
        {name: "negative", a: -1, b: -2, want: -3},
        {name: "zero", a: 0, b: 0, want: 0},
        {name: "mixed", a: -1, b: 5, want: 4},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := Add(tt.a, tt.b)
            if got != tt.want {
                t.Errorf("Add(%d, %d) = %d, want %d", tt.a, tt.b, got, tt.want)
            }
        })
    }
}
```

### With Errors

```go
func TestParseConfig(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        want    *Config
        wantErr string  // empty = no error expected
    }{
        {
            name:  "valid json",
            input: `{"port": 8080}`,
            want:  &Config{Port: 8080},
        },
        {
            name:    "invalid json",
            input:   `{bad}`,
            wantErr: "parsing config",
        },
        {
            name:    "empty input",
            input:   "",
            wantErr: "empty config",
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := ParseConfig(tt.input)

            if tt.wantErr != "" {
                if err == nil {
                    t.Fatalf("expected error containing %q, got nil", tt.wantErr)
                }
                if !strings.Contains(err.Error(), tt.wantErr) {
                    t.Fatalf("error %q does not contain %q", err, tt.wantErr)
                }
                return
            }

            if err != nil {
                t.Fatalf("unexpected error: %v", err)
            }
            if !reflect.DeepEqual(got, tt.want) {
                t.Errorf("got %+v, want %+v", got, tt.want)
            }
        })
    }
}
```

## Subtests

```go
func TestUserService(t *testing.T) {
    svc := NewUserService(newTestDB(t))

    t.Run("Create", func(t *testing.T) {
        user, err := svc.Create(context.Background(), "alice", "alice@example.com")
        if err != nil {
            t.Fatalf("Create: %v", err)
        }
        if user.Name != "alice" {
            t.Errorf("Name = %q, want %q", user.Name, "alice")
        }

        t.Run("duplicate email", func(t *testing.T) {
            _, err := svc.Create(context.Background(), "bob", "alice@example.com")
            if !errors.Is(err, ErrConflict) {
                t.Errorf("expected ErrConflict, got %v", err)
            }
        })
    })

    t.Run("Get", func(t *testing.T) {
        t.Run("existing", func(t *testing.T) {
            user, err := svc.Get(context.Background(), "alice")
            if err != nil {
                t.Fatalf("Get: %v", err)
            }
            if user.Email != "alice@example.com" {
                t.Errorf("Email = %q, want %q", user.Email, "alice@example.com")
            }
        })

        t.Run("not found", func(t *testing.T) {
            _, err := svc.Get(context.Background(), "nonexistent")
            if !errors.Is(err, ErrNotFound) {
                t.Errorf("expected ErrNotFound, got %v", err)
            }
        })
    })
}
```

## Test Helpers

```go
// t.Helper() marks a function as a test helper
// Error locations point to the caller, not the helper
func assertNoError(t *testing.T, err error) {
    t.Helper()
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
}

func assertEqual[T comparable](t *testing.T, got, want T) {
    t.Helper()
    if got != want {
        t.Errorf("got %v, want %v", got, want)
    }
}

// Test fixtures with cleanup
func newTestDB(t *testing.T) *sql.DB {
    t.Helper()
    db, err := sql.Open("sqlite3", ":memory:")
    if err != nil {
        t.Fatalf("opening test db: %v", err)
    }
    t.Cleanup(func() {
        db.Close()
    })

    // Run migrations
    if _, err := db.Exec(schema); err != nil {
        t.Fatalf("applying schema: %v", err)
    }
    return db
}

// Temporary directory
func newTestDir(t *testing.T) string {
    t.Helper()
    dir := t.TempDir()  // automatically cleaned up
    return dir
}

// Skip if condition not met
func requireDocker(t *testing.T) {
    t.Helper()
    if _, err := exec.LookPath("docker"); err != nil {
        t.Skip("docker not available")
    }
}
```

## HTTP Testing

```go
import (
    "net/http"
    "net/http/httptest"
)

// Test an http.HandlerFunc directly
func TestHealthHandler(t *testing.T) {
    req := httptest.NewRequest(http.MethodGet, "/health", nil)
    w := httptest.NewRecorder()

    HealthHandler(w, req)

    resp := w.Result()
    if resp.StatusCode != http.StatusOK {
        t.Errorf("status = %d, want %d", resp.StatusCode, http.StatusOK)
    }

    body, _ := io.ReadAll(resp.Body)
    if string(body) != `{"status":"ok"}` {
        t.Errorf("body = %s", body)
    }
}

// Test with a full server
func TestAPIIntegration(t *testing.T) {
    handler := NewRouter(testDeps)
    srv := httptest.NewServer(handler)
    defer srv.Close()

    // Make real HTTP requests
    resp, err := http.Post(srv.URL+"/users", "application/json",
        strings.NewReader(`{"name":"alice","email":"alice@example.com"}`))
    if err != nil {
        t.Fatalf("POST /users: %v", err)
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusCreated {
        t.Errorf("status = %d, want %d", resp.StatusCode, http.StatusCreated)
    }

    var user User
    if err := json.NewDecoder(resp.Body).Decode(&user); err != nil {
        t.Fatalf("decoding response: %v", err)
    }
    if user.Name != "alice" {
        t.Errorf("name = %q, want %q", user.Name, "alice")
    }
}

// Test with request context (e.g., auth, tracing)
func TestAuthenticatedEndpoint(t *testing.T) {
    req := httptest.NewRequest(http.MethodGet, "/profile", nil)
    req.Header.Set("Authorization", "Bearer test-token")

    // Add context values
    ctx := context.WithValue(req.Context(), userIDKey, "user-123")
    req = req.WithContext(ctx)

    w := httptest.NewRecorder()
    ProfileHandler(w, req)

    if w.Code != http.StatusOK {
        t.Errorf("status = %d, want %d", w.Code, http.StatusOK)
    }
}

// Mock external HTTP dependencies
func TestExternalAPI(t *testing.T) {
    // Create a fake external service
    mockAPI := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        switch r.URL.Path {
        case "/api/data":
            w.Header().Set("Content-Type", "application/json")
            json.NewEncoder(w).Encode(map[string]string{"result": "ok"})
        default:
            w.WriteHeader(http.StatusNotFound)
        }
    }))
    defer mockAPI.Close()

    // Inject mock URL into client
    client := NewAPIClient(mockAPI.URL)
    result, err := client.FetchData(context.Background())
    if err != nil {
        t.Fatalf("FetchData: %v", err)
    }
    if result != "ok" {
        t.Errorf("result = %q, want %q", result, "ok")
    }
}
```

## Benchmarks

```go
// Benchmark functions start with Benchmark and take *testing.B
func BenchmarkFibonacci(b *testing.B) {
    for b.Loop() {  // Go 1.24+ (replaces for i := 0; i < b.N; i++)
        Fibonacci(20)
    }
}

// Benchmark with setup
func BenchmarkSort(b *testing.B) {
    data := generateRandomSlice(10000)
    b.ResetTimer()  // exclude setup from measurement

    for b.Loop() {
        sorted := make([]int, len(data))
        copy(sorted, data)
        sort.Ints(sorted)
    }
}

// Sub-benchmarks for different sizes
func BenchmarkLookup(b *testing.B) {
    for _, size := range []int{10, 100, 1000, 10000} {
        b.Run(fmt.Sprintf("size=%d", size), func(b *testing.B) {
            m := buildMap(size)
            b.ResetTimer()
            for b.Loop() {
                _ = m["key-50"]
            }
        })
    }
}

// Report custom metrics
func BenchmarkThroughput(b *testing.B) {
    data := make([]byte, 1024*1024)  // 1MB
    b.SetBytes(int64(len(data)))     // report MB/s

    for b.Loop() {
        processData(data)
    }
}

// Parallel benchmark
func BenchmarkConcurrentMap(b *testing.B) {
    m := &sync.Map{}
    b.RunParallel(func(pb *testing.PB) {
        for pb.Next() {
            m.Store("key", "value")
            m.Load("key")
        }
    })
}
```

```bash
# Run benchmarks
go test -bench=. -benchmem ./...

# Compare benchmarks
go install golang.org/x/perf/cmd/benchstat@latest
go test -bench=. -count=10 > old.txt
# make changes
go test -bench=. -count=10 > new.txt
benchstat old.txt new.txt
```

## Fuzz Testing (Go 1.18+)

```go
// Fuzz tests discover inputs that cause failures
func FuzzParseJSON(f *testing.F) {
    // Seed corpus: known good inputs
    f.Add(`{"name": "alice"}`)
    f.Add(`{"name": "", "age": 0}`)
    f.Add(`{}`)

    f.Fuzz(func(t *testing.T, input string) {
        var result map[string]any
        err := json.Unmarshal([]byte(input), &result)
        if err != nil {
            return  // invalid JSON is expected, not a failure
        }

        // Round-trip: marshal back and verify
        output, err := json.Marshal(result)
        if err != nil {
            t.Fatalf("Marshal after Unmarshal failed: %v", err)
        }

        var result2 map[string]any
        if err := json.Unmarshal(output, &result2); err != nil {
            t.Fatalf("Round-trip failed: %v", err)
        }
    })
}

func FuzzURL(f *testing.F) {
    f.Add("https://example.com/path?q=value")
    f.Add("http://localhost:8080")
    f.Add("")

    f.Fuzz(func(t *testing.T, rawURL string) {
        parsed, err := url.Parse(rawURL)
        if err != nil {
            return
        }
        // Reconstructed URL should be parseable
        _, err = url.Parse(parsed.String())
        if err != nil {
            t.Errorf("re-parse of %q failed: %v", parsed.String(), err)
        }
    })
}
```

```bash
go test -fuzz=FuzzParseJSON -fuzztime=30s ./...
```

## Testify (Popular Assertion Library)

```go
import (
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
    "github.com/stretchr/testify/mock"
    "github.com/stretchr/testify/suite"
)

// assert: test continues on failure
func TestWithAssert(t *testing.T) {
    result, err := DoSomething()
    assert.NoError(t, err)
    assert.Equal(t, "expected", result.Name)
    assert.NotNil(t, result.ID)
    assert.Len(t, result.Items, 3)
    assert.Contains(t, result.Tags, "important")
    assert.True(t, result.Active)
    assert.InDelta(t, 3.14, result.Value, 0.01)
    assert.WithinDuration(t, time.Now(), result.CreatedAt, time.Second)
}

// require: test stops on failure (use for prerequisites)
func TestWithRequire(t *testing.T) {
    result, err := DoSomething()
    require.NoError(t, err)          // fatal if fails
    require.NotNil(t, result)        // fatal if nil

    assert.Equal(t, "expected", result.Name)  // continues if fails
}

// Mock interfaces
type MockStore struct {
    mock.Mock
}

func (m *MockStore) GetUser(ctx context.Context, id string) (*User, error) {
    args := m.Called(ctx, id)
    if args.Get(0) == nil {
        return nil, args.Error(1)
    }
    return args.Get(0).(*User), args.Error(1)
}

func TestServiceWithMock(t *testing.T) {
    store := new(MockStore)
    store.On("GetUser", mock.Anything, "user-1").
        Return(&User{ID: "user-1", Name: "Alice"}, nil)
    store.On("GetUser", mock.Anything, "missing").
        Return(nil, ErrNotFound)

    svc := NewService(store)

    user, err := svc.GetUser(context.Background(), "user-1")
    require.NoError(t, err)
    assert.Equal(t, "Alice", user.Name)

    _, err = svc.GetUser(context.Background(), "missing")
    assert.ErrorIs(t, err, ErrNotFound)

    store.AssertExpectations(t)
}

// Test suites (group related tests with shared setup)
type UserSuite struct {
    suite.Suite
    db  *sql.DB
    svc *UserService
}

func (s *UserSuite) SetupSuite() {
    s.db = newTestDB(s.T())
    s.svc = NewUserService(s.db)
}

func (s *UserSuite) TearDownSuite() {
    s.db.Close()
}

func (s *UserSuite) SetupTest() {
    // runs before each test
    s.db.Exec("DELETE FROM users")
}

func (s *UserSuite) TestCreate() {
    user, err := s.svc.Create(context.Background(), "alice", "alice@example.com")
    s.Require().NoError(err)
    s.Equal("alice", user.Name)
}

func (s *UserSuite) TestGetNotFound() {
    _, err := s.svc.Get(context.Background(), "nonexistent")
    s.ErrorIs(err, ErrNotFound)
}

func TestUserSuite(t *testing.T) {
    suite.Run(t, new(UserSuite))
}
```

## TestMain (Global Setup/Teardown)

```go
func TestMain(m *testing.M) {
    // Global setup
    db := setupTestDatabase()

    // Run all tests
    code := m.Run()

    // Global teardown
    db.Close()

    os.Exit(code)
}
```

## Test Build Tags

```go
//go:build integration
// +build integration

package myapp_test

func TestDatabaseIntegration(t *testing.T) {
    // Only runs with: go test -tags=integration ./...
}
```

## Coverage

```bash
# Basic coverage
go test -cover ./...

# Coverage profile
go test -coverprofile=coverage.out ./...

# HTML report
go tool cover -html=coverage.out -o coverage.html

# Per-function breakdown
go tool cover -func=coverage.out

# Fail if coverage is below threshold (CI)
go test -coverprofile=coverage.out ./... && \
  go tool cover -func=coverage.out | grep total | awk '{print $3}' | \
  sed 's/%//' | awk '{if ($1 < 80) exit 1}'

# Coverage for specific packages
go test -coverprofile=coverage.out -coverpkg=./internal/... ./...
```

## Race Detector

```bash
# Always run with race detector in CI
go test -race ./...

# Also works with go run and go build
go run -race ./cmd/myapp
go build -race -o myapp ./cmd/myapp
```

## Golden Files

```go
// Compare output against saved "golden" files
func TestRender(t *testing.T) {
    got := Render(input)

    golden := filepath.Join("testdata", t.Name()+".golden")

    if *update {
        // go test -update to regenerate golden files
        os.WriteFile(golden, []byte(got), 0644)
    }

    want, err := os.ReadFile(golden)
    if err != nil {
        t.Fatalf("reading golden file: %v", err)
    }

    if got != string(want) {
        t.Errorf("output mismatch:\ngot:\n%s\nwant:\n%s", got, want)
    }
}

var update = flag.Bool("update", false, "update golden files")
```

## Best Practices

1. **Table-driven tests by default** -- easy to add cases, clear structure
2. **Use `t.Run` for subtests** -- clear names, parallel execution, selective running
3. **`t.Helper()` on every helper** -- accurate error line numbers
4. **`t.Cleanup()` over defer** -- cleaner, works in subtests
5. **`t.Parallel()` where safe** -- faster test suite
6. **`require` for prerequisites, `assert` for checks** -- fail fast on setup, continue on assertions
7. **Test behavior, not implementation** -- test public API, not internal details
8. **Name tests descriptively** -- `TestUserService_Create_DuplicateEmail`
9. **Use `testdata/` for fixtures** -- Go convention, ignored by `go build`
10. **Race detector in CI** -- `go test -race ./...` catches data races
11. **Benchmark before optimizing** -- measure, don't guess
12. **Fuzz parse/decode functions** -- finds edge cases you won't think of
