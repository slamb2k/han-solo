---
description: "Sync repository - cleanup merged branches or rebase unmerged ones"
---

# /hansolo:sync

## Setup and Operations Loading

```bash
#!/bin/bash
set -euo pipefail

# Source sync operations for actual execution
source .claude/lib/operations/sync-operations.sh

# Check for JSON mode (for when called by other commands)
JSON_MODE="${JSON_MODE:-false}"
```

## Squadron Identity

Display Gold Squadron identity (unless in JSON mode):

**Gold Leader, standing by...**

```
███████╗██╗   ██╗███╗   ██╗ ██████╗██╗███╗   ██╗ ██████╗
██╔════╝╚██╗ ██╔╝████╗  ██║██╔════╝██║████╗  ██║██╔════╝
███████╗ ╚████╔╝ ██╔██╗ ██║██║     ██║██╔██╗ ██║██║  ███╗
╚════██║  ╚██╔╝  ██║╚██╗██║██║     ██║██║╚██╗██║██║   ██║
███████║   ██║   ██║ ╚████║╚██████╗██║██║ ╚████║╚██████╔╝
╚══════╝   ╚═╝   ╚═╝  ╚═══╝ ╚═════╝╚═╝╚═╝  ╚═══╝ ╚═════╝
```

## PRE-FLIGHT: DETECT SYNC MODE

Analyze current state to determine what sync operation is needed:

```bash
echo "🔍 PRE-FLIGHT: Analyzing branch state..."
echo ""

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
echo "  Current branch: $CURRENT_BRANCH"

# Detect what type of sync we need
SYNC_MODE=$(detect_sync_mode)
echo "  Detected mode: $SYNC_MODE"

# Pre-flight validation based on mode
case "$SYNC_MODE" in
    cleanup)
        echo "  ✓ Branch has been merged to main"
        echo "  ✓ Ready for cleanup"
        ;;
    rebase)
        echo "  ✓ Branch needs rebasing onto main"

        # Check for uncommitted changes
        if [[ -n "$(git status --porcelain)" ]]; then
            echo "  ⚠️  Uncommitted changes detected"
            echo ""
            echo "❌ Pre-flight failed: Commit or stash changes before sync"
            exit 1
        fi
        echo "  ✓ Working tree clean"
        ;;
    update)
        echo "  ✓ On main branch"
        echo "  ✓ Ready to pull latest"
        ;;
    *)
        echo "  ❌ Unknown sync mode"
        exit 1
        ;;
esac

echo ""
echo "✓ Pre-flight checks passed"
echo ""
```

## EXECUTION: PERFORM SYNC OPERATION

Execute the appropriate sync operation:

```bash
echo "🚀 EXECUTION: Performing $SYNC_MODE operation..."
echo ""

case "$SYNC_MODE" in
    cleanup)
        echo "  Switching to main branch..."
        echo "  Pulling latest changes..."
        echo "  Deleting merged feature branch..."

        # Store the branch name before cleanup
        PREVIOUS_BRANCH="$CURRENT_BRANCH"

        # Perform cleanup
        if cleanup_merged_branch; then
            EXECUTION_STATUS="success"
            CLEANUP_PERFORMED="true"
        else
            EXECUTION_STATUS="failed"
            CLEANUP_PERFORMED="false"
        fi
        ;;

    rebase)
        echo "  Fetching latest from origin..."
        echo "  Rebasing onto origin/main..."

        # Perform rebase
        if rebase_on_main; then
            EXECUTION_STATUS="success"
            echo ""
            echo "  ✓ Successfully rebased on main"
        else
            EXECUTION_STATUS="conflict"
            echo ""
            echo "  ⚠️  Rebase conflicts detected"
            echo ""
            echo "  Resolve conflicts manually:"
            echo "    1. Fix conflicted files"
            echo "    2. git add <resolved-files>"
            echo "    3. git rebase --continue"
            echo ""
            echo "  Or abort with: git rebase --abort"
            exit 1
        fi
        CLEANUP_PERFORMED="false"
        ;;

    update)
        echo "  Pulling latest changes from origin..."

        # Perform update
        if update_main; then
            EXECUTION_STATUS="success"
        else
            EXECUTION_STATUS="failed"
        fi
        CLEANUP_PERFORMED="false"
        ;;
esac

if [[ "$EXECUTION_STATUS" == "success" ]]; then
    echo ""
    echo "✓ Execution completed successfully"
else
    echo ""
    echo "❌ Execution failed"
    exit 1
fi
echo ""
```

## POST-FLIGHT: VERIFY FINAL STATE

Validate the sync operation completed correctly:

```bash
echo "🔄 POST-FLIGHT: Verifying final state..."
echo ""

# Get new branch state
NEW_BRANCH=$(git branch --show-current)
echo "  Current branch: $NEW_BRANCH"

# Get latest commit
LATEST_COMMIT=$(git log -1 --oneline)
echo "  Latest commit: $LATEST_COMMIT"

# Check sync with origin
AHEAD_BEHIND=$(git rev-list --left-right --count origin/main...HEAD 2>/dev/null || echo "0 0")
AHEAD=$(echo "$AHEAD_BEHIND" | awk '{print $2}')
BEHIND=$(echo "$AHEAD_BEHIND" | awk '{print $1}')

if [[ "$BEHIND" -gt 0 ]]; then
    echo "  ⚠️  Branch is $BEHIND commits behind origin/main"
elif [[ "$AHEAD" -gt 0 ]]; then
    echo "  ℹ️  Branch is $AHEAD commits ahead of origin/main"
else
    echo "  ✓ Branch is up to date with origin/main"
fi

# Final validation based on sync mode
case "$SYNC_MODE" in
    cleanup)
        if [[ "$NEW_BRANCH" == "main" ]] || [[ "$NEW_BRANCH" == "master" ]]; then
            echo "  ✓ Successfully switched to main"
            echo "  ✓ Feature branch cleaned up"
            POST_FLIGHT_STATUS="success"
        else
            echo "  ⚠️  Still on feature branch: $NEW_BRANCH"
            POST_FLIGHT_STATUS="warning"
        fi
        ;;

    rebase)
        if [[ "$NEW_BRANCH" == "$CURRENT_BRANCH" ]]; then
            echo "  ✓ Still on feature branch: $NEW_BRANCH"
            echo "  ✓ Rebased onto latest main"
            POST_FLIGHT_STATUS="success"
        else
            echo "  ⚠️  Unexpected branch switch"
            POST_FLIGHT_STATUS="warning"
        fi
        ;;

    update)
        if [[ "$NEW_BRANCH" == "main" ]] || [[ "$NEW_BRANCH" == "master" ]]; then
            echo "  ✓ Main branch updated"
            POST_FLIGHT_STATUS="success"
        else
            echo "  ⚠️  Not on main branch"
            POST_FLIGHT_STATUS="warning"
        fi
        ;;
esac

echo ""

# Output final status
if [[ "$POST_FLIGHT_STATUS" == "success" ]]; then
    echo "✅ POST-FLIGHT: Sync complete!"

    case "$SYNC_MODE" in
        cleanup)
            echo "  • Merged branch cleaned up"
            echo "  • Switched to main"
            echo "  • Ready for next feature"
            ;;
        rebase)
            echo "  • Branch rebased on main"
            echo "  • Linear history maintained"
            echo "  • Ready to continue development"
            ;;
        update)
            echo "  • Main branch updated"
            echo "  • Latest changes pulled"
            echo "  • Repository synchronized"
            ;;
    esac
else
    echo "⚠️  POST-FLIGHT: Sync completed with warnings"
    echo "  • Check branch state manually"
fi
```

## JSON Mode Output

If called in JSON mode (by ship or other commands), output structured response:

```bash
if [[ "$JSON_MODE" == "true" ]]; then
    # Output JSON response
    cat <<EOF
{
    "squadron": {
        "name": "gold",
        "quote": "Gold Leader, standing by...",
        "banner_type": "SYNCING"
    },
    "status": "completed",
    "data": {
        "sync_mode": "$SYNC_MODE",
        "current_branch": "$NEW_BRANCH",
        "previous_branch": "${PREVIOUS_BRANCH:-$CURRENT_BRANCH}",
        "cleanup_performed": ${CLEANUP_PERFORMED:-false}
    }
}
EOF
fi
```

## Summary

The sync command follows the three-phase pattern:

1. **PRE-FLIGHT**:
   - ✓ Detects current branch state
   - ✓ Determines sync mode (cleanup/rebase/update)
   - ✓ Validates prerequisites

2. **EXECUTION**:
   - ✓ Performs actual sync operation
   - ✓ Handles each mode appropriately
   - ✓ Reports conflicts if they occur

3. **POST-FLIGHT**:
   - ✓ Verifies final branch state
   - ✓ Confirms sync completed
   - ✓ Validates expected outcomes

Multi-purpose synchronization that adapts to your current branch state.

## Usage Patterns

### Manual Usage
```bash
/hansolo:sync  # Manually sync at any time
```

### Automatic Usage
Called automatically by `/hansolo:ship` after successful PR merge to complete the workflow.

## Complete Workflow Integration

When called by ship command:
1. Ship creates and monitors PR
2. After merge, ship calls sync
3. Sync detects merged branch
4. Performs cleanup automatically
5. Returns to main, ready for next feature

Note: This command is idempotent - safe to run multiple times.

All operations use real shell scripts with actual git commands!