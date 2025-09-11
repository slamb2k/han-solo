#!/usr/bin/env bash
# quality-gates-simple.sh - Simplified quality gates setup
set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🎯 Setting up Quality Gates${NC}"
echo

# Detect project type
if [ -f "package.json" ]; then
  echo -e "${GREEN}✓${NC} Node.js project detected"
  
  # Detect package manager
  if [ -f "pnpm-lock.yaml" ]; then
    PKG_MGR="pnpm"
  elif [ -f "yarn.lock" ]; then
    PKG_MGR="yarn"
  else
    PKG_MGR="npm"
  fi
  echo -e "${GREEN}✓${NC} Package manager: $PKG_MGR"
  
  # Create test directories
  mkdir -p tests/unit tests/integration tests/regression
  echo -e "${GREEN}✓${NC} Created test directories"
  
  # Create sample test
  cat > tests/unit/example.test.js << 'EOF'
describe('Example Test', () => {
  it('should pass', () => {
    expect(true).toBe(true);
  });
});
EOF
  echo -e "${GREEN}✓${NC} Created sample test"
  
  # Update Husky hooks to run real tests
  if [ -f ".husky/pre-push" ]; then
    cat > .husky/pre-push << 'EOF'
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

echo "🚀 Running pre-push checks..."

# Run tests if they exist
npm test --if-present || {
  echo "❌ Tests failed"
  exit 1
}

echo "✅ Pre-push checks passed!"
EOF
    chmod +x .husky/pre-push
    echo -e "${GREEN}✓${NC} Updated pre-push hook"
  fi
  
  echo
  echo -e "${GREEN}✨ Quality gates setup complete!${NC}"
  echo
  echo "Next steps:"
  echo "  1. Install test framework: ${CYAN}$PKG_MGR install --save-dev jest${NC}"
  echo "  2. Update package.json test script: ${CYAN}\"test\": \"jest\"${NC}"
  echo "  3. Run tests: ${CYAN}$PKG_MGR test${NC}"
  
else
  echo -e "${YELLOW}⚠${NC} No package.json found. Please run from project root."
  exit 1
fi