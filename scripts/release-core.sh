#!/usr/bin/env bash
# release-core.sh - Core implementation for release configuration
# This script handles the actual creation and configuration of release workflows

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Configuration defaults
TARGETS=""
STRATEGY="semantic"
PROJECT_TYPE="library"
PACKAGE_MANAGER="pnpm"
NPM_SCOPE=""
DOCKER_REGISTRY="ghcr.io"
CLOUD_PLATFORM=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --targets) TARGETS="$2"; shift 2 ;;
    --strategy) STRATEGY="$2"; shift 2 ;;
    --project-type) PROJECT_TYPE="$2"; shift 2 ;;
    --package-manager) PACKAGE_MANAGER="$2"; shift 2 ;;
    --npm-scope) NPM_SCOPE="$2"; shift 2 ;;
    --docker-registry) DOCKER_REGISTRY="$2"; shift 2 ;;
    --cloud-platform) CLOUD_PLATFORM="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# Helper functions
log_info() {
  echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
  echo -e "${RED}✗${NC} $1"
}

log_section() {
  echo
  echo -e "${BOLD}${CYAN}$1${NC}"
  echo -e "${CYAN}$(printf '%.0s─' {1..50})${NC}"
}

# Ensure .github/workflows directory exists
ensure_github_workflows() {
  if [[ ! -d .github/workflows ]]; then
    mkdir -p .github/workflows
    log_info "Created .github/workflows directory"
  fi
}

# Create the main release workflow
create_release_workflow() {
  local workflow_file=".github/workflows/reusable-release.yml"
  
  log_section "📝 Creating Release Workflow"
  
  # Start with base workflow structure
  cat > "${workflow_file}" << 'EOF'
name: Release
on:
  workflow_call:
    inputs:
      environment:
        description: 'Deployment environment'
        type: string
        default: 'production'
      version-strategy:
        description: 'Version strategy (semantic, continuous, manual)'
        type: string
        default: 'semantic'
    secrets:
      NPM_TOKEN:
        required: false
      DOCKER_TOKEN:
        required: false
      VERCEL_TOKEN:
        required: false
      NETLIFY_TOKEN:
        required: false

jobs:
  release:
    name: Release Pipeline
    runs-on: ubuntu-latest
    permissions:
      contents: write
      packages: write
      id-token: write
    
    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Need full history for changelog

      - name: 🔍 Detect Configuration
        id: detect
        run: |
          # Detect what we're releasing
          echo "Analyzing project structure..."
EOF

  # Add package manager setup if needed
  if [[ "${TARGETS}" == *"npm"* ]] || [[ "${PROJECT_TYPE}" != "static" ]]; then
    cat >> "${workflow_file}" << EOF
          
      - name: 📦 Setup ${PACKAGE_MANAGER}
        if: '\${{ inputs.version-strategy != "docker-only" }}'
        uses: pnpm/action-setup@v4
        with:
          version: 9
          
      - name: 🟢 Setup Node.js
        if: '\${{ inputs.version-strategy != "docker-only" }}'
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: '${PACKAGE_MANAGER}'
          
      - name: 📚 Install dependencies
        if: '\${{ inputs.version-strategy != "docker-only" }}'
        run: ${PACKAGE_MANAGER} install --frozen-lockfile
EOF
  fi

  # Add version determination based on strategy
  if [[ "${STRATEGY}" == "semantic" ]]; then
    cat >> "${workflow_file}" << 'EOF'
          
      - name: 🔖 Determine Version
        id: version
        if: ${{ inputs.version-strategy == 'semantic' }}
        run: |
          # Analyze commits for semantic version bump
          COMMIT_MSG=$(git log -1 --pretty=%B)
          VERSION_BUMP="patch"
          
          if echo "${COMMIT_MSG}" | grep -q "BREAKING CHANGE"; then
            VERSION_BUMP="major"
          elif echo "${COMMIT_MSG}" | grep -q "^feat"; then
            VERSION_BUMP="minor"
          fi
          
          echo "version-bump=${VERSION_BUMP}" >> ${GITHUB_OUTPUT}
          echo "Detected version bump: ${VERSION_BUMP}"
EOF
  fi

  # Add NPM publishing if configured
  if [[ "${TARGETS}" == *"npm"* ]]; then
    add_npm_publishing "${workflow_file}"
  fi

  # Add Docker building if configured
  if [[ "${TARGETS}" == *"docker"* ]]; then
    add_docker_publishing "${workflow_file}"
  fi

  # Add GitHub releases if configured
  if [[ "${TARGETS}" == *"github"* ]]; then
    add_github_release "${workflow_file}"
  fi

  # Add cloud deployment if configured
  if [[ -n "${CLOUD_PLATFORM}" ]]; then
    add_cloud_deployment "${workflow_file}" "${CLOUD_PLATFORM}"
  fi

  # Add summary step
  cat >> "${workflow_file}" << 'EOF'
          
      - name: 📊 Release Summary
        if: always()
        run: |
          echo "## 🚀 Release Summary" >> ${GITHUB_STEP_SUMMARY}
          echo "" >> ${GITHUB_STEP_SUMMARY}
          echo "- **Strategy**: ${{ inputs.version-strategy }}" >> ${GITHUB_STEP_SUMMARY}
          echo "- **Environment**: ${{ inputs.environment }}" >> ${GITHUB_STEP_SUMMARY}
          echo "- **Status**: ${{ job.status }}" >> ${GITHUB_STEP_SUMMARY}
EOF

  log_info "Created ${workflow_file}"
}

# Add NPM publishing configuration
add_npm_publishing() {
  local workflow_file="$1"
  
  cat >> "${workflow_file}" << 'EOF'
          
      - name: 🏗️ Build Package
        if: ${{ inputs.version-strategy != 'docker-only' }}
        run: |
          if [[ -f "tsconfig.json" ]]; then
            echo "Building TypeScript project..."
            npm run build --if-present
          else
            echo "Running build script if present..."
            npm run build --if-present || echo "No build script found"
          fi
          
      - name: 📦 Configure NPM
        run: |
          echo "//registry.npmjs.org/:_authToken=${{ secrets.NPM_TOKEN }}" > ~/.npmrc
          npm config set registry https://registry.npmjs.org/
          
      - name: 🚀 Publish to NPM
        id: npm-publish
        run: |
          # Update version if semantic
          if [[ "${{ inputs.version-strategy }}" == "semantic" ]]; then
            npm version ${{ steps.version.outputs.version-bump }} --no-git-tag-version
            NEW_VERSION=$(node -p "require('./package.json').version")
            echo "version=${NEW_VERSION}" >> ${GITHUB_OUTPUT}
          fi
          
          # Publish package
          npm publish --access public
          
          echo "## 📦 NPM Package Published" >> ${GITHUB_STEP_SUMMARY}
          echo "- **Package**: $(node -p "require('./package.json').name")" >> ${GITHUB_STEP_SUMMARY}
          echo "- **Version**: $(node -p "require('./package.json').version")" >> ${GITHUB_STEP_SUMMARY}
EOF
}

# Add Docker publishing configuration
add_docker_publishing() {
  local workflow_file="$1"
  
  cat >> "${workflow_file}" << 'EOF'
          
      - name: 🐳 Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
        
      - name: 🔐 Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
          
      - name: 🏷️ Extract Docker metadata
        id: docker-meta
        uses: docker/metadata-action@v5
        with:
          images: ghcr.io/${{ github.repository }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha
            type=raw,value=latest,enable={{is_default_branch}}
            
      - name: 🏗️ Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.docker-meta.outputs.tags }}
          labels: ${{ steps.docker-meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          platforms: linux/amd64,linux/arm64
          
      - name: 🔒 Run security scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ghcr.io/${{ github.repository }}:latest
          format: 'sarif'
          output: 'trivy-results.sarif'
          
      - name: 📊 Docker Summary
        run: |
          echo "## 🐳 Docker Image Published" >> ${GITHUB_STEP_SUMMARY}
          echo "- **Registry**: ghcr.io" >> ${GITHUB_STEP_SUMMARY}
          echo "- **Image**: ghcr.io/${{ github.repository }}" >> ${GITHUB_STEP_SUMMARY}
EOF
}

# Add GitHub release configuration
add_github_release() {
  local workflow_file="$1"
  
  cat >> "${workflow_file}" << 'EOF'
          
      - name: 📋 Generate Changelog
        id: changelog
        run: |
          # Get commits since last tag
          LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
          
          if [[ -z "${LAST_TAG}" ]]; then
            echo "No previous tags found, including last 20 commits"
            COMMITS=$(git log --pretty=format:"- %s (%an)" -20)
          else
            echo "Generating changelog since ${LAST_TAG}"
            COMMITS=$(git log ${LAST_TAG}..HEAD --pretty=format:"- %s (%an)")
          fi
          
          # Generate changelog
          cat > CHANGELOG.md << EOL
          ## What's Changed
          
          ${COMMITS}
          
          **Full Changelog**: https://github.com/${{ github.repository }}/compare/${LAST_TAG}...${{ github.sha }}
          EOL
          
      - name: 🏷️ Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          tag_name: v${{ steps.npm-publish.outputs.version || github.run_number }}
          name: Release v${{ steps.npm-publish.outputs.version || github.run_number }}
          body_path: CHANGELOG.md
          draft: false
          prerelease: false
          generate_release_notes: true
EOF
}

# Add cloud deployment configuration
add_cloud_deployment() {
  local workflow_file="$1"
  local platform="$2"
  
  case "${platform}" in
    vercel)
      cat >> "${workflow_file}" << 'EOF'
          
      - name: ☁️ Deploy to Vercel
        run: |
          npm i -g vercel
          vercel --prod --token=${{ secrets.VERCEL_TOKEN }}
          
          echo "## ☁️ Deployed to Vercel" >> ${GITHUB_STEP_SUMMARY}
          echo "- **Environment**: Production" >> ${GITHUB_STEP_SUMMARY}
EOF
      ;;
    netlify)
      cat >> "${workflow_file}" << 'EOF'
          
      - name: ☁️ Deploy to Netlify
        uses: nwtgck/actions-netlify@v2.0
        with:
          publish-dir: './dist'
          production-branch: main
          github-token: ${{ secrets.GITHUB_TOKEN }}
          deploy-message: "Deploy from GitHub Actions"
        env:
          NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_TOKEN }}
          NETLIFY_SITE_ID: ${{ secrets.NETLIFY_SITE_ID }}
EOF
      ;;
    pages)
      cat >> "${workflow_file}" << 'EOF'
          
      - name: 📄 Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./dist
EOF
      ;;
  esac
}

# Update CI workflow to trigger releases
update_ci_workflow() {
  local ci_file=".github/workflows/ci.yml"
  
  if [[ ! -f "${ci_file}" ]]; then
    log_warn "No CI workflow found, skipping CI update"
    return
  fi
  
  log_section "🔄 Updating CI Workflow"
  
  # Check if release job already exists
  if grep -q "uses: ./.github/workflows/reusable-release.yml" "${ci_file}"; then
    log_info "Release job already configured in CI workflow"
    return
  fi
  
  # Add release job to CI workflow
  # This is simplified - in practice would need more sophisticated YAML manipulation
  log_info "Adding release trigger to CI workflow"
  
  cat >> "${ci_file}" << 'EOF'

  release:
    name: 🚀 Release
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    needs: [build]
    uses: ./.github/workflows/reusable-release.yml
    secrets: inherit
EOF
  
  log_info "Updated CI workflow with release trigger"
}

# Create secrets documentation
create_secrets_documentation() {
  local secrets_file=".github/SECRETS_REQUIRED.md"
  
  log_section "📋 Creating Secrets Documentation"
  
  cat > "${secrets_file}" << 'EOF'
# Required GitHub Secrets for Releases

Configure these secrets in your repository settings:
**Settings → Secrets and variables → Actions → New repository secret**

## Configured Release Targets
EOF

  # Add NPM documentation if needed
  if [[ "${TARGETS}" == *"npm"* ]]; then
    cat >> "${secrets_file}" << 'EOF'

### NPM_TOKEN
**Required for**: NPM package publishing
**How to obtain**:
1. Log in to [npmjs.com](https://www.npmjs.com)
2. Click your profile picture → Access Tokens
3. Click "Generate New Token"
4. Select "Automation" type
5. Copy the token (starts with `npm_`)
6. Add as `NPM_TOKEN` secret in GitHub

**Testing**:
```bash
# Test locally (don't commit this!)
echo "//registry.npmjs.org/:_authToken=YOUR_TOKEN" > ~/.npmrc
npm whoami
```
EOF
  fi

  # Add Vercel documentation if needed
  if [[ "${CLOUD_PLATFORM}" == "vercel" ]]; then
    cat >> "${secrets_file}" << 'EOF'

### VERCEL_TOKEN
**Required for**: Vercel deployments
**How to obtain**:
1. Log in to [vercel.com](https://vercel.com)
2. Go to Account Settings → Tokens
3. Create a new token with a descriptive name
4. Copy the token
5. Add as `VERCEL_TOKEN` secret in GitHub

**Project Setup**:
```bash
# Link your project (run locally)
npx vercel link
```
EOF
  fi

  # Add Netlify documentation if needed
  if [[ "${CLOUD_PLATFORM}" == "netlify" ]]; then
    cat >> "${secrets_file}" << 'EOF'

### NETLIFY_TOKEN & NETLIFY_SITE_ID
**Required for**: Netlify deployments
**How to obtain**:
1. Log in to [app.netlify.com](https://app.netlify.com)
2. Go to User Settings → Applications → Personal Access Tokens
3. Create a new token
4. Add as `NETLIFY_TOKEN` secret
5. Go to your site → Site Settings → General → Site ID
6. Add as `NETLIFY_SITE_ID` secret
EOF
  fi

  # Add testing instructions
  cat >> "${secrets_file}" << 'EOF'

## Testing Your Release Configuration

1. **Verify secrets are set**:
   ```bash
   gh secret list
   ```

2. **Test release locally** (dry run):
   ```bash
   # For NPM
   npm version patch --dry-run
   
   # For Docker
   docker build -t test:latest .
   ```

3. **Trigger a test release**:
   ```bash
   # Create a test branch
   git checkout -b test-release
   
   # Make a small change
   echo "test" >> test.txt
   git add . && git commit -m "test: release workflow"
   
   # Push and create PR
   git push origin test-release
   gh pr create --title "Test release" --body "Testing release workflow"
   ```

4. **Monitor the workflow**:
   - Go to Actions tab in GitHub
   - Watch the release workflow execute
   - Check for any errors

## Troubleshooting

### NPM Publishing Issues
- Ensure package.json has `"name"` field
- Check `"private": false` or remove `"private"` field
- Verify NPM_TOKEN has "Automation" permissions
- Check if package name already exists on NPM

### Docker Build Issues
- Ensure Dockerfile exists and is valid
- Check multi-platform compatibility
- Verify GITHUB_TOKEN has packages:write permission

### Deployment Issues
- Verify deployment tokens are valid
- Check build output directory matches configuration
- Ensure environment variables are set correctly

## Security Best Practices

1. **Never commit tokens** to the repository
2. **Rotate tokens** regularly (every 90 days)
3. **Use least privilege** - only grant necessary permissions
4. **Enable 2FA** on all service accounts
5. **Audit secret usage** in workflow runs

## Additional Resources

- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [NPM Automation Tokens](https://docs.npmjs.com/creating-and-viewing-access-tokens)
- [Docker Hub Access Tokens](https://docs.docker.com/docker-hub/access-tokens/)
- [Vercel Tokens](https://vercel.com/docs/rest-api#authentication)
EOF

  log_info "Created ${secrets_file}"
}

# Update package.json for NPM publishing
configure_npm_publishing() {
  if [[ "${TARGETS}" != *"npm"* ]]; then
    return
  fi
  
  if [[ ! -f "package.json" ]]; then
    log_warn "No package.json found, skipping NPM configuration"
    return
  fi
  
  log_section "📦 Configuring NPM Publishing"
  
  # Use Node.js to update package.json
  node -e "
    const fs = require('fs');
    const pkg = require('./package.json');
    
    // Ensure required fields
    if (!pkg.name) {
      console.error('ERROR: package.json must have a name field');
      process.exit(1);
    }
    
    // Add publishing configuration
    pkg.publishConfig = pkg.publishConfig || {
      access: 'public',
      registry: 'https://registry.npmjs.org/'
    };
    
    // Add repository if missing
    if (!pkg.repository) {
      const { execSync } = require('child_process');
      const origin = execSync('git remote get-url origin').toString().trim();
      pkg.repository = {
        type: 'git',
        url: origin
      };
    }
    
    // Add files field for libraries
    if ('${PROJECT_TYPE}' === 'library' && !pkg.files) {
      pkg.files = ['dist', 'lib', 'src', 'index.js', 'index.d.ts', 'README.md', 'LICENSE']
        .filter(f => {
          const path = require('path');
          const fs = require('fs');
          try {
            fs.accessSync(f);
            return true;
          } catch {
            return false;
          }
        });
    }
    
    // Add version scripts
    pkg.scripts = pkg.scripts || {};
    pkg.scripts['prepublishOnly'] = pkg.scripts['prepublishOnly'] || 
      '${PACKAGE_MANAGER} run build --if-present && ${PACKAGE_MANAGER} test --if-present';
    
    fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\\n');
    console.log('✓ Updated package.json for NPM publishing');
  " || log_error "Failed to update package.json"
}

# Create or update Dockerfile for Docker releases
configure_docker() {
  if [[ "${TARGETS}" != *"docker"* ]]; then
    return
  fi
  
  log_section "🐳 Configuring Docker"
  
  if [[ ! -f "Dockerfile" ]]; then
    log_info "Creating optimized Dockerfile"
    
    if [[ -f "package.json" ]]; then
      # Node.js Dockerfile
      cat > Dockerfile << 'EOF'
# Build stage
FROM node:20-alpine AS builder
WORKDIR /app

# Copy dependency files
COPY package*.json ./
COPY pnpm-lock.yaml* ./
COPY yarn.lock* ./

# Install dependencies
RUN if [ -f pnpm-lock.yaml ]; then \
      npm install -g pnpm && pnpm install --frozen-lockfile; \
    elif [ -f yarn.lock ]; then \
      yarn install --frozen-lockfile; \
    else \
      npm ci; \
    fi

# Copy source code
COPY . .

# Build application
RUN npm run build --if-present

# Production stage
FROM node:20-alpine
WORKDIR /app

# Install production dependencies only
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Copy built application
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/public ./public 2>/dev/null || true

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001
USER nodejs

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})" \
  || exit 1

EXPOSE 3000
CMD ["node", "dist/index.js"]
EOF
    else
      log_warn "Cannot determine project type for Dockerfile"
    fi
    
    # Create .dockerignore
    cat > .dockerignore << 'EOF'
node_modules
npm-debug.log
.env
.env.*
!.env.example
.git
.gitignore
.github
.vscode
.idea
*.md
.DS_Store
coverage
.nyc_output
dist
*.test.*
*.spec.*
__tests__
test
tests
EOF
    
    log_info "Created Dockerfile and .dockerignore"
  else
    log_info "Dockerfile already exists, skipping creation"
  fi
}

# Main execution
main() {
  echo -e "${BOLD}${CYAN}🚀 Configuring Release Automation${NC}"
  echo -e "${CYAN}$(printf '%.0s═' {1..50})${NC}"
  
  # Validate environment
  if [[ ! -d .git ]]; then
    log_error "Not a git repository"
    exit 1
  fi
  
  # Create necessary directories
  ensure_github_workflows
  
  # Configure based on targets
  log_section "🎯 Configuring Release Targets"
  echo "  Targets: ${TARGETS:-none}"
  echo "  Strategy: ${STRATEGY}"
  echo "  Project Type: ${PROJECT_TYPE}"
  
  # Create main release workflow
  create_release_workflow
  
  # Update CI workflow to trigger releases
  update_ci_workflow
  
  # Configure NPM if needed
  configure_npm_publishing
  
  # Configure Docker if needed
  configure_docker
  
  # Create secrets documentation
  create_secrets_documentation
  
  # Success summary
  echo
  echo -e "${BOLD}${GREEN}✅ Release Configuration Complete!${NC}"
  echo
  echo "Configured releases for:"
  
  if [[ "${TARGETS}" == *"npm"* ]]; then
    echo "  📦 NPM package publishing"
  fi
  
  if [[ "${TARGETS}" == *"docker"* ]]; then
    echo "  🐳 Docker image to ${DOCKER_REGISTRY}"
  fi
  
  if [[ "${TARGETS}" == *"github"* ]]; then
    echo "  🏷️ GitHub releases with changelog"
  fi
  
  if [[ -n "${CLOUD_PLATFORM}" ]]; then
    echo "  ☁️ ${CLOUD_PLATFORM} deployment"
  fi
  
  echo
  echo "Next steps:"
  echo "  1. Review: cat .github/workflows/reusable-release.yml"
  echo "  2. Add secrets: See .github/SECRETS_REQUIRED.md"
  echo "  3. Test build: ${PACKAGE_MANAGER} run build"
  echo "  4. Commit: git add . && git commit -m 'Configure releases'"
  echo "  5. Ship: /ship"
  echo
  echo -e "${YELLOW}⚠️  Don't forget to add required secrets!${NC}"
  echo "  See .github/SECRETS_REQUIRED.md for instructions"
}

# Run main function
main "$@"