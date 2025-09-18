---
description: "Create pull request with auto-generated description"
argument_hint: "[issue-number]"
---

# /hansolo:ship

Invoke the han-solo-blue-squadron subagent to create a pull request.

The subagent will:
1. Analyze changes with git diff
2. Generate PR title and description
3. Link to related issues if provided
4. Create PR using GitHub CLI
5. Display PR URL and CI status

Optional: Pass issue number as $1 to auto-link