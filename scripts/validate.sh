#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}Unicorn Team — Plugin Structure Validator${NC}"
echo "────────────────────────────────────────"
echo ""

ERRORS=0

# 1. Check plugin.json
echo -n "  plugin.json exists and is valid JSON... "
if [ -f "$PROJECT_ROOT/.claude-plugin/plugin.json" ]; then
    if python3 -m json.tool "$PROJECT_ROOT/.claude-plugin/plugin.json" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC} (invalid JSON)"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "${RED}✗${NC} (not found)"
    ERRORS=$((ERRORS + 1))
fi

# 2. Count skills (13 composable skills; 5 agent protocols are inlined in .claude/agents/)
echo -n "  Skills count (expect 13)... "
SKILL_COUNT=$(find "$PROJECT_ROOT/skills" -maxdepth 2 -name "SKILL.md" | wc -l)
if [ "$SKILL_COUNT" -eq 13 ]; then
    echo -e "${GREEN}✓${NC} ($SKILL_COUNT)"
else
    echo -e "${RED}✗${NC} (found $SKILL_COUNT)"
    ERRORS=$((ERRORS + 1))
fi

# 3. Check flat structure (no nested category dirs)
echo -n "  Skills are flat (one level deep)... "
DEEP=$(find "$PROJECT_ROOT/skills" -mindepth 3 -name "SKILL.md" 2>/dev/null | wc -l)
if [ "$DEEP" -eq 0 ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC} ($DEEP skills nested too deep)"
    ERRORS=$((ERRORS + 1))
fi

# 4. Check scripts are executable
echo -n "  All scripts executable... "
NON_EXEC=$(find "$PROJECT_ROOT/skills" -name "*.sh" ! -executable 2>/dev/null | wc -l)
NON_EXEC_ROOT=$(find "$PROJECT_ROOT/scripts" -name "*.sh" ! -executable 2>/dev/null | wc -l)
TOTAL_NON_EXEC=$((NON_EXEC + NON_EXEC_ROOT))
if [ "$TOTAL_NON_EXEC" -eq 0 ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC} ($TOTAL_NON_EXEC not executable)"
    ERRORS=$((ERRORS + 1))
fi

# 5. Check hooks.json
echo -n "  hooks/hooks.json exists and valid... "
if [ -f "$PROJECT_ROOT/hooks/hooks.json" ]; then
    if python3 -m json.tool "$PROJECT_ROOT/hooks/hooks.json" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC} (invalid JSON)"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "${RED}✗${NC} (not found)"
    ERRORS=$((ERRORS + 1))
fi

# 6. Check for stale paths
echo -n "  No stale nested paths... "
STALE=$(grep -rl 'skills/agents/\|skills/unicorn/\|skills/domain/' \
    "$PROJECT_ROOT/skills/" \
    "$PROJECT_ROOT/CLAUDE.md" \
    "$PROJECT_ROOT/README.md" \
    "$PROJECT_ROOT/docs/" 2>/dev/null | wc -l)
if [ "$STALE" -eq 0 ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC} ($STALE files with stale paths)"
    ERRORS=$((ERRORS + 1))
fi

echo ""

# 7. Run tests
echo -e "${CYAN}Running tests...${NC}"
echo ""
if pytest "$PROJECT_ROOT/tests/" -v; then
    echo ""
    echo -e "${GREEN}✓${NC} Tests passed"
else
    echo ""
    echo -e "${RED}✗${NC} Tests failed"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "────────────────────────────────────────"
if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}All checks passed.${NC}"
else
    echo -e "${RED}$ERRORS check(s) failed.${NC}"
    exit 1
fi
