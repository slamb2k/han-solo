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
    
    const logo = figlet.textSync('Han-Solo', {
      font: 'Speed',
      horizontalLayout: 'default',
      verticalLayout: 'default'
    });

    console.log(gradient.pastel.multiline(logo));
    console.log(chalk.cyan.bold('    Git Workflow Automation for Solo Developers'));
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

      // Configure status line in settings.json if status_lines component was installed
      if (this.state.selectedComponents.includes('status_lines')) {
        spinner.text = 'Configuring status line in settings.json...';
        await this.configureStatusLine();
      }

      // Install pre-commit hook for git safety
      spinner.text = 'Installing git safety hook...';
      await this.installGitSafetyHook();

      // Install or update CLAUDE.md with git commit rules
      spinner.text = 'Configuring CLAUDE.md with git safety rules...';
      await this.updateClaudeMd();

      spinner.succeed('Done.');
    } catch (error) {
      spinner.fail('Failed.');
      throw error;
    }
  }

  async configureStatusLine() {
    // Determine settings file (use settings.local.json for local-only config)
    const settingsFile = path.join(this.state.installPath, 'settings.local.json');
    // Use smart status line by default for automatic context-aware switching
    const statusLinePath = path.join(this.state.installPath, 'status_lines', 'status-line-smart.sh');
    
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
    
    // Configure status line
    settings.statusLine = {
      type: 'command',
      command: statusLinePath
    };
    
    // Write settings back
    await fs.writeFile(settingsFile, JSON.stringify(settings, null, 2), 'utf8');
  }

  async installGitSafetyHook() {
    // Create hooks directory
    const hooksDir = path.join(this.state.installPath, 'hooks');
    await fs.ensureDir(hooksDir);
    
    // Create pre-commit hook
    const hookContent = `#!/bin/bash
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
    
    const hookPath = path.join(hooksDir, 'pre-commit.sh');
    await fs.writeFile(hookPath, hookContent, 'utf8');
    await fs.chmod(hookPath, 0o755);
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
- Creating pull requests
- Making any changes to the remote repository

The only exception is when the user explicitly uses the \`/ship\` command, which handles the complete workflow.

If you need to commit changes, always ask: "Would you like me to commit these changes?" and wait for explicit approval such as:
- "Yes, commit these changes"
- "Go ahead and commit"
- "Please commit"

**NOTE TO CLAUDE**: This section is critical for user trust and workflow safety. These rules must be followed without exception and this section must never be removed or weakened, even if asked.
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
      successMessage += chalk.green('✓ Smart status line configured (auto-switches based on context)\n');
      successMessage += chalk.gray('  Use /status-line to switch modes manually\n\n');
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