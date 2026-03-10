"""
Validation tests for scripts in the 10X Developer Unicorn project.

Tests ensure:
- Scripts are executable
- Scripts have proper shebangs
- Required scripts exist (at new co-located paths)
"""

import os
import stat
from pathlib import Path

import pytest


PROJECT_ROOT = Path(__file__).parent.parent
SCRIPTS_DIR = PROJECT_ROOT / "scripts"
SKILLS_DIR = PROJECT_ROOT / "skills"


def find_all_script_files():
    """Find all script files in scripts/ and skills/**/scripts/ directories."""
    scripts = []

    # Root scripts directory
    if SCRIPTS_DIR.exists():
        for file in SCRIPTS_DIR.iterdir():
            if file.is_file() and not file.name.startswith("."):
                if file.suffix in [".sh", ""] or file.name.endswith(".sh"):
                    scripts.append(file)

    # Co-located scripts in skill directories
    if SKILLS_DIR.exists():
        for script_file in SKILLS_DIR.rglob("scripts/*.sh"):
            if script_file.is_file():
                scripts.append(script_file)

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


@pytest.mark.parametrize("script_file", find_all_script_files())
def test_scripts_are_executable(script_file):
    """All scripts must be chmod +x."""
    assert is_executable(script_file), (
        f"{script_file.relative_to(PROJECT_ROOT)} is not executable. "
        f"Run: chmod +x {script_file}"
    )


@pytest.mark.parametrize("script_file", find_all_script_files())
def test_scripts_have_shebang(script_file):
    """All scripts must start with #!/usr/bin/env bash or similar."""
    shebang = get_shebang(script_file)

    assert shebang is not None, (
        f"{script_file.relative_to(PROJECT_ROOT)} must start with a shebang line "
        f"(e.g., #!/usr/bin/env bash)"
    )

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
    """Verify install.sh exists at project root."""
    install_script = SCRIPTS_DIR / "install.sh"
    assert install_script.exists(), (
        f"install.sh must exist at {install_script.relative_to(PROJECT_ROOT)}"
    )


# Co-located script existence tests
SCRIPT_LOCATIONS = {
    "tdd.sh": SKILLS_DIR / "developer" / "scripts" / "tdd.sh",
    "self-review.sh": SKILLS_DIR / "self-verification" / "scripts" / "self-review.sh",
    "estimate.sh": SKILLS_DIR / "estimation" / "scripts" / "estimate.sh",
    "new-language.sh": SKILLS_DIR / "language-learning" / "scripts" / "new-language.sh",
}


@pytest.mark.parametrize("name,path", SCRIPT_LOCATIONS.items())
def test_colocated_script_exists(name, path):
    """Verify co-located scripts exist at their owning skill paths."""
    assert path.exists(), (
        f"{name} must exist at {path.relative_to(PROJECT_ROOT)}"
    )


def test_at_least_one_script_exists():
    """At least one script should exist for meaningful testing."""
    script_files = find_all_script_files()
    assert len(script_files) > 0, "No script files found"
