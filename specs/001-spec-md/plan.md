
# Implementation Plan: han-solo - Agentic Orchestrator

**Branch**: `001-spec-md` | **Date**: 2025-09-18 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-spec-md/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → If not found: ERROR "No feature spec at {path}"
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → Detect Project Type from context (web=frontend+backend, mobile=app+api)
   → Set Structure Decision based on project type
3. Fill the Constitution Check section based on the content of the constitution document.
4. Evaluate Constitution Check section below
   → If violations exist: Document in Complexity Tracking
   → If no justification possible: ERROR "Simplify approach first"
   → Update Progress Tracking: Initial Constitution Check
5. Execute Phase 0 → research.md
   → If NEEDS CLARIFICATION remain: ERROR "Resolve unknowns"
6. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent-specific template file (e.g., `CLAUDE.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot, `GEMINI.md` for Gemini CLI, `QWEN.md` for Qwen Code or `AGENTS.md` for opencode).
7. Re-evaluate Constitution Check section
   → If new violations: Refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
8. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
9. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 7. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary
The han-solo feature is an agentic orchestrator tool for Claude Code that enforces opinionated best practices and automates Git workflows. It provides deterministic workflow enforcement through hooks, maintains linear Git history through automated rebasing, and ensures code quality through pre-commit validation. The tool is architected using Claude Code's extensibility triad: slash commands for user interaction, subagents for complex task isolation, and hooks for deterministic rule enforcement.

## Technical Context
**Language/Version**: Bash/Shell Scripts (POSIX compliant), Markdown for configuration
**Primary Dependencies**: Claude Code CLI, Git, GitHub CLI (gh), jq for JSON parsing
**Storage**: File-based configuration (.claude/ directory structure)
**Testing**: Shell script validation, hook execution tests
**Target Platform**: macOS/Linux with Claude Code installed
**Project Type**: single - CLI tool extension for Claude Code
**Performance Goals**: <100ms hook execution time, instant command response
**Constraints**: Must not interfere with Claude Code's core functionality, hooks must be non-blocking unless explicitly designed as gates
**Scale/Scope**: 15 commands, 6 subagents, 5 hooks, 2 output styles

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Core Principles Alignment
- ✅ **Agentic Orchestration**: Design uses Commands/Subagents/Hooks triad as mandated
- ✅ **Determinism Over Probabilism**: Hooks enforce non-negotiable rules (pre-commit, push protection)
- ✅ **Linear History**: Enforced through rebase-only updates and squash merges
- ✅ **User-In-The-Loop**: Interactive prompts for critical decisions, explicit permission model
- ✅ **Ambient Awareness**: Status line for continuous context, warning system for problem states

### Development Workflow
- ✅ **/hansolo:init**: Specified for project initialization
- ✅ **/hansolo:launch**: Specified with pre-flight checks
- ✅ **/hansolo:ship**: Specified for PR creation

### Quality Gates
- ✅ **Pre-Commit Validation**: PreToolUse hook blocks commits on lint failure
- ✅ **Push Protection**: PreToolUse hook prevents direct main branch pushes
- ✅ **Transactional Workflow**: PostToolUse checkpoints + Stop hook squashing

### Governance
- ✅ All subagents aligned with Squadron naming convention
- ✅ CLAUDE.md integration planned for natural language triggers
- ✅ Hook architecture follows deterministic enforcement model

## Project Structure

### Documentation (this feature)
```
specs/[###-feature]/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
# Option 1: Single project (DEFAULT)
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# Option 2: Web application (when "frontend" + "backend" detected)
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# Option 3: Mobile + API (when "iOS/Android" detected)
api/
└── [same as backend above]

ios/ or android/
└── [platform-specific structure]
```

**Structure Decision**: Option 1 (Single project structure) - This is a CLI tool extension, not a web/mobile application

## Phase 0: Outline & Research
1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:
   ```
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

## Phase 1: Design & Contracts
*Prerequisites: research.md complete*

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Generate API contracts** from functional requirements:
   - For each user action → endpoint
   - Use standard REST/GraphQL patterns
   - Output OpenAPI/GraphQL schema to `/contracts/`

3. **Generate contract tests** from contracts:
   - One test file per endpoint
   - Assert request/response schemas
   - Tests must fail (no implementation yet)

4. **Extract test scenarios** from user stories:
   - Each story → integration test scenario
   - Quickstart test = story validation steps

5. **Update agent file incrementally** (O(1) operation):
   - Run `.specify/scripts/bash/update-agent-context.sh claude` for your AI assistant
   - If exists: Add only NEW tech from current plan
   - Preserve manual additions between markers
   - Update recent changes (keep last 3)
   - Keep under 150 lines for token efficiency
   - Output to repository root

**Output**: data-model.md, /contracts/*, failing tests, quickstart.md, agent-specific file

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
- Load `.specify/templates/tasks-template.md` as base
- Generate tasks from Phase 1 design docs (contracts, data model, quickstart)
- Each command → slash command file creation task [P]
- Each subagent → agent configuration task [P]
- Each hook → script implementation task
- Each contract endpoint → validation test task
- Configuration files → setup tasks

**Ordering Strategy**:
- Infrastructure first: .claude directory structure
- Configuration before implementation
- Hooks before commands (enforcement layer first)
- Commands before subagents (API before logic)
- Tests after implementation
- Mark [P] for parallel execution (independent files)

**Estimated Output**: 35-40 numbered, ordered tasks in tasks.md covering:
- 6 slash command definitions
- 6 subagent configurations
- 3 hook scripts (pre-flight, checkpoint, squash)
- 1 status line script
- 2 output style definitions
- Configuration files (settings.json, CLAUDE.md)
- Template files (.gitignore, .gitconfig, .gitmessage, PR template)
- Contract validation tests
- Integration test scenarios

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |


## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command)
- [x] Phase 1: Design complete (/plan command)
- [x] Phase 2: Task planning complete (/plan command - describe approach only)
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS
- [x] All NEEDS CLARIFICATION resolved
- [x] Complexity deviations documented (none required)

---
*Based on Constitution v2.1.1 - See `/memory/constitution.md`*
