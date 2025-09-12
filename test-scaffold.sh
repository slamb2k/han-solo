#!/usr/bin/env bash
# Test the new scaffold system

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'
BOLD='\033[1m'

echo -e "${BOLD}${BLUE}Testing Scaffold System${NC}"
echo "================================"
echo

# Create test directory
TEST_DIR="/tmp/scaffold-test-$(date +%s)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo -e "${YELLOW}1. Creating test project...${NC}"
cat > package.json << 'EOF'
{
  "name": "test-scaffold-project",
  "version": "1.0.0",
  "scripts": {
    "build": "echo 'Building project...'",
    "test": "echo 'Running tests...'",
    "lint": "echo 'Linting code...'",
    "format:check": "echo 'Checking format...'"
  },
  "devDependencies": {
    "typescript": "^5.0.0",
    "react": "^18.0.0",
    "next": "^14.0.0"
  }
}
EOF

# Create tsconfig for TypeScript detection
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "es5",
    "module": "commonjs",
    "strict": true
  }
}
EOF

# Initialize git
git init
git config user.email "test@example.com"
git config user.name "Test User"
git add .
git commit -m "Initial commit"

echo -e "${GREEN}✓ Test project created${NC}"
echo

echo -e "${YELLOW}2. Running scaffold-core with Next.js configuration...${NC}"
"$OLDPWD/scripts/scaffold-core.sh" \
  --language typescript \
  --framework nextjs \
  --package-manager pnpm \
  --project-type application \
  --deploy-target vercel \
  --setup-protection false \
  --setup-husky false \
  --create-workflows true

echo
echo -e "${YELLOW}3. Verifying created files...${NC}"

# Check if workflows were created
check_file() {
  if [ -f "$1" ]; then
    echo -e "${GREEN}✓${NC} $1 exists"
    return 0
  else
    echo -e "${RED}✗${NC} $1 missing"
    return 1
  fi
}

echo -e "${BLUE}Checking reusable workflows:${NC}"
check_file ".github/workflows/reusable-lint.yml"
check_file ".github/workflows/reusable-test.yml"
check_file ".github/workflows/reusable-build.yml"
check_file ".github/workflows/reusable-release.yml"
check_file ".github/workflows/ci.yml"

echo
echo -e "${YELLOW}4. Checking workflow structure...${NC}"

# Verify CI workflow uses reusable workflows
if grep -q "uses: ./.github/workflows/reusable-lint.yml" .github/workflows/ci.yml; then
  echo -e "${GREEN}✓${NC} CI workflow uses reusable-lint.yml"
else
  echo -e "${RED}✗${NC} CI workflow doesn't use reusable-lint.yml"
fi

if grep -q "uses: ./.github/workflows/reusable-test.yml" .github/workflows/ci.yml; then
  echo -e "${GREEN}✓${NC} CI workflow uses reusable-test.yml"
else
  echo -e "${RED}✗${NC} CI workflow doesn't use reusable-test.yml"
fi

if grep -q "uses: ./.github/workflows/reusable-build.yml" .github/workflows/ci.yml; then
  echo -e "${GREEN}✓${NC} CI workflow uses reusable-build.yml"
else
  echo -e "${RED}✗${NC} CI workflow doesn't use reusable-build.yml"
fi

if grep -q "uses: ./.github/workflows/reusable-release.yml" .github/workflows/ci.yml; then
  echo -e "${GREEN}✓${NC} CI workflow uses reusable-release.yml"
else
  echo -e "${RED}✗${NC} CI workflow doesn't use reusable-release.yml"
fi

echo
echo -e "${YELLOW}5. Checking placeholder workflows...${NC}"

# Check if test workflow is placeholder
if grep -q "placeholder" .github/workflows/reusable-test.yml; then
  echo -e "${GREEN}✓${NC} Test workflow is a placeholder (as expected)"
else
  echo -e "${RED}✗${NC} Test workflow is not a placeholder"
fi

# Check if release workflow is placeholder
if grep -q "placeholder" .github/workflows/reusable-release.yml; then
  echo -e "${GREEN}✓${NC} Release workflow is a placeholder (as expected)"
else
  echo -e "${RED}✗${NC} Release workflow is not a placeholder"
fi

# Check if lint workflow has actual implementation
if grep -q "Run ESLint" .github/workflows/reusable-lint.yml; then
  echo -e "${GREEN}✓${NC} Lint workflow has implementation"
else
  echo -e "${RED}✗${NC} Lint workflow missing implementation"
fi

# Check if build workflow has actual implementation
if grep -q "Build project" .github/workflows/reusable-build.yml; then
  echo -e "${GREEN}✓${NC} Build workflow has implementation"
else
  echo -e "${RED}✗${NC} Build workflow missing implementation"
fi

echo
echo -e "${BOLD}${GREEN}✅ Scaffold Test Complete!${NC}"
echo
echo "Test artifacts location: $TEST_DIR"
echo
echo "To inspect the created workflows:"
echo "  cd $TEST_DIR"
echo "  ls -la .github/workflows/"
echo "  cat .github/workflows/ci.yml"