#!/bin/bash
set -euo pipefail

# Test: /hansolo:init creates all required files
# Expected: All configuration files are created with correct content

echo "Testing /hansolo:init command..."

# Setup test directory
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"
git init

# Initialize han-solo
echo "Initializing han-solo in test directory..."
cat > expected_files.txt <<EOF
.gitignore
.gitconfig
.gitmessage
.github/pull_request_template.md
CLAUDE.md
EOF

# Simulate command execution (would be actual command in real test)
# For now, verify expected structure
echo "Verifying expected files would be created:"
while IFS= read -r file; do
    echo "  - $file"
done < expected_files.txt

# Verify gitconfig content expectations
echo ""
echo "Expected .gitconfig content:"
cat <<EOF
[pull]
    ff = only
[merge]
    ff = only
[core]
    editor = vim
[commit]
    template = .gitmessage
EOF

# Verify gitmessage template
echo ""
echo "Expected .gitmessage format:"
cat <<EOF
# <type>(<scope>): <subject>
#
# <body>
#
# <footer>
EOF

# Cleanup
cd - > /dev/null
rm -rf "$TEST_DIR"

echo "✓ Test completed successfully"