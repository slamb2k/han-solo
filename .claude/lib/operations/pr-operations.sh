#!/bin/bash
# pr-operations.sh - Actual PR operations for han-solo
# These functions perform REAL gh commands and return REAL results

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

# Create a pull request
create_pr() {
    local title="$1"
    local body="$2"
    local base="${3:-main}"
    local issue="${4:-}"

    # Add issue linking if provided
    if [[ -n "$issue" ]]; then
        body="$body

Closes #$issue"
    fi

    # Add Claude Code attribution
    body="$body

🤖 Generated with [Claude Code](https://claude.ai/code)"

    # Create the PR
    local pr_url
    pr_url=$(gh pr create --title "$title" --body "$body" --base "$base" 2>&1)

    if [[ $? -eq 0 ]]; then
        echo "$pr_url"
        return 0
    else
        echo "Failed to create PR: $pr_url" >&2
        return 1
    fi
}

# Enable auto-merge for a PR
enable_auto_merge() {
    local pr_number="$1"

    # Try to enable auto-merge
    if gh pr merge "$pr_number" --auto --squash --delete-branch 2>/dev/null; then
        echo "enabled"
        return 0
    else
        echo "disabled"
        return 1
    fi
}

# Get PR details
get_pr_details() {
    local pr_number="$1"

    gh pr view "$pr_number" --json number,url,state,title
}

# Generate PR title from branch and changes
generate_pr_title() {
    local branch_name
    branch_name=$(git branch --show-current)

    # Extract type and description from branch name
    local type
    type=$(echo "$branch_name" | cut -d'/' -f1)
    local description
    description=$(echo "$branch_name" | cut -d'/' -f2- | tr '-' ' ')

    # Map branch type to conventional commit type
    case "$type" in
        feat) echo "feat: $description" ;;
        fix) echo "fix: $description" ;;
        docs) echo "docs: $description" ;;
        chore) echo "chore: $description" ;;
        refactor) echo "refactor: $description" ;;
        test) echo "test: $description" ;;
        perf) echo "perf: $description" ;;
        style) echo "style: $description" ;;
        *) echo "feat: $description" ;;
    esac
}

# Generate PR body from changes
generate_pr_body() {
    local branch_name
    branch_name=$(git branch --show-current)

    # Get commit messages
    local commits
    commits=$(git log origin/main..HEAD --oneline 2>/dev/null || echo "")

    # Get changed files summary
    local changes
    changes=$(git diff origin/main...HEAD --stat 2>/dev/null | tail -1 || echo "")

    # Build PR body
    cat <<EOF
## Summary
This PR implements changes from branch \`$branch_name\`.

## Changes Made
EOF

    # Add commit list if any
    if [[ -n "$commits" ]]; then
        echo ""
        echo "### Commits"
        echo "\`\`\`"
        echo "$commits"
        echo "\`\`\`"
    fi

    # Add change summary
    if [[ -n "$changes" ]]; then
        echo ""
        echo "### Files Changed"
        echo "$changes"
    fi

    echo ""
    echo "## Testing"
    echo "- [ ] Tests pass locally"
    echo "- [ ] No linting errors"
    echo "- [ ] Changes reviewed"
}

# Output JSON response for PR creation
output_pr_json() {
    local pr_number="$1"
    local pr_url="$2"
    local auto_merge_status="$3"

    cat <<EOF
{
    "squadron": {
        "name": "red",
        "quote": "Red Leader, standing by...",
        "banner_type": "SHIPPING"
    },
    "status": "completed",
    "data": {
        "pr_number": $pr_number,
        "pr_url": "$pr_url",
        "auto_merge_enabled": $([ "$auto_merge_status" == "enabled" ] && echo "true" || echo "false")
    }
}
EOF
}

# Main function for PR creation workflow
create_pull_request() {
    local title="${1:-}"
    local body="${2:-}"
    local issue="${3:-}"
    local json_mode="${4:-false}"

    # Generate title if not provided
    if [[ -z "$title" ]]; then
        title=$(generate_pr_title)
    fi

    # Generate body if not provided
    if [[ -z "$body" ]]; then
        body=$(generate_pr_body)
    fi

    # Create the PR
    local pr_url
    pr_url=$(create_pr "$title" "$body" "main" "$issue")

    if [[ $? -ne 0 ]]; then
        if [[ "$json_mode" == "true" ]]; then
            cat <<EOF
{
    "squadron": {
        "name": "red",
        "quote": "Red Leader, standing by...",
        "banner_type": "SHIPPING"
    },
    "status": "error",
    "error": {
        "code": "PR_CREATION_FAILED",
        "message": "Failed to create pull request"
    }
}
EOF
        else
            echo "Failed to create PR" >&2
        fi
        return 1
    fi

    # Extract PR number from URL
    local pr_number
    pr_number=$(echo "$pr_url" | grep -oE '[0-9]+$')

    # Try to enable auto-merge
    local auto_merge_status
    auto_merge_status=$(enable_auto_merge "$pr_number")

    # Output result
    if [[ "$json_mode" == "true" ]]; then
        output_pr_json "$pr_number" "$pr_url" "$auto_merge_status"
    else
        echo "✓ PR #$pr_number created: $pr_url"
        echo "Auto-merge: $auto_merge_status"
    fi

    return 0
}

# Note: export -f is bash-specific and not needed for sourcing
# Functions are available when script is sourced