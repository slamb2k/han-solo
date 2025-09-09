#!/bin/bash
# status-line-smart.sh - Intelligent status line that automatically switches based on context
# Refresh interval: 5 seconds (fast switching for context changes)

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

# If not in a git repo, show basic directory info
if [ -z "$BRANCH" ]; then
  CURRENT_DIR=$(basename "$(pwd)")
  echo "📁 ${CURRENT_DIR} - Not a git repo"
  exit 0
fi

# Function to check if there's an open PR for current branch
has_open_pr() {
  if command -v gh &> /dev/null; then
    PR_COUNT=$(gh pr list --head "$BRANCH" --state open --json number 2>/dev/null | jq length 2>/dev/null || echo 0)
    [ "$PR_COUNT" -gt 0 ]
  else
    return 1
  fi
}

# Function to check if on main/master branch
is_on_main() {
  [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]
}

# Function to check recent commit activity (within last 2 hours)
has_recent_activity() {
  # Check if there are any commits in the last 2 hours
  RECENT_COMMITS=$(git log --since="2 hours ago" --oneline 2>/dev/null | wc -l)
  [ "$RECENT_COMMITS" -gt 0 ]
}

# Function to check if branch has many changes
has_many_changes() {
  # Get main branch name
  MAIN_BRANCH="main"
  if ! git rev-parse --verify main >/dev/null 2>&1; then
    if git rev-parse --verify master >/dev/null 2>&1; then
      MAIN_BRANCH="master"
    fi
  fi
  
  # Count files changed from main
  if git rev-parse --verify "$MAIN_BRANCH" >/dev/null 2>&1; then
    FILES_CHANGED=$(git diff --name-only "$MAIN_BRANCH"..."$BRANCH" 2>/dev/null | wc -l)
    LINES_CHANGED=$(git diff --stat "$MAIN_BRANCH"..."$BRANCH" 2>/dev/null | tail -1 | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' || echo 0)
    
    # Threshold: more than 10 files or more than 500 lines
    [ "$FILES_CHANGED" -gt 10 ] || [ "$LINES_CHANGED" -gt 500 ]
  else
    return 1
  fi
}

# Smart switching logic
if has_open_pr; then
  # Has open PR - use pr-health.sh to monitor CI and review status
  exec "$SCRIPT_DIR/pr-health.sh"
elif is_on_main; then
  # On main branch - use git-safety.sh for safety warnings
  exec "$SCRIPT_DIR/git-safety.sh"
elif has_recent_activity; then
  # Recent commits - use work-session.sh to track productivity
  exec "$SCRIPT_DIR/work-session.sh"
elif has_many_changes; then
  # Large branch - use branch-metrics.sh to monitor size
  exec "$SCRIPT_DIR/branch-metrics.sh"
else
  # Default - use git-safety.sh for general safety
  exec "$SCRIPT_DIR/git-safety.sh"
fi