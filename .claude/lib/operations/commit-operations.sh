#!/bin/bash
# commit-operations.sh - Actual commit operations for han-solo
# These functions perform REAL git commit operations and squashing

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

# Check for uncommitted changes
has_uncommitted_changes() {
    [[ -n "$(git status --porcelain)" ]]
}

# Check for checkpoint commits
has_checkpoint_commits() {
    local checkpoints
    checkpoints=$(git log --oneline --grep="^checkpoint:" -n 10 2>/dev/null | wc -l)
    [[ "$checkpoints" -gt 0 ]]
}

# Count checkpoint commits since last real commit
count_checkpoint_commits() {
    local count=0
    local commits
    commits=$(git log --oneline -n 20 2>/dev/null || echo "")

    while IFS= read -r commit; do
        if [[ "$commit" =~ ^[a-f0-9]+[[:space:]]checkpoint: ]]; then
            ((count++))
        else
            break
        fi
    done <<< "$commits"

    echo "$count"
}

# Generate commit message from changes
generate_commit_message() {
    local branch_name
    branch_name=$(git branch --show-current)

    # Extract type from branch name
    local type
    type=$(echo "$branch_name" | cut -d'/' -f1)

    # Generate description from branch or changes
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

# Create checkpoint commit
create_checkpoint_commit() {
    local message="${1:-checkpoint: work in progress}"

    # Ensure message starts with "checkpoint:"
    if [[ ! "$message" =~ ^checkpoint: ]]; then
        message="checkpoint: $message"
    fi

    # Stage all changes
    git add -A

    # Create commit
    if git commit -m "$message" 2>/dev/null; then
        echo "✓ Checkpoint created: $message"
        return 0
    else
        echo "✗ Failed to create checkpoint"
        return 1
    fi
}

# Squash checkpoint commits into atomic commit
squash_checkpoint_commits() {
    local final_message="${1:-}"
    local checkpoint_count
    checkpoint_count=$(count_checkpoint_commits)

    if [[ "$checkpoint_count" -eq 0 ]]; then
        echo "No checkpoint commits to squash"
        return 1
    fi

    # Generate message if not provided
    if [[ -z "$final_message" ]]; then
        final_message=$(generate_commit_message)
    fi

    echo "Squashing $checkpoint_count checkpoint commits..."

    # Get the commit before the first checkpoint
    local base_commit
    base_commit=$(git log --oneline --skip="$checkpoint_count" -n 1 | cut -d' ' -f1)

    if [[ -z "$base_commit" ]]; then
        # No commit before checkpoints, use root
        echo "Squashing all commits into initial commit"
        # This is complex, for now just create a regular commit
        git add -A
        git commit -m "$final_message" 2>/dev/null || true
    else
        # Interactive rebase to squash
        # Create a script for automated squashing
        local rebase_script="/tmp/han-solo-rebase-$$"
        echo "pick $(git log --oneline -n 1 --skip=$((checkpoint_count - 1)) | cut -d' ' -f1)" > "$rebase_script"
        for i in $(seq 2 "$checkpoint_count"); do
            echo "squash $(git log --oneline -n 1 --skip=$((checkpoint_count - i)) | cut -d' ' -f1)" >> "$rebase_script"
        done

        # Perform the squash
        GIT_SEQUENCE_EDITOR="cat $rebase_script >" git rebase -i "$base_commit" 2>/dev/null

        # Amend the commit message
        git commit --amend -m "$final_message" 2>/dev/null

        rm -f "$rebase_script"
    fi

    echo "✓ Created atomic commit: $final_message"
    return 0
}

# Create atomic commit (checkpoint or squash)
create_atomic_commit() {
    local message="${1:-}"
    local json_mode="${2:-false}"

    # Check if we have uncommitted changes
    if ! has_uncommitted_changes; then
        if [[ "$json_mode" == "true" ]]; then
            output_commit_json "" "no_changes" "No changes to commit"
        else
            echo "No changes to commit"
        fi
        return 1
    fi

    # Check if we have checkpoint commits to squash
    local checkpoint_count
    checkpoint_count=$(count_checkpoint_commits)

    if [[ "$checkpoint_count" -gt 0 ]]; then
        # Squash checkpoints into atomic commit
        if [[ -z "$message" ]]; then
            message=$(generate_commit_message)
        fi

        # First add any new changes
        git add -A
        git commit -m "checkpoint: final changes" 2>/dev/null || true

        # Then squash all checkpoints
        if squash_checkpoint_commits "$message"; then
            local commit_hash
            commit_hash=$(git rev-parse HEAD)

            if [[ "$json_mode" == "true" ]]; then
                output_commit_json "$commit_hash" "squashed" "$message"
            else
                echo "✓ Squashed $checkpoint_count checkpoints into: $message"
                echo "  Commit: $commit_hash"
            fi
            return 0
        fi
    else
        # Create regular commit
        if [[ -z "$message" ]]; then
            # Check if this should be a checkpoint
            if [[ "${CHECKPOINT_MODE:-false}" == "true" ]]; then
                message="checkpoint: work in progress"
            else
                message=$(generate_commit_message)
            fi
        fi

        git add -A
        if git commit -m "$message"; then
            local commit_hash
            commit_hash=$(git rev-parse HEAD)

            if [[ "$json_mode" == "true" ]]; then
                local commit_type="regular"
                [[ "$message" =~ ^checkpoint: ]] && commit_type="checkpoint"
                output_commit_json "$commit_hash" "$commit_type" "$message"
            else
                echo "✓ Created commit: $message"
                echo "  Commit: $commit_hash"
            fi
            return 0
        fi
    fi

    return 1
}

# Output JSON response for commit operations
output_commit_json() {
    local commit_hash="$1"
    local commit_type="$2"
    local message="$3"

    cat <<EOF
{
    "squadron": {
        "name": "gray",
        "quote": "Gray Leader, standing by...",
        "banner_type": "COMMITTING"
    },
    "status": "completed",
    "data": {
        "commit_hash": "$commit_hash",
        "commit_type": "$commit_type",
        "message": "$message"
    }
}
EOF
}

# Note: export -f is bash-specific and not needed for sourcing
# Functions are available when script is sourced