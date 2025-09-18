#!/bin/bash
set -euo pipefail

# Branch State Detection Script
# Used by ship command to determine if a new feature branch is needed

# Get current branch name
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")

# Initialize state variables
BRANCH_STATE="unknown"
PR_EXISTS=false
PR_STATE=""
PR_NUMBER=""
PR_URL=""
NEEDS_NEW_BRANCH=false
MESSAGE=""

# Check if we're on a protected branch
if [[ "$CURRENT_BRANCH" == "main" ]] || [[ "$CURRENT_BRANCH" == "master" ]]; then
    BRANCH_STATE="protected"
    NEEDS_NEW_BRANCH=true
    MESSAGE="You're on the $CURRENT_BRANCH branch. A feature branch is required to create a PR."
else
    # Check if PR exists for current branch
    PR_INFO=$(gh pr list --state all --head "$CURRENT_BRANCH" --json number,state,url --jq '.[0]' 2>/dev/null || echo "{}")

    if [[ "$PR_INFO" != "{}" ]] && [[ -n "$PR_INFO" ]]; then
        PR_EXISTS=true
        PR_NUMBER=$(echo "$PR_INFO" | jq -r '.number // ""')
        PR_STATE=$(echo "$PR_INFO" | jq -r '.state // ""')
        PR_URL=$(echo "$PR_INFO" | jq -r '.url // ""')

        case "$PR_STATE" in
            "OPEN")
                BRANCH_STATE="has_open_pr"
                MESSAGE="This branch already has an open PR: $PR_URL"
                ;;
            "MERGED")
                BRANCH_STATE="has_merged_pr"
                NEEDS_NEW_BRANCH=true
                MESSAGE="This branch's PR was already merged. You'll need a new feature branch for additional changes."
                ;;
            "CLOSED")
                BRANCH_STATE="has_closed_pr"
                MESSAGE="This branch had a PR that was closed without merging. You can create a new PR or start a fresh branch."
                ;;
        esac
    else
        # No PR exists for this branch
        BRANCH_STATE="ready"

        # Check if there are any commits to ship
        COMMITS_AHEAD=$(git rev-list --count origin/main..HEAD 2>/dev/null || echo "0")
        if [[ "$COMMITS_AHEAD" == "0" ]]; then
            BRANCH_STATE="no_changes"
            MESSAGE="No commits to ship. Make some changes first."
        else
            MESSAGE="Ready to create PR with $COMMITS_AHEAD commit(s)."
        fi
    fi
fi

# Check for uncommitted changes
UNCOMMITTED_CHANGES=false
if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
    UNCOMMITTED_CHANGES=true
fi

# Output JSON result
cat <<EOF | jq .
{
  "current_branch": "$CURRENT_BRANCH",
  "branch_state": "$BRANCH_STATE",
  "needs_new_branch": $NEEDS_NEW_BRANCH,
  "pr_exists": $PR_EXISTS,
  "pr_state": "$PR_STATE",
  "pr_number": "$PR_NUMBER",
  "pr_url": "$PR_URL",
  "uncommitted_changes": $UNCOMMITTED_CHANGES,
  "message": "$MESSAGE"
}
EOF