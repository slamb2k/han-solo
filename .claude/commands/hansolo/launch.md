---
description: "Create new feature branch from updated main"
argument_hint: "<feature-name>"
---

# /hansolo:launch

Invoke the han-solo-gold-squadron subagent to create a new feature branch named 'feature/$1'.

The subagent MUST:
1. Check current branch status and notify if on main
2. Ensure the main branch is synced with remote
3. Create new branch from latest main
4. Switch to the new feature branch

If no feature name provided, prompt user for the feature name.