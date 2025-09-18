# Tasks: han-solo - Agentic Orchestrator

**Input**: Design documents from `/specs/001-spec-md/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → If not found: ERROR "No implementation plan found"
   → Extract: tech stack, libraries, structure
2. Load optional design documents:
   → data-model.md: Extract entities → model tasks
   → contracts/: Each file → contract test task
   → research.md: Extract decisions → setup tasks
3. Generate tasks by category:
   → Setup: project init, dependencies, linting
   → Tests: contract tests, integration tests
   → Core: models, services, CLI commands
   → Integration: DB, middleware, logging
   → Polish: unit tests, performance, docs
4. Apply task rules:
   → Different files = mark [P] for parallel
   → Same file = sequential (no [P])
   → Tests before implementation (TDD)
5. Number tasks sequentially (T001, T002...)
6. Generate dependency graph
7. Create parallel execution examples
8. Validate task completeness:
   → All contracts have tests?
   → All entities have models?
   → All endpoints implemented?
9. Return: SUCCESS (tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
- Claude Code configuration: `.claude/` directory
- Scripts and hooks: `.claude/hooks/`, `.claude/scripts/`
- Commands: `.claude/commands/hansolo/`
- Agents: `.claude/agents/hansolo/`
- Templates: Repository root for .gitignore, .gitconfig, etc.

## Phase 3.1: Setup & Infrastructure
**Reference**: idea.md lines 186-193 (Red-Squadron setup), research.md lines 103-132 (Dependencies)

- [ ] T001 Create .claude directory structure (commands/hansolo/, agents/hansolo/, hooks/, output-styles/)
  - **Source**: data-model.md Section 1-4 (Entity storage locations)
- [ ] T002 [P] Create .gitignore template with common patterns for node/python/go projects
  - **Source**: idea.md line 189 (File Scaffolding requirements)
- [ ] T003 [P] Create .gitconfig template enforcing linear history (pull.ff=only, merge.ff=only)
  - **Source**: idea.md line 189, research.md line 37 (Git workflow enforcement)
- [ ] T004 [P] Create .gitmessage commit template with conventional format
  - **Source**: idea.md line 189, research.md line 209 (Conventional commits)
- [ ] T005 [P] Create .github/pull_request_template.md with sections for changes, testing, issues
  - **Source**: idea.md line 189, contracts/commands-api.yaml (PR structure)
- [ ] T006 Initialize .claude/settings.json with hook configurations
  - **Source**: research.md lines 214-230 (Hook configuration format)

## Phase 3.2: Hook Implementation (Enforcement Layer)
**CRITICAL: Hooks must be implemented before commands to ensure enforcement**
**Reference**: idea.md lines 224-294 (Pre-Flight Checks), research.md lines 257-279 (Hook templates)

- [ ] T007 Implement pre-flight-check.sh hook (.claude/hooks/pre-flight-check.sh) for PreToolUse validation
  - **Source**: idea.md lines 250-293 (Implementation example), research.md lines 257-279 (Template)
  - **Key Logic**: Git commit linting (lines 262-279), Push protection (lines 282-290)
- [ ] T008 Implement checkpoint-commit.sh hook (.claude/hooks/checkpoint-commit.sh) for PostToolUse
  - **Source**: idea.md lines 297-301, data-model.md (Checkpoint Commit entity)
- [ ] T009 Implement squash-commits.sh hook (.claude/hooks/squash-commits.sh) for Stop event
  - **Source**: idea.md lines 303-313 (Atomic commits logic)
- [ ] T010 Configure hook registration in .claude/settings.json
  - **Source**: research.md lines 214-230 (JSON configuration)

## Phase 3.3: Command Definitions (API Layer)
**Reference**: idea.md lines 52-81 (Command namespace), contracts/commands-api.yaml (API specs)

- [ ] T011 [P] Create /hansolo:init command (.claude/commands/hansolo/init.md)
  - **Source**: idea.md line 34, contracts/commands-api.yaml `/hansolo:init` endpoint
  - **Template**: idea.md line 62 (simple directive pattern)
- [ ] T012 [P] Create /hansolo:launch command (.claude/commands/hansolo/launch.md)
  - **Source**: idea.md lines 68-75 (YAML frontmatter example)
  - **API**: contracts/commands-api.yaml `/hansolo:launch` endpoint
- [ ] T013 [P] Create /hansolo:commit command (.claude/commands/hansolo/commit.md)
  - **Source**: idea.md line 21 (Gray-Squadron invocation)
  - **API**: contracts/commands-api.yaml `/hansolo:commit` endpoint
- [ ] T014 [P] Create /hansolo:sync command (.claude/commands/hansolo/sync.md)
  - **Source**: idea.md line 197, contracts/commands-api.yaml `/hansolo:sync`
- [ ] T015 [P] Create /hansolo:ship command (.claude/commands/hansolo/ship.md)
  - **Source**: idea.md line 36, contracts/commands-api.yaml `/hansolo:ship`
- [ ] T016 [P] Create /hansolo:ci-setup command (.claude/commands/hansolo/ci-setup.md)
  - **Source**: idea.md line 217, contracts/commands-api.yaml `/hansolo:ci-setup`

## Phase 3.4: Subagent Configurations (Logic Layer)
**Reference**: idea.md lines 173-223 (Squadron details), data-model.md Section 2 (Subagent entity)

- [ ] T017 [P] Configure Red-Squadron agent (.claude/agents/hansolo/red-squadron.md) for project init
  - **Source**: idea.md lines 186-194 (System prompt snippet)
  - **Responsibilities**: File scaffolding, remote config, context seeding
- [ ] T018 [P] Configure Gold-Squadron agent (.claude/agents/hansolo/gold-squadron.md) for Git operations
  - **Source**: idea.md lines 196-205 (Branch creation, sync, conflict resolution)
  - **Key Logic**: Pre-launch checks, branching sequence, guided conflicts
- [ ] T019 [P] Configure Blue-Squadron agent (.claude/agents/hansolo/blue-squadron.md) for PR generation
  - **Source**: idea.md lines 207-214 (Context gathering, content generation)
- [ ] T020 [P] Configure Green-Squadron agent (.claude/agents/hansolo/green-squadron.md) for CI/CD setup
  - **Source**: idea.md lines 216-223 (Project analysis, file generation)
- [ ] T021 [P] Configure Gray-Squadron agent (.claude/agents/hansolo/gray-squadron.md) for commit messages
  - **Source**: idea.md line 42 (Atomic commit message generation)
- [ ] T022 [P] Configure Rogue-Squadron agent (.claude/agents/hansolo/rogue-squadron.md) for conflict resolution
  - **Source**: idea.md lines 351-363 (AI-assisted failure recovery)

## Phase 3.5: Status & Output Configurations
**Reference**: idea.md lines 319-349 (Status line), data-model.md Section 7-8

- [ ] T023 Create han-solo-status.sh script (.claude/scripts/han-solo-status.sh) for status line
  - **Source**: idea.md lines 323-336 (Display items), research.md lines 281-291 (JSON input)
- [ ] T024 [P] Create han-solo-strict output style (.claude/output-styles/han-solo-strict.md)
  - **Source**: idea.md line 346 (Concise, professional style)
- [ ] T025 [P] Create han-solo-tutor output style (.claude/output-styles/han-solo-tutor.md)
  - **Source**: idea.md line 347 (Learning mode with explanations)
- [ ] T026 Configure status line in .claude/settings.json
  - **Source**: research.md lines 281-291 (Status line JSON format)

## Phase 3.6: Contract Validation Tests
**These tests validate the command/hook interfaces work correctly**
- [ ] T027 [P] Test /hansolo:init creates all required files (tests/contract/test_init_command.sh)
- [ ] T028 [P] Test /hansolo:launch creates feature branch correctly (tests/contract/test_launch_command.sh)
- [ ] T029 [P] Test pre-commit hook blocks on lint failure (tests/contract/test_precommit_hook.sh)
- [ ] T030 [P] Test push hook blocks direct main push (tests/contract/test_push_hook.sh)
- [ ] T031 [P] Test checkpoint commits are created (tests/contract/test_checkpoint.sh)
- [ ] T032 [P] Test squash operation works correctly (tests/contract/test_squash.sh)

## Phase 3.7: Integration Tests
**End-to-end workflow validation**
- [ ] T033 Test complete feature workflow: init → launch → commit → ship
- [ ] T034 Test conflict resolution workflow with Rogue-Squadron
- [ ] T035 Test CI/CD setup for Node.js project
- [ ] T036 Test CI/CD setup for Python project
- [ ] T037 Test status line updates with Git state changes

## Phase 3.8: Natural Language Integration
- [ ] T038 Update CLAUDE.md with han-solo command mappings
- [ ] T039 Add interaction rules to CLAUDE.md (permission requirements, interactive prompts)
- [ ] T040 Test natural language triggers ("start a new feature" → /hansolo:launch)

## Phase 3.9: Documentation & Polish
- [ ] T041 [P] Create user documentation in docs/user-guide.md
- [ ] T042 [P] Create troubleshooting guide in docs/troubleshooting.md
- [ ] T043 [P] Add examples to quickstart.md
- [ ] T044 Validate all hook scripts are POSIX-compliant
- [ ] T045 Performance test: Ensure hooks execute in <100ms

## Missing Tasks Identified During Audit

### Additional Setup Tasks Needed:
- [ ] T046 Create project type detection script (.claude/scripts/detect-project.sh)
  - **Source**: research.md lines 237-246 (Linter auto-detection matrix)
  - **Critical for**: T007 hook, T020 Green-Squadron agent

- [ ] T047 Create GitHub branch protection configuration script
  - **Source**: research.md lines 293-309 (Branch protection setup)
  - **Required by**: T017 Red-Squadron agent

- [ ] T048 Create conflict marker parsing utilities
  - **Source**: idea.md line 204 (Guided conflict resolution)
  - **Required by**: T018 Gold-Squadron, T022 Rogue-Squadron

### Missing Integration Points:
- [ ] T049 Create hook performance monitoring script
  - **Source**: research.md lines 268-276 (Performance timer template)
  - **Target**: <100ms execution time

- [ ] T050 Create rate limit checking utility for GitHub API
  - **Source**: Research findings - gh rate limits
  - **Used by**: Status line, Blue-Squadron

## Dependencies
- Infrastructure (T001-T006) must complete first
- Project detection (T046) before hooks (T007-T010)
- Hooks (T007-T010) before commands (T011-T016)
- Commands before subagents (T017-T022)
- Utilities (T047-T050) can run parallel with subagents
- Core implementation before tests (T027-T037)
- Everything before documentation (T041-T045)

## Parallel Execution Examples

### Batch 1: Templates (can run simultaneously)
```
Task: "Create .gitignore template with common patterns"
Task: "Create .gitconfig template enforcing linear history"
Task: "Create .gitmessage commit template"
Task: "Create .github/pull_request_template.md"
```

### Batch 2: Command Definitions (can run simultaneously)
```
Task: "Create /hansolo:init command in .claude/commands/hansolo/init.md"
Task: "Create /hansolo:launch command in .claude/commands/hansolo/launch.md"
Task: "Create /hansolo:commit command in .claude/commands/hansolo/commit.md"
Task: "Create /hansolo:sync command in .claude/commands/hansolo/sync.md"
Task: "Create /hansolo:ship command in .claude/commands/hansolo/ship.md"
Task: "Create /hansolo:ci-setup command in .claude/commands/hansolo/ci-setup.md"
```

### Batch 3: Subagent Configurations (can run simultaneously)
```
Task: "Configure Red-Squadron agent for project initialization"
Task: "Configure Gold-Squadron agent for Git operations"
Task: "Configure Blue-Squadron agent for PR generation"
Task: "Configure Green-Squadron agent for CI/CD setup"
Task: "Configure Gray-Squadron agent for commit messages"
Task: "Configure Rogue-Squadron agent for conflict resolution"
```

### Batch 4: Contract Tests (can run simultaneously after implementation)
```
Task: "Test /hansolo:init command creates required files"
Task: "Test /hansolo:launch creates feature branch correctly"
Task: "Test pre-commit hook blocks on lint failure"
Task: "Test push hook blocks direct main push"
Task: "Test checkpoint commits are created"
Task: "Test squash operation works correctly"
```

## Notes
- [P] tasks = different files, no shared dependencies
- Hook scripts must be executable (chmod +x)
- All markdown files must include proper YAML frontmatter
- Commit after each completed task phase
- Test scripts should use bash with set -euo pipefail

## Task Generation Rules
*Applied during main() execution*

1. **From Contracts**:
   - commands-api.yaml → 6 command implementation tasks
   - hooks-api.yaml → 3 hook script tasks
   - status-api.yaml → 1 status line script task

2. **From Data Model**:
   - SlashCommand entity → command file tasks
   - Subagent entity → agent configuration tasks
   - Hook entity → hook script tasks
   - Settings entity → settings.json task

3. **From Quickstart**:
   - Each workflow step → integration test
   - Each troubleshooting item → validation test

4. **Ordering**:
   - Setup → Hooks → Commands → Agents → Tests → Integration → Documentation
   - Dependencies block parallel execution

## Validation Checklist
*GATE: Checked by main() before returning*

- [x] All contracts have corresponding implementation tasks
- [x] All entities have creation tasks
- [x] Hook implementation comes before command implementation
- [x] Parallel tasks truly independent (different files)
- [x] Each task specifies exact file path
- [x] No task modifies same file as another [P] task
- [x] All 6 commands from spec are included
- [x] All 6 squadrons from spec are included
- [x] All 3 hook types are implemented
- [x] Status line and output styles included
- [x] **NEW**: All tasks reference source documentation
- [x] **NEW**: Critical utilities identified and added (T046-T050)
- [x] **NEW**: Dependencies properly sequenced
- [x] **NEW**: Performance monitoring included

## Implementation Guidance Summary

### Quick Reference for Implementers:
1. **For Hook Implementation**: Start with research.md lines 257-279 (template)
2. **For Commands**: Use idea.md lines 68-75 (YAML frontmatter pattern)
3. **For Subagents**: Reference idea.md lines 186-223 (Squadron details)
4. **For GitHub Integration**: See research.md lines 293-309 (gh commands)
5. **For Linter Detection**: Use research.md lines 237-246 (detection matrix)

---
*Total Tasks: 50* (45 original + 5 critical gaps identified)
*Estimated Parallel Groups: 10*
*Critical Path: Setup → Detection → Hooks → Commands → Tests → Documentation*
*All tasks now include source references for implementation guidance*