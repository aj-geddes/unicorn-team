---
name: python
description: >-
  Guides Python development with modern idioms, tooling, and project structure.
  ALWAYS trigger on "python project", "pyproject.toml", "ruff", "mypy",
  "pytest", "poetry", "python setup", "type hints", "pydantic", "dataclass",
  "async python", "asyncio", "python anti-pattern", "python best practices",
  "python tooling", "python lint". Use when setting up Python projects,
  configuring tooling, choosing data modeling approaches, or writing tests.
  Different from testing skill which covers general test strategy; this covers
  Python-specific pytest patterns and tooling configs.
---
<!-- Last reviewed: 2026-03 -->

# Python Domain Skill

## Modern Type Hints (3.10+)

```python
# Union with | operator
def process(value: int | str | None) -> dict[str, int]: ...

# Type aliases
type UserID = int
type Config = dict[str, str | int | bool]

# See references/type-hints-advanced.md for:
# - Generics and TypeVars
# - Protocols (structural typing)
# - Function overloading
```

## Testing with Pytest

```python
# Fixtures
@pytest.fixture
def sample_user():
    return {"name": "Alice", "email": "alice@example.com"}

# Parametrize
@pytest.mark.parametrize("input,expected", [
    (0, 0), (1, 1), (2, 4),
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

**See references/testing-pytest.md for** advanced fixtures, mocking patterns, markers, plugins.

## Tooling

### Ruff (Linting + Formatting)

Replaces Black, isort, flake8, pyupgrade.

```bash
ruff check --fix . && ruff format .
```

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

```toml
[tool.mypy]
python_version = "3.10"
strict = true
warn_return_any = true
disallow_untyped_defs = true
```

### Poetry (Dependency Management)

```bash
poetry init
poetry add requests
poetry add --group dev pytest pytest-cov ruff mypy
poetry install
poetry run pytest
```

**See references/tooling-config.md for** complete ruff rule sets, mypy options, pre-commit hooks, CI/CD.

## Async Programming

```python
# Concurrent execution
async def fetch_all(urls: list[str]) -> list[dict]:
    return await asyncio.gather(*[fetch_data(url) for url in urls])

# Async context manager
class AsyncDatabase:
    async def __aenter__(self):
        self.connection = await connect()
        return self

    async def __aexit__(self, *args):
        await self.connection.close()
```

**See references/async-patterns.md for** task management, semaphores, queues, error handling, pitfalls.

## Data Modeling

| Use case | Choose | Why |
|----------|--------|-----|
| Internal data, simple containers | `@dataclass` | Stdlib, fast, no deps |
| Performance-critical, immutable | `@dataclass(frozen=True, slots=True)` | Minimal overhead |
| External/untrusted data, APIs | `pydantic.BaseModel` | Auto-validation, serialization |
| Config from environment | `pydantic_settings.BaseSettings` | Env var parsing, type coercion |

```python
# Dataclass: internal data
@dataclass(frozen=True)
class Point:
    x: float
    y: float

# Pydantic: external data with validation
class UserCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    email: EmailStr
    age: int = Field(..., ge=0, le=150)

    @field_validator("email")
    @classmethod
    def normalize_email(cls, v: str) -> str:
        return v.lower().strip()
```

**See references/dataclasses-pydantic.md for** advanced features, nested models, settings, JSON schema.

## Anti-patterns Quick Reference

| Anti-pattern | Fix |
|-------------|-----|
| Mutable default `def f(x=[])` | `def f(x=None)` then `x = x or []` |
| Bare `except:` | `except SpecificError as e:` |
| `== None` / `== True` | `is None` / `is True` |
| Modify list while iterating | List comprehension filter |
| `f = open()` without `with` | `with open() as f:` |
| String concat in loop `+=` | `"".join(...)` |
| Manual index counter | `enumerate()` |
| `type(x) == list` | `isinstance(x, list)` |
| `print()` debugging | `logging.getLogger(__name__)` |
| Star imports `from x import *` | Explicit imports |

## Project Setup Checklist

```bash
# 1. Initialize
poetry init
poetry add <dependencies>
poetry add --group dev pytest pytest-cov ruff mypy pre-commit

# 2. Configure pyproject.toml
# [tool.ruff], [tool.mypy], [tool.pytest.ini_options]

# 3. Install hooks
pre-commit install

# 4. Full quality check
ruff check --fix . && ruff format . && mypy . && pytest --cov=myapp --cov-fail-under=80
```

## Commands

```bash
ruff format . && ruff check --fix .                              # Format + lint
mypy .                                                           # Type check
pytest --cov=myapp --cov-report=term-missing --cov-fail-under=80 # Test + coverage
```

## Reference Files

- **references/type-hints-advanced.md** - Generics, Protocols, TypeVars, overloads, TypedDict
- **references/async-patterns.md** - Task management, queues, synchronization, performance
- **references/testing-pytest.md** - Fixtures, parametrize, mocking, markers, plugins
- **references/tooling-config.md** - ruff, mypy, poetry, pre-commit, bandit configs
- **references/dataclasses-pydantic.md** - Data modeling, validation, serialization, settings
