#!/bin/bash
# branch-operations.sh - Actual git branch operations for han-solo
# These functions perform REAL git commands and return REAL results

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

# Source JSON utilities if they exist
if [[ -f "$LIB_DIR/json-utils.sh" ]]; then
    source "$LIB_DIR/json-utils.sh"
fi

# Create and switch to a new branch
create_branch() {
    local branch_name="$1"
    local previous_branch

    # Get current branch before switching
    previous_branch=$(git branch --show-current)

    # Ensure we're on main and up to date
    if [[ "$previous_branch" != "main" ]] && [[ "$previous_branch" != "master" ]]; then
        git switch main || git switch master
    fi

    # Pull latest
    git pull --ff-only origin main 2>/dev/null || git pull --ff-only origin master 2>/dev/null || true

    # Create and switch to new branch
    git switch -c "$branch_name"

    # Verify we're on the new branch
    local current_branch
    current_branch=$(git branch --show-current)

    if [[ "$current_branch" == "$branch_name" ]]; then
        echo "✓ Successfully created and switched to branch: $branch_name" >&2
        return 0
    else
        echo "✗ Failed to create branch: $branch_name" >&2
        return 1
    fi
}

# Detect branch type from input
detect_branch_type() {
    local input="$1"
    local lower_input
    lower_input=$(echo "$input" | tr '[:upper:]' '[:lower:]')

    local type="feat"

    # Type detection based on keywords
    if [[ "$lower_input" =~ (bug|fix|patch|repair|correct|issue) ]]; then
        type="fix"
    elif [[ "$lower_input" =~ (doc|readme|comment|guide|documentation) ]]; then
        type="docs"
    elif [[ "$lower_input" =~ (chore|dependency|upgrade|maintenance) ]]; then
        type="chore"
    elif [[ "$lower_input" =~ (refactor|restructure|reorganize) ]]; then
        type="refactor"
    elif [[ "$lower_input" =~ (test|spec|testing) ]]; then
        type="test"
    elif [[ "$lower_input" =~ (perf|performance|speed|optimize) ]]; then
        type="perf"
    elif [[ "$lower_input" =~ (style|format|lint|prettier) ]]; then
        type="style"
    fi

    echo "$type"
}

# Process branch input (natural language or explicit)
process_branch_input() {
    local input="$1"
    local lower_input
    lower_input=$(echo "$input" | tr '[:upper:]' '[:lower:]')

    # Check if it's already a properly formatted branch name
    if [[ "$lower_input" =~ ^(feat|fix|docs|chore|refactor|test|perf|style)/[a-z0-9-]+$ ]]; then
        echo "$lower_input"
        return 0
    fi

    # Otherwise, generate from natural language
    local type
    type=$(detect_branch_type "$input")

    # Clean the name
    local clean_name
    clean_name=$(echo "$input" | \
        sed 's/[^a-zA-Z0-9]/-/g' | \
        sed 's/-\+/-/g' | \
        sed 's/^-\|-$//g' | \
        tr '[:upper:]' '[:lower:]' | \
        cut -c1-30)

    [[ -z "$clean_name" ]] && clean_name="update-$(date +%Y%m%d)"

    echo "${type}/${clean_name}"
}

# Auto-generate branch name from repository state
auto_generate_branch_name() {
    local branch_name=""

    # Priority 1: From uncommitted changes
    if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
        local changed
        changed=$(git status --porcelain | head -1 | awk '{print $2}' | xargs basename | cut -d. -f1)
        if [[ -n "$changed" ]]; then
            local type="feat"
            [[ "$changed" =~ test ]] && type="test"
            [[ "$changed" =~ (README|docs|md) ]] && type="docs"
            branch_name="${type}/${changed}-$(date +%Y%m%d)"
        fi
    fi

    # Priority 2: From unshipped commits
    if [[ -z "$branch_name" ]]; then
        local unshipped
        unshipped=$(git log origin/main..HEAD --oneline 2>/dev/null | head -1)
        if [[ -n "$unshipped" ]]; then
            local msg
            msg=$(echo "$unshipped" | cut -d' ' -f2-)
            local type="feat"
            [[ "$msg" =~ ^fix ]] && type="fix"
            [[ "$msg" =~ ^feat ]] && type="feat"
            [[ "$msg" =~ ^docs ]] && type="docs"
            local clean_msg
            clean_msg=$(echo "$msg" | sed 's/^[^:]*: //' | sed 's/[^a-zA-Z0-9-]/-/g' | cut -c1-30 | sed 's/-$//')
            branch_name="${type}/${clean_msg}"
        fi
    fi

    # Priority 3: Timestamp fallback
    if [[ -z "$branch_name" ]]; then
        branch_name="feat/auto-$(date +%Y%m%d-%H%M%S)"
    fi

    echo "$branch_name"
}

# Output JSON response for branch creation
output_branch_json() {
    local branch_name="$1"
    local previous_branch="$2"

    cat <<EOF
{
    "squadron": {
        "name": "gold",
        "quote": "Gold Leader, standing by...",
        "banner_type": "LAUNCHING"
    },
    "status": "completed",
    "data": {
        "branch_created": "$branch_name",
        "previous_branch": "$previous_branch",
        "branch_type": "$(echo "$branch_name" | cut -d'/' -f1)",
        "sync_status": "up_to_date"
    }
}
EOF
}

# Main function for branch creation workflow
create_feature_branch() {
    local input="${1:-}"
    local json_mode="${2:-false}"
    local branch_name=""
    local previous_branch

    # Get current branch
    previous_branch=$(git branch --show-current)

    # Determine branch name
    if [[ -z "$input" ]] || [[ "$input" == "*" ]]; then
        # Auto-generate
        branch_name=$(auto_generate_branch_name)
    else
        # Process input
        branch_name=$(process_branch_input "$input")
    fi

    # Create the branch
    if create_branch "$branch_name"; then
        if [[ "$json_mode" == "true" ]]; then
            output_branch_json "$branch_name" "$previous_branch"
        else
            echo "Branch created: $branch_name"
        fi
        return 0
    else
        if [[ "$json_mode" == "true" ]]; then
            cat <<EOF
{
    "squadron": {
        "name": "gold",
        "quote": "Gold Leader, standing by...",
        "banner_type": "LAUNCHING"
    },
    "status": "error",
    "error": {
        "code": "BRANCH_CREATION_FAILED",
        "message": "Failed to create branch: $branch_name"
    }
}
EOF
        else
            echo "Failed to create branch: $branch_name" >&2
        fi
        return 1
    fi
}

# Note: export -f is bash-specific and not needed for sourcing
# Functions are available when script is sourced