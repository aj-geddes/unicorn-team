#!/usr/bin/env bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Determine script location (absolute path)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Parse flags
FORCE=false
HELP=false

for arg in "$@"; do
    case $arg in
        --force)
            FORCE=true
            shift
            ;;
        --help|-h)
            HELP=true
            shift
            ;;
        *)
            ;;
    esac
done

# Help message
if [ "$HELP" = true ]; then
    echo -e "${CYAN}10X Developer Unicorn - Installation Script${NC}"
    echo ""
    echo "Usage: ./scripts/install.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --force    Override existing hooks without prompting"
    echo "  --help     Show this help message"
    echo ""
    echo "Installation includes:"
    echo "  - Git hooks (pre-commit, pre-push)"
    echo "  - Python dependencies (pytest, ruff, mypy, bandit, coverage)"
    echo "  - Verification of installation"
    echo ""
    echo "This script is non-destructive by default and will warn before"
    echo "overwriting existing hooks."
    exit 0
fi

# Header
echo -e "${CYAN}"
echo "════════════════════════════════════════════════════════════"
echo "  10X Developer Unicorn - Installation"
echo "════════════════════════════════════════════════════════════"
echo -e "${NC}"

# Step 1: Check prerequisites
echo -e "${BLUE}[1/5] Checking prerequisites...${NC}"

# Check for git
if ! command -v git &> /dev/null; then
    echo -e "${RED}✗ git is not installed${NC}"
    echo "Please install git and try again."
    exit 1
fi
echo -e "${GREEN}✓ git found${NC}"

# Check for python3
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}✗ python3 is not installed${NC}"
    echo "Please install python3 and try again."
    exit 1
fi
PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
echo -e "${GREEN}✓ python3 found (${PYTHON_VERSION})${NC}"

# Check for pip
if ! command -v pip3 &> /dev/null && ! python3 -m pip --version &> /dev/null; then
    echo -e "${RED}✗ pip is not installed${NC}"
    echo "Please install pip and try again."
    exit 1
fi
echo -e "${GREEN}✓ pip found${NC}"

echo ""

# Step 2: Detect git repository
echo -e "${BLUE}[2/5] Detecting git repository...${NC}"

if [ -d "${PROJECT_ROOT}/.git" ]; then
    echo -e "${GREEN}✓ Git repository detected at: ${PROJECT_ROOT}${NC}"
    IN_GIT_REPO=true
    GIT_HOOKS_DIR="${PROJECT_ROOT}/.git/hooks"
elif git rev-parse --git-dir &> /dev/null; then
    GIT_ROOT=$(git rev-parse --show-toplevel)
    echo -e "${GREEN}✓ Git repository detected at: ${GIT_ROOT}${NC}"
    IN_GIT_REPO=true
    GIT_HOOKS_DIR="${GIT_ROOT}/.git/hooks"
else
    echo -e "${YELLOW}⚠ Not in a git repository${NC}"
    echo "Hooks will be installed to project but cannot be linked to .git/hooks"
    IN_GIT_REPO=false
fi

echo ""

# Step 3: Create symlinks for hooks
echo -e "${BLUE}[3/5] Installing git hooks...${NC}"

if [ "$IN_GIT_REPO" = true ]; then
    # Pre-commit hook
    SOURCE_PRECOMMIT="${PROJECT_ROOT}/hooks/pre-commit"
    TARGET_PRECOMMIT="${GIT_HOOKS_DIR}/pre-commit"

    if [ -f "$TARGET_PRECOMMIT" ] || [ -L "$TARGET_PRECOMMIT" ]; then
        if [ "$FORCE" = true ]; then
            echo -e "${YELLOW}⚠ Overwriting existing pre-commit hook (--force flag)${NC}"
            rm -f "$TARGET_PRECOMMIT"
        else
            echo -e "${YELLOW}⚠ Pre-commit hook already exists${NC}"
            read -p "Overwrite? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -f "$TARGET_PRECOMMIT"
            else
                echo -e "${YELLOW}Skipping pre-commit hook installation${NC}"
                SOURCE_PRECOMMIT=""
            fi
        fi
    fi

    if [ -n "$SOURCE_PRECOMMIT" ]; then
        if [ -f "$SOURCE_PRECOMMIT" ]; then
            ln -sf "$SOURCE_PRECOMMIT" "$TARGET_PRECOMMIT"
            chmod +x "$SOURCE_PRECOMMIT"
            echo -e "${GREEN}✓ Pre-commit hook installed${NC}"
        else
            echo -e "${YELLOW}⚠ Pre-commit hook not found at ${SOURCE_PRECOMMIT}${NC}"
            echo "  (This is expected if hooks haven't been created yet)"
        fi
    fi

    # Pre-push hook
    SOURCE_PREPUSH="${PROJECT_ROOT}/hooks/pre-push"
    TARGET_PREPUSH="${GIT_HOOKS_DIR}/pre-push"

    if [ -f "$SOURCE_PREPUSH" ]; then
        if [ -f "$TARGET_PREPUSH" ] || [ -L "$TARGET_PREPUSH" ]; then
            if [ "$FORCE" = true ]; then
                echo -e "${YELLOW}⚠ Overwriting existing pre-push hook (--force flag)${NC}"
                rm -f "$TARGET_PREPUSH"
            else
                echo -e "${YELLOW}⚠ Pre-push hook already exists${NC}"
                read -p "Overwrite? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    rm -f "$TARGET_PREPUSH"
                    ln -sf "$SOURCE_PREPUSH" "$TARGET_PREPUSH"
                    chmod +x "$SOURCE_PREPUSH"
                    echo -e "${GREEN}✓ Pre-push hook installed${NC}"
                else
                    echo -e "${YELLOW}Skipping pre-push hook installation${NC}"
                fi
            fi
        else
            ln -sf "$SOURCE_PREPUSH" "$TARGET_PREPUSH"
            chmod +x "$SOURCE_PREPUSH"
            echo -e "${GREEN}✓ Pre-push hook installed${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Pre-push hook not found (will be installed when created)${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Not in git repository - skipping hook installation${NC}"
fi

echo ""

# Step 4: Install Python dependencies
echo -e "${BLUE}[4/5] Installing Python dependencies...${NC}"

DEPENDENCIES=(pytest ruff mypy bandit coverage)
MISSING_DEPS=()

for dep in "${DEPENDENCIES[@]}"; do
    if ! python3 -m pip show "$dep" &> /dev/null; then
        MISSING_DEPS+=("$dep")
    else
        echo -e "${GREEN}✓ ${dep} already installed${NC}"
    fi
done

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo -e "${CYAN}Installing missing dependencies: ${MISSING_DEPS[*]}${NC}"

    # Try to install without sudo first
    if python3 -m pip install --user "${MISSING_DEPS[@]}" &> /dev/null; then
        echo -e "${GREEN}✓ Dependencies installed successfully${NC}"
    else
        echo -e "${YELLOW}⚠ Failed to install with pip --user${NC}"
        echo "You may need to install these manually:"
        for dep in "${MISSING_DEPS[@]}"; do
            echo "  - $dep"
        done
        echo ""
        echo "Try: pip3 install ${MISSING_DEPS[*]}"
    fi
else
    echo -e "${GREEN}✓ All dependencies already installed${NC}"
fi

echo ""

# Step 5: Verify installation
echo -e "${BLUE}[5/5] Verifying installation...${NC}"

# Check that scripts are executable
if [ -d "${PROJECT_ROOT}/scripts" ]; then
    SCRIPTS_COUNT=$(find "${PROJECT_ROOT}/scripts" -type f -name "*.sh" | wc -l)
    EXECUTABLE_COUNT=$(find "${PROJECT_ROOT}/scripts" -type f -name "*.sh" -executable | wc -l)

    if [ "$SCRIPTS_COUNT" -eq "$EXECUTABLE_COUNT" ]; then
        echo -e "${GREEN}✓ All scripts are executable (${EXECUTABLE_COUNT}/${SCRIPTS_COUNT})${NC}"
    else
        echo -e "${YELLOW}⚠ Some scripts are not executable (${EXECUTABLE_COUNT}/${SCRIPTS_COUNT})${NC}"
        echo "Making scripts executable..."
        chmod +x "${PROJECT_ROOT}"/scripts/*.sh 2>/dev/null || true
        echo -e "${GREEN}✓ Scripts made executable${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Scripts directory not found${NC}"
fi

# Check that hooks are executable
if [ -d "${PROJECT_ROOT}/hooks" ]; then
    if [ -f "${PROJECT_ROOT}/hooks/pre-commit" ]; then
        if [ -x "${PROJECT_ROOT}/hooks/pre-commit" ]; then
            echo -e "${GREEN}✓ Pre-commit hook is executable${NC}"
        else
            chmod +x "${PROJECT_ROOT}/hooks/pre-commit"
            echo -e "${GREEN}✓ Pre-commit hook made executable${NC}"
        fi
    fi

    if [ -f "${PROJECT_ROOT}/hooks/pre-push" ]; then
        if [ -x "${PROJECT_ROOT}/hooks/pre-push" ]; then
            echo -e "${GREEN}✓ Pre-push hook is executable${NC}"
        else
            chmod +x "${PROJECT_ROOT}/hooks/pre-push"
            echo -e "${GREEN}✓ Pre-push hook made executable${NC}"
        fi
    fi
fi

# Check directory structure
EXPECTED_DIRS=("skills" "hooks" "scripts" "tests" "docs")
for dir in "${EXPECTED_DIRS[@]}"; do
    if [ -d "${PROJECT_ROOT}/${dir}" ]; then
        echo -e "${GREEN}✓ ${dir}/ directory exists${NC}"
    else
        echo -e "${YELLOW}⚠ ${dir}/ directory not found${NC}"
    fi
done

echo ""

# Success message
echo -e "${GREEN}"
echo "════════════════════════════════════════════════════════════"
echo "  Installation Complete!"
echo "════════════════════════════════════════════════════════════"
echo -e "${NC}"

echo -e "${CYAN}Next Steps:${NC}"
echo ""
echo "1. Run TDD workflow for a feature:"
echo -e "   ${YELLOW}./scripts/tdd.sh <feature-name>${NC}"
echo ""
echo "2. Self-review before commit:"
echo -e "   ${YELLOW}./scripts/self-review.sh${NC}"
echo ""
echo "3. Estimate a task:"
echo -e "   ${YELLOW}./scripts/estimate.sh${NC}"
echo ""
echo "4. Learn a new language/framework:"
echo -e "   ${YELLOW}./scripts/new-language.sh <language>${NC}"
echo ""
echo "5. Validate all skills:"
echo -e "   ${YELLOW}pytest tests/test_skills_valid.py -v${NC}"
echo ""
echo "6. Run full test suite:"
echo -e "   ${YELLOW}pytest -v --cov=. --cov-fail-under=80${NC}"
echo ""

if [ "$IN_GIT_REPO" = true ]; then
    echo -e "${GREEN}Git hooks are active and will run on commit/push${NC}"
else
    echo -e "${YELLOW}To enable git hooks, run this script from within a git repository${NC}"
fi

echo ""
echo -e "${CYAN}Project Root: ${PROJECT_ROOT}${NC}"
echo ""
