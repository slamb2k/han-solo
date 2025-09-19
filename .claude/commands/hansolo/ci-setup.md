---
description: "Configure CI/CD pipeline for project"
argument_hint: "[--deploy]"
---

# /hansolo:ci-setup

Invoke the hansolo-green-squadron subagent to set up continuous integration.

The subagent will:
1. Auto-detect project type
2. Generate appropriate GitHub Actions workflow
3. Configure test, lint, and build steps
4. Set up deployment if --deploy flag provided
5. Guide through secrets configuration

Options:
- --deploy: Include deployment configuration