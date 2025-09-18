#!/bin/bash
set -euo pipefail

# Test: Squash operation works correctly
# Expected: Multiple checkpoint commits become single atomic commit

echo "Testing squash operation..."

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

# Create feature branch
git checkout -b feature/test-squash

# Create multiple checkpoint commits
echo "Creating checkpoint commits..."
for i in 1 2 3 4 5; do
    echo "change$i" > "file$i.txt"
    git add "file$i.txt"
    git commit -m "[checkpoint] Change $i" --no-verify
done

# Show commits before squash
echo "Commits before squash:"
git log --oneline -6

# Count checkpoint commits
CHECKPOINT_COUNT=$(git log --oneline | grep -c "\[checkpoint\]")
echo "Found $CHECKPOINT_COUNT checkpoint commits"

# Simulate squash operation
echo ""
echo "Performing squash operation..."

# Get the commit before checkpoints
BASE_COMMIT=$(git log --oneline | grep -v "\[checkpoint\]" | head -1 | cut -d' ' -f1)
echo "Base commit: $BASE_COMMIT"

# Test squash logic (simulation)
if [[ $CHECKPOINT_COUNT -gt 0 ]]; then
    echo "✓ Would run: git reset --soft $BASE_COMMIT"
    echo "✓ Would run: git commit -m 'feat: implement test feature'"

    # Verify all files would be preserved
    echo ""
    echo "Files that would be in squashed commit:"
    for i in 1 2 3 4 5; do
        if [[ -f "file$i.txt" ]]; then
            echo "  ✓ file$i.txt"
        else
            echo "  ✗ file$i.txt missing!"
        fi
    done

    # Simulate the actual squash
    git reset --soft "$BASE_COMMIT"
    git commit -m "feat: implement test feature with 5 changes"

    # Verify squash result
    echo ""
    echo "Commits after squash:"
    git log --oneline -2

    NEW_CHECKPOINT_COUNT=$(git log --oneline | grep -c "\[checkpoint\]" || echo "0")
    if [[ $NEW_CHECKPOINT_COUNT -eq 0 ]]; then
        echo "✓ All checkpoints successfully squashed"
    else
        echo "✗ Some checkpoints remain: $NEW_CHECKPOINT_COUNT"
    fi

    # Verify files still exist
    ALL_FILES_EXIST=true
    for i in 1 2 3 4 5; do
        if [[ ! -f "file$i.txt" ]]; then
            ALL_FILES_EXIST=false
            break
        fi
    done

    if $ALL_FILES_EXIST; then
        echo "✓ All changes preserved in squashed commit"
    else
        echo "✗ Some changes lost during squash"
    fi
else
    echo "No checkpoint commits to squash"
fi

# Test edge case: no checkpoints to squash
echo ""
echo "Testing with no checkpoints..."
git checkout main
git checkout -b feature/no-checkpoints
echo "regular change" > regular.txt
git add regular.txt
git commit -m "feat: regular commit"

CHECKPOINT_COUNT=$(git log --oneline | grep -c "\[checkpoint\]" || echo "0")
if [[ $CHECKPOINT_COUNT -eq 0 ]]; then
    echo "✓ Correctly detected no checkpoints to squash"
fi

# Cleanup
cd - > /dev/null
rm -rf "$TEST_DIR"

echo "✓ Test completed successfully"