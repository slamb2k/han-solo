#!/bin/bash

# Configure status line in Claude Code settings
# This script sets up the git-safety status line in settings.toml

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}🔧 Configuring Han-Solo Status Line${NC}"
echo ""

# Determine Claude directory
if [ -d "$HOME/.claude" ]; then
  CLAUDE_DIR="$HOME/.claude"
  SCOPE="global"
elif [ -d ".claude" ]; then
  CLAUDE_DIR=".claude"
  SCOPE="project"
else
  echo -e "${RED}❌ No .claude directory found${NC}"
  echo "Please run the Han-Solo installer first:"
  echo "  npx han-solo-installer"
  exit 1
fi

echo -e "Found Claude directory: ${CYAN}$CLAUDE_DIR${NC} (${SCOPE})"

# Check if status lines are installed
STATUS_LINE_DIR="$CLAUDE_DIR/status_lines"
if [ ! -d "$STATUS_LINE_DIR" ]; then
  echo -e "${RED}❌ Status lines not found in $STATUS_LINE_DIR${NC}"
  echo "Please install status lines using:"
  echo "  npx han-solo-installer"
  exit 1
fi

# Find available status line scripts
echo -e "\n${CYAN}Available status lines:${NC}"
STATUS_LINES=()
for script in "$STATUS_LINE_DIR"/*.sh; do
  if [ -f "$script" ]; then
    basename_script=$(basename "$script")
    STATUS_LINES+=("$basename_script")
    echo "  • $basename_script"
  fi
done

if [ ${#STATUS_LINES[@]} -eq 0 ]; then
  echo -e "${RED}❌ No status line scripts found${NC}"
  exit 1
fi

# Select status line
DEFAULT_STATUS_LINE="git-safety.sh"
SELECTED_STATUS_LINE=""

if [[ " ${STATUS_LINES[@]} " =~ " ${DEFAULT_STATUS_LINE} " ]]; then
  SELECTED_STATUS_LINE="$DEFAULT_STATUS_LINE"
  echo -e "\n${GREEN}✓ Using default: $DEFAULT_STATUS_LINE${NC}"
else
  SELECTED_STATUS_LINE="${STATUS_LINES[0]}"
  echo -e "\n${YELLOW}Using: $SELECTED_STATUS_LINE${NC}"
fi

# Full path to selected status line
STATUS_LINE_PATH="$STATUS_LINE_DIR/$SELECTED_STATUS_LINE"

# Configure settings.json (or settings.local.json for local-only)
# Ask user preference
echo -e "\n${CYAN}Where should the status line be configured?${NC}"
echo "  1. settings.json (shared with team if in git)"
echo "  2. settings.local.json (personal, not in git)"
echo ""
read -p "Select (1 or 2, default=2): " SETTINGS_CHOICE

if [ "$SETTINGS_CHOICE" = "1" ]; then
  SETTINGS_FILE="$CLAUDE_DIR/settings.json"
  echo -e "${GREEN}Using shared settings: settings.json${NC}"
else
  SETTINGS_FILE="$CLAUDE_DIR/settings.local.json"
  echo -e "${GREEN}Using local settings: settings.local.json${NC}"
fi

echo -e "\n${CYAN}Configuring $SETTINGS_FILE...${NC}"

# Backup existing settings if present
if [ -f "$SETTINGS_FILE" ]; then
  cp "$SETTINGS_FILE" "${SETTINGS_FILE}.backup"
  echo -e "${YELLOW}Backed up existing settings to ${SETTINGS_FILE}.backup${NC}"
fi

# Create or update settings.json
if [ -f "$SETTINGS_FILE" ]; then
  # Read existing settings
  EXISTING_SETTINGS=$(cat "$SETTINGS_FILE")
  
  # Check if statusLine already exists
  if echo "$EXISTING_SETTINGS" | grep -q '"statusLine"'; then
    # Update existing statusLine configuration
    echo -e "${YELLOW}Updating existing statusLine configuration...${NC}"
    
    # Use jq if available, otherwise use sed
    if command -v jq &> /dev/null; then
      echo "$EXISTING_SETTINGS" | jq --arg path "$STATUS_LINE_PATH" '.statusLine = {"type": "command", "command": $path}' > "$SETTINGS_FILE"
    else
      # Manual JSON update with sed (less reliable but works)
      TEMP_FILE="${SETTINGS_FILE}.tmp"
      echo "$EXISTING_SETTINGS" | sed -E '/"statusLine"[[:space:]]*:[[:space:]]*\{[^}]*\}/c\
  "statusLine": {\
    "type": "command",\
    "command": "'"$STATUS_LINE_PATH"'"\
  }' > "$TEMP_FILE"
      mv "$TEMP_FILE" "$SETTINGS_FILE"
    fi
  else
    # Add statusLine to existing settings
    echo -e "${GREEN}Adding statusLine configuration...${NC}"
    
    if command -v jq &> /dev/null; then
      echo "$EXISTING_SETTINGS" | jq --arg path "$STATUS_LINE_PATH" '. + {"statusLine": {"type": "command", "command": $path}}' > "$SETTINGS_FILE"
    else
      # Manual addition (add before last closing brace)
      TEMP_FILE="${SETTINGS_FILE}.tmp"
      echo "$EXISTING_SETTINGS" | sed '$ s/}$/,\
  "statusLine": {\
    "type": "command",\
    "command": "'"$STATUS_LINE_PATH"'"\
  }\
}/' > "$TEMP_FILE"
      mv "$TEMP_FILE" "$SETTINGS_FILE"
    fi
  fi
else
  # Create new settings.json
  echo -e "${GREEN}Creating new settings.json...${NC}"
  cat > "$SETTINGS_FILE" << EOF
{
  "statusLine": {
    "type": "command",
    "command": "$STATUS_LINE_PATH"
  }
}
EOF
fi

# Make status line executable
chmod +x "$STATUS_LINE_PATH" 2>/dev/null || true

# Success message
echo ""
echo -e "${GREEN}✅ Status line configured successfully!${NC}"
echo ""
echo -e "${CYAN}Configuration:${NC}"
echo "  Settings file: $SETTINGS_FILE"
echo "  Status line: $SELECTED_STATUS_LINE"
echo "  Full path: $STATUS_LINE_PATH"
echo ""
echo -e "${YELLOW}💡 Next steps:${NC}"
echo "  1. Restart Claude Code or reload the window"
echo "  2. The status line will appear in your terminal"
echo "  3. To change status lines, edit: $SETTINGS_FILE"
echo ""
echo -e "${CYAN}Available status lines:${NC}"
echo "  • git-safety.sh - Branch safety and PR status"
echo "  • work-session.sh - Session time and productivity"
echo "  • pr-health.sh - Detailed PR and CI status"
echo "  • branch-metrics.sh - Branch statistics"
echo ""

exit 0