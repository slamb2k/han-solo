#!/bin/bash
# pr-health status line - Shows PR status and CI health
# Refresh interval: 15 seconds

# Colors and symbols
GREEN='✅'
YELLOW='⚠️'
RED='❌'
BLUE='🔵'
PR='🎯'
CHECK='✓'
CROSS='✗'
REVIEW='👀'
MERGE='🔀'
CLOCK='⏳'
FOLDER='📁'

# Get current directory
CURRENT_DIR=$(basename "$(pwd)")

# Get current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

if [ -z "$BRANCH" ]; then
  echo "${FOLDER} ${CURRENT_DIR} - Not a git repo"
  exit 0
fi

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
  echo "${PR} ${CURRENT_DIR} - No GitHub CLI"
  exit 0
fi

# Format branch for display
if [ ${#BRANCH} -gt 12 ]; then
  BRANCH_DISPLAY="${BRANCH:0:10}..."
else
  BRANCH_DISPLAY="$BRANCH"
fi

# Check for PR
PR_JSON=$(gh pr view --json number,state,mergeable,statusCheckRollup,reviews,isDraft 2>/dev/null || echo "")

if [ -z "$PR_JSON" ]; then
  # No PR exists
  echo "${PR} ${CURRENT_DIR}/${BRANCH_DISPLAY} - No PR"
  exit 0
fi

# Parse PR data
PR_NUM=$(echo "$PR_JSON" | jq -r '.number')
PR_STATE=$(echo "$PR_JSON" | jq -r '.state')
MERGEABLE=$(echo "$PR_JSON" | jq -r '.mergeable')
IS_DRAFT=$(echo "$PR_JSON" | jq -r '.isDraft')

# Check status
CHECK_STATUS=$(echo "$PR_JSON" | jq -r '.statusCheckRollup[]?.conclusion // "PENDING"' | head -1)
CHECK_COUNT=$(echo "$PR_JSON" | jq '.statusCheckRollup | length')

# Count check states
PASSING=$(echo "$PR_JSON" | jq '[.statusCheckRollup[]? | select(.conclusion=="SUCCESS")] | length')
FAILING=$(echo "$PR_JSON" | jq '[.statusCheckRollup[]? | select(.conclusion=="FAILURE")] | length')
PENDING=$(echo "$PR_JSON" | jq '[.statusCheckRollup[]? | select(.conclusion==null or .conclusion=="PENDING")] | length')

# Review status
APPROVED=$(echo "$PR_JSON" | jq '[.reviews[]? | select(.state=="APPROVED")] | length')
CHANGES_REQ=$(echo "$PR_JSON" | jq '[.reviews[]? | select(.state=="CHANGES_REQUESTED")] | length')

# Build check status indicator
if [ "$FAILING" -gt 0 ]; then
  CHECK_INDICATOR="${RED}${FAILING}/${CHECK_COUNT}"
elif [ "$PENDING" -gt 0 ]; then
  CHECK_INDICATOR="${CLOCK}${PASSING}/${CHECK_COUNT}"
elif [ "$PASSING" -eq "$CHECK_COUNT" ] && [ "$CHECK_COUNT" -gt 0 ]; then
  CHECK_INDICATOR="${GREEN}${CHECK_COUNT}/${CHECK_COUNT}"
else
  CHECK_INDICATOR="⏸️"
fi

# Build review indicator
REVIEW_INDICATOR=""
if [ "$CHANGES_REQ" -gt 0 ]; then
  REVIEW_INDICATOR=" ${RED}CR"
elif [ "$APPROVED" -gt 0 ]; then
  REVIEW_INDICATOR=" ${GREEN}+${APPROVED}"
fi

# Build merge status
MERGE_STATUS=""
if [ "$IS_DRAFT" = "true" ]; then
  MERGE_STATUS=" 📝Draft"
elif [ "$MERGEABLE" = "MERGEABLE" ]; then
  if [ "$FAILING" -eq 0 ] && [ "$PENDING" -eq 0 ] && [ "$CHECK_COUNT" -gt 0 ]; then
    MERGE_STATUS=" ${GREEN}Ready"
  else
    MERGE_STATUS=" ${BLUE}→"
  fi
elif [ "$MERGEABLE" = "CONFLICTING" ]; then
  MERGE_STATUS=" ${RED}Conflict!"
fi

# Build final status line
echo "${PR} ${CURRENT_DIR}/PR#${PR_NUM} ${CHECK_INDICATOR}${REVIEW_INDICATOR}${MERGE_STATUS}"