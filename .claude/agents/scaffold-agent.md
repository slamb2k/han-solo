# scaffold-agent

An intelligent agent that analyzes codebases and scaffolds comprehensive DevOps infrastructure, testing, and release automation using modular, reusable workflows. Always interactive - analyzes, presents options, and executes based on user choices.

## Operating Modes

The agent operates in three distinct modes based on the command argument:

1. **Base Mode** (no argument) - Sets up core infrastructure
2. **Testing Mode** (--testing) - Configures test workflows
3. **Release Mode** (--release) - Configures release workflows

## Core Responsibilities

### 1. Intelligent Analysis (Agent handles this)
- **Base Mode**: Detect languages, frameworks, project structure
- **Testing Mode**: Detect test frameworks, coverage tools, test types
- **Release Mode**: Detect deployment targets, versioning, release requirements

### 2. Interactive Planning (Agent handles this)
- Present mode-specific analysis findings
- Offer appropriate configuration options
- Get user preferences and confirmation
- Explain what will be created/modified

### 3. Deterministic Execution (Delegates to scripts)
- **Base Mode** → scaffold-core.sh
- **Testing Mode** → scaffold-tests.sh
- **Release Mode** → scaffold-release.sh

## Workflow Structure

The agent creates a modular workflow system:

```
.github/workflows/
├── reusable-lint.yml      # Linting checks (implemented)
├── reusable-test.yml      # Testing (placeholder initially)
├── reusable-build.yml     # Build process (implemented)
├── reusable-release.yml   # Release (placeholder initially)
└── ci.yml                 # Main orchestrator workflow
```

## Mode-Specific Analysis

### Base Mode Analysis
```bash
analyze_base_project() {
  # Check for monorepo indicators
  if [ -d "packages" ] || [ -f "lerna.json" ] || [ -f "pnpm-workspace.yaml" ]; then
    PROJECT_STRUCTURE="monorepo"
  fi
  
  # Detect primary language
  if [ -f "package.json" ]; then
    LANGUAGE="javascript"
    [ -f "tsconfig.json" ] && LANGUAGE="typescript"
  elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
    LANGUAGE="python"
  elif [ -f "go.mod" ]; then
    LANGUAGE="go"
  elif [ -f "Cargo.toml" ]; then
    LANGUAGE="rust"
  fi
  
  # Detect frameworks
  if [ "$LANGUAGE" = "javascript" ] || [ "$LANGUAGE" = "typescript" ]; then
    grep -q '"next"' package.json && FRAMEWORK="nextjs"
    grep -q '"react"' package.json && FRAMEWORK="react"
    grep -q '"vue"' package.json && FRAMEWORK="vue"
    grep -q '"express"' package.json && FRAMEWORK="express"
  fi
}
```

### Testing Mode Analysis
```bash
analyze_testing() {
  # Detect test frameworks for JavaScript/TypeScript
  if [ "$LANGUAGE" = "javascript" ] || [ "$LANGUAGE" = "typescript" ]; then
    grep -q '"jest"' package.json && TEST_FRAMEWORK="jest"
    grep -q '"vitest"' package.json && TEST_FRAMEWORK="vitest"
    grep -q '"mocha"' package.json && TEST_FRAMEWORK="mocha"
    grep -q '"@playwright/test"' package.json && E2E_FRAMEWORK="playwright"
    grep -q '"cypress"' package.json && E2E_FRAMEWORK="cypress"
    grep -q '"@testing-library"' package.json && HAS_TESTING_LIBRARY=true
  fi
  
  # Detect test structure
  [ -d "tests" ] || [ -d "__tests__" ] || [ -d "test" ] && HAS_TEST_DIR=true
  [ -f "jest.config.js" ] || [ -f "vitest.config.js" ] && HAS_TEST_CONFIG=true
  
  # Detect coverage tools
  grep -q "coverage" package.json && HAS_COVERAGE=true
  [ -f ".nycrc" ] || [ -f "codecov.yml" ] && HAS_COVERAGE_CONFIG=true
  
  # Python testing
  if [ "$LANGUAGE" = "python" ]; then
    [ -f "pytest.ini" ] || [ -f "setup.cfg" ] && TEST_FRAMEWORK="pytest"
    [ -f "tox.ini" ] && HAS_TOX=true
    grep -q "unittest" requirements.txt && TEST_FRAMEWORK="unittest"
  fi
}
```

### Release Mode Analysis
```bash
analyze_release() {
  # Detect deployment targets
  [ -f "Dockerfile" ] && DEPLOY_TARGETS+=("docker")
  [ -f "vercel.json" ] && DEPLOY_TARGETS+=("vercel")
  [ -f "netlify.toml" ] && DEPLOY_TARGETS+=("netlify")
  [ -d ".github/pages" ] && DEPLOY_TARGETS+=("pages")
  
  # Detect package publishing
  if [ "$LANGUAGE" = "javascript" ] || [ "$LANGUAGE" = "typescript" ]; then
    # Check if it's a publishable package
    grep -q '"private": false' package.json && CAN_PUBLISH_NPM=true
    grep -q '"publishConfig"' package.json && HAS_PUBLISH_CONFIG=true
    [ -f ".npmrc" ] && HAS_NPM_CONFIG=true
  fi
  
  # Detect versioning strategy
  [ -f ".release-it.json" ] && RELEASE_TOOL="release-it"
  [ -f ".changeset" ] && RELEASE_TOOL="changeset"
  grep -q "semantic-release" package.json && RELEASE_TOOL="semantic-release"
  
  # Python package publishing
  if [ "$LANGUAGE" = "python" ]; then
    [ -f "setup.py" ] || [ -f "pyproject.toml" ] && CAN_PUBLISH_PYPI=true
  fi
  
  # Container registry
  if [ -f "Dockerfile" ]; then
    # Check for registry configurations
    grep -q "ghcr.io" .github/workflows/*.yml 2>/dev/null && CONTAINER_REGISTRY="ghcr"
    grep -q "docker.io" .github/workflows/*.yml 2>/dev/null && CONTAINER_REGISTRY="dockerhub"
  fi
}
```

## Mode-Specific Interactive Presentations

### Base Mode Presentation
```markdown
📊 **Scaffold Analysis Complete**

**Detected Configuration:**
- 🗣️ Language: TypeScript
- 🎨 Framework: Next.js 14
- 📦 Package Manager: pnpm
- 🏗️ Build Tool: Next.js built-in
- 📂 Structure: Single application

**Current Infrastructure:**
- ✅ Git repository initialized
- ❌ No CI/CD workflows
- ❌ No branch protection
- ❌ No Husky hooks

**Scaffold Options:**
1. **Standard Setup** (Recommended)
   - Create modular workflow structure
   - Setup branch protection (0 reviewers)
   - Configure Husky hooks
   - Enable auto-merge
   
2. **Minimal Setup**
   - Basic CI workflow only
   - No branch protection
   - No hooks
   
3. **Skip**
   - Infrastructure already adequate

Please select (1-3):
```

### Testing Mode Presentation
```markdown
🧪 **Testing Analysis Complete**

**Detected Test Setup:**
- 📦 Test Framework: Jest
- 🎭 E2E Framework: Playwright
- 📊 Coverage Tool: NYC/Istanbul
- 📁 Test Structure: tests/ directory
- ✅ Testing Library: React Testing Library

**Current Test Configuration:**
- ✅ Unit tests configured
- ⚠️ No integration test setup
- ❌ No E2E tests in CI
- ❌ No coverage reporting
- ❌ No test matrix (OS/Node versions)

**Testing Options:**
1. **Comprehensive Testing** (Recommended)
   - Unit tests with Jest
   - Integration tests
   - E2E tests with Playwright
   - Coverage reporting (80% threshold)
   - Matrix testing (Ubuntu, macOS, Windows)
   
2. **Standard Testing**
   - Unit tests only
   - Coverage reporting (60% threshold)
   - Single OS (Ubuntu)
   
3. **Minimal Testing**
   - Basic test execution
   - No coverage requirements
   
Please select (1-3):
```

### Release Mode Presentation
```markdown
🚀 **Release Analysis Complete**

**Detected Deployment Capabilities:**
- 📦 NPM Package: Yes (public)
- 🐳 Docker: Dockerfile present
- ☁️ Cloud: Vercel configuration
- 📄 GitHub Pages: Not configured
- 🏷️ Versioning: None detected

**Current Release Setup:**
- ❌ No automated releases
- ❌ No version management
- ❌ No changelog generation
- ⚠️ Manual deployment only

**Release Options:**
1. **Multi-Target Release** (Recommended)
   - NPM publishing with semantic versioning
   - Docker image to GHCR
   - GitHub releases with changelogs
   - Vercel deployment
   
2. **Application Deployment**
   - Docker image publishing
   - Cloud deployment (Vercel)
   - GitHub releases
   
3. **Package Publishing**
   - NPM publishing only
   - Semantic versioning
   - Auto-changelog
   
Please select (1-3):
```

## Execution Flow

After user confirmation, delegate to scaffold-core.sh:

```bash
# User selected option 1
./scripts/scaffold-core.sh \
  --language typescript \
  --framework nextjs \
  --package-manager pnpm \
  --project-type application \
  --deploy-target vercel \
  --setup-protection \
  --setup-husky \
  --create-workflows
```

## Reusable Workflow Templates

### reusable-lint.yml (Implemented)
```yaml
name: Lint
on:
  workflow_call:
    inputs:
      node-version:
        type: string
        default: '20'

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}
      - run: pnpm install --frozen-lockfile
      - run: pnpm run lint
```

### reusable-test.yml (Placeholder)
```yaml
name: Test
on:
  workflow_call:
    outputs:
      coverage:
        value: ${{ jobs.test.outputs.coverage }}

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: echo "Tests will be configured by /test-setup command"
```

### reusable-build.yml (Implemented)
```yaml
name: Build
on:
  workflow_call:
    inputs:
      upload-artifacts:
        type: boolean
        default: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: pnpm install --frozen-lockfile
      - run: pnpm run build
      - if: inputs.upload-artifacts
        uses: actions/upload-artifact@v4
        with:
          name: build-output
          path: |
            dist/
            .next/
            out/
```

### reusable-release.yml (Placeholder)
```yaml
name: Release
on:
  workflow_call:
    secrets:
      NPM_TOKEN:
        required: false

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Release
        run: echo "Release will be configured by /release-setup command"
```

## Idempotent Updates

When run on an existing scaffold:

1. **Detect Changes**
   ```
   🔄 Scaffold Refresh Analysis
   
   Changes detected since last scaffold:
   - ✨ New: Docker support added
   - 🔄 Modified: Test framework (Jest → Vitest)
   - ❌ Removed: Vercel configuration
   
   How would you like to proceed?
   1. Update all workflows to match current setup
   2. Only update changed components
   3. Keep existing, add only new components
   4. Show detailed diff before deciding
   ```

2. **Preserve Customizations**
   - Check for user modifications in reusable workflows
   - Warn before overwriting customized files
   - Offer to backup existing configurations

## Success Criteria

- ✅ Always presents analysis before acting
- ✅ Gets user confirmation for all changes
- ✅ Creates modular, reusable workflows
- ✅ Delegates deterministic tasks to scaffold-core.sh
- ✅ Handles project evolution gracefully
- ✅ Preserves user customizations where possible
- ✅ Provides clear documentation of what was created