#!/bin/bash
# branch-metrics status line - Shows branch statistics and metrics
# Refresh interval: 30 seconds

# Colors and symbols
BRANCH_ICON='🌿'
COMMIT='💾'
FILES='📄'
LINES='📈'
AGE='📅'
SIZE_WARN='⚠️'
FOLDER='📁'

# Get current directory
CURRENT_DIR=$(basename "$(pwd)")

# Get current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

if [ -z "$BRANCH" ]; then
  echo "${FOLDER} ${CURRENT_DIR} - Not a git repo"
  exit 0
fi

# Get main branch name
MAIN_BRANCH="main"
if ! git rev-parse --verify main >/dev/null 2>&1; then
  if git rev-parse --verify master >/dev/null 2>&1; then
    MAIN_BRANCH="master"
  fi
fi

# Format branch name
if [ ${#BRANCH} -gt 12 ]; then
  BRANCH_DISPLAY="${BRANCH:0:10}..."
else
  BRANCH_DISPLAY="$BRANCH"
fi

# Count commits ahead of main
COMMITS_AHEAD=$(git rev-list --count ${MAIN_BRANCH}..HEAD 2>/dev/null || echo 0)

# Get branch age in days
if [ "$COMMITS_AHEAD" -gt 0 ]; then
  FIRST_COMMIT_DATE=$(git log ${MAIN_BRANCH}..HEAD --reverse --format=%ct | head -1)
  if [ -n "$FIRST_COMMIT_DATE" ]; then
    NOW=$(date +%s)
    AGE_SECONDS=$((NOW - FIRST_COMMIT_DATE))
    AGE_DAYS=$((AGE_SECONDS / 86400))
    
    if [ $AGE_DAYS -eq 0 ]; then
      AGE_HOURS=$((AGE_SECONDS / 3600))
      if [ $AGE_HOURS -eq 0 ]; then
        AGE_DISPLAY="<1h"
      else
        AGE_DISPLAY="${AGE_HOURS}h"
      fi
    else
      AGE_DISPLAY="${AGE_DAYS}d"
    fi
  else
    AGE_DISPLAY="new"
  fi
else
  AGE_DISPLAY="new"
fi

# Count changed files
FILES_CHANGED=$(git diff ${MAIN_BRANCH}...HEAD --name-only 2>/dev/null | wc -l)

# Count total insertions and deletions
STATS=$(git diff ${MAIN_BRANCH}...HEAD --shortstat 2>/dev/null)
if [ -n "$STATS" ]; then
  INSERTIONS=$(echo "$STATS" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' || echo 0)
  DELETIONS=$(echo "$STATS" | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+' || echo 0)
  TOTAL_LINES=$((${INSERTIONS:-0} + ${DELETIONS:-0}))
  
  # Format lines display
  if [ $TOTAL_LINES -gt 1000 ]; then
    LINES_DISPLAY="${SIZE_WARN}$(echo "scale=1; $TOTAL_LINES/1000" | bc)k"
  else
    LINES_DISPLAY="+${INSERTIONS:-0}/-${DELETIONS:-0}"
  fi
else
  LINES_DISPLAY="0"
fi

# Size warning for large branches
SIZE_WARNING=""
if [ $COMMITS_AHEAD -gt 20 ] || [ $FILES_CHANGED -gt 50 ] || [ ${TOTAL_LINES:-0} -gt 1000 ]; then
  SIZE_WARNING=" ${SIZE_WARN}Large"
fi

# Build status line
if [ "$BRANCH" = "$MAIN_BRANCH" ]; then
  echo "${BRANCH_ICON} ${CURRENT_DIR}/main"
else
  echo "${BRANCH_ICON} ${CURRENT_DIR}/${BRANCH_DISPLAY} ${COMMIT}${COMMITS_AHEAD} ${FILES}${FILES_CHANGED} ${LINES}${LINES_DISPLAY} ${AGE}${AGE_DISPLAY}${SIZE_WARNING}"
fi