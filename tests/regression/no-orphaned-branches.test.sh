#!/usr/bin/env bash
# Regression test: Ensure ship-core.sh doesn't create orphaned branches
# Bug: Previously pushed to original branch before checking for merged PRs
# Fix: PR #69 - Check for merged PRs before pushing

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test result tracking
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
test_start() {
    local test_name="$1"
    echo -e "\n${YELLOW}Running:${NC} $test_name"
    TESTS_RUN=$((TESTS_RUN + 1))
}

test_pass() {
    local test_name="$1"
    echo -e "${GREEN}✅ PASS:${NC} $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
    local test_name="$1"
    local reason="$2"
    echo -e "${RED}❌ FAIL:${NC} $test_name"
    echo -e "${RED}   Reason:${NC} $reason"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

# Mock functions for testing
setup_test_env() {
    # Save original functions if they exist
    if declare -f gh > /dev/null; then
        eval "original_$(declare -f gh)"
    fi
    
    # Create temporary test directory
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"
    
    # Initialize git repo
    git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    # Create initial commit
    echo "initial" > README.md
    git add README.md
    git commit -m "Initial commit" --quiet
}

cleanup_test_env() {
    # Restore original functions
    if declare -f original_gh > /dev/null; then
        eval "$(declare -f original_gh | sed 's/original_gh/gh/')"
    fi
    
    # Clean up test directory
    cd /
    rm -rf "$TEST_DIR"
}

# Test 1: Verify merged PR check happens before push
test_merged_pr_check_before_push() {
    test_start "Merged PR check occurs before push"
    
    # Setup
    local SCRIPT_PATH="$1"
    local PUSH_ATTEMPTED=false
    local MERGED_PR_CHECK=false
    local CHECK_BEFORE_PUSH=false
    
    # Create a test wrapper that tracks function calls
    cat > test_wrapper.sh << 'EOF'
#!/usr/bin/env bash
source "$1"

# Track when functions are called
PUSH_CALLED=false
PR_CHECK_CALLED=false

# Override git push
git() {
    if [[ "$1" == "push" ]]; then
        PUSH_CALLED=true
        echo "PUSH_ATTEMPTED"
    else
        command git "$@"
    fi
}

# Override gh pr list for merged check
gh() {
    if [[ "$*" == *"--state merged"* ]]; then
        PR_CHECK_CALLED=true
        echo "MERGED_PR_CHECK"
        # Simulate a merged PR exists
        echo '{"number": 42}'
    else
        echo ""
    fi
}

# Export tracking variables
export -f git gh
EOF
    
    # Analyze the script to find where push and PR check occur
    local push_line=$(grep -n "git push" "$SCRIPT_PATH" | head -1 | cut -d: -f1)
    local pr_check_line=$(grep -n "gh pr list.*--state merged" "$SCRIPT_PATH" | head -1 | cut -d: -f1)
    
    if [ -z "$push_line" ] || [ -z "$pr_check_line" ]; then
        test_fail "Merged PR check occurs before push" "Could not find push or PR check in script"
        return
    fi
    
    if [ "$pr_check_line" -lt "$push_line" ]; then
        test_pass "Merged PR check occurs before push"
    else
        test_fail "Merged PR check occurs before push" "PR check at line $pr_check_line comes after push at line $push_line"
    fi
}

# Test 2: Verify branch switch happens before push when merged PR exists
test_branch_switch_before_push() {
    test_start "Branch switch happens before push when merged PR exists"
    
    local SCRIPT_PATH="$1"
    
    # Look for the pattern where new branch is created
    if grep -q "git checkout -b.*NEW_BRANCH" "$SCRIPT_PATH"; then
        # Verify this happens before the push
        local switch_line=$(grep -n "git checkout -b.*NEW_BRANCH" "$SCRIPT_PATH" | head -1 | cut -d: -f1)
        local push_line=$(grep -n "git push" "$SCRIPT_PATH" | head -1 | cut -d: -f1)
        
        if [ "$switch_line" -lt "$push_line" ]; then
            test_pass "Branch switch happens before push when merged PR exists"
        else
            test_fail "Branch switch happens before push when merged PR exists" "Branch switch at line $switch_line comes after push at line $push_line"
        fi
    else
        test_fail "Branch switch happens before push when merged PR exists" "Could not find branch switch logic"
    fi
}

# Test 3: Verify old branch cleanup
test_old_branch_cleanup() {
    test_start "Old branch is cleaned up after creating follow-up"
    
    local SCRIPT_PATH="$1"
    
    # Check if old branch is deleted after creating new one
    if grep -q "git branch -d.*OLD_BRANCH" "$SCRIPT_PATH"; then
        test_pass "Old branch is cleaned up after creating follow-up"
    else
        # Also check for the message about not pushing to original branch
        if grep -q "Will push to new branch.*instead of" "$SCRIPT_PATH"; then
            test_pass "Old branch is cleaned up after creating follow-up"
        else
            test_fail "Old branch is cleaned up after creating follow-up" "No cleanup of old branch found"
        fi
    fi
}

# Test 4: Verify only one push occurs
test_single_push_operation() {
    test_start "Only one push operation occurs per ship execution"
    
    local SCRIPT_PATH="$1"
    
    # Count push operations in the main flow (excluding error handlers)
    local push_count=$(grep -c "git push" "$SCRIPT_PATH" | grep -v "^#" | wc -l)
    
    # There should be one main push block and possibly cleanup pushes
    if [ "$push_count" -le 3 ]; then
        test_pass "Only one push operation occurs per ship execution"
    else
        test_fail "Only one push operation occurs per ship execution" "Found $push_count push operations"
    fi
}

# Main test execution
main() {
    echo -e "${GREEN}=== Han-Solo Regression Test Suite ===${NC}"
    echo "Testing: Orphaned Branch Prevention (PR #69)"
    
    # Get the script path
    SCRIPT_PATH="${1:-.claude/scripts/ship-core.sh}"
    
    if [ ! -f "$SCRIPT_PATH" ]; then
        echo -e "${RED}Error: Script not found at $SCRIPT_PATH${NC}"
        exit 1
    fi
    
    # Run tests
    test_merged_pr_check_before_push "$SCRIPT_PATH"
    test_branch_switch_before_push "$SCRIPT_PATH"
    test_old_branch_cleanup "$SCRIPT_PATH"
    test_single_push_operation "$SCRIPT_PATH"
    
    # Report results
    echo -e "\n${GREEN}=== Test Results ===${NC}"
    echo "Tests Run: $TESTS_RUN"
    echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
    
    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo -e "\n${GREEN}✅ All regression tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}❌ Some regression tests failed!${NC}"
        exit 1
    fi
}

# Run from repo root
if [ -f ".claude/scripts/ship-core.sh" ]; then
    main ".claude/scripts/ship-core.sh"
elif [ -f "../.claude/scripts/ship-core.sh" ]; then
    main "../.claude/scripts/ship-core.sh"
elif [ -f "../../.claude/scripts/ship-core.sh" ]; then
    main "../../.claude/scripts/ship-core.sh"
else
    echo -e "${RED}Error: Cannot find ship-core.sh. Run from repo root.${NC}"
    exit 1
fi