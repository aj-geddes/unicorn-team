# Python Tooling Configuration

Complete guide to modern Python development tools.

## Ruff - Linting and Formatting

Ruff replaces Black, isort, flake8, pyupgrade, and more.

### Basic Configuration

```toml
# pyproject.toml
[tool.ruff]
line-length = 88
target-version = "py310"
src = ["src", "tests"]
extend-exclude = [
    ".git",
    ".venv",
    "__pycache__",
    "build",
    "dist",
]

# Linting rules
[tool.ruff.lint]
select = [
    "E",     # pycodestyle errors
    "W",     # pycodestyle warnings
    "F",     # pyflakes
    "I",     # isort
    "N",     # pep8-naming
    "UP",    # pyupgrade
    "B",     # flake8-bugbear
    "C4",    # flake8-comprehensions
    "SIM",   # flake8-simplify
    "TCH",   # flake8-type-checking
    "RUF",   # Ruff-specific rules
    "PT",    # flake8-pytest-style
    "Q",     # flake8-quotes
    "ARG",   # flake8-unused-arguments
    "PL",    # Pylint
    "PERF",  # Performance anti-patterns
]

ignore = [
    "E501",    # Line too long (handled by formatter)
    "PLR0913", # Too many arguments
    "PLR2004", # Magic value comparison
]

# Per-file ignores
[tool.ruff.lint.per-file-ignores]
"__init__.py" = ["F401"]  # Unused imports OK in __init__
"tests/*" = ["ARG001"]    # Unused arguments OK in tests

# Import sorting (isort replacement)
[tool.ruff.lint.isort]
known-first-party = ["myapp"]
force-single-line = false
lines-after-imports = 2
section-order = [
    "future",
    "standard-library",
    "third-party",
    "first-party",
    "local-folder",
]

[tool.ruff.lint.isort.sections]
"first-party" = ["myapp"]

# Formatting
[tool.ruff.format]
quote-style = "double"
indent-style = "space"
skip-magic-trailing-comma = false
line-ending = "auto"
docstring-code-format = true
docstring-code-line-length = 60

# Type checking mode
[tool.ruff.lint.flake8-type-checking]
strict = true

# Pylint settings
[tool.ruff.lint.pylint]
max-args = 5
max-branches = 12
max-returns = 6
max-statements = 50
```

### Advanced Rules

```toml
# Enable more strict rules
[tool.ruff.lint]
select = [
    # All previous rules...
    "A",     # flake8-builtins (shadowing builtins)
    "ANN",   # flake8-annotations (require type hints)
    "ASYNC", # flake8-async
    "BLE",   # flake8-blind-except
    "COM",   # flake8-commas
    "C90",   # mccabe complexity
    "DTZ",   # flake8-datetimez (timezone aware)
    "ERA",   # eradicate (commented code)
    "EXE",   # flake8-executable
    "FBT",   # flake8-boolean-trap
    "ICN",   # flake8-import-conventions
    "INP",   # flake8-no-pep420
    "ISC",   # flake8-implicit-str-concat
    "PIE",   # flake8-pie
    "PYI",   # flake8-pyi
    "RSE",   # flake8-raise
    "RET",   # flake8-return
    "SLF",   # flake8-self
    "SLOT",  # flake8-slots
    "T10",   # flake8-debugger
    "T20",   # flake8-print
    "TID",   # flake8-tidy-imports
    "TRY",   # tryceratops (exception handling)
    "FLY",   # flynt (f-string conversion)
    "NPY",   # NumPy-specific rules
    "PD",    # pandas-vet
    "LOG",   # flake8-logging
]

# Fine-tune specific rule categories
[tool.ruff.lint.flake8-annotations]
allow-star-arg-any = true
mypy-init-return = true
suppress-dummy-args = true

[tool.ruff.lint.flake8-bugbear]
extend-immutable-calls = ["fastapi.Depends", "fastapi.Query"]

[tool.ruff.lint.mccabe]
max-complexity = 10

[tool.ruff.lint.flake8-tidy-imports]
ban-relative-imports = "all"

[tool.ruff.lint.pydocstyle]
convention = "google"  # or "numpy", "pep257"
```

### Usage

```bash
# Lint code
ruff check .

# Fix auto-fixable issues
ruff check --fix .

# Format code
ruff format .

# Both in one command
ruff check --fix . && ruff format .

# Check specific files
ruff check myapp/core.py

# Show fixes without applying
ruff check --diff .

# Output formats
ruff check --output-format=json .
ruff check --output-format=github .  # For GitHub Actions

# Watch mode
ruff check --watch .

# Explain a rule
ruff rule F401
```

### Pre-commit Hook

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.1.9
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
```

## Mypy - Type Checking

### Strict Configuration

```toml
# pyproject.toml
[tool.mypy]
python_version = "3.10"
strict = true
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
disallow_any_generics = true
disallow_subclassing_any = true
disallow_untyped_calls = true
disallow_incomplete_defs = true
check_untyped_defs = true
disallow_untyped_decorators = true
warn_redundant_casts = true
warn_unused_ignores = true
warn_no_return = true
warn_unreachable = true
strict_equality = true
strict_concatenate = true

# Import discovery
namespace_packages = true
explicit_package_bases = true
mypy_path = "src"
files = ["src", "tests"]
exclude = [
    "build",
    "dist",
]

# Error messages
show_error_codes = true
show_error_context = true
show_column_numbers = true
show_traceback = true
pretty = true

# Per-module options
[[tool.mypy.overrides]]
module = "tests.*"
disallow_untyped_defs = false
disallow_untyped_calls = false

[[tool.mypy.overrides]]
module = "third_party_lib.*"
ignore_missing_imports = true

[[tool.mypy.overrides]]
module = "myapp.legacy.*"
strict = false
disallow_untyped_defs = false
```

### Gradual Typing

```toml
# Start with basic type checking
[tool.mypy]
python_version = "3.10"
warn_return_any = false
warn_unused_configs = true
disallow_untyped_defs = false  # Allow gradual adoption

# Incremental strictness per module
[[tool.mypy.overrides]]
module = "myapp.new_module.*"
strict = true

[[tool.mypy.overrides]]
module = "myapp.core.*"
disallow_untyped_defs = true

[[tool.mypy.overrides]]
module = "myapp.legacy.*"
ignore_errors = true  # Temporarily ignore
```

### Plugin Support

```toml
[tool.mypy]
plugins = [
    "pydantic.mypy",
    "sqlalchemy.ext.mypy.plugin",
]

# Pydantic plugin
[tool.pydantic-mypy]
init_forbid_extra = true
init_typed = true
warn_required_dynamic_aliases = true

# Django plugin
[tool.django-stubs]
django_settings_module = "myapp.settings"
```

### Usage

```bash
# Type check
mypy .

# Check specific files
mypy myapp/core.py

# Show error codes
mypy --show-error-codes .

# Generate HTML report
mypy --html-report ./mypy-report .

# Check coverage
mypy --html-report ./mypy-report --any-exprs-report ./mypy-report .

# Incremental mode (default, faster)
mypy .

# No incremental (clean check)
mypy --no-incremental .

# Install type stubs
mypy --install-types

# Daemon mode (even faster)
dmypy run -- myapp/

# Show column numbers
mypy --show-column-numbers .
```

## Poetry - Dependency Management

### Project Setup

```bash
# Create new project
poetry new myproject
cd myproject

# Or initialize in existing directory
poetry init

# Project structure created:
# myproject/
#   pyproject.toml
#   README.md
#   myproject/
#     __init__.py
#   tests/
#     __init__.py
```

### pyproject.toml

```toml
[tool.poetry]
name = "myapp"
version = "0.1.0"
description = "My application"
authors = ["Your Name <you@example.com>"]
readme = "README.md"
license = "MIT"
homepage = "https://myapp.com"
repository = "https://github.com/user/myapp"
documentation = "https://docs.myapp.com"
keywords = ["api", "web"]
classifiers = [
    "Development Status :: 4 - Beta",
    "Intended Audience :: Developers",
    "Programming Language :: Python :: 3.10",
]

# Package configuration
packages = [{include = "myapp", from = "src"}]
include = ["CHANGELOG.md"]
exclude = ["tests", "docs"]

[tool.poetry.dependencies]
python = "^3.10"
requests = "^2.31.0"
pydantic = "^2.0.0"
fastapi = "^0.104.0"

# Optional dependencies
psycopg2 = {version = "^2.9", optional = true}
redis = {version = "^5.0", optional = true}

[tool.poetry.group.dev.dependencies]
pytest = "^7.4.0"
pytest-cov = "^4.1.0"
pytest-asyncio = "^0.21.0"
ruff = "^0.1.0"
mypy = "^1.5.0"
pre-commit = "^3.5.0"

[tool.poetry.group.docs]
optional = true

[tool.poetry.group.docs.dependencies]
mkdocs = "^1.5.0"
mkdocs-material = "^9.4.0"

# Extras (pip install myapp[postgres])
[tool.poetry.extras]
postgres = ["psycopg2"]
redis = ["redis"]
all = ["psycopg2", "redis"]

# Scripts
[tool.poetry.scripts]
myapp = "myapp.cli:main"
migrate = "myapp.db:migrate"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
```

### Usage

```bash
# Install dependencies
poetry install

# Install with extras
poetry install --extras "postgres redis"

# Install without dev dependencies
poetry install --only main

# Add dependency
poetry add requests
poetry add --group dev pytest

# Update dependencies
poetry update
poetry update requests  # Update specific package

# Remove dependency
poetry remove requests

# Show dependencies
poetry show
poetry show --tree  # Dependency tree
poetry show requests  # Details for package

# Lock dependencies (update lock file)
poetry lock
poetry lock --no-update  # Don't update versions

# Run command in virtualenv
poetry run python script.py
poetry run pytest
poetry run mypy .

# Activate virtualenv
poetry shell

# Build package
poetry build

# Publish to PyPI
poetry publish

# Version bump
poetry version patch  # 0.1.0 -> 0.1.1
poetry version minor  # 0.1.0 -> 0.2.0
poetry version major  # 0.1.0 -> 1.0.0

# Export requirements.txt (for compatibility)
poetry export -f requirements.txt --output requirements.txt
poetry export --only dev -f requirements.txt --output requirements-dev.txt
```

### Poetry Configuration

```bash
# Configure PyPI credentials
poetry config pypi-token.pypi my-token

# Use custom package source
poetry source add private https://pypi.org/simple/

# Virtualenv in project directory
poetry config virtualenvs.in-project true

# Show config
poetry config --list

# Parallel installation
poetry config installer.parallel true
```

## Pre-commit Hooks

```yaml
# .pre-commit-config.yaml
repos:
  # Ruff for linting and formatting
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.1.9
    hooks:
      - id: ruff
        args: [--fix, --exit-non-zero-on-fix]
      - id: ruff-format

  # Mypy for type checking
  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.7.0
    hooks:
      - id: mypy
        additional_dependencies: [types-requests, types-PyYAML]
        args: [--strict]

  # General hooks
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-json
      - id: check-toml
      - id: check-added-large-files
        args: [--maxkb=500]
      - id: check-merge-conflict
      - id: check-case-conflict
      - id: detect-private-key
      - id: mixed-line-ending

  # Security checks
  - repo: https://github.com/PyCQA/bandit
    rev: 1.7.5
    hooks:
      - id: bandit
        args: [-c, pyproject.toml]
        additional_dependencies: ["bandit[toml]"]

  # Commit message format
  - repo: https://github.com/commitizen-tools/commitizen
    rev: 3.12.0
    hooks:
      - id: commitizen
        stages: [commit-msg]

  # Sort requirements.txt
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: requirements-txt-fixer

# Install hooks
# pre-commit install

# Run manually
# pre-commit run --all-files

# Update hooks
# pre-commit autoupdate
```

## Bandit - Security Scanner

```toml
# pyproject.toml
[tool.bandit]
targets = ["src"]
exclude_dirs = ["/tests", "/build", "/dist"]
skips = ["B101"]  # Skip assert_used (OK in tests)

# Severity levels: LOW, MEDIUM, HIGH
[tool.bandit.assert_used]
skips = ["*_test.py", "test_*.py"]
```

```bash
# Scan codebase
bandit -r myapp/

# Exclude directories
bandit -r myapp/ -x tests/,build/

# Output formats
bandit -r myapp/ -f json -o report.json
bandit -r myapp/ -f html -o report.html

# Severity filtering
bandit -r myapp/ -ll  # Only medium and high severity

# Confidence filtering
bandit -r myapp/ -iii  # Only high confidence
```

## Coverage.py

```toml
# pyproject.toml or .coveragerc
[tool.coverage.run]
source = ["myapp"]
branch = true
parallel = true
omit = [
    "*/tests/*",
    "*/migrations/*",
    "*/__init__.py",
    "*/conftest.py",
]

[tool.coverage.report]
precision = 2
show_missing = true
skip_covered = false
exclude_lines = [
    "pragma: no cover",
    "def __repr__",
    "raise AssertionError",
    "raise NotImplementedError",
    "if __name__ == .__main__.:",
    "if TYPE_CHECKING:",
    "class .*\\(Protocol\\):",
    "@(abc\\.)?abstractmethod",
]

[tool.coverage.html]
directory = "htmlcov"
```

```bash
# Run with pytest
pytest --cov=myapp --cov-report=html

# Combine parallel runs
coverage combine

# Generate report
coverage report
coverage html

# Check threshold
coverage report --fail-under=80
```

## tox - Multi-environment Testing

```toml
# pyproject.toml
[tool.tox]
legacy_tox_ini = """
[tox]
envlist = py310,py311,py312,lint,type
isolated_build = True

[testenv]
deps =
    pytest
    pytest-cov
commands =
    pytest --cov=myapp --cov-report=term-missing

[testenv:lint]
deps = ruff
commands = ruff check .

[testenv:type]
deps = mypy
commands = mypy .

[testenv:docs]
deps = mkdocs
commands = mkdocs build
"""
```

```bash
# Run all environments
tox

# Run specific environment
tox -e py310
tox -e lint

# Parallel execution
tox -p auto
```

## Makefile for Common Tasks

```makefile
.PHONY: help install test lint type format clean

help:
	@echo "Available commands:"
	@echo "  install  - Install dependencies"
	@echo "  test     - Run tests with coverage"
	@echo "  lint     - Run linter"
	@echo "  type     - Run type checker"
	@echo "  format   - Format code"
	@echo "  clean    - Clean build artifacts"

install:
	poetry install

test:
	poetry run pytest --cov=myapp --cov-report=html --cov-report=term

lint:
	poetry run ruff check .

lint-fix:
	poetry run ruff check --fix .

type:
	poetry run mypy .

format:
	poetry run ruff format .

all: lint-fix format type test

clean:
	rm -rf build dist *.egg-info
	rm -rf .pytest_cache .mypy_cache .ruff_cache
	rm -rf htmlcov .coverage
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete

watch:
	poetry run ptw -- --cov=myapp
```

## VS Code Configuration

```json
// .vscode/settings.json
{
  "python.defaultInterpreterPath": ".venv/bin/python",
  "python.testing.pytestEnabled": true,
  "python.testing.unittestEnabled": false,

  // Ruff
  "[python]": {
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.fixAll": true,
      "source.organizeImports": true
    },
    "editor.defaultFormatter": "charliermarsh.ruff"
  },

  // Mypy
  "python.linting.mypyEnabled": true,
  "python.linting.mypyArgs": [
    "--strict"
  ],

  // Other settings
  "files.exclude": {
    "**/__pycache__": true,
    "**/*.pyc": true,
    ".pytest_cache": true,
    ".mypy_cache": true,
    ".ruff_cache": true
  },

  "python.analysis.typeCheckingMode": "strict",
  "python.analysis.autoImportCompletions": true
}
```

## GitHub Actions CI

```yaml
# .github/workflows/test.yml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ["3.10", "3.11", "3.12"]

    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: ${{ matrix.python-version }}

      - name: Install Poetry
        uses: snok/install-poetry@v1

      - name: Install dependencies
        run: poetry install

      - name: Lint
        run: poetry run ruff check .

      - name: Type check
        run: poetry run mypy .

      - name: Test
        run: poetry run pytest --cov=myapp --cov-report=xml

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage.xml
```

## Best Practices

1. **Use pyproject.toml**: Centralize configuration
2. **Pin dependencies**: Lock file for reproducibility
3. **Separate dev/prod dependencies**: Use groups/extras
4. **Run checks locally**: Pre-commit hooks
5. **Enforce coverage**: Fail builds below threshold
6. **Type check strictly**: Enable strict mode
7. **Keep configs minimal**: Use defaults when possible
8. **Update regularly**: Run `poetry update` and `pre-commit autoupdate`
9. **Document scripts**: Makefile or justfile for common tasks
10. **CI/CD integration**: Automate all checks
