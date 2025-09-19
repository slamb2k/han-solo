---
description: "Create new feature branch from updated main"
argument_hint: "<feature-name>"
---

# /hansolo:launch

## Setup and JSON Mode Detection

```bash
# Source the branch operations script for actual execution
source .claude/lib/operations/branch-operations.sh

# Check for JSON mode
JSON_MODE=false
if [[ "$1" == "--json" ]]; then
    JSON_MODE=true
    shift  # Remove --json flag from arguments
fi

# Store feature name
FEATURE_NAME="$1"
```

## Squadron Identity Display

If NOT in JSON mode, display squadron identity:

**Gold Leader, standing by...**

```
██╗      █████╗ ██╗   ██╗███╗   ██╗ ██████╗██╗  ██╗██╗███╗   ██╗ ██████╗
██║     ██╔══██╗██║   ██║████╗  ██║██╔════╝██║  ██║██║████╗  ██║██╔════╝
██║     ███████║██║   ██║██╔██╗ ██║██║     ███████║██║██╔██╗ ██║██║  ███╗
██║     ██╔══██║██║   ██║██║╚██╗██║██║     ██╔══██║██║██║╚██╗██║██║   ██║
███████╗██║  ██║╚██████╔╝██║ ╚████║╚██████╗██║  ██║██║██║ ╚████║╚██████╔╝
╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝
```

## Branch Creation Execution

### Handle Input Cases

1. **No input provided** - Prompt for branch name (if not JSON mode):
```bash
if [[ -z "$FEATURE_NAME" ]] && [[ "$JSON_MODE" != "true" ]]; then
    echo "Enter branch name (respond with one of the following):"
    echo "  • Natural language description: \"bug fixes to authentication\""
    echo "  • Explicit branch name: \"fix/auth-validation\" or \"feature/new-login\""
    echo "  • Single '*' character for auto-generation based on your changes"
    echo ""

    # Wait for user input
    read -r FEATURE_NAME
fi
```

2. **JSON mode with no input** - Return awaiting_input response:
```bash
if [[ -z "$FEATURE_NAME" ]] && [[ "$JSON_MODE" == "true" ]]; then
    cat <<EOF
{
    "squadron": {
        "name": "gold",
        "quote": "Gold Leader, standing by...",
        "banner_type": "LAUNCHING"
    },
    "status": "awaiting_input",
    "display": {
        "prompt": "Enter branch name (natural language or explicit format)"
    }
}
EOF
    exit 0
fi
```

### Execute Branch Creation

Use the operations script for ACTUAL branch creation:
```bash
# The operations script handles:
# - Auto-generation if FEATURE_NAME is "*" or empty
# - Natural language parsing
# - Actual git commands
# - JSON response formatting

create_feature_branch "$FEATURE_NAME" "$JSON_MODE"
EXIT_CODE=$?

# Exit with the same code as the operation
exit $EXIT_CODE
```

## What This Command Actually Does

1. **Sources real shell script** - Uses `.claude/lib/operations/branch-operations.sh`
2. **Executes real git commands** - No agent invocation, direct execution
3. **Returns real results** - JSON based on actual branch creation
4. **Handles all input modes** - Natural language, explicit names, auto-generation

## Benefits Over Agent Approach

- ✅ **Guaranteed execution** - Shell script always runs
- ✅ **Real results** - JSON contains actual branch names
- ✅ **Testable** - Can verify with `git branch --show-current`
- ✅ **Fast** - No Task tool overhead
- ✅ **Reliable** - No interpretation issues

## Gold Squadron Role (Future)

Gold Squadron agent can still be invoked for complex scenarios requiring reasoning:
- Conflict resolution guidance
- Branch naming suggestions based on complex context
- Merge strategy recommendations

But for basic branch creation, we use direct execution.