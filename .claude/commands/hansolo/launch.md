---
description: "Create new feature branch from updated main"
argument_hint: "<feature-name>"
---

# /hansolo:launch

Inform the user by outputting:
```
Creating a new feature branch...

██╗      █████╗ ██╗   ██╗███╗   ██╗ ██████╗██╗  ██╗██╗███╗   ██╗ ██████╗ 
██║     ██╔══██╗██║   ██║████╗  ██║██╔════╝██║  ██║██║████╗  ██║██╔════╝ 
██║     ███████║██║   ██║██╔██╗ ██║██║     ███████║██║██╔██╗ ██║██║  ███╗
██║     ██╔══██║██║   ██║██║╚██╗██║██║     ██╔══██║██║██║╚██╗██║██║   ██║
███████╗██║  ██║╚██████╔╝██║ ╚████║╚██████╗██║  ██║██║██║ ╚████║╚██████╔╝
╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ 
```
Invoke the han-solo-gold-squadron subagent to create a new feature branch named 'feature/$1'.

The subagent MUST:
1. Check current branch status and notify if on main
2. Ensure the main branch is synced with remote
3. Create new branch from latest main
4. Switch to the new feature branch

If no feature name provided, prompt the user with:

```
Enter branch name (respond with one of the following):
  • Natural language description: "bug fixes to authentication"
  • Explicit branch name: "fix/auth-validation" or "feature/new-login"
  • Single '*' character for auto-generation based on your changes
```

Handle the user's response:
1. **Natural language or explicit branch name** - Pass it directly to Gold Squadron
2. **'*' character** - Do NOT pass anything to Gold Squadron; the absence of input triggers auto-generation

The Gold Squadron agent will:
- Parse natural language (e.g., "bug fixes to auth" → `fix/auth`)
- Use explicit branch names as-is (with type detection)
- Auto-generate when no input is provided, using this priority:
  1. From uncommitted changes
  2. From unshipped commits
  3. Timestamp fallback if all commits are shipped