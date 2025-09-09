---
name: git-safety
description: Shows git branch safety status and PR state to prevent merge conflicts
refresh_interval: 5
---

#!/bin/bash

# Colors
GREEN='✅'
YELLOW='⚠️'
RED='🔴'
BLUE='🔵'
ROCKET='🚀'

# Get current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

if [ -z "$BRANCH" ]; then
  echo "📁 Not a git repo"
  exit 0
fi

# Check if we're on main/master
if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
  echo "${RED} ON MAIN - Use /fresh to start work"
  exit 0
fi

# Check for uncommitted changes
UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l)
if [ "$UNCOMMITTED" -gt 0 ]; then
  STATUS="${YELLOW}"
  CHANGES=" (${UNCOMMITTED} uncommitted)"
else
  STATUS="${GREEN}"
  CHANGES=""
fi

# Check if branch is ahead/behind/diverged
UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
if [ -n "$UPSTREAM" ]; then
  LOCAL=$(git rev-parse HEAD)
  REMOTE=$(git rev-parse @{u} 2>/dev/null)
  BASE=$(git merge-base HEAD @{u} 2>/dev/null)
  
  if [ "$LOCAL" = "$REMOTE" ]; then
    SYNC=" ✓"
  elif [ "$LOCAL" = "$BASE" ]; then
    BEHIND=$(git rev-list --count HEAD..@{u})
    SYNC=" ↓${BEHIND}"
  elif [ "$REMOTE" = "$BASE" ]; then
    AHEAD=$(git rev-list --count @{u}..HEAD)
    SYNC=" ↑${AHEAD}"
  else
    SYNC=" ${RED}DIVERGED"
  fi
else
  SYNC=""
fi

# Check for open PRs
PR_INFO=""
if command -v gh &> /dev/null; then
  PR_NUM=$(gh pr list --head "$BRANCH" --json number --jq '.[0].number' 2>/dev/null)
  if [ -n "$PR_NUM" ]; then
    PR_STATE=$(gh pr view "$PR_NUM" --json state,mergeable --jq '.state + ":" + .mergeable' 2>/dev/null)
    case "$PR_STATE" in
      *MERGED*)
        PR_INFO=" ${GREEN}PR#${PR_NUM}✓"
        ;;
      *OPEN:MERGEABLE*)
        PR_INFO=" ${BLUE}PR#${PR_NUM}→"
        ;;
      *OPEN:CONFLICTING*)
        PR_INFO=" ${RED}PR#${PR_NUM}⚡"
        ;;
      *OPEN*)
        PR_INFO=" ${YELLOW}PR#${PR_NUM}..."
        ;;
    esac
  fi
fi

# Check branch age
if [ -n "$(git log -1 --format=%ci 2>/dev/null)" ]; then
  BRANCH_AGE=$(( ($(date +%s) - $(git log -1 --format=%ct)) / 86400 ))
  if [ "$BRANCH_AGE" -gt 3 ]; then
    AGE_WARN=" ${YELLOW}${BRANCH_AGE}d old"
  else
    AGE_WARN=""
  fi
else
  AGE_WARN=""
fi

# Format branch name (truncate if too long)
if [ ${#BRANCH} -gt 20 ]; then
  BRANCH_DISPLAY="${BRANCH:0:17}..."
else
  BRANCH_DISPLAY="$BRANCH"
fi

# Output status line
echo "${STATUS} ${BRANCH_DISPLAY}${CHANGES}${SYNC}${PR_INFO}${AGE_WARN}"