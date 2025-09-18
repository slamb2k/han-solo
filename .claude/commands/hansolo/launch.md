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

If no feature name provided, prompt user for the feature name. If they describe a bug, chore or docs type work then use the appropriate name instead. i.e. bug/user-fix, chore/spelling-correct, docs/added-readme. If theydon't provide anything (i.e. They just hit enter) then auto-generate feature branch name from latest commit or timestamp.

## Auto-Generated Branch Names

When a new branch is needed, automatically generate name using:
```bash
# From latest commit subject (sanitized)
LAST_COMMIT=$(git log -1 --pretty=%s | sed 's/[^a-zA-Z0-9-]/-/g' | cut -c1-30)
BRANCH_NAME="feature/${LAST_COMMIT}-$(date +%s)"

# Or simple timestamp-based
BRANCH_NAME="feature/ship-$(date +%Y%m%d-%H%M%S)"
```