# Han-Solo Testing Framework Specification

## Executive Summary

This document outlines a comprehensive testing strategy for the han-solo Git workflow automation tool, focusing on maximum validation without impacting developer velocity. The framework employs a multi-layered approach with tests running at different stages of the development pipeline.

## Core Principles

1. **Fast Feedback First**: Quick checks run locally, comprehensive checks run in CI
2. **Fail Fast, Fail Early**: Catch issues as close to the developer as possible
3. **Progressive Validation**: More expensive checks run later in the pipeline
4. **Zero False Positives**: Every test failure should represent a real issue
5. **Developer Experience**: Testing should guide, not hinder development

## Testing Layers

### Layer 1: Pre-commit (< 1 second)
**Purpose**: Catch obvious issues before they enter version control
**Target Time**: < 1 second total

#### What Runs Here:
- **Formatting** (prettier, shfmt)
  - Auto-fix when possible
  - Only on staged files
- **Basic Syntax Check**
  - Bash syntax validation (`bash -n`)
  - JSON/YAML validation
- **Secrets Detection**
  - Prevent API keys, tokens from being committed

#### Implementation:
```yaml
# .husky/pre-commit
#!/bin/bash
# Quick format check (auto-fix)
npx prettier --write --cache "**/*.{json,md,yml,yaml}"
shfmt -w .claude/scripts/*.sh

# Syntax validation (staged shell scripts only)
for file in $(git diff --cached --name-only --diff-filter=ACM | grep '\.sh$'); do
  bash -n "$file" || exit 1
done

# Secrets scan
npx secretlint "**/*"
```

### Layer 2: Pre-push (< 10 seconds)
**Purpose**: Validate code quality before sharing with team
**Target Time**: < 10 seconds total

#### What Runs Here:
- **ShellCheck** - Shell script linting
  - All shell scripts in the repo
  - Error and warning level issues
- **Type Checking** (if TypeScript is added)
- **Markdown Link Validation**
- **Command Documentation Validation**
  - Ensure .claude/commands match scripts

#### Implementation:
```yaml
# .husky/pre-push
#!/bin/bash
# ShellCheck all scripts
find scripts -name "*.sh" -exec shellcheck {} +

# Validate command definitions match scripts
npm run validate:commands

# Check markdown links
npx markdown-link-check README.md docs/*.md
```

### Layer 3: Pull Request Checks (< 2 minutes)
**Purpose**: Comprehensive validation before merging
**Target Time**: < 2 minutes total

#### What Runs Here:
- **All Pre-commit Checks** (in strict mode)
- **All Pre-push Checks** (in strict mode)
- **Integration Tests**
  - Test actual script execution in Docker container
  - Validate git operations
  - Test PR creation/merge flows
- **Compatibility Tests**
  - macOS vs Linux differences
  - Different git versions
  - GitHub CLI compatibility
- **Documentation Generation**
  - Auto-generate command docs from code

#### Implementation:
```yaml
# .github/workflows/pr-checks.yml
name: PR Checks
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  quick-checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Format Check
        run: npm run format:check
      - name: ShellCheck
        run: shellcheck .claude/scripts/*.sh
      - name: Validate Commands
        run: npm run validate:commands

  integration-tests:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - name: Test Ship Flow
        run: ./tests/integration/test-ship.sh
      - name: Test Scrub Flow
        run: ./tests/integration/test-scrub.sh
```

### Layer 4: Post-merge to Main (< 5 minutes)
**Purpose**: Full regression testing and deployment preparation
**Target Time**: < 5 minutes total

#### What Runs Here:
- **All Previous Checks**
- **Full Regression Suite**
- **Performance Testing**
  - Ensure scripts complete within time limits
- **Compatibility Matrix**
  - Test against multiple git versions
  - Test with various repository sizes
- **Release Preparation**
  - Version bumping
  - Changelog generation
  - Tag creation

## Test Categories

### 1. Syntax & Linting

| Tool | Stage | Config | Purpose |
|------|-------|---------|---------|
| ShellCheck | pre-push, PR | `.shellcheckrc` | Catch shell scripting issues |
| Prettier | pre-commit | `.prettierrc` | Format markdown, JSON, YAML |
| shfmt | pre-commit | `.editorconfig` | Format shell scripts |
| yamllint | PR | `.yamllint` | Validate YAML syntax |

### 2. Functional Tests

#### Unit Tests
Location: `tests/unit/`
Framework: BATS (Bash Automated Testing System)

```bash
# tests/unit/ship-core.test.sh
#!/usr/bin/env bats

@test "detect main branch correctly" {
  run get_default_branch
  [ "$status" -eq 0 ]
  [[ "$output" == "main" || "$output" == "master" ]]
}

@test "check for merged PR detection" {
  # Mock gh command
  function gh() { echo '{"number": 42, "state": "MERGED"}'; }
  export -f gh
  
  run check_merged_pr "test-branch"
  [ "$status" -eq 0 ]
  [ "$output" == "42" ]
}
```

#### Integration Tests
Location: `tests/integration/`
Framework: Docker + BATS

```bash
# tests/integration/test-ship.sh
#!/usr/bin/env bats

setup() {
  # Create test repo in Docker
  docker run -d --name test-repo gitserver
  export TEST_REPO="http://localhost:3000/test.git"
}

@test "ship creates PR successfully" {
  run ./.claude/scripts/ship-core.sh --check
  [ "$status" -eq 0 ]
  
  run ./.claude/scripts/ship-core.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "PR created" ]]
}

teardown() {
  docker rm -f test-repo
}
```

### 3. Regression Tests

Location: `tests/regression/`
Purpose: Ensure fixed bugs stay fixed

```bash
# tests/regression/no-orphaned-branches.test.sh
#!/usr/bin/env bats

@test "ship does not create orphaned branches" {
  # Setup: Create a branch with merged PR
  create_branch_with_merged_pr "fix/test-branch"
  
  # Make new commits
  echo "test" > test.txt
  git add . && git commit -m "test"
  
  # Run ship
  run ./.claude/scripts/ship-core.sh
  [ "$status" -eq 0 ]
  
  # Verify no orphaned branch
  run git ls-remote --heads origin "fix/test-branch"
  [ "$status" -eq 0 ]
  [ -z "$output" ]  # Branch should not exist on remote
}
```

### 4. Performance Tests

Location: `tests/performance/`
Purpose: Ensure operations complete within acceptable time

```bash
# tests/performance/ship-performance.test.sh
#!/usr/bin/env bats

@test "ship completes check mode under 5 seconds" {
  start=$(date +%s)
  run timeout 5 ./.claude/scripts/ship-core.sh --check
  end=$(date +%s)
  
  [ "$status" -eq 0 ]
  [ $((end - start)) -lt 5 ]
}
```

## Implementation Plan

### Phase 1: Foundation (Week 1)
1. Set up BATS testing framework
2. Create basic unit tests for core functions
3. Implement ShellCheck in pre-push hook
4. Add formatting checks in pre-commit

### Phase 2: Integration (Week 2)
1. Create Docker-based test environment
2. Implement integration tests for ship/scrub
3. Add regression tests for recent bugs
4. Set up GitHub Actions workflow

### Phase 3: Advanced (Week 3)
1. Add performance testing
2. Implement compatibility matrix
3. Create mutation testing for shell scripts
4. Add test coverage reporting

### Phase 4: Documentation (Week 4)
1. Generate test reports
2. Create testing guidelines
3. Document how to add new tests
4. Create troubleshooting guide

## Configuration Files

### `.shellcheckrc`
```bash
# ShellCheck configuration
enable=all
severity=warning
shell=bash

# Ignore specific codes if needed
# disable=SC2034  # Unused variables
```

### `.batsrc`
```bash
# BATS configuration
--timing
--print-output-on-failure
--formatter tap
--report-formatter junit
```

### `test-requirements.txt`
```bash
# Testing dependencies
bats-core==1.10.0
bats-assert==2.1.0
bats-support==0.3.0
shellcheck==0.10.0
shfmt==3.8.0
```

## Success Metrics

1. **Test Coverage**: > 80% of critical paths
2. **Execution Time**: 
   - Pre-commit: < 1s
   - Pre-push: < 10s
   - PR checks: < 2 min
   - Full suite: < 5 min
3. **False Positive Rate**: < 1%
4. **Bug Recurrence**: 0% for tested scenarios
5. **Developer Satisfaction**: Testing helps rather than hinders

## Rollout Strategy

1. **Start Optional**: Tests run but don't block initially
2. **Gradual Enforcement**: Enable blocking after stability proven
3. **Team Training**: Workshops on writing and running tests
4. **Continuous Refinement**: Weekly review of test effectiveness

## Maintenance

- **Weekly**: Review test failures, adjust thresholds
- **Monthly**: Update dependencies, review coverage
- **Quarterly**: Performance audit, framework evaluation

## Appendix: Tool Comparison

| Tool | Pros | Cons | Use Case |
|------|------|------|----------|
| BATS | Native bash testing | Limited assertions | Unit/Integration |
| ShellCheck | Comprehensive | Can be pedantic | Linting |
| shellspec | BDD-style | Learning curve | Complex scenarios |
| Docker | Isolated environment | Overhead | Integration tests |

## References

- [BATS Documentation](https://bats-core.readthedocs.io/)
- [ShellCheck Wiki](https://www.shellcheck.net/wiki/)
- [GitHub Actions Testing](https://docs.github.com/en/actions/automating-builds-and-tests)
- [Bash Testing Best Practices](https://github.com/bats-core/bats-core/wiki/Best-Practices)