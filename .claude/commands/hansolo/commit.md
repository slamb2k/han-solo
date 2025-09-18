---
description: "Create atomic commit with quality checks"
argument_hint: "[message]"
---

# /hansolo:commit

Invoke the han-solo-gray-squadron subagent to handle the commit process.

The subagent will:
1. Run quality checks via pre-commit hooks
2. Stage changes appropriately
3. Generate conventional commit message if not provided
4. Create atomic commit
5. Squash any checkpoint commits if configured

Optional: Pass custom commit message as $1