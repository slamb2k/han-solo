---
name: /han-solo:health
description: Comprehensive git repository health check - detect and diagnose potential issues before they cause problems
requires_args: false
---

## Purpose
Run a comprehensive health check on your git repository to detect issues like diverged branches, stale PRs, uncommitted changes, and other potential problems before they cause merge conflicts.

## Usage
```bash
# Run full health check
/health

# Quick status only
/health --quick

# Include branch cleanup suggestions
/health --suggest-cleanup
```

## What It Checks
1. **Branch Status**
   - Current branch name and age
   - Ahead/behind/diverged from origin
   - Uncommitted changes
   
2. **PR Status**
   - Open PRs and their state
   - Mergeable vs conflicting
   - Stale PRs (>7 days)
   
3. **Repository Health**
   - Last fetch time
   - Untracked files
   - Stash count
   - Remote connectivity
   
4. **Safety Indicators**
   - Working on main branch warning
   - Diverged branches alert
   - Old feature branches
   - Large uncommitted changes

## Implementation
```bash
#!/bin/bash
set -e

# Use the existing health check script if available
if [ -f "./scripts/git-health-check.sh" ]; then
  echo "Running comprehensive health check..."
  ./scripts/git-health-check.sh
  exit $?
fi

# Fallback implementation if script not found
echo "🏥 Git Repository Health Check"
echo "================================"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# Check if in git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo -e "${RED}❌ Not in a git repository${NC}"
  exit 1
fi

# Get current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo -e "\n${CYAN}📍 Current Branch${NC}"
echo "  Branch: $BRANCH"

# Check if on main
if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
  echo -e "  ${RED}⚠️  WARNING: On main branch!${NC}"
  echo -e "  ${YELLOW}→ Use /fresh to create a feature branch${NC}"
fi

# Check branch age
if [ "$BRANCH" != "main" ] && [ "$BRANCH" != "master" ]; then
  FIRST_COMMIT=$(git log --reverse --format=%ct -1 2>/dev/null || echo 0)
  if [ "$FIRST_COMMIT" -ne 0 ]; then
    AGE_DAYS=$(( ($(date +%s) - $FIRST_COMMIT) / 86400 ))
    if [ "$AGE_DAYS" -gt 3 ]; then
      echo -e "  ${YELLOW}⚠️  Branch is $AGE_DAYS days old (consider shipping soon)${NC}"
    else
      echo -e "  ${GREEN}✅ Branch age: $AGE_DAYS days${NC}"
    fi
  fi
fi

# Check for uncommitted changes
echo -e "\n${CYAN}📝 Working Directory${NC}"
CHANGES=$(git status --porcelain | wc -l)
if [ "$CHANGES" -gt 0 ]; then
  echo -e "  ${YELLOW}⚠️  $CHANGES uncommitted changes${NC}"
  git status --short
else
  echo -e "  ${GREEN}✅ Clean working directory${NC}"
fi

# Check sync status
echo -e "\n${CYAN}🔄 Sync Status${NC}"
UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "")
if [ -n "$UPSTREAM" ]; then
  LOCAL=$(git rev-parse HEAD)
  REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "")
  BASE=$(git merge-base HEAD @{u} 2>/dev/null || echo "")
  
  if [ "$LOCAL" = "$REMOTE" ]; then
    echo -e "  ${GREEN}✅ In sync with $UPSTREAM${NC}"
  elif [ "$LOCAL" = "$BASE" ]; then
    BEHIND=$(git rev-list --count HEAD..@{u})
    echo -e "  ${YELLOW}⚠️  Behind by $BEHIND commits${NC}"
    echo -e "  ${YELLOW}→ Run: git pull${NC}"
  elif [ "$REMOTE" = "$BASE" ]; then
    AHEAD=$(git rev-list --count @{u}..HEAD)
    echo -e "  ${GREEN}✅ Ahead by $AHEAD commits (ready to push)${NC}"
  else
    echo -e "  ${RED}❌ DIVERGED from $UPSTREAM${NC}"
    echo -e "  ${RED}→ Requires manual resolution or /fresh${NC}"
  fi
else
  echo -e "  ${YELLOW}⚠️  No upstream branch set${NC}"
fi

# Check for stashes
echo -e "\n${CYAN}📦 Stashes${NC}"
STASH_COUNT=$(git stash list | wc -l)
if [ "$STASH_COUNT" -gt 0 ]; then
  echo -e "  ${YELLOW}⚠️  $STASH_COUNT stashes found${NC}"
  git stash list --oneline | head -3
else
  echo -e "  ${GREEN}✅ No stashes${NC}"
fi

# Check PRs if gh is available
if command -v gh &> /dev/null; then
  echo -e "\n${CYAN}🎯 Pull Requests${NC}"
  PR_COUNT=$(gh pr list --author @me --json number | jq length 2>/dev/null || echo 0)
  if [ "$PR_COUNT" -gt 0 ]; then
    echo -e "  Found $PR_COUNT open PR(s):"
    gh pr list --author @me --limit 5
  else
    echo -e "  ${GREEN}✅ No open PRs${NC}"
  fi
fi

# Overall health score
echo -e "\n${CYAN}📊 Health Summary${NC}"
HEALTH_SCORE=100
ISSUES=()

[ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ] && HEALTH_SCORE=$((HEALTH_SCORE - 30)) && ISSUES+=("On main branch")
[ "$CHANGES" -gt 0 ] && HEALTH_SCORE=$((HEALTH_SCORE - 10)) && ISSUES+=("Uncommitted changes")
[ "$STASH_COUNT" -gt 3 ] && HEALTH_SCORE=$((HEALTH_SCORE - 5)) && ISSUES+=("Multiple stashes")
[ -n "$(git status --porcelain)" ] && [ "$CHANGES" -gt 10 ] && HEALTH_SCORE=$((HEALTH_SCORE - 10)) && ISSUES+=("Many uncommitted files")

if [ "$HEALTH_SCORE" -ge 90 ]; then
  echo -e "  ${GREEN}✅ Excellent health (${HEALTH_SCORE}%)${NC}"
elif [ "$HEALTH_SCORE" -ge 70 ]; then
  echo -e "  ${YELLOW}⚠️  Good health (${HEALTH_SCORE}%)${NC}"
else
  echo -e "  ${RED}❌ Poor health (${HEALTH_SCORE}%)${NC}"
fi

if [ ${#ISSUES[@]} -gt 0 ]; then
  echo -e "\n  Issues found:"
  for issue in "${ISSUES[@]}"; do
    echo -e "  ${YELLOW}• $issue${NC}"
  done
fi

echo -e "\n${CYAN}💡 Recommendations${NC}"
if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
  echo -e "  1. Run ${GREEN}/fresh${NC} to start a new feature branch"
fi
if [ "$CHANGES" -gt 0 ]; then
  echo -e "  2. Commit or stash your changes"
fi
if [ "$STASH_COUNT" -gt 3 ]; then
  echo -e "  3. Review and clean up old stashes"
fi
echo -e "  → Ready to ship? Run ${GREEN}/ship --check${NC} first"

exit 0
```

## Output Example
```
🏥 Git Repository Health Check
================================

📍 Current Branch
  Branch: feature/add-login
  ✅ Branch age: 2 days

📝 Working Directory
  ⚠️  3 uncommitted changes
  M  src/auth.js
  M  tests/auth.test.js
  ?? notes.txt

🔄 Sync Status
  ✅ Ahead by 2 commits (ready to push)

📦 Stashes
  ✅ No stashes

🎯 Pull Requests
  ✅ No open PRs

📊 Health Summary
  ✅ Good health (90%)

💡 Recommendations
  1. Commit or stash your changes
  → Ready to ship? Run /ship --check first
```

## Success Indicators
- Health score above 90%
- No diverged branches
- Clean working directory
- No old stale branches
- All PRs in good state

## Related Commands
- `/fresh` - Start clean feature branch
- `/ship --check` - Pre-flight checks before shipping
- `/scrub` - Clean up old branches

## Best Practices
1. Run `/health` at start of each day
2. Address warnings before they become errors
3. Keep health score above 90%
4. Clean up regularly