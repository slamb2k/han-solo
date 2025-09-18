---
description: "Initialize repository with han-solo configuration"
---

# /hansolo:init

Invoke the han-solo-red-squadron subagent to set up this project according to the han-solo methodology.

The subagent will:
1. Create standard configuration files (.gitignore, .gitconfig, .gitmessage)
2. Set up GitHub pull request template
3. Configure branch protection rules via GitHub API
4. Initialize CLAUDE.md with workflow triggers

Pass all user-provided arguments directly to the subagent.