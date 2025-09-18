#!/bin/bash
# han-solo squash commits hook
# Consolidates checkpoint commits into atomic commits when task completes

set -euo pipefail
IFS=$'\n\t'

# Read JSON from stdin
json_input=$(cat)
session_id=$(echo "$json_input" | jq -r '.session_id // "unknown"')

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    exit 0
fi

# Check if squashing is disabled
if [ "${HANSOLO_SQUASH_DISABLED:-}" == "true" ]; then
    exit 0
fi

# Get current branch
current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

# Don't squash on main/master
if [[ "$current_branch" == "main" ]] || [[ "$current_branch" == "master" ]]; then
    exit 0
fi

# Find checkpoint commits since diverging from main
merge_base=$(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main 2>/dev/null || echo "")

if [ -z "$merge_base" ]; then
    echo "han-solo: Unable to find merge base with main branch" >&2
    exit 0
fi

# Count checkpoint commits
checkpoint_count=$(git log --oneline "$merge_base..HEAD" --grep="^checkpoint: \[han-solo\]" 2>/dev/null | wc -l)

if [ "$checkpoint_count" -eq 0 ]; then
    exit 0
fi

echo "han-solo: Found $checkpoint_count checkpoint commits to squash" >&2

# Get list of modified files
files_changed=$(git diff --name-only "$merge_base..HEAD" | sort | uniq)
file_count=$(echo "$files_changed" | wc -l)

# Generate atomic commit message
commit_type="feat"
if echo "$files_changed" | grep -q "^test"; then
    commit_type="test"
elif echo "$files_changed" | grep -q "^docs"; then
    commit_type="docs"
elif echo "$files_changed" | grep -q "fix"; then
    commit_type="fix"
fi

# Create descriptive message
scope=$(echo "$current_branch" | sed 's/feature\///' | sed 's/[-_]/ /g')
commit_msg="$commit_type: implement $scope

Changes made:
$(echo "$files_changed" | head -10 | sed 's/^/- /')

Session: $session_id
Files modified: $file_count
Checkpoints squashed: $checkpoint_count"

# Perform soft reset to merge-base
git reset --soft "$merge_base" 2>/dev/null

# Create single atomic commit
git commit -m "$commit_msg" --no-verify >/dev/null 2>&1

echo "han-solo: ✅ Squashed $checkpoint_count checkpoints into atomic commit" >&2
echo "han-solo: Commit message: $commit_type: implement $scope" >&2

exit 0