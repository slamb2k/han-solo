---
description: "Configure CI/CD pipeline for project"
argument_hint: "[--deploy]"
---

# /hansolo:ci-setup

## Setup and Operations Loading

```bash
#!/bin/bash
set -euo pipefail

# Source CI operations for actual execution
source .claude/lib/operations/ci-operations.sh

# Check for deploy flag
INCLUDE_DEPLOY="false"
if [[ "${1:-}" == "--deploy" ]]; then
    INCLUDE_DEPLOY="true"
fi
```

## Squadron Identity

Display Green Squadron identity:
```bash
echo ""
echo "Green Leader, standing by..."
echo ""
cat .claude/lib/banners/configuring.txt 2>/dev/null || true
echo ""
```

## PRE-FLIGHT: ANALYZE PROJECT

Check project structure and requirements:

```bash
echo "🔍 PRE-FLIGHT: Analyzing project structure..."
echo ""

# Detect project type
PROJECT_TYPE=$(detect_project_type)
echo "  Project type: $PROJECT_TYPE"

# Check for existing CI configuration
if [[ -f ".github/workflows/ci.yml" ]] || [[ -f ".github/workflows/main.yml" ]]; then
    echo "  ⚠️  Existing CI workflow detected"
    echo ""
    echo "  Override existing configuration? (y/N)"
    read -r OVERRIDE
    if [[ "$OVERRIDE" != "y" ]] && [[ "$OVERRIDE" != "Y" ]]; then
        echo ""
        echo "✓ Keeping existing configuration"
        exit 0
    fi
fi

# Check for GitHub repository
if git remote get-url origin 2>/dev/null | grep -q github.com; then
    echo "  ✓ GitHub repository detected"
    GH_REPO="true"
else
    echo "  ℹ️  No GitHub remote (will create local workflow)"
    GH_REPO="false"
fi

# Check for test configuration
case "$PROJECT_TYPE" in
    node)
        if grep -q '"test"' package.json 2>/dev/null; then
            echo "  ✓ Test script found in package.json"
        else
            echo "  ⚠️  No test script in package.json"
        fi
        ;;
    python)
        if [[ -f "pytest.ini" ]] || [[ -f "setup.cfg" ]] || [[ -d "tests" ]]; then
            echo "  ✓ Test configuration detected"
        else
            echo "  ⚠️  No test configuration found"
        fi
        ;;
    *)
        echo "  ℹ️  Generic project type"
        ;;
esac

echo ""
echo "✓ Pre-flight checks complete"
echo ""
```

## EXECUTION: SETUP CI PIPELINE

Create CI/CD configuration:

```bash
echo "🚀 EXECUTION: Setting up CI/CD pipeline..."
echo ""

# Step 1: Create GitHub Actions workflow
echo "  Step 1/4: Creating GitHub Actions workflow"
create_github_actions_workflow "$PROJECT_TYPE" "$INCLUDE_DEPLOY"

# Step 2: Create PR template
echo "  Step 2/4: Creating pull request template"
create_pr_template

# Step 3: Create .github directory structure
echo "  Step 3/4: Setting up GitHub directory structure"
mkdir -p .github/{workflows,ISSUE_TEMPLATE}
echo "    ✓ Directory structure created"

# Step 4: Configure branch protection (if applicable)
echo "  Step 4/4: Configuring branch protection"
if [[ "$GH_REPO" == "true" ]] && command -v gh &>/dev/null; then
    setup_branch_protection
else
    echo "    ℹ️  Manual configuration required"
fi

echo ""
echo "✓ Execution completed successfully"
echo ""
```

## POST-FLIGHT: VERIFY CONFIGURATION

Validate CI setup:

```bash
echo "🔄 POST-FLIGHT: Verifying CI configuration..."
echo ""

# Check workflow file exists
if [[ -f ".github/workflows/ci.yml" ]]; then
    echo "  ✓ Workflow file created"
    WORKFLOW_LINES=$(wc -l < .github/workflows/ci.yml)
    echo "    Lines: $WORKFLOW_LINES"
else
    echo "  ❌ Workflow file not found"
fi

# Check PR template exists
if [[ -f ".github/pull_request_template.md" ]]; then
    echo "  ✓ PR template created"
else
    echo "  ⚠️  PR template not created"
fi

# List created files
echo ""
echo "  Created files:"
find .github -type f -name "*.yml" -o -name "*.md" | while read -r file; do
    echo "    • $file"
done

# Show next steps
echo ""
echo "✅ POST-FLIGHT: CI/CD setup complete!"
echo ""

cat << 'EOF'
Next steps:

1. Review and customize the workflow:
   vi .github/workflows/ci.yml

2. Add any required secrets to GitHub:
   gh secret set SECRET_NAME

3. Commit the CI configuration:
   git add .github/
   git commit -m "ci: add GitHub Actions workflow"

4. Push to trigger first CI run:
   git push origin

EOF

if [[ "$INCLUDE_DEPLOY" == "true" ]]; then
    cat << 'EOF'
5. Configure deployment secrets:
   - Add deployment keys/tokens to GitHub Secrets
   - Update deployment commands in workflow
   - Test deployment on feature branch first

EOF
fi

echo "CI pipeline will run on:"
echo "  • Every push to main/develop"
echo "  • Every pull request to main"
echo ""
echo "Happy testing! 🚀"
```

## Summary

The ci-setup command follows the three-phase pattern:

1. **PRE-FLIGHT**:
   - ✓ Detects project type
   - ✓ Checks for existing CI
   - ✓ Validates test configuration

2. **EXECUTION**:
   - ✓ Creates GitHub Actions workflow
   - ✓ Generates PR template
   - ✓ Sets up directory structure
   - ✓ Configures branch protection

3. **POST-FLIGHT**:
   - ✓ Verifies files created
   - ✓ Lists configuration files
   - ✓ Provides next steps

All operations use real shell scripts with actual file generation!