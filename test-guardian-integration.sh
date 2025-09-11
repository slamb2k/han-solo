#!/usr/bin/env bash
# Test script to verify bootstrap and quality-gates guardian integration

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

echo -e "${BOLD}Testing Bootstrap → Quality Gates Integration${NC}"
echo "================================================"
echo

# Create a test directory
TEST_DIR="/tmp/guardian-test-$(date +%s)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo -e "${YELLOW}1. Creating test project...${NC}"
cat > package.json << 'EOF'
{
  "name": "test-project",
  "version": "1.0.0",
  "scripts": {
    "build": "echo 'Building...'",
    "test": "echo 'Testing...'"
  },
  "devDependencies": {
    "typescript": "^5.0.0"
  }
}
EOF

# Initialize git
git init
git add .
git commit -m "Initial commit"

echo -e "${YELLOW}2. Simulating bootstrap workflow with placeholders...${NC}"
mkdir -p .github/workflows
cat > .github/workflows/ci.yml << 'EOF'
name: CI
on:
  push:
    branches: [main]
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  # PLACEHOLDER:TEST-SUITE
  # quality-gates-guardian will insert test-suite job here
  
  format:
    name: "🧹 Format"
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: pnpm install --frozen-lockfile
      - name: "Check formatting"
        # PLACEHOLDER:FORMAT-COMMAND
        run: pnpm run format:check --if-present

  lint:
    name: "🔎 Lint"
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: pnpm install --frozen-lockfile
      - name: "Run linting"
        # PLACEHOLDER:LINT-COMMAND
        run: pnpm run lint --if-present

  build:
    name: "🛠️ Build"
    runs-on: ubuntu-latest
    # PLACEHOLDER:BUILD-DEPENDENCIES
    needs: [format, lint]
    steps:
      - uses: actions/checkout@v4
      - run: pnpm install --frozen-lockfile
      - name: "Building project"
        # PLACEHOLDER:BUILD-COMMAND
        run: pnpm run build --if-present
EOF

echo -e "${GREEN}✓ Bootstrap workflow created with placeholders${NC}"
echo

echo -e "${YELLOW}3. Checking for placeholders...${NC}"
if grep -q "PLACEHOLDER:" .github/workflows/ci.yml; then
  echo -e "${GREEN}✓ Placeholders detected:${NC}"
  grep "PLACEHOLDER:" .github/workflows/ci.yml | sed 's/.*PLACEHOLDER:/  - /' | sort -u
else
  echo -e "${RED}✗ No placeholders found${NC}"
fi
echo

echo -e "${YELLOW}4. Running quality-gates placeholder detection...${NC}"
# Source the script functions (don't run main)
source <(sed '/^main$/,$d' "$OLDPWD/scripts/quality-gates-core.sh")

# Test placeholder detection
if check_bootstrap_placeholders; then
  echo -e "${GREEN}✓ Bootstrap placeholders detected successfully${NC}"
else
  echo -e "${RED}✗ Failed to detect placeholders${NC}"
fi
echo

echo -e "${YELLOW}5. Testing evolution detection...${NC}"
# Add some evolution indicators
mkdir -p tests
touch Dockerfile
if detect_evolution; then
  echo -e "${GREEN}✓ Evolution detected successfully${NC}"
else
  echo -e "${YELLOW}⚠ No evolution detected${NC}"
fi
echo

echo -e "${YELLOW}6. Simulating placeholder filling...${NC}"
# Set required variables for fill_workflow_placeholders
LANGUAGE="typescript"
HAS_TYPESCRIPT=true

# Test filling placeholders
fill_workflow_placeholders
echo

echo -e "${YELLOW}7. Verifying placeholders were filled...${NC}"
if grep -q "PLACEHOLDER:" .github/workflows/ci.yml; then
  echo -e "${RED}✗ Placeholders still present:${NC}"
  grep "PLACEHOLDER:" .github/workflows/ci.yml | head -5
else
  echo -e "${GREEN}✓ All placeholders filled successfully${NC}"
fi

# Check if test-suite was added
if grep -q "test-suite:" .github/workflows/ci.yml; then
  echo -e "${GREEN}✓ Test suite job added${NC}"
else
  echo -e "${RED}✗ Test suite job not added${NC}"
fi

# Check if test-suite.yml was created
if [ -f ".github/workflows/test-suite.yml" ]; then
  echo -e "${GREEN}✓ Test suite workflow created${NC}"
else
  echo -e "${RED}✗ Test suite workflow not created${NC}"
fi
echo

echo -e "${BOLD}${GREEN}Integration Test Complete!${NC}"
echo -e "Test directory: $TEST_DIR"
echo
echo "To inspect results:"
echo "  cd $TEST_DIR"
echo "  cat .github/workflows/ci.yml"
echo "  cat .github/workflows/test-suite.yml"