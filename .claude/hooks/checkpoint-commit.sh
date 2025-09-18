#!/bin/bash
# han-solo checkpoint commit hook
# Creates granular commits after file modifications

set -euo pipefail
IFS=$'\n\t'

# Read JSON from stdin
json_input=$(cat)
tool_name=$(echo "$json_input" | jq -r '.tool_name // "unknown"')

# Only process file modification tools
if [[ "$tool_name" != "Write" ]] && [[ "$tool_name" != "Edit" ]] && [[ "$tool_name" != "MultiEdit" ]]; then
    exit 0
fi

# Get modified files
files_modified=$(echo "$json_input" | jq -r '.tool_result.files_modified[]? // .tool_input.file_path // "unknown"' 2>/dev/null)

if [ -z "$files_modified" ] || [ "$files_modified" == "unknown" ]; then
    exit 0
fi

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    exit 0
fi

# Check if hansolo checkpoint mode is enabled (default: enabled)
if [ "${HANSOLO_CHECKPOINT_DISABLED:-}" == "true" ]; then
    exit 0
fi

# Create checkpoint commit for each modified file
for file in $files_modified; do
    if [ -f "$file" ]; then
        # Add the file to staging
        git add "$file" 2>/dev/null || continue

        # Create checkpoint commit
        timestamp=$(date '+%Y%m%d-%H%M%S')
        filename=$(basename "$file")
        commit_msg="checkpoint: [han-solo] modify $filename - $timestamp"

        # Commit only if there are changes
        if ! git diff --cached --quiet 2>/dev/null; then
            git commit -m "$commit_msg" --no-verify >/dev/null 2>&1 || true
            echo "han-solo: 📝 Checkpoint created for $filename" >&2
        fi
    fi
done

exit 0