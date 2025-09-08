#!/usr/bin/env bash
# install.sh — Installer for han-solo Claude Code tools
# Downloads and installs the latest release from GitHub
#
# Usage:
#   # Project-scoped installation (default - .claude/ in current directory)
#   curl -fsSL https://raw.githubusercontent.com/slamb2k/han-solo/main/scripts/install.sh | bash
#   
#   # Global/user installation (~/.claude/)
#   curl -fsSL https://raw.githubusercontent.com/slamb2k/han-solo/main/scripts/install.sh | bash -s -- --global
#   
#   # Install specific version
#   TAG=v2024.01.15-1 curl -fsSL ... | bash
#   
#   # Combine flags
#   TAG=v2024.01.15-1 curl -fsSL ... | bash -s -- --global

set -Eeuo pipefail

# Configuration
REPO_USER="${REPO_USER:-slamb2k}"
REPO_NAME="${REPO_NAME:-han-solo}"
TAG="${TAG:-latest}"  # Can specify a specific version like v2024.01.15-1

# Parse command line arguments
GLOBAL_INSTALL=false
for arg in "$@"; do
  case $arg in
    --global|-g)
      GLOBAL_INSTALL=true
      shift
      ;;
    --help|-h)
      echo "han-solo Claude tools installer"
      echo ""
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --global, -g    Install globally to ~/.claude/ (default: project .claude/)"
      echo "  --help, -h      Show this help message"
      echo ""
      echo "Environment variables:"
      echo "  TAG             Version to install (default: latest)"
      echo "  REPO_USER       GitHub username (default: slamb2k)"
      echo "  REPO_NAME       Repository name (default: han-solo)"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      echo "Use --help for usage information" >&2
      exit 1
      ;;
  esac
done

# Set installation directory based on scope
if [ "$GLOBAL_INSTALL" = true ]; then
  DEST="${HOME}/.claude"
  SCOPE_DESC="global/user"
  SCOPE_NOTE="(available in all projects)"
else
  DEST=".claude"
  SCOPE_DESC="project"
  SCOPE_NOTE="(this project only)"
fi

# Temporary directory for downloads
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

# Check for required tools
require() { 
  command -v "$1" >/dev/null 2>&1 || { 
    echo "❌ Missing required tool: $1" >&2
    echo "   Please install $1 and try again." >&2
    exit 2
  }
}

# Verify prerequisites
require curl
require unzip

echo "🚀 Installing han-solo Claude tools ${SCOPE_NOTE}..."
echo "   Repository: ${REPO_USER}/${REPO_NAME}"
echo "   Version: ${TAG}"
echo "   Scope: ${SCOPE_DESC}"
echo "   Target: ${DEST}"
echo ""

# Fetch release info from GitHub API
if [ "$TAG" = "latest" ]; then
  API_URL="https://api.github.com/repos/${REPO_USER}/${REPO_NAME}/releases/latest"
  echo "→ Fetching latest release information..."
else
  API_URL="https://api.github.com/repos/${REPO_USER}/${REPO_NAME}/releases/tags/${TAG}"
  echo "→ Fetching release ${TAG} information..."
fi

# Download release metadata
RELEASE_JSON="${TMPDIR}/release.json"
if ! curl -fsSL "$API_URL" -o "$RELEASE_JSON" 2>/dev/null; then
  echo "❌ ERROR: Failed to fetch release information" >&2
  echo "   URL: $API_URL" >&2
  echo "" >&2
  echo "   This could mean:" >&2
  echo "   • The repository doesn't have any releases yet" >&2
  echo "   • The specified version (${TAG}) doesn't exist" >&2
  echo "   • Network connectivity issues" >&2
  exit 1
fi

# Parse release information
DOWNLOAD_URL="$(grep -o '"browser_download_url":[[:space:]]*"[^"]*\.zip"' "$RELEASE_JSON" | cut -d'"' -f4 | head -1)"
CHECKSUM_URL="$(grep -o '"browser_download_url":[[:space:]]*"[^"]*SHA256SUMS"' "$RELEASE_JSON" | cut -d'"' -f4 | head -1)"
VERSION="$(grep -o '"tag_name":[[:space:]]*"[^"]*"' "$RELEASE_JSON" | cut -d'"' -f4)"

if [ -z "$DOWNLOAD_URL" ]; then
  echo "❌ ERROR: No release archive found" >&2
  echo "   The release exists but doesn't contain the expected .zip file" >&2
  exit 1
fi

echo "→ Downloading han-solo Claude tools ${VERSION}..."
ARCHIVE_PATH="${TMPDIR}/han-solo-claude.zip"
if ! curl -fsSL "$DOWNLOAD_URL" -o "$ARCHIVE_PATH" --progress-bar; then
  echo "❌ ERROR: Failed to download release archive" >&2
  exit 1
fi

# Optional: Verify checksum if available
if [ -n "$CHECKSUM_URL" ]; then
  if command -v sha256sum >/dev/null 2>&1; then
    echo "→ Verifying checksum..."
    CHECKSUM_PATH="${TMPDIR}/SHA256SUMS"
    if curl -fsSL "$CHECKSUM_URL" -o "$CHECKSUM_PATH" 2>/dev/null; then
      # Extract just the filename from the archive path for checksum verification
      ARCHIVE_NAME="$(basename "$ARCHIVE_PATH")"
      # Create a temporary checksum file with the correct path
      grep "$(basename "$DOWNLOAD_URL")" "$CHECKSUM_PATH" | sed "s|han-solo-claude-.*\.zip|${ARCHIVE_NAME}|" > "${TMPDIR}/checksum.txt"
      if (cd "$TMPDIR" && sha256sum -c checksum.txt >/dev/null 2>&1); then
        echo "   ✅ Checksum verified"
      else
        echo "   ⚠️  WARNING: Checksum verification failed" >&2
        echo "   The download may be corrupted. Proceed with caution." >&2
      fi
    fi
  elif command -v shasum >/dev/null 2>&1; then
    echo "→ Verifying checksum (using shasum)..."
    CHECKSUM_PATH="${TMPDIR}/SHA256SUMS"
    if curl -fsSL "$CHECKSUM_URL" -o "$CHECKSUM_PATH" 2>/dev/null; then
      EXPECTED="$(grep "$(basename "$DOWNLOAD_URL")" "$CHECKSUM_PATH" | awk '{print $1}')"
      ACTUAL="$(shasum -a 256 "$ARCHIVE_PATH" | awk '{print $1}')"
      if [ "$EXPECTED" = "$ACTUAL" ]; then
        echo "   ✅ Checksum verified"
      else
        echo "   ⚠️  WARNING: Checksum verification failed" >&2
      fi
    fi
  fi
fi

# Backup existing settings if present
if [ -f "${DEST}/settings.local.json" ]; then
  echo "→ Backing up existing settings..."
  cp "${DEST}/settings.local.json" "${TMPDIR}/settings.backup.json"
fi

# Note about existing installation
if [ "$GLOBAL_INSTALL" = true ]; then
  if [ -d "${DEST}/commands/han-solo" ]; then
    echo "→ Will replace existing han-solo commands..."
  fi
  if [ -d "${DEST}/agents" ] && [ -f "${DEST}/agents/bootstrap-guardian.md" ]; then
    echo "→ Will replace existing han-solo agents..."
  fi
fi

# Create destination directory
mkdir -p "$DEST"

# Extract archive
if [ "$GLOBAL_INSTALL" = true ]; then
  echo "→ Extracting to ${DEST}..."
else
  echo "→ Extracting to $(pwd)/${DEST}..."
fi

if ! unzip -q -o "$ARCHIVE_PATH" -d "$DEST"; then
  echo "❌ ERROR: Failed to extract archive" >&2
  exit 1
fi

# Restore settings if backed up
if [ -f "${TMPDIR}/settings.backup.json" ]; then
  echo "→ Restoring settings..."
  mv "${TMPDIR}/settings.backup.json" "${DEST}/settings.local.json"
fi

# Verify installation
if [ ! -d "${DEST}/agents" ] || [ ! -d "${DEST}/commands" ]; then
  echo "⚠️  WARNING: Installation may be incomplete" >&2
  echo "   Expected directories not found in ${DEST}/" >&2
fi

# Success message
printf "\n✅ Successfully installed han-solo Claude tools ${VERSION}\n"
if [ "$GLOBAL_INSTALL" = true ]; then
  printf "   Location: %s (global)\n" "${DEST}"
else
  printf "   Location: %s (project)\n" "$(pwd)/${DEST}"
fi
printf "\n"
printf "📂 Installed components:\n"
printf "   • Agents:   %s\n" "${DEST}/agents/"
printf "   • Commands: %s\n" "${DEST}/commands/"
printf "\n"

if [ "$GLOBAL_INSTALL" = true ]; then
  printf "🌍 Global installation notes:\n"
  printf "   • These tools are now available in ALL your projects\n"
  printf "   • Commands will show as '(user)' in Claude Code\n"
  printf "   • Project-specific .claude/ directories take precedence\n"
else
  printf "📁 Project installation notes:\n"
  printf "   • These tools are only available in this project\n"
  printf "   • Commands will show as '(project)' in Claude Code\n"
  printf "   • Use --global flag to install for all projects\n"
fi

printf "\n"
printf "🚀 Next steps:\n"
printf "   1. Restart Claude Code (or reload window)\n"
printf "   2. Run /help to see available commands\n"
printf "   3. Run /bootstrap to set up repository governance\n"
printf "   4. Run /ship to ship your changes\n"
printf "\n"
printf "📚 Documentation: https://github.com/${REPO_USER}/${REPO_NAME}\n"