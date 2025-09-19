# Agent Execution Fix Analysis

## Root Cause
The squadron agents (Gold, Red, etc.) are Claude Code subagents that receive instructions via markdown files. When these agents receive prompts like "Create branch X", they're interpreting the instructions to SHOW bash commands rather than EXECUTE them.

## The Problem Pattern
Current agent behavior:
1. Receives: "Create branch feat/test"
2. Shows: `<bash>git switch -c feat/test</bash>`
3. Returns: JSON saying branch was created
4. Reality: No branch was actually created

## Why Current Instructions Don't Work
Even with explicit instructions like:
- "YOU MUST EXECUTE COMMANDS, NOT DISPLAY THEM"
- "USE THE BASH TOOL"
- "NEVER show bash commands in markdown code blocks"

The agents still display commands because:
1. The `<bash>` tags look like a special syntax for execution
2. The agents interpret this as a way to show what they're doing
3. The Task tool invocation doesn't properly trigger tool use

## Potential Solutions

### Solution 1: Explicit Tool Use Format
Instead of:
```
USE BASH TOOL: git switch -c branch
```

Use:
```
EXECUTE WITH BASH TOOL:
Tool: Bash
Command: git switch -c branch
Description: Create and switch to new branch
```

### Solution 2: Step-by-Step Execution
Break down into explicit steps:
```
STEP 1: Execute Bash tool with command "git branch --show-current"
STEP 2: Capture output in variable CURRENT_BRANCH
STEP 3: Execute Bash tool with command "git switch -c feat/new"
STEP 4: Execute Bash tool with command "git branch --show-current"
STEP 5: Capture output in variable NEW_BRANCH
STEP 6: Return JSON with NEW_BRANCH value
```

### Solution 3: Direct Command Execution
Instead of using Task tool to invoke agents, have commands directly execute bash and format responses:

```bash
# In /hansolo:launch
git switch -c "$BRANCH_NAME"
if [ "$JSON_MODE" = true ]; then
    echo "{\"branch_created\": \"$BRANCH_NAME\"}"
fi
```

### Solution 4: Agent Instruction Rewrite
Completely rewrite agent instructions to be unambiguous:

```markdown
When you receive this prompt, you MUST:

1. Use the Bash tool (not markdown code blocks)
2. Actually execute the command
3. Wait for the result
4. Return the actual result

DO NOT:
- Show bash commands in any format
- Use <bash> tags
- Display markdown code blocks
- Simulate or pretend to execute
```

## Recommended Approach
The most reliable solution is likely **Solution 3** - have the commands themselves execute the necessary bash commands and only use agents for complex logic that requires Claude's reasoning capabilities.

For simpler operations like branch creation, the command can directly:
1. Run git commands
2. Format JSON responses
3. Handle errors

This avoids the agent execution problem entirely for basic operations while still allowing agents to handle complex scenarios like conflict resolution or PR description generation.

## Test Case
To verify any fix works:
1. Start on main branch
2. Run command that should create branch
3. Check with `git branch --show-current`
4. Branch should actually exist, not just in JSON response