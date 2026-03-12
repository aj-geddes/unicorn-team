"""
Validation tests for the Claude Code plugin manifest.

Tests ensure:
- .claude-plugin/plugin.json exists and is valid
- Required fields are present
- All 18 skills are discoverable at the expected flat paths
"""

import json
from pathlib import Path

import pytest


PROJECT_ROOT = Path(__file__).parent.parent
PLUGIN_DIR = PROJECT_ROOT / ".claude-plugin"
SKILLS_DIR = PROJECT_ROOT / "skills"
AGENTS_DIR = PROJECT_ROOT / ".claude" / "agents"

REQUIRED_FIELDS = ["name", "version", "description", "author", "license"]


def test_plugin_directory_exists():
    """The .claude-plugin directory must exist."""
    assert PLUGIN_DIR.exists(), (
        f".claude-plugin directory not found at {PLUGIN_DIR}"
    )


def test_plugin_json_exists():
    """plugin.json must exist inside .claude-plugin/."""
    plugin_json = PLUGIN_DIR / "plugin.json"
    assert plugin_json.exists(), (
        f"plugin.json must exist at {plugin_json.relative_to(PROJECT_ROOT)}"
    )


def test_plugin_json_valid():
    """plugin.json must be valid JSON."""
    plugin_json = PLUGIN_DIR / "plugin.json"

    if not plugin_json.exists():
        pytest.skip("plugin.json not created yet")

    try:
        data = json.loads(plugin_json.read_text(encoding="utf-8"))
        assert isinstance(data, dict), "plugin.json must be a JSON object"
    except json.JSONDecodeError as e:
        pytest.fail(f"plugin.json is not valid JSON: {e}")


def test_plugin_name_is_unicorn_team():
    """Plugin name must be 'unicorn-team'."""
    plugin_json = PLUGIN_DIR / "plugin.json"

    if not plugin_json.exists():
        pytest.skip("plugin.json not created yet")

    data = json.loads(plugin_json.read_text(encoding="utf-8"))
    assert data.get("name") == "unicorn-team", (
        f"Plugin name must be 'unicorn-team', got '{data.get('name')}'"
    )


def test_plugin_has_required_fields():
    """plugin.json must have all required fields."""
    plugin_json = PLUGIN_DIR / "plugin.json"

    if not plugin_json.exists():
        pytest.skip("plugin.json not created yet")

    data = json.loads(plugin_json.read_text(encoding="utf-8"))

    for field in REQUIRED_FIELDS:
        assert field in data, (
            f"plugin.json missing required field: '{field}'"
        )


def test_all_18_skills_discoverable():
    """All 18 skills must be discoverable at skills/*/SKILL.md."""
    skill_files = sorted(SKILLS_DIR.glob("*/SKILL.md"))

    assert len(skill_files) == 18, (
        f"Expected 18 skills at skills/*/SKILL.md, found {len(skill_files)}: "
        f"{[f.parent.name for f in skill_files]}"
    )


def test_skills_are_flat():
    """Skills must be one level deep (skills/<name>/SKILL.md), not nested."""
    # Find any SKILL.md files that are more than one level deep
    all_skills = list(SKILLS_DIR.rglob("SKILL.md"))
    flat_skills = list(SKILLS_DIR.glob("*/SKILL.md"))

    assert len(all_skills) == len(flat_skills), (
        f"Found {len(all_skills)} total SKILL.md files but only "
        f"{len(flat_skills)} at the expected flat level. "
        f"Some skills are still nested."
    )


def test_agents_directory_exists():
    """The .claude/agents directory must exist for agent definitions."""
    assert AGENTS_DIR.exists(), (
        f".claude/agents directory not found at {AGENTS_DIR}"
    )
