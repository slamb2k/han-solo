---
name: /han-solo:release
description: "Configure and manage automated release workflows for NPM, Docker, GitHub, and cloud deployments"
requires_args: false
argument-hint: "[--npm | --docker | --github | --cloud | --all]"
allowed-tools:
  - Task
---

# release

Intelligently configures automated release workflows based on your project type and deployment targets. Sets up versioning, publishing, and deployment pipelines tailored to your specific needs.

## Purpose
Establish comprehensive release automation that handles versioning, artifact publishing, and deployment across multiple platforms while maintaining consistency and reliability.

## Usage
```bash
# Interactive mode - analyzes and suggests release configuration
/release

# Configure NPM package publishing
/release --npm

# Configure Docker image releases
/release --docker

# Configure GitHub releases with changelogs
/release --github

# Configure cloud deployments (Vercel, Netlify, Pages)
/release --cloud

# Configure all detected release targets
/release --all
```

## What It Does

### 1. Release Analysis
- Detects project type (library, application, monorepo)
- Identifies deployment targets (NPM, Docker, cloud platforms)
- Analyzes versioning strategy (semantic, calendar, manual)
- Discovers existing CI/CD setup
- Checks for release configuration files

### 2. Interactive Configuration
- Presents detected release targets
- Offers configuration options based on project type
- Asks for deployment preferences
- Shows what will be configured
- Gets user confirmation before proceeding

### 3. Workflow Configuration

#### Creates/Updates
- `.github/workflows/reusable-release.yml` - Actual release implementation
- `.github/workflows/ci.yml` - Updates to trigger releases on main branch

#### Release Strategies

**Semantic Versioning** (default for libraries)
- Analyzes commit messages for version bumps
- Major: Breaking changes
- Minor: New features
- Patch: Bug fixes

**Continuous Deployment** (default for applications)
- Deploy on every merge to main
- Tag with build number or SHA
- Roll back capability

**Manual Releases**
- Trigger via GitHub UI
- Choose version number
- Add release notes

### 4. Platform-Specific Configuration

#### NPM Publishing
- Updates `package.json` with publishing config
- Sets up `publishConfig` and `files` fields
- Configures pre/post version scripts
- Creates `.npmignore` if needed
- Documents NPM_TOKEN secret requirement

#### Docker Releases
- Creates multi-stage Dockerfile if missing
- Sets up GitHub Container Registry (ghcr.io)
- Configures image tagging strategy
- Implements build caching
- Sets up vulnerability scanning

#### GitHub Releases
- Generates changelogs from commits
- Creates release notes
- Uploads build artifacts
- Tags releases appropriately
- Links to PRs and issues

#### Cloud Deployments
- **Vercel**: Production deployments with preview URLs
- **Netlify**: Deploy with forms and functions
- **GitHub Pages**: Static site deployment
- **AWS/GCP/Azure**: Container deployments

### 5. Files Created/Modified

#### Workflow Files
- `.github/workflows/reusable-release.yml` - Main release workflow
- `.github/workflows/release-notes.yml` - Changelog generation (optional)

#### Configuration Files
- `package.json` - NPM publishing configuration
- `Dockerfile` - Container configuration (if Docker)
- `.dockerignore` - Docker build exclusions
- `vercel.json` - Vercel configuration (if detected)
- `.github/SECRETS_REQUIRED.md` - Documentation for required secrets

## Example Scenarios

### NPM Library
```bash
/release --npm
# Detects: Library project with main/index exports
# Configures: Semantic versioning, NPM publishing, GitHub releases
# Creates: Release workflow that publishes on version tags
```

### Next.js Application
```bash
/release --cloud
# Detects: Next.js app with Vercel
# Configures: Continuous deployment to Vercel
# Creates: Release workflow with preview and production deployments
```

### Dockerized Service
```bash
/release --docker
# Detects: Dockerfile present
# Configures: Multi-arch builds, GHCR publishing
# Creates: Release workflow with container scanning
```

### Full Stack Monorepo
```bash
/release --all
# Detects: Multiple packages and apps
# Configures: Coordinated releases across packages
# Creates: Release workflow with dependency management
```

## Release Triggers

### Automatic Triggers
- **On merge to main**: For continuous deployment
- **On version tag**: For semantic releases (v1.0.0)
- **On schedule**: For nightly/weekly releases

### Manual Triggers
- **workflow_dispatch**: Release on demand
- **GitHub UI**: Create release with notes
- **CLI**: Using gh release create

## Security & Secrets

The command creates documentation for required secrets:

### NPM Publishing
- `NPM_TOKEN`: Automation token from npmjs.com

### Docker Registry
- Uses `GITHUB_TOKEN` (automatic) for GHCR

### Cloud Platforms
- `VERCEL_TOKEN`: For Vercel deployments
- `NETLIFY_AUTH_TOKEN`: For Netlify
- Custom tokens for AWS/GCP/Azure

## Implementation Details

This command delegates to the release-agent for intelligent configuration.

When invoked, use the Task tool with:
- **subagent_type**: "release-agent"
- **description**: "Configure releases"
- **prompt**: Include the mode (--npm, --docker, etc.) and ask the agent to:
  1. Analyze the project for release requirements
  2. Detect existing release configuration
  3. Present release options to the user
  4. Get user confirmation
  5. Delegate to release-core.sh script for execution
  6. Update reusable-release.yml with actual implementation
  7. Create necessary configuration files
  8. Document required secrets
  9. Provide comprehensive setup report

The agent handles:
- Intelligent detection of release targets
- Interactive user dialogue
- Coordination between different release types
- Ensuring consistency across configurations

## Success Metrics

After running this command, you'll have:
- ✅ Automated release pipeline
- ✅ Proper versioning strategy
- ✅ Multi-platform deployment
- ✅ Changelog generation
- ✅ Rollback capability
- ✅ Security scanning (where applicable)
- ✅ Clear documentation

## Requirements

- Git repository
- GitHub repository (for GitHub Actions)
- Target platform accounts (NPM, Docker Hub, Vercel, etc.)
- Appropriate secrets configured

## Post-Setup

After configuration:
1. Review: `cat .github/workflows/reusable-release.yml`
2. Add secrets: See `.github/SECRETS_REQUIRED.md`
3. Test locally: Verify build/package commands work
4. Create test release: Tag and push to trigger workflow
5. Monitor: Check Actions tab for release status

## Related Commands
- `/scaffold` - Set up base DevOps infrastructure
- `/quality-gates` - Configure testing and validation
- `/ship` - Ship changes through the pipeline