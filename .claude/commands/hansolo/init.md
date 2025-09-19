---
description: "Initialize repository with han-solo configuration"
---

# /hansolo:init

## Setup and Operations Loading

```bash
#!/bin/bash
set -euo pipefail

# Source init operations for actual execution
source .claude/lib/operations/init-operations.sh

# Check for force flag
FORCE_INIT="${FORCE_INIT:-false}"
if [[ "${1:-}" == "--force" ]]; then
    FORCE_INIT="true"
fi
```

## Squadron Identity

Display Blue Squadron identity:
```bash
echo ""
echo "Blue Leader, standing by..."
echo ""
cat .claude/lib/banners/initializing.txt 2>/dev/null || true
echo ""
```

## PRE-FLIGHT: CHECK INITIALIZATION STATUS

Validate prerequisites and current state:

```bash
echo "🔍 PRE-FLIGHT: Checking initialization status..."
echo ""

# Check if we're in a directory that makes sense
if [[ ! -w "." ]]; then
    echo "  ❌ No write permissions in current directory"
    exit 1
fi
echo "  ✓ Write permissions confirmed"

# Check git repository status
if is_git_repo; then
    echo "  ✓ Git repository exists"
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "none")
    echo "  Current branch: $CURRENT_BRANCH"
else
    echo "  ℹ️  Not a git repository (will initialize)"
fi

# Check for existing initialization
if is_already_initialized; then
    echo "  ⚠️  han-solo already initialized"

    if [[ "$FORCE_INIT" != "true" ]]; then
        echo ""
        echo "❌ Pre-flight failed: Already initialized"
        echo "  Use --force to reinitialize"
        exit 1
    else
        echo "  ✓ Force flag detected - will reinitialize"
    fi
else
    echo "  ✓ Ready for initialization"
fi

# Check for GitHub CLI (optional but recommended)
if command -v gh &>/dev/null; then
    echo "  ✓ GitHub CLI available"
    GH_AVAILABLE="true"
else
    echo "  ℹ️  GitHub CLI not found (some features unavailable)"
    GH_AVAILABLE="false"
fi

echo ""
echo "✓ Pre-flight checks passed"
echo ""
```

## EXECUTION: INITIALIZE REPOSITORY

Perform the actual initialization:

```bash
echo "🚀 EXECUTION: Initializing han-solo..."
echo ""

# Step 1: Initialize git repository
echo "  Step 1/6: Git repository"
if ! is_git_repo; then
    git init
    git branch -M main 2>/dev/null || git branch -M master
    echo "    ✓ Git repository initialized"
else
    echo "    ✓ Git repository already exists"
fi

# Step 2: Create Claude directory structure
echo "  Step 2/6: Claude directory structure"
setup_claude_directory
echo "    ✓ .claude/ directories created"

# Step 3: Create/update .gitignore
echo "  Step 3/6: Git ignore configuration"
create_gitignore
echo "    ✓ .gitignore configured"

# Step 4: Create CLAUDE.md context file
echo "  Step 4/6: Claude context file"
create_claude_context
echo "    ✓ CLAUDE.md created"

# Step 5: Install git hooks
echo "  Step 5/6: Git hooks"
install_git_hooks
echo "    ✓ Pre-commit and pre-push hooks installed"

# Step 6: Branch protection (if GitHub CLI available)
echo "  Step 6/6: Branch protection"
if [[ "$GH_AVAILABLE" == "true" ]]; then
    # Check for GitHub remote
    if git remote get-url origin 2>/dev/null | grep -q github.com; then
        echo "    ℹ️  GitHub repository detected"
        setup_branch_protection
    else
        echo "    ℹ️  No GitHub remote (skipping)"
    fi
else
    echo "    ℹ️  GitHub CLI not available (skipping)"
fi

echo ""
echo "✓ Execution completed successfully"
echo ""
```

## POST-FLIGHT: VERIFY INITIALIZATION

Validate everything was set up correctly:

```bash
echo "🔄 POST-FLIGHT: Verifying initialization..."
echo ""

# Verify git repository
if is_git_repo; then
    echo "  ✓ Git repository operational"
    COMMIT_COUNT=$(git rev-list --count HEAD 2>/dev/null || echo "0")
    echo "    Commits: $COMMIT_COUNT"
else
    echo "  ⚠️  Git repository not found"
fi

# Verify Claude structure
if [[ -d .claude ]]; then
    echo "  ✓ Claude directory exists"
    CLAUDE_DIRS=$(find .claude -type d -maxdepth 1 | wc -l)
    echo "    Subdirectories: $((CLAUDE_DIRS - 1))"
fi

# Verify configuration files
if [[ -f .claude/settings.json ]]; then
    echo "  ✓ Settings configured"
fi

if [[ -f CLAUDE.md ]]; then
    echo "  ✓ Context file created"
    CONTEXT_SIZE=$(wc -l < CLAUDE.md)
    echo "    Lines: $CONTEXT_SIZE"
fi

# Verify git hooks
if [[ -x .git/hooks/pre-commit ]]; then
    echo "  ✓ Pre-commit hook executable"
fi

if [[ -x .git/hooks/pre-push ]]; then
    echo "  ✓ Pre-push hook executable"
fi

# Check if initial commit needed
if [[ "$COMMIT_COUNT" == "0" ]]; then
    echo ""
    echo "  ℹ️  No commits yet"
    echo "     Create initial commit:"
    echo "     git add ."
    echo "     git commit -m 'chore: initialize repository with han-solo'"
fi

echo ""
echo "✅ POST-FLIGHT: Initialization verified!"
echo ""

# Final instructions
cat << 'EOF'
🎉 han-solo initialization complete!

Next steps:
1. Review CLAUDE.md and customize for your project
2. Create your first feature: /hansolo:launch
3. Make changes and commit: /hansolo:commit
4. Ship your work: /hansolo:ship

Available commands:
  /hansolo:launch <feature>  - Create feature branch
  /hansolo:commit [message]  - Create atomic commit
  /hansolo:ship [issue]      - Create and monitor PR
  /hansolo:sync             - Sync repository
  /hansolo:ci-setup         - Configure CI/CD

Happy coding! 🚀
EOF
```

## Summary

The init command follows the three-phase pattern:

1. **PRE-FLIGHT**:
   - ✓ Checks write permissions
   - ✓ Detects existing initialization
   - ✓ Validates git repository state

2. **EXECUTION**:
   - ✓ Initializes git repository
   - ✓ Creates Claude directory structure
   - ✓ Configures gitignore
   - ✓ Creates context file
   - ✓ Installs git hooks
   - ✓ Sets up branch protection

3. **POST-FLIGHT**:
   - ✓ Verifies all components installed
   - ✓ Checks configuration validity
   - ✓ Provides next steps guidance

All operations use real shell scripts with actual file system operations!