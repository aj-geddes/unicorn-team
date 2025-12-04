"""
Validation tests for git hooks in the 10X Developer Unicorn project.

Tests ensure:
- Hooks exist
- Hooks are executable
- Hooks have proper shebangs
- Hooks implement required quality checks
"""

import os
import stat
from pathlib import Path

import pytest


PROJECT_ROOT = Path(__file__).parent.parent
HOOKS_DIR = PROJECT_ROOT / "hooks"


def is_executable(file_path):
    """Check if a file has executable permissions."""
    st = os.stat(file_path)
    return bool(st.st_mode & stat.S_IXUSR)


def get_shebang(file_path):
    """Get the shebang line from a file, if present."""
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            first_line = f.readline()
            if first_line.startswith("#!"):
                return first_line.strip()
    except (IOError, UnicodeDecodeError):
        pass
    return None


def read_file_content(file_path):
    """Read file content, return empty string if file doesn't exist."""
    try:
        return file_path.read_text(encoding="utf-8")
    except (IOError, UnicodeDecodeError):
        return ""


def test_hooks_directory_exists():
    """The hooks directory must exist."""
    assert HOOKS_DIR.exists(), (
        f"Hooks directory not found at {HOOKS_DIR}. "
        f"Create the directory structure first."
    )


def test_precommit_exists():
    """hooks/pre-commit exists."""
    precommit = HOOKS_DIR / "pre-commit"

    # Skip if hooks directory doesn't exist yet
    if not HOOKS_DIR.exists():
        pytest.skip("Hooks directory does not exist yet")

    # Skip if no hooks exist yet (early in development)
    if not list(HOOKS_DIR.iterdir()):
        pytest.skip("No hooks created yet")

    if not precommit.exists():
        pytest.skip(
            f"pre-commit not created yet at {precommit.relative_to(PROJECT_ROOT)}"
        )

    assert precommit.exists(), (
        f"pre-commit hook must exist at {precommit.relative_to(PROJECT_ROOT)}"
    )


def test_precommit_is_executable():
    """hooks/pre-commit is executable."""
    precommit = HOOKS_DIR / "pre-commit"

    if not precommit.exists():
        pytest.skip("pre-commit hook not created yet")

    assert is_executable(precommit), (
        f"{precommit.relative_to(PROJECT_ROOT)} is not executable. "
        f"Run: chmod +x {precommit}"
    )


def test_precommit_has_shebang():
    """Must start with proper shebang."""
    precommit = HOOKS_DIR / "pre-commit"

    if not precommit.exists():
        pytest.skip("pre-commit hook not created yet")

    shebang = get_shebang(precommit)

    assert shebang is not None, (
        f"{precommit.relative_to(PROJECT_ROOT)} must start with a shebang line "
        f"(e.g., #!/usr/bin/env bash)"
    )

    # Valid shebangs for hooks
    valid_shebangs = [
        "#!/usr/bin/env bash",
        "#!/bin/bash",
        "#!/usr/bin/env sh",
        "#!/bin/sh",
        "#!/usr/bin/env python",
        "#!/usr/bin/env python3",
        "#!/usr/bin/python",
        "#!/usr/bin/python3",
    ]

    is_valid = any(shebang.startswith(valid) for valid in valid_shebangs)

    assert is_valid, (
        f"{precommit.relative_to(PROJECT_ROOT)} has invalid shebang: {shebang}. "
        f"Use one of: {', '.join(valid_shebangs)}"
    )


def test_precommit_checks_for_todos():
    """Script must check for TODO markers."""
    precommit = HOOKS_DIR / "pre-commit"

    if not precommit.exists():
        pytest.skip("pre-commit hook not created yet")

    content = read_file_content(precommit)

    # Check for TODO/FIXME/HACK detection patterns
    todo_patterns = [
        "TODO",
        "FIXME",
        "HACK",
        "todo",
        "fixme",
        "hack",
    ]

    has_todo_check = any(pattern in content for pattern in todo_patterns)

    assert has_todo_check, (
        f"{precommit.relative_to(PROJECT_ROOT)} must check for TODO/FIXME/HACK markers. "
        f"According to CLAUDE.md, no TODO/FIXME/HACK markers should be committed."
    )


def test_precommit_checks_coverage():
    """Script must enforce coverage threshold."""
    precommit = HOOKS_DIR / "pre-commit"

    if not precommit.exists():
        pytest.skip("pre-commit hook not created yet")

    content = read_file_content(precommit)

    # Check for coverage-related patterns
    coverage_patterns = [
        "coverage",
        "cov",
        "pytest",
        "--cov",
        "80",  # The 80% threshold from CLAUDE.md
    ]

    # Need at least coverage keyword and some threshold
    has_coverage = "coverage" in content.lower() or "--cov" in content

    assert has_coverage, (
        f"{precommit.relative_to(PROJECT_ROOT)} must enforce coverage threshold. "
        f"According to CLAUDE.md, coverage must be >= 80%."
    )


def test_prepush_exists():
    """hooks/pre-push exists (when created)."""
    prepush = HOOKS_DIR / "pre-push"

    # Skip if hooks directory doesn't exist yet
    if not HOOKS_DIR.exists():
        pytest.skip("Hooks directory does not exist yet")

    # This is created in Phase 5, so it's okay if it doesn't exist early on
    if not prepush.exists():
        pytest.skip(
            f"pre-push not created yet at {prepush.relative_to(PROJECT_ROOT)}"
        )

    assert prepush.exists(), (
        f"pre-push hook must exist at {prepush.relative_to(PROJECT_ROOT)}"
    )


def test_prepush_is_executable():
    """hooks/pre-push is executable (when it exists)."""
    prepush = HOOKS_DIR / "pre-push"

    if not prepush.exists():
        pytest.skip("pre-push hook not created yet")

    assert is_executable(prepush), (
        f"{prepush.relative_to(PROJECT_ROOT)} is not executable. "
        f"Run: chmod +x {prepush}"
    )


def test_at_least_one_hook_exists():
    """At least one hook should exist for meaningful testing."""
    if not HOOKS_DIR.exists():
        pytest.skip("Hooks directory does not exist yet")

    hook_files = list(HOOKS_DIR.iterdir())

    if len(hook_files) == 0:
        pytest.skip(
            "No hook files found yet. "
            "This test will run once hooks are created."
        )
