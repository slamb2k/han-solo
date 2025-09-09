#!/bin/bash

# 🔧 Git Workflow Tools Installation Script
# One-command setup for all git workflow improvements

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Emojis
CHECK="✅"
TOOLS="🔧"
HOOK="🪝"
ALIAS="⚡"
CONFIG="⚙️"
ROCKET="🚀"

echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${CYAN}       🔧 Git Workflow Tools Installer${NC}"
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Track what we've installed
INSTALLED_ITEMS=()
FAILED_ITEMS=()

# Step 1: Make scripts executable
echo -e "${BOLD}1. ${TOOLS} Making scripts executable${NC}"
for script in "$SCRIPT_DIR"/*.sh; do
    if [ -f "$script" ]; then
        chmod +x "$script"
        echo -e "  ${CHECK} $(basename "$script")"
    fi
done
INSTALLED_ITEMS+=("Scripts made executable")
echo ""

# Step 2: Install Git Hooks
echo -e "${BOLD}2. ${HOOK} Installing Git Hooks${NC}"

# Check if .git exists
if [ ! -d "$PROJECT_ROOT/.git" ]; then
    echo -e "  ${RED}❌ Not a git repository!${NC}"
    FAILED_ITEMS+=("Git hooks (not a git repo)")
else
    # Set git hooks path
    git config core.hooksPath .githooks
    echo -e "  ${CHECK} Set hooks path to .githooks"
    
    # Make hooks executable
    if [ -d "$PROJECT_ROOT/.githooks" ]; then
        chmod +x "$PROJECT_ROOT/.githooks"/* 2>/dev/null || true
        echo -e "  ${CHECK} Made hooks executable"
        INSTALLED_ITEMS+=("Git hooks")
    else
        echo -e "  ${YELLOW}⚠️  .githooks directory not found${NC}"
        FAILED_ITEMS+=("Git hooks (directory not found)")
    fi
fi
echo ""

# Step 3: Install Shell Aliases
echo -e "${BOLD}3. ${ALIAS} Installing Shell Aliases${NC}"

# Detect shell
SHELL_RC=""
SHELL_NAME=""
if [ -n "${ZSH_VERSION:-}" ] || [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
    SHELL_NAME="zsh"
elif [ -n "${BASH_VERSION:-}" ] || [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
    SHELL_NAME="bash"
fi

if [ -n "$SHELL_RC" ]; then
    ALIAS_SOURCE="source $SCRIPT_DIR/git-aliases.sh"
    
    # Check if already installed
    if grep -q "git-aliases.sh" "$SHELL_RC" 2>/dev/null; then
        echo -e "  ${CHECK} Aliases already installed in $SHELL_NAME"
    else
        echo "" >> "$SHELL_RC"
        echo "# Git Workflow Aliases" >> "$SHELL_RC"
        echo "$ALIAS_SOURCE" >> "$SHELL_RC"
        echo -e "  ${CHECK} Added aliases to $SHELL_RC"
        INSTALLED_ITEMS+=("Shell aliases ($SHELL_NAME)")
    fi
    
    # Source immediately for current session
    source "$SCRIPT_DIR/git-aliases.sh" 2>/dev/null || true
else
    echo -e "  ${YELLOW}⚠️  Could not detect shell (bash/zsh)${NC}"
    echo -e "  ${YELLOW}    Manually add to your shell rc file:${NC}"
    echo -e "  ${GREEN}    source $SCRIPT_DIR/git-aliases.sh${NC}"
    FAILED_ITEMS+=("Shell aliases (manual setup needed)")
fi
echo ""

# Step 4: Configure Git Settings
echo -e "${BOLD}4. ${CONFIG} Configuring Git Settings${NC}"

# Set pull to rebase by default
git config --global pull.rebase true
echo -e "  ${CHECK} Set pull.rebase = true"

# Set push default to current
git config --global push.default current
echo -e "  ${CHECK} Set push.default = current"

# Enable rerere
git config --global rerere.enabled true
echo -e "  ${CHECK} Enabled rerere (reuse recorded resolution)"

# Set default branch name
git config --global init.defaultBranch main
echo -e "  ${CHECK} Set default branch = main"

INSTALLED_ITEMS+=("Git configurations")
echo ""

# Step 5: Create useful symlinks (optional)
echo -e "${BOLD}5. ${TOOLS} Creating convenience symlinks${NC}"

# Ask user if they want global commands
echo -e "  ${YELLOW}Create global commands? (requires sudo) (y/N):${NC} "
read -n 1 -r CREATE_GLOBAL
echo
if [[ $CREATE_GLOBAL =~ ^[Yy]$ ]]; then
    # Try to create symlinks in /usr/local/bin
    if [ -d "/usr/local/bin" ]; then
        sudo ln -sf "$SCRIPT_DIR/git-health-check.sh" /usr/local/bin/git-health 2>/dev/null && \
            echo -e "  ${CHECK} git-health command created" || \
            echo -e "  ${YELLOW}⚠️  Could not create git-health${NC}"
        
        sudo ln -sf "$SCRIPT_DIR/pre-ship-check.sh" /usr/local/bin/pre-ship 2>/dev/null && \
            echo -e "  ${CHECK} pre-ship command created" || \
            echo -e "  ${YELLOW}⚠️  Could not create pre-ship${NC}"
        
        sudo ln -sf "$SCRIPT_DIR/post-ship-cleanup.sh" /usr/local/bin/post-ship 2>/dev/null && \
            echo -e "  ${CHECK} post-ship command created" || \
            echo -e "  ${YELLOW}⚠️  Could not create post-ship${NC}"
        
        INSTALLED_ITEMS+=("Global commands")
    else
        echo -e "  ${YELLOW}⚠️  /usr/local/bin not found${NC}"
    fi
else
    echo -e "  ${INFO} Skipped global commands"
fi
echo ""

# Final Summary
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${CYAN}              Installation Summary${NC}"
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ ${#INSTALLED_ITEMS[@]} -gt 0 ]; then
    echo -e "${GREEN}${CHECK} Successfully installed:${NC}"
    for item in "${INSTALLED_ITEMS[@]}"; do
        echo -e "  • $item"
    done
    echo ""
fi

if [ ${#FAILED_ITEMS[@]} -gt 0 ]; then
    echo -e "${RED}❌ Failed to install:${NC}"
    for item in "${FAILED_ITEMS[@]}"; do
        echo -e "  • $item"
    done
    echo ""
fi

# Usage instructions
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${CYAN}              ${ROCKET} Ready to Use!${NC}"
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BOLD}Available Commands:${NC}"
echo ""
echo -e "${GREEN}Workflow Commands (if aliases installed):${NC}"
echo -e "  ${CYAN}ghelp${NC}     - Show all available aliases"
echo -e "  ${CYAN}gfresh${NC}    - Start fresh feature branch"
echo -e "  ${CYAN}gsafe${NC}     - Check if safe to ship"
echo -e "  ${CYAN}gship${NC}     - Safe wrapper for /ship"
echo -e "  ${CYAN}gclean${NC}    - Post-ship cleanup"
echo ""
echo -e "${GREEN}Direct Scripts:${NC}"
echo -e "  ${CYAN}./scripts/git-health-check.sh${NC}  - Full health check"
echo -e "  ${CYAN}./scripts/pre-ship-check.sh${NC}     - Pre-ship safety"
echo -e "  ${CYAN}./scripts/post-ship-cleanup.sh${NC}  - Post-ship cleanup"
echo ""
echo -e "${BOLD}${YELLOW}⚠️  Note:${NC}"
if [ -n "$SHELL_RC" ]; then
    echo -e "  Restart your terminal or run: ${GREEN}source $SHELL_RC${NC}"
    echo -e "  to use the new aliases immediately."
fi
echo ""
echo -e "${BOLD}${GREEN}Installation complete! Happy shipping! 🚢${NC}"
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

exit 0