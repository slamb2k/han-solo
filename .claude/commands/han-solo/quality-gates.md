---
name: /han-solo:quality-gates
description: "Analyze your codebase and set up comprehensive quality gates with testing, linting, and CI/CD tailored to your tech stack"
requires_args: false
argument-hint: "[--strict | --balanced | --minimal]"
allowed-tools:
  - Task
---

# quality-gates

Intelligently analyzes your codebase and sets up comprehensive quality gates including testing frameworks, linting, formatting, and CI/CD workflows tailored to your specific tech stack.

## Purpose
Establish a multi-layered quality assurance system that provides fast feedback at every stage of development while maintaining developer velocity. The command detects your frameworks and languages, then configures appropriate tools and workflows.

## Usage
```bash
# Analyze and set up quality gates with balanced defaults
/quality-gates

# Strict mode - maximum validation, may impact velocity
/quality-gates --strict

# Balanced mode - optimal trade-off (default)
/quality-gates --balanced

# Minimal mode - essential checks only, maximum velocity
/quality-gates --minimal
```

## What It Does

### 1. Codebase Analysis
- Detects programming languages (JavaScript, TypeScript, Python, Go, Rust, etc.)
- Identifies frameworks (React, Vue, Next.js, Express, Django, etc.)
- Recognizes package managers (npm, pnpm, yarn, pip, cargo, etc.)
- Discovers existing test frameworks
- Analyzes current CI/CD setup

### 2. Quality Gate Layers

#### Layer 1: Pre-commit (< 1 second)
- **Formatting**: Prettier, Black, gofmt, rustfmt
- **Staged file linting**: ESLint, Pylint, golangci-lint
- **Secret detection**: Prevents API keys from being committed

#### Layer 2: Pre-push (< 10 seconds)
- **Full linting**: All files, not just staged
- **Type checking**: TypeScript, mypy, go vet
- **Unit tests**: Jest, pytest, go test, cargo test
- **Security scanning**: Basic vulnerability checks

#### Layer 3: Pull Request (< 2 minutes)
- **All previous checks** in strict mode
- **Integration tests**: API tests, E2E tests
- **Coverage reporting**: Ensure adequate test coverage
- **Build verification**: Ensure project builds successfully
- **Documentation generation**: Update API docs if needed

#### Layer 4: Main Branch (< 5 minutes)
- **Full test suite**: Including slow tests
- **Performance benchmarks**: Detect performance regressions
- **Security audit**: Comprehensive vulnerability scanning
- **Release preparation**: Version bumping, changelog

### 3. Workflow Configuration

#### Reusable Test Workflow
- **Updates**: `.github/workflows/reusable-test.yml`
- **Configures**: Actual test implementation based on detected frameworks
- **Sets up**: Test matrices, coverage thresholds, and framework-specific commands
- **Replaces**: Placeholders with real test execution

### 4. Framework-Specific Configurations

#### JavaScript/TypeScript
- **Testing**: Jest or Vitest with React Testing Library
- **Linting**: ESLint with appropriate plugins
- **Formatting**: Prettier with .prettierrc
- **Type checking**: TypeScript strict mode
- **CI**: GitHub Actions with pnpm caching

#### Python
- **Testing**: pytest with coverage
- **Linting**: ruff or flake8 + black
- **Type checking**: mypy with strict settings
- **Formatting**: black + isort
- **CI**: GitHub Actions with pip caching

#### Go
- **Testing**: go test with race detection
- **Linting**: golangci-lint with strict config
- **Formatting**: gofmt + goimports
- **Security**: gosec for vulnerability scanning
- **CI**: GitHub Actions with Go module caching

#### Rust
- **Testing**: cargo test with doc tests
- **Linting**: clippy with pedantic lints
- **Formatting**: rustfmt with standard config
- **Security**: cargo-audit for dependencies
- **CI**: GitHub Actions with cargo caching

### 5. Files Created/Modified

#### Workflow Files
- `.github/workflows/reusable-test.yml` - Test workflow with actual implementation
- `.github/workflows/ci.yml` - Updates test job if needed

#### Configuration Files
- `.prettierrc` - Formatting rules
- `.eslintrc.js` - Linting configuration
- `tsconfig.json` - TypeScript settings (enhanced)
- `jest.config.js` or `vitest.config.js` - Test configuration
- `.husky/pre-commit` - Fast checks
- `.husky/pre-push` - Comprehensive validation

#### Test Structure
```
tests/
├── unit/           # Fast, isolated tests
├── integration/    # API and service tests
├── e2e/           # End-to-end browser tests
└── performance/   # Benchmark tests
```

## Examples by Tech Stack

### Next.js Application
```bash
/quality-gates
# Detects: Next.js, React, TypeScript
# Sets up: Jest, React Testing Library, Playwright, ESLint, Prettier
# CI: Vercel deployment checks, Lighthouse scores
```

### Express API
```bash
/quality-gates
# Detects: Express, Node.js, JavaScript
# Sets up: Jest, Supertest, ESLint, Prettier
# CI: API testing, security headers check
```

### Python Django
```bash
/quality-gates --strict
# Detects: Django, Python
# Sets up: pytest-django, black, mypy, ruff
# CI: Django test runner, migration checks
```

### Go Microservice
```bash
/quality-gates
# Detects: Go modules
# Sets up: go test, golangci-lint, go-mockgen
# CI: Race detection, benchmark regression
```

## Quality Modes

### Minimal Mode
- Basic formatting and linting
- Critical path unit tests only
- Simple CI with essential checks
- ~30 second PR validation

### Balanced Mode (Default)
- Comprehensive linting and formatting
- Unit and integration tests
- Security scanning
- ~2 minute PR validation

### Strict Mode
- All checks enabled
- 80% coverage requirement
- Performance benchmarks
- Mutation testing
- ~5 minute PR validation

## Implementation Details

This command delegates to the quality-gates-guardian agent for comprehensive setup.

When invoked, use the Task tool with:
- **subagent_type**: "quality-gates-guardian"
- **description**: "Set up quality gates"
- **prompt**: Include the mode (--minimal, --balanced, or --strict) and ask the agent to:
  1. Check for existing bootstrap/scaffold setup and placeholders
  2. Analyze the codebase to detect languages and frameworks
  3. Detect any evolution since bootstrap/scaffold was run
  4. Update `.github/workflows/reusable-test.yml` with actual test implementation
  5. Fill workflow placeholders or update existing workflows
  6. Set up appropriate testing frameworks with real tests (no placeholders)
  7. Configure linting and formatting tools
  8. Update Husky hooks for pre-commit and pre-push validation
  9. Create or enhance GitHub Actions workflows
  10. If major changes detected, present options to the user
  11. Ensure all "echo" placeholder scripts are replaced with real commands
  12. Use scaffold-tests.sh script to configure reusable-test.yml
  13. Provide a comprehensive report of changes

The agent will handle all the complex logic for:
- Detecting and filling bootstrap placeholders
- Identifying codebase evolution requiring user decisions
- Configuring the appropriate tools for the user's specific tech stack
- Maintaining consistency with bootstrap patterns

## Success Metrics

After running this command, you'll have:
- ✅ Zero "placeholder" test scripts
- ✅ Functional test suite with examples
- ✅ Linting catching common issues
- ✅ Type safety where applicable
- ✅ CI passing on every PR
- ✅ < 10 second pre-push feedback
- ✅ Clear path to add more tests

## Requirements

- Git repository
- Node.js (for Husky)
- Package manager (npm, pnpm, yarn)
- GitHub repository (for Actions)

## Post-Setup

After setup completes:
1. Review generated configurations
2. Run `npm test` to verify setup
3. Make a test commit to verify hooks
4. Create a test PR to verify CI

## Related Commands
- `/bootstrap` - Initial repository setup
- `/ship` - Ship code through quality gates
- `/health` - Check quality gate status