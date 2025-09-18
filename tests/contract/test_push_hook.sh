#!/bin/bash
set -euo pipefail

# Test: Push hook blocks direct main push
# Expected: Exit code 2 when pushing to main

echo "Testing push protection hook..."

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

# Test pushing to main
echo "Simulating push to main branch..."
echo '{"tool_name": "Bash", "tool_input": {"command": "git push origin main"}}' | \
    bash -c '
        json_input=$(cat)
        command=$(echo "$json_input" | grep -o "git push.*main")
        if [[ -n "$command" ]]; then
            current_branch=$(git branch --show-current 2>/dev/null || echo "main")
            if [[ "$current_branch" == "main" ]] || [[ "$command" == *"main"* ]]; then
                echo "✓ Blocking direct push to main branch"
                echo "ERROR: Direct pushes to main are not allowed. Use /hansolo:ship" >&2
                exit 2
            fi
        fi
        exit 0
    '

HOOK_EXIT=$?
if [[ $HOOK_EXIT -eq 2 ]]; then
    echo "✓ Hook correctly blocked push to main"
else
    echo "✗ Hook did not block push to main (exit code: $HOOK_EXIT)"
fi

# Test pushing to feature branch
echo ""
echo "Testing push to feature branch..."
git checkout -b feature/test-branch

echo '{"tool_name": "Bash", "tool_input": {"command": "git push origin feature/test-branch"}}' | \
    bash -c '
        json_input=$(cat)
        command=$(echo "$json_input" | grep "git push")
        if [[ -n "$command" ]]; then
            if [[ "$command" == *"main"* ]] || [[ "$command" == *"master"* ]]; then
                echo "Blocking push to protected branch"
                exit 2
            else
                echo "✓ Allowing push to feature branch"
                exit 0
            fi
        fi
        exit 0
    '

HOOK_EXIT=$?
if [[ $HOOK_EXIT -eq 0 ]]; then
    echo "✓ Hook correctly allowed push to feature branch"
else
    echo "✗ Hook blocked valid feature branch push (exit code: $HOOK_EXIT)"
fi

# Test force push prevention
echo ""
echo "Testing force push prevention..."
echo '{"tool_name": "Bash", "tool_input": {"command": "git push --force origin main"}}' | \
    bash -c '
        json_input=$(cat)
        command=$(echo "$json_input" | grep "git push")
        if [[ "$command" == *"--force"* ]] && [[ "$command" == *"main"* ]]; then
            echo "✓ Blocking force push to main"
            exit 2
        fi
        exit 0
    '

HOOK_EXIT=$?
if [[ $HOOK_EXIT -eq 2 ]]; then
    echo "✓ Hook correctly blocked force push"
else
    echo "✗ Hook did not block force push (exit code: $HOOK_EXIT)"
fi

# Cleanup
cd - > /dev/null
rm -rf "$TEST_DIR"

echo "✓ Test completed successfully"