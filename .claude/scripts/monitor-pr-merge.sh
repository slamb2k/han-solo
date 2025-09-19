#!/bin/bash
# monitor-pr-merge.sh - Monitor a pull request until it's merged
# Usage: monitor-pr-merge.sh <pr-number> [timeout-seconds]
# Exit codes: 0=merged, 1=error, 2=timeout

set -e

# Configuration
PR_NUMBER="$1"
TIMEOUT="${2:-300}"  # Default 5 minutes
POLL_INTERVAL=10     # Check every 10 seconds
ELAPSED=0

# Validate input
if [[ -z "$PR_NUMBER" ]]; then
    echo "Error: PR number required"
    echo "Usage: $0 <pr-number> [timeout-seconds]"
    exit 1
fi

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🔄 Monitoring PR #$PR_NUMBER for merge completion..."
echo "   Timeout: ${TIMEOUT} seconds"
echo ""

# Function to check PR status
check_pr_status() {
    gh pr view "$PR_NUMBER" --json state,mergeable,mergeStateStatus 2>/dev/null || echo '{"error":"not found"}'
}

# Function to show progress
show_progress() {
    local dots=$((ELAPSED / 10 % 4))
    case $dots in
        0) printf "\r⏳ Waiting for merge.   " ;;
        1) printf "\r⏳ Waiting for merge..  " ;;
        2) printf "\r⏳ Waiting for merge... " ;;
        3) printf "\r⏳ Waiting for merge...." ;;
    esac
}

# Main monitoring loop
while [[ $ELAPSED -lt $TIMEOUT ]]; do
    # Get PR status
    PR_JSON=$(check_pr_status)

    # Check for errors
    if echo "$PR_JSON" | grep -q '"error"'; then
        echo -e "\n${RED}✗ Error: Could not find PR #$PR_NUMBER${NC}"
        exit 1
    fi

    # Parse status
    STATE=$(echo "$PR_JSON" | jq -r '.state')
    MERGEABLE=$(echo "$PR_JSON" | jq -r '.mergeable')
    MERGE_STATUS=$(echo "$PR_JSON" | jq -r '.mergeStateStatus')

    # Check if merged
    if [[ "$STATE" == "MERGED" ]]; then
        echo -e "\n${GREEN}✓ PR #$PR_NUMBER has been successfully merged!${NC}"
        exit 0
    fi

    # Check if closed without merging
    if [[ "$STATE" == "CLOSED" ]]; then
        echo -e "\n${RED}✗ PR #$PR_NUMBER was closed without merging${NC}"
        exit 1
    fi

    # Show current status on first iteration and every 30 seconds
    if [[ $ELAPSED -eq 0 ]] || [[ $((ELAPSED % 30)) -eq 0 ]]; then
        echo -e "\n📊 Status Check:"
        echo "   State: $STATE"
        echo "   Mergeable: $MERGEABLE"
        echo "   Merge Status: $MERGE_STATUS"

        # Provide helpful context based on status
        case "$MERGE_STATUS" in
            "BLOCKED")
                echo -e "   ${YELLOW}⚠ Waiting for CI checks to complete...${NC}"
                ;;
            "BEHIND")
                echo -e "   ${YELLOW}⚠ Branch is behind main, may need update${NC}"
                ;;
            "UNSTABLE")
                echo -e "   ${YELLOW}⚠ Some checks are failing${NC}"
                ;;
            "CLEAN")
                echo -e "   ${GREEN}✓ Ready to merge (waiting for auto-merge)${NC}"
                ;;
        esac
        echo ""
    fi

    # Show progress indicator
    show_progress

    # Wait before next check
    sleep $POLL_INTERVAL
    ELAPSED=$((ELAPSED + POLL_INTERVAL))
done

# Timeout reached
echo -e "\n${YELLOW}⏱ Timeout reached after ${TIMEOUT} seconds${NC}"
echo ""
echo "The PR has not been merged yet. You can:"
echo "1. Check the PR status: gh pr view $PR_NUMBER --web"
echo "2. Merge manually if ready: gh pr merge $PR_NUMBER --squash"
echo "3. Continue monitoring: $0 $PR_NUMBER $TIMEOUT"
echo ""

exit 2