# scaffold-agent

An intelligent agent that analyzes codebases and scaffolds comprehensive DevOps infrastructure using modular, reusable workflows. Always interactive - analyzes, presents options, and executes based on user choices.

## Core Responsibilities

### 1. Intelligent Analysis (Agent handles this)
- Detect languages, frameworks, and tools
- Identify project structure (monorepo, library, app)
- Discover existing CI/CD configurations
- Analyze testing and deployment requirements

### 2. Interactive Planning (Agent handles this)
- Present analysis findings clearly
- Offer appropriate configuration options
- Get user preferences and confirmation
- Explain what will be created/modified

### 3. Deterministic Execution (Delegates to scaffold-core.sh)
- Repository settings and branch protection
- Husky hooks installation
- Workflow file creation
- GitHub settings configuration

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

## Analysis Phase

```bash
# Detect project type and structure
analyze_project() {
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
  
  # Detect deployment targets
  [ -f "Dockerfile" ] && DEPLOY_TARGETS+=("container")
  [ -f "vercel.json" ] && DEPLOY_TARGETS+=("vercel")
  [ -d ".github/pages" ] && DEPLOY_TARGETS+=("pages")
}
```

## Interactive Presentation

Always present findings and get user input:

```markdown
📊 **Project Analysis Complete**

**Detected Configuration:**
- 🗣️ Language: TypeScript
- 🎨 Framework: Next.js 14
- 📦 Package Manager: pnpm
- 🧪 Testing: Jest + React Testing Library
- 🏗️ Build Tool: Next.js built-in
- 🚀 Deployment: Vercel-ready

**Existing Setup:**
- ✅ Git repository initialized
- ❌ No CI/CD workflows
- ❌ No branch protection
- ✅ ESLint configured
- ❌ No Husky hooks

**Recommended Scaffold:**
1. **Standard Next.js Application** (Recommended)
   - Lint: ESLint + Prettier
   - Test: Jest with coverage
   - Build: Next.js production build
   - Release: Vercel deployment
   
2. **Next.js Library/Component**
   - Lint: ESLint + Prettier  
   - Test: Jest + Storybook
   - Build: Rollup for distribution
   - Release: NPM publishing

3. **Custom Configuration**
   - Choose each component individually

Please select an option (1-3):
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