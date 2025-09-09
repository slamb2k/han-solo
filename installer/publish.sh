#!/bin/bash

# Publish script for @han-solo/installer package

set -e

echo "📦 Preparing to publish @han-solo/installer..."

# Check if logged into npm
if ! npm whoami &>/dev/null; then
  echo "❌ Not logged into npm. Please run 'npm login' first."
  exit 1
fi

# Clean any previous builds
rm -rf node_modules package-lock.json

# Install fresh dependencies
echo "📥 Installing dependencies..."
npm install

# Run any tests (when we have them)
# npm test

# Publish to npm
echo "🚀 Publishing to npm..."
npm publish --access public

echo "✅ Successfully published @han-solo/installer!"
echo ""
echo "Users can now install with:"
echo "  npx @han-solo/installer"