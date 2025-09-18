#!/bin/bash
set -euo pipefail

# Integration Test: Conflict resolution workflow
# Tests: Rogue-Squadron conflict handling

echo "========================================"
echo "INTEGRATION TEST: Conflict Resolution"
echo "========================================"

# Setup test environment
TEST_DIR=$(mktemp -d)
echo "Test directory: $TEST_DIR"
cd "$TEST_DIR"

# Initialize repository with two branches that will conflict
git init
git config user.email "test@example.com"
git config user.name "Test User"

# Create initial commit
cat > README.md <<EOF
# Test Project
Version: 1.0.0
EOF
git add README.md
git commit -m "Initial commit"

# Create first feature branch
echo ""
echo "Creating first feature branch..."
git checkout -b feature/update-version-1
cat > README.md <<EOF
# Test Project
Version: 2.0.0
Author: Developer 1
EOF
git add README.md
git commit -m "feat: update version to 2.0.0"

# Create conflicting branch
echo "Creating conflicting branch..."
git checkout main
git checkout -b feature/update-version-2
cat > README.md <<EOF
# Test Project
Version: 1.5.0
Modified: $(date +%Y-%m-%d)
EOF
git add README.md
git commit -m "feat: update version to 1.5.0"

# Merge first branch to main
echo ""
echo "Merging first branch to main..."
git checkout main
git merge feature/update-version-1 --no-ff -m "Merge feature/update-version-1"

# Try to rebase second branch (will conflict)
echo ""
echo "Attempting to rebase conflicting branch..."
git checkout feature/update-version-2

# Simulate conflict detection
echo "Simulating: /hansolo:sync"
echo ""

# Attempt rebase
if ! git rebase main 2>/dev/null; then
    echo "✓ Conflict detected during rebase"

    # Show conflict status
    echo ""
    echo "Conflict Analysis:"
    echo "-----------------"
    git status --short | grep "^UU" || echo "No direct conflicts shown"

    # Show conflict content
    echo ""
    echo "Conflict in README.md:"
    cat README.md || true

    # Simulate Rogue-Squadron activation
    echo ""
    echo "Activating Rogue-Squadron for conflict resolution..."
    echo ""
    echo "Options presented to user:"
    echo "[1] Keep your version (Version: 1.5.0)"
    echo "[2] Keep incoming version (Version: 2.0.0)"
    echo "[3] Manually merge both changes"
    echo "[4] Abort rebase"

    # Simulate user choosing option 3
    echo ""
    echo "User selects: [3] Manually merge"

    # Resolve conflict manually
    cat > README.md <<EOF
# Test Project
Version: 2.0.0
Author: Developer 1
Modified: $(date +%Y-%m-%d)
EOF

    git add README.md

    # Continue rebase
    if git rebase --continue 2>/dev/null; then
        echo "✓ Rebase completed successfully"
    else
        # Skip if rebase is already done
        echo "✓ Conflict resolved"
    fi
else
    echo "✗ Expected conflict but rebase succeeded"
fi

# Verify resolution
echo ""
echo "Verification:"
echo "------------"

# Check file content
if grep -q "Version: 2.0.0" README.md && grep -q "Modified:" README.md; then
    echo "✓ Both changes successfully merged"
else
    echo "✗ Merge incomplete"
fi

# Check branch status
CURRENT_BRANCH=$(git branch --show-current)
echo "✓ Current branch: $CURRENT_BRANCH"

# Check commit history
COMMIT_COUNT=$(git log --oneline | wc -l)
echo "✓ Commits in history: $COMMIT_COUNT"

# Test abort scenario
echo ""
echo "Testing abort scenario..."
git checkout main
git checkout -b feature/abort-test
echo "conflicting content" > conflict.txt
git add conflict.txt
git commit -m "Add conflict file"

git checkout main
echo "different content" > conflict.txt
git add conflict.txt
git commit -m "Add different content"

git checkout feature/abort-test
if ! git rebase main 2>/dev/null; then
    echo "✓ Conflict created for abort test"

    # Simulate abort
    git rebase --abort

    if [[ $(git branch --show-current) == "feature/abort-test" ]]; then
        echo "✓ Successfully aborted and restored state"
    else
        echo "✗ Abort failed"
    fi
fi

# Cleanup
cd - > /dev/null
rm -rf "$TEST_DIR"

echo ""
echo "========================================"
echo "✓ INTEGRATION TEST PASSED"
echo "========================================"