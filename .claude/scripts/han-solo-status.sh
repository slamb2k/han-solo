#!/bin/bash
# han-solo status line script
# Displays project and workflow status

set -euo pipefail
IFS=$'\n\t'

# Read JSON input from Claude Code
input=$(cat)
project_dir=$(echo "$input" | jq -r '.project_dir // "."')
model=$(echo "$input" | jq -r '.model // "unknown"')
context_remaining=$(echo "$input" | jq -r '.context_remaining // 1.0')

# Navigate to project directory
cd "$project_dir" 2>/dev/null || cd .

# Get project name
project_name=$(basename "$PWD")

# Get Git status
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch=$(git branch --show-current 2>/dev/null || echo "unknown")

    # Check if branch is main/master
    if [[ "$branch" == "main" ]] || [[ "$branch" == "master" ]]; then
        branch_icon="⚠️"
        branch_msg="On main, use /hansolo:launch"
    else
        branch_icon="🌿"
        branch_msg="$branch"
    fi

    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        git_status="*modified"
    else
        git_status="clean"
    fi
else
    branch_icon="❌"
    branch_msg="Not a git repo"
    git_status=""
fi

# Check for active PR
pr_info=""
if command -v gh >/dev/null 2>&1; then
    pr_data=$(gh pr view --json number,state 2>/dev/null || echo "{}")
    pr_number=$(echo "$pr_data" | jq -r '.number // ""')
    if [ -n "$pr_number" ]; then
        pr_info=" | PR #$pr_number"
    fi
fi

# Calculate context usage
context_percent=$(echo "$context_remaining * 100" | bc -l 2>/dev/null | cut -d'.' -f1 || echo "100")

# Build status line
echo -n "📁 $project_name | $branch_icon $branch_msg$git_status$pr_info | 🧠 ${context_percent}% left"