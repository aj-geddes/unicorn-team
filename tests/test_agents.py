"""
Validation tests for agent definitions in .claude/agents/.

Tests ensure:
- .claude/agents/ directory exists with 5 agent definitions
- Each agent .md has valid frontmatter (name, description, model, tools, skills)
- Model values are valid (sonnet/opus/haiku)
- Skill references resolve to existing skills/ directories
- Agent names match the expected set
- Protocol reference files exist in .claude/protocols/
"""

import re
from pathlib import Path

import pytest
import yaml


PROJECT_ROOT = Path(__file__).parent.parent
AGENTS_DIR = PROJECT_ROOT / ".claude" / "agents"
SKILLS_DIR = PROJECT_ROOT / "skills"
PROTOCOLS_DIR = PROJECT_ROOT / ".claude" / "protocols"

EXPECTED_AGENTS = {"developer", "architect", "qa-security", "devops", "polyglot"}
VALID_MODELS = {"sonnet", "opus", "haiku"}


def find_agent_files():
    """Find all .md files in the agents directory."""
    if not AGENTS_DIR.exists():
        return []
    return sorted(AGENTS_DIR.glob("*.md"))


def parse_agent_frontmatter(agent_file):
    """
    Parse YAML frontmatter from an agent .md file.

    Returns:
        dict: Parsed frontmatter or None if invalid
        str: Body content after frontmatter
    """
    content = agent_file.read_text(encoding="utf-8")

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


def test_agents_directory_exists():
    """The .claude/agents directory must exist."""
    assert AGENTS_DIR.exists(), (
        f".claude/agents directory not found at {AGENTS_DIR}"
    )


def test_exactly_5_agents():
    """There must be exactly 5 agent definitions."""
    agent_files = find_agent_files()
    agent_names = [f.stem for f in agent_files]

    assert len(agent_files) == 5, (
        f"Expected 5 agent definitions in .claude/agents/, "
        f"found {len(agent_files)}: {agent_names}"
    )


def test_agent_names_match_expected():
    """Agent filenames must match the expected set."""
    agent_files = find_agent_files()
    agent_names = {f.stem for f in agent_files}

    assert agent_names == EXPECTED_AGENTS, (
        f"Agent names mismatch. Expected {EXPECTED_AGENTS}, got {agent_names}. "
        f"Missing: {EXPECTED_AGENTS - agent_names}, "
        f"Extra: {agent_names - EXPECTED_AGENTS}"
    )


@pytest.mark.parametrize("agent_file", find_agent_files(),
                         ids=lambda f: f.stem)
def test_agent_has_valid_frontmatter(agent_file):
    """Every agent .md must have valid YAML frontmatter."""
    frontmatter, _ = parse_agent_frontmatter(agent_file)

    assert frontmatter is not None, (
        f"{agent_file.name} must have valid YAML frontmatter between --- delimiters"
    )


@pytest.mark.parametrize("agent_file", find_agent_files(),
                         ids=lambda f: f.stem)
def test_agent_has_required_fields(agent_file):
    """Every agent must have name, description, model, tools, and skills."""
    frontmatter, _ = parse_agent_frontmatter(agent_file)

    if frontmatter is None:
        pytest.skip("Frontmatter validation failed")

    required_fields = ["name", "description", "model", "tools", "skills"]
    for field in required_fields:
        assert field in frontmatter, (
            f"{agent_file.name} frontmatter missing required field: '{field}'"
        )


@pytest.mark.parametrize("agent_file", find_agent_files(),
                         ids=lambda f: f.stem)
def test_agent_model_is_valid(agent_file):
    """Agent model must be one of: sonnet, opus, haiku."""
    frontmatter, _ = parse_agent_frontmatter(agent_file)

    if frontmatter is None or "model" not in frontmatter:
        pytest.skip("Frontmatter or model field missing")

    model = frontmatter["model"]
    assert model in VALID_MODELS, (
        f"{agent_file.name} has invalid model '{model}'. "
        f"Must be one of: {VALID_MODELS}"
    )


@pytest.mark.parametrize("agent_file", find_agent_files(),
                         ids=lambda f: f.stem)
def test_agent_skills_resolve(agent_file):
    """Every skill referenced by an agent must exist as a skills/ directory."""
    frontmatter, _ = parse_agent_frontmatter(agent_file)

    if frontmatter is None or "skills" not in frontmatter:
        pytest.skip("Frontmatter or skills field missing")

    skills = frontmatter["skills"]
    assert isinstance(skills, list), (
        f"{agent_file.name} 'skills' must be a list"
    )

    for skill_name in skills:
        skill_dir = SKILLS_DIR / skill_name
        assert skill_dir.exists(), (
            f"{agent_file.name} references skill '{skill_name}' "
            f"but {skill_dir.relative_to(PROJECT_ROOT)} does not exist"
        )

        skill_file = skill_dir / "SKILL.md"
        assert skill_file.exists(), (
            f"{agent_file.name} references skill '{skill_name}' "
            f"but {skill_file.relative_to(PROJECT_ROOT)} does not exist"
        )


@pytest.mark.parametrize("agent_file", find_agent_files(),
                         ids=lambda f: f.stem)
def test_agent_has_no_self_referencing_protocol_skill(agent_file):
    """Agents must not reference their own name as a skill.

    Protocol content is inlined into the agent definition body,
    not loaded as a separate skill from skills/.
    """
    frontmatter, _ = parse_agent_frontmatter(agent_file)

    if frontmatter is None or "skills" not in frontmatter:
        pytest.skip("Frontmatter or skills field missing")

    agent_name = frontmatter.get("name", agent_file.stem)
    skills = frontmatter["skills"]

    # Also check for the agent-devops -> devops mapping
    protocol_skill_names = {agent_name, f"agent-{agent_name}"}

    for skill_name in skills:
        assert skill_name not in protocol_skill_names, (
            f"{agent_file.name} should not reference '{skill_name}' as a skill. "
            f"Protocol content should be inlined in the agent definition body."
        )


def test_protocols_directory_exists():
    """The .claude/protocols directory must exist for agent reference files."""
    assert PROTOCOLS_DIR.exists(), (
        f".claude/protocols directory not found at {PROTOCOLS_DIR}. "
        f"Agent reference materials should be stored here."
    )
