#!/usr/bin/env bash
# install.sh — Unified installer for han-solo Claude Code tools
# Works in both interactive (TTY) and non-interactive modes
#
# Usage:
#   # Interactive installation (if TTY available)
#   ./scripts/install.sh
#   
#   # Non-interactive with defaults
#   ./scripts/install.sh --auto
#   
#   # Non-interactive with options
#   ./scripts/install.sh --auto --global --profile solo
#   
#   # Remote installation via curl
#   curl -fsSL https://raw.githubusercontent.com/slamb2k/han-solo/main/scripts/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/slamb2k/han-solo/main/scripts/install.sh | bash -s -- --auto --global

set -Eeuo pipefail

# ============================================================================
# Configuration
# ============================================================================
REPO_USER="${REPO_USER:-slamb2k}"
REPO_NAME="${REPO_NAME:-han-solo}"
TAG="${TAG:-latest}"

# Colors and styles (only used if TTY available)
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
NC='\033[0m'

# Box drawing characters (for interactive mode)
BOX_TL='╔'
BOX_TR='╗'
BOX_BL='╚'
BOX_BR='╝'
BOX_H='═'
BOX_V='║'

# Symbols
CHECK='✅'
CROSS='❌'
ARROW='→'
STAR='⭐'
ROCKET='🚀'
PACKAGE='📦'
TOOLS='🔧'

# ============================================================================
# TTY Detection
# ============================================================================
if [ -t 0 ] && [ -t 1 ]; then
  HAS_TTY=true
else
  HAS_TTY=false
fi

# ============================================================================
# Command Line Parsing
# ============================================================================
INTERACTIVE=""  # Will be set based on TTY and flags
INSTALL_SCOPE="project"
PROFILE="solo"
COMPONENTS=""
RUNNING_REMOTELY=false

# Detect if we're running from curl/remote
if [ -z "${BASH_SOURCE[0]:-}" ] || [ "${BASH_SOURCE[0]}" = "-" ]; then
  RUNNING_REMOTELY=true
  INTERACTIVE=false
fi

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --auto|-a)
      INTERACTIVE=false
      shift
      ;;
    --interactive|-i)
      if [ "$HAS_TTY" = false ]; then
        echo "Error: Interactive mode requires a TTY terminal"
        exit 1
      fi
      INTERACTIVE=true
      shift
      ;;
    --global|-g)
      INSTALL_SCOPE="global"
      shift
      ;;
    --project|-p)
      INSTALL_SCOPE="project"
      shift
      ;;
    --profile)
      PROFILE="$2"
      shift 2
      ;;
    --components)
      COMPONENTS="$2"
      shift 2
      ;;
    --help|-h)
      cat << EOF
han-solo Claude tools unified installer

Usage: $0 [OPTIONS]

Options:
  --auto, -a            Non-interactive installation with defaults
  --interactive, -i     Force interactive mode (requires TTY)
  --global, -g          Install globally to ~/.claude/
  --project, -p         Install to project .claude/ (default)
  --profile PROFILE     Installation profile: solo, team, minimal, custom
  --components LIST     Comma-separated component list (for custom profile)
  --help, -h            Show this help message

Environment variables:
  TAG                   Version to install (default: latest)
  REPO_USER            GitHub username (default: slamb2k)
  REPO_NAME            Repository name (default: han-solo)

Examples:
  # Interactive installation (if TTY available)
  ./scripts/install.sh
  
  # Non-interactive with solo profile
  ./scripts/install.sh --auto --global --profile solo
  
  # Custom components
  ./scripts/install.sh --auto --components "commands,agents,status_lines"
  
  # Remote installation
  curl -fsSL .../install.sh | bash -s -- --auto --global
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Set interactive mode if not explicitly set
if [ -z "$INTERACTIVE" ]; then
  INTERACTIVE=$HAS_TTY
fi

# ============================================================================
# Helper Functions
# ============================================================================

# Print colored output (only if TTY available)
print_color() {
  local color=$1
  shift
  if [ "$HAS_TTY" = true ]; then
    echo -e "${color}$*${NC}"
  else
    echo "$*"
  fi
}

# Check for required tools
require() {
  command -v "$1" >/dev/null 2>&1 || {
    print_color "$RED" "❌ Missing required tool: $1"
    echo "   Please install $1 and try again."
    exit 2
  }
}

# Clear screen (only in interactive mode)
clear_screen() {
  if [ "$INTERACTIVE" = true ] && [ "$HAS_TTY" = true ]; then
    clear
    tput civis 2>/dev/null || true  # Hide cursor
  fi
}

# Show cursor on exit
cleanup() {
  if [ "$HAS_TTY" = true ]; then
    tput cnorm 2>/dev/null || true  # Show cursor
  fi
}
trap cleanup EXIT

# Draw ASCII art logo (interactive mode only)
draw_logo() {
  if [ "$INTERACTIVE" = true ]; then
    print_color "$CYAN" "
    ╦ ╦┌─┐┌┐┌   ╔═╗┌─┐┬  ┌─┐
    ╠═╣├─┤│││───╚═╗│ ││  │ │
    ╩ ╩┴ ┴┘└┘   ╚═╝└─┘┴─┘└─┘
    "
    print_color "$DIM$ITALIC" "    Git Workflow Automation for Solo Developers"
    echo ""
  fi
}

# Simple menu for interactive mode
menu_select() {
  local prompt=$1
  shift
  local options=("$@")
  local selected=0
  
  echo ""
  print_color "$BOLD" "$prompt"
  echo ""
  
  if [ "$INTERACTIVE" = false ]; then
    # Non-interactive: return first option
    return 0
  fi
  
  # Simple numbered menu (easier than arrow keys)
  for i in "${!options[@]}"; do
    echo "  $((i+1)). ${options[$i]}"
  done
  echo ""
  
  while true; do
    read -p "Select (1-${#options[@]}): " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
      return $((choice - 1))
    fi
    echo "Invalid selection. Please enter a number between 1 and ${#options[@]}"
  done
}

# Checkbox selection for components
checkbox_select() {
  local prompt=$1
  shift
  local options=("$@")
  local selected=()
  
  echo ""
  print_color "$BOLD" "$prompt"
  print_color "$DIM" "(Enter numbers separated by spaces, or 'all' for everything)"
  echo ""
  
  if [ "$INTERACTIVE" = false ]; then
    # Non-interactive: select all
    SELECTED_COMPONENTS=("${options[@]}")
    return
  fi
  
  # Display numbered options
  for i in "${!options[@]}"; do
    echo "  $((i+1)). ${options[$i]}"
  done
  echo ""
  
  read -p "Select components: " choices
  
  if [ "$choices" = "all" ]; then
    SELECTED_COMPONENTS=("${options[@]}")
  else
    SELECTED_COMPONENTS=()
    for choice in $choices; do
      if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
        SELECTED_COMPONENTS+=("${options[$((choice-1))]}")
      fi
    done
  fi
}

# Progress indicator
show_progress() {
  local task=$1
  if [ "$HAS_TTY" = true ]; then
    echo -ne "${PACKAGE} $task..."
    # Simple spinner
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    for i in {1..10}; do
      printf "\b${spin:i%10:1}"
      sleep 0.1
    done
    echo -e "\b${CHECK}"
  else
    echo "→ $task"
  fi
}

# ============================================================================
# Remote Installation Functions
# ============================================================================

download_and_extract() {
  local tmpdir="$1"
  local dest="$2"
  
  print_color "$CYAN" "🚀 Downloading han-solo from GitHub..."
  echo "   Repository: ${REPO_USER}/${REPO_NAME}"
  echo "   Version: ${TAG}"
  echo ""
  
  # Fetch release info
  if [ "$TAG" = "latest" ]; then
    API_URL="https://api.github.com/repos/${REPO_USER}/${REPO_NAME}/releases/latest"
  else
    API_URL="https://api.github.com/repos/${REPO_USER}/${REPO_NAME}/releases/tags/${TAG}"
  fi
  
  # Download release metadata
  RELEASE_JSON="${tmpdir}/release.json"
  if ! curl -fsSL "$API_URL" -o "$RELEASE_JSON" 2>/dev/null; then
    print_color "$RED" "❌ Failed to fetch release information"
    exit 1
  fi
  
  # Parse download URL
  DOWNLOAD_URL="$(grep -o '"browser_download_url":[[:space:]]*"[^"]*\.zip"' "$RELEASE_JSON" | cut -d'"' -f4 | head -1)"
  VERSION="$(grep -o '"tag_name":[[:space:]]*"[^"]*"' "$RELEASE_JSON" | cut -d'"' -f4)"
  
  if [ -z "$DOWNLOAD_URL" ]; then
    # No release archive, try to clone instead
    print_color "$YELLOW" "No release archive found, cloning repository..."
    if command -v git >/dev/null 2>&1; then
      git clone --depth 1 "https://github.com/${REPO_USER}/${REPO_NAME}.git" "${tmpdir}/repo"
      cp -r "${tmpdir}/repo/.claude" "$dest/"
      cp -r "${tmpdir}/repo/scripts" "${tmpdir}/"
      return 0
    else
      print_color "$RED" "❌ No release archive and git not available"
      exit 1
    fi
  fi
  
  # Download archive
  ARCHIVE_PATH="${tmpdir}/han-solo.zip"
  echo "→ Downloading ${VERSION}..."
  if ! curl -fsSL "$DOWNLOAD_URL" -o "$ARCHIVE_PATH" --progress-bar; then
    print_color "$RED" "❌ Failed to download release"
    exit 1
  fi
  
  # Extract
  echo "→ Extracting..."
  if ! unzip -q -o "$ARCHIVE_PATH" -d "$dest"; then
    print_color "$RED" "❌ Failed to extract archive"
    exit 1
  fi
  
  # Copy scripts to temp for local execution
  if [ -d "${dest}/scripts" ]; then
    cp -r "${dest}/scripts" "${tmpdir}/"
  fi
}

# ============================================================================
# Installation Functions
# ============================================================================

install_component() {
  local component=$1
  local src_dir=$2
  local dest_dir=$3
  
  case "$component" in
    "commands")
      if [ -d "${src_dir}/.claude/commands" ]; then
        show_progress "Installing commands"
        mkdir -p "${dest_dir}/commands"
        cp -r "${src_dir}/.claude/commands/"* "${dest_dir}/commands/" 2>/dev/null || true
      fi
      ;;
    "agents")
      if [ -d "${src_dir}/.claude/agents" ]; then
        show_progress "Installing agents"
        mkdir -p "${dest_dir}/agents"
        cp -r "${src_dir}/.claude/agents/"* "${dest_dir}/agents/" 2>/dev/null || true
      fi
      ;;
    "status_lines")
      if [ -d "${src_dir}/.claude/status_lines" ]; then
        show_progress "Installing status lines"
        mkdir -p "${dest_dir}/status_lines"
        cp -r "${src_dir}/.claude/status_lines/"* "${dest_dir}/status_lines/" 2>/dev/null || true
        chmod +x "${dest_dir}/status_lines/"*.sh 2>/dev/null || true
      fi
      ;;
    "hooks")
      if [ -d "${src_dir}/hooks" ]; then
        show_progress "Installing git hooks"
        mkdir -p .git/hooks
        cp "${src_dir}/hooks/"* .git/hooks/ 2>/dev/null || true
        chmod +x .git/hooks/* 2>/dev/null || true
      fi
      ;;
    "scripts")
      if [ -d "${src_dir}/scripts" ]; then
        show_progress "Installing utility scripts"
        mkdir -p scripts
        cp "${src_dir}/scripts/"*.sh scripts/ 2>/dev/null || true
        chmod +x scripts/*.sh 2>/dev/null || true
      fi
      ;;
    "aliases")
      show_progress "Configuring git aliases"
      git config --global alias.fresh '!bash -c "$(curl -fsSL https://raw.githubusercontent.com/slamb2k/han-solo/main/scripts/git-fresh.sh)"' 2>/dev/null || true
      git config --global alias.ship '!bash -c "$(curl -fsSL https://raw.githubusercontent.com/slamb2k/han-solo/main/scripts/git-ship.sh)"' 2>/dev/null || true
      ;;
  esac
}

perform_installation() {
  local src_dir=$1
  local dest_dir=$2
  local components=("${@:3}")
  
  print_color "$CYAN" "📦 Installing han-solo components..."
  echo ""
  
  # Create destination
  mkdir -p "$dest_dir"
  
  # Install each component
  for component in "${components[@]}"; do
    install_component "$component" "$src_dir" "$dest_dir"
  done
  
  echo ""
  print_color "$GREEN" "✅ Installation complete!"
}

# ============================================================================
# Main Installation Flow
# ============================================================================

main() {
  # Check prerequisites
  if [ "$RUNNING_REMOTELY" = true ]; then
    require curl
    require unzip
  fi
  
  # Setup temporary directory
  TMPDIR="$(mktemp -d)"
  trap 'rm -rf "$TMPDIR"' EXIT
  
  # Determine source directory
  if [ "$RUNNING_REMOTELY" = true ]; then
    # Download from GitHub
    SRC_DIR="$TMPDIR"
    download_and_extract "$TMPDIR" "$TMPDIR"
  else
    # Use local repository
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    SRC_DIR="$(dirname "$SCRIPT_DIR")"
  fi
  
  # Interactive or auto mode
  if [ "$INTERACTIVE" = true ]; then
    # ========================================
    # Interactive Mode
    # ========================================
    clear_screen
    draw_logo
    
    print_color "$GREEN$BOLD" "Welcome to Han-Solo Interactive Installer!"
    echo ""
    echo "This installer will help you set up git workflow automation tools."
    echo ""
    
    if [ "$HAS_TTY" = true ]; then
      echo "Press Enter to continue..."
      read -r
    fi
    
    # Step 1: Installation scope
    clear_screen
    draw_logo
    
    options=("Project (this repository only)" "Global (all repositories)" "Custom location")
    menu_select "Step 1: Where should han-solo be installed?" "${options[@]}"
    case $? in
      0) INSTALL_SCOPE="project" ;;
      1) INSTALL_SCOPE="global" ;;
      2) 
        read -p "Enter custom path: " CUSTOM_PATH
        INSTALL_SCOPE="custom"
        ;;
    esac
    
    # Step 2: Profile selection
    clear_screen
    draw_logo
    
    options=("Solo Developer (all features)" "Team Workflow (collaborative)" "Minimal (essentials only)" "Custom (choose components)")
    menu_select "Step 2: Select installation profile" "${options[@]}"
    PROFILE_CHOICE=$?
    
    # Step 3: Component selection (if custom)
    if [ $PROFILE_CHOICE -eq 3 ]; then
      clear_screen
      draw_logo
      
      components=("commands" "agents" "status_lines" "hooks" "scripts" "aliases")
      checkbox_select "Step 3: Select components to install" "${components[@]}"
      INSTALL_COMPONENTS=("${SELECTED_COMPONENTS[@]}")
    else
      case $PROFILE_CHOICE in
        0) # Solo
          INSTALL_COMPONENTS=("commands" "agents" "status_lines" "scripts")
          ;;
        1) # Team
          INSTALL_COMPONENTS=("commands" "agents" "hooks")
          ;;
        2) # Minimal
          INSTALL_COMPONENTS=("commands")
          ;;
      esac
    fi
    
    # Step 4: Confirmation
    clear_screen
    draw_logo
    
    print_color "$CYAN$BOLD" "Installation Summary"
    echo ""
    echo "  Scope: $INSTALL_SCOPE"
    echo "  Components: ${#INSTALL_COMPONENTS[@]} selected"
    for comp in "${INSTALL_COMPONENTS[@]}"; do
      echo "    - $comp"
    done
    echo ""
    
    read -p "Proceed with installation? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      print_color "$YELLOW" "Installation cancelled."
      exit 0
    fi
    
  else
    # ========================================
    # Auto Mode
    # ========================================
    print_color "$CYAN" "🚀 Han-Solo Auto Installation"
    echo ""
    
    # Parse profile into components
    case "$PROFILE" in
      solo)
        INSTALL_COMPONENTS=("commands" "agents" "status_lines" "scripts")
        ;;
      team)
        INSTALL_COMPONENTS=("commands" "agents" "hooks")
        ;;
      minimal)
        INSTALL_COMPONENTS=("commands")
        ;;
      custom)
        if [ -z "$COMPONENTS" ]; then
          INSTALL_COMPONENTS=("commands" "agents")
        else
          IFS=',' read -ra INSTALL_COMPONENTS <<< "$COMPONENTS"
        fi
        ;;
      *)
        print_color "$RED" "Unknown profile: $PROFILE"
        exit 1
        ;;
    esac
  fi
  
  # Determine destination directory
  case "$INSTALL_SCOPE" in
    global)
      DEST_DIR="${HOME}/.claude"
      ;;
    project)
      DEST_DIR=".claude"
      ;;
    custom)
      DEST_DIR="${CUSTOM_PATH:-/tmp/.claude}"
      ;;
  esac
  
  # Perform installation
  echo ""
  perform_installation "$SRC_DIR" "$DEST_DIR" "${INSTALL_COMPONENTS[@]}"
  
  # Success message
  echo ""
  print_color "$GREEN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  print_color "$GREEN$BOLD" "  ✅ Han-Solo Installation Complete!"
  print_color "$GREEN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  if [ "$INSTALL_SCOPE" = "global" ]; then
    echo "📍 Location: ~/.claude (global)"
    echo "   Available in all projects"
  else
    echo "📍 Location: $(pwd)/${DEST_DIR} (project)"
    echo "   Available in this project only"
  fi
  
  echo ""
  echo "📦 Installed components:"
  for comp in "${INSTALL_COMPONENTS[@]}"; do
    echo "   ✓ $comp"
  done
  
  echo ""
  print_color "$CYAN$BOLD" "🚀 Next steps:"
  echo "  1. Restart Claude Code or reload the window"
  echo "  2. Run /help to see available commands"
  echo "  3. Run /bootstrap to set up repository governance"
  echo "  4. Run /fresh to start a new feature branch"
  echo ""
  print_color "$DIM" "📚 Documentation: https://github.com/${REPO_USER}/${REPO_NAME}"
  echo ""
}

# Run main installation
main