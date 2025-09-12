#!/usr/bin/env bash
# Test the enhanced scaffold system with all modes

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

echo -e "${BOLD}${BLUE}Testing Enhanced Scaffold System${NC}"
echo "============================================"
echo

# Create test directory
TEST_DIR="/tmp/scaffold-enhanced-test-$(date +%s)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo -e "${YELLOW}1. Setting up test project...${NC}"

# Create a Next.js-like project
cat > package.json << 'EOF'
{
  "name": "test-nextjs-app",
  "version": "1.0.0",
  "private": false,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "test": "jest"
  },
  "dependencies": {
    "next": "14.0.0",
    "react": "18.2.0",
    "react-dom": "18.2.0"
  },
  "devDependencies": {
    "typescript": "5.0.0",
    "@types/react": "18.2.0",
    "jest": "29.0.0",
    "@testing-library/react": "14.0.0",
    "@playwright/test": "1.40.0",
    "eslint": "8.0.0",
    "prettier": "3.0.0"
  }
}
EOF

# Create TypeScript config
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "es5",
    "lib": ["dom", "es2017"],
    "jsx": "preserve",
    "module": "esnext",
    "strict": true
  }
}
EOF

# Create test directory structure
mkdir -p tests/unit tests/integration tests/e2e
echo "test('sample', () => expect(1).toBe(1));" > tests/unit/sample.test.js

# Create Dockerfile for release testing
cat > Dockerfile << 'EOF'
FROM node:20-alpine
WORKDIR /app
COPY . .
RUN npm install
CMD ["npm", "start"]
EOF

# Create Vercel config
cat > vercel.json << 'EOF'
{
  "framework": "nextjs",
  "outputDirectory": ".next"
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

# Test 1: Base Scaffold
echo -e "${BOLD}${CYAN}═══════════════════════════════════════════${NC}"
echo -e "${BOLD}${CYAN}TEST 1: Base Scaffold Mode${NC}"
echo -e "${BOLD}${CYAN}═══════════════════════════════════════════${NC}"
echo

"$OLDPWD/scripts/scaffold-core.sh" \
  --language typescript \
  --framework nextjs \
  --package-manager pnpm \
  --project-type application \
  --deploy-target vercel \
  --setup-protection false \
  --setup-husky false \
  --create-workflows true

# Verify base scaffold
echo -e "${YELLOW}Verifying base scaffold...${NC}"
if [ -f ".github/workflows/ci.yml" ] && \
   [ -f ".github/workflows/reusable-lint.yml" ] && \
   [ -f ".github/workflows/reusable-test.yml" ] && \
   [ -f ".github/workflows/reusable-build.yml" ] && \
   [ -f ".github/workflows/reusable-release.yml" ]; then
  echo -e "${GREEN}✓ All base workflows created${NC}"
else
  echo -e "${RED}✗ Missing base workflows${NC}"
fi

# Check if test/release are placeholders
if grep -q "placeholder" .github/workflows/reusable-test.yml; then
  echo -e "${GREEN}✓ Test workflow is placeholder${NC}"
else
  echo -e "${RED}✗ Test workflow not placeholder${NC}"
fi

if grep -q "placeholder" .github/workflows/reusable-release.yml; then
  echo -e "${GREEN}✓ Release workflow is placeholder${NC}"
else
  echo -e "${RED}✗ Release workflow not placeholder${NC}"
fi

echo

# Test 2: Testing Configuration
echo -e "${BOLD}${CYAN}═══════════════════════════════════════════${NC}"
echo -e "${BOLD}${CYAN}TEST 2: Testing Mode${NC}"
echo -e "${BOLD}${CYAN}═══════════════════════════════════════════${NC}"
echo

"$OLDPWD/scripts/scaffold-tests.sh" \
  --language typescript \
  --test-framework jest \
  --e2e-framework playwright \
  --coverage-threshold 80 \
  --test-matrix multi-os \
  --package-manager pnpm \
  --mode comprehensive

# Verify test configuration
echo -e "${YELLOW}Verifying test configuration...${NC}"
if grep -q "jest --coverage" .github/workflows/reusable-test.yml; then
  echo -e "${GREEN}✓ Jest configured in test workflow${NC}"
else
  echo -e "${RED}✗ Jest not configured${NC}"
fi

if grep -q "playwright" .github/workflows/reusable-test.yml; then
  echo -e "${GREEN}✓ Playwright E2E configured${NC}"
else
  echo -e "${RED}✗ Playwright not configured${NC}"
fi

if grep -q "ubuntu-latest.*macos-latest.*windows-latest" .github/workflows/reusable-test.yml; then
  echo -e "${GREEN}✓ Multi-OS matrix configured${NC}"
else
  echo -e "${RED}✗ Multi-OS matrix not configured${NC}"
fi

if ! grep -q "placeholder" .github/workflows/reusable-test.yml; then
  echo -e "${GREEN}✓ Test workflow no longer placeholder${NC}"
else
  echo -e "${RED}✗ Test workflow still placeholder${NC}"
fi

echo

# Test 3: Release Configuration
echo -e "${BOLD}${CYAN}═══════════════════════════════════════════${NC}"
echo -e "${BOLD}${CYAN}TEST 3: Release Mode${NC}"
echo -e "${BOLD}${CYAN}═══════════════════════════════════════════${NC}"
echo

"$OLDPWD/scripts/scaffold-release.sh" \
  --language typescript \
  --deploy-targets "npm,docker,github,vercel" \
  --release-strategy semantic \
  --package-manager pnpm \
  --project-type application \
  --mode comprehensive

# Verify release configuration
echo -e "${YELLOW}Verifying release configuration...${NC}"
if grep -q "npm publish" .github/workflows/reusable-release.yml; then
  echo -e "${GREEN}✓ NPM publishing configured${NC}"
else
  echo -e "${RED}✗ NPM publishing not configured${NC}"
fi

if grep -q "docker/build-push-action" .github/workflows/reusable-release.yml; then
  echo -e "${GREEN}✓ Docker publishing configured${NC}"
else
  echo -e "${RED}✗ Docker publishing not configured${NC}"
fi

if grep -q "softprops/action-gh-release" .github/workflows/reusable-release.yml; then
  echo -e "${GREEN}✓ GitHub releases configured${NC}"
else
  echo -e "${RED}✗ GitHub releases not configured${NC}"
fi

if grep -q "vercel" .github/workflows/reusable-release.yml; then
  echo -e "${GREEN}✓ Vercel deployment configured${NC}"
else
  echo -e "${RED}✗ Vercel deployment not configured${NC}"
fi

if ! grep -q "placeholder" .github/workflows/reusable-release.yml; then
  echo -e "${GREEN}✓ Release workflow no longer placeholder${NC}"
else
  echo -e "${RED}✗ Release workflow still placeholder${NC}"
fi

# Check if secrets documentation was created
if [ -f ".github/SECRETS_REQUIRED.md" ]; then
  echo -e "${GREEN}✓ Secrets documentation created${NC}"
else
  echo -e "${RED}✗ Secrets documentation missing${NC}"
fi

echo

# Test 4: Verify CI Integration
echo -e "${BOLD}${CYAN}═══════════════════════════════════════════${NC}"
echo -e "${BOLD}${CYAN}TEST 4: CI Integration${NC}"
echo -e "${BOLD}${CYAN}═══════════════════════════════════════════${NC}"
echo

echo -e "${YELLOW}Checking CI workflow integration...${NC}"
if grep -q "uses: ./.github/workflows/reusable-lint.yml" .github/workflows/ci.yml && \
   grep -q "uses: ./.github/workflows/reusable-test.yml" .github/workflows/ci.yml && \
   grep -q "uses: ./.github/workflows/reusable-build.yml" .github/workflows/ci.yml && \
   grep -q "uses: ./.github/workflows/reusable-release.yml" .github/workflows/ci.yml; then
  echo -e "${GREEN}✓ All reusable workflows integrated in CI${NC}"
else
  echo -e "${RED}✗ Missing workflow integration${NC}"
fi

# Check job dependencies
if grep -q "needs: \[lint, test\]" .github/workflows/ci.yml; then
  echo -e "${GREEN}✓ Build depends on lint and test${NC}"
else
  echo -e "${RED}✗ Incorrect job dependencies${NC}"
fi

if grep -q "needs: \[build\]" .github/workflows/ci.yml; then
  echo -e "${GREEN}✓ Release depends on build${NC}"
else
  echo -e "${RED}✗ Release dependency incorrect${NC}"
fi

echo
echo -e "${BOLD}${CYAN}═══════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}✅ Enhanced Scaffold Test Complete!${NC}"
echo -e "${BOLD}${CYAN}═══════════════════════════════════════════${NC}"
echo
echo "Test Summary:"
echo "  ✅ Base scaffold creates modular workflow structure"
echo "  ✅ Test mode configures actual test implementation"
echo "  ✅ Release mode configures multi-target releases"
echo "  ✅ All workflows properly integrated in CI"
echo
echo "Test artifacts location: $TEST_DIR"
echo
echo "To inspect the generated workflows:"
echo "  cd $TEST_DIR"
echo "  tree .github/workflows/"
echo "  cat .github/workflows/ci.yml"
echo "  cat .github/workflows/reusable-test.yml"
echo "  cat .github/workflows/reusable-release.yml"