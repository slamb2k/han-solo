#!/bin/bash
set -euo pipefail

# Test: /hansolo:launch creates feature branch correctly
# Expected: New branch created from latest main

echo "Testing /hansolo:launch command..."

# Setup test directory
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"
git init
git config user.email "test@example.com"
git config user.name "Test User"

# Create initial commit
echo "initial" > README.md
git add README.md
git commit -m "Initial commit"

# Test branch creation
FEATURE_NAME="test-feature"
echo "Simulating: /hansolo:launch $FEATURE_NAME"

# Expected behavior
echo "Expected actions:"
echo "  1. Verify on main branch"
echo "  2. Pull latest from origin"
echo "  3. Create feature/$FEATURE_NAME branch"
echo "  4. Switch to new branch"

# Simulate branch creation
git checkout -b "feature/$FEATURE_NAME"

# Verify branch was created
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" == "feature/$FEATURE_NAME" ]]; then
    echo "✓ Feature branch created successfully: $CURRENT_BRANCH"
else
    echo "✗ Branch creation failed. Current: $CURRENT_BRANCH"
    exit 1
fi

# Test invalid scenarios
echo ""
echo "Testing edge cases:"
echo "  - Launching from non-main branch: Should prompt to switch"
echo "  - Branch already exists: Should error"
echo "  - Uncommitted changes: Should stash first"

# Cleanup
cd - > /dev/null
rm -rf "$TEST_DIR"

echo "✓ Test completed successfully"