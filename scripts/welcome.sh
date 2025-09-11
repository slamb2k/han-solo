#!/bin/bash

# Display colorful banner
printf "\033[38;5;202m╔════════════════════════════════════════════════════════════════════════════════════════╗\033[0m\n"
printf "\033[38;5;208m║  __    __       ___       __   __               _______   ______    __        ______   ║\033[0m\n"
printf "\033[38;5;214m║ |  |  |  |     /   \\     |  \\ |  |             /       | /  __  \\  |  |      /  __  \\  ║\033[0m\n"
printf "\033[38;5;220m║ |  |__|  |    /  ^  \\    |   \\|  |  ______    |   (----\`|  |  |  | |  |     |  |  |  | ║\033[0m\n"
printf "\033[38;5;226m║ |   __   |   /  /_\\  \\   |  . \`  | |______|    \\   \\    |  |  |  | |  |     |  |  |  | ║\033[0m\n"
printf "\033[38;5;190m║ |  |  |  |  /  _____  \\  |  |\\   |         .----)   |   |  \`--'  | |  \`----.|  \`--'  | ║\033[0m\n"
printf "\033[38;5;154m║ |__|  |__| /__/     \\__\\ |__| \\__|         |_______/     \\______/  |_______| \\______/  ║\033[0m\n"
printf "\033[38;5;118m║                                                                                        ║\033[0m\n"
printf "\033[38;5;82m╚════════════════════════════════════════════════════════════════════════════════════════╝\033[0m\n"
# Flush stdout to ensure banner displays immediately
exec 1>&1
# Brief pause to let the user see the banner (1 second for welcome)
sleep 1

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

echo ""
echo -e "${BOLD}${CYAN}                     Welcome to Han-Solo Git Workflow Automation!${NC}"
echo ""
echo -e "${YELLOW}🚀 Essential Commands:${NC}"
echo ""
echo -e "  ${GREEN}/bootstrap${NC}    - Set up repository governance (branch protection, CI, hooks)"
echo -e "  ${GREEN}/ship${NC}         - Create PR, wait for checks, and auto-merge"
echo -e "  ${GREEN}/fresh${NC}        - Start a new feature branch from latest main"
echo -e "  ${GREEN}/status-line${NC}  - Switch between status line modes"
echo ""
echo -e "${YELLOW}📚 Quick Start:${NC}"
echo ""
echo -e "  1. Run ${CYAN}/bootstrap${NC} to set up your repository"
echo -e "  2. Use ${CYAN}/fresh feature-name${NC} to start new work"
echo -e "  3. Make your changes and commit them"
echo -e "  4. Run ${CYAN}/ship${NC} to create PR and auto-merge"
echo ""
echo -e "${YELLOW}💡 Pro Tips:${NC}"
echo ""
echo -e "  • Use ${CYAN}/status-line smart${NC} for automatic status switching"
echo -e "  • Run ${CYAN}/health${NC} to check repository status"
echo -e "  • Use ${CYAN}/scrub${NC} to clean up old branches"
echo -e "  • Add ${CYAN}--nowait${NC} to /ship to create PR without auto-merging"
echo ""
echo -e "${BLUE}For more information, visit: ${CYAN}https://github.com/slamb2k/han-solo${NC}"
echo ""