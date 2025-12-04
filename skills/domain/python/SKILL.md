---
name: python
description: >
  Expert Python development with modern idioms (3.10+), type hints, testing,
  and tooling. Use when writing Python code, reviewing Python implementations,
  setting up Python projects, debugging Python issues, or advising on Pythonic
  patterns. Covers fundamentals, testing with pytest, ruff/mypy tooling, async
  patterns, and common anti-patterns to avoid.
---

# Python Domain Skill

## Quick Reference

### Modern Type Hints (3.10+)

```python
# Union with | operator
def process(value: int | str | None) -> dict[str, int]:
    pass

# Type aliases
type UserID = int
type Config = dict[str, str | int | bool]

# See references/type-hints-advanced.md for:
# - Generics and TypeVars
# - Protocols (structural typing)
# - Function overloading
# - Advanced patterns
```

### Essential Patterns

```python
# Context managers (always use for resources)
with open("file.txt") as f:
    content = f.read()

# Comprehensions
squares = [x**2 for x in range(10) if x % 2 == 0]
word_lengths = {word: len(word) for word in words}

# Decorators (always use @wraps)
from functools import wraps

def timer(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        start = time.time()
        result = func(*args, **kwargs)
        print(f"{func.__name__} took {time.time() - start:.2f}s")
        return result
    return wrapper
```

## Code Style

### PEP 8 Essentials

```python
# Imports: stdlib, third-party, local (blank line separated)
import os
import sys

import requests
from fastapi import FastAPI

from myapp.models import User

# Line length: 88 characters (Black/ruff default)
# Use trailing commas in multi-line structures
my_list = [
    1,
    2,
    3,  # Trailing comma
]

# Naming: snake_case, UPPER_CASE, CapWords, _private
def calculate_total() -> float:
    MAX_VALUE = 100
    return 0.0

class UserAccount:
    def __init__(self):
        self._internal = {}
```

## Testing with Pytest

```python
# Basic test
def test_addition():
    assert 1 + 1 == 2

# Fixtures
@pytest.fixture
def sample_user():
    return {"name": "Alice", "email": "alice@example.com"}

def test_user(sample_user):
    assert sample_user["name"] == "Alice"

# Parametrize
@pytest.mark.parametrize("input,expected", [
    (0, 0),
    (1, 1),
    (2, 4),
])
def test_square(input, expected):
    assert input ** 2 == expected

# Mock with pytest-mock
def test_api(mocker):
    mock_get = mocker.patch("requests.get")
    mock_get.return_value.json.return_value = {"status": "ok"}
    result = fetch_data()
    assert result["status"] == "ok"
```

**Coverage target: 80%+**

```bash
pytest --cov=myapp --cov-report=term-missing --cov-fail-under=80
```

**See references/testing-pytest.md for:**
- Advanced fixtures (scopes, factories)
- Mocking patterns
- Markers and plugins
- Test organization

## Tooling

### Ruff (Linting + Formatting)

Replaces Black, isort, flake8, pyupgrade.

```bash
# Lint and fix
ruff check --fix .

# Format
ruff format .

# Both
ruff check --fix . && ruff format .
```

**Basic config:**

```toml
# pyproject.toml
[tool.ruff]
line-length = 88
target-version = "py310"

[tool.ruff.lint]
select = ["E", "W", "F", "I", "N", "UP", "B", "C4", "SIM"]
ignore = ["E501"]

[tool.ruff.format]
quote-style = "double"
```

### Mypy (Type Checking)

```bash
mypy myapp/
```

**Strict config:**

```toml
[tool.mypy]
python_version = "3.10"
strict = true
warn_return_any = true
disallow_untyped_defs = true
```

### Poetry (Dependency Management)

```bash
# Setup
poetry init
poetry add requests
poetry add --group dev pytest ruff mypy

# Install and run
poetry install
poetry run pytest
poetry shell
```

**See references/tooling-config.md for:**
- Complete ruff rule sets
- Mypy configuration options
- Poetry advanced usage
- Pre-commit hooks
- CI/CD integration

## Async Programming

```python
import asyncio

# Basic async function
async def fetch_data(url: str) -> dict:
    await asyncio.sleep(1)
    return {"url": url}

# Run concurrently
async def fetch_all(urls: list[str]) -> list[dict]:
    return await asyncio.gather(*[fetch_data(url) for url in urls])

# Run from sync
def main():
    result = asyncio.run(fetch_data("https://api.example.com"))

# Context manager
class AsyncDatabase:
    async def __aenter__(self):
        self.connection = await connect()
        return self

    async def __aexit__(self, *args):
        await self.connection.close()

async def query():
    async with AsyncDatabase() as db:
        return await db.query("SELECT * FROM users")
```

**See references/async-patterns.md for:**
- Task management and cancellation
- Semaphores and rate limiting
- Queues and producers/consumers
- Error handling
- Performance optimization
- Common pitfalls

## Data Modeling

### Dataclasses (Standard Library)

```python
from dataclasses import dataclass, field
from datetime import datetime

@dataclass
class User:
    id: int
    name: str
    email: str
    created_at: datetime = field(default_factory=datetime.now)
    roles: list[str] = field(default_factory=list)

# Immutable
@dataclass(frozen=True)
class Point:
    x: float
    y: float
```

### Pydantic (Validation)

```python
from pydantic import BaseModel, Field, EmailStr, field_validator

class UserCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    email: EmailStr
    age: int = Field(..., ge=0, le=150)

    @field_validator("email")
    @classmethod
    def normalize_email(cls, v: str) -> str:
        return v.lower().strip()

# Automatic validation
try:
    user = UserCreate(name="Alice", email="ALICE@EXAMPLE.COM", age=30)
except ValidationError as e:
    print(e.json())
```

**When to use:**
- **Dataclasses**: Internal data, simple containers, performance critical
- **Pydantic**: External data, API validation, configs from environment

**See references/dataclasses-pydantic.md for:**
- Advanced dataclass features (slots, ordering)
- Pydantic validators and computed fields
- Settings management
- Nested models and generics
- JSON schema generation

## Common Patterns

### Error Handling

```python
# Specific exceptions
def divide(a: float, b: float) -> float:
    if b == 0:
        raise ValueError("Cannot divide by zero")
    return a / b

# Custom exceptions
class UserNotFoundError(Exception):
    def __init__(self, user_id: int):
        self.user_id = user_id
        super().__init__(f"User {user_id} not found")

# Try-except-else-finally
try:
    result = risky_operation()
except SpecificError as e:
    logger.error(f"Operation failed: {e}")
    raise
else:
    post_process(result)  # Only if no exception
finally:
    cleanup()  # Always runs
```

### Logging

```python
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)

logger = logging.getLogger(__name__)

def process_data(data):
    logger.info("Processing data", extra={"count": len(data)})
    try:
        result = transform(data)
        logger.debug("Transform successful")
        return result
    except Exception as e:
        logger.error("Transform failed", exc_info=True)
        raise
```

## Anti-patterns to Avoid

### 1. Mutable Default Arguments
```python
# BAD
def add_item(item, items=[]):
    items.append(item)
    return items

# GOOD
def add_item(item, items=None):
    if items is None:
        items = []
    items.append(item)
    return items
```

### 2. Bare Except Clauses
```python
# BAD
try:
    risky_operation()
except:  # Catches everything including KeyboardInterrupt
    pass

# GOOD
try:
    risky_operation()
except SpecificError as e:
    logger.error(f"Expected error: {e}")
```

### 3. Using == for None
```python
# BAD
if value == None:
    pass

# GOOD
if value is None:
    pass
```

### 4. Modifying List While Iterating
```python
# BAD
for item in items:
    if should_remove(item):
        items.remove(item)  # Skips elements

# GOOD
items = [item for item in items if not should_remove(item)]
```

### 5. Not Using with for Files
```python
# BAD
f = open("file.txt")
data = f.read()
f.close()  # Might not run if exception

# GOOD
with open("file.txt") as f:
    data = f.read()
```

### 6. String Concatenation in Loops
```python
# BAD (slow)
result = ""
for item in items:
    result += str(item) + ","

# GOOD
result = ",".join(str(item) for item in items)
```

### 7. Not Using enumerate
```python
# BAD
i = 0
for item in items:
    print(f"{i}: {item}")
    i += 1

# GOOD
for i, item in enumerate(items):
    print(f"{i}: {item}")
```

### 8. Type Checking with type()
```python
# BAD
if type(value) == list:
    pass

# GOOD (supports subclasses)
if isinstance(value, list):
    pass
```

## Project Setup Checklist

```bash
# 1. Initialize with poetry
poetry init
poetry add <dependencies>
poetry add --group dev pytest pytest-cov ruff mypy

# 2. Create pyproject.toml config
# [tool.ruff], [tool.mypy], [tool.pytest.ini_options]

# 3. Install pre-commit
poetry add --group dev pre-commit
pre-commit install

# 4. Run quality checks
ruff check --fix . && ruff format . && mypy . && pytest --cov=myapp --cov-fail-under=80
```

## Commands

```bash
# Format and lint
ruff format . && ruff check --fix .

# Type check
mypy .

# Test with coverage
pytest --cov=myapp --cov-report=term-missing --cov-fail-under=80

# Full quality check
ruff format . && ruff check . && mypy . && pytest --cov=myapp --cov-fail-under=80
```

## Reference Files

For detailed information, see:

- **references/type-hints-advanced.md** - Generics, Protocols, TypeVars, overloads, TypedDict, advanced patterns
- **references/async-patterns.md** - asyncio deep dive, task management, queues, synchronization, performance
- **references/testing-pytest.md** - Fixtures, parametrize, mocking, markers, plugins, best practices
- **references/tooling-config.md** - ruff, mypy, poetry, pre-commit, bandit configs with examples
- **references/dataclasses-pydantic.md** - Data modeling, validation, serialization, settings management

## Best Practices Summary

1. **Type hints everywhere**: Enable mypy strict mode
2. **Test-driven development**: Write tests first, aim for 80%+ coverage
3. **Use modern syntax**: Python 3.10+ features (match, union with |)
4. **Validate at boundaries**: Pydantic for external data
5. **Context managers for resources**: Always use `with`
6. **Async for I/O**: Use asyncio for network/file operations
7. **Ruff for consistency**: Auto-format and lint
8. **Specific exceptions**: Never bare except
9. **Logging not print**: Use proper logging
10. **Immutability when possible**: frozen dataclasses, Final types

Use this skill for idiomatic, type-safe, well-tested Python development.
