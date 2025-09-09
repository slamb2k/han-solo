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
    console.log();
    console.log(chalk.cyan.bold('  Git Workflow Automation for Solo Developers'));
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
        margin: 1,
        borderStyle: 'round',
        borderColor: 'cyan'
      }
    );
    
    console.log(welcomeBox);
    console.log();
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

      spinner.succeed('Installation complete!');
    } catch (error) {
      spinner.fail('Installation failed');
      throw error;
    }
  }

  showSuccess() {
    console.log();
    const successBox = boxen(
      chalk.green.bold('✨ Installation Complete!\n\n') +
      'Han-Solo has been successfully installed to:\n' +
      chalk.cyan(this.state.installPath) + '\n\n' +
      chalk.yellow.bold('Next Steps:\n') +
      '1. Restart Claude Code or reload the window\n' +
      '2. Run ' + chalk.cyan('/help') + ' to see available commands\n' +
      '3. Run ' + chalk.cyan('/bootstrap') + ' to set up repository governance\n' +
      '4. Run ' + chalk.cyan('/fresh') + ' to start a new feature branch\n\n' +
      chalk.green('Happy shipping! 🚀'),
      {
        padding: 1,
        margin: 1,
        borderStyle: 'double',
        borderColor: 'green'
      }
    );
    
    console.log(successBox);
  }
}

// Run installer
if (require.main === module) {
  const installer = new HanSoloInstaller();
  installer.run();
}

module.exports = HanSoloInstaller;