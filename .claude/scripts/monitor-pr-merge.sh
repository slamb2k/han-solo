#!/bin/bash
set -euo pipefail

# PR Merge Monitoring Script
# Monitors a PR until it's merged or timeout occurs
# Used by Blue Squadron for complete shipping workflow

# Get PR number from argument
PR_NUMBER="${1:-}"
if [[ -z "$PR_NUMBER" ]]; then
    echo "ERROR: PR number required" >&2
    echo "Usage: $0 <pr-number>" >&2
    exit 1
fi

# Configuration
MAX_WAIT_TIME=600  # 10 minutes max wait
CHECK_INTERVAL=10   # Check every 10 seconds
ELAPSED_TIME=0

echo "Monitoring PR #$PR_NUMBER for merge completion..."

# Function to check PR status
check_pr_status() {
    local pr_data=$(gh pr view "$PR_NUMBER" --json state,mergeable,mergeStateStatus,statusCheckRollup 2>/dev/null || echo "{}")

    if [[ "$pr_data" == "{}" ]]; then
        echo "ERROR: Could not fetch PR data" >&2
        return 1
    fi

    local state=$(echo "$pr_data" | jq -r '.state')
    local mergeable=$(echo "$pr_data" | jq -r '.mergeable')
    local merge_state=$(echo "$pr_data" | jq -r '.mergeStateStatus')

    echo "$state|$mergeable|$merge_state"
}

# Function to check CI status
check_ci_status() {
    local checks=$(gh pr checks "$PR_NUMBER" --json name,status,conclusion 2>/dev/null || echo "[]")

    if [[ "$checks" == "[]" ]]; then
        echo "NO_CHECKS"
        return
    fi

    local failed=$(echo "$checks" | jq '[.[] | select(.conclusion == "FAILURE")] | length')
    local pending=$(echo "$checks" | jq '[.[] | select(.status != "COMPLETED")] | length')
    local success=$(echo "$checks" | jq '[.[] | select(.conclusion == "SUCCESS")] | length')

    if [[ "$failed" -gt 0 ]]; then
        echo "FAILED"
    elif [[ "$pending" -gt 0 ]]; then
        echo "PENDING"
    elif [[ "$success" -gt 0 ]]; then
        echo "SUCCESS"
    else
        echo "UNKNOWN"
    fi
}

# Function to enable auto-merge
enable_auto_merge() {
    echo "Enabling auto-merge for PR #$PR_NUMBER..."

    if gh pr merge "$PR_NUMBER" --auto --squash --delete-branch 2>/dev/null; then
        echo "✓ Auto-merge enabled"
        return 0
    else
        echo "⚠️ Could not enable auto-merge, will monitor for manual merge"
        return 1
    fi
}

# Initial status check
INITIAL_STATUS=$(check_pr_status)
IFS='|' read -r STATE MERGEABLE MERGE_STATE <<< "$INITIAL_STATUS"

echo "Initial PR state: $STATE"
echo "Mergeable: $MERGEABLE"
echo "Merge state: $MERGE_STATE"

# If PR is already merged, we're done
if [[ "$STATE" == "MERGED" ]]; then
    echo "✓ PR #$PR_NUMBER is already merged!"
    exit 0
fi

# If PR is closed (not merged), exit with error
if [[ "$STATE" == "CLOSED" ]]; then
    echo "✗ PR #$PR_NUMBER is closed without merging"
    exit 1
fi

# Try to enable auto-merge
AUTO_MERGE_ENABLED=false
if enable_auto_merge; then
    AUTO_MERGE_ENABLED=true
fi

# Monitor loop
echo ""
echo "Monitoring PR merge status..."
echo "Maximum wait time: ${MAX_WAIT_TIME}s"
echo ""

while [[ $ELAPSED_TIME -lt $MAX_WAIT_TIME ]]; do
    # Check current status
    CURRENT_STATUS=$(check_pr_status)
    IFS='|' read -r STATE MERGEABLE MERGE_STATE <<< "$CURRENT_STATUS"

    # Check if merged
    if [[ "$STATE" == "MERGED" ]]; then
        echo ""
        echo "✓ PR #$PR_NUMBER has been merged!"

        # Get merge details
        MERGE_INFO=$(gh pr view "$PR_NUMBER" --json mergedAt,mergedBy --jq '"\(.mergedAt) by \(.mergedBy.login)"')
        echo "Merged at: $MERGE_INFO"

        exit 0
    fi

    # Check if closed
    if [[ "$STATE" == "CLOSED" ]]; then
        echo ""
        echo "✗ PR #$PR_NUMBER was closed without merging"
        exit 1
    fi

    # Check CI status
    CI_STATUS=$(check_ci_status)

    # Display progress
    printf "\r[%3d/%3d s] State: %-6s | CI: %-8s | Mergeable: %-8s | Auto-merge: %-8s" \
        "$ELAPSED_TIME" "$MAX_WAIT_TIME" "$STATE" "$CI_STATUS" "$MERGEABLE" \
        "$([ "$AUTO_MERGE_ENABLED" = true ] && echo "ENABLED" || echo "DISABLED")"

    # If CI failed, exit
    if [[ "$CI_STATUS" == "FAILED" ]]; then
        echo ""
        echo "✗ CI checks failed for PR #$PR_NUMBER"
        echo "View details: gh pr checks $PR_NUMBER"
        exit 1
    fi

    # If mergeable and CI passed, but auto-merge not enabled, try manual merge
    if [[ "$CI_STATUS" == "SUCCESS" ]] && [[ "$MERGEABLE" == "MERGEABLE" ]] && [[ "$AUTO_MERGE_ENABLED" == "false" ]]; then
        echo ""
        echo "CI passed and PR is mergeable. Attempting manual merge..."

        if gh pr merge "$PR_NUMBER" --squash --delete-branch; then
            echo "✓ PR #$PR_NUMBER has been merged!"
            exit 0
        else
            echo "⚠️ Manual merge failed, continuing to monitor..."
        fi
    fi

    # Wait before next check
    sleep $CHECK_INTERVAL
    ELAPSED_TIME=$((ELAPSED_TIME + CHECK_INTERVAL))
done

# Timeout reached
echo ""
echo "⚠️ Timeout reached after ${MAX_WAIT_TIME}s"
echo "PR #$PR_NUMBER is still not merged"
echo ""
echo "Current status:"
echo "  State: $STATE"
echo "  CI Status: $(check_ci_status)"
echo "  Mergeable: $MERGEABLE"
echo ""
echo "You can:"
echo "  1. Check PR manually: gh pr view $PR_NUMBER --web"
echo "  2. Merge manually: gh pr merge $PR_NUMBER --squash"
echo "  3. Continue monitoring: $0 $PR_NUMBER"

exit 2  # Exit code 2 for timeout