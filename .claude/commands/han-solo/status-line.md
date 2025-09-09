---
name: /han-solo:status-line
description: Switch between different status line modes or enable smart auto-switching
requires_args: false
argument-hint: "[smart|safety|work|pr|metrics|current|help]"
allowed_tools:
  - Bash
  - Read
  - Edit
  - Write
---

## Purpose
Control which status line is displayed in your terminal. Choose between smart auto-switching mode or manually select a specific status line for your current workflow needs.

## Usage
```bash
# Enable smart auto-switching (recommended)
/status-line smart

# Manually select a specific status line
/status-line safety    # Git safety warnings
/status-line work      # Work session tracking
/status-line pr        # PR and CI monitoring
/status-line metrics   # Branch size metrics

# Show current status line
/status-line current

# Show help
/status-line help
```

## Status Line Modes

### 🧠 Smart Mode (Default)
Automatically switches between status lines based on context:
- **Has open PR** → Shows PR health and CI status
- **On main branch** → Shows safety warnings
- **Recent commits** → Shows work session tracking
- **Large branch** → Shows branch metrics
- **Otherwise** → Shows git safety status

### 🛡️ Safety Mode
Shows git safety warnings and sync status. Best for general development.

### 💼 Work Mode
Tracks your current coding session with productivity metrics.

### 🎯 PR Mode
Monitors PR status, CI checks, and review approvals.

### 📊 Metrics Mode
Displays branch statistics and size warnings.

## Implementation
```bash
#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# Get the command argument
MODE="${1:-help}"

# Settings file path
SETTINGS_FILE=".claude/settings.local.json"

# Status line paths
STATUS_LINE_DIR=".claude/status_lines"
SMART_LINE="$STATUS_LINE_DIR/status-line-smart.sh"
SAFETY_LINE="$STATUS_LINE_DIR/git-safety.sh"
WORK_LINE="$STATUS_LINE_DIR/work-session.sh"
PR_LINE="$STATUS_LINE_DIR/pr-health.sh"
METRICS_LINE="$STATUS_LINE_DIR/branch-metrics.sh"

# Function to update settings file
update_status_line() {
  local script_path="$1"
  local mode_name="$2"
  
  # Ensure settings file exists
  if [ ! -f "$SETTINGS_FILE" ]; then
    echo "{}" > "$SETTINGS_FILE"
  fi
  
  # Update the status line setting using a temp file
  local tmp_file=$(mktemp)
  if command -v jq &> /dev/null; then
    jq --arg path "$script_path" '.statusLine = {"type": "command", "command": $path, "padding": 0}' "$SETTINGS_FILE" > "$tmp_file"
    mv "$tmp_file" "$SETTINGS_FILE"
  else
    # Fallback to simple replacement if jq is not available
    cat > "$tmp_file" << EOF
{
  "statusLine": {
    "type": "command",
    "command": "$script_path",
    "padding": 0
  }
}
EOF
    mv "$tmp_file" "$SETTINGS_FILE"
  fi
  
  echo -e "${GREEN}✅ Status line switched to: ${CYAN}$mode_name${NC}"
}

# Show current status line
show_current() {
  if [ -f "$SETTINGS_FILE" ]; then
    CURRENT=$(grep -oP '"command":\s*"[^"]*' "$SETTINGS_FILE" 2>/dev/null | cut -d'"' -f4 || echo "none")
    case "$CURRENT" in
      *smart*) echo -e "${CYAN}Current mode: ${GREEN}Smart (auto-switching)${NC}" ;;
      *git-safety*) echo -e "${CYAN}Current mode: ${GREEN}Safety${NC}" ;;
      *work-session*) echo -e "${CYAN}Current mode: ${GREEN}Work Session${NC}" ;;
      *pr-health*) echo -e "${CYAN}Current mode: ${GREEN}PR Health${NC}" ;;
      *branch-metrics*) echo -e "${CYAN}Current mode: ${GREEN}Branch Metrics${NC}" ;;
      *) echo -e "${CYAN}Current mode: ${YELLOW}Unknown${NC}" ;;
    esac
  else
    echo -e "${YELLOW}No status line configured${NC}"
  fi
}

# Show help
show_help() {
  echo -e "${CYAN}Han-Solo Status Line Switcher${NC}"
  echo ""
  echo "Usage: /status-line [mode]"
  echo ""
  echo "Modes:"
  echo -e "  ${GREEN}smart${NC}    - 🧠 Auto-switch based on context (recommended)"
  echo -e "  ${GREEN}safety${NC}   - 🛡️  Git safety warnings and sync status"
  echo -e "  ${GREEN}work${NC}     - 💼 Work session tracking and productivity"
  echo -e "  ${GREEN}pr${NC}       - 🎯 PR health and CI check monitoring"
  echo -e "  ${GREEN}metrics${NC}  - 📊 Branch statistics and size metrics"
  echo -e "  ${GREEN}current${NC}  - Show current status line mode"
  echo -e "  ${GREEN}help${NC}     - Show this help message"
  echo ""
  echo "Smart mode automatically switches between status lines:"
  echo "  • Open PR → PR health"
  echo "  • On main → Safety warnings"
  echo "  • Recent activity → Work session"
  echo "  • Large branch → Branch metrics"
  echo "  • Default → Git safety"
}

# Main logic
case "$MODE" in
  smart)
    update_status_line "$SMART_LINE" "Smart (auto-switching)"
    echo -e "${CYAN}Smart mode will automatically switch based on your context.${NC}"
    ;;
  safety)
    update_status_line "$SAFETY_LINE" "Git Safety"
    echo -e "${CYAN}Showing git safety warnings and sync status.${NC}"
    ;;
  work)
    update_status_line "$WORK_LINE" "Work Session"
    echo -e "${CYAN}Tracking your coding session and productivity.${NC}"
    ;;
  pr)
    update_status_line "$PR_LINE" "PR Health"
    echo -e "${CYAN}Monitoring PR status and CI checks.${NC}"
    ;;
  metrics)
    update_status_line "$METRICS_LINE" "Branch Metrics"
    echo -e "${CYAN}Displaying branch statistics and size metrics.${NC}"
    ;;
  current)
    show_current
    ;;
  help|*)
    show_help
    ;;
esac
```

## Examples

### Smart Auto-Switching
```bash
/status-line smart
# Status line now automatically switches based on context
```

### Focus on PR Work
```bash
/status-line pr
# Always shows PR and CI status while working on feedback
```

### Track Productivity
```bash
/status-line work
# Shows session duration and changes made
```

### Monitor Branch Size
```bash
/status-line metrics
# Keep an eye on branch complexity before shipping
```

## Success Indicators
- Settings file updated successfully
- Status line changes visible in terminal
- Appropriate mode selected for current work

## Related Commands
- `/fresh` - Start new work with clean branch
- `/ship` - Ship your changes
- `/health` - Check repository health

## Best Practices
1. Use **smart mode** for general development
2. Switch to **pr mode** when addressing PR feedback
3. Use **work mode** for time tracking
4. Check **metrics mode** before shipping large changes