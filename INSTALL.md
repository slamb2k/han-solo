![han-solo logo](assets/logo.png)

# Installing han-solo (bootstrap-guardian + git-shipper)

Han-solo ships **2 subagents** and **2 slash commands** that Claude Code will auto-discover:

- Subagents → `.claude/agents/`
- Commands  → `.claude/commands/` (organized into subdirectories)

You can install them **project-scoped** (recommended) or **user-scoped** (global). Project scope is versioned in your repo; user scope works across all projects.

## Project-scoped install (recommended)

One-liner:

  curl -fsSL https://raw.githubusercontent.com/slamb2k/han-solo/<TAG>/install.sh | bash

This writes files into `.claude/` in the current repository so they travel with your code.

## User-scoped (global) install

One-liner:

  curl -fsSL https://raw.githubusercontent.com/slamb2k/han-solo/<TAG>/install-global.sh | bash

This installs to `~/.claude/` so the agents/commands are available across all projects.

## Optional: integrity verification (maintainers)

Provide a `SHA256SUMS` file in your release/tag for each path under `.claude/`:

  # Example SHA256SUMS lines (space before relative path)
  <sha256>  agents/bootstrap-guardian.md
  <sha256>  agents/git-shipper.md
  <sha256>  commands/bootstrap/bootstrap.md
  <sha256>  commands/git/ship.md

Then publish its raw URL and ask users to set:
  
  CHECKSUMS_URL="https://raw.githubusercontent.com/slamb2k/han-solo/<TAG>/SHA256SUMS"

before running the installer, or embed the URL directly in the scripts.

## Verifying install

1. Restart Claude Code (or reload).
2. Run `/help` — you should see your commands with a `(project)` tag if project-scoped, or `(user)` if installed globally.
3. Run `/agents` — confirm `bootstrap-guardian` and `git-shipper` appear and tools/permissions look right.

## Uninstall

Project-scoped:
- Delete the `.claude/agents/*` and `.claude/commands/*` you added (or remove `.claude` entirely if it only contains han-solo).
- Commit the removal in your repo.

User-scoped:
- Remove the corresponding files from `~/.claude/agents/` and `~/.claude/commands/`.

## Notes

- Claude Code automatically discovers commands in `.claude/commands` (project-level) and `~/.claude/commands` (user-level), and it namespaces them by subdirectory for organization. Subagents live in the analogous `agents` directories.
- Project scope takes precedence over user scope when names collide.

