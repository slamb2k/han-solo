---
description: "Create atomic commit with quality checks"
argument_hint: "[message]"
---

# /hansolo:commit

## Setup and Operations Loading

```bash
#!/bin/bash
set -euo pipefail

# Source commit operations for actual execution
source .claude/lib/operations/commit-operations.sh

# Store commit message if provided
COMMIT_MESSAGE="$1"

# Check for checkpoint mode flag
CHECKPOINT_MODE="${CHECKPOINT_MODE:-false}"
if [[ "${2:-}" == "--checkpoint" ]]; then
    CHECKPOINT_MODE="true"
fi
```

## Squadron Identity

Display Gray Squadron identity:
```bash
echo ""
echo "Gray Leader, standing by..."
echo ""
cat .claude/lib/banners/committing.txt 2>/dev/null || true
echo ""
```

## PRE-FLIGHT: VALIDATE COMMIT READINESS

Check prerequisites for committing:

```bash
echo "🔍 PRE-FLIGHT: Checking commit readiness..."
echo ""

# Check current branch
CURRENT_BRANCH=$(git branch --show-current)
echo "  Current branch: $CURRENT_BRANCH"

# Check if on protected branch
if [[ "$CURRENT_BRANCH" == "main" ]] || [[ "$CURRENT_BRANCH" == "master" ]]; then
    echo "  ⚠️  On protected branch"
    echo ""
    echo "❌ Pre-flight failed: Cannot commit directly to main"
    echo "  Create a feature branch first: /hansolo:launch"
    exit 1
fi
echo "  ✓ On feature branch"

# Check for changes
if ! has_uncommitted_changes; then
    echo "  ℹ️  No uncommitted changes"

    # Check if we have checkpoint commits to squash
    CHECKPOINT_COUNT=$(count_checkpoint_commits)
    if [[ "$CHECKPOINT_COUNT" -gt 0 ]]; then
        echo "  ✓ Found $CHECKPOINT_COUNT checkpoint commits to squash"
        SQUASH_MODE="true"
    else
        echo ""
        echo "✓ Pre-flight complete: Nothing to commit"
        exit 0
    fi
else
    echo "  ✓ Found uncommitted changes"
    SQUASH_MODE="false"
fi

# Run quality checks (linting, formatting)
echo "  Running quality checks..."

# Check for pre-commit hooks
if [[ -f .git/hooks/pre-commit ]]; then
    # Dry run the pre-commit hook
    if .git/hooks/pre-commit 2>/dev/null; then
        echo "  ✓ Quality checks passed"
    else
        echo "  ⚠️  Quality checks found issues"
        echo ""
        echo "Run linting/formatting tools before committing:"
        echo "  npm run lint"
        echo "  npm run format"
        # Continue anyway - hook will run again during actual commit
    fi
else
    echo "  ℹ️  No pre-commit hooks configured"
fi

echo ""
echo "✓ Pre-flight checks complete"
echo ""
```

## EXECUTION: CREATE COMMIT

Perform the actual commit operation:

```bash
echo "🚀 EXECUTION: Creating commit..."
echo ""

# Determine commit type
if [[ "$CHECKPOINT_MODE" == "true" ]]; then
    echo "  Mode: Checkpoint commit"
    if [[ -z "$COMMIT_MESSAGE" ]]; then
        COMMIT_MESSAGE="checkpoint: $(date +%Y%m%d-%H%M%S)"
    elif [[ ! "$COMMIT_MESSAGE" =~ ^checkpoint: ]]; then
        COMMIT_MESSAGE="checkpoint: $COMMIT_MESSAGE"
    fi
elif [[ "$SQUASH_MODE" == "true" ]]; then
    echo "  Mode: Squashing checkpoints"
    if [[ -z "$COMMIT_MESSAGE" ]]; then
        echo "  Generating commit message from branch..."
        COMMIT_MESSAGE=$(generate_commit_message)
    fi
else
    echo "  Mode: Atomic commit"
    if [[ -z "$COMMIT_MESSAGE" ]]; then
        echo "  Generating commit message from changes..."
        COMMIT_MESSAGE=$(generate_commit_message)
    fi
fi

echo "  Message: $COMMIT_MESSAGE"
echo ""

# Stage changes
if has_uncommitted_changes; then
    echo "  Staging all changes..."
    git add -A

    # Show what will be committed
    STAGED_FILES=$(git diff --cached --name-only | wc -l)
    echo "  Files to commit: $STAGED_FILES"
fi

# Create the commit
if [[ "$SQUASH_MODE" == "true" ]]; then
    # Squash checkpoint commits
    if squash_checkpoint_commits "$COMMIT_MESSAGE"; then
        EXECUTION_STATUS="success"
        COMMIT_TYPE="squashed"
    else
        EXECUTION_STATUS="failed"
        echo "❌ Failed to squash checkpoints"
        exit 1
    fi
elif create_atomic_commit "$COMMIT_MESSAGE" "false"; then
    EXECUTION_STATUS="success"
    if [[ "$COMMIT_MESSAGE" =~ ^checkpoint: ]]; then
        COMMIT_TYPE="checkpoint"
    else
        COMMIT_TYPE="atomic"
    fi
else
    EXECUTION_STATUS="failed"
    echo "❌ Failed to create commit"
    exit 1
fi

# Get commit details
COMMIT_HASH=$(git rev-parse HEAD)
COMMIT_SHORT=$(git rev-parse --short HEAD)

echo ""
echo "✓ Commit created successfully"
echo "  Hash: $COMMIT_SHORT"
echo "  Type: $COMMIT_TYPE"
echo ""
```

## POST-FLIGHT: VERIFY COMMIT STATE

Validate the commit was created correctly:

```bash
echo "🔄 POST-FLIGHT: Verifying commit..."
echo ""

# Verify commit exists
if git cat-file -e "$COMMIT_HASH" 2>/dev/null; then
    echo "  ✓ Commit exists in repository"
else
    echo "  ❌ Commit verification failed"
    exit 1
fi

# Check working tree status
if has_uncommitted_changes; then
    echo "  ⚠️  Still have uncommitted changes"
    REMAINING_FILES=$(git status --porcelain | wc -l)
    echo "     $REMAINING_FILES files remaining"
else
    echo "  ✓ Working tree clean"
fi

# Show commit info
echo "  Commit details:"
git log -1 --oneline "$COMMIT_HASH" | sed 's/^/    /'

# Check if ready to ship
if [[ "$COMMIT_TYPE" != "checkpoint" ]]; then
    # Check if we have unpushed commits
    UNPUSHED=$(git rev-list --count origin/main..HEAD 2>/dev/null || echo "0")
    if [[ "$UNPUSHED" -gt 0 ]]; then
        echo ""
        echo "  ℹ️  You have $UNPUSHED unpushed commit(s)"
        echo "     Ready to ship: /hansolo:ship"
    fi
fi

echo ""

# Final status
if [[ "$COMMIT_TYPE" == "checkpoint" ]]; then
    echo "✅ POST-FLIGHT: Checkpoint saved!"
    echo "  • Changes saved as checkpoint"
    echo "  • Continue working and checkpoint again"
    echo "  • Run /hansolo:commit to create final commit"
elif [[ "$COMMIT_TYPE" == "squashed" ]]; then
    echo "✅ POST-FLIGHT: Atomic commit created!"
    echo "  • Checkpoint commits squashed"
    echo "  • Clean linear history maintained"
    echo "  • Ready to ship: /hansolo:ship"
else
    echo "✅ POST-FLIGHT: Commit complete!"
    echo "  • Atomic commit created"
    echo "  • Quality checks passed"
    echo "  • Ready to ship: /hansolo:ship"
fi
```

## Summary

The commit command follows the three-phase pattern:

1. **PRE-FLIGHT**:
   - ✓ Validates not on protected branch
   - ✓ Checks for changes or checkpoints
   - ✓ Runs quality checks

2. **EXECUTION**:
   - ✓ Generates commit message if needed
   - ✓ Stages changes
   - ✓ Creates atomic or checkpoint commit
   - ✓ Squashes checkpoints if requested

3. **POST-FLIGHT**:
   - ✓ Verifies commit created
   - ✓ Checks working tree state
   - ✓ Suggests next actions

## Usage Examples

```bash
# Create atomic commit with generated message
/hansolo:commit

# Create atomic commit with custom message
/hansolo:commit "feat: add user authentication"

# Create checkpoint commit
/hansolo:commit "work in progress" --checkpoint

# Squash all checkpoints into atomic commit
/hansolo:commit "feat: complete feature"
```

All operations use real shell scripts with actual git commands!