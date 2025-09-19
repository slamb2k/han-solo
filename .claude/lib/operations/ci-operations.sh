#!/bin/bash
# ci-operations.sh - Actual CI/CD setup operations for han-solo
# These functions perform REAL CI/CD configuration and workflow generation

set -euo pipefail

# Source utilities if available
if [ -n "${BASH_SOURCE[0]:-}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [ -n "${ZSH_VERSION:-}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
else
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi
LIB_DIR="$(dirname "$SCRIPT_DIR")"

# Detect project type
detect_project_type() {
    if [[ -f "package.json" ]]; then
        echo "node"
    elif [[ -f "requirements.txt" ]] || [[ -f "setup.py" ]] || [[ -f "pyproject.toml" ]]; then
        echo "python"
    elif [[ -f "go.mod" ]]; then
        echo "go"
    elif [[ -f "Cargo.toml" ]]; then
        echo "rust"
    elif [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]]; then
        echo "java"
    elif [[ -f "Gemfile" ]]; then
        echo "ruby"
    elif [[ -f "composer.json" ]]; then
        echo "php"
    else
        echo "generic"
    fi
}

# Get test command for project type
get_test_command() {
    local project_type="$1"

    case "$project_type" in
        node)
            if grep -q '"test"' package.json 2>/dev/null; then
                echo "npm test"
            else
                echo "echo 'No tests configured'"
            fi
            ;;
        python)
            if [[ -f "pytest.ini" ]] || [[ -f "setup.cfg" ]]; then
                echo "pytest"
            elif [[ -d "tests" ]]; then
                echo "python -m unittest discover"
            else
                echo "echo 'No tests configured'"
            fi
            ;;
        go)
            echo "go test ./..."
            ;;
        rust)
            echo "cargo test"
            ;;
        *)
            echo "echo 'No tests configured'"
            ;;
    esac
}

# Get lint command for project type
get_lint_command() {
    local project_type="$1"

    case "$project_type" in
        node)
            if grep -q '"lint"' package.json 2>/dev/null; then
                echo "npm run lint"
            else
                echo "echo 'No linter configured'"
            fi
            ;;
        python)
            if command -v flake8 &>/dev/null; then
                echo "flake8 ."
            elif command -v pylint &>/dev/null; then
                echo "pylint **/*.py"
            else
                echo "echo 'No linter configured'"
            fi
            ;;
        go)
            echo "go vet ./..."
            ;;
        rust)
            echo "cargo clippy -- -D warnings"
            ;;
        *)
            echo "echo 'No linter configured'"
            ;;
    esac
}

# Get build command for project type
get_build_command() {
    local project_type="$1"

    case "$project_type" in
        node)
            if grep -q '"build"' package.json 2>/dev/null; then
                echo "npm run build"
            else
                echo "echo 'No build step required'"
            fi
            ;;
        python)
            if [[ -f "setup.py" ]]; then
                echo "python setup.py build"
            else
                echo "echo 'No build step required'"
            fi
            ;;
        go)
            echo "go build ./..."
            ;;
        rust)
            echo "cargo build --release"
            ;;
        java)
            if [[ -f "pom.xml" ]]; then
                echo "mvn package"
            elif [[ -f "build.gradle" ]]; then
                echo "gradle build"
            fi
            ;;
        *)
            echo "echo 'No build step required'"
            ;;
    esac
}

# Create GitHub Actions workflow
create_github_actions_workflow() {
    local project_type="$1"
    local include_deploy="${2:-false}"
    local workflow_path=".github/workflows/ci.yml"

    # Create .github/workflows directory
    mkdir -p "$(dirname "$workflow_path")"

    # Get commands
    local test_cmd=$(get_test_command "$project_type")
    local lint_cmd=$(get_lint_command "$project_type")
    local build_cmd=$(get_build_command "$project_type")

    echo "Creating GitHub Actions workflow for $project_type project..."

    # Generate workflow content
    cat > "$workflow_path" << EOF
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  quality:
    name: Quality Checks
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

EOF

    # Add language-specific setup
    case "$project_type" in
        node)
            cat >> "$workflow_path" << 'EOF'
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'

    - name: Install dependencies
      run: npm ci

EOF
            ;;
        python)
            cat >> "$workflow_path" << 'EOF'
    - name: Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'

    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt

EOF
            ;;
        go)
            cat >> "$workflow_path" << 'EOF'
    - name: Setup Go
      uses: actions/setup-go@v4
      with:
        go-version: '1.21'

    - name: Install dependencies
      run: go mod download

EOF
            ;;
        rust)
            cat >> "$workflow_path" << 'EOF'
    - name: Setup Rust
      uses: actions-rs/toolchain@v1
      with:
        toolchain: stable
        profile: minimal
        override: true

EOF
            ;;
    esac

    # Add test, lint, and build steps
    cat >> "$workflow_path" << EOF
    - name: Run linter
      run: $lint_cmd

    - name: Run tests
      run: $test_cmd

    - name: Build project
      run: $build_cmd
EOF

    # Add deployment job if requested
    if [[ "$include_deploy" == "true" ]]; then
        cat >> "$workflow_path" << 'EOF'

  deploy:
    name: Deploy
    needs: quality
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'

    steps:
    - uses: actions/checkout@v3

    # Add deployment steps here
    - name: Deploy to production
      run: |
        echo "Add your deployment commands here"
        # Examples:
        # - Deploy to AWS: aws s3 sync . s3://bucket-name
        # - Deploy to Heroku: git push heroku main
        # - Deploy to Vercel: vercel --prod
      env:
        # Add your deployment secrets as GitHub Secrets
        # DEPLOY_KEY: ${{ secrets.DEPLOY_KEY }}
EOF
    fi

    echo "✓ GitHub Actions workflow created at $workflow_path"
    return 0
}

# Create pull request template
create_pr_template() {
    local template_path=".github/pull_request_template.md"

    mkdir -p "$(dirname "$template_path")"

    cat > "$template_path" << 'EOF'
## Description
Brief description of the changes in this PR.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] I have tested these changes locally
- [ ] All tests pass
- [ ] I have added tests that prove my fix is effective or that my feature works

## Checklist
- [ ] My code follows the style guidelines of this project
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings

## Related Issues
Closes #(issue number)

## Screenshots (if applicable)
Add screenshots to help explain your changes.
EOF

    echo "✓ Pull request template created at $template_path"
    return 0
}

# Setup branch protection rules
setup_branch_protection() {
    if ! command -v gh &>/dev/null; then
        echo "GitHub CLI not found, skipping branch protection setup"
        return 0
    fi

    # Check if we have a GitHub remote
    if ! git remote get-url origin 2>/dev/null | grep -q github.com; then
        echo "No GitHub remote found, skipping branch protection"
        return 0
    fi

    echo "Setting up branch protection rules..."

    # This would require GitHub API permissions
    cat << 'EOF'

To complete branch protection setup:
1. Go to GitHub repository settings
2. Navigate to Branches
3. Add rule for 'main' branch:
   - Require pull request reviews before merging
   - Dismiss stale pull request approvals when new commits are pushed
   - Require status checks to pass before merging
   - Require branches to be up to date before merging
   - Include administrators
   - Restrict who can push to matching branches

Or use GitHub CLI:
gh api repos/:owner/:repo/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["quality"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"dismiss_stale_reviews":true,"require_code_owner_reviews":true}'
EOF

    return 0
}

# Main CI setup function
setup_ci_pipeline() {
    local include_deploy="${1:-false}"
    local json_mode="${2:-false}"

    echo "Setting up CI/CD pipeline..."
    echo ""

    # Detect project type
    local project_type=$(detect_project_type)
    echo "Detected project type: $project_type"

    # Create workflow
    if create_github_actions_workflow "$project_type" "$include_deploy"; then
        echo "✓ GitHub Actions workflow created"
    else
        echo "✗ Failed to create workflow"
        return 1
    fi

    # Create PR template
    if create_pr_template; then
        echo "✓ Pull request template created"
    fi

    # Setup branch protection
    setup_branch_protection

    echo ""
    echo "✓ CI/CD pipeline setup complete!"

    if [[ "$json_mode" == "true" ]]; then
        output_ci_json "$project_type" "$include_deploy"
    fi

    return 0
}

# Output JSON response for CI operations
output_ci_json() {
    local project_type="$1"
    local deploy_enabled="$2"

    cat <<EOF
{
    "squadron": {
        "name": "green",
        "quote": "Green Leader, standing by...",
        "banner_type": "CONFIGURING"
    },
    "status": "completed",
    "data": {
        "project_type": "$project_type",
        "workflow_created": true,
        "pr_template_created": true,
        "deploy_enabled": $deploy_enabled,
        "files_created": [
            ".github/workflows/ci.yml",
            ".github/pull_request_template.md"
        ]
    }
}
EOF
}

# Note: Functions are available when script is sourced