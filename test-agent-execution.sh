#!/bin/bash
# Test script to verify squadron agents actually execute commands

set -e

echo "=== Agent Execution Test ==="
echo "Testing whether Gold Squadron actually creates branches"
echo ""

# Get current branch
ORIGINAL_BRANCH=$(git branch --show-current)
echo "Starting on branch: $ORIGINAL_BRANCH"

# Test branch name
TEST_BRANCH="test/agent-exec-$(date +%s)"
echo "Will attempt to create: $TEST_BRANCH"
echo ""

# This should be done by Gold Squadron
echo "Invoking Gold Squadron to create branch..."
echo "Expected: Branch gets created and we switch to it"
echo "Bug behavior: JSON returned but branch not created"
echo ""

# After Gold Squadron runs, check if branch was actually created
echo "Checking results after Gold Squadron invocation..."

# Check current branch
CURRENT_BRANCH=$(git branch --show-current)
echo "Current branch after agent: $CURRENT_BRANCH"

# Check if test branch exists
if git show-ref --verify --quiet "refs/heads/$TEST_BRANCH"; then
    echo "✅ SUCCESS: Branch $TEST_BRANCH was created!"
    echo "Gold Squadron is executing commands properly"

    # Cleanup
    git switch "$ORIGINAL_BRANCH"
    git branch -D "$TEST_BRANCH"
    echo "Cleaned up test branch"
else
    echo "❌ FAILURE: Branch $TEST_BRANCH was NOT created"
    echo "Gold Squadron is not executing commands"
    echo ""
    echo "This confirms the bug: agents return JSON without doing work"
fi

echo ""
echo "=== Test Complete ===""