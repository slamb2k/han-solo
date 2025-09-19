#!/bin/bash
# init-operations.sh - Actual initialization operations for han-solo
# These functions perform REAL repository setup and configuration

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

# Check if repository is already initialized
is_already_initialized() {
    [[ -f .claude/settings.json ]] || [[ -f .gitignore ]] || [[ -f CLAUDE.md ]]
}

# Check if we're in a git repository
is_git_repo() {
    git rev-parse --git-dir &>/dev/null
}

# Initialize git repository
initialize_git_repo() {
    if ! is_git_repo; then
        echo "Initializing git repository..."
        git init
        git branch -M main 2>/dev/null || git branch -M master
        return 0
    else
        echo "Git repository already initialized"
        return 0
    fi
}

# Create .gitignore file
create_gitignore() {
    local gitignore_path=".gitignore"

    if [[ -f "$gitignore_path" ]]; then
        echo "Updating existing .gitignore..."

        # Check if .claude entries exist
        if ! grep -q "^\.claude/cache" "$gitignore_path" 2>/dev/null; then
            echo "" >> "$gitignore_path"
            echo "# han-solo/Claude Code" >> "$gitignore_path"
            echo ".claude/cache/" >> "$gitignore_path"
            echo ".claude/tmp/" >> "$gitignore_path"
            echo ".claude/*.log" >> "$gitignore_path"
        fi
    else
        echo "Creating .gitignore..."
        cat > "$gitignore_path" << 'EOF'
# Dependencies
node_modules/
vendor/
venv/
.env

# Build outputs
dist/
build/
*.pyc
__pycache__/

# IDE
.vscode/
.idea/
*.swp
*.swo
.DS_Store

# han-solo/Claude Code
.claude/cache/
.claude/tmp/
.claude/*.log

# Testing
coverage/
.coverage
*.test.js
EOF
    fi

    return 0
}

# Create CLAUDE.md context file
create_claude_context() {
    local claude_path="CLAUDE.md"
    local project_name
    project_name=$(basename "$(pwd)")

    if [[ -f "$claude_path" ]]; then
        echo "CLAUDE.md already exists"
        return 0
    fi

    echo "Creating CLAUDE.md context file..."
    cat > "$claude_path" << EOF
# $project_name Project Context

## Overview
This project uses han-solo, an opinionated Git workflow orchestrator for Claude Code.

## han-solo Commands

### Core Workflow
- \`/hansolo:launch <feature>\` - Create a new feature branch
- \`/hansolo:commit [message]\` - Create atomic commit with quality checks
- \`/hansolo:ship [issue]\` - Create PR and monitor until merged
- \`/hansolo:sync\` - Sync repository (cleanup/rebase/update)

### Setup & Configuration
- \`/hansolo:init\` - Initialize repository with han-solo
- \`/hansolo:ci-setup\` - Configure CI/CD pipeline

## Workflow

1. **Start Feature**: \`/hansolo:launch my-feature\`
2. **Make Changes**: Edit files as needed
3. **Checkpoint**: \`/hansolo:commit --checkpoint\` (optional)
4. **Commit**: \`/hansolo:commit "feat: add feature"\`
5. **Ship**: \`/hansolo:ship\`
6. **Next Feature**: Automatic cleanup, ready to launch again

## Project Structure
\`\`\`
.claude/            # han-solo configuration
├── commands/       # Slash commands
├── agents/         # Squadron agents
├── hooks/          # Git hooks
└── lib/           # Shared utilities
\`\`\`

## Development Guidelines
- Linear Git history (rebase-only)
- Atomic commits (squashed checkpoints)
- Quality checks before commits
- Automated PR workflow

---
*This file provides context to Claude Code. Update as needed.*
EOF

    return 0
}

# Setup Claude directory structure
setup_claude_directory() {
    echo "Setting up .claude directory structure..."

    # Create directories
    mkdir -p .claude/{commands,agents,hooks,lib,scripts,cache,tmp}

    # Create basic settings.json if not exists
    if [[ ! -f .claude/settings.json ]]; then
        cat > .claude/settings.json << 'EOF'
{
  "han-solo": {
    "version": "1.0.0",
    "initialized": true,
    "workflow": {
      "enforceLinearHistory": true,
      "requireQualityChecks": true,
      "autoSquashCheckpoints": true,
      "protectMainBranch": true
    },
    "squadrons": {
      "gold": "branch-operations",
      "red": "pr-operations",
      "gray": "commit-operations",
      "blue": "init-operations",
      "green": "ci-operations",
      "rogue": "conflict-resolution"
    }
  }
}
EOF
    fi

    return 0
}

# Install git hooks
install_git_hooks() {
    echo "Installing git hooks..."

    # Create hooks directory if needed
    mkdir -p .git/hooks

    # Pre-commit hook
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# han-solo pre-commit hook
# Runs quality checks before allowing commits

# Check if on protected branch
BRANCH=$(git branch --show-current)
if [[ "$BRANCH" == "main" ]] || [[ "$BRANCH" == "master" ]]; then
    echo "❌ Direct commits to $BRANCH are not allowed"
    echo "Create a feature branch: /hansolo:launch"
    exit 1
fi

# Run project-specific quality checks if available
if [[ -f package.json ]] && command -v npm &>/dev/null; then
    if grep -q '"lint"' package.json; then
        echo "Running linter..."
        npm run lint || exit 1
    fi
fi

# Python projects
if [[ -f requirements.txt ]] && command -v black &>/dev/null; then
    echo "Running black formatter..."
    black --check . || exit 1
fi

echo "✓ Pre-commit checks passed"
exit 0
EOF
    chmod +x .git/hooks/pre-commit

    # Pre-push hook
    cat > .git/hooks/pre-push << 'EOF'
#!/bin/bash
# han-solo pre-push hook
# Prevents direct pushes to protected branches

while read local_ref local_sha remote_ref remote_sha; do
    if [[ "$remote_ref" =~ ^refs/heads/(main|master)$ ]]; then
        echo "❌ Direct push to protected branch not allowed"
        echo "Use /hansolo:ship to create a pull request"
        exit 1
    fi
done

exit 0
EOF
    chmod +x .git/hooks/pre-push

    return 0
}

# Setup branch protection (requires gh CLI)
setup_branch_protection() {
    if ! command -v gh &>/dev/null; then
        echo "GitHub CLI not found, skipping branch protection"
        return 0
    fi

    # Check if we have a GitHub remote
    if ! git remote get-url origin 2>/dev/null | grep -q github.com; then
        echo "No GitHub remote found, skipping branch protection"
        return 0
    fi

    echo "Configuring branch protection..."

    # This would require GitHub API permissions
    # For now, just provide instructions
    cat << 'EOF'

To complete branch protection setup:
1. Go to GitHub repository settings
2. Navigate to Branches
3. Add rule for 'main' branch:
   - Require pull request reviews
   - Dismiss stale reviews
   - Require status checks
   - Include administrators
   - Restrict force pushes

Or run: gh repo edit --default-branch main --delete-branch-on-merge
EOF

    return 0
}

# Main initialization function
initialize_hansolo() {
    local json_mode="${1:-false}"
    local force="${2:-false}"

    # Check if already initialized
    if [[ "$force" != "true" ]] && is_already_initialized; then
        if [[ "$json_mode" == "true" ]]; then
            output_init_json "already_initialized" "Repository already initialized"
        else
            echo "Repository already initialized with han-solo"
            echo "Use --force to reinitialize"
        fi
        return 1
    fi

    echo "Initializing han-solo..."
    echo ""

    # Step 1: Git repository
    if initialize_git_repo; then
        echo "✓ Git repository ready"
    fi

    # Step 2: Claude directory
    if setup_claude_directory; then
        echo "✓ Claude directory structure created"
    fi

    # Step 3: Git ignore
    if create_gitignore; then
        echo "✓ .gitignore configured"
    fi

    # Step 4: Context file
    if create_claude_context; then
        echo "✓ CLAUDE.md context created"
    fi

    # Step 5: Git hooks
    if install_git_hooks; then
        echo "✓ Git hooks installed"
    fi

    # Step 6: Branch protection
    setup_branch_protection

    echo ""
    echo "✓ han-solo initialization complete!"

    if [[ "$json_mode" == "true" ]]; then
        output_init_json "completed" "Initialization successful"
    fi

    return 0
}

# Output JSON response for init operations
output_init_json() {
    local status="$1"
    local message="$2"

    cat <<EOF
{
    "squadron": {
        "name": "blue",
        "quote": "Blue Leader, standing by...",
        "banner_type": "INITIALIZING"
    },
    "status": "$status",
    "data": {
        "message": "$message",
        "git_initialized": $(is_git_repo && echo "true" || echo "false"),
        "claude_configured": $([ -f .claude/settings.json ] && echo "true" || echo "false"),
        "hooks_installed": $([ -f .git/hooks/pre-commit ] && echo "true" || echo "false")
    }
}
EOF
}

# Note: export -f is bash-specific and not needed for sourcing
# Functions are available when script is sourced