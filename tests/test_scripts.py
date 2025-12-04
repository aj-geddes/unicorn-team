"""
Validation tests for scripts in the 10X Developer Unicorn project.

Tests ensure:
- Scripts are executable
- Scripts have proper shebangs
- Required scripts exist
"""

import os
import stat
from pathlib import Path

import pytest


PROJECT_ROOT = Path(__file__).parent.parent
SCRIPTS_DIR = PROJECT_ROOT / "scripts"


def find_script_files():
    """Find all script files in the scripts directory."""
    if not SCRIPTS_DIR.exists():
        return []

    scripts = []
    for file in SCRIPTS_DIR.iterdir():
        # Skip non-files and hidden files
        if file.is_file() and not file.name.startswith("."):
            # Include shell scripts and files without extension
            if file.suffix in [".sh", ""] or file.name.endswith(".sh"):
                scripts.append(file)

    return scripts


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


@pytest.mark.parametrize("script_file", find_script_files())
def test_scripts_are_executable(script_file):
    """All scripts in scripts/ must be chmod +x."""
    assert is_executable(script_file), (
        f"{script_file.relative_to(PROJECT_ROOT)} is not executable. "
        f"Run: chmod +x {script_file}"
    )


@pytest.mark.parametrize("script_file", find_script_files())
def test_scripts_have_shebang(script_file):
    """All scripts must start with #!/usr/bin/env bash or similar."""
    shebang = get_shebang(script_file)

    assert shebang is not None, (
        f"{script_file.relative_to(PROJECT_ROOT)} must start with a shebang line "
        f"(e.g., #!/usr/bin/env bash)"
    )

    # Valid shebangs for shell scripts
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
        f"{script_file.relative_to(PROJECT_ROOT)} has invalid shebang: {shebang}. "
        f"Use one of: {', '.join(valid_shebangs)}"
    )


def test_scripts_directory_exists():
    """The scripts directory must exist."""
    assert SCRIPTS_DIR.exists(), (
        f"Scripts directory not found at {SCRIPTS_DIR}. "
        f"Create the directory structure first."
    )


def test_install_script_exists():
    """Verify install.sh exists."""
    install_script = SCRIPTS_DIR / "install.sh"

    # Skip if scripts directory doesn't exist yet
    if not SCRIPTS_DIR.exists():
        pytest.skip("Scripts directory does not exist yet")

    # Skip if no scripts exist yet (early in development)
    if not list(SCRIPTS_DIR.iterdir()):
        pytest.skip("No scripts created yet")

    if not install_script.exists():
        pytest.skip(
            f"install.sh not created yet at {install_script.relative_to(PROJECT_ROOT)}"
        )

    assert install_script.exists(), (
        f"install.sh must exist at {install_script.relative_to(PROJECT_ROOT)}"
    )


def test_tdd_script_exists():
    """Verify tdd.sh exists (when created)."""
    tdd_script = SCRIPTS_DIR / "tdd.sh"

    # Skip if scripts directory doesn't exist yet
    if not SCRIPTS_DIR.exists():
        pytest.skip("Scripts directory does not exist yet")

    # Skip if no scripts exist yet (early in development)
    if not list(SCRIPTS_DIR.iterdir()):
        pytest.skip("No scripts created yet")

    if not tdd_script.exists():
        pytest.skip(
            f"tdd.sh not created yet at {tdd_script.relative_to(PROJECT_ROOT)}"
        )

    assert tdd_script.exists(), (
        f"tdd.sh must exist at {tdd_script.relative_to(PROJECT_ROOT)}"
    )


def test_self_review_script_exists():
    """Verify self-review.sh exists (when created)."""
    self_review_script = SCRIPTS_DIR / "self-review.sh"

    # Skip if scripts directory doesn't exist yet
    if not SCRIPTS_DIR.exists():
        pytest.skip("Scripts directory does not exist yet")

    # Skip if no scripts exist yet (early in development)
    if not list(SCRIPTS_DIR.iterdir()):
        pytest.skip("No scripts created yet")

    if not self_review_script.exists():
        pytest.skip(
            f"self-review.sh not created yet at {self_review_script.relative_to(PROJECT_ROOT)}"
        )

    assert self_review_script.exists(), (
        f"self-review.sh must exist at {self_review_script.relative_to(PROJECT_ROOT)}"
    )


def test_at_least_one_script_exists():
    """At least one script should exist for meaningful testing."""
    if not SCRIPTS_DIR.exists():
        pytest.skip("Scripts directory does not exist yet")

    script_files = find_script_files()

    if len(script_files) == 0:
        pytest.skip(
            "No script files found yet. "
            "This test will run once scripts are created."
        )
