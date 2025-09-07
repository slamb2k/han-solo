#!/usr/bin/env bash
# install-global.sh — User-scoped installer for han-solo (~/.claude/*)
# Installs 2 subagents + 2 commands into your home ~/.claude so they work across projects.
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/slamb2k/han-solo/<TAG>/install-global.sh | bash
#
# Optional: REPO_USER, REPO_NAME, TAG, CHECKSUMS_URL (same semantics as install.sh)

set -Eeuo pipefail

REPO_USER="${REPO_USER:-slamb2k}"
REPO_NAME="${REPO_NAME:-<REPO_NAME>}"
TAG="${TAG:-main}"
RAW_BASE="https://raw.githubusercontent.com/${REPO_USER}/${REPO_NAME}/${TAG}/.claude"

DEST="${HOME}/.claude"
AGENTS_DIR="${DEST}/agents"
CMDS_DIR="${DEST}/commands"
BOOT_DIR="${CMDS_DIR}/bootstrap"
GIT_DIR="${CMDS_DIR}/git"

CHECKSUMS_URL="${CHECKSUMS_URL:-}"

require() { command -v "$1" >/dev/null 2>&1 || { echo "Missing required tool: $1"; exit 2; }; }
require curl
require mkdir
require printf

mkdir -p "${AGENTS_DIR}" "${BOOT_DIR}" "${GIT_DIR}"

FILES=(
  "agents/bootstrap-guardian.md|${AGENTS_DIR}/bootstrap-guardian.md"
  "agents/git-shipper.md|${AGENTS_DIR}/git-shipper.md"
  "commands/bootstrap/bootstrap.md|${BOOT_DIR}/bootstrap.md"
  "commands/git/ship.md|${GIT_DIR}/ship.md"
)

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

if [ -n "$CHECKSUMS_URL" ]; then
  curl -fsSL "$CHECKSUMS_URL" -o "${TMPDIR}/SHA256SUMS"
  if ! command -v sha256sum >/dev/null 2>&1 && ! command -v shasum >/dev/null 2>&1; then
    echo "WARN: sha256sum/shasum not found; skipping checksum verification"
    CHECKSUMS_URL=""
  fi
fi

fetch_and_write() {
  local rel="$1" dst="$2"
  local url="${RAW_BASE}/${rel}"
  local tmp="${TMPDIR}/$(basename "$rel")"

  echo "→ Fetch ${rel}"
  curl -fsSL "$url" -o "$tmp"

  if [ -n "$CHECKSUMS_URL" ]; then
    if command -v sha256sum >/dev/null 2>&1; then
      (cd "${TMPDIR}" && sha256sum -c <(grep -E " ${rel}$" "${TMPDIR}/SHA256SUMS") ) || {
        echo "ERROR: checksum failed for ${rel}"; exit 3;
      }
    else
      EXPECTED="$(grep -E " ${rel}$" "${TMPDIR}/SHA256SUMS" | awk '{print $1}')"
      ACTUAL="$(shasum -a 256 "$tmp" | awk '{print $1}')"
      [ "$EXPECTED" = "$ACTUAL" ] || { echo "ERROR: checksum failed for ${rel}"; exit 3; }
    fi
  fi

  mkdir -p "$(dirname "$dst")"
  mv "$tmp" "$dst"
}

for pair in "${FILES[@]}"; do
  IFS='|' read -r rel dst <<<"$pair"
  fetch_and_write "$rel" "$dst"
done

printf "\n✅ Installed han-solo agents & commands at: %s\n" "$DEST"
printf "   - Agents: %s\n" "$AGENTS_DIR"
printf "   - Commands: %s\n\n" "$CMDS_DIR"
printf "Next steps:\n"
printf "  • Restart Claude Code (or reload) so it picks up new commands/agents\n"
printf "  • In Claude Code: run /help (should show '(user)' on your commands)\n"
printf "  • Run /agents to confirm subagents are visible\n"
