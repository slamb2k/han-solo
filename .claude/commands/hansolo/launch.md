---
description: "Create new feature branch from updated main"
argument_hint: "<feature-name>"
---

# /hansolo:launch

## Squadron Identity & JSON Mode Detection

First, check for JSON mode:
```bash
JSON_MODE=false
if [[ "$1" == "--json" ]]; then
    JSON_MODE=true
    shift  # Remove --json flag from arguments
fi
```

If NOT in JSON mode, display squadron identity:
```
echo ""
echo "Gold Leader, standing by..."
echo ""
cat .claude/lib/banners/launching.txt
echo ""
```

## Invoke Gold Squadron

Invoke the hansolo-gold-squadron subagent to create a new feature branch.

Pass the JSON_MODE flag to the agent:
```
Task(subagent_type="hansolo-gold-squadron",
     prompt="Create feature branch. JSON_MODE=$JSON_MODE. Feature: $1")
```

The subagent MUST:
1. Check current branch status and notify if on main
2. Ensure the main branch is synced with remote
3. Create new branch from latest main
4. Switch to the new feature branch

If no feature name provided and NOT in JSON mode, prompt the user with:

```
Enter branch name (respond with one of the following):
  • Natural language description: "bug fixes to authentication"
  • Explicit branch name: "fix/auth-validation" or "feature/new-login"
  • Single '*' character for auto-generation based on your changes
```

Handle the user's response:
1. **Natural language or explicit branch name** - Pass it directly to Gold Squadron
2. **'*' character** - Do NOT pass anything to Gold Squadron; the absence of input triggers auto-generation

If in JSON mode and no feature name:
- Return JSON response with status "awaiting_input"
- Include prompt in display.prompt field

## Gold Squadron Responsibilities

The Gold Squadron agent will:
- Parse natural language (e.g., "bug fixes to auth" → `fix/auth`)
- Use explicit branch names as-is (with type detection)
- Auto-generate when no input is provided, using this priority:
  1. From uncommitted changes
  2. From unshipped commits
  3. Timestamp fallback if all commits are shipped

If JSON_MODE=true, Gold Squadron returns:
```json
{
  "squadron": {
    "name": "gold",
    "quote": "Gold Leader, standing by...",
    "banner_type": "LAUNCHING"
  },
  "status": "completed",
  "data": {
    "branch_created": "feature/branch-name",
    "previous_branch": "main"
  }
}
```