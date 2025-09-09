# NPM Release Setup

This document explains how to set up NPM publishing for the Han-Solo installer.

## Prerequisites

1. **NPM Account**: You need an npm account with publish permissions for the `han-solo-installer` package.
2. **NPM Token**: Generate an automation token from npm.

## Generating NPM Token

1. Log in to [npmjs.com](https://www.npmjs.com/)
2. Click on your profile icon → Access Tokens
3. Click "Generate New Token"
4. Select "Automation" type (for CI/CD)
5. Copy the token (it starts with `npm_`)

## Adding Token to GitHub

1. Go to your repository settings on GitHub
2. Navigate to Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Name: `NPM_TOKEN`
5. Value: Paste your npm token
6. Click "Add secret"

## How It Works

When code is merged to main or when manually triggered:

1. The CI workflow generates a version number (date-based or manual)
2. Updates the `package.json` version in the installer directory
3. Publishes to npm with public access
4. Creates a GitHub Release with:
   - Link to the npm package
   - Commit history
   - Installation instructions
   - No zip files attached (package is on npm)

## Manual Release

You can trigger a manual release from the Actions tab:

1. Go to Actions → CI workflow
2. Click "Run workflow"
3. Optionally provide a custom version (e.g., "1.2.3")
4. Click "Run workflow"

## Version Format

- **Automatic**: `YYYY.MM.DD-{run_number}` (e.g., 2025.09.09-42)
- **Manual**: Any valid semver (e.g., 1.2.3, 2.0.0-beta.1)

## Verifying Releases

After a release:
- Check npm: https://www.npmjs.com/package/han-solo-installer
- Check GitHub Releases: https://github.com/slamb2k/han-solo/releases
- Test installation: `npx han-solo-installer@latest`