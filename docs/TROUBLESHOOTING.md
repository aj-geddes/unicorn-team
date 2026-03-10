# Troubleshooting Guide

This guide covers common issues you may encounter when using the 10X Developer Unicorn system and how to resolve them.

## Table of Contents

1. [Installation Issues](#installation-issues)
2. [Pre-commit Hook Issues](#pre-commit-hook-issues)
3. [TDD Script Issues](#tdd-script-issues)
4. [Self-Review Script Issues](#self-review-script-issues)
5. [Estimation Script Issues](#estimation-script-issues)
6. [Language Learning Script Issues](#language-learning-script-issues)
7. [General Debugging](#general-debugging)

---

## Installation Issues

### Issue: "Permission denied" when running scripts

**Symptom:**
```bash
$ ./scripts/tdd.sh my-feature
bash: ./scripts/tdd.sh: Permission denied
```

**Cause:** Scripts are not marked as executable.

**Solution:**
```bash
# Make all scripts executable
chmod +x scripts/*.sh

# Or make a specific script executable
chmod +x scripts/tdd.sh
```

**Prevention:** The install script should handle this automatically. If you added scripts manually, run:
```bash
find scripts/ -name "*.sh" -exec chmod +x {} \;
```

---

### Issue: Missing dependencies (pytest, ruff, mypy)

**Symptom:**
```bash
$ pytest tests/
bash: pytest: command not found
```

**Cause:** Python dependencies not installed.

**Solution:**
```bash
# Install with pip
pip install pytest pytest-cov ruff mypy

# Or if using a virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install pytest pytest-cov ruff mypy
```

**For project-based installation:**
```bash
# If you have a requirements.txt
pip install -r requirements.txt

# Or install from pyproject.toml
pip install -e .
```

---

### Issue: Hook not running

**Symptom:**
- You commit code with TODOs or failing tests, but hook doesn't stop you
- No output from pre-commit hook

**Cause:** Hook not installed or not executable.

**Solution:**
```bash
# Check if hook exists
ls -la .git/hooks/pre-commit

# If missing, install the plugin (which wires hooks automatically)
claude plugin install aj-geddes/unicorn-team

# If exists but not executable
chmod +x .git/hooks/pre-commit

# Verify hook is installed
cat .git/hooks/pre-commit
```

**Testing the hook:**
```bash
# Test hook directly
.git/hooks/pre-commit

# If it doesn't run, check shebang
head -n 1 .git/hooks/pre-commit
# Should be: #!/bin/bash
```

---

## Pre-commit Hook Issues

### Issue: Tests failing in hook

**Symptom:**
```bash
Running tests...
FAILED tests/test_feature.py::test_something
Error: Tests failed. Commit aborted.
```

**Cause:** Your code has failing tests.

**Solution:**
```bash
# Run tests to see details
pytest -v

# Fix the failing tests, then try commit again
git add .
git commit -m "fix: resolve test failures"
```

**Bypass (use sparingly):**
```bash
# Only if you're committing work-in-progress to a feature branch
git commit --no-verify -m "wip: partial implementation"
```

**When bypassing is OK:**
- Committing to a feature branch (not main)
- Saving work-in-progress
- Emergency hotfix (fix tests in next commit)

**When bypassing is NOT OK:**
- Merging to main
- Creating a pull request
- Releasing code

---

### Issue: Coverage below threshold

**Symptom:**
```bash
Running tests with coverage...
FAILED: Coverage 72% is below threshold of 80%
```

**Cause:** Your new code doesn't have sufficient test coverage.

**Solution:**
```bash
# Check which lines are not covered
pytest --cov=. --cov-report=html
# Open htmlcov/index.html in browser to see missing coverage

# Add tests for uncovered code
# Then verify coverage
pytest --cov=. --cov-report=term-missing

# Commit once coverage is above threshold
```

**Adjust threshold temporarily (not recommended):**
```bash
# Edit hooks/pre-commit
# Change: COVERAGE_THRESHOLD=80
# To:     COVERAGE_THRESHOLD=70

# But add a TODO to increase it back
```

---

### Issue: Secrets detection false positives

**Symptom:**
```bash
Error: Possible secrets detected in staged files:
path/to/file.py:15: API_KEY = "example_key_for_documentation"
```

**Cause:** Hook detects strings that look like secrets but are actually examples or test data.

**Solution:**

**Option 1: Rename the variable**
```python
# Instead of:
API_KEY = "example_key"

# Use:
EXAMPLE_API_KEY = "example_key"  # Example only, not a real key
```

**Option 2: Move to test fixtures**
```python
# In tests/conftest.py
@pytest.fixture
def mock_api_key():
    return "test_key_12345"
```

**Option 3: Whitelist in hook (if genuinely safe)**
```bash
# Edit hooks/pre-commit
# Add to the secrets check exclusions:
grep -rn "API_KEY\|SECRET\|PASSWORD\|TOKEN" "$STAGED" | \
  grep -v "test_" | \
  grep -v "example_" | \
  grep -v "mock_"
```

---

### Issue: How to bypass (--no-verify) and when it's OK

**Using --no-verify:**
```bash
git commit --no-verify -m "your message"
```

**When it's acceptable:**
1. **Work-in-progress commits** on feature branches
   ```bash
   git commit --no-verify -m "wip: exploring new approach"
   ```

2. **Documentation-only changes** (if hook incorrectly flags them)
   ```bash
   git commit --no-verify -m "docs: update README"
   ```

3. **Emergency hotfix** (but fix quality in next commit)
   ```bash
   git commit --no-verify -m "hotfix: patch critical security issue"
   git commit -m "test: add coverage for hotfix"
   ```

**When it's NOT acceptable:**
1. Merging to main branch
2. Creating pull requests
3. Releasing/deploying code
4. Bypassing due to laziness

**Best practice:**
```bash
# Instead of bypassing, use fixup commits
git commit -m "wip: partial feature"
# Later, when tests pass:
git commit --fixup HEAD
git rebase -i --autosquash
```

---

## TDD Script Issues

### Issue: Wrong language detected

**Symptom:**
```bash
$ ./scripts/tdd.sh my_feature
Detected language: python
Created: tests/test_my_feature.py
# But you wanted JavaScript tests
```

**Cause:** Script detects language based on existing files in directory.

**Solution:**
```bash
# Specify language explicitly (future enhancement)
# For now, edit scripts/tdd.sh:

# Find this section:
detect_language() {
  # Add your preferred language at the top
  if [ -f "package.json" ]; then
    echo "javascript"
    return
  fi
  # ... rest of detection
}

# Or run in subdirectory with target language files
cd src/javascript
../../scripts/tdd.sh my_feature
```

---

### Issue: Test file in wrong location

**Symptom:**
```bash
Created: tests/test_my_feature.py
# But your project uses: tests/unit/test_my_feature.py
```

**Cause:** Script uses default test directory structure.

**Solution:**
```bash
# Edit scripts/tdd.sh to match your structure:

# Find TEST_DIR variable
TEST_DIR="tests"

# Change to:
TEST_DIR="tests/unit"

# Or for JavaScript:
TEST_DIR="src/__tests__"
```

---

### Issue: RED phase passes when it shouldn't

**Symptom:**
```bash
RED: Writing failing test...
Running tests...
All tests passed
ERROR: Tests should FAIL in RED phase
```

**Cause:** You wrote a test that passes without implementation, or implementation already exists.

**Solution:**
```bash
# Check if implementation already exists
ls src/ | grep my_feature

# If implementation exists, delete or rename it
mv src/my_feature.py src/my_feature.py.bak

# Or write a more specific test that requires new code
# Edit the test file to assert something not yet implemented
```

**Example of proper RED test:**
```python
# This will fail because function doesn't exist yet
def test_calculate_fibonacci():
    assert calculate_fibonacci(5) == 5
    assert calculate_fibonacci(10) == 55
```

---

## Self-Review Script Issues

### Issue: No staged changes detected

**Symptom:**
```bash
$ ./scripts/self-review.sh
No staged changes found. Use: git add <files>
```

**Cause:** You haven't staged any changes for commit.

**Solution:**
```bash
# Stage your changes first
git add src/my_file.py tests/test_my_file.py

# Then run self-review
./scripts/self-review.sh

# Or stage everything
git add .
./scripts/self-review.sh
```

---

### Issue: Debug code false positives

**Symptom:**
```bash
Warning: Debug code detected:
src/calculator.py:45: debugger()
# But it's actually: # debugger() - commented out
```

**Cause:** Script checks for debug patterns without considering comments.

**Solution:**

**Immediate fix:**
```bash
# Remove or refine the debug statement
# Instead of: debugger()
# Use proper logging:
import logging
logging.debug("Calculation result: %s", result)
```

**Update script to ignore comments:**
```bash
# Edit scripts/self-review.sh
# Change the grep pattern:
grep -rn "console\.log\|debugger\|pdb\.set_trace\|print(" "$STAGED" | \
  grep -v "^\s*#" | \
  grep -v "^\s*//"
```

---

### Issue: Tests not found

**Symptom:**
```bash
Running tests...
ERROR: No tests found
```

**Cause:** Script can't locate test files, or they're not in expected location.

**Solution:**
```bash
# Check test file location
find . -name "test_*.py" -o -name "*_test.py"

# Verify test directory structure
ls -R tests/

# Update self-review.sh to match your structure
# Edit TEST_PATH variable:
TEST_PATH="tests"  # Change to your test directory

# Or specify explicitly when running
TEST_PATH="src/__tests__" ./scripts/self-review.sh
```

---

## Estimation Script Issues

### Issue: Invalid number input

**Symptom:**
```bash
$ ./scripts/estimate.sh
How many stories? abc
Error: Invalid number
```

**Cause:** Non-numeric input provided.

**Solution:**
```bash
# Provide numeric input
$ ./scripts/estimate.sh
How many stories? 5
How many known unknowns? 2
How many unknown unknowns? 1
```

**Automation:**
```bash
# Pass estimates via environment variables (if script supports)
STORIES=5 KNOWN_UNKNOWNS=2 UNKNOWN_UNKNOWNS=1 ./scripts/estimate.sh

# Or use heredoc for batch input
./scripts/estimate.sh << EOF
5
2
1
EOF
```

---

### Issue: Output file permissions

**Symptom:**
```bash
Error: Cannot write to estimates/project-estimate.md: Permission denied
```

**Cause:** No write permission on output directory.

**Solution:**
```bash
# Check directory permissions
ls -la estimates/

# Create directory if missing
mkdir -p estimates

# Fix permissions
chmod 755 estimates

# Or write to a different location
OUTPUT_DIR="$HOME/estimates" ./scripts/estimate.sh
```

---

## Language Learning Script Issues

### Issue: Unknown language extension

**Symptom:**
```bash
$ ./scripts/new-language.sh kotlin
Error: Unknown language: kotlin
```

**Cause:** Language not configured in script.

**Solution:**
```bash
# Edit scripts/new-language.sh
# Add to the case statement:

case "$LANGUAGE" in
  kotlin)
    EXTENSION="kt"
    TEST_FRAMEWORK="JUnit"
    PACKAGE_MANAGER="gradle"
    ;;
  # ... other languages
```

**Or request enhancement:**
```bash
# Create an issue or add to TODO
# For now, use closest equivalent
./scripts/new-language.sh java  # Similar JVM language
```

---

### Issue: Resume not working

**Symptom:**
```bash
$ ./scripts/new-language.sh python
Starting from scratch (no progress found)
# But you already completed basics
```

**Cause:** Progress file not found or corrupted.

**Solution:**
```bash
# Check progress file location
ls -la .10x-learning/python/

# Check progress file contents
cat .10x-learning/python/progress.txt

# Manually set progress
echo "COMPLETED: basics, syntax, testing" > .10x-learning/python/progress.txt

# Or restart learning path
rm -rf .10x-learning/python/
./scripts/new-language.sh python
```

---

### Issue: Templates not created

**Symptom:**
```bash
$ ./scripts/new-language.sh rust
Created learning directory
# But skills/rust/ is empty
```

**Cause:** Template creation failed or was skipped.

**Solution:**
```bash
# Check for error messages in script output
./scripts/new-language.sh rust 2>&1 | tee debug.log

# Manually create template structure
mkdir -p skills/rust
cat > skills/rust/SKILL.md << 'EOF'
---
name: rust
description: Rust language fundamentals, ownership, borrowing, and cargo
---

# Rust Programming Skill

## Overview
[Content to be filled during learning]
EOF

# Re-run with verbose mode (if supported)
bash -x ./scripts/new-language.sh rust
```

---

## General Debugging

### How to run scripts in debug mode

**Enable bash debug output:**
```bash
# Method 1: Use bash -x
bash -x ./scripts/tdd.sh my_feature

# Method 2: Set xtrace in script
# Add to top of script:
set -x  # Enable debug output
set -e  # Exit on error
set -u  # Exit on undefined variable

# Method 3: Add DEBUG variable
DEBUG=1 ./scripts/tdd.sh my_feature
```

**Add debugging to scripts:**
```bash
# Add to script:
if [ "${DEBUG:-0}" = "1" ]; then
  set -x
fi

# Then run with:
DEBUG=1 ./scripts/tdd.sh my_feature
```

---

### Checking script permissions

**Check if script is executable:**
```bash
# List with permissions
ls -l scripts/

# Should show 'x' in permissions:
# -rwxr-xr-x  1 user group 1234 Jan 01 12:00 tdd.sh

# Check specific script
test -x scripts/tdd.sh && echo "Executable" || echo "Not executable"

# Make all scripts executable
chmod +x scripts/*.sh

# Verify shebang line
head -n 1 scripts/*.sh
# Each should show: #!/bin/bash or #!/usr/bin/env bash
```

---

### Verifying Git hooks installation

**Check hook exists and is executable:**
```bash
# List hooks
ls -la .git/hooks/

# Check pre-commit hook
cat .git/hooks/pre-commit

# Verify it's executable
test -x .git/hooks/pre-commit && echo "OK" || echo "Not executable"

# Test hook directly
.git/hooks/pre-commit
```

**Reinstall hooks if needed:**
```bash
# Backup existing hooks
cp -r .git/hooks .git/hooks.backup

# Copy from hooks/ directory
cp hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# Or reinstall the plugin (which rewires hooks)
claude plugin install aj-geddes/unicorn-team
```

**Check if hook is being called:**
```bash
# Add debug output to hook
# Edit .git/hooks/pre-commit, add at top:
echo "PRE-COMMIT HOOK RUNNING" >&2

# Try to commit
git commit -m "test"
# You should see: PRE-COMMIT HOOK RUNNING
```

---

## Getting More Help

### Enable verbose logging

Add to any script:
```bash
set -x  # Print commands as they execute
set -v  # Print commands as they're read
```

### Check environment

```bash
# Verify paths
echo $PATH
which python
which pytest

# Check Git configuration
git config --list

# Check shell
echo $SHELL
bash --version
```

### Common diagnostic commands

```bash
# Show what would be committed
git diff --cached --stat

# Show hook execution
GIT_TRACE=1 git commit -m "test"

# Test hook in isolation
bash -x .git/hooks/pre-commit

# Check Python environment
python --version
pip list | grep pytest

# Verify test discovery
pytest --collect-only
```

### Report issues

If you encounter a bug not covered here:

1. **Gather information:**
   ```bash
   # System info
   uname -a
   bash --version
   python --version

   # Script output
   bash -x ./scripts/problematic-script.sh 2>&1 | tee error.log
   ```

2. **Check existing issues:** Review project issues/discussions

3. **Create minimal reproduction:** Simplify to smallest failing case

4. **Document:**
   - What you expected
   - What actually happened
   - Steps to reproduce
   - Environment details
   - Error output

---

## Quick Reference

### Most Common Fixes

```bash
# Scripts not executable
chmod +x scripts/*.sh

# Hooks not running
claude plugin install aj-geddes/unicorn-team

# Tests failing
pytest -v  # See details
pytest --lf  # Run only last failed

# Coverage too low
pytest --cov=. --cov-report=html
# Open htmlcov/index.html

# Debug any script
bash -x ./scripts/script-name.sh

# Validate plugin structure
./scripts/validate.sh

# Reinstall plugin
claude plugin install aj-geddes/unicorn-team
```

### Emergency Bypass

```bash
# Use only when absolutely necessary
git commit --no-verify -m "emergency: reason"

# Then immediately fix and commit properly
# Add tests, fix coverage, etc.
git commit -m "test: add coverage for emergency commit"
```

---

## Prevention Tips

1. **Run self-review before committing:**
   ```bash
   ./scripts/self-review.sh
   ```

2. **Keep hooks updated:**
   ```bash
   git pull
   claude plugin install aj-geddes/unicorn-team
   ```

3. **Test in isolation first:**
   ```bash
   pytest tests/test_specific.py -v
   ```

4. **Use TDD script for new features:**
   ```bash
   ./scripts/tdd.sh feature-name
   ```

5. **Check coverage regularly:**
   ```bash
   pytest --cov=. --cov-report=term-missing
   ```

---

Remember: The quality gates exist to help you, not hinder you. If you find yourself bypassing them frequently, that's a signal to either fix your workflow or improve the tooling.
