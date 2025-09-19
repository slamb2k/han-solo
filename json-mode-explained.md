# JSON Mode in han-solo: How It Should Work

## Overview
JSON mode enables structured communication between commands and agents, allowing command chaining without redundant UI displays.

## Core Principle
**JSON mode changes OUTPUT format, not EXECUTION behavior**. Agents must always execute their tasks, whether in JSON mode or not.

## Communication Flow

### 1. Command Chaining
```
User → /hansolo:ship
         ↓
     Ship detects need for branch
         ↓
     Ship → /hansolo:launch --json
         ↓
     Launch → Gold Squadron (JSON_MODE=true)
         ↓
     Gold Squadron executes & returns JSON
         ↓
     Launch returns JSON to Ship
         ↓
     Ship parses JSON and continues
```

### 2. Agent Behavior

#### Correct (What Should Happen)
```
Prompt: "Create branch. JSON_MODE=true"
         ↓
Agent: 1. EXECUTE git commands with Bash tool
       2. CAPTURE actual results
       3. RETURN JSON with real data
```

#### Current Bug (What's Happening)
```
Prompt: "Create branch. JSON_MODE=true"
         ↓
Agent: 1. DISPLAY bash commands in markdown
       2. SKIP actual execution
       3. RETURN JSON with hypothetical data
```

## JSON Response Structure

### Success Response
```json
{
    "squadron": {
        "name": "gold",
        "quote": "Gold Leader, standing by...",
        "banner_type": "LAUNCHING"
    },
    "status": "completed",
    "data": {
        "branch_created": "feat/actual-branch-name",
        "previous_branch": "main"
    }
}
```

### Key Points
- `status`: Based on ACTUAL execution results
- `data`: Contains REAL values from executed commands
- Squadron identity preserved for UI consistency

## Use Cases

### 1. Ship → Launch Integration
- Ship on main needs feature branch
- Calls launch with --json to avoid double banners
- Gets structured response to know branch name
- Continues with PR creation

### 2. Ship → Sync Integration
- Ship monitors PR until merged
- Calls sync to cleanup
- Parses response to confirm cleanup
- Reports complete workflow to user

### 3. Error Handling
```json
{
    "squadron": {
        "name": "red",
        "quote": "Red Leader, standing by..."
    },
    "status": "error",
    "error": {
        "code": "PR_EXISTS",
        "message": "PR already exists for this branch"
    }
}
```

## Implementation Requirements

### For Agents
1. **MUST execute commands** using Bash tool
2. **MUST capture real results** from execution
3. **MUST return accurate JSON** based on what actually happened
4. **MUST handle errors** and report them in JSON

### For Commands
1. **Check for --json flag** in arguments
2. **Pass JSON_MODE to agents** when needed
3. **Parse JSON responses** for command chaining
4. **Display UI appropriately** based on mode

## Testing JSON Mode

### Test 1: Direct Agent Invocation
```bash
# Should create actual branch AND return JSON
Task(subagent="gold-squadron", prompt="Create branch. JSON_MODE=true")
```

### Test 2: Command Chain
```bash
# Should create branch, PR, monitor, and cleanup
/hansolo:ship  # From main with changes
```

### Test 3: Error Scenarios
```bash
# Should return error JSON without partial execution
/hansolo:ship  # With existing PR
```

## Common Issues

### Issue 1: Agents Not Executing
**Symptom**: JSON returned but no actual changes made
**Cause**: Agent displaying commands instead of executing
**Fix**: Ensure all agents use Bash tool for execution

### Issue 2: Banner Truncation
**Symptom**: Banners cut off in command chains
**Cause**: Multiple commands displaying banners
**Fix**: Use JSON mode to suppress intermediate banners

### Issue 3: Lost Context
**Symptom**: Chained command doesn't know previous state
**Cause**: Not parsing JSON response properly
**Fix**: Extract and use data from JSON responses

## Summary
JSON mode is about **structured communication**, not deferred execution. Agents must do their work immediately and report real results in JSON format. This enables seamless command chaining while maintaining the squadron theming for user-facing interactions.