# **han-solo Constitution**

## **Core Principles**

### **I. Agentic Orchestration**

The han-solo tool is architected as an intelligent orchestration layer, not a monolithic script. It is built on the triad of Claude Code's extensibility features: Slash Commands serve as the user-facing API for intent, Subagents act as isolated microservices for complex logic, and Hooks function as a middleware layer for deterministic rule enforcement. This separation of concerns is fundamental to the tool's modularity, resilience, and scalability.

### **II. Determinism Over Probabilism**

The tool's behavior must be robust, predictable, and opinionated. While the LLM provides intelligence, critical workflow rules are enforced through deterministic Claude Code Hooks, not probabilistic prompts. This ensures that essential quality gates, such as linting before commits or preventing direct pushes to main, are non-negotiable, application-level rules that execute automatically and reliably.

### **III. Linear History (NON-NEGOTIABLE)**

A clean, linear, and easily understandable Git history is a primary objective. This is achieved through a strict, opinionated Git workflow: all new work begins from a fresh, up-to-date main branch; feature branches are kept up-to-date via rebasing, not merging; and all pull requests are squash-merged to ensure a single, atomic commit represents each completed feature on the main branch.

### **IV. User-In-The-Loop Interaction**

The tool must keep the user in control of critical decisions. It must never commit, push, or create pull requests without explicit user permission (except when the /hansolo:ship command is invoked). For any interactive command that presents choices or requires input, the tool MUST stop, present the options clearly, and wait for an explicit user response before proceeding. It must never assume default options or bypass these safety mechanisms.

### **V. Ambient Awareness & Safety**

The user must have constant, non-intrusive situational awareness of their development environment. The custom Status Line is used to display the current project context, model usage, Git branch status, and, most importantly, actionable warnings for problem states like pipeline failures, branch divergence, or when a new feature branch is required. This provides an early warning system to prevent workflow errors.

## **Development Workflow**

The han-solo tool defines a structured development lifecycle managed through three primary commands:

1. **/hansolo:init**: Initializes a new project, scaffolding opinionated .gitconfig, .gitignore, and template files. It also programmatically configures GitHub branch protection rules to enforce the core principles.  
2. **/hansolo:launch**: Creates a new feature branch. This command includes a pre-flight check to ensure the user is not on main or a previously shipped branch. It then guarantees the new branch is created from the latest version of main.  
3. **/hansolo:ship**: Manages the pull request and deployment process. This includes generating a high-quality PR description, creating the PR on GitHub, and configuring a CI/CD pipeline via GitHub Actions for testing and automated deployment upon merge.

## **Quality Gates & Enforcement**

Workflow integrity is guaranteed by a series of automated checks implemented as Claude Code Hooks:

* **Pre-Commit Validation (PreToolUse Hook)**: Before any git commit is executed, a hook automatically runs linters and formatters relevant to the project type. The commit is blocked if any quality checks fail, and the LLM is instructed to fix the issues.  
* **Push Protection (PreToolUse Hook)**: A hook intercepts any git push command and blocks any attempt to push directly to the main branch, enforcing the pull request workflow.  
* **Transactional Workflow (PostToolUse & Stop Hooks)**: To maintain a granular audit trail during development, a PostToolUse hook creates a "checkpoint" commit after every file modification. When the task is complete, a Stop hook automatically squashes all intermediate checkpoints into a single, well-documented, atomic commit for the feature branch.

## **Governance**

This Constitution supersedes all other practices and conventions. All components of the han-solo tool, including the system prompts for its subagents (Red-Squadron, Gold-Squadron, Blue-Squadron, Green-Squadron, Rogue-Squadron) and the instructions within CLAUDE.md, must be implemented in alignment with these principles. The CLAUDE.md file serves as the runtime guide for enforcing the user interaction patterns defined herein. Amendments to this constitution require documentation, team approval, and a clear migration plan.

**Version**: 1.0.0 | **Ratified**: 2025-09-18 | **Last Amended**: 2025-09-18