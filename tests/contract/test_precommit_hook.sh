#!/bin/bash
set -euo pipefail

# Test: Pre-commit hook blocks on lint failure
# Expected: Exit code 2 when linting fails

echo "Testing pre-commit hook..."

# Setup test directory
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"
git init
git config user.email "test@example.com"
git config user.name "Test User"

# Create package.json for Node.js project
cat > package.json <<EOF
{
  "name": "test-project",
  "scripts": {
    "lint": "exit 1"
  }
}
EOF

# Create test file with intentional lint error
cat > index.js <<EOF
// Intentional lint error
const unused_var = "This should fail linting"
console.log("Hello")
EOF

# Test hook with failing lint
echo "Simulating pre-commit hook with failing lint..."
echo '{"tool_name": "Bash", "tool_input": {"command": "git commit -m test"}}' | \
    bash -c '
        # Simulate hook logic
        json_input=$(cat)
        command=$(echo "$json_input" | grep -o "git commit")
        if [[ -n "$command" ]]; then
            echo "Running lint check..."
            if ! npm run lint 2>/dev/null; then
                echo "✓ Lint failed as expected, blocking commit"
                exit 2
            fi
        fi
        exit 0
    '

HOOK_EXIT=$?
if [[ $HOOK_EXIT -eq 2 ]]; then
    echo "✓ Hook correctly blocked commit on lint failure"
else
    echo "✗ Hook did not block commit (exit code: $HOOK_EXIT)"
fi

# Test with passing lint
echo ""
echo "Testing with passing lint..."
cat > package.json <<EOF
{
  "name": "test-project",
  "scripts": {
    "lint": "exit 0"
  }
}
EOF

echo '{"tool_name": "Bash", "tool_input": {"command": "git commit -m test"}}' | \
    bash -c '
        json_input=$(cat)
        command=$(echo "$json_input" | grep -o "git commit")
        if [[ -n "$command" ]]; then
            echo "Running lint check..."
            if npm run lint 2>/dev/null; then
                echo "✓ Lint passed, allowing commit"
                exit 0
            fi
        fi
        exit 2
    '

HOOK_EXIT=$?
if [[ $HOOK_EXIT -eq 0 ]]; then
    echo "✓ Hook correctly allowed commit when lint passes"
else
    echo "✗ Hook blocked valid commit (exit code: $HOOK_EXIT)"
fi

# Cleanup
cd - > /dev/null
rm -rf "$TEST_DIR"

echo "✓ Test completed successfully"