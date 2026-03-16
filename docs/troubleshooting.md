---
layout: default
title: "Troubleshooting the unicorn-team Claude Code Plugin"
description: "Fix common issues with the unicorn-team Claude Code plugin: installation problems, hook failures, script permissions, test failures, and plugin update errors."
permalink: /troubleshooting/
---

# Troubleshooting

Quick solutions for the most common issues. Each entry follows a Problem / Solution format.

---

## Installation

### Permission denied when running scripts

**Problem**: `bash: ./scripts/tdd.sh: Permission denied`

**Solution**:
```bash
chmod +x scripts/*.sh
```

The install process should handle this automatically. If you added scripts manually, make them executable.

### Missing dependencies (pytest, ruff, mypy)

**Problem**: `bash: pytest: command not found`

**Solution**:
```bash
pip install pytest pytest-cov ruff mypy
```

Or if using a virtual environment:
```bash
python -m venv venv
source venv/bin/activate
pip install pytest pytest-cov ruff mypy
```

---

## Hooks

### Pre-commit hook not running

**Problem**: Commits go through without quality checks. No hook output visible.

**Solution**: Verify the hook exists and is executable.

```bash
# Check if hook exists
ls -la .git/hooks/pre-commit

# If missing, reinstall the plugin
claude plugin install unicorn-team@unicorn-team

# If exists but not executable
chmod +x .git/hooks/pre-commit

# Test the hook directly
.git/hooks/pre-commit
```

### Tests failing in pre-commit hook

**Problem**: `FAILED tests/test_feature.py::test_something -- Commit aborted.`

**Solution**: Fix the failing tests, then commit again.

```bash
# See detailed failures
pytest -v

# Fix the code, then retry
git add .
git commit -m "fix: resolve test failures"
```

**Emergency bypass** (feature branches only):
```bash
git commit --no-verify -m "wip: partial implementation"
```

Never bypass on main, in pull requests, or for releases.

### Coverage below threshold

**Problem**: `FAILED: Coverage 72% is below threshold of 80%`

**Solution**: Add tests for uncovered code.

```bash
# Find uncovered lines
pytest --cov=. --cov-report=term-missing

# Or generate an HTML report
pytest --cov=. --cov-report=html
# Open htmlcov/index.html
```

### Secrets detection false positives

**Problem**: Hook flags example/test values as secrets.

**Solution**: Rename variables to indicate they are not real secrets.

```python
# Instead of:
API_KEY = "example_key"

# Use:
EXAMPLE_API_KEY = "example_key"  # Not a real key
```

Or move test values to fixtures in `tests/conftest.py`.

---

## Scripts

### TDD script: RED phase passes unexpectedly

**Problem**: Tests pass during RED phase when they should fail.

**Solution**: Either the implementation already exists or the test isn't specific enough.

```bash
# Check if implementation exists
ls src/ | grep my_feature

# Write a test that requires code not yet written
def test_specific_behavior():
    assert my_function(edge_case) == expected_result
```

### Self-review: no staged changes detected

**Problem**: `No staged changes found.`

**Solution**: Stage your changes before running self-review.

```bash
git add src/my_file.py tests/test_my_file.py
./skills/self-verification/scripts/self-review.sh
```

### Estimation script: invalid number input

**Problem**: `Error: Invalid number`

**Solution**: Provide numeric values when prompted. The script expects hours as numbers for optimistic, realistic, and pessimistic estimates.

---

## General Debugging

### Debug any script

Run with bash debug output to see exactly what's happening:

```bash
bash -x ./scripts/script-name.sh
```

### Check your environment

```bash
# Verify tools are available
which python && python --version
which pytest && pytest --version

# Verify test discovery
pytest --collect-only

# Check hook execution with git tracing
GIT_TRACE=1 git commit -m "test"
```

### Validate plugin structure

```bash
./scripts/validate.sh
```

This checks that all SKILL.md files have valid frontmatter, scripts are executable, and the directory structure is correct.

---

## Quick Reference

```bash
# Fix script permissions
chmod +x scripts/*.sh

# Reinstall plugin and hooks
claude plugin install unicorn-team@unicorn-team

# See failing test details
pytest -v

# Run only last failed tests
pytest --lf

# Find uncovered lines
pytest --cov=. --cov-report=term-missing

# Debug a script
bash -x ./scripts/script-name.sh

# Validate plugin structure
./scripts/validate.sh
```

---

## Still Stuck?

1. Run the script with `bash -x` to see exactly where it fails
2. Check `python --version` and `pip list | grep pytest`
3. Try reinstalling: `claude plugin install unicorn-team@unicorn-team`
4. Open an issue at [github.com/aj-geddes/unicorn-team](https://github.com/aj-geddes/unicorn-team) with your error output and environment details
