# **Architecting han-solo: An Agentic Orchestrator for Modern Software Delivery**

## **Foundational Architecture: The Command, Agent, and Hook Triad**

The architecture of a sophisticated agentic tool like han-solo must be built upon a foundation that prioritizes resilience, modularity, and predictable behavior. The Claude Code ecosystem, with its distinct extensibility features, provides the necessary components for such an architecture. The most effective design moves beyond treating the tool as a single, monolithic script and instead conceptualizes it as an intelligent orchestration layer. This layer is composed of a triad of core components: Slash Commands for user interaction, Subagents for complex task execution, and Hooks for workflow enforcement. By strategically separating these concerns, the system achieves a level of robustness and scalability that is essential for enforcing an opinionated, high-quality software delivery methodology.

### **The Core Principle: Determinism over Probabilism**

A central requirement for han-solo is that it be "robust" and "opinionated," which translates to a technical mandate for deterministic execution. While large language models (LLMs) like Claude are highly capable of following complex instructions, their behavior is inherently probabilistic.1 Relying solely on a prompt to enforce a critical workflow step—for instance, instructing Claude to "run the linter before you commit"—introduces a potential point of failure. The model might misunderstand, forget, or otherwise deviate from the instruction, undermining the entire workflow.

Claude Code Hooks are specifically designed to solve this problem by providing "deterministic, programmatic control over Claude Code's behavior".2 Hooks are not suggestions to the LLM; they are application-level rules that execute automatically at specific points in the agent's lifecycle.1 This distinction is the architectural cornerstone of

han-solo.

The existence of separate features for commands, agents, and hooks within Claude Code is not an incidental design choice; it reflects a mature architectural pattern that mirrors modern software design principles:

* **Slash Commands** function as the public **API**, providing a clear, user-facing contract for initiating actions.  
* **Subagents** act as containerized **Microservices**, encapsulating complex, domain-specific logic in an isolated context.  
* **Hooks** serve as **Middleware** or a policy enforcement layer, intercepting operations to apply non-negotiable rules.

Embracing this separation of concerns is fundamental to building han-solo effectively. A typical user action, such as committing code, will trigger a chain of events that leverages this layered architecture. The user might type /han-solo:commit, a simple command that signals their intent. This command, in turn, invokes a specialized Gray-Squadron subagent to handle the complex logic of analyzing the code changes and generating a conventional commit message. Before the subagent can execute the final git commit tool, a PreToolUse hook intercepts the action, runs the linter and formatter, and only allows the commit to proceed if all quality checks pass.4 This sequence—

**Command \-\> Subagent \-\> Hook \-\> Tool Execution**—ensures that the user experience is simple, the complex logic is modular, and the workflow rules are inviolable.

### **Mapping han-solo Tasks to Claude Code Features**

To translate the abstract requirements of the han-solo product brief into a concrete and optimized implementation, each function must be mapped to the most appropriate Claude Code extensibility feature. This mapping forms the architectural blueprint for the tool, ensuring that each component is built using the primitive best suited for its purpose. This prevents architectural anti-patterns, such as embedding complex, multi-step logic within a simple slash command file instead of delegating it to a context-isolated subagent.6 The following table provides this foundational mapping.

**Table 1: Mapping han-solo Tasks to Claude Code Extensibility Features**

| han-solo Task | Primary Claude Code Feature | Rationale & Supporting Documentation |
| :---- | :---- | :---- |
| **User Interaction & Entry Points** |  |  |
| Initiate project setup | **Slash Command** (/hansolo:init) | Provides a direct, user-invoked entry point for a complex workflow. The command itself is simple; it delegates the heavy lifting to a subagent. 6 |
| Start a new feature branch | **Slash Command** (/hansolo:launch \<feature-name\>) | A common, discrete action perfectly suited for a simple command with an argument. 9 |
| Create a pull request | **Slash Command** (/hansolo:ship) | Serves as the user's intent signal, which then invokes the specialized Blue-Squadron subagent. |
| **Complex, Isolated Logic** |  |  |
| Project initialization & scaffolding | **Subagent** (Red-Squadron) | Isolates the context-heavy task of creating files (.gitignore, .gitconfig), configuring GitHub via API, and preventing pollution of the main chat. 10 |
| Opinionated Git operations (rebase, etc.) | **Subagent** (Gold-Squadron) | Encapsulates the specific, multi-step Git command sequences, ensuring they are executed correctly in a clean context. 11 |
| Generating PR descriptions | **Subagent** (Blue-Squadron) | Requires reading code diffs, issue details, and templates. This high-context task must be isolated to preserve the main agent's focus. 12 |
| Generating CI/CD YAML files | **Subagent** (Green-Squadron) | Involves project type detection, logic branching (e.g., npm vs. PyPI), and file generation—a perfect use case for a specialized agent. 14 |
| Generating atomic commit messages | **Subagent** (Gray-Squadron) | Encapsulates the logic for summarizing staged changes into a single, conventional commit message, ensuring consistency for the Stop hook's squashing process. 10 |
| AI-assisted conflict resolution | **Subagent** (Rogue-Squadron) | Isolates the highly specialized and complex task of parsing Git conflict markers, analyzing semantic differences, and proposing intelligent resolutions to the user. 10 |
| **Deterministic Rule Enforcement** |  |  |
| Enforce linting/formatting before commit | **Hook** (PreToolUse on git commit) | Guarantees the check runs deterministically every time, blocking the commit on failure using exit code 2\. This is non-negotiable for a robust workflow. 5 |
| Prevent direct pushes to main | **Hook** (PreToolUse on git push) | A script that checks the current branch and target, blocking any attempt to push directly to the main branch. 2 |
| Auto-sync main after PR merge | **Hook** (Stop or custom event) | A post-workflow hook that ensures the local main branch is always up-to-date, fulfilling a core tenet of the proposed workflow. 4 |
| **Ambient User Feedback** |  |  |
| Display current branch, PR status, CI checks | **Status Line** | Offers persistent, real-time, ambient information to the user without cluttering the chat history. A custom script can fetch this data. 17 |
| Switch between verbose/terse feedback | **Output Style** | Transforms the core interaction model based on user need (e.g., a "Training Mode" for juniors vs. a "Silent Mode" for experts). 19 |

## **The User Interface: Crafting an Intuitive Slash Command API**

The user-facing interface of han-solo will be defined by its suite of custom slash commands. The design philosophy for this "API" is to create a command set that is powerful yet simple, self-documenting, and capable of seamlessly integrating with natural language interaction. This approach ensures that the tool is both accessible to new users and efficient for power users.

### **Designing the Command Namespace**

To maintain clarity and prevent conflicts with other tools or built-in Claude Code commands, all han-solo functionality will be organized under a consistent namespace. Claude Code supports namespacing through directory structures; for instance, a file located at .claude/commands/frontend/component.md can be invoked with a namespaced command.8

han-solo will adopt the namespace /hansolo:\<verb\>. All command definition files will reside within the project's .claude/commands/hansolo/ directory. This structure provides immediate brand recognition for the tool's functions (e.g., /hansolo:init, /hansolo:launch, /hansolo:ship).

The content of each command's markdown file will be minimal. Instead of containing complex logic, each file will serve as a simple directive to invoke the appropriate subagent. For example, the file .claude/commands/hansolo/init.md would contain a prompt such as: "Invoke the han-solo-red-squadron subagent to set up this project according to the han-solo methodology. Pass all user-provided arguments directly to the subagent." This design choice adheres to the principle of separation of concerns, keeping the user interface layer clean and delegating complex operations to the specialized engine room of subagents.

### **Leveraging Metadata for a Self-Documenting Experience**

A key to creating an excellent user experience is making the tool's capabilities discoverable and easy to use. Claude Code's slash commands support YAML frontmatter in their markdown definition files, which can be used to provide metadata such as a description and an argument-hint.9 This metadata is displayed to the user in the command menu, effectively making the tool self-documenting.

Every han-solo command will have meticulously defined frontmatter. For the /hansolo:launch command, the definition file (.claude/commands/hansolo/launch.md) would look like this:

---

## **description: "Creates a new feature branch from an up-to-date main branch." argument-hint: ""**

Invoke the han-solo-gold-squadron subagent to create a new feature branch named 'feature/$1'. The subagent MUST ensure the main branch is synced with the remote before creating the new branch.

This approach elevates the slash command from a simple text macro to a well-defined API endpoint. The user immediately understands the command's purpose and the required arguments.

It is crucial to recognize the proper architectural role of slash commands within this system. While it is possible to embed multi-line scripts and complex logic directly into the command's markdown file, this is an anti-pattern for a robust tool like han-solo.6 Slash commands are best treated as simple, declarative

**intent triggers**. Their sole responsibility is to capture the user's intent and any associated arguments, and then pass control to a more capable and isolated subagent. Subagents are explicitly designed for complex, stateful operations and have their own context windows, making them far more resilient and easier to debug than logic embedded in a markdown file.10 The slash command is the "button"; the subagent is the "factory" that does the work.

### **Integrating with Natural Language via CLAUDE.md**

To create a more fluid and intuitive user experience, han-solo will leverage the CLAUDE.md file. This special file is automatically loaded into Claude's context at the start of a session and can be used to map natural language phrases to specific actions, including the execution of slash commands.6

A dedicated section within the project's CLAUDE.md file will establish these mappings, allowing users to interact with han-solo conversationally without needing to memorize the exact command syntax.

**Example CLAUDE.md entry:**

### **Han-Solo Workflow Triggers**

* When the user says "start a new feature" or "create a branch", execute the /hansolo:launch command. Use the subsequent words as the feature name argument.  
* When the user says "I'm ready to commit" or "commit my work", execute the /han-solo:commit command.  
* When the user says "create the PR" or "open a pull request", execute the /hansolo:ship command.

### **Never commit and push changes unless explicitly asked by the user.**

Always ask for permission before (except when /ship has been called):

* Running git commit  
* Running git push  
* Running gh pr create or any PR creation commands  
* Creating pull requests

### **Interaction behaviour:**

**⚠️ MANDATORY INTERACTION BEHAVIOR ⚠️**

#### **When Commands Require User Input:**

When executing commands that contain any of the following:

* read \-r statements  
* (USER INTERACTION REQUIRED) markers  
* Options presented as 1, \[2\], \[3\] etc.  
* Interactive prompts for user decisions  
* Choice menus or confirmation prompts

**YOU MUST**:

1. **STOP IMMEDIATELY** when you encounter the interaction point  
2. **PRESENT THE OPTIONS** clearly to the user  
3. **EXPLICITLY ASK** for their choice (e.g., "Which option would you like? Please tell me 1, 2, or 3")  
4. **WAIT FOR USER RESPONSE** before continuing  
5. **NEVER ASSUME DEFAULTS** for interactive prompts \- the user must make the choice

**YOU MUST NOT**:

* Continue past interaction points without user input  
* Assume or select default options automatically  
* Delegate to agents/subagents before getting user responses  
* Treat interactive commands as non-interactive

#### **Example Interaction Pattern:**

**CORRECT**:

Claude: "I detected merged PR \#87. The ship command needs your input:

\[1\] Start fresh (Recommended) \- Creates new branch with your changes  
\[2\] Create PR without rebasing \- Manual conflict resolution in GitHub  
\[3\] Continue with auto-resolution \- Let git-shipper attempt to fix

Which option would you prefer (1, 2, or 3)?"

User: "Let's go with option 2"

Claude: \[Continues with skip-rebase strategy\]

**INCORRECT**:

Claude: "I detected merged PR \#87, proceeding with option 1 (default)..."  
\[Continues without waiting for user input\]

#### **Two-Phase Command Execution:**

Commands with interaction points should be executed in phases:

* **Phase 1**: Run command up to the interaction point, gather context, present options  
* **PAUSE**: Wait for and receive user decision  
* **Phase 2**: Continue command execution with user's choice

#### **Special Cases:**

1. **Merged PR Detection in /ship**: Always requires user choice between fresh-start, skip-rebase, or auto-resolve  
2. **Branch Deletion Confirmations in /scrub**: Requires user confirmation for branches with unmerged commits  
3. **Launch Conflicts**: Requires user decision on how to handle stash conflicts

**NOTE TO CLAUDE**: Interactive prompts are designed to prevent data loss and ensure user control over critical decisions. Never bypass these safety mechanisms. When in doubt, stop and ask the user rather than assuming their intent.

This integration creates a powerful synergy. The user can describe their intent in plain English, which triggers the formal, structured workflow defined by the slash command. The command, in turn, invokes the specialized subagent, and the entire process is guarded by the deterministic hooks. This architecture successfully bridges the gap between the flexibility of conversational AI and the rigor of a repeatable, professional engineering process.

## **The Engine Room: Leveraging Subagents for Complex Operations**

The core logic of han-solo will be encapsulated within a suite of specialized, single-responsibility subagents. This architectural choice is fundamental to managing the complexity of the tool's operations. By isolating tasks, han-solo can maintain a clean primary conversation context, ensure modularity for easier maintenance and testing, and significantly improve the reliability of multi-step processes.

### **Why Subagents are Non-Negotiable for han-solo**

Each major function of han-solo—project initialization, Git operations, pull request generation, and CI/CD configuration—involves a sequence of actions like reading files, running commands, parsing output, and making decisions. Executing these tasks within the main chat thread would rapidly consume the context window with low-level operational details. This "context pollution" can lead to what community members describe as "context amnesia," where the primary agent loses track of the high-level objective due to the overwhelming amount of detail from the previous task.11

Subagents are the architectural solution to this problem. They provide dedicated, isolated context windows, ensuring that the details of one complex task do not interfere with the next.10 While some community discussions note that the context handoff between the main agent and a subagent can be a challenge for very large, amorphous projects, the tasks defined for

han-solo are discrete and well-defined, making them ideal candidates for subagent delegation.11 The design will adhere to best practices by creating focused subagents with detailed system prompts and tightly-scoped tool access, leading to higher success rates on designated tasks.10

### **The Red-Squadron Agent: Project Scaffolding and Guardrail Setup**

* **Trigger:** Invoked by the /hansolo:init slash command.  
* **Responsibilities:** This agent is responsible for the complete, one-time setup of a repository according to the han-solo standard.  
  1. **File Scaffolding:** It will create the opinionated configuration files specified in the project brief: .gitignore (with sensible defaults for common project types), the shared .gitconfig to enforce linear history preferences, the .gitmessage commit template, and the .github/pull\_request\_template.md.  
  2. **Remote Configuration:** Using the GitHub CLI (gh) or a dedicated GitHub API tool, the agent will programmatically configure the remote repository's branch protection rules. This includes enforcing that the main branch cannot be pushed to directly and that all merges must come through a pull request with passing status checks.  
  3. **Context Seeding:** It will create the initial CLAUDE.md file for the project, pre-populated with the natural language triggers defined in the previous section, ensuring the han-solo workflow is immediately accessible conversationally.

* ## **System Prompt Snippet (.claude/agents/hansolo/red-squadron.md):**     **name: hansolo-red-squadron description: "Sets up a new project with the han-solo opinionated Git and GitHub configuration." tools: Write, Bash, gh-cli**    **You are an expert project bootstrap agent. Your sole purpose is to scaffold a new repository with the standard han-solo configuration files. You MUST create .gitignore, .gitconfig, .gitmessage, and .github/pull\_request\_template.md with the prescribed content. Following file creation, you MUST use the gh tool to configure branch protection rules on the remote repository to prevent direct pushes to main and require pull requests with status checks.**

### **The Gold-Squadron Agent: Enforcing Linear History**

* **Trigger:** Invoked by commands like /hansolo:launch, /hansolo:sync, and /hansolo:rebase.  
* **Responsibilities:** This agent is the custodian of the local Git repository's state, enforcing the workflow's core tenets.  
  1. **Branch Creation:** This agent is responsible for creating new feature branches safely and predictably. Before creating a branch, it performs a pre-launch check:  
     * **Status Check:** It determines the current branch and checks if it is main or if it has already been merged into main.21  
     * **User Notification:** If the user is on main or a previously shipped branch, it provides a clear notification. For example: 'han-solo: You are on the main branch. A new feature branch will be created from the latest version of main.' This ensures the user is aware of the context before the new branch is created.5  
     * **Branching Sequence:** After the check and any necessary notification, it executes the precise sequence: git switch main && git pull \--ff-only && git switch \-c feature/\<branch-name\>. This guarantees that all new work starts from the absolute latest version of main without creating messy merge commits.  
  2. **Synchronization:** When syncing an existing feature branch with main, it will execute git fetch origin followed by git rebase origin/main, preserving a clean, linear project history.  
  3. **Guided Conflict Resolution:** A simple tool would fail and exit upon a rebase conflict. The Gold-Squadron agent is designed to turn this failure into a guided, interactive resolution process. When a rebase fails, the agent's prompt will instruct it to parse the conflict markers (\<\<\<\<\<\<\<, \=======, \>\>\>\>\>\>\>) from the affected files. It will then present a human-readable summary of the conflict to the user and offer intelligent options, such as "Conflict in user.service.ts: The remote changes add logging, while your local changes refactor the error handling. How should I proceed? (1) Keep my changes, (2) Accept remote changes, (3) I will provide a manual resolution." This transforms a common developer frustration into a collaborative problem-solving session, adding significant value over a standard CLI wrapper.

### **The Blue-Squadron Agent: From Diff to Description**

* **Trigger:** Invoked by the /hansolo:ship command.  
* **Responsibilities:** This agent automates the creation of high-quality, informative pull requests.  
  1. **Context Gathering:** It runs git diff origin/main...HEAD to get the full context of the changes made on the feature branch.  
  2. **Content Generation:** It reads the .github/pull\_request\_template.md to use as its output structure. It then analyzes the code diff to generate a concise one-line summary for the title and a more detailed bullet-point list of changes for the body.  
  3. **Issue Linking:** It will interactively prompt the user for the associated issue number (e.g., "Which issue does this PR close?") to automatically add the Closes: \#ISSUE\_NUMBER line to the description, ensuring proper work tracking.  
  4. **PR Creation:** Finally, it uses the gh pr create command, populating the title and body with the generated content to open the pull request on GitHub.

### **The Green-Squadron Agent: Intelligent Pipeline Generation**

* **Trigger:** Invoked by a command such as /hansolo:ci-setup.  
* **Responsibilities:** This agent streamlines the setup of continuous integration and deployment pipelines.  
  1. **Project Analysis:** It scans the project's root directory for key indicator files like package.json (Node.js), requirements.txt (Python), pom.xml (Maven), or go.mod (Go) to automatically detect the project type.  
  2. **Interactive Configuration:** Based on the detected project type, it presents the user with a list of recommended CI steps. For example: "I've detected a Python project. I recommend a CI pipeline with the following steps: Lint (flake8), Format (black), Test (pytest), and Deploy to PyPI. Do you approve and wish to configure deployment?"  
  3. **File Generation:** Upon approval, it generates the corresponding .github/workflows/ci.yml file with the correct syntax and steps for GitHub Actions.  
  4. **Secrets Management:** For deployment steps, the agent will identify the necessary secrets (e.g., PYPI\_API\_TOKEN, AWS\_ACCESS\_KEY\_ID). It will not ask for these secrets directly but will provide the user with the exact gh secret set command they need to run, along with a link to the repository's secrets settings page, ensuring a secure configuration process.

## **The Guardian: Enforcing Workflow Integrity with Hooks**

This section details the implementation of han-solo's enforcement layer using Claude Code Hooks. This is the most critical component for ensuring the tool's robustness, as it moves essential quality and process checks from being mere conventions to being non-negotiable system rules. Hooks provide the safety net that guarantees the integrity of the han-solo workflow.

### **Pre-Flight Checks with PreToolUse**

The PreToolUse hook event is ideal for implementing quality gates, as it runs before a tool is executed and can block the action if a check fails.3 It can be configured to trigger only for specific tools, and its script can block execution by returning an exit code of

2\. The stderr from the script is then fed back to Claude, allowing the agent to understand the reason for the failure and attempt a correction.5

han-solo will use a single "smart dispatcher" script for its pre-flight checks, a pattern that avoids performance degradation from multiple, broadly scoped hooks.24 This dispatcher is triggered on any

Bash tool usage and then internally routes to the appropriate validation logic based on the specific command being attempted.

**Configuration (.claude/settings.json):**

JSON

{  
  "hooks": {  
    "PreToolUse":  
      }  
    \]  
  }  
}

**Implementation (.claude/hooks/pre-flight-check.sh):**

Bash

\#\!/bin/bash  
set \-euo pipefail

\# Read the JSON payload from stdin  
json\_input=$(cat)  
command\=$(echo "$json\_input" | jq \-r '.tool\_input.command')

\# \--- Pre-Commit Hook Logic \---  
if \[\[ "$command" \== git\\ commit\* \]\]; then  
  echo "han-solo: Running pre-commit checks..." \>&2

  \# Auto-detect project type and run linter/formatter  
  if \[ \-f package.json \]; then  
    \# For Node.js projects  
    if\! npm run lint \--if-present; then  
      echo "han-solo: Linting failed. Commit blocked." \>&2  
      exit 2 \# Blocking exit code  
    fi  
  elif \[ \-f pyproject.toml \]; then  
    \# For Python projects  
    if\! ruff check. ||\! ruff format \--check.; then  
      echo "han-solo: Linter or formatter check failed. Commit blocked." \>&2  
      exit 2 \# Blocking exit code  
    fi  
  fi  
fi

\# \--- Pre-Push Hook Logic \---  
if \[\[ "$command" \== git\\ push\* \]\]; then  
  current\_branch=$(git rev-parse \--abbrev-ref HEAD)  
  if \[\[ "$current\_branch" \== "main" |

| "$current\_branch" \== "master" \]\]; then  
    echo "han-solo: Direct push to the main branch is forbidden. Use a pull request. Push blocked." \>&2  
    exit 2 \# Blocking exit code  
  fi  
fi

exit 0 \# Success, allow command to proceed

This hook establishes a powerful, self-correcting feedback loop. If Claude, guided by the Gold-Squadron subagent, attempts to commit code that fails the linting check, the hook script will exit with code 2\. Claude Code will block the git commit command and feed the stderr message ("han-solo: Linting failed. Commit blocked.") back to the agent. The agent, now aware of the specific failure, can then parse the linting errors and attempt to fix the code automatically before re-attempting the commit. This elevates the system from a simple command executor to an intelligent, resilient workflow partner.

### **Granular History with PostToolUse Checkpoints**

Agentic workflows often involve numerous small, iterative changes. Capturing the history of these changes is invaluable for debugging and review. A pattern developed by the Claude Code community involves using PostToolUse hooks to create automatic "checkpoint" commits after every file modification.4 This provides a granular, step-by-step history of the AI's work during a session.

han-solo will adopt this pattern to enhance traceability. A PostToolUse hook will be configured to match the Write, Edit, and MultiEdit tools. The associated script will execute a git add for the modified file(s) followed by git commit \-m "checkpoint: \[han-solo\] modify $(basename \<file\>) \- $(date)". This creates a perfect audit trail of the agent's actions, making it trivial to use git revert to undo a single erroneous change without discarding the entire session's progress.

### **Atomic Commits with the Stop Hook**

While checkpoint commits are beneficial during development, they would clutter the final Git history, violating the han-solo principle of a clean, linear log. The Stop hook, which fires when an agent finishes its task, provides the perfect opportunity to consolidate this work.3

A script triggered by the Stop hook will perform the finalization of the session's work:

1. It will first identify the starting point of the work by finding the merge-base with the remote main branch (git merge-base HEAD origin/main).  
2. It will then execute a git reset \--soft \<merge-base-sha\>. This command effectively undoes all the intermediate checkpoint commits but leaves all the file changes staged and ready for a new commit.  
3. Next, it will invoke a simplified version of the Gray-Squadron agent (or a dedicated script) to generate a single, high-quality, conventional commit message that summarizes all the staged changes, using the .gitmessage template.  
4. Finally, it will execute the definitive git commit, creating a single, atomic, and well-documented entry in the feature branch's history.

The combination of PostToolUse checkpointing and Stop hook squashing creates a "transactional" AI workflow. The development process is treated as a single transaction. During the session, every micro-change is saved and easily revertible, providing maximum flexibility and safety. When the task is complete, the entire body of work is committed atomically to the branch's history. This approach delivers the best of both worlds: granular traceability during the creative process and professional clarity in the final code artifact.

## **Advanced Feature Enhancements and Strategic Recommendations**

To elevate han-solo from a highly competent tool to a truly next-generation development partner, several advanced features can be implemented by leveraging the full spectrum of Claude Code's capabilities. These enhancements focus on improving situational awareness, adapting the interaction model to user needs, and intelligently handling failure states.

### **Dynamic Situational Awareness via Custom Status Lines**

The Claude Code status line provides a persistent, non-intrusive space for displaying real-time information. A custom script, configured via the /statusline command, can populate this area with contextually relevant data, giving the user ambient situational awareness without cluttering the main conversation window.26

A han-solo-status.sh script will be developed to provide this awareness. It will display key information about the current state of the workflow 18:

* **Project Folder:** 📁 han-solo-project \- Displays the root name of the project directory, providing immediate context.  
* **Current Model:** 🤖 Opus 4.1 \- Shows the active Claude model, which is available in the JSON data passed to the status line script.  
* **Context Window Usage:** 🧠 \[█████░░░░░\] 49% left \- A visual progress bar indicating the percentage of the context window remaining before an automatic /compact is triggered. This is crucial for managing long sessions and preventing unexpected context loss.  
* **Current Git Branch:** 🌿 Branch: feature/user-authentication  
* **Pull Request Status:** 🔗 PR: \#42 (Checks: 🟢 Passed) or (Checks: 🟡 Pending)  
* **Active Workflow Mode:** 🎯 Mode: han-solo (Tutor)  
* **Problem State Notifications:** The status line will also serve as an early warning system for common workflow issues, providing clear, actionable alerts:  
  * **New Branch Required:** ⚠️ On main, use /hansolo:launch to start\! \- This warning appears if the user is on the main branch or an old feature branch that has already been merged, reminding them to start new work correctly.  
  * **Pipeline Failures:** 🔥 PR \#42 Checks Failed\! \- If the CI/CD pipeline for the current pull request fails, this notification provides immediate feedback, allowing the user to investigate without waiting for a GitHub notification.  
  * **Branch Divergence:** 🚨 Branch diverged from remote\! \- This indicates that both the local and remote branches have unique commits, requiring a pull or rebase to resolve.

The script will gather this information by parsing a JSON object passed to it via stdin, which contains the model name and project directory. To calculate context usage, the script will read the session's transcript file, estimate the total tokens, and calculate the percentage used against the model's context limit. For problem state notifications, the script will execute lightweight git and gh commands to check branch status and pipeline health, ensuring the user is always aware of the repository's state.27 This provides the user with instant, at-a-glance feedback on their position within the development lifecycle.

### **Adaptive Interaction with Custom Output Styles**

Output Styles are a powerful feature that allows for the complete replacement of Claude's core system prompt, fundamentally altering its personality, tone, and communication style while preserving its access to all underlying tools and capabilities.19 This enables

han-solo to adapt its interaction model to different users and scenarios.

Two custom output styles will be defined for han-solo:

1. **han-solo-strict (Default):** This style's system prompt will instruct Claude to be concise, professional, and fact-driven. Its responses will be terse, focusing on task completion and providing machine-readable output (like JSON or YAML) where appropriate. This mode is optimized for experienced developers who prioritize efficiency.  
2. **han-solo-tutor (Learning Mode):** This style is designed for onboarding and training. Its system prompt will instruct Claude to explain the *'why'* behind every action it takes within the han-solo workflow. When it creates a new branch, it will explain the importance of syncing with main first. When it performs a rebase, it will describe the benefits of maintaining a linear history.

Users can easily switch between these modes using /output-style han-solo-tutor. This transforms the tool from a system that merely *enforces* a workflow into a mentor that actively *teaches* it, making it an invaluable asset for team development and knowledge sharing.

### **The Rogue-Squadron Agent: A Future-Forward Feature**

Building upon the guided conflict resolution concept for the Gold-Squadron agent, a more advanced, dedicated Rogue-Squadron agent represents the next frontier in agentic development: AI-assisted failure recovery.

The proposed workflow is as follows:

1. The Gold-Squadron subagent attempts a git rebase operation, which fails due to conflicts.  
2. A PostToolUse hook is configured to detect a non-zero exit code from any git rebase command.  
3. This hook's script, instead of just reporting the failure, explicitly invokes the Rogue-Squadron subagent, passing the list of conflicting files as arguments.  
4. The Rogue-Squadron has a highly specialized system prompt: "You are an expert at resolving Git merge conflicts. For each file provided, analyze the content between the \<\<\<\<\<\<\<, \=======, and \>\>\>\>\>\>\> markers. Explain the semantic conflict in plain English. Then, propose a logically merged version of the code that correctly synthesizes both sets of changes. Present your proposed resolution in a code block for user approval."  
5. The user reviews the AI-proposed resolution. Upon approval, the agent applies the changes to the file, runs git add, and continues the rebase with git rebase \--continue.

This feature moves beyond simple task execution and into the realm of intelligent problem-solving, where the AI agent is not just a tool but a partner in overcoming common development hurdles.

### **Secure and Intelligent CD Pipeline Configuration**

The Green-Squadron agent can be enhanced to handle the sensitive nature of deployment secrets with greater security and intelligence.

1. After the agent generates the .github/workflows/ci.yml file, it will parse the file to identify the names of any secrets required for the deployment steps (e.g., VERCEL\_TOKEN, NPM\_TOKEN).  
2. It will then use the gh secret set command. However, to avoid having the user paste a sensitive token directly into the terminal where it could be logged in the conversation transcript, the agent will take a more secure approach.  
3. It will prompt the user: "This deployment requires the VERCEL\_TOKEN secret. Please paste the token now. Your input will be masked and will not be saved in our conversation history."  
4. The agent will then execute a shell command that uses read \-s (silent read) to capture the user's input without echoing it to the screen. This input is then piped directly to the gh secret set VERCEL\_TOKEN \--body \- command.

This workflow demonstrates a sophisticated understanding of both the functional requirements of CI/CD setup and the critical operational security practices of a real-world development environment. It makes han-solo not just a powerful and efficient tool, but also a trustworthy one.

#### **Works cited**

1. Claude Code Hooks: What is and How to Use It \- CometAPI, accessed on September 18, 2025, [https://www.cometapi.com/claude-code-hooks-what-is-and-how-to-use-it/](https://www.cometapi.com/claude-code-hooks-what-is-and-how-to-use-it/)  
2. What is Claude Code Hooks and How to Use It \- Apidog, accessed on September 18, 2025, [https://apidog.com/blog/claude-code-hooks/](https://apidog.com/blog/claude-code-hooks/)  
3. Get started with Claude Code hooks \- Anthropic, accessed on September 18, 2025, [https://docs.anthropic.com/en/docs/claude-code/hooks-guide](https://docs.anthropic.com/en/docs/claude-code/hooks-guide)  
4. HOW TO USE \`HOOKS\` on CLAUDE CODE CLI: Intelligent Git workflow automation for Claude Code that creates checkpoint commits on every file change and squashes them into meaningful task commits. \- Reddit, accessed on September 18, 2025, [https://www.reddit.com/r/ClaudeAI/comments/1m083kb/how\_to\_use\_hooks\_on\_claude\_code\_cli\_intelligent/](https://www.reddit.com/r/ClaudeAI/comments/1m083kb/how_to_use_hooks_on_claude_code_cli_intelligent/)  
5. Hooks reference \- Claude Docs, accessed on September 18, 2025, [https://docs.anthropic.com/en/docs/claude-code/hooks](https://docs.anthropic.com/en/docs/claude-code/hooks)  
6. Claude Code Slash Commands: Boost Your Productivity with Custom Automation, accessed on September 18, 2025, [https://alexop.dev/tils/claude-code-slash-commands-boost-productivity/](https://alexop.dev/tils/claude-code-slash-commands-boost-productivity/)  
7. is claude able to use custom slash commands inside a custom slash command? \- Reddit, accessed on September 18, 2025, [https://www.reddit.com/r/ClaudeAI/comments/1lwsfo4/is\_claude\_able\_to\_use\_custom\_slash\_commands/](https://www.reddit.com/r/ClaudeAI/comments/1lwsfo4/is_claude_able_to_use_custom_slash_commands/)  
8. How to Add Custom Slash Commands in Claude Code \- AI Engineer Guide, accessed on September 18, 2025, [https://aiengineerguide.com/blog/claude-code-custom-command/](https://aiengineerguide.com/blog/claude-code-custom-command/)  
9. Slash commands \- Claude Docs, accessed on September 18, 2025, [https://docs.anthropic.com/en/docs/claude-code/slash-commands](https://docs.anthropic.com/en/docs/claude-code/slash-commands)  
10. Subagents \- Claude Docs, accessed on September 18, 2025, [https://docs.anthropic.com/en/docs/claude-code/sub-agents](https://docs.anthropic.com/en/docs/claude-code/sub-agents)  
11. How to use Claude Code subagents to parallelize development \- Hacker News, accessed on September 18, 2025, [https://news.ycombinator.com/item?id=45181577](https://news.ycombinator.com/item?id=45181577)  
12. Claude Code: Best practices for agentic coding \- Anthropic, accessed on September 18, 2025, [https://www.anthropic.com/engineering/claude-code-best-practices](https://www.anthropic.com/engineering/claude-code-best-practices)  
13. Claude Sub-Agents Workflow (Full Demo) \- YouTube, accessed on September 18, 2025, [https://www.youtube.com/watch?v=-zzbkh9B-5Q](https://www.youtube.com/watch?v=-zzbkh9B-5Q)  
14. Building with Claude Code Subagents (My Beloved Minions) | by Yee Fei \- Medium, accessed on September 18, 2025, [https://medium.com/@ooi\_yee\_fei/building-with-claude-code-subagents-my-beloved-minions-b5a9a4318ba5](https://medium.com/@ooi_yee_fei/building-with-claude-code-subagents-my-beloved-minions-b5a9a4318ba5)  
15. How Claude Code Hooks Save Me HOURS Daily \- YouTube, accessed on September 18, 2025, [https://www.youtube.com/watch?v=Q4gsvJvRjCU](https://www.youtube.com/watch?v=Q4gsvJvRjCU)  
16. disler/claude-code-hooks-mastery \- GitHub, accessed on September 18, 2025, [https://github.com/disler/claude-code-hooks-mastery](https://github.com/disler/claude-code-hooks-mastery)  
17. medium.com, accessed on September 18, 2025, [https://medium.com/@joe.njenga/how-im-using-claude-code-status-line-new-feature-to-keep-context-96a4adf21728\#:\~:text=What%20is%20Claude%20Code%20Status%20Line%3F\&text=Claude%20Code's%20Status%20Line%20feature,and%20updated%20in%20real%2Dtime.](https://medium.com/@joe.njenga/how-im-using-claude-code-status-line-new-feature-to-keep-context-96a4adf21728#:~:text=What%20is%20Claude%20Code%20Status%20Line%3F&text=Claude%20Code's%20Status%20Line%20feature,and%20updated%20in%20real%2Dtime.)  
18. Claude Code Status Line Script \- Andrea Grandi, accessed on September 18, 2025, [https://www.andreagrandi.it/posts/claude-code-status-line-script/](https://www.andreagrandi.it/posts/claude-code-status-line-script/)  
19. What is Output Styles in Claude Code | ClaudeLog, accessed on September 18, 2025, [https://www.claudelog.com/faqs/what-is-output-styles-in-claude-code/](https://www.claudelog.com/faqs/what-is-output-styles-in-claude-code/)  
20. Claude Code Tips & Tricks: Custom Slash Commands \- Cloud Artisan, accessed on September 18, 2025, [https://cloudartisan.com/posts/2025-04-14-claude-code-tips-slash-commands/](https://cloudartisan.com/posts/2025-04-14-claude-code-tips-slash-commands/)  
21. Claude Code Adds /statusline Command: Custom Status Bar Display : r/ClaudeAI \- Reddit, accessed on September 18, 2025, [https://www.reddit.com/r/ClaudeAI/comments/1mlhx2j/claude\_code\_adds\_statusline\_command\_custom\_status/](https://www.reddit.com/r/ClaudeAI/comments/1mlhx2j/claude_code_adds_statusline_command_custom_status/)  
22. How Can I Know if a Branch Has Been Already Merged Into Master? \- Better Stack, accessed on September 18, 2025, [https://betterstack.com/community/questions/how-to-know-if-branch-has-been-already-merged/](https://betterstack.com/community/questions/how-to-know-if-branch-has-been-already-merged/)  
23. Claude Code Hooks: Automating macOS Notifications for Task Completion \- Masato Naka, accessed on September 18, 2025, [https://nakamasato.medium.com/claude-code-hooks-automating-macos-notifications-for-task-completion-42d200e751cc](https://nakamasato.medium.com/claude-code-hooks-automating-macos-notifications-for-task-completion-42d200e751cc)  
24. Hooks \- ClaudeLog, accessed on September 18, 2025, [https://www.claudelog.com/mechanics/hooks/](https://www.claudelog.com/mechanics/hooks/)  
25. I built a hook that gives Claude Code automatic version history, so you can easily revert any change \- Reddit, accessed on September 18, 2025, [https://www.reddit.com/r/ClaudeAI/comments/1ls64yu/i\_built\_a\_hook\_that\_gives\_claude\_code\_automatic/](https://www.reddit.com/r/ClaudeAI/comments/1ls64yu/i_built_a_hook_that_gives_claude_code_automatic/)  
26. Automate Your AI Workflows with Claude Code Hooks \- Butler's Log \- GitButler, accessed on September 18, 2025, [https://blog.gitbutler.com/automate-your-ai-workflows-with-claude-code-hooks](https://blog.gitbutler.com/automate-your-ai-workflows-with-claude-code-hooks)  
27. cli/cli: GitHub's official command line tool \- GitHub, accessed on September 18, 2025, [https://github.com/cli/cli](https://github.com/cli/cli)  
28. gh workflow list \- GitHub CLI, accessed on September 18, 2025, [https://cli.github.com/manual/gh\_workflow\_list](https://cli.github.com/manual/gh_workflow_list)  
29. Output Styles \- ClaudeLog, accessed on September 18, 2025, [https://www.claudelog.com/mechanics/output-styles/](https://www.claudelog.com/mechanics/output-styles/)