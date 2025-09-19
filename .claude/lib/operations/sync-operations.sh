#!/bin/bash
# sync-operations.sh - Actual sync operations for han-solo
# These functions perform REAL git sync operations and return REAL results

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

# Detect sync mode based on branch state
detect_sync_mode() {
    local current_branch
    current_branch=$(git branch --show-current)

    # If on main, just update
    if [[ "$current_branch" == "main" ]] || [[ "$current_branch" == "master" ]]; then
        echo "update"
        return 0
    fi

    # Check if branch has been merged to main
    local merge_base
    merge_base=$(git merge-base HEAD origin/main 2>/dev/null || echo "")

    if [[ -n "$merge_base" ]]; then
        # Check if this branch's commits are in main
        local branch_commits
        branch_commits=$(git rev-list --count "$merge_base"..HEAD 2>/dev/null || echo "0")

        if [[ "$branch_commits" == "0" ]]; then
            echo "cleanup"
        else
            # Check if PR was merged (look for squash commit in main)
            local pr_merged
            pr_merged=$(git log origin/main --grep="$current_branch" --oneline -1 2>/dev/null || echo "")

            if [[ -n "$pr_merged" ]]; then
                echo "cleanup"
            else
                echo "rebase"
            fi
        fi
    else
        echo "rebase"
    fi
}

# Perform cleanup for merged branches
cleanup_merged_branch() {
    local current_branch
    current_branch=$(git branch --show-current)

    if [[ "$current_branch" == "main" ]] || [[ "$current_branch" == "master" ]]; then
        echo "Already on main branch" >&2
        return 1
    fi

    echo "✓ Branch $current_branch has been merged. Performing cleanup..." >&2

    # Switch to main
    git switch main || git switch master

    # Pull latest
    git pull --ff-only origin main 2>/dev/null || git pull --ff-only origin master 2>/dev/null

    # Delete the old branch
    git branch -D "$current_branch" 2>/dev/null || true

    echo "✓ Cleanup complete! You're on updated main." >&2
    return 0
}

# Perform rebase for unmerged branches
rebase_on_main() {
    local current_branch
    current_branch=$(git branch --show-current)

    echo "Syncing branch $current_branch with main..." >&2

    # Fetch latest
    git fetch origin

    # Attempt rebase
    if git rebase origin/main; then
        echo "✓ Successfully rebased on main" >&2
        return 0
    else
        echo "✗ Rebase failed - conflicts need resolution" >&2
        return 1
    fi
}

# Update main branch
update_main() {
    echo "Updating main branch..." >&2

    # Pull latest
    if git pull --ff-only origin main 2>/dev/null || git pull --ff-only origin master 2>/dev/null; then
        echo "✓ Main branch updated" >&2
        return 0
    else
        echo "✗ Failed to update main" >&2
        return 1
    fi
}

# Output JSON response for sync operations
output_sync_json() {
    local sync_mode="$1"
    local current_branch="$2"
    local previous_branch="${3:-}"
    local cleanup_performed="${4:-false}"

    cat <<EOF
{
    "squadron": {
        "name": "gold",
        "quote": "Gold Leader, standing by...",
        "banner_type": "SYNCING"
    },
    "status": "completed",
    "data": {
        "sync_mode": "$sync_mode",
        "current_branch": "$current_branch",
        "previous_branch": "$previous_branch",
        "cleanup_performed": $cleanup_performed
    }
}
EOF
}

# Main sync workflow
perform_sync() {
    local json_mode="${1:-false}"
    local sync_mode
    local previous_branch
    local current_branch
    local cleanup_performed="false"

    # Get initial state
    previous_branch=$(git branch --show-current)

    # Detect sync mode
    sync_mode=$(detect_sync_mode)

    # Perform appropriate sync operation
    case "$sync_mode" in
        cleanup)
            if cleanup_merged_branch; then
                cleanup_performed="true"
                current_branch=$(git branch --show-current)
            else
                current_branch="$previous_branch"
            fi
            ;;
        rebase)
            if rebase_on_main; then
                current_branch="$previous_branch"
            else
                current_branch="$previous_branch"
                if [[ "$json_mode" == "true" ]]; then
                    cat <<EOF
{
    "squadron": {
        "name": "gold",
        "quote": "Gold Leader, standing by...",
        "banner_type": "SYNCING"
    },
    "status": "error",
    "error": {
        "code": "REBASE_CONFLICTS",
        "message": "Rebase failed due to conflicts"
    }
}
EOF
                    return 1
                fi
            fi
            ;;
        update)
            if update_main; then
                current_branch="$previous_branch"
            else
                current_branch="$previous_branch"
            fi
            ;;
    esac

    # Output result
    if [[ "$json_mode" == "true" ]]; then
        output_sync_json "$sync_mode" "$current_branch" "$previous_branch" "$cleanup_performed"
    else
        echo "Sync complete (mode: $sync_mode)"
    fi

    return 0
}

# Note: export -f is bash-specific and not needed for sourcing
# Functions are available when script is sourced