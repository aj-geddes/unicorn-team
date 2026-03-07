#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

INSTALL_MODE="project"
FORCE=false

for arg in "$@"; do
    case "$arg" in
        --global) INSTALL_MODE="global" ;;
        --force)  FORCE=true ;;
        --uninstall)
            echo -e "${CYAN}Uninstalling...${NC}"
            rm -rf "$PROJECT_ROOT/.claude/skills"
            echo -e "${GREEN}Removed .claude/skills/${NC}"
            exit 0
            ;;
        --help|-h)
            cat <<'HELP'
Usage: ./scripts/install.sh [--global] [--force] [--uninstall] [--help]

Install unicorn-team skills into Claude Code.

Options:
  --global     Install to ~/.claude/skills/ (user-wide, copies files)
  --force      Overwrite existing skills and hooks
  --uninstall  Remove installed skills from .claude/skills/
  --help       Show this message

Default: project-level install to .claude/skills/ (symlinks)
HELP
            exit 0
            ;;
    esac
done

# ── Header ──────────────────────────────────────────────
echo ""
echo -e "${CYAN}Unicorn Team — Claude Code Installer${NC}"
echo "────────────────────────────────────────"

if [ "$INSTALL_MODE" = "global" ]; then
    SKILLS_TARGET="$HOME/.claude/skills"
    echo -e "Mode: ${YELLOW}global${NC} ($SKILLS_TARGET)"
else
    SKILLS_TARGET="$PROJECT_ROOT/.claude/skills"
    echo -e "Mode: ${GREEN}project${NC} (.claude/skills/)"
fi
echo ""

# ── Skills ──────────────────────────────────────────────
echo -e "${CYAN}Skills${NC}"

mkdir -p "$SKILLS_TARGET"

INSTALLED=0
SKIPPED=0

# Track names to handle collisions (agents/devops vs domain/devops)
declare -A SEEN_NAMES

while IFS= read -r skill_md; do
    skill_dir="$(dirname "$skill_md")"
    skill_name="$(basename "$skill_dir")"

    # On collision, prefix with parent directory name
    if [[ -v "SEEN_NAMES[$skill_name]" ]]; then
        parent="$(basename "$(dirname "$skill_dir")")"
        skill_name="${parent}-${skill_name}"
    fi
    SEEN_NAMES["$skill_name"]=1

    link="$SKILLS_TARGET/$skill_name"

    if [ -e "$link" ] && [ "$FORCE" = false ]; then
        echo -e "  ${YELLOW}~${NC} $skill_name (exists, use --force)"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    if [ "$INSTALL_MODE" = "project" ]; then
        rel="$(realpath --relative-to="$SKILLS_TARGET" "$skill_dir")"
        ln -sfn "$rel" "$link"
    else
        rm -rf "$link"
        cp -r "$skill_dir" "$link"
    fi

    echo -e "  ${GREEN}+${NC} $skill_name"
    INSTALLED=$((INSTALLED + 1))
done < <(find "$PROJECT_ROOT/skills" -name "SKILL.md" -type f | sort)

echo -e "  ── ${GREEN}$INSTALLED installed${NC}, $SKIPPED skipped"
echo ""

# ── Git Hooks ───────────────────────────────────────────
echo -e "${CYAN}Git Hooks${NC}"

if git -C "$PROJECT_ROOT" rev-parse --git-dir &>/dev/null; then
    GIT_DIR="$(git -C "$PROJECT_ROOT" rev-parse --absolute-git-dir)"
    HOOKS_DIR="$GIT_DIR/hooks"
    mkdir -p "$HOOKS_DIR"

    for hook in pre-commit pre-push; do
        src="$PROJECT_ROOT/hooks/$hook"
        dst="$HOOKS_DIR/$hook"
        [ -f "$src" ] || continue

        if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
            echo -e "  ${GREEN}✓${NC} $hook (already linked)"
            continue
        fi

        if [ -e "$dst" ] && [ "$FORCE" = false ]; then
            echo -e "  ${YELLOW}~${NC} $hook (exists, use --force)"
            continue
        fi

        chmod +x "$src"
        ln -sf "$src" "$dst"
        echo -e "  ${GREEN}+${NC} $hook"
    done
else
    echo -e "  ${YELLOW}~${NC} Not a git repo — skipping hooks"
fi
echo ""

# ── Scripts ─────────────────────────────────────────────
echo -e "${CYAN}Scripts${NC}"

SCRIPT_COUNT=0
while IFS= read -r script; do
    chmod +x "$script"
    SCRIPT_COUNT=$((SCRIPT_COUNT + 1))
done < <(find "$PROJECT_ROOT/skills" -path "*/scripts/*.sh" -type f 2>/dev/null)
chmod +x "$PROJECT_ROOT/scripts/install.sh"
SCRIPT_COUNT=$((SCRIPT_COUNT + 1))
echo -e "  ${GREEN}✓${NC} $SCRIPT_COUNT scripts marked executable"
echo ""

# ── CLAUDE.md (global only) ─────────────────────────────
if [ "$INSTALL_MODE" = "global" ]; then
    echo -e "${CYAN}CLAUDE.md${NC}"
    CLAUDE_MD="$HOME/.claude/CLAUDE.md"
    MARKER_START="<!-- unicorn-team-start -->"
    MARKER_END="<!-- unicorn-team-end -->"

    ACTIVATION_BLOCK="$MARKER_START
## Orchestrator Mode (10X Unicorn)

You coordinate the 10X Unicorn agent team. Delegate all substantial work to
subagents (Agent tool). Never implement complex tasks directly.

- Route tasks using the orchestrator skill's decision tree
- Enforce TDD: tests first, always (RED -> GREEN -> REFACTOR)
- Apply quality gates before returning results
- Each subagent gets fresh 200K context -- use it
$MARKER_END"

    if [ -f "$CLAUDE_MD" ] && grep -qF "$MARKER_START" "$CLAUDE_MD"; then
        # Replace existing block
        sed -i "/$MARKER_START/,/$MARKER_END/c\\$ACTIVATION_BLOCK" "$CLAUDE_MD"
        echo -e "  ${GREEN}✓${NC} Updated orchestrator block in $CLAUDE_MD"
    elif [ -f "$CLAUDE_MD" ]; then
        # Append to existing file
        printf '\n%s\n' "$ACTIVATION_BLOCK" >> "$CLAUDE_MD"
        echo -e "  ${GREEN}+${NC} Appended orchestrator block to $CLAUDE_MD"
    else
        # Create new file
        mkdir -p "$(dirname "$CLAUDE_MD")"
        echo "$ACTIVATION_BLOCK" > "$CLAUDE_MD"
        echo -e "  ${GREEN}+${NC} Created $CLAUDE_MD"
    fi
    echo ""
fi

# ── .gitignore (project only) ──────────────────────────
if [ "$INSTALL_MODE" = "project" ]; then
    GITIGNORE="$PROJECT_ROOT/.gitignore"
    ENTRY=".claude/skills/"
    if ! grep -qxF "$ENTRY" "$GITIGNORE" 2>/dev/null; then
        echo "$ENTRY" >> "$GITIGNORE"
        echo -e "${CYAN}.gitignore${NC}"
        echo -e "  ${GREEN}+${NC} Added $ENTRY"
        echo ""
    fi
fi

# ── Summary ─────────────────────────────────────────────
echo "────────────────────────────────────────"
TOTAL=$((INSTALLED + SKIPPED))
echo -e "${GREEN}Done.${NC} $TOTAL skills available to Claude Code."
echo ""
if [ "$INSTALL_MODE" = "global" ]; then
    echo -e "Skills:  ${YELLOW}ls ~/.claude/skills/${NC}"
else
    echo -e "Skills:  ${YELLOW}ls .claude/skills/${NC}"
fi
echo -e "Test:    ${YELLOW}pytest tests/ -v${NC}"
echo ""
