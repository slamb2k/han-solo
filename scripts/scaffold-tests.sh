#!/usr/bin/env bash
# scaffold-tests.sh - Deterministic test configuration for reusable-test.yml
# This script configures the actual test implementation based on detected frameworks

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Configuration from command line arguments
LANGUAGE=""
TEST_FRAMEWORK=""
E2E_FRAMEWORK=""
COVERAGE_THRESHOLD="60"
TEST_MATRIX="single"  # single, multi-os, full
PACKAGE_MANAGER="pnpm"
MODE="standard"  # minimal, standard, comprehensive

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --language) LANGUAGE="$2"; shift 2 ;;
    --test-framework) TEST_FRAMEWORK="$2"; shift 2 ;;
    --e2e-framework) E2E_FRAMEWORK="$2"; shift 2 ;;
    --coverage-threshold) COVERAGE_THRESHOLD="$2"; shift 2 ;;
    --test-matrix) TEST_MATRIX="$2"; shift 2 ;;
    --package-manager) PACKAGE_MANAGER="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# Helper functions
log_info() {
  echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}⚠${NC} $1"
}

log_section() {
  echo
  echo -e "${BOLD}${CYAN}$1${NC}"
  echo -e "${CYAN}$(printf '%.0s─' {1..50})${NC}"
}

# Configure test workflow for JavaScript/TypeScript
configure_js_test_workflow() {
  local workflow_file=".github/workflows/reusable-test.yml"
  
  log_info "Configuring JavaScript/TypeScript test workflow"
  
  # Determine test command based on framework
  local test_cmd="npm test"
  case "${TEST_FRAMEWORK}" in
    jest)
      test_cmd="${PACKAGE_MANAGER} run test --coverage --ci"
      ;;
    vitest)
      test_cmd="${PACKAGE_MANAGER} run test:unit --coverage --run"
      ;;
    mocha)
      test_cmd="${PACKAGE_MANAGER} run test --recursive"
      ;;
    *)
      test_cmd="${PACKAGE_MANAGER} test"
      ;;
  esac
  
  # Build matrix configuration
  local matrix_os="[\"ubuntu-latest\"]"
  local matrix_node="[\"20\"]"
  
  if [[ "${TEST_MATRIX}" = "multi-os" ]]; then
    matrix_os='["ubuntu-latest", "macos-latest", "windows-latest"]'
  elif [[ "${TEST_MATRIX}" = "full" ]]; then
    matrix_os='["ubuntu-latest", "macos-latest", "windows-latest"]'
    matrix_node='["18", "20", "22"]'
  fi
  
  cat > "$workflow_file" << EOF
name: Test
on:
  workflow_call:
    inputs:
      node-version:
        description: 'Node.js version'
        type: string
        default: '20'
      package-manager:
        description: 'Package manager'
        type: string
        default: '${PACKAGE_MANAGER}'
      coverage-threshold:
        description: 'Minimum coverage percentage'
        type: number
        default: ${COVERAGE_THRESHOLD}
    outputs:
      coverage:
        description: 'Test coverage percentage'
        value: \${ jobs.test.outputs.coverage }
      test-results:
        description: 'Test results summary'
        value: \${ jobs.test.outputs.results }

jobs:
  test:
    name: Test (\${ matrix.os } / Node \${ matrix.node })
    runs-on: \${ matrix.os }
    strategy:
      fail-fast: false
      matrix:
        os: $matrix_os
        node: $matrix_node
    outputs:
      coverage: \${ steps.coverage.outputs.percentage }
      results: \${ steps.results.outputs.summary }
    
    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4
        
      - name: 📦 Setup pnpm
        if: inputs.package-manager == 'pnpm'
        uses: pnpm/action-setup@v4
        
      - name: 🟢 Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: \${ matrix.node }
          cache: \${ inputs.package-manager }
          
      - name: 📚 Install dependencies
        run: |
          if [[ "\${ inputs.package-manager }" = "npm" ]]; then
            npm ci
          elif [[ "\${ inputs.package-manager }" = "pnpm" ]]; then
            pnpm install --frozen-lockfile
          else
            yarn install --frozen-lockfile
          fi
          
      - name: 🧪 Run unit tests
        id: unit-tests
        run: $test_cmd
        
      - name: 📊 Process coverage
        id: coverage
        if: success() && matrix.os == 'ubuntu-latest'
        run: |
          if [[ -f "coverage/coverage-summary.json" ]]; then
            COVERAGE=\$(node -e "console.log(require('./coverage/coverage-summary.json').total.lines.pct)")
            echo "percentage=\${COVERAGE}" >> \${GITHUB_OUTPUT}
            
            if (( \$(echo "\${COVERAGE} < \${ inputs.coverage-threshold }" | bc -l) )); then
              echo "::error::Coverage \${COVERAGE}% is below threshold \${ inputs.coverage-threshold }%"
              exit 1
            fi
          else
            echo "percentage=0" >> \${GITHUB_OUTPUT}
          fi
          
      - name: 📈 Upload coverage
        if: success() && matrix.os == 'ubuntu-latest'
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info
          flags: unittests
          name: coverage-\${ matrix.os }-node-\${ matrix.node }
EOF
  
  # Add integration tests if comprehensive mode
  if [[ "${MODE}" = "comprehensive" ]]; then
    cat >> "$workflow_file" << 'EOF'
          
      - name: 🔗 Run integration tests
        if: success()
        run: |
          if ${ inputs.package-manager } run test:integration --help 2>/dev/null; then
            ${ inputs.package-manager } run test:integration
          else
            echo "No integration tests configured"
          fi
EOF
  fi
  
  # Add E2E tests if framework detected and comprehensive mode
  if [[ -n "${E2E_FRAMEWORK}" ]] && [[ "${MODE}" = "comprehensive" ]]; then
    cat >> "$workflow_file" << EOF
          
      - name: 🎭 Install Playwright browsers
        if: matrix.os == 'ubuntu-latest' && '${E2E_FRAMEWORK}' == 'playwright'
        run: npx playwright install --with-deps
        
      - name: 🎭 Run E2E tests
        if: matrix.os == 'ubuntu-latest'
        run: |
          if \${ inputs.package-manager } run test:e2e --help 2>/dev/null; then
            \${ inputs.package-manager } run test:e2e
          else
            echo "E2E tests not configured"
          fi
EOF
  fi
  
  # Complete the workflow
  cat >> "$workflow_file" << 'EOF'
          
      - name: 📋 Generate test summary
        id: results
        if: always()
        run: |
          echo "## 🧪 Test Results" >> ${GITHUB_STEP_SUMMARY}
          echo "" >> ${GITHUB_STEP_SUMMARY}
          echo "- **OS**: ${ matrix.os }" >> ${GITHUB_STEP_SUMMARY}
          echo "- **Node**: ${ matrix.node }" >> ${GITHUB_STEP_SUMMARY}
          
          if [[ "${ steps.unit-tests.outcome }" = "success" ]]; then
            echo "- **Unit Tests**: ✅ Passed" >> ${GITHUB_STEP_SUMMARY}
            echo "summary=✅ All tests passed" >> ${GITHUB_OUTPUT}
          else
            echo "- **Unit Tests**: ❌ Failed" >> ${GITHUB_STEP_SUMMARY}
            echo "summary=❌ Tests failed" >> ${GITHUB_OUTPUT}
          fi
          
          if [[ -n "${ steps.coverage.outputs.percentage }" ]]; then
            echo "- **Coverage**: ${ steps.coverage.outputs.percentage }%" >> ${GITHUB_STEP_SUMMARY}
          fi
EOF
}

# Configure test workflow for Python
configure_python_test_workflow() {
  local workflow_file=".github/workflows/reusable-test.yml"
  
  log_info "Configuring Python test workflow"
  
  # Determine test command
  local test_cmd="pytest"
  if [[ "${TEST_FRAMEWORK}" = "unittest" ]]; then
    test_cmd="python -m unittest discover"
  fi
  
  # Build matrix configuration
  local matrix_os="[\"ubuntu-latest\"]"
  local matrix_python='["3.11"]'
  
  if [[ "${TEST_MATRIX}" = "multi-os" ]]; then
    matrix_os='["ubuntu-latest", "macos-latest", "windows-latest"]'
  elif [[ "${TEST_MATRIX}" = "full" ]]; then
    matrix_os='["ubuntu-latest", "macos-latest", "windows-latest"]'
    matrix_python='["3.9", "3.10", "3.11", "3.12"]'
  fi
  
  cat > "$workflow_file" << EOF
name: Test
on:
  workflow_call:
    inputs:
      python-version:
        description: 'Python version'
        type: string
        default: '3.11'
      coverage-threshold:
        description: 'Minimum coverage percentage'
        type: number
        default: ${COVERAGE_THRESHOLD}
    outputs:
      coverage:
        description: 'Test coverage percentage'
        value: \${ jobs.test.outputs.coverage }

jobs:
  test:
    name: Test (\${ matrix.os } / Python \${ matrix.python })
    runs-on: \${ matrix.os }
    strategy:
      fail-fast: false
      matrix:
        os: $matrix_os
        python: $matrix_python
    outputs:
      coverage: \${ steps.coverage.outputs.percentage }
    
    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4
        
      - name: 🐍 Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: \${ matrix.python }
          cache: 'pip'
          
      - name: 📚 Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
          pip install pytest pytest-cov
          
      - name: 🧪 Run tests with coverage
        run: $test_cmd --cov=. --cov-report=xml --cov-report=term
        
      - name: 📊 Check coverage threshold
        id: coverage
        if: matrix.os == 'ubuntu-latest'
        run: |
          COVERAGE=\$(python -c "import xml.etree.ElementTree as ET; tree = ET.parse('coverage.xml'); root = tree.getroot(); print(float(root.get('line-rate')) * 100)")
          echo "percentage=\${COVERAGE}" >> \${GITHUB_OUTPUT}
          
          if (( \$(echo "\${COVERAGE} < \${ inputs.coverage-threshold }" | bc -l) )); then
            echo "::error::Coverage \${COVERAGE}% is below threshold \${ inputs.coverage-threshold }%"
            exit 1
          fi
          
      - name: 📈 Upload coverage
        if: matrix.os == 'ubuntu-latest'
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage.xml
          flags: unittests
          name: coverage-\${ matrix.os }-python-\${ matrix.python }
EOF
}

# Update package.json scripts for JavaScript projects
update_package_scripts() {
  if [[ "${LANGUAGE}" != "javascript" ]] && [[ "${LANGUAGE}" != "typescript" ]]; then
    return
  fi
  
  log_section "📝 Updating package.json scripts"
  
  # Check if package.json exists
  if [[ ! -f "package.json" ]]; then
    log_warn "No package.json found, skipping script updates"
    return
  fi
  
  # Add test scripts if they don't exist
  if [[ "${TEST_FRAMEWORK}" = "jest" ]]; then
    # Add Jest test scripts
    node -e "
      const pkg = require('./package.json');
      pkg.scripts = pkg.scripts || {};
      pkg.scripts['test'] = pkg.scripts['test'] || 'jest';
      pkg.scripts['test:unit'] = pkg.scripts['test:unit'] || 'jest --testPathPattern=unit';
      pkg.scripts['test:integration'] = pkg.scripts['test:integration'] || 'jest --testPathPattern=integration';
      pkg.scripts['test:coverage'] = pkg.scripts['test:coverage'] || 'jest --coverage';
      pkg.scripts['test:watch'] = pkg.scripts['test:watch'] || 'jest --watch';
      require('fs').writeFileSync('package.json', JSON.stringify(pkg, null, 2));
    " && log_info "Added Jest test scripts"
  elif [[ "${TEST_FRAMEWORK}" = "vitest" ]]; then
    # Add Vitest test scripts
    node -e "
      const pkg = require('./package.json');
      pkg.scripts = pkg.scripts || {};
      pkg.scripts['test'] = pkg.scripts['test'] || 'vitest';
      pkg.scripts['test:unit'] = pkg.scripts['test:unit'] || 'vitest run --dir tests/unit';
      pkg.scripts['test:integration'] = pkg.scripts['test:integration'] || 'vitest run --dir tests/integration';
      pkg.scripts['test:coverage'] = pkg.scripts['test:coverage'] || 'vitest run --coverage';
      pkg.scripts['test:watch'] = pkg.scripts['test:watch'] || 'vitest watch';
      require('fs').writeFileSync('package.json', JSON.stringify(pkg, null, 2));
    " && log_info "Added Vitest test scripts"
  fi
  
  # Add E2E scripts if framework detected
  if [[ "${E2E_FRAMEWORK}" = "playwright" ]]; then
    node -e "
      const pkg = require('./package.json');
      pkg.scripts = pkg.scripts || {};
      pkg.scripts['test:e2e'] = pkg.scripts['test:e2e'] || 'playwright test';
      pkg.scripts['test:e2e:ui'] = pkg.scripts['test:e2e:ui'] || 'playwright test --ui';
      require('fs').writeFileSync('package.json', JSON.stringify(pkg, null, 2));
    " && log_info "Added Playwright E2E scripts"
  elif [[ "${E2E_FRAMEWORK}" = "cypress" ]]; then
    node -e "
      const pkg = require('./package.json');
      pkg.scripts = pkg.scripts || {};
      pkg.scripts['test:e2e'] = pkg.scripts['test:e2e'] || 'cypress run';
      pkg.scripts['test:e2e:open'] = pkg.scripts['test:e2e:open'] || 'cypress open';
      require('fs').writeFileSync('package.json', JSON.stringify(pkg, null, 2));
    " && log_info "Added Cypress E2E scripts"
  fi
}

# Main execution
main() {
  # Display colorful banner
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  "${SCRIPT_DIR}/block-text.sh" -s "SCAFFOLDING TESTS"
  
  log_section "📋 Configuration Summary"
  echo "  Language: ${LANGUAGE}"
  echo "  Test Framework: ${TEST_FRAMEWORK}"
  echo "  E2E Framework: ${E2E_FRAMEWORK:-none}"
  echo "  Coverage Threshold: ${COVERAGE_THRESHOLD}%"
  echo "  Test Matrix: ${TEST_MATRIX}"
  echo "  Mode: ${MODE}"
  
  # Configure test workflow based on language
  log_section "🔧 Configuring Test Workflow"
  
  if [[ "${LANGUAGE}" = "javascript" ]] || [[ "${LANGUAGE}" = "typescript" ]]; then
    configure_js_test_workflow
  elif [[ "${LANGUAGE}" = "python" ]]; then
    configure_python_test_workflow
  else
    log_warn "Language ${LANGUAGE} not yet supported for test configuration"
    exit 1
  fi
  
  log_info "Test workflow configured successfully"
  
  # Update package scripts
  update_package_scripts
  
  # Summary
  echo
  echo -e "${BOLD}${GREEN}✅ Test Configuration Complete!${NC}"
  echo
  echo "Configured:"
  echo "  ✅ Test workflow with ${TEST_FRAMEWORK}"
  if [[ -n "${E2E_FRAMEWORK}" ]]; then
    echo "  ✅ E2E tests with ${E2E_FRAMEWORK}"
  fi
  echo "  ✅ Coverage threshold: ${COVERAGE_THRESHOLD}%"
  echo "  ✅ Test matrix: ${TEST_MATRIX}"
  echo
  echo "Next steps:"
  echo "  1. Review: cat .github/workflows/reusable-test.yml"
  echo "  2. Test locally: ${PACKAGE_MANAGER} test"
  echo "  3. Commit changes: git add . && git commit -m 'Configure testing'"
  echo "  4. Ship: /ship"
}

# Run main function
