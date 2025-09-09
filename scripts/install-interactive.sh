#!/bin/bash

# 🚀 Han-Solo Interactive Installer
# Beautiful terminal experience with advanced controls

set -e

# Terminal colors and styles
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'
BLINK='\033[5m'
REVERSE='\033[7m'
NC='\033[0m' # No Color

# Box drawing characters
BOX_TL='╔'
BOX_TR='╗'
BOX_BL='╚'
BOX_BR='╝'
BOX_H='═'
BOX_V='║'
BOX_PLUS='╬'
BOX_T_DOWN='╦'
BOX_T_UP='╩'
BOX_T_RIGHT='╠'
BOX_T_LEFT='╣'

# Symbols
CHECK='✓'
CROSS='✗'
ARROW='→'
STAR='★'
HEART='♥'
DIAMOND='♦'
RADIO_ON='◉'
RADIO_OFF='○'
CHECK_ON='☑'
CHECK_OFF='☐'
ROCKET='🚀'
PACKAGE='📦'
TOOL='🔧'
SPARKLES='✨'

# Installation state
SELECTED_COMPONENTS=()
INSTALL_MODE="project"
SELECTED_PROFILE=""

# Clear screen and hide cursor
clear_screen() {
    clear
    tput civis  # Hide cursor
}

# Show cursor on exit
cleanup() {
    tput cnorm  # Show cursor
    echo -e "\n${GREEN}Thanks for using Han-Solo!${NC}"
}
trap cleanup EXIT

# Draw a box
draw_box() {
    local width=$1
    local height=$2
    local title=$3
    
    # Top line with title
    echo -ne "${CYAN}${BOX_TL}"
    if [ -n "$title" ]; then
        echo -ne "${BOX_H}${BOX_H}[ ${WHITE}${BOLD}$title${NC}${CYAN} ]"
        for ((i=${#title}+6; i<$width-2; i++)); do echo -ne "${BOX_H}"; done
    else
        for ((i=0; i<$width-2; i++)); do echo -ne "${BOX_H}"; done
    fi
    echo -e "${BOX_TR}${NC}"
}

# Draw ASCII art logo
draw_logo() {
    echo -e "${CYAN}"
    cat << 'EOF'
    ╦ ╦┌─┐┌┐┌   ╔═╗┌─┐┬  ┌─┐
    ╠═╣├─┤│││───╚═╗│ ││  │ │
    ╩ ╩┴ ┴┘└┘   ╚═╝└─┘┴─┘└─┘
EOF
    echo -e "${NC}"
    echo -e "${DIM}${ITALIC}    Git Workflow Automation for Solo Developers${NC}"
    echo ""
}

# Animated progress bar
progress_bar() {
    local duration=$1
    local width=50
    local progress=0
    
    echo -ne "  ["
    while [ $progress -le $width ]; do
        echo -ne "${GREEN}█${NC}"
        progress=$((progress + 1))
        sleep $(echo "scale=3; $duration/$width" | bc 2>/dev/null || echo 0.02)
    done
    echo -e "] ${GREEN}${CHECK}${NC}"
}

# Interactive menu with arrow key navigation
menu_select() {
    local prompt=$1
    shift
    local options=("$@")
    local selected=0
    local key=""
    
    # Hide cursor
    tput civis
    
    while true; do
        # Clear menu area
        tput cuu ${#options[@]}
        tput cuu 2
        
        # Display prompt
        echo -e "${BOLD}${prompt}${NC}"
        echo ""
        
        # Display options
        for i in "${!options[@]}"; do
            if [ $i -eq $selected ]; then
                echo -e "  ${GREEN}${ARROW}${NC} ${REVERSE}${options[$i]}${NC}"
            else
                echo -e "    ${options[$i]}"
            fi
        done
        
        # Read key input
        read -rsn1 key
        case "$key" in
            A) # Up arrow
                ((selected--))
                [ $selected -lt 0 ] && selected=$((${#options[@]} - 1))
                ;;
            B) # Down arrow
                ((selected++))
                [ $selected -ge ${#options[@]} ] && selected=0
                ;;
            "") # Enter
                break
                ;;
        esac
    done
    
    tput cnorm
    return $selected
}

# Checkbox selection interface
checkbox_select() {
    local prompt=$1
    shift
    local options=("$@")
    local selected=()
    local cursor=0
    local key=""
    
    # Initialize all as unselected
    for i in "${!options[@]}"; do
        selected[$i]=0
    done
    
    tput civis
    
    while true; do
        # Clear and redraw
        tput cuu $((${#options[@]} + 3))
        
        echo -e "${BOLD}${prompt}${NC}"
        echo -e "${DIM}(Use ↑/↓ to navigate, SPACE to select, ENTER to confirm)${NC}"
        echo ""
        
        for i in "${!options[@]}"; do
            local checkbox="${CHECK_OFF}"
            [ ${selected[$i]} -eq 1 ] && checkbox="${CHECK_ON}"
            
            if [ $i -eq $cursor ]; then
                echo -e "  ${GREEN}${ARROW}${NC} ${checkbox} ${options[$i]}"
            else
                echo -e "    ${checkbox} ${options[$i]}"
            fi
        done
        
        read -rsn1 key
        case "$key" in
            A) # Up
                ((cursor--))
                [ $cursor -lt 0 ] && cursor=$((${#options[@]} - 1))
                ;;
            B) # Down
                ((cursor++))
                [ $cursor -ge ${#options[@]} ] && cursor=0
                ;;
            " ") # Space - toggle selection
                if [ ${selected[$cursor]} -eq 0 ]; then
                    selected[$cursor]=1
                else
                    selected[$cursor]=0
                fi
                ;;
            "") # Enter - confirm
                break
                ;;
        esac
    done
    
    # Build result array
    SELECTED_COMPONENTS=()
    for i in "${!options[@]}"; do
        [ ${selected[$i]} -eq 1 ] && SELECTED_COMPONENTS+=("${options[$i]}")
    done
    
    tput cnorm
}

# Spinner animation
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Type writer effect
type_text() {
    local text=$1
    local delay=${2:-0.03}
    
    for (( i=0; i<${#text}; i++ )); do
        echo -n "${text:$i:1}"
        sleep $delay
    done
    echo ""
}

# Main installation flow
main() {
    clear_screen
    
    # Welcome screen with ASCII art
    draw_logo
    sleep 0.5
    
    echo -e "${GREEN}${SPARKLES} Welcome to Han-Solo Interactive Installer ${SPARKLES}${NC}"
    echo ""
    type_text "Let's set up your ultimate git workflow automation tools!" 0.02
    echo ""
    echo -e "${DIM}Press ENTER to continue...${NC}"
    read -s
    
    clear_screen
    draw_logo
    
    # Step 1: Select installation mode
    echo -e "${CYAN}${BOLD}Step 1: Installation Scope${NC}"
    echo ""
    echo -e "Where would you like to install Han-Solo?"
    echo ""
    options=("Project-scoped (recommended)" "Global (all projects)" "Custom location")
    menu_select "Select installation scope:" "${options[@]}"
    case $? in
        0) INSTALL_MODE="project" ;;
        1) INSTALL_MODE="global" ;;
        2) INSTALL_MODE="custom" ;;
    esac
    
    clear_screen
    draw_logo
    
    # Step 2: Select profile
    echo -e "${CYAN}${BOLD}Step 2: Configuration Profile${NC}"
    echo ""
    echo -e "Choose a pre-configured profile or customize:"
    echo ""
    options=("Solo Developer (fast & safe)" "Team Workflow (collaborative)" "Minimal (essentials only)" "Custom (choose components)")
    menu_select "Select profile:" "${options[@]}"
    SELECTED_PROFILE=$?
    
    clear_screen
    draw_logo
    
    # Step 3: Component selection (if custom)
    if [ $SELECTED_PROFILE -eq 3 ]; then
        echo -e "${CYAN}${BOLD}Step 3: Select Components${NC}"
        echo ""
        components=(
            "Core Commands (/ship, /bootstrap)"
            "Safety Commands (/fresh, /health)"
            "Git Aliases (gfresh, gsafe, etc.)"
            "Status Lines (git-safety, work-session, pr-health, branch-metrics)"
            "Pre-commit Hooks"
            "Pre-push Hooks"
            "Output Styles"
            "Bash Scripts (health-check, cleanup)"
            "Documentation"
        )
        checkbox_select "Select components to install:" "${components[@]}"
    else
        # Pre-select based on profile
        case $SELECTED_PROFILE in
            0) # Solo Developer
                SELECTED_COMPONENTS=("all")
                ;;
            1) # Team
                SELECTED_COMPONENTS=("core" "hooks" "status")
                ;;
            2) # Minimal
                SELECTED_COMPONENTS=("core")
                ;;
        esac
    fi
    
    clear_screen
    draw_logo
    
    # Step 4: Confirmation
    echo -e "${CYAN}${BOLD}Installation Summary${NC}"
    echo ""
    draw_box 60 10 "Configuration"
    echo -e "${CYAN}${BOX_V}${NC} ${BOLD}Mode:${NC}        $INSTALL_MODE"
    echo -e "${CYAN}${BOX_V}${NC} ${BOLD}Profile:${NC}     ${options[$SELECTED_PROFILE]}"
    echo -e "${CYAN}${BOX_V}${NC} ${BOLD}Components:${NC}  ${#SELECTED_COMPONENTS[@]} selected"
    echo -e "${CYAN}${BOX_BL}"
    for ((i=0; i<58; i++)); do echo -ne "${BOX_H}"; done
    echo -e "${BOX_BR}${NC}"
    echo ""
    
    echo -e "${YELLOW}Proceed with installation? (y/n)${NC}"
    read -n1 confirm
    echo ""
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${RED}Installation cancelled.${NC}"
        exit 0
    fi
    
    # Step 5: Installation with progress
    clear_screen
    draw_logo
    
    echo -e "${CYAN}${BOLD}Installing Han-Solo...${NC}"
    echo ""
    
    # Simulate installation steps with progress bars
    tasks=(
        "Creating directories"
        "Copying commands"
        "Installing agents"
        "Setting up hooks"
        "Installing status lines"
        "Configuring status line"
        "Installing scripts"
        "Updating configuration"
        "Running tests"
    )
    
    for task in "${tasks[@]}"; do
        echo -ne "${PACKAGE} $task..."
        # Simulate work with spinner
        (sleep 1) &
        spinner $!
        echo -e " ${GREEN}${CHECK}${NC}"
        progress_bar 0.5
    done
    
    echo ""
    draw_box 60 8 "Installation Complete!"
    echo -e "${CYAN}${BOX_V}${NC}  ${GREEN}${ROCKET} Han-Solo has been successfully installed!${NC}"
    echo -e "${CYAN}${BOX_V}${NC}"
    echo -e "${CYAN}${BOX_V}${NC}  ${BOLD}Quick Start:${NC}"
    echo -e "${CYAN}${BOX_V}${NC}    ${CYAN}/fresh${NC}  - Start a new feature branch"
    echo -e "${CYAN}${BOX_V}${NC}    ${CYAN}/ship${NC}   - Ship your changes"
    echo -e "${CYAN}${BOX_V}${NC}    ${CYAN}/health${NC} - Check repository health"
    echo -e "${CYAN}${BOX_BL}"
    for ((i=0; i<58; i++)); do echo -ne "${BOX_H}"; done
    echo -e "${BOX_BR}${NC}"
    echo ""
    
    # Final message with typewriter effect
    type_text "${GREEN}${STAR} Happy shipping! May the force be with your commits. ${STAR}${NC}" 0.03
    echo ""
}

# Run main installation
main