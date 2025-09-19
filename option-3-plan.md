# Option 3: JSON Output Implementation Plan

## Problem Statement

When han-solo commands invoke other commands via Bash (e.g., `/hansolo:ship` calling `/hansolo:launch`), ASCII art banners get truncated or mangled in the Bash output. This creates a poor user experience and breaks the visual design of the workflow.

### Current Issues
1. `claude /hansolo:launch` via Bash truncates the LAUNCHING banner
2. No way to invoke slash commands internally without Bash
3. Display output must pass through the calling tool
4. Testing is difficult with unstructured text output

## Solution: Structured JSON Communication

Commands and agents will support a `--json` flag that returns structured JSON instead of human-readable output. Calling commands can parse this JSON to:
- Extract and display banners directly (avoiding Bash truncation)
- Handle interactive prompts programmatically
- Maintain command encapsulation
- Enable comprehensive testing

## Implementation Strategy

### Phase 1: Core JSON Support

#### 1.1 Add JSON Flag Detection
All commands check for `--json` in arguments:
```bash
JSON_MODE=false
if [[ "$1" == "--json" ]]; then
  JSON_MODE=true
fi
```

#### 1.2 Modify Agent Responses
Agents return JSON when invoked in JSON mode:
```json
{
  "display": {
    "banner": "██╗      █████╗ ██╗   ██╗███╗   ██╗...",
    "message": "Enter branch name (respond with one of the following)..."
  },
  "status": "awaiting_input",
  "data": {
    "current_branch": "main",
    "has_uncommitted": true
  }
}
```

### Phase 2: Command Updates

#### 2.1 Update launch.md
```markdown
# /hansolo:launch

If --json flag present:
  Set JSON_MODE=true
  Skip banner display

Invoke Gold Squadron with mode:
  Task(subagent_type="hansolo-gold-squadron",
       prompt="Create branch. JSON_MODE=${JSON_MODE}")

If JSON_MODE:
  Output agent response directly
Else:
  Display banner and handle interactively
```

#### 2.2 Update ship.md
```markdown
# /hansolo:ship

When needing to launch:
  # Get JSON response
  LAUNCH_JSON=$(claude /hansolo:launch --json)

  # Extract display elements
  BANNER=$(echo "$LAUNCH_JSON" | jq -r '.display.banner')
  MESSAGE=$(echo "$LAUNCH_JSON" | jq -r '.display.message')
  STATUS=$(echo "$LAUNCH_JSON" | jq -r '.status')

  # Display banner directly to user (no Bash truncation!)
  Display: $BANNER
  Display: $MESSAGE

  # Handle based on status
  if [[ "$STATUS" == "awaiting_input" ]]; then
    # Get user input
    # Continue with branch name
  fi
```

### Phase 3: Testing Framework

#### 3.1 Test Structure
```bash
#!/bin/bash
# test-hansolo-json.sh

test_launch_json_schema() {
  output=$(claude /hansolo:launch --json <<< "feature/test")

  # Validate required fields
  echo "$output" | jq -e '.display.banner' || fail "Missing banner"
  echo "$output" | jq -e '.status' || fail "Missing status"
  echo "$output" | jq -e '.data' || fail "Missing data"
}

test_ship_json_integration() {
  output=$(claude /hansolo:ship --json)

  # Validate PR creation
  pr_number=$(echo "$output" | jq -r '.pr.number')
  [[ "$pr_number" =~ ^[0-9]+$ ]] || fail "Invalid PR number"
}
```

## JSON Schema Definitions

### Launch Command Response
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["status", "display"],
  "properties": {
    "status": {
      "type": "string",
      "enum": ["awaiting_input", "branch_created", "error"]
    },
    "display": {
      "type": "object",
      "properties": {
        "banner": {"type": "string"},
        "message": {"type": "string"}
      }
    },
    "data": {
      "type": "object",
      "properties": {
        "branch_name": {"type": "string"},
        "previous_branch": {"type": "string"},
        "uncommitted_changes": {"type": "boolean"}
      }
    },
    "error": {
      "type": "object",
      "properties": {
        "code": {"type": "string"},
        "message": {"type": "string"}
      }
    }
  }
}
```

### Ship Command Response
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["status"],
  "properties": {
    "status": {
      "type": "string",
      "enum": ["needs_branch", "creating_pr", "pr_created", "merged", "error"]
    },
    "pr": {
      "type": "object",
      "properties": {
        "number": {"type": "integer"},
        "url": {"type": "string"},
        "state": {"type": "string"}
      }
    },
    "display": {
      "type": "object",
      "properties": {
        "banner": {"type": "string"},
        "message": {"type": "string"}
      }
    }
  }
}
```

## Example Implementation

### launch.md with JSON support
```bash
# Check for JSON mode
if [[ "$1" == "--json" ]]; then
  shift  # Remove --json from arguments
  JSON_MODE=true
else
  JSON_MODE=false
fi

# Display banner in human mode only
if [[ "$JSON_MODE" == "false" ]]; then
  cat << 'EOF'
██╗      █████╗ ██╗   ██╗███╗   ██╗ ██████╗██╗  ██╗██╗███╗   ██╗ ██████╗
[... rest of banner ...]
EOF
fi

# Invoke Gold Squadron
RESPONSE=$(Task "hansolo-gold-squadron" "Create branch JSON_MODE=$JSON_MODE")

# Output based on mode
if [[ "$JSON_MODE" == "true" ]]; then
  echo "$RESPONSE"  # Pass through JSON
else
  # Parse and display for humans
  echo "Branch created successfully!"
fi
```

### ship.md parsing JSON
```bash
# Need to launch a new branch
if [[ "$NEEDS_BRANCH" == "true" ]]; then
  # Get JSON response from launch
  LAUNCH_JSON=$(claude /hansolo:launch --json)

  # Extract banner and display directly
  BANNER=$(echo "$LAUNCH_JSON" | jq -r '.display.banner // empty')
  if [[ -n "$BANNER" ]]; then
    echo "$BANNER"  # Direct display, no Bash truncation!
  fi

  # Extract and show message
  MESSAGE=$(echo "$LAUNCH_JSON" | jq -r '.display.message // empty')
  if [[ -n "$MESSAGE" ]]; then
    echo "$MESSAGE"
  fi

  # Handle interaction based on status
  STATUS=$(echo "$LAUNCH_JSON" | jq -r '.status')
  case "$STATUS" in
    "awaiting_input")
      read -r USER_INPUT
      # Continue with branch creation using input
      ;;
    "branch_created")
      BRANCH=$(echo "$LAUNCH_JSON" | jq -r '.data.branch_name')
      echo "Switched to branch: $BRANCH"
      ;;
    "error")
      ERROR_MSG=$(echo "$LAUNCH_JSON" | jq -r '.error.message')
      echo "Error: $ERROR_MSG"
      exit 1
      ;;
  esac
fi
```

## Migration Path

### Phase 1: Add JSON Support (Backward Compatible)
1. Add `--json` flag handling to all commands
2. Agents detect JSON_MODE and respond accordingly
3. Existing usage continues to work unchanged

### Phase 2: Update Internal Calls
1. Modify ship.md to use `--json` when calling launch
2. Update other inter-command calls to use JSON
3. Test thoroughly with both modes

### Phase 3: Enhanced Features
1. Add JSON schema validation
2. Implement comprehensive test suite
3. Add `--output-format` with options: text, json, yaml

### Rollback Strategy
If issues arise:
1. Remove `--json` flag usage from internal calls
2. Revert to direct command execution
3. JSON mode remains available for testing

## Benefits Analysis

### Testing Improvements
- **Predictable Output**: JSON structure is deterministic
- **Schema Validation**: Automated validation against schemas
- **Easy Assertions**: Use `jq` for precise field checks
- **Mock Responses**: Trivial to create test fixtures

### User Experience
- **Perfect Banners**: No truncation or mangling
- **Consistent Display**: Calling command controls presentation
- **Better Errors**: Structured error messages with codes

### Development Benefits
- **Debugging**: Clear data flow between commands
- **Extensibility**: Easy to add new fields
- **Documentation**: Schema serves as documentation
- **Versioning**: Can version schemas for compatibility

### Example Test Suite
```bash
# Comprehensive test with JSON validation
test_full_workflow() {
  # Test launch JSON output
  launch_json=$(echo "feature/test" | claude /hansolo:launch --json)
  echo "$launch_json" | jq empty || fail "Invalid JSON from launch"

  # Validate against schema
  echo "$launch_json" | jsonschema -F launch-schema.json || fail "Schema violation"

  # Test ship JSON output
  ship_json=$(claude /hansolo:ship --json)
  pr_number=$(echo "$ship_json" | jq -r '.pr.number')

  # Assert PR was created
  [[ -n "$pr_number" ]] || fail "No PR number in response"

  # Validate complete workflow
  final_status=$(echo "$ship_json" | jq -r '.status')
  [[ "$final_status" == "pr_created" ]] || fail "Unexpected status: $final_status"
}
```

## Implementation Timeline

1. **Week 1**: Add JSON flag support to Gold Squadron and launch.md
2. **Week 2**: Update Red Squadron and ship.md to use JSON
3. **Week 3**: Create test suite and schema validation
4. **Week 4**: Update remaining commands and documentation

## Success Criteria

1. ✅ Banners display perfectly when commands call each other
2. ✅ All commands support `--json` flag
3. ✅ Comprehensive test suite using JSON output
4. ✅ Zero regression in existing functionality
5. ✅ Documentation includes JSON schemas

## Next Steps

1. Ship current squadron swap changes
2. Implement Phase 1 (JSON flag support) in Gold Squadron
3. Test launch.md with `--json` flag
4. Update ship.md to parse JSON responses
5. Create automated test suite

---

*This plan preserves our JSON implementation strategy while we ship the current squadron file swaps.*