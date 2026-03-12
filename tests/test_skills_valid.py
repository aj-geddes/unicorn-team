"""
Validation tests for SKILL.md files in the 10X Developer Unicorn project.

Tests ensure:
- Valid YAML frontmatter with required fields
- Descriptions include trigger phrases
- Skill bodies are under 500 lines
"""

import re
from pathlib import Path

import pytest
import yaml


PROJECT_ROOT = Path(__file__).parent.parent
SKILLS_DIR = PROJECT_ROOT / "skills"


def find_skill_files():
    """Find all SKILL.md files in the skills directory."""
    if not SKILLS_DIR.exists():
        return []
    return list(SKILLS_DIR.rglob("SKILL.md"))


def parse_skill_frontmatter(skill_file):
    """
    Parse YAML frontmatter from a SKILL.md file.

    Returns:
        dict: Parsed frontmatter or None if invalid
        str: Body content after frontmatter
    """
    content = skill_file.read_text(encoding="utf-8")

    # Match frontmatter between --- delimiters
    pattern = r'^---\s*\n(.*?)\n---\s*\n(.*)$'
    match = re.match(pattern, content, re.DOTALL)

    if not match:
        return None, content

    frontmatter_text = match.group(1)
    body = match.group(2)

    try:
        frontmatter = yaml.safe_load(frontmatter_text)
        return frontmatter, body
    except yaml.YAMLError:
        return None, body


@pytest.mark.parametrize("skill_file", find_skill_files())
def test_skill_has_valid_frontmatter(skill_file):
    """Every SKILL.md must have name and description in YAML frontmatter."""
    frontmatter, _ = parse_skill_frontmatter(skill_file)

    assert frontmatter is not None, (
        f"{skill_file.relative_to(PROJECT_ROOT)} must have valid YAML frontmatter "
        f"between --- delimiters"
    )

    assert "name" in frontmatter, (
        f"{skill_file.relative_to(PROJECT_ROOT)} frontmatter must include 'name' field"
    )

    assert "description" in frontmatter, (
        f"{skill_file.relative_to(PROJECT_ROOT)} frontmatter must include 'description' field"
    )

    assert isinstance(frontmatter["name"], str) and frontmatter["name"].strip(), (
        f"{skill_file.relative_to(PROJECT_ROOT)} 'name' field must be a non-empty string"
    )

    assert isinstance(frontmatter["description"], str) and frontmatter["description"].strip(), (
        f"{skill_file.relative_to(PROJECT_ROOT)} 'description' field must be a non-empty string"
    )


@pytest.mark.parametrize("skill_file", find_skill_files())
def test_skill_description_has_triggers(skill_file):
    """Description must explain when to use the skill."""
    frontmatter, _ = parse_skill_frontmatter(skill_file)

    if frontmatter is None or "description" not in frontmatter:
        pytest.skip("Frontmatter validation failed, skip trigger check")

    description = frontmatter["description"].lower()

    # Check for trigger-related keywords that indicate "when to use"
    trigger_indicators = [
        "when",
        "use this",
        "use when",
        "trigger",
        "activate",
        "invoke",
        "call this",
        "for",
        "helps",
        "solves",
    ]

    has_trigger = any(indicator in description for indicator in trigger_indicators)

    # Also check for reasonable length (substantial description)
    min_description_words = 10
    word_count = len(description.split())

    assert has_trigger or word_count >= min_description_words, (
        f"{skill_file.relative_to(PROJECT_ROOT)} description must explain when to use "
        f"the skill (include trigger phrases like 'when', 'use this for', etc.) "
        f"or provide a substantial description (at least {min_description_words} words)"
    )


@pytest.mark.parametrize("skill_file", find_skill_files())
def test_skill_under_500_lines(skill_file):
    """Body must be under 500 lines (split to references/ if larger)."""
    _, body = parse_skill_frontmatter(skill_file)

    # Count non-empty lines in the body
    body_lines = [line for line in body.split("\n") if line.strip()]
    line_count = len(body_lines)

    max_lines = 500

    assert line_count <= max_lines, (
        f"{skill_file.relative_to(PROJECT_ROOT)} body has {line_count} lines, "
        f"exceeds maximum of {max_lines} lines. "
        f"Consider splitting large content into references/ directory."
    )


def test_skills_directory_exists():
    """The skills directory must exist."""
    assert SKILLS_DIR.exists(), (
        f"Skills directory not found at {SKILLS_DIR}. "
        f"Create the directory structure first."
    )


def test_at_least_one_skill_exists():
    """At least one SKILL.md file should exist for meaningful testing."""
    skill_files = find_skill_files()

    if len(skill_files) == 0:
        pytest.skip(
            "No SKILL.md files found yet. "
            "This test will run once skills are created."
        )


# Agent protocol skills should NOT have trigger phrases -- they are
# preloaded by agent definitions, not triggered directly by users.
AGENT_PROTOCOL_SKILLS = {
    "developer", "architect", "qa-security", "agent-devops", "polyglot"
}


def _find_agent_protocol_skills():
    """Find SKILL.md files for agent protocol skills."""
    results = []
    for name in sorted(AGENT_PROTOCOL_SKILLS):
        skill_file = SKILLS_DIR / name / "SKILL.md"
        if skill_file.exists():
            results.append(skill_file)
    return results


@pytest.mark.parametrize("skill_file", _find_agent_protocol_skills(),
                         ids=lambda f: f.parent.name)
def test_agent_skills_are_detriggered(skill_file):
    """Agent protocol skills must NOT have 'ALWAYS trigger on' in descriptions.

    These skills are preloaded by agent definitions (.claude/agents/*.md)
    and should not be triggered directly as standalone skills.
    """
    frontmatter, _ = parse_skill_frontmatter(skill_file)

    if frontmatter is None or "description" not in frontmatter:
        pytest.skip("Frontmatter validation failed")

    description = frontmatter["description"]

    assert "ALWAYS trigger on" not in description, (
        f"{skill_file.relative_to(PROJECT_ROOT)} is an agent protocol skill "
        f"and must NOT have 'ALWAYS trigger on' in its description. "
        f"Agent protocol skills are preloaded by agent definitions, "
        f"not triggered directly."
    )
