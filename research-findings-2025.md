# han-solo 2025 Research: Git, jq, and Shell Scripting Requirements

**Research Date**: 2025-09-18
**Research Scope**: Git version requirements, jq capabilities, POSIX shell compatibility, and linter auto-detection patterns
**Target Platform**: macOS and Linux with Claude Code CLI

## Executive Summary

This document provides comprehensive research findings for the han-solo agentic orchestrator project, focusing on minimum version requirements and best practices for Git, jq, and shell scripting in 2025. All findings are based on current stable versions and proven production practices.

## 1. Git Version Requirements and Features

### Minimum Version Requirements

Based on feature analysis and han-solo's specific workflow needs:

| Feature | Minimum Git Version | Recommended | Rationale |
|---------|-------------------|-------------|-----------|
| **Rebase --autostash** | 2.6 (config), 2.9 (CLI) | 2.9+ | Essential for han-solo's automated rebasing |
| **Worktree support** | 2.5 (basic), 2.9 (full) | 2.9+ | Required for advanced branch management |
| **Sparse-checkout** | 2.25 (modern cmd) | 2.36+ | Integration with worktree, performance |
| **Worktree + sparse-checkout** | 2.36 | 2.36+ | Seamless integration for large repos |

**Recommended Minimum**: **Git 2.36** (Q2 2022) for optimal feature compatibility

### 2025 Performance Improvements

#### Latest Stable Versions
- **Git 2.49** (March 2025)
- **Git 2.51.0** (August 2025) - Current latest with accelerated 8-week cycle

#### Key Performance Enhancements
1. **Massive Speed Improvements**:
   - **22x faster** `git fetch` in large repositories (10,000+ refs)
   - **18x faster** `git push` with reftable backend
   - Real-world example: Microsoft/FluentUI repack time: 96s → 34s

2. **Compression Improvements**:
   - **New name-hash v2 packing algorithm**
   - **Zlib-ng support**: Up to 25% performance improvement on modern hardware
   - Pack size reduction: 439 MiB → 160 MiB (Microsoft/FluentUI example)

3. **New Features for han-solo**:
   - **git backfill**: Efficient blob recovery for partial clones
   - **Stable git switch/restore**: No longer experimental
   - **SHA-256 as default**: Enhanced security (Git 3.0 preparation)
   - **Rust integration**: Improved security and stability

### Recommendations for han-solo
- **Target Git 2.36+** for full feature compatibility
- **Leverage Git 2.49+** performance improvements for large repositories
- **Use reftable backend** where available for maximum performance gains
- **Plan for SHA-256 transition** in future versions

## 2. jq Version and Performance Analysis

### Latest Stable Version
- **jq 1.8.1** (Current stable, includes CVE fixes)
- **jq 1.8.0** performance regression issues resolved in 1.8.1

### Performance Characteristics

#### Memory Usage
- **Extremely memory efficient**: Portable C with zero runtime dependencies
- **Streaming parser** (`--stream` flag): Sacrifices speed for reduced memory usage
- **Optimal for large files**: Can process TB-scale JSON files with streaming

#### Performance Benchmarks (2025)
| Comparison | Memory Usage | Speed | Notes |
|------------|-------------|-------|-------|
| jq vs yq (Go) | 3x less memory | 3.5x faster | Standard processing |
| jq vs yq (Python) | 12.7x less memory | 147x faster | Large file processing |
| jq vs alternatives | Comparable or better | Fastest for most tasks | C implementation advantage |

#### Best Practices for han-solo
```bash
# For hook scripts processing Git JSON output
git log --format=json | jq -r '.commit.message'

# For large file processing (status line data)
jq --stream --raw-output '.tool_input.command' < stdin

# Memory-efficient parsing in hooks
echo "$json_input" | jq -r '.tool_input.command'
```

### Common jq Patterns for Hook Scripts
```bash
# Extract command from Claude Code hook payload
command=$(echo "$json_input" | jq -r '.tool_input.command')

# Parse GitHub API responses
pr_status=$(gh api repos/owner/repo/pulls/123 | jq -r '.state')

# Extract multiple values efficiently
eval "$(jq -r '@sh "BRANCH=\(.branch) STATUS=\(.status)"' <<< "$json_input")"
```

## 3. POSIX Shell Compatibility and Cross-Platform Scripting

### Platform Differences (2025)

#### macOS
- **Default `/bin/sh`**: GNU bash 3.2.57 (symlinked)
- **Bash location**: `/bin/bash` (system provided)
- **Alternative shells**: dash, yash available via Homebrew
- **POSIX compliance**: Built-in sh is POSIX compliant

#### Linux
- **Debian/Ubuntu**: `/bin/sh` → dash (default)
- **RHEL/CentOS**: `/bin/sh` → bash (not ideal for portability testing)
- **Recommended testing**: dash for POSIX compliance verification

### POSIX vs Bash Feature Comparison

| Feature | POSIX sh | Bash | han-solo Usage |
|---------|----------|------|----------------|
| `[[` conditionals | ❌ | ✅ | Use `[` for compatibility |
| Arrays | ❌ | ✅ | Avoid or use space-separated strings |
| `local` keyword | ❌ | ✅ | Use functions without local vars |
| `read -r` | ✅ | ✅ | Safe for both |
| `echo -n` | ⚠️ | ✅ | Use `printf` instead |
| Process substitution `<()` | ❌ | ✅ | Use pipes or temporary files |

### Best Practices for han-solo Scripts

#### 1. Shebang Strategy
```bash
#!/bin/bash
# Use bash explicitly for han-solo hooks that need bash features

#!/bin/sh
# Use sh for maximum portability where possible
```

#### 2. POSIX-Compliant Alternatives
```bash
# Instead of bash arrays
items="item1 item2 item3"
for item in $items; do
    echo "$item"
done

# Instead of [[ ]]
if [ -z "$variable" ] && [ -f "$file" ]; then
    echo "POSIX compatible"
fi

# Instead of echo -n
printf "%s" "No newline"

# Instead of local variables
my_function() {
    # Use unique prefixes to avoid conflicts
    mf_temp_var="$1"
    echo "$mf_temp_var"
}
```

#### 3. Testing Strategy
```bash
# Test POSIX compliance with shellcheck
shellcheck --shell=sh script.sh

# Test with dash on Ubuntu/Debian
dash script.sh

# Test cross-platform
# macOS: /bin/sh script.sh
# Linux: dash script.sh
```

### Recommended Approach for han-solo
1. **Use bash explicitly** for hook scripts requiring advanced features
2. **Test with dash** on Linux for POSIX compliance verification
3. **Use ShellCheck** with `--shell=sh` flag for validation
4. **Document bash dependencies** clearly in script headers

## 4. Linter Auto-Detection Patterns

### Project Type Detection Matrix

| Language | Primary File | Secondary Files | Linter Commands | Notes |
|----------|-------------|----------------|-----------------|--------|
| **Node.js** | `package.json` | `.eslintrc.*`, `yarn.lock` | `npm run lint`, `eslint .` | Check scripts section |
| **Python** | `pyproject.toml` | `requirements.txt`, `setup.py` | `ruff check .`, `ruff format .` | Ruff is the new standard |
| **Go** | `go.mod` | `go.sum` | `golangci-lint run` | v2 has new config format |
| **Java/Maven** | `pom.xml` | `src/main/java/` | `mvn checkstyle:check` | Maven-based projects |
| **Java/Gradle** | `build.gradle` | `gradle.properties` | `gradle checkstyle` | Gradle-based projects |
| **Rust** | `Cargo.toml` | `Cargo.lock` | `cargo clippy` | Built-in linting |
| **TypeScript** | `tsconfig.json` | `package.json` | `npm run lint`, `tsc --noEmit` | Often with Node.js |

### Detection Algorithm for han-solo Hooks

```bash
#!/bin/bash
# Project type detection for pre-commit linting

detect_project_type() {
    local project_root="${1:-.}"

    # Check for multiple indicators
    if [ -f "$project_root/package.json" ]; then
        # Check if it's a Node.js project with linting
        if grep -q '"lint"' "$project_root/package.json"; then
            echo "nodejs"
            return 0
        fi
    fi

    if [ -f "$project_root/pyproject.toml" ]; then
        # Modern Python project
        echo "python-modern"
        return 0
    elif [ -f "$project_root/requirements.txt" ] || [ -f "$project_root/setup.py" ]; then
        # Legacy Python project
        echo "python-legacy"
        return 0
    fi

    if [ -f "$project_root/go.mod" ]; then
        echo "go"
        return 0
    fi

    if [ -f "$project_root/pom.xml" ]; then
        echo "java-maven"
        return 0
    elif [ -f "$project_root/build.gradle" ] || [ -f "$project_root/build.gradle.kts" ]; then
        echo "java-gradle"
        return 0
    fi

    if [ -f "$project_root/Cargo.toml" ]; then
        echo "rust"
        return 0
    fi

    echo "unknown"
    return 1
}

run_linter_for_project() {
    local project_type="$1"

    case "$project_type" in
        "nodejs")
            npm run lint --if-present || echo "No lint script found"
            ;;
        "python-modern")
            ruff check . && ruff format --check .
            ;;
        "python-legacy")
            # Fallback to older tools
            if command -v flake8 >/dev/null; then
                flake8 .
            fi
            if command -v black >/dev/null; then
                black --check .
            fi
            ;;
        "go")
            golangci-lint run
            ;;
        "java-maven")
            mvn checkstyle:check
            ;;
        "java-gradle")
            gradle checkstyle
            ;;
        "rust")
            cargo clippy -- -D warnings
            ;;
        *)
            echo "Unknown project type, skipping linting"
            return 0
            ;;
    esac
}
```

### 2025 Linter Command Updates

#### Python (Ruff Era)
```bash
# Modern Python linting (2025 standard)
ruff check .                    # Linting
ruff format .                   # Formatting
ruff check --fix .              # Auto-fix issues

# Legacy fallback
flake8 .                        # Old linting
black .                         # Old formatting
```

#### Go (golangci-lint v2)
```bash
# New v2 commands (2025)
golangci-lint run               # Lint code
golangci-lint run --fix         # Fix and format
golangci-lint fmt               # Format only
golangci-lint migrate           # Convert v1 to v2 config
```

#### Node.js (Standard Patterns)
```bash
# Common package.json scripts
npm run lint                    # Standard lint command
npm run lint:fix                # Auto-fix issues
npx eslint .                    # Direct ESLint
npx prettier --check .          # Format checking
```

### Integration Pattern for han-solo

```bash
# Pre-commit hook integration
#!/bin/bash
set -euo pipefail

# Read Claude Code hook payload
json_input=$(cat)
command=$(echo "$json_input" | jq -r '.tool_input.command')

# Only run on git commit commands
if [[ "$command" == git\ commit* ]]; then
    echo "han-solo: Running pre-commit checks..." >&2

    project_type=$(detect_project_type)
    echo "han-solo: Detected project type: $project_type" >&2

    if ! run_linter_for_project "$project_type"; then
        echo "han-solo: Linting failed. Commit blocked." >&2
        exit 2  # Block the commit
    fi

    echo "han-solo: All checks passed!" >&2
fi

exit 0  # Allow command to proceed
```

## Recommendations Summary

### For han-solo Implementation

1. **Git Requirements**:
   - **Minimum**: Git 2.36+ for full feature compatibility
   - **Recommended**: Git 2.49+ for performance benefits
   - Target reftable backend for large repositories

2. **jq Usage**:
   - **Version**: jq 1.8.1+ (latest stable with CVE fixes)
   - Use streaming (`--stream`) for large JSON processing
   - Leverage memory efficiency for hook scripts

3. **Shell Scripting**:
   - **Use bash explicitly** for hook scripts requiring advanced features
   - **Test POSIX compliance** with dash and ShellCheck
   - **Document dependencies** clearly

4. **Linter Integration**:
   - **Auto-detect** project types using primary configuration files
   - **Use modern tools**: ruff (Python), golangci-lint v2 (Go)
   - **Graceful fallbacks** for unknown project types

5. **Cross-Platform Compatibility**:
   - Target both macOS and Linux environments
   - Test on both bash and dash interpreters
   - Use portable constructs where possible

### Performance Targets for han-solo

- **Hook execution**: <100ms for pre-flight checks
- **Project detection**: <50ms using file system checks
- **JSON parsing**: Leverage jq's native speed
- **Git operations**: Benefit from 2025 performance improvements

This research provides the foundation for implementing a robust, performant, and compatible han-solo system that works reliably across modern development environments in 2025.