#!/usr/bin/env bash
# scaffold-release.sh - Deterministic release configuration for reusable-release.yml
# This script configures the actual release implementation based on deployment targets

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Configuration from command line arguments
LANGUAGE=""
DEPLOY_TARGETS=""  # npm,docker,github,vercel,pages
RELEASE_STRATEGY=""  # semantic,manual,continuous
PACKAGE_MANAGER="pnpm"
MODE="standard"  # minimal, standard, comprehensive
PROJECT_TYPE=""  # library, application, monorepo

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --language) LANGUAGE="$2"; shift 2 ;;
    --deploy-targets) DEPLOY_TARGETS="$2"; shift 2 ;;
    --release-strategy) RELEASE_STRATEGY="$2"; shift 2 ;;
    --package-manager) PACKAGE_MANAGER="$2"; shift 2 ;;
    --project-type) PROJECT_TYPE="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
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

log_section() {
  echo
  echo -e "${BOLD}${CYAN}$1${NC}"
  echo -e "${CYAN}$(printf '%.0s─' {1..50})${NC}"
}

# Configure NPM publishing workflow
configure_npm_release() {
  cat << 'EOF'
      
      - name: 📦 Setup NPM publishing
        if: contains(inputs.targets, 'npm')
        run: |
          echo "//registry.npmjs.org/:_authToken=${ secrets.NPM_TOKEN }" > ~/.npmrc
          
      - name: 🔖 Bump version
        if: contains(inputs.targets, 'npm') && inputs.strategy == 'semantic'
        id: version
        run: |
          # Determine version bump based on commits
          if git log -1 --pretty=%B | grep -q "BREAKING CHANGE"; then
            VERSION_BUMP="major"
          elif git log -1 --pretty=%B | grep -q "^feat"; then
            VERSION_BUMP="minor"
          else
            VERSION_BUMP="patch"
          fi
          
          # Bump version
          npm version ${VERSION_BUMP} --no-git-tag-version
          NEW_VERSION=$(node -p "require('./package.json').version")
          echo "version=${NEW_VERSION}" >> ${GITHUB_OUTPUT}
          
      - name: 📚 Build package
        if: contains(inputs.targets, 'npm')
        run: ${ inputs.package-manager } run build
        
      - name: 🚀 Publish to NPM
        if: contains(inputs.targets, 'npm')
        run: |
          if [[ "${ inputs.package-manager }" = "pnpm" ]]; then
            pnpm publish --no-git-checks
          else
            npm publish
          fi
          
      - name: 📝 Create NPM release notes
        if: contains(inputs.targets, 'npm') && success()
        run: |
          echo "## 📦 NPM Package Released" >> ${GITHUB_STEP_SUMMARY}
          echo "" >> ${GITHUB_STEP_SUMMARY}
          echo "- **Version**: ${ steps.version.outputs.version }" >> ${GITHUB_STEP_SUMMARY}
          echo "- **Package**: $(node -p "require('./package.json').name")" >> ${GITHUB_STEP_SUMMARY}
          echo "- **Registry**: https://www.npmjs.com/package/$(node -p "require('./package.json').name")" >> ${GITHUB_STEP_SUMMARY}
EOF
}

# Configure Docker release workflow
configure_docker_release() {
  cat << 'EOF'
      
      - name: 🐳 Set up Docker Buildx
        if: contains(inputs.targets, 'docker')
        uses: docker/setup-buildx-action@v3
        
      - name: 🔐 Log in to GitHub Container Registry
        if: contains(inputs.targets, 'docker')
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${ github.actor }
          password: ${ secrets.GITHUB_TOKEN }
          
      - name: 🏷️ Extract metadata
        if: contains(inputs.targets, 'docker')
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ghcr.io/${ github.repository }
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}
            type=semver,pattern={{major}.{{minor}
            type=sha
            type=raw,value=latest,enable={{is_default_branch}
            
      - name: 🏗️ Build and push Docker image
        if: contains(inputs.targets, 'docker')
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${ steps.meta.outputs.tags }
          labels: ${ steps.meta.outputs.labels }
          cache-from: type=gha
          cache-to: type=gha,mode=max
          
      - name: 📝 Docker release notes
        if: contains(inputs.targets, 'docker') && success()
        run: |
          echo "## 🐳 Docker Image Released" >> ${GITHUB_STEP_SUMMARY}
          echo "" >> ${GITHUB_STEP_SUMMARY}
          echo "- **Registry**: ghcr.io" >> ${GITHUB_STEP_SUMMARY}
          echo "- **Image**: ghcr.io/${ github.repository }" >> ${GITHUB_STEP_SUMMARY}
          echo "- **Tags**: ${ steps.meta.outputs.tags }" >> ${GITHUB_STEP_SUMMARY}
EOF
}

# Configure GitHub release workflow
configure_github_release() {
  cat << 'EOF'
      
      - name: 📋 Generate changelog
        if: contains(inputs.targets, 'github')
        id: changelog
        run: |
          # Get commits since last tag
          LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
          if [[ -z "${LAST_TAG}" ]]; then
            COMMITS=$(git log --pretty=format:"- %s (%an)" -10)
          else
            COMMITS=$(git log ${LAST_TAG}..HEAD --pretty=format:"- %s (%an)")
          fi
          
          # Generate changelog
          cat > CHANGELOG.md << EOL
          ## What's Changed
          
          ${COMMITS}
          
          **Full Changelog**: https://github.com/${ github.repository }/compare/${LAST_TAG}...v${ steps.version.outputs.version || github.sha }
          EOL
          
      - name: 🏷️ Create GitHub Release
        if: contains(inputs.targets, 'github')
        uses: softprops/action-gh-release@v1
        with:
          tag_name: v${ steps.version.outputs.version || github.run_number }
          name: Release v${ steps.version.outputs.version || github.run_number }
          body_path: CHANGELOG.md
          draft: false
          prerelease: false
          generate_release_notes: true
EOF
}

# Configure cloud deployment (Vercel/Netlify)
configure_cloud_deployment() {
  cat << 'EOF'
      
      - name: ☁️ Deploy to Vercel
        if: contains(inputs.targets, 'vercel')
        run: |
          npm i -g vercel
          vercel --prod --token=${ secrets.VERCEL_TOKEN }
          
      - name: 📝 Vercel deployment notes
        if: contains(inputs.targets, 'vercel') && success()
        run: |
          echo "## ☁️ Deployed to Vercel" >> ${GITHUB_STEP_SUMMARY}
          echo "" >> ${GITHUB_STEP_SUMMARY}
          echo "- **Environment**: Production" >> ${GITHUB_STEP_SUMMARY}
          echo "- **URL**: https://${ github.event.repository.name }.vercel.app" >> ${GITHUB_STEP_SUMMARY}
EOF
}

# Create the main release workflow
create_release_workflow() {
  local workflow_file=".github/workflows/reusable-release.yml"
  
  log_info "Creating release workflow for targets: ${DEPLOY_TARGETS}"
  
  # Start workflow
  cat > "$workflow_file" << EOF
name: Release
on:
  workflow_call:
    inputs:
      environment:
        description: 'Deployment environment'
        type: string
        default: 'production'
      targets:
        description: 'Release targets (comma-separated: npm,docker,github,vercel)'
        type: string
        default: '${DEPLOY_TARGETS}'
      strategy:
        description: 'Release strategy (semantic, manual, continuous)'
        type: string
        default: '${RELEASE_STRATEGY}'
      package-manager:
        description: 'Package manager'
        type: string
        default: '${PACKAGE_MANAGER}'
    secrets:
      NPM_TOKEN:
        required: false
      VERCEL_TOKEN:
        required: false
      DEPLOY_TOKEN:
        required: false

jobs:
  release:
    name: Release to \${ inputs.targets }
    runs-on: ubuntu-latest
    environment: \${ inputs.environment }
    permissions:
      contents: write
      packages: write
      id-token: write
    
    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Need full history for changelog
          
      - name: 📦 Setup pnpm
        if: inputs.package-manager == 'pnpm'
        uses: pnpm/action-setup@v4
        
      - name: 🟢 Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: \${ inputs.package-manager }
          
      - name: 📚 Install dependencies
        run: |
          if [[ "\${ inputs.package-manager }" = "npm" ]]; then
            npm ci
          elif [[ "\${ inputs.package-manager }" = "pnpm" ]]; then
            pnpm install --frozen-lockfile
          else
            yarn install --frozen-lockfile
          fi
EOF
  
  # Add target-specific configurations
  if [[ "${DEPLOY_TARGETS}" == *"npm"* ]]; then
    configure_npm_release >> "$workflow_file"
  fi
  
  if [[ "${DEPLOY_TARGETS}" == *"docker"* ]]; then
    configure_docker_release >> "$workflow_file"
  fi
  
  if [[ "${DEPLOY_TARGETS}" == *"github"* ]]; then
    configure_github_release >> "$workflow_file"
  fi
  
  if [[ "${DEPLOY_TARGETS}" == *"vercel"* ]] || [[ "${DEPLOY_TARGETS}" == *"netlify"* ]]; then
    configure_cloud_deployment >> "$workflow_file"
  fi
  
  # Complete workflow
  cat >> "$workflow_file" << 'EOF'
          
      - name: 📊 Release Summary
        if: always()
        run: |
          echo "## 🚀 Release Summary" >> ${GITHUB_STEP_SUMMARY}
          echo "" >> ${GITHUB_STEP_SUMMARY}
          echo "- **Strategy**: ${ inputs.strategy }" >> ${GITHUB_STEP_SUMMARY}
          echo "- **Targets**: ${ inputs.targets }" >> ${GITHUB_STEP_SUMMARY}
          echo "- **Environment**: ${ inputs.environment }" >> ${GITHUB_STEP_SUMMARY}
          echo "- **Status**: ${ job.status }" >> ${GITHUB_STEP_SUMMARY}
          
      - name: 🔔 Notify on success
        if: success()
        run: |
          echo "::notice::Successfully released to: ${ inputs.targets }"
          
      - name: ❌ Notify on failure
        if: failure()
        run: |
          echo "::error::Release failed for targets: ${ inputs.targets }"
EOF
}

# Update package.json for releases
update_package_json() {
  if [[ "${LANGUAGE}" != "javascript" ]] && [[ "${LANGUAGE}" != "typescript" ]]; then
    return
  fi
  
  if [[ "${DEPLOY_TARGETS}" != *"npm"* ]]; then
    return
  fi
  
  log_section "📝 Updating package.json for NPM publishing"
  
  if [[ ! -f "package.json" ]]; then
    log_warn "No package.json found"
    return
  fi
  
  # Update package.json with publishing configuration
  node -e "
    const fs = require('fs');
    const pkg = require('./package.json');
    
    // Ensure required fields for publishing
    if (!pkg.name) {
      console.error('Package name is required for NPM publishing');
      process.exit(1);
    }
    
    // Add publishing configuration if not present
    if (!pkg.publishConfig) {
      pkg.publishConfig = {
        access: 'public',
        registry: 'https://registry.npmjs.org/'
      };
    }
    
    // Add repository field if not present
    if (!pkg.repository) {
      const origin = require('child_process')
        .execSync('git remote get-url origin')
        .toString()
        .trim();
      pkg.repository = {
        type: 'git',
        url: origin
      };
    }
    
    // Add files field if not present
    if (!pkg.files && '${PROJECT_TYPE}' === 'library') {
      pkg.files = ['dist', 'lib', 'esm', 'cjs', 'README.md', 'LICENSE'];
    }
    
    // Add release scripts
    pkg.scripts = pkg.scripts || {};
    pkg.scripts['prepublishOnly'] = pkg.scripts['prepublishOnly'] || '${PACKAGE_MANAGER} run build && ${PACKAGE_MANAGER} test';
    pkg.scripts['version'] = pkg.scripts['version'] || 'git add -A .';
    pkg.scripts['postversion'] = pkg.scripts['postversion'] || 'git push && git push --tags';
    
    fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
    console.log('✓ Updated package.json for NPM publishing');
  " || log_warn "Could not update package.json"
}

# Create GitHub Actions secrets documentation
create_secrets_doc() {
  log_section "📋 Creating secrets documentation"
  
  local secrets_file=".github/SECRETS_REQUIRED.md"
  
  cat > "$secrets_file" << EOF
# Required GitHub Secrets

Configure these secrets in your repository settings under Settings → Secrets → Actions:

## Secrets needed for your release configuration:
EOF
  
  if [[ "${DEPLOY_TARGETS}" == *"npm"* ]]; then
    cat >> "$secrets_file" << 'EOF'

### NPM_TOKEN
- **Required for**: NPM package publishing
- **How to get**: 
  1. Log in to npmjs.com
  2. Go to Access Tokens in your account settings
  3. Generate a new token with "Automation" type
  4. Copy the token and add it as a secret

EOF
  fi
  
  if [[ "${DEPLOY_TARGETS}" == *"vercel"* ]]; then
    cat >> "$secrets_file" << 'EOF'

### VERCEL_TOKEN
- **Required for**: Vercel deployments
- **How to get**:
  1. Log in to vercel.com
  2. Go to Account Settings → Tokens
  3. Create a new token
  4. Copy the token and add it as a secret

EOF
  fi
  
  cat >> "$secrets_file" << 'EOF'
## Adding secrets:

1. Go to: https://github.com/YOUR_ORG/YOUR_REPO/settings/secrets/actions
2. Click "New repository secret"
3. Add the secret name and value
4. Click "Add secret"

## Testing your release:

After adding secrets, test your release workflow:
```bash
# Create a test release branch
git checkout -b test-release

# Make a small change
echo "test" >> test.txt

# Commit and push
git add . && git commit -m "test: release workflow"
git push origin test-release

# Create a PR and merge to trigger release
gh pr create --title "Test release" --body "Testing release workflow"
```
EOF
  
  log_info "Created secrets documentation at $secrets_file"
}

# Main execution
main() {
  # Display colorful banner
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  "${SCRIPT_DIR}/block-text.sh" -s "SCAFFOLDING RELEASE"
  
  log_section "📋 Configuration Summary"
  echo "  Language: ${LANGUAGE}"
  echo "  Deploy Targets: ${DEPLOY_TARGETS}"
  echo "  Release Strategy: ${RELEASE_STRATEGY}"
  echo "  Project Type: ${PROJECT_TYPE}"
  echo "  Mode: ${MODE}"
  
  # Create release workflow
  log_section "🔧 Configuring Release Workflow"
  create_release_workflow
  log_info "Release workflow configured successfully"
  
  # Update package.json if needed
  update_package_json
  
  # Create secrets documentation
  create_secrets_doc
  
  # Summary
  echo
  echo -e "${BOLD}${GREEN}✅ Release Configuration Complete!${NC}"
  echo
  echo "Configured releases for:"
  for target in ${DEPLOY_TARGETS//,/ }; do
    case $target in
      npm) echo "  📦 NPM package publishing" ;;
      docker) echo "  🐳 Docker image to GHCR" ;;
      github) echo "  🏷️ GitHub releases with changelog" ;;
      vercel) echo "  ☁️ Vercel deployment" ;;
      netlify) echo "  ☁️ Netlify deployment" ;;
      pages) echo "  📄 GitHub Pages deployment" ;;
    esac
  done
  echo
  echo "Next steps:"
  echo "  1. Review workflow: cat .github/workflows/reusable-release.yml"
  echo "  2. Add secrets: cat .github/SECRETS_REQUIRED.md"
  echo "  3. Commit changes: git add . && git commit -m 'Configure releases'"
  echo "  4. Ship: /ship"
  echo
  echo -e "${YELLOW}⚠️  Don't forget to add required secrets to GitHub!${NC}"
  echo "  See .github/SECRETS_REQUIRED.md for details"
}

# Run main function
