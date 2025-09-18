# han-solo Troubleshooting Guide

## Table of Contents
1. [Installation Issues](#installation-issues)
2. [Command Errors](#command-errors)
3. [Git Workflow Problems](#git-workflow-problems)
4. [Hook Failures](#hook-failures)
5. [GitHub Integration](#github-integration)
6. [Performance Issues](#performance-issues)
7. [Conflict Resolution](#conflict-resolution)
8. [CI/CD Problems](#cicd-problems)
9. [Debug Commands](#debug-commands)

## Installation Issues

### Claude Code Not Found

**Problem**: "Claude Code CLI not found"

**Solution**:
1. Install Claude Code CLI:
   ```bash
   npm install -g @anthropic/claude-cli
   ```
2. Verify installation:
   ```bash
   claude --version
   ```
3. Ensure version is 1.0.117 or higher

### GitHub CLI Not Authenticated

**Problem**: "gh: not authenticated"

**Solution**:
1. Install GitHub CLI:
   ```bash
   brew install gh  # macOS
   sudo apt install gh  # Linux
   ```
2. Authenticate:
   ```bash
   gh auth login
   ```
3. Choose authentication method (browser recommended)
4. Verify:
   ```bash
   gh auth status
   ```

### jq Not Installed

**Problem**: "jq: command not found"

**Solution**:
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# CentOS/RHEL
sudo yum install jq
```

## Command Errors

### Command Not Found

**Problem**: "/hansolo:init not found"

**Solution**:
1. Ensure han-solo is initialized:
   ```bash
   ls -la .claude/commands/hansolo/
   ```
2. If missing, manually create command structure:
   ```bash
   mkdir -p .claude/commands/hansolo
   mkdir -p .claude/agents/hansolo
   mkdir -p .claude/hooks
   ```
3. Re-run initialization

### YAML Frontmatter Invalid

**Problem**: "Invalid YAML frontmatter in command"

**Solution**:
1. Check command file syntax:
   ```bash
   head -n 10 .claude/commands/hansolo/init.md
   ```
2. Ensure proper YAML format:
   ```yaml
   ---
   description: "Command description"
   argument_hint: "optional"
   ---
   ```

### Command Execution Fails

**Problem**: Command runs but doesn't complete

**Solution**:
1. Check for syntax errors in command file
2. Verify all required tools are available
3. Run with verbose output:
   ```bash
   VERBOSE=1 /hansolo:command
   ```

## Git Workflow Problems

### Cannot Create Branch

**Problem**: "Failed to create feature branch"

**Causes & Solutions**:

1. **Uncommitted changes**:
   ```bash
   git stash
   /hansolo:launch feature-name
   git stash pop
   ```

2. **Not on main branch**:
   ```bash
   git checkout main
   /hansolo:launch feature-name
   ```

3. **Branch already exists**:
   ```bash
   git branch -D feature/old-branch
   /hansolo:launch feature-name
   ```

### Rebase Fails

**Problem**: "Rebase failed during sync"

**Solution**:
1. Check conflict status:
   ```bash
   git status
   ```
2. If conflicts exist:
   ```bash
   # Option 1: Resolve manually
   git status --short | grep "^UU"
   # Fix conflicts in listed files
   git add .
   git rebase --continue

   # Option 2: Abort and try again
   git rebase --abort
   /hansolo:sync
   ```

### Cannot Push to Remote

**Problem**: "Push rejected"

**Common causes**:

1. **No upstream branch**:
   ```bash
   git push -u origin feature/branch-name
   ```

2. **Behind remote**:
   ```bash
   /hansolo:sync
   git push
   ```

3. **Protected branch**:
   - Never push directly to main
   - Use `/hansolo:ship` instead

## Hook Failures

### Pre-commit Hook Blocking

**Problem**: "Pre-commit hook failed"

**Debug steps**:
1. Run hook manually:
   ```bash
   echo '{"tool_name":"Bash","tool_input":{"command":"git commit -m test"}}' | \
     .claude/hooks/pre-flight-check.sh
   ```
2. Check exit code:
   - 0 = success
   - 1 = warning
   - 2 = block

3. Common fixes:
   - Fix linting errors
   - Format code properly
   - Remove debug statements

### Hook Performance Issues

**Problem**: "Hook execution slow"

**Solution**:
1. Monitor performance:
   ```bash
   .claude/scripts/monitor-performance.sh analyze
   ```
2. Optimize slow hooks:
   - Add early exit conditions
   - Cache expensive operations
   - Use background processing

### Hook Not Triggering

**Problem**: Hook doesn't run

**Solution**:
1. Verify hook is executable:
   ```bash
   chmod +x .claude/hooks/*.sh
   ```
2. Check settings.json:
   ```json
   {
     "hooks": [
       {
         "matcher": "Bash",
         "hooks": [
           {
             "type": "script",
             "path": ".claude/hooks/pre-flight-check.sh",
             "event": "PreToolUse"
           }
         ]
       }
     ]
   }
   ```

## GitHub Integration

### API Rate Limit Exceeded

**Problem**: "API rate limit exceeded"

**Solution**:
1. Check current limits:
   ```bash
   .claude/scripts/check-rate-limits.sh
   ```
2. Wait for reset (time shown in output)
3. Optimize API usage:
   - Use GraphQL instead of REST
   - Batch operations
   - Cache responses

### Branch Protection Not Working

**Problem**: "Cannot enable branch protection"

**Solution**:
1. Verify admin permissions:
   ```bash
   gh api repos/:owner/:repo | jq .permissions
   ```
2. Run setup script:
   ```bash
   .claude/scripts/setup-branch-protection.sh
   ```
3. Manual configuration:
   - Visit: `https://github.com/owner/repo/settings/branches`
   - Enable protection for main branch

### PR Creation Fails

**Problem**: "Failed to create pull request"

**Common issues**:

1. **No commits to push**:
   ```bash
   git log origin/main..HEAD
   ```

2. **PR already exists**:
   ```bash
   gh pr list
   ```

3. **No repository remote**:
   ```bash
   gh repo create
   git remote add origin <url>
   ```

## Performance Issues

### Slow Command Execution

**Problem**: Commands take too long

**Diagnosis**:
```bash
# Check hook performance
.claude/scripts/monitor-performance.sh analyze

# Monitor in real-time
.claude/scripts/monitor-performance.sh monitor
```

**Solutions**:
- Disable unnecessary hooks temporarily
- Clear git cache: `git gc`
- Check network connectivity

### High Memory Usage

**Problem**: Claude Code using excessive memory

**Solution**:
1. Compact context:
   ```
   /compact
   ```
2. Clear checkpoint commits:
   ```bash
   git reflog expire --expire=now --all
   git gc --prune=now
   ```

## Conflict Resolution

### Multiple Conflicts

**Problem**: Many files have conflicts

**Solution**:
1. Use conflict parser:
   ```bash
   .claude/scripts/parse-conflicts.sh stats
   ```
2. Resolve systematically:
   ```bash
   # List conflicted files
   .claude/scripts/parse-conflicts.sh list

   # Resolve each file
   .claude/scripts/parse-conflicts.sh resolve <file> <strategy>
   ```

### Complex Merge Conflicts

**Problem**: Difficult to understand conflicts

**Solution**:
1. View three-way diff:
   ```bash
   git checkout --conflict=diff3 <file>
   ```
2. Use merge tool:
   ```bash
   git mergetool
   ```
3. Get help from Rogue-Squadron:
   - It will analyze conflicts
   - Provide resolution options
   - Guide through manual merge

### Lost Changes During Conflict

**Problem**: Changes lost during resolution

**Recovery**:
```bash
# Find lost commits
git reflog

# Recover specific commit
git cherry-pick <commit-hash>

# Recover file from commit
git show <commit>:<file> > <file>
```

## CI/CD Problems

### Workflow Not Triggering

**Problem**: GitHub Actions not running

**Check**:
1. Workflow file location:
   ```bash
   ls .github/workflows/
   ```
2. Workflow syntax:
   ```bash
   # Validate YAML
   yamllint .github/workflows/ci.yml
   ```
3. Branch configuration:
   - Ensure workflow triggers on correct branches
   - Check workflow permissions

### Tests Failing in CI

**Problem**: Tests pass locally but fail in CI

**Debug**:
1. Check environment differences:
   - Node/Python versions
   - Environment variables
   - Dependencies

2. Run tests in CI-like environment:
   ```bash
   docker run -it ubuntu:latest
   # Install dependencies and run tests
   ```

### Deployment Failures

**Problem**: Deployment step failing

**Common issues**:
1. **Missing secrets**:
   ```bash
   gh secret list
   gh secret set SECRET_NAME
   ```

2. **Wrong deployment target**:
   - Verify deployment configuration
   - Check environment URLs

## Debug Commands

### Diagnostic Information

Gather system information:
```bash
# han-solo version info
cat .claude/commands/hansolo/init.md | head -5

# Git configuration
git config --list | grep hansolo

# Check all hooks
ls -la .claude/hooks/

# Verify commands
ls -la .claude/commands/hansolo/

# Check agents
ls -la .claude/agents/hansolo/
```

### Test Individual Components

```bash
# Test hook execution
echo '{"tool_name":"Edit"}' | .claude/hooks/checkpoint-commit.sh

# Test conflict parser
.claude/scripts/parse-conflicts.sh help

# Test project detection
.claude/scripts/detect-project.sh

# Test rate limit checker
.claude/scripts/check-rate-limits.sh
```

### Reset and Cleanup

If all else fails, reset han-solo:
```bash
# Backup current configuration
cp -r .claude .claude.backup

# Remove han-solo
rm -rf .claude/commands/hansolo
rm -rf .claude/agents/hansolo
rm -rf .claude/hooks

# Reinitialize
/hansolo:init
```

## Getting Additional Help

1. **Check logs**:
   ```bash
   tail -f /tmp/han-solo-performance.log
   ```

2. **Run integration tests**:
   ```bash
   bash tests/integration/test_complete_workflow.sh
   ```

3. **Enable verbose mode**:
   ```bash
   export VERBOSE=1
   export DEBUG=1
   ```

4. **Report issues**:
   - Include error messages
   - Provide steps to reproduce
   - Share relevant configuration

---

Remember: Most issues can be resolved by:
1. Checking prerequisites are installed
2. Ensuring proper permissions
3. Verifying configuration files
4. Running cleanup commands