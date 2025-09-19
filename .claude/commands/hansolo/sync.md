---
description: "Sync feature branch with latest main"
---

# /hansolo:sync

Invoke the hansolo-gold-squadron subagent to synchronize the current feature branch with main.

The subagent will:
1. Fetch latest changes from origin
2. Rebase current branch onto origin/main
3. Handle any conflicts with guided resolution
4. Maintain linear history

Note: This operation may require manual conflict resolution.