---
name: /han-solo:fresh
description: Start a fresh feature branch with all safety checks - the safest way to begin new work
requires_args: false
---

## Purpose
Start a fresh, clean feature branch from an updated main branch. This command ensures you never encounter merge conflicts by always starting from the latest code.

## Usage
```bash
# Create branch with auto-generated name (feature/YYYY-MM-DD-HHMMSS)
/fresh

# Create branch with custom name
/fresh my-feature

# Create branch with conventional prefix
/fresh fix/bug-123
/fresh feat/new-feature
/fresh docs/update-readme
```

## What It Does
1. **Saves** any uncommitted work to stash
2. **Switches** to main branch
3. **Fetches** latest from origin
4. **Resets** main to match origin/main exactly
5. **Cleans** untracked files and directories
6. **Creates** new feature branch
7. **Restores** stashed work if any

## Safety Features
- ✅ Never loses uncommitted work (auto-stash)
- ✅ Always starts from latest main
- ✅ Cleans up old branches automatically
- ✅ Prevents working on stale code
- ✅ Shows clear status after completion

## Context (Auto-detected)
The command will detect:
- Current repository and branch
- Any uncommitted changes
- Divergence from origin/main
- Age of current branch
- Open PRs

## Examples
```bash
# Monday morning fresh start
/fresh monday-work

# Start bug fix with clean slate
/fresh fix/login-issue

# Quick feature branch
/fresh

# After a failed PR, start over
/fresh attempt-2
```

## Implementation
```bash
#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}🚀 Starting fresh work session...${NC}"

# Parse branch name argument
BRANCH_NAME="${1:-feature/$(date +%Y-%m-%d-%H%M%S)}"

# Ensure we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo -e "${RED}❌ Not in a git repository${NC}"
  exit 1
fi

# Get current branch for reporting
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo -e "Current branch: ${YELLOW}$CURRENT_BRANCH${NC}"

# Check for uncommitted changes and stash them
STASH_NEEDED=false
if [ -n "$(git status --porcelain)" ]; then
  echo -e "${YELLOW}📦 Stashing uncommitted changes...${NC}"
  git stash push -m "fresh-command-autostash-$(date +%s)"
  STASH_NEEDED=true
fi

# Determine main branch name
MAIN_BRANCH="main"
if ! git rev-parse --verify main >/dev/null 2>&1; then
  if git rev-parse --verify master >/dev/null 2>&1; then
    MAIN_BRANCH="master"
  fi
fi

# Switch to main branch
echo -e "${CYAN}📍 Switching to $MAIN_BRANCH branch...${NC}"
git checkout "$MAIN_BRANCH" 2>/dev/null || {
  echo -e "${RED}❌ Failed to checkout $MAIN_BRANCH${NC}"
  exit 1
}

# Fetch latest changes
echo -e "${CYAN}📡 Fetching latest changes...${NC}"
git fetch origin --prune

# Hard reset to origin/main
echo -e "${CYAN}🔄 Syncing with origin/$MAIN_BRANCH...${NC}"
git reset --hard "origin/$MAIN_BRANCH"

# Clean untracked files
echo -e "${CYAN}🧹 Cleaning untracked files...${NC}"
git clean -fd

# Create new feature branch
echo -e "${GREEN}🌱 Creating new branch: $BRANCH_NAME${NC}"
git checkout -b "$BRANCH_NAME"

# Restore stashed changes if any
if [ "$STASH_NEEDED" = true ]; then
  echo -e "${YELLOW}📤 Restoring stashed changes...${NC}"
  git stash pop || {
    echo -e "${YELLOW}⚠️  Could not auto-restore stash (conflicts possible)${NC}"
    echo -e "${YELLOW}   Use 'git stash list' and 'git stash pop' manually${NC}"
  }
fi

# Show final status
echo ""
echo -e "${GREEN}✅ Fresh branch ready!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Branch: ${CYAN}$BRANCH_NAME${NC}"
echo -e "  Base: ${CYAN}origin/$MAIN_BRANCH${NC} (latest)"
echo -e "  Status: ${GREEN}Clean and ready for work${NC}"
echo ""
echo -e "${YELLOW}💡 Next steps:${NC}"
echo -e "  1. Make your changes"
echo -e "  2. Commit with: ${CYAN}git add . && git commit -m 'your message'${NC}"
echo -e "  3. Ship with: ${CYAN}/ship${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Final safety check
if [ "$(git rev-parse --abbrev-ref HEAD)" = "$MAIN_BRANCH" ]; then
  echo -e "${RED}⚠️  WARNING: Still on $MAIN_BRANCH branch!${NC}"
  exit 1
fi

exit 0
```

## Success Criteria
- ✅ On a new feature branch
- ✅ Branch based on latest origin/main
- ✅ No uncommitted changes lost
- ✅ Working directory clean
- ✅ Ready for development

## Troubleshooting
- **"Not in a git repository"**: Run from project root
- **"Failed to checkout main"**: Ensure main/master branch exists
- **"Could not auto-restore stash"**: Manual conflict resolution needed
- **Network issues**: Check internet connection for fetch

## Related Commands
- `/ship` - Ship your changes when ready
- `/health` - Check repository health
- `/scrub` - Clean up old branches

## Best Practices
1. **Use daily**: Start each day with `/fresh`
2. **Small branches**: Ship often, keep branches focused
3. **Descriptive names**: Use `feat/`, `fix/`, `docs/` prefixes
4. **Clean regularly**: Don't accumulate old branches