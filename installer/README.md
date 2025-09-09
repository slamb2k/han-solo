# Han-Solo Installer

Interactive installer for Han-Solo Claude Code tools with a beautiful terminal UI.

## 🚀 Quick Start

Run the installer directly with npx (no installation required):

```bash
npx @han-solo/installer
```

## ✨ Features

- **Beautiful TUI** - Modern terminal interface with colors and ASCII art
- **Interactive Selection** - Choose components with arrow keys and checkboxes
- **Smart Profiles** - Pre-configured profiles for different workflows
- **Flexible Installation** - Install globally or per-project
- **Auto-Download** - Automatically fetches latest files from GitHub
- **No Dependencies** - Runs temporarily via npx

## 📦 Installation Options

### Project Installation (Recommended)
Installs to `.claude/` in current directory:
```bash
npx @han-solo/installer
# Select "Project" when prompted
```

### Global Installation
Installs to `~/.claude/` for all projects:
```bash
npx @han-solo/installer
# Select "Global" when prompted
```

## 🎯 Profiles

### Solo Developer
Full suite for independent development:
- Commands (/ship, /bootstrap, /fresh)
- Agents (bootstrap-guardian, git-shipper)
- Status Lines
- Utility Scripts

### Team Workflow
Collaborative development tools:
- Commands
- Agents
- Git Hooks

### Minimal
Essential commands only:
- Commands

### Custom
Choose your own components

## 🎨 Components

- **Commands** - Core workflow commands (/ship, /bootstrap, /fresh)
- **Agents** - Specialized sub-agents for complex tasks
- **Status Lines** - Real-time git status indicators
- **Scripts** - Utility scripts and helpers
- **Hooks** - Git hooks for pre-commit and pre-push

## 🔧 Advanced Usage

### Run Specific Version
```bash
npx @han-solo/installer@1.0.0
```

### Use with Node
```javascript
const HanSoloInstaller = require('@han-solo/installer');
const installer = new HanSoloInstaller();
installer.run();
```

## 📚 Documentation

For more information about Han-Solo:
- [GitHub Repository](https://github.com/slamb2k/han-solo)
- [Full Documentation](https://github.com/slamb2k/han-solo/blob/main/README.md)

## 📄 License

MIT