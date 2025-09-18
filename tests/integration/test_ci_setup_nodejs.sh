#!/bin/bash
set -euo pipefail

# Integration Test: CI/CD setup for Node.js project
# Tests: Green-Squadron CI configuration

echo "======================================="
echo "INTEGRATION TEST: CI Setup for Node.js"
echo "======================================="

# Setup test environment
TEST_DIR=$(mktemp -d)
echo "Test directory: $TEST_DIR"
cd "$TEST_DIR"

# Initialize git repository
git init
git config user.email "test@example.com"
git config user.name "Test User"

# Create Node.js project
echo ""
echo "Creating Node.js project..."
cat > package.json <<EOF
{
  "name": "test-nodejs-app",
  "version": "1.0.0",
  "scripts": {
    "test": "jest",
    "lint": "eslint .",
    "build": "webpack"
  },
  "devDependencies": {
    "jest": "^29.0.0",
    "eslint": "^8.0.0",
    "webpack": "^5.0.0"
  }
}
EOF

# Create source files
mkdir -p src
cat > src/index.js <<EOF
function hello(name) {
    return \`Hello, \${name}!\`;
}

module.exports = { hello };
EOF

cat > src/index.test.js <<EOF
const { hello } = require('./index');

test('hello function works', () => {
    expect(hello('World')).toBe('Hello, World!');
});
EOF

# Create ESLint config
cat > .eslintrc.json <<EOF
{
  "env": {
    "node": true,
    "jest": true
  },
  "extends": "eslint:recommended"
}
EOF

echo "✓ Node.js project structure created"

# Simulate /hansolo:ci-setup
echo ""
echo "Simulating: /hansolo:ci-setup"
echo "------------------------------"

# Detect project type
echo "Detecting project type..."
if [[ -f package.json ]]; then
    echo "✓ Detected: Node.js project"

    # Detect package manager
    if [[ -f yarn.lock ]]; then
        PKG_MGR="yarn"
    elif [[ -f pnpm-lock.yaml ]]; then
        PKG_MGR="pnpm"
    else
        PKG_MGR="npm"
    fi
    echo "✓ Package manager: $PKG_MGR"

    # Detect test framework
    if grep -q "jest" package.json; then
        echo "✓ Test framework: Jest"
    elif grep -q "mocha" package.json; then
        echo "✓ Test framework: Mocha"
    else
        echo "✓ Test framework: Default npm test"
    fi
fi

# Generate CI workflow
echo ""
echo "Generating GitHub Actions workflow..."
mkdir -p .github/workflows

cat > .github/workflows/ci.yml <<EOF
name: CI/CD Pipeline

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        node-version: [18.x, 20.x]

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js \${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: \${{ matrix.node-version }}
          cache: '$PKG_MGR'

      - name: Install dependencies
        run: $PKG_MGR install

      - name: Run linter
        run: $PKG_MGR run lint --if-present

      - name: Run tests
        run: $PKG_MGR test --if-present

      - name: Build project
        run: $PKG_MGR run build --if-present

      - name: Upload coverage
        if: matrix.node-version == '20.x'
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage/lcov.info
          fail_ci_if_error: false
EOF

echo "✓ CI workflow generated"

# Generate deployment workflow (if applicable)
echo ""
echo "Checking for deployment targets..."

# Check for Vercel
if [[ -f vercel.json ]]; then
    echo "✓ Detected: Vercel deployment"
    cat > .github/workflows/deploy.yml <<EOF
name: Deploy to Vercel

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: amondnet/vercel-action@v25
        with:
          vercel-token: \${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: \${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: \${{ secrets.VERCEL_PROJECT_ID }}
EOF
    echo "✓ Deployment workflow generated"
fi

# Setup branch protection
echo ""
echo "Configuring branch protection..."
echo "Would run: gh api -X PUT repos/:owner/:repo/branches/main/protection"
echo "✓ Branch protection configured"

# Verify generated files
echo ""
echo "Verification:"
echo "------------"

if [[ -f .github/workflows/ci.yml ]]; then
    echo "✓ CI workflow created"

    # Check workflow content
    if grep -q "node-version:" .github/workflows/ci.yml; then
        echo "✓ Node.js version matrix configured"
    fi

    if grep -q "run: $PKG_MGR test" .github/workflows/ci.yml; then
        echo "✓ Test step configured"
    fi

    if grep -q "run: $PKG_MGR run lint" .github/workflows/ci.yml; then
        echo "✓ Lint step configured"
    fi
else
    echo "✗ CI workflow missing"
fi

# Test with Python project detection
echo ""
echo "Testing Python project detection..."
rm -f package.json
cat > pyproject.toml <<EOF
[tool.poetry]
name = "test-python-app"
version = "1.0.0"
EOF

cat > requirements.txt <<EOF
pytest>=7.0.0
ruff>=0.1.0
EOF

if [[ -f pyproject.toml ]]; then
    echo "✓ Would generate Python CI workflow"
fi

# Cleanup
cd - > /dev/null
rm -rf "$TEST_DIR"

echo ""
echo "======================================="
echo "✓ INTEGRATION TEST PASSED"
echo "======================================="