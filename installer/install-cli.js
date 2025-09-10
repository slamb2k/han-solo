#!/usr/bin/env node

/**
 * Han-Solo CLI Installer (Alternative)
 * Uses inquirer for better compatibility
 */

const inquirer = require('inquirer');
const chalk = require('chalk');
const fs = require('fs-extra');
const path = require('path');
const ora = require('ora');
const boxen = require('boxen');
const gradient = require('gradient-string');
const figlet = require('figlet');
const { execSync } = require('child_process');

// Configuration
const REPO_URL = 'https://github.com/slamb2k/han-solo';

const COMPONENTS = {
  commands: {
    name: 'Commands',
    description: 'Core workflow commands (/ship, /bootstrap, /fresh)',
    path: '.claude/commands',
    selected: true
  },
  agents: {
    name: 'Agents',
    description: 'Specialized sub-agents (bootstrap-guardian, git-shipper)',
    path: '.claude/agents',
    selected: true
  },
  status_lines: {
    name: 'Status Lines',
    description: 'Real-time git status indicators',
    path: '.claude/status_lines',
    selected: true
  },
  scripts: {
    name: 'Utility Scripts',
    description: 'Helper scripts and tools',
    path: 'scripts',
    selected: false
  },
  hooks: {
    name: 'Git Hooks',
    description: 'Pre-commit and pre-push hooks',
    path: 'hooks',
    selected: false
  }
};

const PROFILES = {
  solo: {
    name: 'Solo Developer',
    description: 'Full suite for independent development',
    components: ['commands', 'agents', 'status_lines', 'scripts']
  },
  team: {
    name: 'Team Workflow',
    description: 'Collaborative development tools',
    components: ['commands', 'agents', 'hooks']
  },
  minimal: {
    name: 'Minimal',
    description: 'Essential commands only',
    components: ['commands']
  },
  custom: {
    name: 'Custom',
    description: 'Choose your own components',
    components: []
  }
};

class HanSoloInstaller {
  constructor() {
    this.state = {
      scope: 'project',
      profile: 'solo',
      selectedComponents: [],
      installPath: '',
      sourceDir: ''
    };
  }

  async run() {
    try {
      await this.showWelcome();
      await this.findSourceDirectory();
      console.log();
      await this.promptInstallation();
      await this.performInstallation();
      this.showSuccess();
    } catch (error) {
      console.error(chalk.red('\n✗ Installation failed:'), error.message);
      process.exit(1);
    }
  }

  async showWelcome() {
    console.clear();
    
    // Han-Solo ASCII art banner - matching the bash scripts
    console.log(chalk.rgb(255, 215, 0)('╔════════════════════════════════════════════════════════════════════════════════════════╗'));
    console.log(chalk.rgb(255, 215, 0)('║  __    __       ___       __   __               _______   ______    __        ______   ║'));
    console.log(chalk.rgb(255, 185, 0)('║ |  |  |  |     /   \\     |  \\ |  |             /       | /  __  \\  |  |      /  __  \\  ║'));
    console.log(chalk.rgb(255, 165, 0)('║ |  |__|  |    /  ^  \\    |   \\|  |  ______    |   (----`|  |  |  | |  |     |  |  |  | ║'));
    console.log(chalk.rgb(255, 140, 0)('║ |   __   |   /  /_\\  \\   |  . `  | |______|    \\   \\    |  |  |  | |  |     |  |  |  | ║'));
    console.log(chalk.rgb(255, 215, 100)('║ |  |  |  |  /  _____  \\  |  |\\   |         .----)   |   |  `--\'  | |  `----.|  `--\'  | ║'));
    console.log(chalk.rgb(255, 185, 50)('║ |__|  |__| /__/     \\__\\ |__| \\__|         |_______/     \\______/  |_______| \\______/  ║'));
    console.log(chalk.rgb(205, 133, 0)('║                                                                                        ║'));
    console.log(chalk.rgb(205, 133, 0)('╚════════════════════════════════════════════════════════════════════════════════════════╝'));
    console.log();
    console.log(chalk.cyan.bold('                    🚀 Git Workflow Automation for Solo Developers'));
    console.log();
    
    const welcomeBox = boxen(
      chalk.yellow('Welcome to the Han-Solo Interactive Installer!\n\n') +
      'This installer will help you set up:\n' +
      chalk.green('  • ') + 'Workflow commands (/ship, /bootstrap, /fresh)\n' +
      chalk.green('  • ') + 'Intelligent git agents\n' +
      chalk.green('  • ') + 'Real-time status indicators\n' +
      chalk.green('  • ') + 'Repository governance tools',
      {
        padding: 1,
        borderStyle: 'round',
        borderColor: 'cyan'
      }
    );
    
    console.log(welcomeBox);
  }

  async findSourceDirectory() {
    const spinner = ora('Detecting installation source...').start();
    
    // Check if we're running from the repo
    const localPath = path.join(__dirname, '..');
    if (await fs.pathExists(path.join(localPath, '.claude'))) {
      this.state.sourceDir = localPath;
      spinner.succeed('Found local installation files');
      return;
    }

    // Check for bundled files (when published to npm)
    const bundledPath = path.join(__dirname, 'files');
    if (await fs.pathExists(bundledPath)) {
      this.state.sourceDir = bundledPath;
      spinner.succeed('Found bundled installation files');
      return;
    }

    // Clone from GitHub as fallback
    spinner.text = 'Downloading from GitHub...';
    const tempDir = path.join(require('os').tmpdir(), 'han-solo-install-' + Date.now());
    
    try {
      await fs.ensureDir(tempDir);
      execSync(`git clone --depth 1 ${REPO_URL} ${tempDir}`, { 
        stdio: 'ignore' 
      });
      this.state.sourceDir = tempDir;
      spinner.succeed('Downloaded installation files from GitHub');
    } catch (error) {
      // Try using curl/wget as fallback
      spinner.text = 'Git not available, trying alternative download...';
      try {
        const zipUrl = `${REPO_URL}/archive/refs/heads/main.zip`;
        const zipPath = path.join(tempDir, 'han-solo.zip');
        
        // Try curl first, then wget
        try {
          execSync(`curl -L ${zipUrl} -o ${zipPath}`, { stdio: 'ignore' });
        } catch {
          execSync(`wget ${zipUrl} -O ${zipPath}`, { stdio: 'ignore' });
        }
        
        execSync(`unzip -q ${zipPath} -d ${tempDir}`, { stdio: 'ignore' });
        this.state.sourceDir = path.join(tempDir, 'han-solo-main');
        spinner.succeed('Downloaded installation files');
      } catch {
        spinner.fail('Failed to download installation files');
        throw new Error('Could not download Han-Solo files. Please check your internet connection.');
      }
    }
  }

  async promptInstallation() {
    // Scope selection
    const { scope } = await inquirer.prompt([
      {
        type: 'list',
        name: 'scope',
        message: 'Where would you like to install Han-Solo?',
        choices: [
          {
            name: 'Project (current directory only)',
            value: 'project',
            short: 'Project'
          },
          {
            name: 'Global (all projects)',
            value: 'global',
            short: 'Global'
          }
        ],
        default: 'project'
      }
    ]);
    this.state.scope = scope;

    console.log();

    // Profile selection
    const { profile } = await inquirer.prompt([
      {
        type: 'list',
        name: 'profile',
        message: 'Select installation profile:',
        choices: Object.entries(PROFILES).map(([key, prof]) => ({
          name: `${chalk.yellow(prof.name)} - ${chalk.gray(prof.description)}`,
          value: key,
          short: prof.name
        })),
        default: 'solo'
      }
    ]);
    this.state.profile = profile;

    // Component selection for custom profile
    if (profile === 'custom') {
      const { components } = await inquirer.prompt([
        {
          type: 'checkbox',
          name: 'components',
          message: 'Select components to install:',
          choices: Object.entries(COMPONENTS).map(([key, comp]) => ({
            name: `${comp.name} - ${chalk.gray(comp.description)}`,
            value: key,
            checked: comp.selected
          })),
          validate: (answer) => {
            if (answer.length < 1) {
              return 'You must choose at least one component.';
            }
            return true;
          }
        }
      ]);
      this.state.selectedComponents = components;
    } else {
      this.state.selectedComponents = PROFILES[profile].components;
    }

    // Set install path
    this.state.installPath = this.state.scope === 'global'
      ? path.join(require('os').homedir(), '.claude')
      : path.join(process.cwd(), '.claude');

    // No need to ask about status line type anymore - just use han-solo.sh

    // Confirmation
    console.log();
    console.log(boxen(
      chalk.cyan.bold('Installation Summary\n\n') +
      chalk.yellow('Scope: ') + (this.state.scope === 'global' ? 'Global' : 'Project') + '\n' +
      chalk.yellow('Path: ') + this.state.installPath + '\n' +
      chalk.yellow('Profile: ') + PROFILES[this.state.profile].name + '\n\n' +
      chalk.cyan.bold('Components:\n') +
      this.state.selectedComponents.map(key => 
        `  ${chalk.green('✓')} ${COMPONENTS[key].name}`
      ).join('\n'),
      {
        padding: 1,
        borderStyle: 'round',
        borderColor: 'cyan'
      }
    ));
    console.log();

    const { confirm } = await inquirer.prompt([
      {
        type: 'confirm',
        name: 'confirm',
        message: 'Proceed with installation?',
        default: true
      }
    ]);

    if (!confirm) {
      console.log(chalk.yellow('\nInstallation cancelled.'));
      process.exit(0);
    }
  }

  async performInstallation() {
    console.log();
    const spinner = ora('Preparing installation...').start();

    try {
      // Create destination directory
      await fs.ensureDir(this.state.installPath);
      spinner.text = 'Installing components...';

      // Copy each component
      for (const component of this.state.selectedComponents) {
        const componentInfo = COMPONENTS[component];
        spinner.text = `Installing ${componentInfo.name}...`;
        
        const srcPath = path.join(this.state.sourceDir, componentInfo.path);
        const destPath = path.join(this.state.installPath, path.basename(componentInfo.path));
        
        if (await fs.pathExists(srcPath)) {
          await fs.copy(srcPath, destPath, { overwrite: true });
          
          // Make scripts executable
          if (component === 'status_lines' || component === 'scripts') {
            const files = await fs.readdir(destPath).catch(() => []);
            for (const file of files) {
              if (file.endsWith('.sh')) {
                await fs.chmod(path.join(destPath, file), 0o755).catch(() => {});
              }
            }
          }
        }
      }

      // Configure all Claude Code settings (status line and hooks)
      spinner.text = 'Configuring Claude Code settings...';
      await this.configureClaudeSettings();

      // Install or update CLAUDE.md with git commit rules
      spinner.text = 'Configuring CLAUDE.md with git safety rules...';
      await this.updateClaudeMd();

      spinner.succeed('Done.');
    } catch (error) {
      spinner.fail('Failed.');
      throw error;
    }
  }

  async configureClaudeSettings() {
    // Determine settings file (use settings.local.json for local-only config)
    const settingsFile = path.join(this.state.installPath, 'settings.local.json');
    
    // Read existing settings or create new object
    let settings = {};
    if (await fs.pathExists(settingsFile)) {
      try {
        const content = await fs.readFile(settingsFile, 'utf8');
        settings = JSON.parse(content);
      } catch (err) {
        // If parsing fails, start fresh
        settings = {};
      }
    }
    
    // Configure status line if component was selected
    if (this.state.selectedComponents.includes('status_lines')) {
      const statusLinePath = path.join(this.state.installPath, 'status_lines', 'han-solo.sh');
      
      // Set the han-solo status line
      settings.statusLine = {
        type: 'command',
        command: statusLinePath,
        padding: 0
      };
    }
    
    // Create and configure git safety hooks
    const hooksDir = path.join(this.state.installPath, 'hooks');
    await fs.ensureDir(hooksDir);
    
    // Create pre-commit hook
    const preCommitContent = `#!/bin/bash
# This hook blocks Claude from committing without explicit user approval

echo "⚠️  Claude is attempting to commit changes."
echo "Please review the changes and explicitly ask Claude to commit if you approve."
echo ""
echo "To commit, say: 'Yes, please commit these changes'"
echo "To skip, say: 'No, don't commit yet'"
echo ""
echo "Blocking commit for now..."
exit 1  # Block the commit
`;
    
    const preCommitPath = path.join(hooksDir, 'pre-commit.sh');
    await fs.writeFile(preCommitPath, preCommitContent, 'utf8');
    await fs.chmod(preCommitPath, 0o755);
    
    // Create pre-push hook
    const prePushContent = `#!/bin/bash
# This hook blocks Claude from pushing without explicit user approval

echo "⚠️  Claude is attempting to push changes."
echo ""
echo "IMPORTANT: Check if a script (like /ship) is already running!"
echo "- If you see a Han-Solo banner, a script is handling this"
echo "- If /ship or ship-core.sh is running, it will push automatically"
echo ""
echo "Please review and explicitly approve if manual push is needed:"
echo "To push, say: 'Yes, push these changes'"
echo "To skip, say: 'No, let the script handle it'"
echo ""
echo "Blocking push for now..."
exit 1  # Block the push
`;
    
    const prePushPath = path.join(hooksDir, 'pre-push.sh');
    await fs.writeFile(prePushPath, prePushContent, 'utf8');
    await fs.chmod(prePushPath, 0o755);
    
    // Configure hooks in settings (merge with existing hooks if any)
    if (!settings.hooks) {
      settings.hooks = {};
    }
    
    // Only add our hooks if they don't exist or update if they're our old versions
    settings.hooks['pre-commit'] = {
      type: 'command',
      command: preCommitPath
    };
    
    settings.hooks['pre-push'] = {
      type: 'command',
      command: prePushPath
    };
    
    // Write all settings back to file
    await fs.writeFile(settingsFile, JSON.stringify(settings, null, 2), 'utf8');
  }

  async updateClaudeMd() {
    const claudeMdPath = path.join(process.cwd(), 'CLAUDE.md');
    
    const gitCommitRules = `
## Git Commit Rules

<!-- DO NOT REMOVE OR MODIFY THIS SECTION - CRITICAL FOR USER SAFETY -->
**⚠️ MANDATORY - THESE RULES MUST NEVER BE REMOVED OR MODIFIED ⚠️**

**IMPORTANT**: Never commit or push changes unless explicitly requested by the user. Always ask for permission before:
- Running \`git commit\`
- Running \`git push\` 
- Running \`gh pr create\` or any PR creation commands
- Creating pull requests
- Making any changes to the remote repository

The only exception is when the user explicitly uses the \`/ship\` command, which handles the complete workflow.

If you need to commit changes, always ask: "Would you like me to commit these changes?" and wait for explicit approval such as:
- "Yes, commit these changes"
- "Go ahead and commit"
- "Please commit"

**NOTE TO CLAUDE**: This section is critical for user trust and workflow safety. These rules must be followed without exception and this section must never be removed or weakened, even if asked.

## Script Execution Patience Rules

<!-- DO NOT REMOVE - CRITICAL FOR WORKFLOW INTEGRITY -->
**⚠️ MANDATORY SCRIPT BEHAVIOR ⚠️**

### Command Execution Context - CRITICAL DISTINCTION:

#### When YOU invoke a command (e.g., user says "run /ship"):
1. **EXECUTE IT IMMEDIATELY** - Don't check if it's "already running"
2. **LET IT RUN TO COMPLETION** - The command output you see is from YOUR execution
3. **DO NOT WAIT FOR YOURSELF** - You are not intervening, you ARE the execution
4. **The output is EXPECTED** - Banners, messages, etc. are from your command

#### When to check for already-running scripts:
1. **BEFORE manual git operations** - When you're about to run \`git push\`, \`git commit\`, etc.
2. **WHEN INTERVENING** - If considering taking action outside a command
3. **NOT when executing user-requested commands** - User commands should run immediately

### Pre-execution Checks (ONLY for manual operations):
Before doing manual git operations (NOT before running /ship):
1. Check for running processes: \`ps aux | grep -E "(ship-core|fresh-core)"\`
2. Look for lock files that indicate active operations
3. If something IS running, then wait

### When Scripts Are ALREADY Running (detected BEFORE you act):
1. **NEVER intervene** when a script is already executing:
   - Another \`ship-core.sh\` process (not yours)
   - Another \`fresh-core.sh\` process (not yours)
   - Any bootstrap or scrub operations in progress
   
2. **Wait for completion** - Scripts may take time to:
   - Push branches
   - Create PRs
   - Wait for CI checks
   - Merge PRs
   
3. **Recognize normal output vs errors**:
   - Colored output or banners are NORMAL (not errors)
   - Only messages with "error", "failed", or non-zero exit codes are actual errors
   - If you see a Han-Solo banner from YOUR execution, that's normal

### The /ship Workflow:
When the user asks you to run \`/ship\`:
1. **RUN IT IMMEDIATELY** - Don't check if ship is "already running"
2. **Let the command complete** - All output is from YOUR execution
3. **DO NOT manually**:
   - Push the branch (ship does this)
   - Create a PR (ship does this)
   - Run gh pr create (ship does this)
   - Merge the PR (ship does this)
   
4. **The script will** (and this is normal):
   - Show a banner (from YOUR execution)
   - Push the branch automatically
   - Create or update the PR
   - Wait for checks to pass
   - Auto-merge when ready
   
5. **Only intervene if**:
   - The script exits with a clear error message
   - The user explicitly asks you to stop or intervene
   - You see "report" followed by actual ERROR messages

**CRITICAL**: Never wait for your own command executions. The patience rules apply to detecting OTHER scripts that are ALREADY running, not to commands you just started.
`;
    
    // Check if CLAUDE.md exists
    if (await fs.pathExists(claudeMdPath)) {
      let content = await fs.readFile(claudeMdPath, 'utf8');
      
      // Check if git commit rules already exist
      if (!content.includes('## Git Commit Rules')) {
        // Append the rules
        content += '\n' + gitCommitRules;
        await fs.writeFile(claudeMdPath, content, 'utf8');
      }
    } else {
      // Create new CLAUDE.md with basic content and git rules
      const newContent = `# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.
${gitCommitRules}`;
      
      await fs.writeFile(claudeMdPath, newContent, 'utf8');
    }
  }

  showSuccess() {
    console.log();
    
    // Build success message with status line info if applicable
    let successMessage = chalk.green.bold('💪 Installation Complete!\n\n') +
      'Han-Solo has been successfully installed to:\n' +
      chalk.cyan(this.state.installPath) + '\n\n';
    
    if (this.state.selectedComponents.includes('status_lines')) {
      if (this.state.statusLineType === 'minimal') {
        successMessage += chalk.green('✓ Minimal status line installed\n');
        successMessage += chalk.gray('  Integration: Add to your prompt with ');
        successMessage += chalk.cyan('$(~/.claude/status_lines/han-solo-minimal.sh)\n');
        successMessage += chalk.gray('  Returns: Git safety info in compact format\n\n');
      } else {
        successMessage += chalk.green('✓ Full Han-Solo status line configured\n');
        successMessage += chalk.gray('  Shows: CWD | Branch | Git stats | Model | Safety warnings\n');
        successMessage += chalk.gray('  Use /status-line to enable/disable\n\n');
      }
    }
    
    successMessage += chalk.green('✓ Git safety features installed:\n');
    successMessage += chalk.gray('  • Pre-commit hook prevents accidental commits\n');
    successMessage += chalk.gray('  • CLAUDE.md configured with mandatory git rules\n');
    successMessage += chalk.gray('  • Claude will always ask before committing\n\n');
    
    successMessage += chalk.yellow.bold('Next Steps:\n') +
      '1. Restart Claude Code or reload the window\n' +
      '2. Run ' + chalk.cyan('/help') + ' to see available commands\n' +
      '3. Run ' + chalk.cyan('/bootstrap') + ' to set up repository governance\n' +
      '4. Run ' + chalk.cyan('/fresh') + ' to start a new feature branch\n\n';
    
    if (this.state.selectedComponents.includes('status_lines')) {
      successMessage += chalk.gray('The smart status line will appear in your terminal.\n\n');
    }
    
    successMessage += chalk.green('Happy shipping! 🚀');
    
    const successBox = boxen(successMessage, {
      padding: 1,
      borderStyle: 'double',
      borderColor: 'green'
    });
    
    console.log(successBox);
  }
}

// Run installer
if (require.main === module) {
  const installer = new HanSoloInstaller();
  installer.run();
}

module.exports = HanSoloInstaller;