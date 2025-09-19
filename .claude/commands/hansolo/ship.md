---
description: "Create pull request with auto-generated description"
argument_hint: "[issue-number]"
---

# /hansolo:ship

## Setup and Operations Loading

```bash
#!/bin/bash
set -euo pipefail

# Source operation scripts for actual execution
source .claude/lib/operations/branch-operations.sh
source .claude/lib/operations/pr-operations.sh
source .claude/lib/operations/sync-operations.sh

# Store issue number if provided
ISSUE_NUMBER="$1"
```

## Squadron Identity

Display Red Squadron identity:

**Red Leader, standing by...**

```
███████╗██╗  ██╗██╗██████╗ ██████╗ ██╗███╗   ██╗ ██████╗
██╔════╝██║  ██║██║██╔══██╗██╔══██╗██║████╗  ██║██╔════╝
███████╗███████║██║██████╔╝██████╔╝██║██╔██╗ ██║██║  ███╗
╚════██║██╔══██║██║██╔═══╝ ██╔═══╝ ██║██║╚██╗██║██║   ██║
███████║██║  ██║██║██║     ██║     ██║██║ ╚████║╚██████╔╝
╚══════╝╚═╝  ╚═╝╚═╝╚═╝     ╚═╝     ╚═╝╚═╝  ╚═══╝ ╚═════╝
```

## PRE-FLIGHT CHECKS

Validate we're ready to ship:

### 1. Check Current Branch State
```bash
echo "🔍 Pre-flight checks..."

# Get current branch state
BRANCH_STATE=$(.claude/scripts/check-branch-state.sh)
NEEDS_NEW_BRANCH=$(echo "$BRANCH_STATE" | jq -r '.needs_new_branch')
CURRENT_BRANCH=$(echo "$BRANCH_STATE" | jq -r '.current_branch')
PR_EXISTS=$(echo "$BRANCH_STATE" | jq -r '.pr_exists')
PR_STATE=$(echo "$BRANCH_STATE" | jq -r '.pr_state')
PR_URL=$(echo "$BRANCH_STATE" | jq -r '.pr_url')

echo "  Current branch: $CURRENT_BRANCH"
```

### 2. Handle Protected Branch
```bash
if [[ "$NEEDS_NEW_BRANCH" == "true" ]]; then
    echo "  ⚠️  On protected branch - need feature branch"
    echo ""
    echo "📍 Creating feature branch..."

    # Use branch operations to create branch
    LAUNCH_RESULT=$(create_feature_branch "" "true")
    BRANCH_CREATED=$(echo "$LAUNCH_RESULT" | jq -r '.data.branch_created // ""')

    if [[ -z "$BRANCH_CREATED" ]]; then
        echo "❌ Pre-flight failed: Could not create feature branch"
        exit 1
    fi

    echo "  ✓ Created and switched to: $BRANCH_CREATED"

    # Show Gold Squadron banner since we launched
    echo ""
    echo "Gold Leader, standing by..."
    echo ""
    echo "██╗      █████╗ ██╗   ██╗███╗   ██╗ ██████╗██╗  ██╗██╗███╗   ██╗ ██████╗"
    echo "██║     ██╔══██╗██║   ██║████╗  ██║██╔════╝██║  ██║██║████╗  ██║██╔════╝"
    echo "██║     ███████║██║   ██║██╔██╗ ██║██║     ███████║██║██╔██╗ ██║██║  ███╗"
    echo "██║     ██╔══██║██║   ██║██║╚██╗██║██║     ██╔══██║██║██║╚██╗██║██║   ██║"
    echo "███████╗██║  ██║╚██████╔╝██║ ╚████║╚██████╗██║  ██║██║██║ ╚████║╚██████╔╝"
    echo "╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝"
    echo ""

    # Update current branch
    CURRENT_BRANCH="$BRANCH_CREATED"
else
    echo "  ✓ On feature branch: $CURRENT_BRANCH"
fi
```

### 3. Check for Existing PR
```bash
if [[ "$PR_EXISTS" == "true" ]]; then
    if [[ "$PR_STATE" == "OPEN" ]]; then
        echo "  ⚠️  PR already exists: $PR_URL"
        echo ""
        echo "✓ Pre-flight complete: Nothing to ship (PR exists)"
        exit 0
    elif [[ "$PR_STATE" == "MERGED" ]]; then
        echo "  ⚠️  Branch already shipped (PR was merged)"
        echo ""
        echo "Create a new feature branch for additional changes."
        exit 0
    fi
fi

echo "  ✓ No existing PR found"
echo ""
echo "✓ Pre-flight checks passed"
echo ""
```

## EXECUTION: CREATE PULL REQUEST

Perform the actual PR creation:

```bash
echo "🚀 EXECUTION: Creating pull request..."
echo ""

# Generate PR content
echo "  Analyzing changes..."
PR_TITLE=$(generate_pr_title)
PR_BODY=$(generate_pr_body)

echo "  Title: $PR_TITLE"
echo ""

# Create the actual PR
PR_JSON=$(create_pull_request "$PR_TITLE" "$PR_BODY" "$ISSUE_NUMBER" "true")
EXIT_CODE=$?

if [[ $EXIT_CODE -ne 0 ]]; then
    echo "❌ Execution failed: Could not create PR"
    echo "$PR_JSON" | jq -r '.error.message // "Unknown error"' >&2
    exit 1
fi

# Extract PR details
PR_NUMBER=$(echo "$PR_JSON" | jq -r '.data.pr_number // ""')
PR_URL=$(echo "$PR_JSON" | jq -r '.data.pr_url // ""')
AUTO_MERGE=$(echo "$PR_JSON" | jq -r '.data.auto_merge_enabled // false')

if [[ -z "$PR_NUMBER" ]]; then
    echo "❌ Execution failed: No PR number returned"
    exit 1
fi

echo "✓ PR #$PR_NUMBER created successfully"
echo "  URL: $PR_URL"

if [[ "$AUTO_MERGE" == "true" ]]; then
    echo "  ✓ Auto-merge enabled"
else
    echo "  ℹ Auto-merge not enabled (may need approvals)"
fi
echo ""
```

## MONITOR AND WAIT

Monitor PR until merged:

```bash
echo "⏳ Monitoring PR #$PR_NUMBER for merge..."
echo ""

# Use monitoring script
.claude/scripts/monitor-pr-merge.sh "$PR_NUMBER" 300
MERGE_STATUS=$?

if [[ $MERGE_STATUS -eq 0 ]]; then
    echo ""
    echo "✓ PR #$PR_NUMBER has been merged!"
    PR_MERGED="true"
elif [[ $MERGE_STATUS -eq 2 ]]; then
    echo ""
    echo "⏱ Timeout reached - PR not merged yet"
    echo ""
    echo "You can:"
    echo "  1. Check status: gh pr view $PR_NUMBER --web"
    echo "  2. Merge manually: gh pr merge $PR_NUMBER --squash"
    echo "  3. After merge, run: /hansolo:sync"
    PR_MERGED="false"
else
    echo ""
    echo "❌ PR monitoring failed"
    PR_MERGED="false"
fi
echo ""
```

## POST-FLIGHT: SYNC AND CLEANUP

Verify outcomes and clean up if PR was merged:

```bash
echo "🔄 POST-FLIGHT: Finalizing..."
echo ""

if [[ "$PR_MERGED" == "true" ]]; then
    echo "  Syncing repository after merge..."

    # Perform sync to cleanup merged branch
    SYNC_JSON=$(perform_sync "true")
    SYNC_MODE=$(echo "$SYNC_JSON" | jq -r '.data.sync_mode // ""')
    CLEANUP_DONE=$(echo "$SYNC_JSON" | jq -r '.data.cleanup_performed // false')
    CURRENT_BRANCH=$(echo "$SYNC_JSON" | jq -r '.data.current_branch // ""')

    if [[ "$CLEANUP_DONE" == "true" ]]; then
        echo "  ✓ Feature branch cleaned up"
        echo "  ✓ Switched to: $CURRENT_BRANCH"
    else
        echo "  ✓ Sync complete (mode: $SYNC_MODE)"
    fi

    # Final validation
    if [[ "$CURRENT_BRANCH" == "main" ]] || [[ "$CURRENT_BRANCH" == "master" ]]; then
        echo ""
        echo "✅ POST-FLIGHT: Ship complete!"
        echo "  • PR created and merged"
        echo "  • Branch cleaned up"
        echo "  • On main with latest changes"
        echo "  • Ready for next feature"
    else
        echo ""
        echo "⚠️  POST-FLIGHT: Ship complete with warnings"
        echo "  • PR created and merged"
        echo "  • Still on feature branch: $CURRENT_BRANCH"
        echo "  • Run /hansolo:sync to complete cleanup"
    fi
else
    # PR not merged yet
    echo "  PR created but not yet merged"
    echo ""
    echo "✓ POST-FLIGHT: Partial ship complete"
    echo "  • PR #$PR_NUMBER created successfully"
    echo "  • Monitor or merge manually"
    echo "  • Run /hansolo:sync after merge"
fi
```

## Summary

The ship command follows the three-phase pattern:

1. **PRE-FLIGHT**:
   - ✓ Validates branch state
   - ✓ Creates feature branch if needed
   - ✓ Checks for existing PRs

2. **EXECUTION**:
   - ✓ Creates actual pull request
   - ✓ Enables auto-merge if possible
   - ✓ Monitors until merged (with timeout)

3. **POST-FLIGHT**:
   - ✓ Syncs repository after merge
   - ✓ Cleans up feature branch
   - ✓ Validates final state

All operations use real shell scripts, not agent simulations!