#!/bin/bash
# han-solo project type detection script
# Detects project type and returns appropriate linter commands

set -euo pipefail
IFS=$'\n\t'

# Default response
PROJECT_TYPE="unknown"
LINT_CMD=""
FORMAT_CMD=""

# Node.js detection
if [ -f "package.json" ]; then
    PROJECT_TYPE="nodejs"
    # Check for lint script in package.json
    if grep -q '"lint"' package.json 2>/dev/null; then
        LINT_CMD="npm run lint --if-present"
    elif [ -f ".eslintrc.json" ] || [ -f ".eslintrc.js" ] || [ -f ".eslintrc.yml" ]; then
        LINT_CMD="npx eslint ."
    fi
    if grep -q '"format"' package.json 2>/dev/null; then
        FORMAT_CMD="npm run format --if-present"
    elif [ -f ".prettierrc" ] || [ -f ".prettierrc.json" ]; then
        FORMAT_CMD="npx prettier --check ."
    fi

# Python detection
elif [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ]; then
    PROJECT_TYPE="python"
    # Prefer ruff for 2025 standard
    if command -v ruff >/dev/null 2>&1; then
        LINT_CMD="ruff check ."
        FORMAT_CMD="ruff format --check ."
    elif [ -f "pyproject.toml" ] && grep -q "black" pyproject.toml 2>/dev/null; then
        LINT_CMD="python -m flake8 . || true"
        FORMAT_CMD="python -m black --check ."
    elif command -v pylint >/dev/null 2>&1; then
        LINT_CMD="pylint **/*.py || true"
    fi

# Go detection
elif [ -f "go.mod" ]; then
    PROJECT_TYPE="go"
    if command -v golangci-lint >/dev/null 2>&1; then
        LINT_CMD="golangci-lint run"
    else
        LINT_CMD="go vet ./..."
    fi
    FORMAT_CMD="gofmt -l ."

# Java/Maven detection
elif [ -f "pom.xml" ]; then
    PROJECT_TYPE="maven"
    LINT_CMD="mvn checkstyle:check || true"
    FORMAT_CMD=""

# Java/Gradle detection
elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    PROJECT_TYPE="gradle"
    LINT_CMD="gradle checkstyle || true"
    FORMAT_CMD=""

# Rust detection
elif [ -f "Cargo.toml" ]; then
    PROJECT_TYPE="rust"
    LINT_CMD="cargo clippy -- -D warnings"
    FORMAT_CMD="cargo fmt -- --check"

# Ruby detection
elif [ -f "Gemfile" ]; then
    PROJECT_TYPE="ruby"
    if command -v rubocop >/dev/null 2>&1; then
        LINT_CMD="rubocop"
        FORMAT_CMD="rubocop --auto-correct-all --dry-run"
    fi
fi

# Output as JSON for easy parsing
cat <<EOF
{
  "project_type": "$PROJECT_TYPE",
  "lint_cmd": "$LINT_CMD",
  "format_cmd": "$FORMAT_CMD"
}
EOF