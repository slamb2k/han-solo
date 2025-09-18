#!/bin/bash
# han-solo pre-flight check hook
# Enforces quality checks before git operations

set -euo pipefail
IFS=$'\n\t'

# Performance timer for <100ms target
start_time=$(date +%s%N 2>/dev/null || echo "0")

# Read JSON from stdin (Claude Code v1.0.117+)
json_input=$(cat)
tool_name=$(echo "$json_input" | jq -r '.tool_name // "unknown"')
command=$(echo "$json_input" | jq -r '.tool_input.command // ""')

# --- Pre-Commit Hook Logic ---
if [[ "$command" == git\ commit* ]]; then
    echo "han-solo: Running pre-commit checks..." >&2

    # Get project detection
    project_info=$(.claude/scripts/detect-project.sh 2>/dev/null || echo '{"project_type":"unknown"}')
    project_type=$(echo "$project_info" | jq -r '.project_type')
    lint_cmd=$(echo "$project_info" | jq -r '.lint_cmd // ""')

    if [ -n "$lint_cmd" ] && [ "$lint_cmd" != "null" ]; then
        echo "han-solo: Detected $project_type project, running: $lint_cmd" >&2
        if ! eval "$lint_cmd"; then
            echo "han-solo: ❌ Linting failed. Commit blocked." >&2
            echo "han-solo: Fix the linting errors and try again." >&2
            exit 2  # Blocking exit code
        fi
        echo "han-solo: ✅ Linting passed." >&2
    else
        echo "han-solo: No linter configured for project type: $project_type" >&2
    fi
fi

# --- Pre-Push Hook Logic ---
if [[ "$command" == git\ push* ]]; then
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

    # Check if pushing to main/master
    if [[ "$current_branch" == "main" ]] || [[ "$current_branch" == "master" ]]; then
        echo "han-solo: ❌ Direct push to $current_branch branch is forbidden." >&2
        echo "han-solo: Use a feature branch and create a pull request." >&2
        echo "han-solo: Try: git switch -c feature/your-feature" >&2
        exit 2  # Blocking exit code
    fi

    # Check if pushing to protected branch in remote
    if [[ "$command" == *"main"* ]] || [[ "$command" == *"master"* ]]; then
        echo "han-solo: ❌ Cannot push directly to protected branch." >&2
        echo "han-solo: Create a pull request instead with: /hansolo:ship" >&2
        exit 2  # Blocking exit code
    fi

    echo "han-solo: ✅ Push validation passed for branch: $current_branch" >&2
fi

# --- Branch Checkout Protection ---
if [[ "$command" == git\ checkout* ]] || [[ "$command" == git\ switch* ]]; then
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        echo "han-solo: ⚠️ You have uncommitted changes." >&2
        echo "han-solo: Consider committing or stashing first." >&2
        # Warning only, don't block
    fi
fi

# Performance check
if [ "$start_time" != "0" ]; then
    end_time=$(date +%s%N 2>/dev/null || echo "0")
    if [ "$end_time" != "0" ]; then
        duration=$(( (end_time - start_time) / 1000000 ))
        if [ "$duration" -gt 100 ]; then
            echo "han-solo: ⚠️ Hook took ${duration}ms (target: <100ms)" >&2
        fi
    fi
fi

exit 0  # Success, allow command to proceed