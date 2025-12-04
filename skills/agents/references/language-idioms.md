# Language-Specific Idioms and Best Practices

Deep dive into idiomatic patterns, best practices, and common pitfalls for each supported language.

## Python Idioms

### The Zen of Python

```python
import this

# Key principles:
# - Beautiful is better than ugly
# - Explicit is better than implicit
# - Simple is better than complex
# - Readability counts
# - There should be one obvious way to do it
```

### Type Hints and Type Checking

```python
from typing import List, Dict, Optional, Union, Callable, TypeVar, Generic
from decimal import Decimal

# Modern type hints (Python 3.10+)
def process_items(items: list[str], limit: int | None = None) -> dict[str, int]:
    """Process items and return counts."""
    counts: dict[str, int] = {}
    for item in items[:limit]:
        counts[item] = counts.get(item, 0) + 1
    return counts

# Generic types
T = TypeVar('T')

def first_or_none(items: list[T]) -> T | None:
    """Return first item or None if list is empty."""
    return items[0] if items else None

# Protocol for structural typing
from typing import Protocol

class Drawable(Protocol):
    """Anything with a draw() method."""
    def draw(self) -> None: ...

def render(obj: Drawable) -> None:
    """Render any drawable object."""
    obj.draw()

# Literal types
from typing import Literal

Mode = Literal["read", "write", "append"]

def open_file(path: str, mode: Mode) -> File:
    """Type-safe file opening."""
    ...
```

### Context Managers and Resource Management

```python
# Basic context manager
with open("file.txt", "r") as f:
    data = f.read()

# Custom context manager
from contextlib import contextmanager

@contextmanager
def database_transaction(db):
    """Context manager for database transactions."""
    try:
        yield db
        db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()

# Usage
with database_transaction(db) as transaction:
    transaction.execute("INSERT INTO users ...")

# Class-based context manager
class Timer:
    """Measure execution time."""

    def __enter__(self):
        self.start = time.time()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.end = time.time()
        self.duration = self.end - self.start
        print(f"Duration: {self.duration:.2f}s")
        return False  # Don't suppress exceptions

# Usage
with Timer():
    expensive_operation()
```

### Comprehensions and Generator Expressions

```python
# List comprehension
squares = [x**2 for x in range(10)]

# Dict comprehension
word_lengths = {word: len(word) for word in ["hello", "world"]}

# Set comprehension
unique_lengths = {len(word) for word in words}

# Generator expression (lazy evaluation)
total = sum(x**2 for x in range(1000000))  # Memory efficient!

# Nested comprehensions
matrix = [[i*j for j in range(5)] for i in range(5)]

# With conditions
even_squares = [x**2 for x in range(10) if x % 2 == 0]

# Multiple iterables
pairs = [(x, y) for x in range(3) for y in range(3)]

# Dict comprehension with filtering
filtered = {k: v for k, v in data.items() if v > 0}
```

### Itertools Patterns

```python
from itertools import (
    islice, chain, combinations, permutations,
    groupby, accumulate, cycle, repeat
)

# Take first N items from iterator
first_ten = list(islice(infinite_sequence(), 10))

# Chain iterables
all_items = chain(list1, list2, list3)

# Combinations and permutations
combos = list(combinations([1, 2, 3], 2))  # [(1,2), (1,3), (2,3)]
perms = list(permutations([1, 2, 3], 2))   # [(1,2), (1,3), (2,1), ...]

# Group by key
data = [("a", 1), ("a", 2), ("b", 3), ("b", 4)]
for key, group in groupby(data, key=lambda x: x[0]):
    print(f"{key}: {list(group)}")

# Running sum
cumsum = list(accumulate([1, 2, 3, 4]))  # [1, 3, 6, 10]

# Infinite iterators
counter = cycle([1, 2, 3])  # 1, 2, 3, 1, 2, 3, ...
ones = repeat(1, 5)         # 1, 1, 1, 1, 1
```

### Dataclasses and Attrs

```python
from dataclasses import dataclass, field
from typing import List

@dataclass
class User:
    """User with automatic __init__, __repr__, __eq__."""
    id: int
    email: str
    age: int
    tags: List[str] = field(default_factory=list)
    is_active: bool = True

    def __post_init__(self):
        """Validation after initialization."""
        if self.age < 0:
            raise ValueError("Age cannot be negative")

# Usage
user = User(id=1, email="test@example.com", age=25)
print(user)  # User(id=1, email='test@example.com', age=25, tags=[], is_active=True)

# Frozen (immutable) dataclass
@dataclass(frozen=True)
class Point:
    x: float
    y: float

# With ordering
@dataclass(order=True)
class Task:
    priority: int
    name: str

tasks = [Task(3, "Low"), Task(1, "High"), Task(2, "Med")]
tasks.sort()  # Sorts by priority
```

### Decorators and Function Wrappers

```python
from functools import wraps
import time

# Simple decorator
def timer(func):
    """Time function execution."""
    @wraps(func)
    def wrapper(*args, **kwargs):
        start = time.time()
        result = func(*args, **kwargs)
        end = time.time()
        print(f"{func.__name__} took {end-start:.2f}s")
        return result
    return wrapper

@timer
def slow_function():
    time.sleep(1)

# Decorator with arguments
def retry(max_attempts=3, delay=1):
    """Retry function on exception."""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            for attempt in range(max_attempts):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    if attempt == max_attempts - 1:
                        raise
                    time.sleep(delay)
        return wrapper
    return decorator

@retry(max_attempts=5, delay=2)
def flaky_api_call():
    ...

# Class decorator
def singleton(cls):
    """Ensure only one instance of class exists."""
    instances = {}

    @wraps(cls)
    def get_instance(*args, **kwargs):
        if cls not in instances:
            instances[cls] = cls(*args, **kwargs)
        return instances[cls]

    return get_instance

@singleton
class Database:
    ...
```

### Pytest Fixtures and Parametrization

```python
import pytest

# Fixture with scope
@pytest.fixture(scope="session")
def database():
    """Session-wide database connection."""
    db = Database.connect()
    yield db
    db.disconnect()

# Fixture with cleanup
@pytest.fixture
def temp_file():
    """Create temporary file."""
    f = tempfile.NamedTemporaryFile(delete=False)
    yield f.name
    os.unlink(f.name)  # Cleanup

# Parametrized fixture
@pytest.fixture(params=[1, 2, 3])
def test_value(request):
    """Run test with multiple values."""
    return request.param

# Parametrized test
@pytest.mark.parametrize("input,expected", [
    (1, 2),
    (2, 4),
    (3, 6),
])
def test_double(input, expected):
    assert double(input) == expected

# Multiple parameters
@pytest.mark.parametrize("x,y,expected", [
    (1, 1, 2),
    (2, 3, 5),
    pytest.param(1, 0, 1, marks=pytest.mark.slow),
])
def test_add(x, y, expected):
    assert add(x, y) == expected

# Indirect parametrization
@pytest.fixture
def user(request):
    return User(**request.param)

@pytest.mark.parametrize("user", [
    {"name": "Alice", "age": 30},
    {"name": "Bob", "age": 25},
], indirect=True)
def test_user(user):
    assert user.name in ["Alice", "Bob"]
```

## JavaScript/TypeScript Idioms

### Modern JS Patterns

```typescript
// Destructuring
const { name, age, email } = user;
const [first, second, ...rest] = array;

// Spread operator
const merged = { ...defaults, ...userConfig };
const combined = [...array1, ...array2];

// Default parameters
function greet(name = "Guest", greeting = "Hello") {
    return `${greeting}, ${name}!`;
}

// Arrow functions
const double = (x: number) => x * 2;
const users = data.map(item => ({ id: item.id, name: item.name }));

// Optional chaining
const userName = user?.profile?.name;
const firstItem = array?.[0];

// Nullish coalescing
const value = userInput ?? defaultValue;  // Only null/undefined
const other = userInput || defaultValue;  // Any falsy value

// Template literals
const message = `Hello, ${name}! You have ${count} messages.`;
const multiline = `
    Line 1
    Line 2
`;

// Object shorthand
const name = "Alice";
const age = 30;
const user = { name, age };  // Same as { name: name, age: age }

// Computed property names
const key = "dynamicKey";
const obj = { [key]: "value" };
```

### Async/Await Patterns

```typescript
// Basic async/await
async function fetchUser(id: string): Promise<User> {
    const response = await fetch(`/api/users/${id}`);
    if (!response.ok) {
        throw new Error('Failed to fetch user');
    }
    return response.json();
}

// Error handling
async function fetchUserSafe(id: string): Promise<User | null> {
    try {
        const user = await fetchUser(id);
        return user;
    } catch (error) {
        console.error('Error fetching user:', error);
        return null;
    }
}

// Parallel execution
async function fetchAll() {
    const [users, posts, comments] = await Promise.all([
        fetchUsers(),
        fetchPosts(),
        fetchComments(),
    ]);
    return { users, posts, comments };
}

// Race condition
async function fetchWithTimeout(url: string, timeout: number) {
    return Promise.race([
        fetch(url),
        new Promise((_, reject) =>
            setTimeout(() => reject(new Error('Timeout')), timeout)
        ),
    ]);
}

// Sequential async operations
async function processItems(items: Item[]) {
    for (const item of items) {
        await processItem(item);  // Wait for each
    }
}

// Parallel async operations
async function processItemsParallel(items: Item[]) {
    await Promise.all(items.map(item => processItem(item)));
}
```

### TypeScript Type Guards

```typescript
// Type predicate
function isString(value: unknown): value is string {
    return typeof value === 'string';
}

// Usage
function process(value: string | number) {
    if (isString(value)) {
        // TypeScript knows value is string here
        console.log(value.toUpperCase());
    } else {
        // TypeScript knows value is number here
        console.log(value.toFixed(2));
    }
}

// Discriminated unions
type Shape =
    | { kind: 'circle'; radius: number }
    | { kind: 'rectangle'; width: number; height: number }
    | { kind: 'square'; size: number };

function area(shape: Shape): number {
    switch (shape.kind) {
        case 'circle':
            return Math.PI * shape.radius ** 2;
        case 'rectangle':
            return shape.width * shape.height;
        case 'square':
            return shape.size ** 2;
    }
}

// Assertion functions
function assert(condition: unknown, message?: string): asserts condition {
    if (!condition) {
        throw new Error(message ?? 'Assertion failed');
    }
}

// Usage
function process(value: string | null) {
    assert(value !== null, 'Value must not be null');
    // TypeScript knows value is string here
    console.log(value.toUpperCase());
}
```

### React Hooks Patterns

```typescript
import { useState, useEffect, useCallback, useMemo, useRef } from 'react';

// State hook
function Counter() {
    const [count, setCount] = useState(0);
    return (
        <button onClick={() => setCount(count + 1)}>
            Count: {count}
        </button>
    );
}

// Effect hook
function DataFetcher({ userId }: { userId: string }) {
    const [user, setUser] = useState<User | null>(null);

    useEffect(() => {
        let cancelled = false;

        async function fetch() {
            const data = await fetchUser(userId);
            if (!cancelled) {
                setUser(data);
            }
        }

        fetch();

        return () => {
            cancelled = true;  // Cleanup
        };
    }, [userId]);  // Re-run when userId changes

    return <div>{user?.name}</div>;
}

// Callback hook (memoize function)
function Parent() {
    const [count, setCount] = useState(0);

    const handleClick = useCallback(() => {
        setCount(c => c + 1);
    }, []);  // Function doesn't change

    return <Child onClick={handleClick} />;
}

// Memo hook (memoize value)
function ExpensiveComponent({ items }: { items: Item[] }) {
    const total = useMemo(() => {
        return items.reduce((sum, item) => sum + item.price, 0);
    }, [items]);  // Only recompute when items change

    return <div>Total: {total}</div>;
}

// Ref hook
function TextInput() {
    const inputRef = useRef<HTMLInputElement>(null);

    useEffect(() => {
        inputRef.current?.focus();
    }, []);

    return <input ref={inputRef} />;
}

// Custom hook
function useLocalStorage<T>(key: string, initial: T) {
    const [value, setValue] = useState<T>(() => {
        const stored = localStorage.getItem(key);
        return stored ? JSON.parse(stored) : initial;
    });

    useEffect(() => {
        localStorage.setItem(key, JSON.stringify(value));
    }, [key, value]);

    return [value, setValue] as const;
}
```

### Testing with Vitest/Jest

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';

describe('Calculator', () => {
    let calc: Calculator;

    beforeEach(() => {
        calc = new Calculator();
    });

    it('adds two numbers', () => {
        expect(calc.add(2, 3)).toBe(5);
    });

    it('handles errors', () => {
        expect(() => calc.divide(10, 0)).toThrow('Division by zero');
    });

    // Mocking
    it('calls API', async () => {
        const mockFetch = vi.fn().mockResolvedValue({
            ok: true,
            json: async () => ({ id: 1, name: 'Test' }),
        });
        global.fetch = mockFetch;

        const result = await fetchUser('1');

        expect(mockFetch).toHaveBeenCalledWith('/api/users/1');
        expect(result).toEqual({ id: 1, name: 'Test' });
    });

    // Snapshot testing
    it('renders correctly', () => {
        const component = <Button>Click me</Button>;
        expect(component).toMatchSnapshot();
    });
});
```

## Go Idioms

### Error Handling

```go
// Standard error handling
func readFile(path string) ([]byte, error) {
    data, err := os.ReadFile(path)
    if err != nil {
        return nil, fmt.Errorf("failed to read file %s: %w", path, err)
    }
    return data, nil
}

// Multiple return values
func divide(a, b float64) (float64, error) {
    if b == 0 {
        return 0, errors.New("division by zero")
    }
    return a / b, nil
}

// Named return values
func calculate(x int) (result int, err error) {
    if x < 0 {
        err = errors.New("negative input")
        return
    }
    result = x * 2
    return
}

// Custom error types
type ValidationError struct {
    Field string
    Value interface{}
    Err   error
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation failed for field %s: %v", e.Field, e.Err)
}

func (e *ValidationError) Unwrap() error {
    return e.Err
}

// Error checking with errors.Is and errors.As
if errors.Is(err, os.ErrNotExist) {
    // Handle file not found
}

var validationErr *ValidationError
if errors.As(err, &validationErr) {
    // Handle validation error
    fmt.Println("Field:", validationErr.Field)
}
```

### Interfaces and Composition

```go
// Small interfaces (Go philosophy)
type Reader interface {
    Read(p []byte) (n int, err error)
}

type Writer interface {
    Write(p []byte) (n int, err error)
}

type ReadWriter interface {
    Reader
    Writer
}

// Struct composition
type User struct {
    ID   int
    Name string
}

type Admin struct {
    User           // Embedded struct
    Permissions []string
}

admin := Admin{
    User: User{ID: 1, Name: "Alice"},
    Permissions: []string{"read", "write"},
}
// Can access: admin.ID, admin.Name (promoted fields)

// Interface implementation is implicit
type MyWriter struct{}

func (w MyWriter) Write(p []byte) (n int, err error) {
    return len(p), nil
}
// MyWriter automatically implements Writer interface!
```

### Goroutines and Channels

```go
// Basic goroutine
go func() {
    fmt.Println("Running in background")
}()

// Channel communication
ch := make(chan int)

// Send
go func() {
    ch <- 42
}()

// Receive
value := <-ch

// Buffered channel
ch := make(chan int, 10)

// Range over channel
go func() {
    for i := 0; i < 5; i++ {
        ch <- i
    }
    close(ch)  // Signal no more values
}()

for value := range ch {
    fmt.Println(value)
}

// Select for multiple channels
select {
case msg := <-ch1:
    fmt.Println("From ch1:", msg)
case msg := <-ch2:
    fmt.Println("From ch2:", msg)
case <-time.After(1 * time.Second):
    fmt.Println("Timeout")
}

// Worker pool pattern
func worker(id int, jobs <-chan int, results chan<- int) {
    for job := range jobs {
        results <- job * 2
    }
}

jobs := make(chan int, 100)
results := make(chan int, 100)

// Start workers
for w := 1; w <= 3; w++ {
    go worker(w, jobs, results)
}

// Send jobs
for j := 1; j <= 9; j++ {
    jobs <- j
}
close(jobs)

// Collect results
for a := 1; a <= 9; a++ {
    <-results
}
```

### Table-Driven Tests

```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name     string
        a, b     int
        expected int
    }{
        {"positive numbers", 2, 3, 5},
        {"negative numbers", -2, -3, -5},
        {"mixed signs", -2, 3, 1},
        {"zero", 0, 0, 0},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := Add(tt.a, tt.b)
            if result != tt.expected {
                t.Errorf("Add(%d, %d) = %d; want %d",
                    tt.a, tt.b, result, tt.expected)
            }
        })
    }
}

// Test helpers
func assertEqual(t *testing.T, got, want interface{}) {
    t.Helper()  // Mark as helper
    if got != want {
        t.Errorf("got %v; want %v", got, want)
    }
}

// Benchmarks
func BenchmarkAdd(b *testing.B) {
    for i := 0; i < b.N; i++ {
        Add(2, 3)
    }
}
```

## Rust Idioms

### Ownership and Borrowing

```rust
// Ownership transfer
fn take_ownership(s: String) {
    println!("{}", s);
}  // s is dropped here

let s = String::from("hello");
take_ownership(s);
// s is no longer valid here!

// Borrowing (immutable)
fn borrow_read(s: &String) {
    println!("{}", s);
}

let s = String::from("hello");
borrow_read(&s);
// s is still valid here

// Mutable borrowing
fn borrow_write(s: &mut String) {
    s.push_str(" world");
}

let mut s = String::from("hello");
borrow_write(&mut s);
println!("{}", s);  // "hello world"

// Multiple immutable borrows OK
let s = String::from("hello");
let r1 = &s;
let r2 = &s;
println!("{} {}", r1, r2);  // OK

// But can't mix mutable and immutable
let mut s = String::from("hello");
let r1 = &s;
// let r2 = &mut s;  // ERROR!
```

### Error Handling with Result and Option

```rust
// Result type
fn divide(a: f64, b: f64) -> Result<f64, String> {
    if b == 0.0 {
        Err(String::from("division by zero"))
    } else {
        Ok(a / b)
    }
}

// Using Result
match divide(10.0, 2.0) {
    Ok(result) => println!("Result: {}", result),
    Err(e) => eprintln!("Error: {}", e),
}

// ? operator for early return
fn calculate() -> Result<f64, String> {
    let a = divide(10.0, 2.0)?;  // Returns error if divide fails
    let b = divide(a, 3.0)?;
    Ok(b)
}

// Option type
fn find_user(id: i32) -> Option<User> {
    if id > 0 {
        Some(User { id, name: String::from("Alice") })
    } else {
        None
    }
}

// Using Option
if let Some(user) = find_user(1) {
    println!("Found: {}", user.name);
}

// Unwrap alternatives
let value = option.unwrap_or(default);
let value = option.unwrap_or_else(|| expensive_default());
let value = option.expect("Should have a value here");

// Combinators
let result = option
    .map(|x| x * 2)
    .filter(|x| x > &10)
    .unwrap_or(0);
```

### Pattern Matching

```rust
// Basic match
match value {
    1 => println!("one"),
    2 => println!("two"),
    _ => println!("other"),
}

// Match with guards
match number {
    n if n < 0 => println!("negative"),
    n if n > 0 => println!("positive"),
    _ => println!("zero"),
}

// Destructuring
struct Point { x: i32, y: i32 }

match point {
    Point { x: 0, y: 0 } => println!("origin"),
    Point { x, y: 0 } => println!("on x axis at {}", x),
    Point { x: 0, y } => println!("on y axis at {}", y),
    Point { x, y } => println!("at ({}, {})", x, y),
}

// Enum matching
enum Message {
    Quit,
    Move { x: i32, y: i32 },
    Write(String),
}

match msg {
    Message::Quit => println!("quit"),
    Message::Move { x, y } => println!("move to {}, {}", x, y),
    Message::Write(text) => println!("text: {}", text),
}

// if let (match single pattern)
if let Some(value) = optional {
    println!("Got: {}", value);
}

// while let
while let Some(value) = stack.pop() {
    println!("{}", value);
}
```

### Iterators and Closures

```rust
// Iterator methods
let numbers = vec![1, 2, 3, 4, 5];

let doubled: Vec<_> = numbers.iter()
    .map(|x| x * 2)
    .collect();

let sum: i32 = numbers.iter().sum();

let even: Vec<_> = numbers.iter()
    .filter(|&x| x % 2 == 0)
    .collect();

// Closures
let add_one = |x| x + 1;
let result = add_one(5);

// Closure capturing environment
let factor = 2;
let multiply = |x| x * factor;

// Move closure (take ownership)
let move_closure = move |x| x * factor;

// Custom iterator
struct Counter {
    count: u32,
}

impl Iterator for Counter {
    type Item = u32;

    fn next(&mut self) -> Option<Self::Item> {
        self.count += 1;
        if self.count < 6 {
            Some(self.count)
        } else {
            None
        }
    }
}

// Usage
for num in Counter { count: 0 } {
    println!("{}", num);
}
```

### Testing Patterns

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        assert_eq!(2 + 2, 4);
    }

    #[test]
    #[should_panic(expected = "division by zero")]
    fn it_panics() {
        divide(10, 0);
    }

    #[test]
    fn with_result() -> Result<(), String> {
        let result = divide(10.0, 2.0)?;
        assert_eq!(result, 5.0);
        Ok(())
    }

    // Test helper
    fn setup() -> TestData {
        TestData::new()
    }

    #[test]
    fn using_helper() {
        let data = setup();
        assert!(data.is_valid());
    }
}
```

## Common Patterns Across Languages

### Builder Pattern

```python
# Python
class UserBuilder:
    def __init__(self):
        self._user = {}

    def with_email(self, email):
        self._user['email'] = email
        return self

    def with_age(self, age):
        self._user['age'] = age
        return self

    def build(self):
        return User(**self._user)

user = (UserBuilder()
    .with_email("test@example.com")
    .with_age(25)
    .build())
```

```typescript
// TypeScript
class UserBuilder {
    private email?: string;
    private age?: number;

    withEmail(email: string): this {
        this.email = email;
        return this;
    }

    withAge(age: number): this {
        this.age = age;
        return this;
    }

    build(): User {
        if (!this.email || !this.age) {
            throw new Error('Email and age required');
        }
        return new User(this.email, this.age);
    }
}

const user = new UserBuilder()
    .withEmail('test@example.com')
    .withAge(25)
    .build();
```

```rust
// Rust
struct UserBuilder {
    email: Option<String>,
    age: Option<u32>,
}

impl UserBuilder {
    fn new() -> Self {
        UserBuilder { email: None, age: None }
    }

    fn email(mut self, email: String) -> Self {
        self.email = Some(email);
        self
    }

    fn age(mut self, age: u32) -> Self {
        self.age = Some(age);
        self
    }

    fn build(self) -> Result<User, String> {
        Ok(User {
            email: self.email.ok_or("Email required")?,
            age: self.age.ok_or("Age required")?,
        })
    }
}

let user = UserBuilder::new()
    .email(String::from("test@example.com"))
    .age(25)
    .build()?;
```

## Anti-Patterns

### Python Anti-Patterns

```python
# ❌ Mutable default arguments
def add_item(item, items=[]):  # BAD!
    items.append(item)
    return items

# ✅ Use None as default
def add_item(item, items=None):
    if items is None:
        items = []
    items.append(item)
    return items

# ❌ Catching all exceptions
try:
    risky_operation()
except:  # BAD!
    pass

# ✅ Catch specific exceptions
try:
    risky_operation()
except ValueError as e:
    logger.error(f"Value error: {e}")
    raise

# ❌ Using `eval`
result = eval(user_input)  # DANGEROUS!

# ✅ Use ast.literal_eval or proper parsing
import ast
result = ast.literal_eval(user_input)
```

### JavaScript/TypeScript Anti-Patterns

```typescript
// ❌ Using `any`
function process(data: any) {  // BAD!
    return data.value;
}

// ✅ Use proper types
function process(data: { value: string }) {
    return data.value;
}

// ❌ Not handling async errors
async function fetch() {
    const data = await fetchData();  // Unhandled rejection!
}

// ✅ Handle errors
async function fetch() {
    try {
        const data = await fetchData();
    } catch (error) {
        console.error('Failed:', error);
    }
}

// ❌ Mutating props in React
function Component({ items }) {
    items.push(newItem);  // BAD!
}

// ✅ Create new array
function Component({ items }) {
    const newItems = [...items, newItem];
}
```

## Remember

- **Python**: "There should be one obvious way to do it"
- **JavaScript**: Embrace async/await, avoid callback hell
- **Go**: Simple, explicit, concurrent by design
- **Rust**: Compiler is your friend, trust the borrow checker
- **All**: Write idiomatic code that matches language philosophy
