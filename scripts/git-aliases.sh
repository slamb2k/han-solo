#!/bin/bash

# 🚀 Git Workflow Aliases
# Source this file in your .bashrc or .zshrc to use these shortcuts

# Colors for echo output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# ============================================
# Core Workflow Aliases
# ============================================

# 🌱 Start fresh work session
# Usage: gfresh feature/my-feature
gfresh() {
    local branch_name="${1:-feature/$(date +%Y%m%d-%H%M%S)}"
    echo -e "${CYAN}Starting fresh work session...${NC}"
    git checkout main 2>/dev/null || git checkout master
    git fetch origin --prune
    git reset --hard origin/main 2>/dev/null || git reset --hard origin/master
    git clean -fd
    git checkout -b "$branch_name"
    echo -e "${GREEN}✅ Created branch: $branch_name${NC}"
    echo -e "${YELLOW}Ready to work! Use /ship when done.${NC}"
}

# 🔍 Check if safe to ship
# Usage: gsafe
gsafe() {
    if [ -f "./scripts/pre-ship-check.sh" ]; then
        ./scripts/pre-ship-check.sh
    else
        echo -e "${YELLOW}Pre-ship check script not found${NC}"
        echo -e "Running basic checks..."
        
        local current_branch=$(git rev-parse --abbrev-ref HEAD)
        if [ "$current_branch" = "main" ] || [ "$current_branch" = "master" ]; then
            echo -e "${RED}❌ On main branch - not safe!${NC}"
            return 1
        else
            echo -e "${GREEN}✅ On feature branch: $current_branch${NC}"
        fi
        
        if [ -n "$(git status --porcelain)" ]; then
            echo -e "${YELLOW}⚠️  Uncommitted changes present${NC}"
        fi
        
        local unpushed=$(git rev-list HEAD ^@{u} 2>/dev/null | wc -l)
        if [ "$unpushed" -gt 0 ]; then
            echo -e "${YELLOW}⚠️  $unpushed unpushed commits${NC}"
        fi
    fi
}

# 🚢 Safe ship wrapper
# Usage: gship
gship() {
    echo -e "${CYAN}Running pre-ship safety check...${NC}"
    if gsafe; then
        echo -e "${GREEN}Safety check passed!${NC}"
        echo -e "${CYAN}Running /ship...${NC}"
        /ship "$@"
        echo -e "${YELLOW}Remember to run: gclean${NC}"
    else
        echo -e "${RED}Safety check failed! Fix issues before shipping.${NC}"
        return 1
    fi
}

# 🧹 Post-ship cleanup
# Usage: gclean
gclean() {
    if [ -f "./scripts/post-ship-cleanup.sh" ]; then
        ./scripts/post-ship-cleanup.sh
    else
        echo -e "${CYAN}Running manual cleanup...${NC}"
        local shipped_branch=$(git rev-parse --abbrev-ref HEAD)
        git checkout main 2>/dev/null || git checkout master
        git fetch origin --prune
        git reset --hard origin/main 2>/dev/null || git reset --hard origin/master
        
        if [ "$shipped_branch" != "main" ] && [ "$shipped_branch" != "master" ]; then
            echo -e "${YELLOW}Delete branch $shipped_branch? (y/N)${NC}"
            read -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                git branch -D "$shipped_branch"
                echo -e "${GREEN}✅ Deleted $shipped_branch${NC}"
            fi
        fi
        echo -e "${GREEN}✅ Cleanup complete!${NC}"
    fi
}

# 📊 Enhanced status
# Usage: gstatus
gstatus() {
    if [ -f "./scripts/git-health-check.sh" ]; then
        ./scripts/git-health-check.sh
    else
        echo -e "${CYAN}=== Git Status Overview ===${NC}"
        echo -e "${YELLOW}Branch:${NC} $(git rev-parse --abbrev-ref HEAD)"
        echo -e "${YELLOW}Status:${NC}"
        git status -sb
        echo ""
        echo -e "${YELLOW}Recent commits:${NC}"
        git log --oneline -5
    fi
}

# ============================================
# Utility Aliases
# ============================================

# 🔄 Sync with main
# Usage: gsync
gsync() {
    echo -e "${CYAN}Syncing with main...${NC}"
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    git checkout main 2>/dev/null || git checkout master
    git fetch origin --prune
    git reset --hard origin/main 2>/dev/null || git reset --hard origin/master
    git checkout "$current_branch"
    echo -e "${GREEN}✅ Synced!${NC}"
}

# 🌿 Create feature branch
# Usage: gfeature my-feature
gfeature() {
    local feature_name="${1:-feature-$(date +%Y%m%d-%H%M%S)}"
    if [[ ! "$feature_name" =~ ^feature/ ]]; then
        feature_name="feature/$feature_name"
    fi
    git checkout -b "$feature_name"
    echo -e "${GREEN}✅ Created branch: $feature_name${NC}"
}

# 🗑️ Delete merged branches
# Usage: gprune
gprune() {
    echo -e "${CYAN}Cleaning merged branches...${NC}"
    git branch --merged | grep -v "^\*" | grep -v main | grep -v master | xargs -r git branch -d
    git remote prune origin
    echo -e "${GREEN}✅ Pruned!${NC}"
}

# 📝 Quick commit
# Usage: gcommit "commit message"
gcommit() {
    if [ -z "$1" ]; then
        echo -e "${RED}Please provide a commit message${NC}"
        return 1
    fi
    git add -A
    git commit -m "$1"
}

# 🚑 Emergency reset
# Usage: greset
greset() {
    echo -e "${YELLOW}⚠️  This will reset to origin/main. Continue? (y/N)${NC}"
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git fetch origin
        git reset --hard origin/main 2>/dev/null || git reset --hard origin/master
        git clean -fd
        echo -e "${GREEN}✅ Reset complete!${NC}"
    fi
}

# 📋 Show available aliases
# Usage: ghelp
ghelp() {
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}          🚀 Git Workflow Aliases${NC}"
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BOLD}Core Workflow:${NC}"
    echo -e "  ${GREEN}gfresh [name]${NC}  - Start fresh feature branch"
    echo -e "  ${GREEN}gsafe${NC}          - Check if safe to ship"
    echo -e "  ${GREEN}gship${NC}          - Safe wrapper for /ship"
    echo -e "  ${GREEN}gclean${NC}         - Post-ship cleanup"
    echo -e "  ${GREEN}gstatus${NC}        - Enhanced git status"
    echo ""
    echo -e "${BOLD}Utilities:${NC}"
    echo -e "  ${GREEN}gsync${NC}          - Sync with main branch"
    echo -e "  ${GREEN}gfeature [name]${NC}- Create feature branch"
    echo -e "  ${GREEN}gprune${NC}         - Delete merged branches"
    echo -e "  ${GREEN}gcommit \"msg\"${NC}  - Quick add & commit"
    echo -e "  ${GREEN}greset${NC}         - Emergency reset to origin"
    echo ""
    echo -e "${BOLD}Workflow Example:${NC}"
    echo -e "  ${CYAN}gfresh feature/my-task${NC}  # Start"
    echo -e "  ${CYAN}# ... do work ...${NC}"
    echo -e "  ${CYAN}gsafe${NC}                    # Check"
    echo -e "  ${CYAN}gship${NC}                    # Ship"
    echo -e "  ${CYAN}gclean${NC}                   # Clean"
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ============================================
# Auto-setup notification
# ============================================

# Show help on source
echo -e "${GREEN}✅ Git workflow aliases loaded!${NC}"
echo -e "Type ${CYAN}ghelp${NC} to see available commands"