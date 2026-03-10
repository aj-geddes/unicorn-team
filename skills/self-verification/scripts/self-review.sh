#!/usr/bin/env bash
#
# self-review.sh - Self-Verification Protocol for Code Quality
#
# Systematic pre-commit review that catches issues before code review.
# Based on the principle: "Never commit code you wouldn't approve in a code review."
#
# Usage:
#   ./scripts/self-review.sh
#   ./scripts/self-review.sh && git commit -m "your message"
#

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_step() {
    echo -e "\n${PURPLE}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not in a git repository. Run this from within your git project."
    exit 1
fi

# Check if there are staged changes
if ! git diff --cached --quiet 2>/dev/null; then
    HAS_STAGED=true
else
    HAS_STAGED=false
fi

print_header "🔍 SELF-REVIEW PROTOCOL"
echo "Quality assurance before commit"
echo ""
echo "Remember: Would I approve this in code review?"

# ============================================================================
# 1. SHOW STAGED CHANGES
# ============================================================================

print_header "📝 STEP 1: REVIEW STAGED CHANGES"

if [ "$HAS_STAGED" = false ]; then
    print_warning "No changes are staged for commit."
    echo ""
    read -p "Would you like to see unstaged changes instead? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_step "Unstaged changes summary:"
        git diff --stat
        echo ""
        print_step "Detailed diff:"
        git diff
    fi
    print_info "Stage your changes with 'git add' and run this script again."
    exit 0
fi

print_step "Staged files summary:"
git diff --cached --stat

echo ""
print_step "Detailed diff (read as if someone else wrote it):"
git diff --cached

# ============================================================================
# 2. COMPLETENESS CHECK (Interactive)
# ============================================================================

print_header "✅ STEP 2: COMPLETENESS CHECK"

echo ""
echo "Review the following criteria carefully:"
echo ""
echo "  □ Does this change do ONE thing well?"
echo "  □ Are all edge cases handled?"
echo "  □ Is error handling complete?"
echo "  □ Are error messages clear and actionable?"
echo "  □ Is input validation in place?"
echo "  □ Are tests comprehensive (not just happy path)?"
echo "  □ Is logging added for key operations?"
echo ""

read -p "Is the implementation complete? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_error "Implementation incomplete. Continue working before committing."
    exit 1
fi
print_success "Completeness verified"

# ============================================================================
# 3. QUALITY CHECK (Automated)
# ============================================================================

print_header "🔍 STEP 3: QUALITY CHECK"

QUALITY_ISSUES=0

# Check for TODO/FIXME/HACK markers
print_step "Checking for TODO/FIXME/HACK markers..."
if git diff --cached | grep -E "^\+.*\b(TODO|FIXME|HACK)\b" > /dev/null 2>&1; then
    print_error "Found TODO/FIXME/HACK markers in staged changes"
    git diff --cached | grep -E "^\+.*\b(TODO|FIXME|HACK)\b" --color=always
    echo ""
    print_warning "Either resolve these or create tracking tickets and remove markers"
    QUALITY_ISSUES=$((QUALITY_ISSUES + 1))
else
    print_success "No TODO/FIXME/HACK markers found"
fi

# Check for debug code
print_step "Checking for debug code..."
DEBUG_PATTERNS="breakpoint\(\)|import pdb|pdb\.set_trace|console\.log|debugger|print\(.*DEBUG|logger\.debug"
if git diff --cached | grep -E "^\+.*($DEBUG_PATTERNS)" > /dev/null 2>&1; then
    print_error "Found debug code in staged changes"
    git diff --cached | grep -E "^\+.*($DEBUG_PATTERNS)" --color=always
    echo ""
    print_warning "Remove debug statements before committing"
    QUALITY_ISSUES=$((QUALITY_ISSUES + 1))
else
    print_success "No debug code found"
fi

# Check for commented code
print_step "Checking for commented code..."
if git diff --cached | grep -E "^\+\s*(#|//|/\*).*(def |function |class |const |let |var )" > /dev/null 2>&1; then
    print_warning "Possible commented-out code detected"
    git diff --cached | grep -E "^\+\s*(#|//|/\*).*(def |function |class |const |let |var )" --color=always
    echo ""
    read -p "Is this intentional documentation/examples? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Delete commented code (it's in git history)"
        QUALITY_ISSUES=$((QUALITY_ISSUES + 1))
    fi
fi

# Check for secrets patterns
print_step "Checking for potential secrets..."
SECRET_PATTERNS="api[_-]?key|password|secret|token|private[_-]?key|credential"
if git diff --cached | grep -iE "^\+.*($SECRET_PATTERNS)\s*=\s*['\"]" > /dev/null 2>&1; then
    print_error "Possible secrets detected in staged changes"
    git diff --cached | grep -iE "^\+.*($SECRET_PATTERNS)\s*=\s*['\"]" --color=always
    echo ""
    print_warning "Verify these are not actual secrets!"
    read -p "Are you CERTAIN these are safe to commit? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Move secrets to environment variables or secret management"
        QUALITY_ISSUES=$((QUALITY_ISSUES + 1))
    fi
else
    print_success "No obvious secrets detected"
fi

if [ $QUALITY_ISSUES -gt 0 ]; then
    print_error "Quality check failed with $QUALITY_ISSUES issue(s)"
    echo ""
    read -p "Fix issues now? (Press Enter to abort, 'c' to continue anyway) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Cc]$ ]]; then
        exit 1
    fi
    print_warning "Continuing despite quality issues..."
else
    print_success "Quality check passed"
fi

# ============================================================================
# 4. TEST VERIFICATION
# ============================================================================

print_header "🧪 STEP 4: TEST VERIFICATION"

# Detect project type and run appropriate tests
TEST_COMMAND=""
COVERAGE_COMMAND=""

if [ -f "pytest.ini" ] || [ -f "pyproject.toml" ] || find . -name "test_*.py" -o -name "*_test.py" 2>/dev/null | grep -q .; then
    # Python project
    if command -v pytest &> /dev/null; then
        print_step "Detected Python project, running pytest..."
        TEST_COMMAND="pytest -v"
        COVERAGE_COMMAND="pytest --cov=. --cov-report=term-missing --cov-fail-under=80 -v"
    else
        print_warning "pytest not found. Install it to run tests."
    fi
elif [ -f "package.json" ]; then
    # Node.js project
    if command -v npm &> /dev/null; then
        print_step "Detected Node.js project, running npm test..."
        TEST_COMMAND="npm test"
        COVERAGE_COMMAND="npm test -- --coverage"
    else
        print_warning "npm not found. Install Node.js to run tests."
    fi
elif [ -f "go.mod" ]; then
    # Go project
    if command -v go &> /dev/null; then
        print_step "Detected Go project, running go test..."
        TEST_COMMAND="go test ./... -v"
        COVERAGE_COMMAND="go test ./... -cover -coverprofile=coverage.out"
    else
        print_warning "go not found. Install Go to run tests."
    fi
else
    print_warning "Could not detect project type. Skipping automated tests."
    print_info "Manually verify that all tests pass."
fi

# Run tests if we found a test command
if [ -n "$COVERAGE_COMMAND" ]; then
    echo ""
    if eval "$COVERAGE_COMMAND"; then
        print_success "Tests passed with adequate coverage"
    else
        print_error "Tests failed or coverage below threshold (80%)"
        echo ""
        read -p "Fix tests now? (Press Enter to abort, 'c' to continue anyway) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Cc]$ ]]; then
            exit 1
        fi
        print_warning "Continuing despite test failures..."
    fi
elif [ -n "$TEST_COMMAND" ]; then
    echo ""
    if eval "$TEST_COMMAND"; then
        print_success "Tests passed"
        print_warning "Coverage check not available - verify manually"
    else
        print_error "Tests failed"
        exit 1
    fi
else
    # Manual verification
    echo ""
    echo "Manual test verification:"
    echo "  □ All tests pass?"
    echo "  □ Coverage ≥ 80%?"
    echo "  □ Edge cases tested?"
    echo "  □ Error paths tested?"
    echo ""
    read -p "Have you run tests and verified coverage? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Run and verify tests before committing"
        exit 1
    fi
    print_success "Test verification confirmed"
fi

# ============================================================================
# 5. DOCUMENTATION CHECK
# ============================================================================

print_header "📚 STEP 5: DOCUMENTATION CHECK"

echo ""
echo "Documentation checklist:"
echo ""
echo "  □ Public APIs/functions have docstrings?"
echo "  □ Complex logic has explanatory comments (WHY, not WHAT)?"
echo "  □ README updated if behavior changed?"
echo "  □ Examples provided for new features?"
echo ""

read -p "Is documentation complete? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Add documentation before committing"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    print_success "Documentation verified"
fi

# ============================================================================
# 6. FINAL REVIEW CHECKLIST
# ============================================================================

print_header "👀 STEP 6: FINAL REVIEW"

echo ""
echo "Take a moment to consider:"
echo ""
echo "  □ Does this change do ONE thing well?"
echo "  □ Would I approve this in code review?"
echo "  □ Is the code clear enough that I won't need to explain it?"
echo "  □ Will this work in production, not just locally?"
echo "  □ Have I considered edge cases and failure modes?"
echo "  □ Is this the simplest solution that could work?"
echo ""

# Fresh eyes check
print_warning "FRESH EYES CHECK:"
print_info "Read the diff one more time as if reviewing someone else's code."
echo ""
read -p "Press Enter to see the diff again (or 's' to skip) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo ""
    git diff --cached
fi

# ============================================================================
# 7. FINAL DECISION
# ============================================================================

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
read -p "Ready to commit? (y/n) " -n 1 -r
echo
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_success "Self-review complete! Proceeding with commit."
    echo ""
    print_info "You can now run: git commit -m \"your message\""
    exit 0
else
    print_warning "Self-review incomplete. Continue working on the code."
    echo ""
    print_info "Unstage changes with: git reset HEAD"
    exit 1
fi
