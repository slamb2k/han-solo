#!/usr/bin/env bash
# scaffold-core.sh - Deterministic scaffold execution for DevOps setup
# This script handles the actual creation of files and settings after the
# scaffold-agent has analyzed the project and gotten user confirmation

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
FRAMEWORK=""
PACKAGE_MANAGER="pnpm"
PROJECT_TYPE=""
DEPLOY_TARGET=""
SETUP_PROTECTION=true
SETUP_HUSKY=true
CREATE_WORKFLOWS=true
MODE="standard"  # minimal, standard, full

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --language) LANGUAGE="$2"; shift 2 ;;
    --framework) FRAMEWORK="$2"; shift 2 ;;
    --package-manager) PACKAGE_MANAGER="$2"; shift 2 ;;
    --project-type) PROJECT_TYPE="$2"; shift 2 ;;
    --deploy-target) DEPLOY_TARGET="$2"; shift 2 ;;
    --setup-protection) SETUP_PROTECTION="$2"; shift 2 ;;
    --setup-husky) SETUP_HUSKY="$2"; shift 2 ;;
    --create-workflows) CREATE_WORKFLOWS="$2"; shift 2 ;;
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

log_error() {
  echo -e "${RED}✗${NC} $1"
}

log_section() {
  echo
  echo -e "${BOLD}${CYAN}$1${NC}"
  echo -e "${CYAN}$(printf '%.0s─' {1..50})${NC}"
}

# Create reusable lint workflow
create_lint_workflow() {
  log_info "Creating reusable lint workflow"
  
  mkdir -p .github/workflows
  
  if [[ "${LANGUAGE}" = "javascript" ]] || [[ "${LANGUAGE}" = "typescript" ]]; then
    cat > .github/workflows/reusable-lint.yml << 'EOF'
name: Lint
on:
  workflow_call:
    inputs:
      node-version:
        description: 'Node.js version'
        type: string
        default: '20'
      package-manager:
        description: 'Package manager (npm, pnpm, yarn)'
        type: string
        default: 'pnpm'

jobs:
  lint:
    name: Lint Code
    runs-on: ubuntu-latest
    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4
        
      - name: 📦 Setup pnpm
        if: inputs.package-manager == 'pnpm'
        uses: pnpm/action-setup@v4
        
      - name: 🟢 Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${ inputs.node-version }
          cache: ${ inputs.package-manager }
          
      - name: 📚 Install dependencies
        run: |
          if [[ "${ inputs.package-manager }" = "npm" ]]; then
            npm ci
          elif [[ "${ inputs.package-manager }" = "pnpm" ]]; then
            pnpm install --frozen-lockfile
          else
            yarn install --frozen-lockfile
          fi
          
      - name: 🧹 Run Prettier check
        run: ${ inputs.package-manager } run format:check || true
        continue-on-error: true
        
      - name: 🔍 Run ESLint
        run: ${ inputs.package-manager } run lint
EOF
  elif [[ "${LANGUAGE}" = "python" ]]; then
    cat > .github/workflows/reusable-lint.yml << 'EOF'
name: Lint
on:
  workflow_call:
    inputs:
      python-version:
        description: 'Python version'
        type: string
        default: '3.11'

jobs:
  lint:
    name: Lint Code
    runs-on: ubuntu-latest
    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4
        
      - name: 🐍 Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: ${ inputs.python-version }
          
      - name: 📚 Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install black flake8 mypy
          [ -f requirements.txt ] && pip install -r requirements.txt
          
      - name: 🧹 Run Black check
        run: black --check .
        continue-on-error: true
        
      - name: 🔍 Run Flake8
        run: flake8 .
        
      - name: 🔍 Run mypy
        run: mypy . --ignore-missing-imports
        continue-on-error: true
EOF
  fi
}

# Create reusable test workflow (placeholder)
create_test_workflow() {
  log_info "Creating reusable test workflow (placeholder)"
  
  cat > .github/workflows/reusable-test.yml << 'EOF'
name: Test
on:
  workflow_call:
    outputs:
      coverage:
        description: 'Test coverage percentage'
        value: ${ jobs.test.outputs.coverage }
      test-results:
        description: 'Test results summary'
        value: ${ jobs.test.outputs.results }

jobs:
  test:
    name: Run Tests
    runs-on: ubuntu-latest
    outputs:
      coverage: ${ steps.test.outputs.coverage }
      results: ${ steps.test.outputs.results }
    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4
        
      - name: 🧪 Run tests
        id: test
        run: |
          echo "::notice::Test workflow is a placeholder. Configure with /test-setup command"
          echo "coverage=0" >> ${GITHUB_OUTPUT}
          echo "results=pending" >> ${GITHUB_OUTPUT}
          
      - name: 📊 Test Summary
        run: |
          echo "## 🧪 Test Results" >> ${GITHUB_STEP_SUMMARY}
          echo "" >> ${GITHUB_STEP_SUMMARY}
          echo "Test execution will be configured by the /test-setup command." >> ${GITHUB_STEP_SUMMARY}
          echo "" >> ${GITHUB_STEP_SUMMARY}
          echo "This is a placeholder workflow that ensures the CI pipeline structure is in place." >> ${GITHUB_STEP_SUMMARY}
EOF
}

# Create reusable build workflow
create_build_workflow() {
  log_info "Creating reusable build workflow"
  
  if [[ "${LANGUAGE}" = "javascript" ]] || [[ "${LANGUAGE}" = "typescript" ]]; then
    cat > .github/workflows/reusable-build.yml << 'EOF'
name: Build
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
        default: 'pnpm'
      upload-artifacts:
        description: 'Upload build artifacts'
        type: boolean
        default: true
    outputs:
      artifact-name:
        description: 'Name of uploaded artifact'
        value: ${ jobs.build.outputs.artifact-name }

jobs:
  build:
    name: Build Project
    runs-on: ubuntu-latest
    outputs:
      artifact-name: ${ steps.upload.outputs.artifact-name }
    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4
        
      - name: 📦 Setup pnpm
        if: inputs.package-manager == 'pnpm'
        uses: pnpm/action-setup@v4
        
      - name: 🟢 Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${ inputs.node-version }
          cache: ${ inputs.package-manager }
          
      - name: 📚 Install dependencies
        run: |
          if [[ "${ inputs.package-manager }" = "npm" ]]; then
            npm ci
          elif [[ "${ inputs.package-manager }" = "pnpm" ]]; then
            pnpm install --frozen-lockfile
          else
            yarn install --frozen-lockfile
          fi
          
      - name: 🔨 Build project
        run: ${ inputs.package-manager } run build
        
      - name: 📦 Upload artifacts
        id: upload
        if: inputs.upload-artifacts && success()
        uses: actions/upload-artifact@v4
        with:
          name: build-${ github.sha }
          path: |
            dist/
            build/
            .next/
            out/
          retention-days: 7
          if-no-files-found: ignore
          
      - name: 📊 Build Summary
        run: |
          echo "## 🏗️ Build Results" >> ${GITHUB_STEP_SUMMARY}
          echo "" >> ${GITHUB_STEP_SUMMARY}
          echo "- **Status**: ✅ Success" >> ${GITHUB_STEP_SUMMARY}
          echo "- **Node Version**: ${ inputs.node-version }" >> ${GITHUB_STEP_SUMMARY}
          echo "- **Package Manager**: ${ inputs.package-manager }" >> ${GITHUB_STEP_SUMMARY}
          if [[ "${ inputs.upload-artifacts }" = "true" ]]; then
            echo "- **Artifacts**: Uploaded as build-${ github.sha }" >> ${GITHUB_STEP_SUMMARY}
          fi
EOF
  elif [[ "${LANGUAGE}" = "python" ]]; then
    cat > .github/workflows/reusable-build.yml << 'EOF'
name: Build
on:
  workflow_call:
    inputs:
      python-version:
        description: 'Python version'
        type: string
        default: '3.11'
      upload-artifacts:
        description: 'Upload build artifacts'
        type: boolean
        default: true

jobs:
  build:
    name: Build Project
    runs-on: ubuntu-latest
    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4
        
      - name: 🐍 Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: ${ inputs.python-version }
          
      - name: 📚 Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install build
          [ -f requirements.txt ] && pip install -r requirements.txt
          
      - name: 🔨 Build distribution
        run: python -m build
        
      - name: 📦 Upload artifacts
        if: inputs.upload-artifacts && success()
        uses: actions/upload-artifact@v4
        with:
          name: python-dist-${ github.sha }
          path: dist/
          retention-days: 7
EOF
  fi
}

# Create reusable release workflow (placeholder)
create_release_workflow() {
  log_info "Creating reusable release workflow (placeholder)"
  
  cat > .github/workflows/reusable-release.yml << 'EOF'
name: Release
on:
  workflow_call:
    inputs:
      environment:
        description: 'Deployment environment'
        type: string
        default: 'production'
    secrets:
      NPM_TOKEN:
        required: false
      DEPLOY_TOKEN:
        required: false

jobs:
  release:
    name: Release
    runs-on: ubuntu-latest
    environment: ${ inputs.environment }
    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4
        
      - name: 🚀 Release
        run: |
          echo "::notice::Release workflow is a placeholder. Configure with /release-setup command"
          
      - name: 📊 Release Summary
        run: |
          echo "## 🚀 Release Configuration Needed" >> ${GITHUB_STEP_SUMMARY}
          echo "" >> ${GITHUB_STEP_SUMMARY}
          echo "The release workflow is currently a placeholder." >> ${GITHUB_STEP_SUMMARY}
          echo "" >> ${GITHUB_STEP_SUMMARY}
          echo "Use the \`/release-setup\` command to configure:" >> ${GITHUB_STEP_SUMMARY}
          echo "- NPM publishing" >> ${GITHUB_STEP_SUMMARY}
          echo "- Docker image publishing" >> ${GITHUB_STEP_SUMMARY}
          echo "- GitHub releases" >> ${GITHUB_STEP_SUMMARY}
          echo "- Deployment to cloud providers" >> ${GITHUB_STEP_SUMMARY}
EOF
}

# Create main CI workflow that uses the reusable workflows
create_main_workflow() {
  log_info "Creating main CI workflow"
  
  cat > .github/workflows/ci.yml << EOF
name: CI

on:
  push:
    branches: [main]
  pull_request:
    types: [opened, synchronize, reopened]

# Cancel in-progress runs for the same branch
concurrency:
  group: \${ github.workflow }-\${ github.event.pull_request.number || github.ref }
  cancel-in-progress: true

jobs:
  lint:
    name: 🧹 Lint
    uses: ./.github/workflows/reusable-lint.yml
    with:
      node-version: '20'
      package-manager: '${PACKAGE_MANAGER}'
  
  test:
    name: 🧪 Test
    uses: ./.github/workflows/reusable-test.yml
  
  build:
    name: 🏗️ Build
    needs: [lint, test]
    uses: ./.github/workflows/reusable-build.yml
    with:
      node-version: '20'
      package-manager: '${PACKAGE_MANAGER}'
      upload-artifacts: true
  
  release:
    name: 🚀 Release
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    needs: [build]
    uses: ./.github/workflows/reusable-release.yml
    with:
      environment: 'production'
EOF
}

# Setup Husky hooks
setup_husky() {
  if [[ "${SETUP_HUSKY}" != "true" ]]; then
    return
  fi
  
  log_section "🪝 Setting up Husky hooks"
  
  # Install Husky
  if [[ "${PACKAGE_MANAGER}" = "npm" ]]; then
    npm install --save-dev husky lint-staged
    npx husky init
  elif [[ "${PACKAGE_MANAGER}" = "pnpm" ]]; then
    pnpm add -D husky lint-staged
    pnpm exec husky init
  else
    yarn add -D husky lint-staged
    yarn husky init
  fi
  
  # Create pre-commit hook
  cat > .husky/pre-commit << 'EOF'
#!/usr/bin/env sh
. "$(dirname "$0")/_/husky.sh"

npx lint-staged
EOF
  chmod +x .husky/pre-commit
  
  # Create pre-push hook
  cat > .husky/pre-push << 'EOF'
#!/usr/bin/env sh
. "$(dirname "$0")/_/husky.sh"

npm run test 2>/dev/null || true
npm run build
EOF
  chmod +x .husky/pre-push
  
  log_info "Husky hooks configured"
}

# Setup branch protection
setup_branch_protection() {
  if [[ "${SETUP_PROTECTION}" != "true" ]]; then
    return
  fi
  
  log_section "🔒 Setting up branch protection"
  
  # Get repository info
  REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")
  OWNER=$(git remote get-url origin | sed -E 's/.*[:/]([^/]+)\/[^/]+\.git/\1/')
  
  # Required status checks
  REQUIRED_CHECKS='["🧹 Lint","🧪 Test","🏗️ Build"]'
  
  # Create branch protection
  gh api -X PUT "repos/${OWNER}/${REPO_NAME}/branches/main/protection" \
    -f required_status_checks[strict]=true \
    -f required_status_checks[contexts]="${REQUIRED_CHECKS}" \
    -f enforce_admins=false \
    -f required_pull_request_reviews[required_approving_review_count]=0 \
    -f required_pull_request_reviews[dismiss_stale_reviews]=true \
    -f allow_force_pushes=false \
    -f allow_deletions=false \
    >/dev/null 2>&1 && log_info "Branch protection enabled" || log_warn "Could not set branch protection"
  
  # Enable auto-merge
  gh api -X PATCH "repos/${OWNER}/${REPO_NAME}" \
    -f allow_auto_merge=true \
    -f delete_branch_on_merge=true \
    >/dev/null 2>&1 && log_info "Auto-merge enabled" || log_warn "Could not enable auto-merge"
}

# Main execution
main() {
  # Display colorful banner
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  "${SCRIPT_DIR}/block-text.sh" -s "SCAFFOLDING"
  
  # Create workflows if requested
  if [[ "${CREATE_WORKFLOWS}" = "true" ]]; then
    log_section "📁 Creating reusable workflows"
    create_lint_workflow
    create_test_workflow
    create_build_workflow
    create_release_workflow
    create_main_workflow
    log_info "All workflows created"
  fi
  
  # Setup Husky
  setup_husky
  
  # Setup branch protection
  setup_branch_protection
  
  # Final summary
  echo
  echo -e "${BOLD}${GREEN}✅ Scaffold Complete!${NC}"
  echo
  echo "Created structure:"
  echo "  .github/workflows/"
  echo "    ├── ci.yml                 (main orchestrator)"
  echo "    ├── reusable-lint.yml      (✅ implemented)"
  echo "    ├── reusable-test.yml      (⏳ placeholder)"
  echo "    ├── reusable-build.yml     (✅ implemented)"
  echo "    └── reusable-release.yml   (⏳ placeholder)"
  echo
  echo "Next steps:"
  echo "  1. Run: /test-setup    to configure testing"
  echo "  2. Run: /release-setup to configure releases"
  echo "  3. Run: git add . && git commit -m 'Add scaffold'"
  echo "  4. Run: /ship          to deploy your changes"
}

# Run main function
