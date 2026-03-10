#!/usr/bin/env bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Helper functions for colored output
print_banner() {
    local color=$1
    local text=$2
    echo -e "\n${color}${BOLD}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${color}${BOLD}  $text${NC}"
    echo -e "${color}${BOLD}════════════════════════════════════════════════════════════════${NC}\n"
}

print_step() {
    echo -e "${CYAN}  →${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check for feature name argument
if [[ $# -lt 1 ]]; then
    echo -e "${RED}Usage: $0 <feature-name>${NC}"
    echo ""
    echo "Example:"
    echo "  $0 user-authentication"
    echo "  $0 payment-processing"
    exit 1
fi

FEATURE="$1"

# Detect project language and set up test configuration
detect_language() {
    if [[ -f "pyproject.toml" ]] || [[ -f "requirements.txt" ]] || [[ -f "setup.py" ]]; then
        echo "python"
    elif [[ -f "package.json" ]]; then
        echo "javascript"
    elif [[ -f "go.mod" ]]; then
        echo "go"
    elif [[ -f "Cargo.toml" ]]; then
        echo "rust"
    else
        echo "unknown"
    fi
}

LANG=$(detect_language)

# Set language-specific configurations
case $LANG in
    python)
        TEST_DIR="tests"
        TEST_FILE="${TEST_DIR}/test_${FEATURE}.py"
        TEST_RUNNER="pytest"
        TEST_CMD="pytest \"$TEST_FILE\" -v"
        TEST_CMD_QUIET="pytest \"$TEST_FILE\" -q"
        COVERAGE_CMD="pytest \"$TEST_FILE\" -v --cov=. --cov-report=term-missing"
        LANG_ICON="🐍"
        LANG_NAME="Python"
        ;;
    javascript)
        TEST_DIR="tests"
        TEST_FILE="${TEST_DIR}/${FEATURE}.test.js"
        # Try to detect test runner from package.json
        if grep -q "vitest" package.json 2>/dev/null; then
            TEST_RUNNER="vitest"
            TEST_CMD="npm run test -- \"$TEST_FILE\""
            TEST_CMD_QUIET="npm run test -- \"$TEST_FILE\" --reporter=basic"
            COVERAGE_CMD="npm run test -- \"$TEST_FILE\" --coverage"
        else
            TEST_RUNNER="jest"
            TEST_CMD="npm test -- \"$TEST_FILE\""
            TEST_CMD_QUIET="npm test -- \"$TEST_FILE\" --silent"
            COVERAGE_CMD="npm test -- \"$TEST_FILE\" --coverage"
        fi
        LANG_ICON="📦"
        LANG_NAME="JavaScript"
        ;;
    go)
        TEST_DIR="."
        TEST_FILE="${FEATURE}_test.go"
        TEST_RUNNER="go test"
        TEST_CMD="go test -v -run Test${FEATURE^}"
        TEST_CMD_QUIET="go test -run Test${FEATURE^}"
        COVERAGE_CMD="go test -v -cover -coverprofile=coverage.out && go tool cover -func=coverage.out"
        LANG_ICON="🐹"
        LANG_NAME="Go"
        ;;
    rust)
        TEST_DIR="tests"
        TEST_FILE="${TEST_DIR}/${FEATURE}.rs"
        TEST_RUNNER="cargo test"
        TEST_CMD="cargo test ${FEATURE} -- --nocapture"
        TEST_CMD_QUIET="cargo test ${FEATURE} --quiet"
        COVERAGE_CMD="cargo test ${FEATURE} -- --nocapture"
        LANG_ICON="🦀"
        LANG_NAME="Rust"
        ;;
    *)
        print_error "Unknown project type!"
        echo "Please ensure you have one of the following files in your project root:"
        echo "  - pyproject.toml or requirements.txt (Python)"
        echo "  - package.json (JavaScript/TypeScript)"
        echo "  - go.mod (Go)"
        echo "  - Cargo.toml (Rust)"
        exit 1
        ;;
esac

# Create test directory if it doesn't exist
if [[ ! -d "$TEST_DIR" ]] && [[ "$TEST_DIR" != "." ]]; then
    print_step "Creating test directory: $TEST_DIR"
    mkdir -p "$TEST_DIR"
fi

# Main TDD workflow
print_banner "$CYAN" "🔴 🟢 🔵  TDD WORKFLOW: $FEATURE"
echo -e "${LANG_ICON} ${BOLD}Language:${NC} $LANG_NAME"
echo -e "📄 ${BOLD}Test file:${NC} $TEST_FILE"
echo -e "🔧 ${BOLD}Test runner:${NC} $TEST_RUNNER"
echo ""

# ============================================================================
# RED PHASE: Write Failing Test
# ============================================================================
print_banner "$RED" "🔴 PHASE 1: RED - Write Failing Test"

echo -e "${BOLD}Instructions:${NC}"
print_step "Create test file: ${CYAN}$TEST_FILE${NC}"
print_step "Write a test that describes the ${BOLD}expected behavior${NC}"
print_step "The test ${BOLD}MUST fail${NC} initially (this is critical!)"
print_step "Focus on ${BOLD}what${NC} the code should do, not ${BOLD}how${NC}"
echo ""
echo -e "${YELLOW}${BOLD}Why this matters:${NC}"
echo -e "  Tests written first ensure you're building the ${BOLD}right thing${NC}."
echo -e "  A failing test proves the feature doesn't exist yet."
echo ""

read -p "Press Enter when your failing test is written..."

# Verify test file exists
if [[ ! -f "$TEST_FILE" ]]; then
    print_error "Test file not found: $TEST_FILE"
    echo ""
    echo "Please create the test file before proceeding."
    exit 1
fi

echo ""
print_step "Running tests (expecting ${RED}${BOLD}FAILURE${NC})..."
echo ""

# Run tests and expect failure
if eval "$TEST_CMD" 2>&1; then
    echo ""
    print_error "Tests are passing! This violates the RED phase."
    echo ""
    echo -e "${YELLOW}${BOLD}What went wrong?${NC}"
    echo -e "  In TDD, tests ${BOLD}must fail first${NC} to prove:"
    echo -e "  1. The feature doesn't exist yet"
    echo -e "  2. The test actually tests something"
    echo -e "  3. You're not accidentally testing existing code"
    echo ""
    echo -e "${BOLD}Next steps:${NC}"
    echo -e "  → Write a test that fails (tests new behavior)"
    echo -e "  → Or verify you're testing the right thing"
    echo ""
    exit 1
fi

echo ""
print_success "Test fails as expected! RED phase complete."
echo ""

# ============================================================================
# GREEN PHASE: Make It Pass
# ============================================================================
print_banner "$GREEN" "🟢 PHASE 2: GREEN - Make It Pass"

echo -e "${BOLD}Instructions:${NC}"
print_step "Implement the ${BOLD}minimum code${NC} needed to make the test pass"
print_step "${BOLD}No optimization${NC} - just make it work"
print_step "${BOLD}No extra features${NC} - only what the test requires"
print_step "Keep it simple - you'll refactor later"
echo ""
echo -e "${YELLOW}${BOLD}Why this matters:${NC}"
echo -e "  The simplest solution that passes reveals the real requirements."
echo -e "  Premature optimization is the root of all evil."
echo ""

read -p "Press Enter when your implementation is ready..."

echo ""
print_step "Running tests (expecting ${GREEN}${BOLD}SUCCESS${NC})..."
echo ""

# Run tests and expect success
if ! eval "$TEST_CMD" 2>&1; then
    echo ""
    print_error "Tests are still failing!"
    echo ""
    echo -e "${YELLOW}${BOLD}What to do:${NC}"
    echo -e "  → Review the test failure output above"
    echo -e "  → Fix the implementation"
    echo -e "  → Run: ${CYAN}$TEST_CMD${NC}"
    echo -e "  → Repeat until tests pass"
    echo ""
    echo "Run this script again when tests pass to continue to REFACTOR phase."
    exit 1
fi

echo ""
print_success "Tests pass! GREEN phase complete."
echo ""

# ============================================================================
# REFACTOR PHASE: Improve Quality
# ============================================================================
print_banner "$BLUE" "🔵 PHASE 3: REFACTOR - Improve Quality"

echo -e "${BOLD}Instructions:${NC}"
print_step "Improve code ${BOLD}without changing behavior${NC}"
print_step "Clean up: remove duplication, improve names, simplify logic"
print_step "Make small changes and ${BOLD}run tests after each${NC}"
print_step "If tests fail, undo and try a different refactoring"
echo ""
echo -e "${YELLOW}${BOLD}Refactoring checklist:${NC}"
echo -e "  □ Remove duplicated code"
echo -e "  □ Improve variable/function names"
echo -e "  □ Simplify complex conditionals"
echo -e "  □ Extract magic numbers to constants"
echo -e "  □ Break down large functions"
echo -e "  □ Add comments for complex logic"
echo ""
echo -e "${YELLOW}${BOLD}Why this matters:${NC}"
echo -e "  Refactoring with tests gives you ${BOLD}confidence${NC}."
echo -e "  You can improve code without fear of breaking it."
echo ""

read -p "Press Enter when refactoring is complete..."

echo ""
print_step "Running final verification with coverage..."
echo ""

# Run tests with coverage
if ! eval "$COVERAGE_CMD" 2>&1; then
    echo ""
    print_error "Tests failed after refactoring!"
    echo ""
    echo -e "${YELLOW}${BOLD}What happened:${NC}"
    echo -e "  Your refactoring changed the behavior (broke the tests)."
    echo ""
    echo -e "${BOLD}Next steps:${NC}"
    echo -e "  → Undo your last change"
    echo -e "  → Make smaller refactoring steps"
    echo -e "  → Run tests after EACH change"
    echo ""
    exit 1
fi

echo ""
print_success "All tests pass after refactoring!"
echo ""

# ============================================================================
# COMPLETION SUMMARY
# ============================================================================
print_banner "$GREEN" "✅ TDD CYCLE COMPLETE: $FEATURE"

echo -e "${BOLD}What you accomplished:${NC}"
echo -e "  ${RED}🔴${NC} Wrote a failing test that defined the requirement"
echo -e "  ${GREEN}🟢${NC} Implemented the simplest code to make it pass"
echo -e "  ${BLUE}🔵${NC} Refactored to improve quality without breaking tests"
echo ""

echo -e "${BOLD}Code Quality Summary:${NC}"
# Show test count
TEST_COUNT=$(eval "$TEST_CMD_QUIET" 2>&1 | grep -oP '\d+(?= passed)' | head -1 || echo "?")
echo -e "  Tests: ${GREEN}$TEST_COUNT passed${NC}"

# Show coverage if available
if [[ "$LANG" == "python" ]]; then
    COVERAGE=$(pytest "$TEST_FILE" --cov=. --cov-report=term 2>/dev/null | grep "^TOTAL" | awk '{print $NF}' || echo "N/A")
    echo -e "  Coverage: ${CYAN}$COVERAGE${NC}"
fi
echo ""

echo -e "${BOLD}Next steps:${NC}"
print_step "Review your changes: ${CYAN}git diff${NC}"
print_step "Run full test suite: ${CYAN}$TEST_RUNNER${NC}"
print_step "Self-review before commit: ${CYAN}./scripts/self-review.sh${NC}"
print_step "Commit with: ${CYAN}git add . && git commit -m \"feat($FEATURE): <description>\"${NC}"
echo ""

echo -e "${CYAN}${BOLD}Remember:${NC} Every feature follows this cycle: ${RED}RED${NC} → ${GREEN}GREEN${NC} → ${BLUE}REFACTOR${NC}"
echo ""

print_success "Happy coding! 🚀"
