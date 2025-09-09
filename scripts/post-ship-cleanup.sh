#!/bin/bash

# 🧹 Post-Ship Cleanup Script
# Automatically syncs your repository after a successful /ship

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# Emoji
CHECK="✅"
CLEAN="🧹"
SYNC="🔄"
TRASH="🗑️"
INFO="ℹ️ "
SPARKLE="✨"

echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${CYAN}              🧹 Post-Ship Cleanup${NC}"
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Save current branch name before switching
SHIPPED_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Determine main branch
MAIN_BRANCH="main"
if ! git show-ref --verify --quiet refs/heads/main; then
    if git show-ref --verify --quiet refs/heads/master; then
        MAIN_BRANCH="master"
    else
        echo -e "${RED}  ❌ No main or master branch found${NC}"
        exit 1
    fi
fi

echo -e "${BOLD}${INFO} Starting cleanup after shipping from: ${YELLOW}$SHIPPED_BRANCH${NC}"
echo ""

# Step 1: Fetch latest changes
echo -e "${BOLD}1. ${SYNC} Fetching latest changes${NC}"
git fetch origin --prune
echo -e "  ${CHECK} Fetched latest from origin"
echo ""

# Step 2: Switch to main branch
echo -e "${BOLD}2. ${SYNC} Switching to $MAIN_BRANCH branch${NC}"
git checkout "$MAIN_BRANCH" 2>/dev/null || {
    echo -e "  ${RED}Failed to checkout $MAIN_BRANCH${NC}"
    exit 1
}
echo -e "  ${CHECK} Switched to $MAIN_BRANCH"
echo ""

# Step 3: Reset main to match origin
echo -e "${BOLD}3. ${SYNC} Syncing $MAIN_BRANCH with origin${NC}"
BEFORE_COMMIT=$(git rev-parse HEAD)
git reset --hard origin/"$MAIN_BRANCH"
AFTER_COMMIT=$(git rev-parse HEAD)

if [ "$BEFORE_COMMIT" != "$AFTER_COMMIT" ]; then
    COMMITS_DIFF=$(git rev-list --count "$BEFORE_COMMIT".."$AFTER_COMMIT" 2>/dev/null || echo "unknown")
    echo -e "  ${CHECK} Synced $MAIN_BRANCH (updated by $COMMITS_DIFF commits)"
else
    echo -e "  ${CHECK} Already in sync with origin/$MAIN_BRANCH"
fi
echo ""

# Step 4: Clean untracked files (optional)
echo -e "${BOLD}4. ${CLEAN} Cleaning workspace${NC}"
UNTRACKED_COUNT=$(git ls-files --others --exclude-standard | wc -l)
if [ "$UNTRACKED_COUNT" -gt 0 ]; then
    echo -e "  ${INFO} Found $UNTRACKED_COUNT untracked file(s)"
    echo -e "  ${INFO} Run ${GREEN}git clean -fd${NC} to remove them (skipping for safety)"
else
    echo -e "  ${CHECK} No untracked files"
fi
echo ""

# Step 5: Delete the shipped branch (if not main)
echo -e "${BOLD}5. ${TRASH} Cleaning up branches${NC}"
if [ "$SHIPPED_BRANCH" != "$MAIN_BRANCH" ] && [ "$SHIPPED_BRANCH" != "master" ]; then
    # Check if branch exists locally
    if git show-ref --verify --quiet refs/heads/"$SHIPPED_BRANCH"; then
        echo -e "  ${INFO} Delete shipped branch: ${YELLOW}$SHIPPED_BRANCH${NC}?"
        echo -e "  ${INFO} (Branch was likely merged via PR)"
        read -p "  Delete branch? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git branch -D "$SHIPPED_BRANCH"
            echo -e "  ${CHECK} Deleted branch: $SHIPPED_BRANCH"
        else
            echo -e "  ${INFO} Kept branch: $SHIPPED_BRANCH"
        fi
    fi
else
    echo -e "  ${INFO} Was on $MAIN_BRANCH, no branch to delete"
fi

# Clean up other merged branches
echo ""
echo -e "  ${INFO} Checking for other merged branches..."
MERGED_BRANCHES=$(git branch --merged origin/"$MAIN_BRANCH" | grep -v "^\*" | grep -v "$MAIN_BRANCH" | grep -v "master" || true)
if [ -n "$MERGED_BRANCHES" ]; then
    echo -e "  ${INFO} Found merged branches:"
    echo "$MERGED_BRANCHES" | sed 's/^/    /'
    read -p "  Delete all merged branches? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "$MERGED_BRANCHES" | xargs -r git branch -d
        echo -e "  ${CHECK} Deleted merged branches"
    fi
else
    echo -e "  ${CHECK} No merged branches to clean"
fi
echo ""

# Step 6: Prune remote tracking branches
echo -e "${BOLD}6. ${CLEAN} Pruning remote branches${NC}"
BEFORE_REMOTE=$(git branch -r | wc -l)
git remote prune origin
AFTER_REMOTE=$(git branch -r | wc -l)
PRUNED=$((BEFORE_REMOTE - AFTER_REMOTE))
if [ "$PRUNED" -gt 0 ]; then
    echo -e "  ${CHECK} Pruned $PRUNED remote tracking branch(es)"
else
    echo -e "  ${CHECK} No remote branches to prune"
fi
echo ""

# Step 7: Show current status
echo -e "${BOLD}7. ${INFO} Final Status${NC}"
echo -e "  ${INFO} Current branch: ${GREEN}$MAIN_BRANCH${NC}"
echo -e "  ${INFO} Latest commit:"
git log --oneline -1 | sed 's/^/    /'

# Check if up to date
LOCAL_COMMIT=$(git rev-parse HEAD)
REMOTE_COMMIT=$(git rev-parse origin/"$MAIN_BRANCH")
if [ "$LOCAL_COMMIT" = "$REMOTE_COMMIT" ]; then
    echo -e "  ${CHECK} Fully synced with origin/$MAIN_BRANCH"
else
    echo -e "  ${RED}❌ Not in sync with origin (this shouldn't happen)${NC}"
fi
echo ""

# Step 8: Recommendations
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${CYAN}              ${SPARKLE} Ready for Next Task${NC}"
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BOLD}  Next steps:${NC}"
echo -e "  1. Create a new feature branch:"
echo -e "     ${GREEN}git checkout -b feature/your-next-feature${NC}"
echo ""
echo -e "  2. Or use the safe workflow:"
echo -e "     ${GREEN}gfresh feature/your-next-feature${NC} (if aliases installed)"
echo ""
echo -e "${BOLD}  ${CHECK} Cleanup complete! Your repository is clean and synced.${NC}"
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

exit 0