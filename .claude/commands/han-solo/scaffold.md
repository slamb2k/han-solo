---
name: /han-solo:scaffold
description: "Intelligently scaffold your repository with modular DevOps workflows, branch protection, and release automation"
requires_args: false
argument-hint: "[--refresh | --minimal | --full]"
allowed-tools:
  - Task
---

# scaffold

Analyzes your codebase and sets up a comprehensive, modular DevOps scaffold with reusable workflows, branch protection, and repository settings. Always interactive - presents findings and asks for confirmation.

## Purpose
Create a flexible, maintainable DevOps foundation using modular, reusable workflows that can evolve with your project while maintaining a consistent structure.

## Usage
```bash
# Initial scaffold - full analysis and setup
/scaffold

# Refresh existing scaffold with detected changes
/scaffold --refresh

# Minimal setup - essentials only
/scaffold --minimal

# Full setup - all features
/scaffold --full
```

## What It Does

### 1. **Project Analysis** (via scaffold-agent)
- Detects languages, frameworks, and build tools
- Identifies project type (library, application, monorepo)
- Discovers existing CI/CD configurations
- Analyzes testing frameworks and deployment targets

### 2. **Interactive Planning**
- Presents analysis findings
- Offers configuration options based on project type
- Asks for user preferences and additional context
- Shows exactly what will be created/modified

### 3. **Modular Workflow Creation**
Creates separate, reusable workflows:
- `.github/workflows/reusable-lint.yml` - Linting checks
- `.github/workflows/reusable-test.yml` - Test execution (placeholder initially)
- `.github/workflows/reusable-build.yml` - Build process
- `.github/workflows/reusable-release.yml` - Release automation (placeholder initially)
- `.github/workflows/ci.yml` - Main workflow that orchestrates the above

### 4. **Repository Configuration** (via scaffold-core)
- Branch protection with required status checks
- Auto-merge and auto-delete branch settings
- Husky hooks for pre-commit and pre-push
- Repository settings optimization

## Key Features

### Modular Architecture
```yaml
# Main CI workflow calls reusable components
name: CI
jobs:
  lint:
    uses: ./.github/workflows/reusable-lint.yml
  test:
    uses: ./.github/workflows/reusable-test.yml
  build:
    uses: ./.github/workflows/reusable-build.yml
    needs: [lint, test]
  release:
    if: github.ref == 'refs/heads/main'
    uses: ./.github/workflows/reusable-release.yml
    needs: [build]
```

### Idempotent & Adaptive
- Detects existing configurations
- Preserves custom modifications where possible
- Updates only what's needed
- Can refresh when project structure changes

### Interactive Flow
1. **Analysis Phase**: "I've detected a TypeScript/React project with Jest testing..."
2. **Options Phase**: "Would you like to: [1] Standard web app setup [2] Library setup [3] Custom..."
3. **Confirmation Phase**: "Here's what I'll create: [shows plan]... Proceed?"
4. **Execution Phase**: Creates all components

## Example Interactions

### First Run
```
/scaffold
> Analyzing your project...
> 
> 📊 Analysis Results:
> - Language: TypeScript
> - Framework: Next.js
> - Testing: Jest + React Testing Library
> - Package Manager: pnpm
> - Project Type: Web Application
> 
> 📋 Recommended Configuration:
> 1. Standard Next.js setup (lint, test, build, deploy to Vercel)
> 2. Library setup (lint, test, build, publish to npm)
> 3. Custom configuration
> 
> Please choose (1-3): 1
> 
> ✅ I'll create:
> - 4 reusable workflows (lint, test, build, release)
> - Main CI workflow
> - Branch protection for 'main'
> - Husky hooks
> - Auto-merge configuration
> 
> Proceed? (y/n): y
```

### Refresh Run
```
/scaffold --refresh
> Checking existing scaffold...
> 
> 🔄 Changes Detected:
> - New: Docker configuration found
> - Changed: Test framework (Jest → Vitest)
> - Missing: Release workflow not configured
> 
> 📋 Update Options:
> 1. Update all components to match current structure
> 2. Only add missing components
> 3. Show detailed diff
> 
> Please choose (1-3): 1
```

## Reusable Workflows

### Lint Workflow
- Actual implementation based on detected linters
- Supports ESLint, Prettier, Black, ruff, etc.

### Test Workflow
- Initially a placeholder
- Will be implemented by `/test-setup` command

### Build Workflow
- Actual implementation based on build tools
- Supports webpack, vite, tsc, etc.

### Release Workflow
- Initially a placeholder
- Will be implemented by `/release-setup` command

## Implementation Details

Uses the Task tool with:
- **subagent_type**: "scaffold-agent"
- **description**: "Scaffold repository"
- **prompt**: Includes mode and asks agent to:
  1. Analyze the codebase thoroughly
  2. Present findings to user
  3. Offer appropriate options
  4. Get user confirmation
  5. Delegate to scaffold-core.sh for execution
  6. Create modular, reusable workflows
  7. Report what was created

## Related Commands
- `/test-setup` - Configure the test workflow
- `/release-setup` - Configure the release workflow
- `/quality-gates` - Add additional quality checks
- `/ship` - Ship code through the scaffold