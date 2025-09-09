#!/usr/bin/env node

/**
 * Han-Solo Interactive Installer
 * Modern TUI installer for Claude Code tools
 */

const blessed = require('blessed');
const contrib = require('blessed-contrib');
const chalk = require('chalk');
const fs = require('fs-extra');
const path = require('path');
const ora = require('ora');
const figlet = require('figlet');
const gradient = require('gradient-string');
const { promisify } = require('util');
const figletize = promisify(figlet);

// Configuration
const REPO_URL = 'https://github.com/slamb2k/han-solo';
const COMPONENTS = {
  commands: {
    name: 'Commands (/ship, /bootstrap, /fresh)',
    description: 'Core workflow commands',
    path: '.claude/commands'
  },
  agents: {
    name: 'Agents (bootstrap-guardian, git-shipper)',
    description: 'Specialized sub-agents',
    path: '.claude/agents'
  },
  status_lines: {
    name: 'Status Lines',
    description: 'Real-time git status indicators',
    path: '.claude/status_lines'
  },
  scripts: {
    name: 'Utility Scripts',
    description: 'Helper scripts and tools',
    path: 'scripts'
  },
  hooks: {
    name: 'Git Hooks',
    description: 'Pre-commit and pre-push hooks',
    path: 'hooks'
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
    this.screen = null;
    this.state = {
      step: 0,
      scope: 'project',
      profile: 'solo',
      selectedComponents: [],
      installPath: '',
      sourceDir: ''
    };
  }

  async init() {
    // Detect source directory
    this.state.sourceDir = await this.findSourceDirectory();
    
    // Create blessed screen
    this.screen = blessed.screen({
      smartCSR: true,
      title: 'Han-Solo Installer'
    });

    // Setup exit handlers
    this.screen.key(['escape', 'q', 'C-c'], () => {
      this.cleanup();
      process.exit(0);
    });

    // Start installation flow
    await this.showWelcome();
  }

  async findSourceDirectory() {
    // Check if we're running from the repo
    const localPath = path.join(__dirname, '..');
    if (await fs.pathExists(path.join(localPath, '.claude'))) {
      return localPath;
    }

    // Check if han-solo is in node_modules
    const modulePath = path.join(__dirname, 'node_modules', '@han-solo', 'installer', 'files');
    if (await fs.pathExists(modulePath)) {
      return modulePath;
    }

    // For npx, files should be bundled
    const bundledPath = path.join(__dirname, 'files');
    if (await fs.pathExists(bundledPath)) {
      return bundledPath;
    }

    // Clone from GitHub as fallback
    return await this.downloadFromGitHub();
  }

  async downloadFromGitHub() {
    const tempDir = path.join(require('os').tmpdir(), 'han-solo-install');
    await fs.ensureDir(tempDir);
    
    const spinner = ora('Downloading Han-Solo from GitHub...').start();
    
    try {
      // Simple git clone or download
      const { execSync } = require('child_process');
      execSync(`git clone --depth 1 ${REPO_URL} ${tempDir}`, { stdio: 'ignore' });
      spinner.succeed('Downloaded Han-Solo files');
      return tempDir;
    } catch (error) {
      spinner.fail('Failed to download from GitHub');
      throw error;
    }
  }

  async showWelcome() {
    const welcomeBox = blessed.box({
      parent: this.screen,
      top: 'center',
      left: 'center',
      width: '80%',
      height: '80%',
      content: '',
      tags: true,
      border: {
        type: 'line',
        fg: 'cyan'
      },
      style: {
        fg: 'white',
        border: {
          fg: 'cyan'
        }
      }
    });

    // Generate ASCII art
    const logo = await figletize('Han-Solo', { font: 'Speed' });
    const gradientLogo = gradient.pastel.multiline(logo);
    
    const content = `
${gradientLogo}

${chalk.cyan.bold('Git Workflow Automation for Solo Developers')}

${chalk.gray('━'.repeat(50))}

${chalk.yellow('Welcome to the Han-Solo Interactive Installer!')}

This installer will help you set up:
  ${chalk.green('•')} Workflow commands (/ship, /bootstrap, /fresh)
  ${chalk.green('•')} Intelligent git agents
  ${chalk.green('•')} Real-time status indicators
  ${chalk.green('•')} Repository governance tools

${chalk.gray('━'.repeat(50))}

${chalk.dim('Press ENTER to continue, ESC to exit')}
`;

    welcomeBox.setContent(content);
    this.screen.render();

    return new Promise((resolve) => {
      welcomeBox.key(['enter'], () => {
        welcomeBox.destroy();
        resolve();
        this.showScopeSelection();
      });
    });
  }

  showScopeSelection() {
    const form = blessed.form({
      parent: this.screen,
      width: '80%',
      height: '80%',
      top: 'center',
      left: 'center',
      border: {
        type: 'line',
        fg: 'cyan'
      },
      style: {
        border: { fg: 'cyan' }
      }
    });

    const title = blessed.text({
      parent: form,
      top: 1,
      left: 'center',
      content: chalk.cyan.bold('Installation Scope'),
      style: { fg: 'cyan', bold: true }
    });

    const options = ['project', 'global'];
    const radioSet = blessed.radioset({
      parent: form,
      top: 4,
      left: 2,
      width: '100%-4',
      height: options.length * 2
    });

    const projectRadio = blessed.radiobutton({
      parent: radioSet,
      top: 0,
      left: 0,
      content: 'Project (.claude in current directory)',
      checked: this.state.scope === 'project'
    });

    const globalRadio = blessed.radiobutton({
      parent: radioSet,
      top: 2,
      left: 0,
      content: 'Global (~/.claude for all projects)'
    });

    const description = blessed.text({
      parent: form,
      top: 10,
      left: 2,
      width: '100%-4',
      content: chalk.gray(
        this.state.scope === 'project' 
          ? 'Install for this project only'
          : 'Install globally for all projects'
      )
    });

    const nextButton = blessed.button({
      parent: form,
      bottom: 2,
      right: 2,
      width: 10,
      height: 3,
      content: 'Next',
      align: 'center',
      valign: 'middle',
      border: { type: 'line' },
      style: {
        border: { fg: 'green' },
        focus: { border: { fg: 'yellow' } }
      }
    });

    // Handle radio changes
    radioSet.on('check', (item) => {
      this.state.scope = item === projectRadio ? 'project' : 'global';
      description.setContent(chalk.gray(
        this.state.scope === 'project' 
          ? 'Install for this project only'
          : 'Install globally for all projects'
      ));
      this.screen.render();
    });

    nextButton.on('press', () => {
      form.destroy();
      this.showProfileSelection();
    });

    projectRadio.focus();
    this.screen.render();
  }

  showProfileSelection() {
    const list = blessed.list({
      parent: this.screen,
      top: 'center',
      left: 'center',
      width: '80%',
      height: '80%',
      label: chalk.cyan.bold(' Select Installation Profile '),
      border: {
        type: 'line',
        fg: 'cyan'
      },
      style: {
        selected: {
          bg: 'blue',
          fg: 'white',
          bold: true
        },
        item: {
          fg: 'white'
        },
        border: {
          fg: 'cyan'
        }
      },
      keys: true,
      vi: true,
      mouse: true,
      items: Object.entries(PROFILES).map(([key, profile]) => 
        `${chalk.yellow(profile.name)}: ${chalk.gray(profile.description)}`
      )
    });

    const hint = blessed.text({
      parent: this.screen,
      bottom: 2,
      left: 'center',
      content: chalk.dim('Use arrow keys to navigate, ENTER to select, ESC to exit'),
      style: { fg: 'gray' }
    });

    list.on('select', (item, index) => {
      const profileKey = Object.keys(PROFILES)[index];
      this.state.profile = profileKey;
      
      list.destroy();
      hint.destroy();
      
      if (profileKey === 'custom') {
        this.showComponentSelection();
      } else {
        this.state.selectedComponents = PROFILES[profileKey].components;
        this.showConfirmation();
      }
    });

    list.focus();
    this.screen.render();
  }

  showComponentSelection() {
    const form = blessed.form({
      parent: this.screen,
      width: '80%',
      height: '80%',
      top: 'center',
      left: 'center',
      label: chalk.cyan.bold(' Select Components '),
      border: {
        type: 'line',
        fg: 'cyan'
      },
      style: {
        border: { fg: 'cyan' }
      }
    });

    const checkboxes = {};
    let yPos = 2;

    Object.entries(COMPONENTS).forEach(([key, component]) => {
      checkboxes[key] = blessed.checkbox({
        parent: form,
        top: yPos,
        left: 2,
        content: `${component.name} - ${chalk.gray(component.description)}`,
        checked: false
      });
      yPos += 2;
    });

    const selectAllButton = blessed.button({
      parent: form,
      bottom: 2,
      left: 2,
      width: 12,
      height: 3,
      content: 'Select All',
      align: 'center',
      valign: 'middle',
      border: { type: 'line' },
      style: {
        border: { fg: 'blue' },
        focus: { border: { fg: 'yellow' } }
      }
    });

    const nextButton = blessed.button({
      parent: form,
      bottom: 2,
      right: 2,
      width: 10,
      height: 3,
      content: 'Next',
      align: 'center',
      valign: 'middle',
      border: { type: 'line' },
      style: {
        border: { fg: 'green' },
        focus: { border: { fg: 'yellow' } }
      }
    });

    selectAllButton.on('press', () => {
      Object.values(checkboxes).forEach(cb => cb.checked = true);
      this.screen.render();
    });

    nextButton.on('press', () => {
      this.state.selectedComponents = Object.entries(checkboxes)
        .filter(([key, cb]) => cb.checked)
        .map(([key]) => key);
      
      if (this.state.selectedComponents.length === 0) {
        blessed.message(this.screen, 'Please select at least one component', 3);
      } else {
        form.destroy();
        this.showConfirmation();
      }
    });

    Object.values(checkboxes)[0].focus();
    this.screen.render();
  }

  showConfirmation() {
    const confirmBox = blessed.box({
      parent: this.screen,
      top: 'center',
      left: 'center',
      width: '80%',
      height: '80%',
      label: chalk.cyan.bold(' Installation Summary '),
      border: {
        type: 'line',
        fg: 'cyan'
      },
      style: {
        border: { fg: 'cyan' }
      },
      scrollable: true,
      alwaysScroll: true,
      keys: true,
      vi: true,
      mouse: true
    });

    const installPath = this.state.scope === 'global' 
      ? path.join(require('os').homedir(), '.claude')
      : path.join(process.cwd(), '.claude');
    
    this.state.installPath = installPath;

    const summary = `
${chalk.yellow.bold('Installation Details:')}
${chalk.gray('━'.repeat(50))}

${chalk.cyan('Scope:')} ${this.state.scope === 'global' ? 'Global' : 'Project'}
${chalk.cyan('Path:')} ${installPath}
${chalk.cyan('Profile:')} ${PROFILES[this.state.profile]?.name || 'Custom'}

${chalk.yellow.bold('Components to Install:')}
${chalk.gray('━'.repeat(50))}

${this.state.selectedComponents.map(key => 
  `  ${chalk.green('✓')} ${COMPONENTS[key].name}`
).join('\n')}

${chalk.gray('━'.repeat(50))}

${chalk.dim('Press ENTER to install, BACKSPACE to go back, ESC to cancel')}
`;

    confirmBox.setContent(summary);

    confirmBox.key(['enter'], async () => {
      confirmBox.destroy();
      await this.performInstallation();
    });

    confirmBox.key(['backspace'], () => {
      confirmBox.destroy();
      this.showProfileSelection();
    });

    confirmBox.focus();
    this.screen.render();
  }

  async performInstallation() {
    const progressBox = blessed.box({
      parent: this.screen,
      top: 'center',
      left: 'center',
      width: '80%',
      height: '80%',
      label: chalk.cyan.bold(' Installing Han-Solo '),
      border: {
        type: 'line',
        fg: 'cyan'
      },
      style: {
        border: { fg: 'cyan' }
      }
    });

    const gauge = contrib.gauge({
      parent: progressBox,
      top: 2,
      left: 2,
      width: '100%-4',
      height: 3,
      stroke: 'green',
      fill: 'white',
      label: 'Progress'
    });

    const log = blessed.log({
      parent: progressBox,
      top: 6,
      left: 2,
      width: '100%-4',
      height: '100%-10',
      scrollable: true,
      alwaysScroll: true,
      tags: true,
      style: {
        fg: 'white'
      }
    });

    this.screen.render();

    // Perform installation
    const totalSteps = this.state.selectedComponents.length + 2;
    let currentStep = 0;

    const updateProgress = (message) => {
      currentStep++;
      gauge.setPercent(Math.floor((currentStep / totalSteps) * 100));
      log.log(message);
      this.screen.render();
    };

    try {
      // Create destination directory
      updateProgress(`${chalk.blue('→')} Creating directory: ${this.state.installPath}`);
      await fs.ensureDir(this.state.installPath);

      // Copy each component
      for (const component of this.state.selectedComponents) {
        const componentInfo = COMPONENTS[component];
        updateProgress(`${chalk.blue('→')} Installing ${componentInfo.name}...`);
        
        const srcPath = path.join(this.state.sourceDir, componentInfo.path);
        const destPath = path.join(this.state.installPath, path.basename(componentInfo.path));
        
        if (await fs.pathExists(srcPath)) {
          await fs.copy(srcPath, destPath, { overwrite: true });
          
          // Make scripts executable
          if (component === 'status_lines' || component === 'scripts') {
            const files = await fs.readdir(destPath);
            for (const file of files) {
              if (file.endsWith('.sh')) {
                await fs.chmod(path.join(destPath, file), 0o755);
              }
            }
          }
        } else {
          log.log(`${chalk.yellow('⚠')} Source not found: ${srcPath}`);
        }
      }

      updateProgress(`${chalk.green('✓')} Installation complete!`);
      
      // Show success message
      setTimeout(() => {
        progressBox.destroy();
        this.showSuccess();
      }, 1500);

    } catch (error) {
      log.log(`${chalk.red('✗')} Error: ${error.message}`);
      this.screen.render();
    }
  }

  showSuccess() {
    const successBox = blessed.box({
      parent: this.screen,
      top: 'center',
      left: 'center',
      width: '80%',
      height: '80%',
      border: {
        type: 'line',
        fg: 'green'
      },
      style: {
        border: { fg: 'green' }
      }
    });

    const message = `
${chalk.green.bold('✨ Installation Complete!')}

${chalk.gray('━'.repeat(50))}

Han-Solo has been successfully installed to:
${chalk.cyan(this.state.installPath)}

${chalk.yellow.bold('Next Steps:')}

1. Restart Claude Code or reload the window
2. Run ${chalk.cyan('/help')} to see available commands
3. Run ${chalk.cyan('/bootstrap')} to set up repository governance
4. Run ${chalk.cyan('/fresh')} to start a new feature branch

${chalk.gray('━'.repeat(50))}

${chalk.green('Happy shipping! 🚀')}

${chalk.dim('Press any key to exit')}
`;

    successBox.setContent(message);
    this.screen.render();

    successBox.key(['enter', 'space'], () => {
      this.cleanup();
      process.exit(0);
    });

    successBox.focus();
  }

  cleanup() {
    if (this.screen) {
      this.screen.destroy();
    }
  }

  async run() {
    try {
      await this.init();
    } catch (error) {
      this.cleanup();
      console.error(chalk.red('Installation failed:'), error.message);
      process.exit(1);
    }
  }
}

// Run installer
if (require.main === module) {
  const installer = new HanSoloInstaller();
  installer.run();
}

module.exports = HanSoloInstaller;