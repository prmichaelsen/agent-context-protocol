# Changelog

All notable changes to the Agent Context Protocol will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [5.16.0] - 2026-03-13

### Added
- **`@acp.handoff` command** — generate cross-context task handoff reports for transferring work to agents in different repositories or providers
  - Synthesizes handoff from chat conversation context (primary source)
  - Describes the problem and request without prescribing implementation steps
  - Supports `--to` / `--target` arguments for explicit target, or infers from conversation
  - Resolves project names against `~/.acp/projects.yaml`
  - Includes source project path/repo URL for back-reference
  - Uses absolute file paths (from `/`) for cross-project clarity
  - Prompts user to output to chat or save to `agent/reports/`
  - Freeform format shaped by each handoff's specific needs

## [5.15.1] - 2026-03-09

### Fixed
- **Install script missing bundled scripts** — `acp.install.sh` and `acp.uninstall.sh` were not referenced by any command in package.yaml, so the dependency-based installer skipped them
  - Added `acp.install.sh` to `acp.package-create` and `acp.project-create` command dependencies
  - Added `acp.uninstall.sh` to `acp.package-remove` command dependencies

## [5.15.0] - 2026-03-09

### Added
- **`@acp.clarifications-research` command** — research and fill in agent-delegated clarification items
  - Scans clarification docs for research delegation markers (`research this`, `agent: ...`, etc.)
  - Classifies response lines as empty, user-answer, or research-request
  - Explores codebase (Glob, Grep, Read) to answer delegated questions
  - Replaces trigger lines with `[Researched]`-prefixed answers with file references
  - Supports `--latest`, `--dry-run`, `--scope <path>` arguments
  - Never modifies user answers, empty lines, or clarification status

## [5.14.0] - 2026-03-09

### Added
- **`--quick` and `--skip` flags for @acp.init** — faster initialization for returning users
  - `--quick` / `-q`: skips version checks, source file review, and doc sync
  - `--skip <items>`: granular control over 8 individual steps (checks, sessions, docs, global, keys, files, sync, progress)
  - Step 9: usage tip shown when no flags used so users discover faster modes naturally
  - @acp.init bumped to v1.1.0

## [5.13.1] - 2026-03-06

### Changed
- **Yes/No question format preference in clarifications** (Task 110) — improved UX for answering clarification questions
  - Prefer Yes/No over "Option A or Option B?" — users answer "yes/no" instead of "the former/the latter"
  - Two options with recommendation: "We recommend X. Acceptable?" (yes/no)
  - Two options without recommendation: "Do you prefer X?" (yes/no) — no forced recommendations
  - Multi-option discrete format: each sub-option gets its own `>` response line for inline yes/no
  - Updated conflict resolution in @acp.clarification-capture to yes/no/custom format
- **Milestone 15 Complete** — all 5 tasks done (106-110)

## [5.13.0] - 2026-03-04

### Added
- **Duplicate awareness in @acp.clarification-create** (Task 109) — avoids generating duplicate questions
  - Step 1.5: Check Existing Clarifications for Overlap
  - Title-based heuristic: infer relevance from filenames, only load relevant clars
  - Visible output showing which clarifications checked/skipped
  - Cross-references existing answers to skip already-answered questions

### Changed
- **Milestone 15 Complete** — Clarification Capture System fully implemented
  - 4/4 tasks complete: directive, templates, integration, duplicate awareness

## [5.12.3] - 2026-03-04

### Changed
- **Integrated @acp.clarification-capture into create commands** (Task 108) — all 4 create commands now support context capture
  - Updated: design-create, task-create, pattern-create, command-create
  - Added Arguments section with --from-clar, --from-clars, --from-chat, --from-context
  - Added Step 2.7: Capture Clarification Context (references shared directive)
  - Generate steps updated to insert Key Design Decisions section when context available

## [5.12.2] - 2026-03-04

### Added
- **Key Design Decisions section in entity templates** (Task 107) — optional section for capturing clarification decisions
  - Added to: design.template.md, task template, pattern.template.md, command.template.md
  - Category-grouped tables with Decision/Choice/Rationale columns
  - Populated by @acp.clarification-capture or manually authored

## [5.12.1] - 2026-03-04

### Added
- **@acp.clarification-capture shared directive** (Task 106) — reusable directive for capturing clarification decisions into entity documents
  - 8-step capture flow: detect sources, read clars, warn partial, resolve conflicts, synthesize chat, generate section, update status, return
  - Full argument table: `--from-clar`, `--from-clars`, `--from-chat`, `--from-context`
  - Auto-detect mode (default): implicit `--from-context` when no flags specified
  - Conflict resolution UX: flag for user, accept "most recent wins"
  - Warning UX for uncaptured decisions in session

## [5.12.0] - 2026-03-04

### Added
- **Clarification Capture System** (M15) — prevent loss of design rationale from ephemeral clarifications
  - Design document: `agent/design/local.clarification-capture-system.md`
  - Shared directive `@acp.clarification-capture` for embedding decisions in entity docs
  - "Key Design Decisions" optional section for entity templates (category-grouped tables)
  - `--from-clar`, `--from-clars`, `--from-chat`, `--from-context` arguments for create commands
  - Auto-detect and warn when uncaptured clarifications exist in session
  - Conflict resolution flow (flag and ask user to resolve)
  - Duplicate awareness in `@acp.clarification-create`
  - Milestone 15 with 4 tasks (106-109)

## [5.10.2] - 2026-03-02

### Fixed
- **macOS compatibility** — all scripts now work on macOS (BSD sed and missing sha256sum)
  - Replace all `sed -i` calls with portable `_sed_i` / `_yaml_sed_i` wrappers (17 call sites across 7 files)
  - macOS BSD sed requires `sed -i ''` (explicit empty backup suffix); GNU sed does not
  - Add `shasum -a 256` fallback for macOS where `sha256sum` is unavailable
  - Fixes install script failure: `sed: invalid command code f` on macOS temp paths

## [5.10.1] - 2026-03-01

### Added
- **Deliverables Verification Gate** (Task 95) — mandatory verification before task completion
  - `@acp.proceed` Step 3.5: verify all expected files exist before marking task complete
  - `@acp.proceed` Step A3.5: milestone completion sweep after autonomous task loop
  - Autonomous loop Step 4: VERIFY DELIVERABLES in per-task loop (renumbered 4-8)
  - Updated single-task and autonomous verification checklists with file existence checks
  - AGENT.md: added "Documentation is a First-Class Deliverable" to Quality Best Practices

## [5.10.0] - 2026-03-01

### Added
- **Sessions System** (M12) — global session tracking for concurrent multi-project agent work
  - `acp.sessions.sh` — self-contained script with 6 subcommands (register, deregister, list, clean, heartbeat, count)
  - `@acp.sessions` command — dedicated session management with NLP argument support
  - `sessions.template.yaml` — template for `~/.acp/sessions.yaml`
  - Directive-level integration: `@acp.init` (register), `@acp.status` (count), `@acp.report` (deregister)
  - PPID-based stale detection with dead-PID cleanup and timeout removal
  - E2E test suite: 16 tests, 40 assertions, 100% pass rate
  - AGENT.md Sessions System documentation section
  - Advisory-only — no locking or coordination

## [5.9.2] - 2026-03-01

### Added
- Session registration step in `@acp.init` (Step 1.5 — register + show siblings)
- Session count display in `@acp.status` (Step 5.5 — "Sessions: N active")
- Session deregistration step in `@acp.report` (Step 10 — end session)
- All integration steps guarded with "if script exists" for graceful degradation

## [5.9.1] - 2026-03-01

### Added
- `acp.sessions.sh` — self-contained sessions infrastructure script (6 subcommands)
- `sessions.template.yaml` — template for `~/.acp/sessions.yaml`
- Session management: register, deregister, list, clean, heartbeat, count
- PPID-based stale detection with dead-PID cleanup and 2h timeout removal
- `--pid` flag on register for explicit PID control

## [5.9.0] - 2026-03-01

### Added
- `saas-platform` massive benchmark — 15-step expert-complexity dual-seed benchmark
  - 20 buggy Express/Node.js seed files (auth bypass, plaintext passwords, filter bugs, wrong status codes)
  - 32 ACP documentation overlay files (8 design docs, 5 patterns, 3 milestones, 15 tasks)
  - 30 step prompts (15 ACP + 15 baseline) covering analysis through security hardening
  - `verify_saas_platform()` verification function in runner/verify.sh

### Fixed
- Baseline task names missing in benchmark report chart (task vs tasks YAML field fallback)

## [5.8.0] - 2026-03-01

### Added
- `get_git_origin()` and `get_git_branch()` utility functions in `acp.common.sh`
- `git_origin` and `git_branch` fields auto-detected and stored in project registry
- `@acp.projects-restore` command — clone missing projects from stored git origins
- `acp.projects-restore.sh` script with `--dry-run` and `--install-acp` flags
- Git origin backfill pass in `@acp.projects-sync` for existing registered projects
- `--git-origin` and `--git-branch` flags on `@acp.project-update`
- Git origin display in `@acp.project-info` and `@acp.project-list` output

### Changed
- `register_project()` now accepts optional 5th/6th args for git_origin/git_branch with auto-detection fallback
- `@acp.projects-sync` detects and shows git origin during discovery, backfills missing origins
- Updated command docs: project-create, project-info, project-list, project-update, projects-sync

## [5.7.3] - 2026-03-01

### Added

**ACP-Initialized Project Benchmark** (Milestone 11 — Task 90):
- Dual-seed benchmark: seed-base (Express app, 9 files) + seed-acp (agent/ directory, 14 files)
- ACP mode gets pre-loaded designs, patterns, tasks, progress; baseline gets nothing
- Mode-specific step prompts: ACP prompts are 1 line each, baseline prompts are 15-44 lines each
- Runner enhanced: `seed_dir_acp` overlay, `skip_acp_install` config, `prompt_file_acp`/`prompt_file_baseline` support
- Verify function and GitHub Actions workflow choice added
- M11 complete (12/12 tasks)

## [5.7.2] - 2026-03-01

### Changed
- Add `--autonomous` flag alias to `@acp.proceed` command (equivalent to `--complete` and `--auto`)

## [5.7.1] - 2026-03-01

### Added

**Enterprise Task Manager Benchmark** (Milestone 11 — Task 89):
- Large-scope benchmark: 670+ line seed project (12 files) with 5 unlabeled bugs
- Circular dependencies, inconsistent patterns, missing auth on routes
- 10 step prompts: deep analysis, bug fixes, refactoring, 50+ tests, teams, activity feed, RBAC, security audit, migration docs
- Designed for 2-4 hour runtime per mode — punishes "dive in without planning"
- Verification function and GitHub Actions workflow choice added

**ACP-Initialized Project Benchmark Task** (Milestone 11 — Task 90):
- Task specification for dual-seed benchmark (planned, not yet implemented)
- Tests value of pre-existing ACP documentation vs no docs

## [5.7.0] - 2026-03-01

### Added

**Documentation & Historical Tracking — M11 Complete** (Milestone 11 — Task 86):
- Benchmark Suite section in AGENT.md (quick start, task table, architecture, key files)
- Benchmark section in README.md with quick-start commands
- Historical run comparison script (`compare-runs.sh`)
- Design document status updated to Implemented

**Milestone 11 Complete**: ACP Benchmark Suite — 10/10 tasks
- Full E2E benchmark system: ACP vs baseline comparison
- 6 benchmark tasks (simple → complex, including legacy refactor and event-driven pivot)
- LLM evaluator with 6-category rubric
- HTML dashboard with radar charts
- GitHub Actions on-demand workflow
- Historical tracking and documentation

## [5.6.3] - 2026-03-01

### Added

**GitHub Actions Workflow** (Milestone 11 — Task 85):
- On-demand benchmark workflow with `workflow_dispatch` trigger
- Configurable inputs: task selection, mode (acp/baseline/both), run count
- Report artifact upload with 90-day retention
- Job summary with YAML results
- Timeout controls: 90min per task, 2hr per job

## [5.6.2] - 2026-03-01

### Added

**Order Pipeline Benchmark** (Milestone 11 — Task 88):
- `order-pipeline` benchmark task: 7-step challenge with mid-stream sync-to-event-driven pivot
- Steps cover: catalog/inventory, cart/orders, state machine, tests, event-driven refactor, notifications+retry, integration+docs
- Verification function with event bus module detection (multiple naming conventions)

## [5.6.1] - 2026-03-01

### Added

**Legacy Refactor Benchmark** (Milestone 11 — Task 87):
- `legacy-refactor` benchmark task: 6-step refactoring challenge starting from messy seed app
- Seed application: working but poorly structured Express CRUD app with intentional bugs
- Seed directory support in run-single.sh (copies seed files + runs npm install before step 1)
- Verification function `verify_legacy_refactor()` in verify.sh

## [5.6.0] - 2026-03-01

### Added

**New Benchmark Tasks & Evaluator Fix** (Milestone 11 — Tasks 87, 88):
- Legacy Codebase Refactor benchmark (task-87): 6-step task starting from pre-built messy Express app, tests planning under constraints
- Event-Driven Order Pipeline benchmark (task-88): 7-step task with mid-stream sync-to-event-driven architectural pivot

### Fixed
- Evaluator JSON extraction now reads `.structured_output` (where `--json-schema` places data) instead of empty `.result` field

## [5.5.0] - 2026-02-28

### Added

**Report & Dashboard Enhancement** (Milestone 11 — Task 84):
- Improvement percentage column in metrics comparison tables (Markdown + HTML)
- Per-step breakdown tables showing step ID, phase, duration, tokens, turns
- Radar chart (Chart.js) for 6-dimension evaluation score visualization in HTML reports
- Evaluation scores written to summary.yaml per task/mode
- Checks row in verification tables
- serve-reports.sh index now shows eval scores, multi-task report links with task names

## [5.4.0] - 2026-02-28

### Added

**LLM Evaluator** (Milestone 11 — Task 83):
- `evaluator-prompt.md`: 6-category rubric (correctness, completeness, code style, documentation, architecture, testing) with scoring guidelines (1-10, MISS/MEETS/EXCEEDS)
- `evaluation-schema.json`: JSON schema for structured evaluator output
- Evaluator integration in `run-single.sh`: runs as separate Claude session after verification, saves per-category scores and rationales
- Evaluation tables in Markdown and HTML reports with color-coded scores and summaries

## [5.3.2] - 2026-02-28

### Added

- Benchmark runner injects `@acp.plan` directive (plan before building) into first step prompt in ACP mode
- Benchmark runner injects `@acp.proceed` directive (structured implementation) into subsequent step prompts in ACP mode
- Single-prompt benchmarks also receive plan directive in ACP mode

## [5.3.1] - 2026-02-28

### Fixed

- `run-single.sh`: grep commands now use `|| true` to prevent `set -euo pipefail` crashes when config fields are missing
- `run-single.sh`: timeout config parsing now matches both `timeout:` and `timeout_minutes:` field names
- `run-single.sh`: CHECKS_TOTAL calculation no longer produces multi-line output that breaks integer comparison
- `run-benchmark.sh`: HTML/Markdown reports now generated for all tasks in `--task all` mode (was skipped for multi-task runs)

## [5.3.0] - 2026-02-28

### Added

**Benchmark Task Suites** (Milestone 11 — Tasks 80-82):
- `simple-cli-tool` benchmark: 3 steps (build CSV-to-JSON CLI, test suite, fix empty cells bug)
- `medium-rest-api` benchmark: 4 steps (Express CRUD API, tests, fix DELETE/PUT bugs, refactor routes)
- `complex-auth-system` benchmark: 5 steps (scaffold, JWT auth, tests, fix security issues, docs)
- Verification functions for all three tasks in verify.sh

**Benchmark Runner Enhancements**:
- `--task all` flag to run all benchmark tasks in one command
- Tasks sorted by complexity (trivial → simple → medium → complex)
- Per-task error handling: failures don't abort the entire suite
- ACP init preamble (`@agent/commands/acp.init.md`) prepended to first prompt in ACP mode

### Fixed

- Update script (`acp.version-update.sh`) now writes full `.gitignore` (reports, clarifications, drafts, feedback, preferences) matching install script

## [5.2.0] - 2026-02-28

### Added

**Benchmark Runner Multi-Turn & Metrics Fix** (Milestone 11 — Task 79):
- Multi-turn step loop in run-single.sh with `--resume` session continuity
- Token metrics extraction fix: tries `.usage.*` (nested) then top-level with fallback
- Raw JSON output saved per step for debugging
- `metrics-collector.sh` for multi-run statistical aggregation (mean, stddev)
- `--runs N` flag in run-benchmark.sh for repeated benchmark execution
- Task-aware verification dispatch (`verify_<task_name>` functions)
- Per-step YAML metrics files with phase tagging
- Backward compatibility: single-prompt tasks (hello-world) work unchanged

## [5.1.0] - 2026-02-28

### Added

**@acp.proceed Autonomous Completion Mode** (Milestone 10 — Task 78):
- `--complete` / `--auto` / `--finish-milestone` flags for autonomous milestone completion
- `--commit` / `--commit-each` / `--with-commits` flags for per-task git commits
- `--dry-run` flag to preview planned tasks without execution
- Natural language argument parsing with fuzzy matching ("finish milestone", "just finish everything")
- `--complete` implies `--commit` — autonomous mode always commits per-task
- Mandatory confirmation prompt before autonomous execution
- Autonomous task loop: implements all remaining tasks, commits after each
- Per-task `@git.commit` subroutine integration (version bump, changelog, progress)
- Progress indicators with bar graphs and task status symbols between tasks
- Summary report at end of run (completions, failures, commits, version range)
- Error handling: halt on failures, never commit partial work, seek user intervention
- Interruption handling: infer user intent from messages during autonomous runs
- `@acp.proceed` command bumped to v2.0.0

## [5.0.1] - 2026-02-28

### Changed

- Added "Use Direct Git Commits" best practice to AGENT.md workflow guidelines — agents should use `git commit -m` directly, not bash tools or heredocs

## [5.0.0] - 2026-02-28

### Added

**Template Source Files Support** (Milestone 9):
- `contents.files` section in package.yaml schema for declaring template files
- Template files install to project-specified target paths (not agent/)
- Variable substitution system with `{{PLACEHOLDER}}` format
- `.template` extension stripping during installation
- Selective installation via `--files` flag
- Unsafe target path rejection (no `../` or absolute paths)
- Manifest tracking for template files: target paths, variable values, checksums
- Helper functions: `is_template_file_modified()`, `get_template_file_target()`, `get_template_file_variables()`, `update_template_file_in_manifest()`
- `@acp.package-list` shows template file counts and modification status
- `@acp.package-remove` removes template files from target paths
- `@acp.package-update` updates template files with stored variable reuse
- `@acp.package-validate` validates template file declarations
- Backward compatibility for packages without `contents.files` metadata
- 34 E2E tests covering all template features (100% pass rate)
- AGENT.md documentation for Template Source Files

### Fixed

- Manifest `packages: {}` bug where empty manifest skipped package entry creation

## [4.6.1] - 2026-02-27

### Fixed

- Argument parsing for `--commands`, `--patterns`, `--designs`, and `--files` now correctly stops on single-dash flags like `-y`, preventing them from being consumed as filenames

## [4.6.0] - 2026-02-27

### Added

- `--list` flag for package install now shows full file preview (clone → scan → validate → display) without installing

## [4.5.0] - 2026-02-27

### Added

- `report-html.sh`: standalone HTML report generator with styled metrics and verification tables
- `report-markdown.sh`: standalone Markdown report generator with diff annotations
- `serve-reports.sh`: index.html generator and HTTP dev server with hot reload on refresh
- Benchmark runner now automatically generates HTML and Markdown reports after each run

### Changed

- `run-benchmark.sh` summary output now lists individual report file paths (YAML, Markdown, HTML)

## [4.4.0] - 2026-02-27

### Added

- Benchmark suite infrastructure for empirically measuring ACP's value
- `hello-world` benchmark task: simple shell script creation with automated verification
- `run-benchmark.sh` entry point: runs tasks in ACP vs baseline modes with side-by-side comparison
- `run-single.sh` executor: isolated workspace creation, Claude CLI invocation, JSON metrics parsing
- `verify.sh` verification framework: checks file existence, executability, and output correctness
- Per-run YAML reports and `summary.yaml` with token/turn/cost diff calculations
- Benchmark reports excluded from version control via `.gitignore`

## [4.3.1] - 2026-02-27

### Fixed

- Install script now creates `drafts/`, `clarifications/`, `feedback/`, and `preferences/` directories
- Install script `.gitignore` now includes all local-only directories (was only `reports/`)
- Install script now copies clarification template to `agent/clarifications/`

## [4.3.0] - 2026-02-27

### Added

- `agent/files/` directory support in package installer — files install to project root (`.`), preserving subdirectory structure
- `--files` flag for selective installation of files directory
- Unrecognized directory warning when packages contain dirs outside the known set (patterns, commands, design, scripts, files)
- `scripts: []` and `files: []` arrays in manifest package template

**Project Registry System**:
- Global project registry at `~/.acp/projects.yaml` for tracking all ACP projects
- `@acp.project-list` - List all registered projects with filtering by type, status, tags
- `@acp.project-set` - Switch between projects (context switching)
- `@acp.project-info` - Show detailed project information including metadata
- `@acp.project-update` - Update project metadata (type, status, tags, description, related projects)
- `@acp.project-remove` - Remove projects from registry (keeps project files)
- `@acp.projects-sync` - Discover and register existing projects in `~/.acp/projects/`
- Automatic project registration on creation via `@acp.project-create`
- Current project tracking for context-aware operations
- Relationship and dependency tracking between projects

**Documentation**:
- Added "Project Registry System" section to AGENT.md with commands, examples, and workflow
- Added "Project Registry" section to README.md with quick examples
- Updated command list in README.md with all project registry commands

**Milestone Progress**: M7 (Global ACP Project Registry) - 100% complete (10/10 tasks)

### Fixed

- Manifest tracking: `design` directory now correctly maps to `designs` manifest key (was causing empty arrays for all installed files)
- Manifest template missing `scripts` and `files` arrays — installed scripts were never recorded

Closes #6

## [4.2.2] - 2026-02-27

### Fixed

- `local` keyword used outside function in `acp.package-install.sh` line 276, causing all package installs to fail with `local: can only be used in a function` when `set -e` is enabled
- Closes #5

## [4.2.1] - 2026-02-26

### Added

**Critical Rule**: Never Force-Add Gitignored Files
- Added new critical rule to AGENT.md prohibiting use of `git add -f`
- Agents must never attempt to override `.gitignore` rules
- Gitignored files should be acknowledged and skipped
- Rationale: Prevents security issues (exposing secrets), repository bloat (build artifacts), and merge conflicts (local configs)

**@git.commit Enhancement**: Gitignore Handling
- Updated Step 7 "Intelligently Stage Changes" with gitignore handling
- Added explicit instructions to skip gitignored files
- Added "Gitignore Handling" subsection with DO/DON'T examples
- Clarified that `git add -f` should never be used

**Impact**: All future agents will respect `.gitignore` rules and never force-add gitignored files, preventing common anti-patterns in version control.

## [4.2.0] - 2026-02-26

### Added

**New Command**: `@acp.projects-sync`
- Discover unregistered ACP projects in `~/.acp/projects/` directory
- Automatically detect projects with `agent/progress.yaml` file
- Skip already-registered projects with clear indicators
- Prompt user for each unregistered project found
- Extract metadata from `progress.yaml` (type, description)
- Register selected projects with timestamps
- Display summary statistics (projects found, newly registered)
- Handle edge cases (empty directory, non-ACP directories, malformed YAML)
- Auto-initialize registry if needed
- Interactive prompts with Y/n confirmation

**Use Cases**:
- Migrate existing projects to registry system
- Discover manually created projects
- Organize all ACP projects in one registry
- Bulk registration of multiple projects

**Implementation**:
- Script: `agent/scripts/acp.projects-sync.sh` (105 lines)
- Documentation: `agent/commands/acp.projects-sync.md` (377 lines)
- Tests: `e2e/acp.projects-sync.test.sh` (8 scenarios, 35 assertions)

**Milestone Progress**: M7 (Global ACP Project Registry) - 70% complete (7/10 tasks)

## [4.1.1] - 2026-02-25

### Changed

**Task Structure Documentation**:
- Updated AGENT.md directory structure to show milestone subdirectories as standard
- Updated task structure: `agent/tasks/milestone-{N}-{title}/task-{M}-{name}.md` (standard)
- Added unassigned directory: `agent/tasks/unassigned/task-{M}-{name}.md` (tasks without milestone)
- Noted legacy flat structure: `agent/tasks/task-{N}-{name}.md` (older tasks)
- Updated progress.yaml example to show subdirectory file paths
- Updated `@acp.task-create` command to use milestone subdirectories
- Added note about older tasks using flat structure for historical reasons

**Impact**: Documentation now accurately reflects the current task organization structure used in Milestones 6-8.

## [4.1.0] - 2026-02-25

### Added

**New Command**: `@acp.clarification-create`
- Create structured clarification documents from file input or chat
- Automatic clarification numbering (finds next available number)
- Accepts file path or interactive chat input
- Generates questions organized into Items > Questions > Bullet points
- Follows clarification template structure
- Includes response markers (`>`) for inline user answers
- Supports `--file`, `--title`, and `--auto` arguments
- Can analyze existing files (drafts, designs) to identify gaps
- Interactive mode for chat-based question generation

**Use Cases**:
- Gather detailed requirements for ambiguous specifications
- Analyze draft files before converting to formal documents
- Create structured question documents for stakeholder input
- Clarify design decisions and implementation details

## [4.0.0] - 2026-02-25

### Changed

**BREAKING: AGENT.md Best Practices Consolidation**
- Consolidated all best practices into single section with 3-level hierarchy (## > ### > ####)
- Removed duplicate "For Adding New Features" section (was in 2 locations)
- Moved orphaned subsections (Documentation, Organization, Progress Tracking, Quality) into Best Practices
- Restructured "Best Practices for Agents" from numbered list to hierarchical categories
- Updated table of contents with expanded Best Practices subcategories
- Added 4 strategic cross-references linking workflows to best practices

**Best Practices Structure**:
- Critical Rules (5 practices): Never reject requests, update CHANGELOG, no secrets, respect edits, respect re-execution
- Workflow Best Practices (8 practices): Read first, document, verify, be explicit, organize, track progress, inline feedback, format commands
- Documentation Best Practices (4 practices): Write for agents, focus, link, update
- Organization Best Practices (3 practices): Naming, structure, DRY
- Progress Tracking Best Practices (3 practices): Update frequently, be objective, look forward/back
- Quality Best Practices (3 practices): Verification, patterns, refine

**Entity Creation Simplification**:
- Replaced detailed creation instructions with `@acp.{entity}-create` command references
- Removed step-by-step guides, template copying examples, and manual file creation steps
- Simplified to: "Invoke [`@acp.{entity}-create`](agent/commands/acp.{entity}-create.md) and follow directives"
- Applies to: design documents, tasks, patterns, commands

### Added

**New Best Practice**: Format Commands for User Execution
- Chain commands with `&& \` for dependent execution
- Chain commands with `;` for independent execution
- Don't include `#` comment lines in command blocks
- Don't include EOF newlines in command blocks
- Ensures copy-paste friendliness for users

**Command Version Updates**:
- `@git.commit` bumped to v2.0.0 with version history section documenting AGENT.md restructuring impact

### Fixed

**Documentation Clarity**:
- Eliminated ~15% duplication by consolidating scattered best practices
- Improved navigation with hierarchical structure and cross-references
- Single source of truth for all agent behavior guidelines

**Impact**: This restructuring may affect how agents interpret and apply ACP methodology. The new hierarchical organization provides clearer categorization but represents a significant change to the documentation structure that agents rely on.

## [3.14.1] - 2026-02-25

### Fixed

**Script Installation Bugs** (Task 69):
- Fixed argument parsing bug where `-y` flag was collected as filename in `--commands`, `--patterns`, and `--designs` flags
- Fixed `get_file_version()` returning exit code 1 when file has no version, causing script to exit with `set -e`
- Fixed `add_file_to_manifest()` causing loop to exit early when manifest operations failed
- Fixed `should_install_file()` grep commands failing with `set -e` when no matches found
- Script installation loop now processes all scripts correctly (was stopping after first script)
- Added error handling to `add_file_to_manifest` calls to prevent loop breakage
- All E2E tests now passing (28/28 assertions, 100% pass rate)

**Installation Script Improvements**:
- Argument parsing now explicitly checks for known flags instead of using generic `^-` regex
- Error handling in script installation loop prevents premature exit
- Graceful degradation when manifest operations fail (warns but continues)
- Added `|| true` to grep commands in `should_install_file()` to handle no-match cases

### Changed

**Error Handling**:
- `get_file_version()` now returns exit code 0 even when package.yaml missing
- Script installation continues even if manifest update fails (with warning)
- More robust error handling throughout installation pipeline

## [3.14.0] - 2026-02-24

### Added

**Script-Command Binding System** (Milestone 3 - Tasks 65-68):
- Added `scripts` field to package.yaml schema (REQUIRED for command entries)
- Commands now declare script dependencies in frontmatter (`**Scripts**:` field)
- Dual declaration system: frontmatter + package.yaml (validated for consistency)
- Selective script installation based on installed commands
- Reference counting for shared utilities (acp.common.sh, acp.yaml-parser.sh)
- Scripts only installed when their commands are installed
- Experimental filtering applies to scripts (respects `--experimental` flag)
- Added `validate_script_dependencies()` to `acp.package-validate.sh`
- Validation ensures frontmatter matches package.yaml scripts arrays
- Validation verifies all declared scripts exist in scripts section
- Created `package.yaml` for ACP core with complete script declarations
- Added **Scripts**: field to all 30 ACP commands (14 with scripts, 16 without)

**Installation Enhancements**:
- Updated `acp.package-install.sh` with selective script installation logic
- Updated `acp.install.sh` with selective installation for ACP core
- Scripts collected from package.yaml for each installed command
- Deduplication ensures shared utilities installed once
- Backward compatibility maintained (installs all if no package.yaml)

**Template Updates**:
- Updated `command.template.md` with **Scripts**: field and documentation
- Updated `package.template.yaml` with scripts array examples
- Updated `package.schema.yaml` with required scripts field definition

### Changed

**Installation Behavior**:
- Scripts no longer installed indiscriminately
- Only scripts needed by installed commands are copied
- Experimental commands don't install their scripts (unless `--experimental` used)
- Cleaner installations with no unused script files

**Validation**:
- Package validation now checks script-command binding consistency
- Clear error messages for missing or mismatched script declarations
- Fixable suggestions provided for common issues

### Fixed

**Script Installation**:
- Fixed script clutter from unused files in experimental packages
- Fixed scripts being installed even when commands were skipped
- Fixed lack of dependency tracking between commands and scripts

## [3.13.0] - 2026-02-24

### Added

**Project Registry Commands** (Milestone 7 - Tasks 53-54):
- Added `@acp.project-set` command for seamless context switching between projects
- Command updates `current_project` in `~/.acp/projects.yaml` registry
- Command updates `last_accessed` timestamp for project tracking
- Command changes working directory to project path (interactive mode)
- Command validates project exists in registry and directory exists on filesystem
- Comprehensive error messages with helpful suggestions and available project lists
- Tilde (`~`) expansion support in project paths
- Created `agent/commands/acp.project-set.md` (command documentation)
- Created `agent/scripts/acp.project-set.sh` (context switching script)
- Created `e2e/acp.project-set.test.sh` (8 tests, 29 assertions, 100% passing)

**Test Utilities**:
- Added `assert_not_contains()` function to `tests/common.sh` for negative assertions

### Fixed

**YAML Parser Enhancements** (Task 53):
- Fixed `set -euo pipefail` compatibility in `agent/scripts/acp.common.sh` (line 69)
- Fixed `set -euo pipefail` compatibility in `agent/scripts/acp.yaml-parser.sh` (lines 12, 817)
- Fixed `yaml_query()` to return children keys for map/array nodes (previously returned empty)
- Map/array nodes now return YAML-formatted children list (e.g., "project-1:\nproject-2:\n")
- Scalar values continue to return normally

### Changed

**Project Registry Progress**:
- Milestone 7: 22% → 33% complete (3/9 tasks done)
- Task 54 completed with full E2E test coverage

## [3.12.0] - 2026-02-23

### Added

**Experimental Features System** (Milestone 8):
- Added `experimental` field to package.yaml schema for marking experimental features
- Added `--experimental` flag to `@acp.package-install` for opt-in installation
- Experimental features require explicit opt-in during installation
- Once installed, experimental features update normally (no flag required)
- Validation checks consistency between package.yaml and file metadata
- Graduated features (experimental → stable) automatically detected during updates
- Clear visual indicators for experimental features (⊘ skipped, ⚠ experimental, 🎓 graduated)

**Schema Enhancement**:
- `agent/schemas/package.schema.yaml` now supports optional `experimental: true` field in all content types
- Field is optional and defaults to false (backward compatible)

**Validation**:
- Added `validate_experimental_consistency()` to `agent/scripts/acp.package-validate.sh`
- Checks if `experimental: true` in package.yaml → file MUST have `**Status**: Experimental`
- Checks if file has `**Status**: Experimental` → package.yaml MUST have `experimental: true`
- Provides fixable suggestions for inconsistencies

**Installation**:
- Added `should_install_file()` filtering function to `agent/scripts/acp.package-install.sh`
- Without `--experimental`: Skips features marked `experimental: true`
- With `--experimental`: Installs all features including experimental
- Manifest tracks experimental status for update handling

**Updates**:
- Added `is_experimental_installed()` to `agent/scripts/acp.package-update.sh`
- Added `check_graduation()` to detect experimental → stable transitions
- Already-installed experimental features update normally
- New experimental features are skipped (use --experimental with install)
- Graduated features automatically marked as stable

**Documentation**:
- Created `agent/design/local.experimental-features-system.md` (comprehensive design)
- Created `agent/milestones/milestone-8-experimental-features.md`
- Created 4 task documents for implementation
- Updated `@acp.package-install` command documentation with --experimental flag
- Updated `@acp.package-update` command documentation with experimental behavior
- Updated `@acp.package-validate` command documentation with consistency checks
- Added "Experimental Features" section to AGENT.md
- Added experimental features examples to README.md

### Changed

**Installation Behavior**:
- Default installation now skips experimental features
- `--experimental` flag required to install experimental features
- Clear visual indicators for skipped and experimental files

**Update Behavior**:
- Smart handling based on installation status
- Installed experimental features update without flag
- New experimental features require explicit installation

**Manifest Structure**:
- Files can now have `experimental: true` field
- Enables tracking of experimental status across updates

## [3.11.0] - 2026-02-23

### Added

**YAML Parser Enhancement**:
- `yaml_set()` now automatically creates missing intermediate map nodes
- Added `create_node_and_link()` function for auto-creation with parent linking
- Added `YAML_PARSER_LOADED` guard to prevent variable resets on re-sourcing
- Enhanced `source_yaml_parser()` to check if already loaded

**Project Registry Infrastructure** (Task 52):
- Created `agent/schemas/projects.schema.yaml` - Complete registry schema
- Created `agent/projects.template.yaml` - Registry template
- Added 8 project registry functions to `acp.common.sh`:
  - `get_projects_registry_path()` - Get registry file path
  - `projects_registry_exists()` - Check if registry exists
  - `init_projects_registry()` - Initialize registry
  - `register_project()` - Add project to registry (uses yaml_write!)
  - `project_exists()` - Check if project registered
  - `get_current_project()` - Get active project name
  - `get_current_project_path()` - Get active project path
- Updated `init_global_acp()` to auto-initialize projects registry
- Created `tests/acp.project-registry.test.sh` - 5/5 tests passing (100%)
- Added `assert_file_exists()` to `tests/common.sh`

### Fixed

**YAML Parser**:
- Fixed duplicate children bug in AST (separated `create_node` from `add_child`)
- Fixed `create_node()` to not auto-link (backward compatibility)
- `yaml_set()` now works for creating nested structures, not just updates

### Changed

**Project Registry**:
- Registry template uses clean empty map syntax (`projects:` not `projects: {}`)
- `register_project()` now uses yaml_write instead of sed manipulation

## [3.10.1] - 2026-02-22

### Fixed

**Documentation**:
- Fixed `@acp.package-install` command documentation to match actual script implementation
- Script requires `--repo` flag (not positional argument)
- Updated all examples to use correct syntax: `--repo <url>`
- Added global installation example with `--global --repo <url>`
- Clarified that scripts are installed and made executable automatically

## [3.10.0] - 2026-02-22

### Added

**New Command**:
- Created `@acp.project-create` command for bootstrapping generic ACP projects
- Creates projects without package.yaml (not for distribution)
- No release branches or pre-commit hooks (simpler than packages)
- Always uses `local` namespace (not configurable)
- Collects project metadata (name, description, type, author, license)
- Installs full ACP in new directory
- Creates project-focused README.md with development section
- Creates appropriate .gitignore for project type
- Initializes git repository with initial commit
- Creates progress.yaml with project metadata
- Comprehensive documentation with comparison to `@acp.package-create`

### Changed

**Progress Tracking**:
- Completed Task 49: @acp.project-create Command (1 hour)
- Milestone 5: 86% → 100% complete (7/7 tasks) 🎉
- Updated current_milestone: M5 → M6 (ready for Preferences System)

## [3.9.3] - 2026-02-22

### Added

**Task Planning**:
- Created Task 51: Pattern Reading in Commands for context awareness
- Updates 6 commands to read `agent/patterns/` during execution
- Intelligent pattern selection based on context
- Ensures agents understand project patterns before making decisions
- Estimated 2-3 hours implementation time

### Changed

**Progress Tracking**:
- Updated Milestone 2 tasks_total: 3 → 4 (added task-51)
- Deleted 3 draft files (acp-project-create, acp-search-enhancement, read-patterns-enhancement)

## [3.9.2] - 2026-02-22

### Fixed

**Package Search**:
- Fixed `@acp.package-search` to filter by `topic:acp-package` by default
- Default search now returns 3 actual ACP packages (not 11,356 irrelevant repos)
- Search query construction: `topic:acp-package` (default) or `{query}+topic:acp-package` (with query)
- Updated command documentation to explain topic filter requirement
- Package discovery now requires `acp-package` topic on GitHub repository

### Changed

**Progress Tracking**:
- Completed Task 50: Package Search Default Topic Filter (0.5 hours)
- Milestone 3: 90% → 100% complete (10/10 tasks)

## [3.9.1] - 2026-02-22

### Added

**Task Planning**:
- Created Task 49: `@acp.project-create` command for bootstrapping generic ACP projects
- Task document includes comparison with `@acp.package-create` (packages vs projects)
- Projects use `local` namespace (not configurable, unlike packages)
- Projects don't include package.yaml, release branches, or pre-commit hooks
- Estimated 3-4 hours implementation time
- Created Task 50: Package Search Default Topic Filter (1 hour)

### Changed

**Progress Tracking**:
- Updated Milestone 5 tasks_total: 6 → 7 (added task-49)
- Updated Milestone 3 tasks_total: 9 → 10 (added task-50)
- Added initialization entry to recent_work (context loaded via `@acp.init`)

## [3.9.0] - 2026-02-22

### Added

**Global Package Installation System**:
- Global package installation to `~/.acp/agent/` with `--global` flag
- Packages installed directly into global ACP structure (not separate packages directory)
- Global package discovery via `~/.acp/agent/manifest.yaml`
- Global infrastructure: `~/.acp/` with full ACP installation at root
- Global manifest functions in `acp.common.sh` (7 functions)
- Enhanced [`@acp.init`](agent/commands/acp.init.md) with automatic global package discovery
- Namespace precedence rules (local always overrides global)

**Global Package Commands**:
- [`@acp.package-install`](agent/commands/acp.package-install.md) supports `--global` flag
- [`@acp.package-list`](agent/commands/acp.package-list.md) supports `--global` flag
- [`@acp.package-update`](agent/commands/acp.package-update.md) supports `--global` flag
- [`@acp.package-remove`](agent/commands/acp.package-remove.md) supports `--global` flag
- [`@acp.package-info`](agent/commands/acp.package-info.md) supports `--global` flag

### Changed

- **Global installation architecture**: Packages install directly to `~/.acp/agent/` (not `~/.acp/packages/`)
- **Manifest location**: Global manifest at `~/.acp/agent/manifest.yaml` (following ACP structure)
- **AGENT.md**: Added "Global Package Discovery" section with discovery workflow, precedence rules, and examples
- **README.md**: Added "Global Package Installation" section with usage examples and use cases
- All package command documentation updated with `--global` flag examples

### Documentation

- Documented namespace precedence rules (local > global)
- Added global ACP structure diagram
- Documented when to use global vs local installation
- Added comprehensive examples for global package workflows
- Updated all package management command documentation

## [3.8.0] - 2026-02-22

### Added

**New @acp.plan Command**:
- Created `agent/commands/acp.plan.md` - Systematic milestone and task planning command
- Scans progress.yaml for undefined milestones/tasks
- Supports multiple planning workflows (design first, requirements first, chat, drafts)
- Invokes `@acp.milestone-create`, `@acp.task-create`, `@acp.design-create` as subroutines
- New task structure: `agent/tasks/milestone-{N}-{title}/task-{M}-{title}.md`
- Orphaned tasks: `agent/tasks/unassigned/task-{M}-{title}.md`
- CLI and natural language argument support
- Batch and interactive modes
- Structured draft questions for each entity type (3 questions each)
- Created `agent/clarifications/clarification-6-acp-plan-command.md` with design requirements

**Command Template Enhancement**:
- Added Arguments section to `agent/commands/command.template.md`
- Documents CLI-style and natural language arguments
- Includes argument mapping approach
- Placed before Prerequisites section
- Optional section (omit if command has no arguments)

**Command Creation Enhancement**:
- Updated `agent/commands/acp.command-create.md` to handle Arguments section
- Asks if command accepts arguments during creation
- Fills or removes Arguments section accordingly
- Ensures Arguments placed before Prerequisites

## [3.7.3] - 2026-02-22

### Added

**E2E Test Suite for Package Update Command**:
- Created `e2e/acp.package-update.test.sh` with 13 comprehensive test cases
- Tests all update scenarios: empty manifest, non-existent package, flags (--check, --skip-modified, --force, -y)
- Tests specific package updates and manifest validation
- All 13 assertions passing (100%)

**Test Utilities Enhancement**:
- Added `assert_not_equals()` function to `tests/common.sh`
- Enables negative assertions in test suites
- Used across all E2E tests for error case validation

### Fixed

**Critical Bug in Package Update Script**:
- Fixed function ordering in `agent/scripts/acp.package-update.sh`
- Functions `check_package_for_updates()` and `update_package()` were defined after use (lines 129, 188)
- Moved function definitions before main script logic
- Script now executes correctly without "command not found" errors

**Test Coverage Complete**:
- All 5 package management commands now have E2E tests
- Total: 52/52 assertions passing (100%)
- Commands tested: list (10), info (13), remove (8), search (8), update (13)

## [3.7.2] - 2026-02-22

### Changed

**Package Browser UI Improvements**:
- Reduced vertical spacing throughout for better screen efficiency
- Smaller header (3em → 2em title, 1.2em → 1em subtitle)
- Compact search box (30px → 15px padding)
- Tighter package cards (20px → 12px padding, 20px → 12px margins)
- Smaller fonts (package name 1.5em → 1.2em, meta 0.9em → 0.85em)
- More packages visible per screen (~30% space reduction)
- Maintained readability while improving information density

## [3.7.1] - 2026-02-21

### Fixed

**Critical Bug Fixes in Package Management Scripts**:
- Fixed `(( VAR++ ))` arithmetic expressions causing early exit with `set -e`
  - `acp.package-list.sh` - 2 occurrences fixed
  - `acp.package-search.sh` - 1 occurrence fixed
  - `acp.package-remove.sh` - 8 occurrences fixed
- Fixed file counting in `acp.package-remove.sh` (grep -c returning multiple lines)
- Fixed JSON parsing in `acp.package-search.sh` (handle spaces in JSON)
- Disabled `set -e` in `acp.package-search.sh` (incompatible with while-read subshell)

**Package Search Now Working**:
- Search successfully finds and displays ACP packages
- Tested with real repositories (acp-tanstack-cloudflare, acp-mcp-auth-server-base)
- All search modes working (keyword, topic, user, limit)

### Added

**E2E Test Infrastructure**:
- Created `e2e/` directory for end-to-end tests
- Created `e2e/acp.package-list.test.sh` (10/10 assertions passing)
- Created `e2e/acp.package-info.test.sh` (13/13 assertions passing)
- Created `e2e/acp.package-remove.test.sh` (8/8 assertions passing)
- Created `e2e/acp.package-search.test.sh` (8/8 assertions passing)
- Enhanced `tests/common.sh` with test helper functions
- Total: 39/39 assertions passing (100%)

## [3.7.0] - 2026-02-21

### Changed

**YAML Parser Migration**:
- All scripts now use `acp.yaml-parser.sh` (AST-based parser) via `source_yaml_parser()`
- 10-100x performance improvement for multiple queries (parse once, query many)
- Generic path expressions supported: `.path.to.field`, `.array[0].field`
- Backward-compatible API maintained: `yaml_get()`, `yaml_get_nested()`, `yaml_has_key()`, `yaml_get_array()`
- Updated documentation references from `acp.yaml.sh` to `acp.yaml-parser.sh`

### Removed

- `acp.yaml.sh` - Replaced by `acp.yaml-parser.sh`
  - Old parser removed (migration complete)
  - All functionality now provided by `acp.yaml-parser.sh`
  - Test file `tests/acp.yaml.test.sh` also removed

## [3.6.3] - 2026-02-21

### Fixed
- Renamed `agent/patterns/typescript/library-services.md` to `local.library-services.md` for namespace consistency
- All pattern files now follow proper namespace conventions

## [3.6.2] - 2026-02-21

### Added
- Package creation now includes local-only directories: `agent/clarifications/` and `agent/feedback/`
- Created `.gitkeep` files in local directories to track structure while keeping content local
- Copied clarification template to new packages for easy use
- Added comprehensive documentation in package README about local development directories
- Updated `.gitignore` to exclude content files while tracking `.gitkeep` and templates

### Changed
- Package `.gitignore` now explicitly documents local-only pattern (clarifications, feedback, reports)
- Improved consistency with existing reports directory pattern

## [3.6.1] - 2026-02-21

### Changed
- Package creation script now includes ACP attribution link in generated README files
- Generated package READMEs now have blockquote with link to Agent Context Protocol repository

### Fixed
- Repository URL validation: automatically appends `.git` suffix if missing
- ACP version constraint in package.yaml: removed quotes (was `">=2.8.0"`, now `>=2.8.0`)
- Bootstrap script location: moved from `scripts/` to `agent/scripts/` for consistency

## [3.6.0] - 2026-02-21

### Added

**YAML Parser Modification Operations**:
- Added `yaml_array_append()` - Append scalar values to arrays
- Added `yaml_array_append_object()` - Append objects to arrays
- Added `yaml_object_set()` - Set fields on objects
- Full modification support: parse → modify → append → write cycle
- Auto-converts empty maps to arrays for seamless array operations
- Proper serialization with correct indentation for all structures
- Objects in arrays serialize with dash prefix on first field

**Manifest Integration**:
- `add_file_to_manifest()` now uses YAML parser exclusively (no awk!)
- All installed files tracked with complete metadata
- Verified with real package installations

**Parser Enhancements**:
- Changed shebang to `#!/bin/bash` for BASH_SOURCE compatibility
- Fixed root node serialization (no extra indentation)
- Fixed array item serialization (proper spacing: `-  value`)
- Fixed object-in-array serialization (dash prefix for first field)
- Parent type tracking for context-aware serialization

**Test Coverage**:
- Added 10+ modification operation tests to test suite
- All tests consolidated in single file
- 50+ total tests, 100% passing

**Known Limitations**:
- Inline empty arrays (`patterns: []`) parse as scalars
- Workaround: sed converts `[]` to proper format before parsing
- This is acceptable for ACP's use cases

**Impact**: YAML parser now supports full CRUD operations on complex structures using the parser itself

## [3.5.2] - 2026-02-21

### Fixed

**YAML Parser Integration Bug**:
- Fixed `yaml_has_key()` to check node existence instead of value presence
- Added `yaml_get_array()` function for array element counting
- Resolves BR-2026-02-21-008: validation script now correctly reads package.yaml contents
- Validation now shows "All X files in contents exist" instead of "All 0 files"
- Package files are now properly validated for namespace consistency
- Bug was caused by `yaml_has_key()` returning false for keys with no direct value (arrays, maps)

**Impact**: Package validation now works correctly in all contexts

## [3.5.1] - 2026-02-21

### Fixed

**YAML Validation Integration**:
- Updated `agent/scripts/acp.yaml-validate.sh` to use new generic YAML parser
- Added `yaml_has_key()` function to `acp.yaml-parser.sh` for backward compatibility
- Fixed sourcing behavior to prevent main section execution when sourced
- All validation functions now use AST-based parser for better performance
- Zero breaking changes - drop-in replacement maintains full compatibility

## [3.5.0] - 2026-02-21

### Added

**Generic YAML Parser with AST**:
- New `agent/scripts/acp.yaml-parser.sh` - Pure POSIX shell YAML parser with Abstract Syntax Tree
- Parse once, query many times with efficient AST caching
- Generic path expressions: `.path.to.field`, `.array[0].field`, `.nested.array[0].field`
- Full API: `yaml_parse()`, `yaml_query()`, `yaml_set()`, `yaml_write()`
- Backward compatible with existing `yaml_get()` and `yaml_get_nested()` functions
- Zero external dependencies (no yq, jq, or other tools required)
- Comprehensive test suite with 30+ tests in `tests/acp.yaml-parser.test.sh`
- Reusable test utilities in `tests/common.sh`
- Complete design documentation in `agent/design/yaml-parser-design.md`
- Handles simple maps, nested objects, arrays, object arrays, and complex structures
- Production-ready implementation suitable for extraction as standalone project (`yaml-sh`)

**Benefits**:
- 10-100x faster for multiple queries on same file (parse once, query many)
- Works for ANY YAML structure without hard-coded patterns
- Enables future enhancements (filters, wildcards, YAML 1.2 features)
- Provides foundation for more sophisticated YAML operations

**Completed**:
- Task 34: Build Generic YAML Parser with AST (estimated 80-160 hours, delivered in one session)

## [3.4.3] - 2026-02-21

### Fixed

**Template Distribution**:
- `acp.install.sh` now copies `package.template.yaml`
- `acp.version-update.sh` now copies `package.template.yaml` and `manifest.template.yaml`
- Ensures all template files are distributed correctly during installation and updates

## [3.4.2] - 2026-02-21

### Fixed

**Template Distribution** (partial):
- Initial fix for template distribution

## [3.4.1] - 2026-02-21

### Changed

**Package File Validation Strictness**:
- Changed from warning to error for package files not in contents
- Files matching package namespace MUST be in package.yaml contents
- Prevents accidental omissions
- Provides clear guidance on how to fix

## [3.4.0] - 2026-02-21

### Added

**Smart Package File Detection in Validation**:
- `@acp.package-validate` detects package files not in contents
- Files matching package namespace but excluded from package.yaml
- Shows error with list of affected files
- Provides guidance on how to add them (@acp.command-create, @acp.pattern-create)
- Helps catch forgotten files

## [3.3.2] - 2026-02-21

### Added

**YAML Parser Test Suite**:
- Created `tests/acp.yaml.spec.sh` with comprehensive test coverage
- 14 tests validating parser functionality (all passing)
- Tests basic operations, simple arrays, object arrays with indexing
- Validates `yaml_get_nested()` array indexing feature
- Tests complex nested structures (manifest.yaml format)
- Prevents regressions in parser functionality

## [3.3.1] - 2026-02-21

### Fixed

**ACP Core Tracking in manifest.yaml**:
- `acp.install.sh` now creates `manifest.yaml` with acp-core package entry
- Tracks all installed core commands, patterns, and designs
- `acp.version-update.sh` updates acp-core version in manifest
- `acp.package-validate.sh` checks manifest before warning about unlisted files
- No more false warnings about core commands

## [3.3.0] - 2026-02-21

### Added

**Enhanced YAML Parser for Nested Objects**:
- Added `yaml_get_nested()` function to `acp.yaml.sh` for array indexing support
- Supports syntax: `contents.commands[0].name`
- POSIX-compliant implementation using awk
- Enables reading nested objects in YAML arrays
- Generic solution for all nested object access

**Package Template**:
- Created `agent/package.template.yaml` showing correct package.yaml format
- Documents object format for contents arrays: `{name: "file.md"}`
- Provides single source of truth for package creators

### Changed

**Package Validation Improvements**:
- Updated `acp.package-validate.sh` to use `yaml_get_nested()`
- File existence check now correctly reads package.yaml contents
- Namespace validation now correctly reads package.yaml contents
- Fixed "All 0 files in contents exist" error

**Schema Documentation**:
- Updated `agent/schemas/package.schema.yaml` to document object format
- Contents arrays must contain objects with `name` field
- Enables version tracking per file (extensible for future)

### Fixed

- Package validation can now read files from package.yaml contents correctly
- No more false "unlisted files" warnings
- Object format works consistently across all scripts

## [3.2.1] - 2026-02-21

### Fixed

**Package .gitignore Correction**:
- Removed `agent/progress.yaml` and `agent/manifest.yaml` from package .gitignore
- Both files should be committed in package repositories (just like in ACP projects)
- manifest.yaml tracks installed dependencies for package development
- progress.yaml tracks package development progress
- All ACP files should be version controlled in packages

## [3.2.0] - 2026-02-21

### Added

**Progress Tracking for Package Repositories**:
- `@acp.package-create` now creates `agent/progress.yaml` for package development tracking
- Minimal structure with no predefined milestones or tasks
- Enables full ACP workflow in package repositories (@acp.init, @acp.proceed, @acp.status)
- Package developers can create milestones and tasks as needed
- All ACP files are version controlled (manifest.yaml and progress.yaml committed)

**Benefits**:
- Consistent experience between projects and packages
- Package developers can use standard ACP commands
- Track package development progress
- Plan features with milestones and tasks

## [3.1.1] - 2026-02-21

### Fixed

**Package Validation Bug Fix**:
- Fixed `@acp.package-validate` namespace validation to skip files not in `package.yaml` contents
- Validation now only checks files listed in package contents
- Files not in contents (e.g., installed dependencies) are skipped with informational message
- Fixes false positive namespace violations for package developers
- manifest.yaml already acts as dev dependency tracker (no new fields needed)

**Impact**:
- Package developers can install dependencies (like `git.commit.md`) without validation errors
- Validation correctly focuses only on package content files
- Installation system already worked correctly (only installs contents)

## [3.1.0] - 2026-02-21

### Added

**Bootstrap Installation Feature**:
- `@acp.package-create` now generates `scripts/bootstrap.sh` for one-command installation
- Bootstrap script installs ACP (if needed) and the package in a single command
- README.md template includes "Quick Start (Bootstrap New Project)" section
- Users can run: `curl -fsSL {repo}/raw/{branch}/scripts/bootstrap.sh | bash`
- Perfect for bootstrapping new projects with specific ACP packages
- Automatic generation for every package created

**Benefits**:
- Simplifies onboarding for new users
- One-command setup for ACP + package
- Works whether ACP is installed or not
- Prominently featured in package README.md

## [3.0.0] - 2026-02-21

### Summary

Major release consolidating 33 commits and completing Milestone 4 (ACP Package Development System). This release represents a complete package development workflow from creation to publishing, with breaking changes to `@acp.package-create`.

### Added

**Milestone 4: ACP Package Development System (Complete)**
- Complete package development workflow operational
- 11 tasks completed across 6 implementation phases
- 33 commits since version 2.0.0

**Entity Creation Commands**:
- `@acp.pattern-create` - Create patterns with namespace and draft support
- `@acp.command-create` - Create commands with automatic package.yaml updates
- `@acp.design-create` - Create design documents with namespace enforcement
- `@acp.task-create` - Create tasks with milestone linking and progress updates

**Validation System**:
- `@acp.package-validate` - Comprehensive package validation with shell checks and test installation
- `@acp.validate` v2.0.0 - Enhanced with namespace validation and computer roleplay directive
- YAML schema system with pure bash validator (zero dependencies)
- Namespace consistency checking across all entity types
- Reserved namespace enforcement (acp, local, core, system, global)

**Publishing Automation**:
- `@acp.package-publish` - 13-step publishing workflow with version management
- Automatic version bump detection from Conventional Commits
- CHANGELOG generation support (LLM-based, shell placeholder)
- Branch validation (main, master, mainline, release, custom)
- Test installation from remote after publishing

**Package Creation & Management**:
- `@acp.package-create` v2.0.0 - Complete rewrite with full ACP installation
- `@acp.package-create` v2.1.0 - Non-interactive mode with CLI arguments
- Pre-commit hook system for package.yaml validation
- Default directory: `~/.acp/projects/acp-{name}/`
- Full ACP installation (templates, scripts, schemas) in packages

**Infrastructure & Utilities**:
- YAML schema system (agent/schemas/package.schema.yaml)
- Pure bash YAML validator (acp.yaml-validate.sh) - zero dependencies
- Namespace utilities (5 functions for context-aware namespace handling)
- README update utilities (automatic content list generation from package.yaml)
- Pre-commit hook template system with automatic installation
- install_precommit_hook() function in acp.common.sh

**Documentation & Patterns**:
- TypeScript library-services pattern
- Computer roleplay directive added to command templates
- "Resume a previous session" section in README
- Critical directives about respecting user re-execution commands
- Comprehensive command documentation with examples

**Milestone 5 Planning**:
- Global Package Installation design completed
- 5 tasks created (tasks 25-29)
- Global installation to `~/.acp/packages/` with `--global` flag
- Agent discovery via `~/.acp/manifest.yaml`
- Auto-initialization design (global-acp-installation.md)
- Estimated: 9-13 hours implementation

### Changed

**BREAKING: @acp.package-create** - Complete rewrite (v1.0.0 → v2.0.0 → v2.1.0)
- Now runs `acp.install.sh` to install complete ACP structure (all templates, commands, scripts)
- Changed default directory from arbitrary location to `~/.acp/projects/acp-{name}/`
- Removed example file creation (use templates from ACP installation instead)
- Added release branch configuration (default: main)
- Added pre-commit hook installation (validates package.yaml before commits)
- Added non-interactive mode with CLI arguments (v2.1.0)
- Breaking: Old workflow no longer supported

**Package Development Workflow**:
- Packages now created with complete ACP tooling
- Full validation before publishing
- Automated version management via Conventional Commits
- Pre-commit validation hooks automatically installed

**acp.install.sh Enhancements**:
- Now copies `agent/schemas/*.yaml` files
- Now copies `agent/manifest.template.yaml`
- Ensures complete ACP installation for packages

### Fixed

- **@acp.package-create Directory Structure** - Fixed redundant nesting
  - Changed from `~/.acp/projects/{name}/acp-{name}/` to `~/.acp/projects/acp-{name}/`
  - Fixed SCRIPT_DIR to use absolute path (prevents issues after cd)
  - Fixed directory existence check (was creating before checking)
- **Documentation Formatting** - Fixed command file formatting
  - Fixed missing closing quote in computer roleplay directive
  - Fixed repository URLs in examples to include "acp-" prefix
  - Added explicit confirmation requirement before invoking installed commands

### Migration Guide

**For Package Developers**:
- **Old**: Create packages anywhere with manual setup
- **New**: Use `@acp.package-create` for full ACP installation in `~/.acp/projects/`
- **New**: Packages include pre-commit hooks for automatic validation
- **New**: Use `@acp.package-publish` for automated publishing with version management
- **New**: Use entity creation commands (@acp.pattern-create, @acp.command-create, etc.)

**For Package Users**:
- No breaking changes to package installation
- All existing `@acp.package-install` commands work as before
- New validation and publishing commands available
- New entity creation commands for package development

**Breaking Changes**:
- `@acp.package-create` workflow completely changed
- Old manual package creation workflow no longer supported
- Packages must now be created in `~/.acp/projects/` by default
- Package structure now includes full ACP installation

### Statistics

- **Commits**: 33 since version 2.0.0
- **Milestones**: 4 completed (M1-M4), 1 planned (M5)
- **Tasks**: 24 completed, 5 planned (29 total)
- **Commands**: 25 implemented
- **Scripts**: 17 in agent/scripts/
- **Overall Progress**: 86% (M1-M4 complete, M5 not started)

## [2.11.0] - 2026-02-21

### Added
- **@acp.package-create Non-Interactive Mode** - Command-line argument support
  - Added `--name`, `--description`, `--author`, `--repository` flags
  - Added `--license`, `--homepage`, `--tags`, `--branch`, `--target-dir` optional flags
  - Automatic non-interactive mode when all required args provided
  - Removed `--yes` flag (not needed with CLI args)
  - Script version: 2.0.0 → 2.1.0

### Fixed
- **@acp.package-create Directory Structure** - Fixed redundant nesting
  - Changed default from `~/.acp/projects/{name}/acp-{name}/` to `~/.acp/projects/acp-{name}/`
  - Fixed SCRIPT_DIR to use absolute path (prevents issues after cd)
  - Fixed directory existence check (was creating before checking)

### Changed
- **Test Package Created** - Successfully tested non-interactive mode
  - Created acp-test-package at `~/.acp/projects/acp-test-package/`
  - Verified full ACP installation, package.yaml, git initialization
  - Pre-commit hook installed and working

## [2.10.1] - 2026-02-21

### Changed
- **Milestone 5 Planning** - Global Package Installation design completed
  - Revised design document based on user clarification feedback
  - Removed symlink-based architecture in favor of simple agent discovery
  - Added `@acp.init` enhancement to automatically read and report global packages
  - Created clarification document with 25+ architecture questions answered
  - Updated milestone document with 4 implementation phases
  - Global packages install to `~/.acp/packages/` only (no symlinks)
  - Agents discover packages via `~/.acp/manifest.yaml`
  - Local packages always take precedence over global packages

## [2.10.0] - 2026-02-21

### Added
- **Milestone 4 Complete** - ACP Package Development System fully operational
  - All 11 tasks completed (100%)
  - Complete package development workflow from creation to publishing
  - Entity creation commands, validation system, publishing automation
  - Pre-commit hook system documented and integrated

### Changed
- **Task 24: Pre-Commit Hook System** - Documentation completed
  - Hook implementation already complete from Task 23
  - Comprehensive documentation added to task document
  - Verification checklist completed
  - Implementation notes and testing results documented
- **Milestone 4 Status** - Marked as completed
  - Progress: 91% → 100%
  - All 6 phases complete (Infrastructure, Entity Creation, Validation, Publishing, Package Creation, Hooks)
  - Completed date: 2026-02-21
- **Project Progress** - Overall progress: 92% → 100%
  - All 4 milestones complete
  - 24/24 tasks completed
  - Ready for Milestone 5 planning

## [2.9.1] - 2026-02-21

### Fixed
- Documentation formatting in command files
  - Fixed missing closing quote in computer roleplay directive (acp.proceed.md, command.template.md, git.commit.md)
  - Added computer roleplay directive to acp.package-install.md and acp.report.md
  - Fixed repository URLs in examples to include "acp-" prefix (acp.package-install.md)
  - Added explicit confirmation requirement before invoking installed commands (acp.package-install.md)

## [2.9.0] - 2026-02-21

### Changed
- **@acp.package-create Command** - Complete rewrite with full ACP installation
  - Now runs `acp.install.sh` to install complete ACP structure (all templates, commands, scripts)
  - Collects release branch configuration (default: main)
  - Default directory changed to `~/.acp/packages/{package-name}` or `$HOME/.acp/packages/{package-name}`
  - Installs pre-commit hook automatically (validates package.yaml before commits)
  - Removed example file creation (use templates from ACP installation instead)
  - Creates package.yaml with `release.branch` field
  - Enhanced next steps with entity creation commands
  - Version bump: 1.0.0 → 2.0.0 (breaking - complete rewrite)
- **acp.install.sh** - Enhanced to copy schemas directory and manifest template
  - Now copies `agent/schemas/*.yaml` files
  - Now copies `agent/manifest.template.yaml`
  - Ensures complete ACP installation for packages

### Added
- **install_precommit_hook()** - New function in `acp.common.sh`
  - Installs pre-commit hook for package validation
  - Validates package.yaml before allowing commits
  - Gracefully handles missing validation scripts
  - Documents future enhancements (namespace checking, CHANGELOG validation)

## [2.8.0] - 2026-02-21

### Added
- **@acp.package-publish Command** - Automated package publishing workflow
  - 11-step publishing workflow from validation to testing
  - Delegates to @git.commit for version/CHANGELOG management (avoids logic duplication)
  - Automatic version bump detection from Conventional Commits
  - Analyzes commits for breaking changes, features, and fixes
  - User confirmation for version number (Y/n/custom)
  - Branch validation (main, master, mainline, release, custom)
  - Remote status checking (prevents overwriting)
  - Git tag creation (vX.Y.Z format)
  - Push to remote (commits and tags)
  - Post-publish test installation from remote
  - Comprehensive error handling at each step
  - Shell script: `agent/scripts/acp.package-publish.sh`

### Changed
- Milestone 4 progress: 73% → 82% (9/11 tasks complete)
- Phase 4 (Publishing) complete

## [2.7.0] - 2026-02-21

### Changed
- **Enhanced @acp.validate Command** - Added strict namespace validation
  - STRICT enforcement: All patterns/commands/designs MUST have namespace prefix
  - In packages: Use package namespace (e.g., firebase.pattern.md)
  - In projects: Use local namespace (e.g., local.pattern.md)
  - ERROR for files missing namespace prefix (not just warning)
  - Exception: Template files (*.template.md) don't need namespace
  - Added Step 8: Validate Namespace Conventions
  - Context-aware validation (package vs project detection)
  - Checks for reserved namespace violations (acp, local, core, system, global)
  - Updated verification checklist with namespace checks
  - Updated example output with namespace validation section
  - Added computer roleplay directive to command header
  - Version bump: 1.0.0 → 2.0.0 (breaking - new strict validation)
- Milestone 4 progress: 64% → 73% (8/11 tasks complete)
- Phase 3 (Validation) complete

## [2.6.0] - 2026-02-21

### Changed
- **Enhanced @acp.validate Command** - Added namespace validation and reserved name checking
  - Added Step 8: Validate Namespace Conventions
  - Context-aware validation (package vs project detection)
  - Validates command/pattern/design filenames use correct namespace
  - Checks for reserved namespace violations (acp, local, core, system, global)
  - Updated verification checklist with namespace checks
  - Updated example output with namespace validation section
  - Added computer roleplay directive to command header
  - Version bump: 1.0.0 → 2.0.0 (breaking - new validation checks)
- Milestone 4 progress: 64% → 73% (8/11 tasks complete)
- Phase 3 (Validation) complete

## [2.5.0] - 2026-02-21

### Added
- **@acp.package-validate Command** - Comprehensive package validation system
  - Shell-based validation (YAML structure, file existence, namespace consistency, git setup, README)
  - Test installation to temporary directory with automatic cleanup
  - Remote repository availability checking via git ls-remote
  - Unlisted files detection (finds files not in package.yaml)
  - Validation score calculation and comprehensive reporting
  - Fixable issues identification for LLM auto-fix
  - Command documentation with examples and troubleshooting
  - Shell script: `agent/scripts/acp.package-validate.sh`

### Changed
- Milestone 4 progress: 55% → 64% (7/11 tasks complete)
- Phase 3 (Validation) started with Task 20 complete

## [2.4.0] - 2026-02-21

### Changed
- Enhanced `agent/commands/command.template.md` with computer roleplay directive
  - Clarifies that agent should execute command directives as instructions
  - Improves command execution clarity and consistency

## [2.3.0] - 2026-02-21

### Added
- **@acp.command-create Command** - LLM-based command creation
  - Context-aware namespace detection
  - Collects command-specific fields (category, frequency)
  - Automatic package.yaml and README.md updates
  - Draft file support
- **@acp.design-create Command** - LLM-based design document creation
  - Context-aware namespace detection
  - Automatic package.yaml and README.md updates
  - Draft file support
- **Design: install-local-patterns-feature** - Proposal for --install-local flag
  - Install local namespace patterns from source repos with namespace conversion
  - Enable sharing of implementation patterns between packages

### Changed
- Milestone 4 progress: 55% (6/11 tasks complete)
- Phase 2 (Entity Creation) complete - all 3 entity creation commands implemented

## [2.2.3] - 2026-02-21

### Added
- **Pattern: library-services** - Service layer, database layer, and API client layer architecture
  - Three-layer architecture for TypeScript libraries
  - Complete implementation examples for each layer
  - Dependency injection pattern
  - Testing examples with mocks
  - Benefits, trade-offs, and usage guidance
  - Demonstrates @acp.pattern-create command in action

## [2.2.2] - 2026-02-20

### Added
- **@acp.pattern-create Command** - LLM-based pattern creation (no shell script needed)
  - Context-aware namespace detection
  - Chat-based information collection
  - Draft file support
  - Automatic package.yaml and README.md updates
  - Command documentation complete

### Changed
- Simplified entity creation approach: LLM handles creation directly via command directives
- Removed unnecessary shell script (agent/scripts/acp.pattern-create.sh)
- Entity creation commands are now pure LLM directives (more intelligent and flexible)

## [2.2.1] - 2026-02-20

### Added
- **Task 15: Namespace Utilities** - Context-aware namespace detection and validation
  - Added `is_acp_package()` - Detects if directory is ACP package
  - Added `infer_namespace()` - Infers namespace from package.yaml, directory name, or git remote
  - Added `validate_namespace()` - Validates format and checks reserved names (acp, local, core, system, global)
  - Added `get_namespace_for_file()` - Returns package namespace or "local" for non-packages
  - Added `validate_namespace_consistency()` - Checks for conflicts between sources
- **Task 16: README Update Utilities** - Automatic README.md content list generation
  - Added `update_readme_contents()` - Updates README from package.yaml
  - Added `generate_contents_section()` - Generates formatted markdown lists
  - Added `add_file_to_readme()` - Convenience wrapper
  - Uses HTML comment markers for section boundaries
  - Extracts file names and descriptions from package.yaml

### Changed
- Enhanced `agent/scripts/acp.common.sh` with 8 new utility functions
- Milestone 4 progress: 27% (3/11 tasks complete)

## [2.2.0] - 2026-02-20

### Added
- **Milestone 4: ACP Package Development System** - Comprehensive planning complete
  - Created design document with complete architecture and specifications
  - Created milestone document with 11 tasks across 6 phases
  - Created 11 task documents (task-14 through task-24)
  - Estimated effort: 45-58 hours over 6-8 weeks
- **Clarification System** - 4 clarification documents with 214 questions answered
  - clarification-1: Package create enhancements (31 questions)
  - clarification-2: Package development commands (62 questions)
  - clarification-3: Draft files and schema validation (73 questions)
  - clarification-4: Implementation edge cases (48 questions)
- **Task 14 Complete: YAML Schema System** - Pure bash YAML validator
  - Created `agent/schemas/package.schema.yaml` with comprehensive schema definition
  - Implemented `agent/scripts/acp.yaml-validate.sh` (pure bash, zero dependencies)
  - Validates required fields, types, patterns, lengths, reserved names
  - Tested with valid and invalid package.yaml files
  - Provides helpful error messages
- **New Commands Planned** (to be implemented in M4):
  - `@acp.pattern-create` - Create patterns with namespace enforcement
  - `@acp.command-create` - Create commands with namespace enforcement
  - `@acp.design-create` - Create design documents with namespace enforcement
  - `@acp.package-validate` - Comprehensive package validation with auto-fix
  - `@acp.package-publish` - Automated publishing workflow

### Changed
- Updated `@acp.package-create` command with chat-based collection and target directory support
- Project status changed to in_progress with current_milestone: M4
- Milestone 4 progress: 9% (1/11 tasks complete)

## [2.1.4] - 2026-02-18

### Added
- **CRITICAL: Never Reject User Requests Directive**: Added as Best Practice #1 in AGENT.md
  - Agents must NEVER reject requests based on session duration, token context limits, session cost, or task complexity
  - Emphasizes that users have the right to request any work they need
  - Agents should break down complex tasks and work iteratively
  - Marked with 🚨 CRITICAL warning indicators for maximum visibility
  - Positioned as the most important best practice for agent behavior

### Changed
- Renumbered existing best practices (CHANGELOG.md guideline is now #8, secrets handling remains in sequence)

## [2.1.3] - 2026-02-18

### Added
- **Package Management Commands**: Complete package management system with 6 new commands
  - `@acp.package-search` - Search for available ACP packages
  - `@acp.package-list` - List installed packages
  - `@acp.package-remove` - Remove installed packages
  - `@acp.package-info` - Display package information
  - `@acp.package-update` - Update installed packages
  - `@acp.package-install` - Enhanced with manifest support
- **Manifest System**: YAML-based package metadata
  - `agent/manifest.template.yaml` for package authors
  - Tracks package name, version, description, author
  - Lists all files (commands, patterns, designs)
  - Documents dependencies on other packages
  - Enables selective installation and updates
- Supporting shell scripts for all package commands
- Milestone 3 completed (100% - all 13 tasks done)

## [2.1.2] - 2026-02-18

### Changed
- **Command Display**: Refactored command list display into shared `display_available_commands()` function
  - Added new function in `acp.common.sh` for consistent command display
  - Updated `acp.install.sh` to use shared function
  - Updated `acp.version-update.sh` to use shared function
  - Now displays all 19 commands including 6 package management commands
  - Eliminates code duplication (reduced from 40+ lines to 1 function call)

## [2.1.1] - 2026-02-18

### Fixed
- **Script Installation**: Install and update scripts now copy all *.sh files dynamically
  - Previously hardcoded list was missing new package management scripts
  - `acp.package-search.sh`, `acp.package-list.sh`, `acp.package-remove.sh`, `acp.package-info.sh`, `acp.package-update.sh` now properly installed
  - Future-proof: any new scripts will be automatically copied
  - Simplified code from 10 lines to 4 lines using find command

## [2.1.0] - 2026-02-18

### Added
- **Dependency Checking System**: Project dependency compatibility validation for npm, pip, cargo, and go packages
  - Automatic package manager detection
  - Version compatibility checking with color-coded output
  - User prompts with recommendations for missing dependencies
  - Integration with package installation flow
  - Respects `--yes` flag for CI/CD automation
- Added 6 dependency checking functions to `acp.common.sh`:
  - `detect_package_manager()` - Detects npm/pip/cargo/go
  - `check_npm_dependency()` - Validates npm packages
  - `check_pip_dependency()` - Validates Python packages
  - `check_cargo_dependency()` - Validates Rust packages
  - `check_go_dependency()` - Validates Go packages
  - `validate_project_dependencies()` - Main validation function

### Changed
- Enhanced `acp.package-install.sh` with dependency validation before installation
- Updated project status to "completed" - all 3 milestones (16 tasks) complete
- Milestone 3 progress: 78% → 100%

### Verified
- Pure bash YAML parser (`acp.yaml.sh`) already implemented and functional
- Based on fiftydinar/yaml-parser (MIT license)
- Provides yaml_get(), yaml_set(), yaml_has_key(), yaml_get_array()

## [2.0.0] - 2026-02-18

### Changed
- **BREAKING**: All core ACP scripts renamed with `acp.` prefix for namespace protection
  - `check-for-updates.sh` → `acp.version-check-for-updates.sh`
  - `common.sh` → `acp.common.sh`
  - `install.sh` → `acp.install.sh`
  - `package-install.sh` → `acp.package-install.sh`
  - `uninstall.sh` → `acp.uninstall.sh`
  - `update.sh` → `acp.version-update.sh`
  - `version.sh` → `acp.version-check.sh`
  - `yaml.sh` → `acp.yaml.sh`
- **BREAKING**: Script names now perfectly align with command names
  - `@acp.version-check` → `acp.version-check.sh`
  - `@acp.version-update` → `acp.version-update.sh`
  - `@acp.package-install` → `acp.package-install.sh`
- Installation and update scripts now automatically remove deprecated script names
- All 84+ references updated across documentation

### Added
- `cleanup_deprecated_scripts()` function in `acp.common.sh`
- Automatic cleanup of old script names during install/update

### Migration Guide
**For Users**: No action required if using commands (`@acp.*`)
- Commands still work the same way
- Scripts are called internally by ACP

**For Direct Script Users**: Update script paths
- Old: `./agent/scripts/update.sh`
- New: `./agent/scripts/acp.version-update.sh`

**Why This Change**:
- Enables third-party packages to add their own scripts without conflicts
- Perfect alignment between command names and script names
- Clear namespace ownership (`acp.*` = core, `firebase.*` = firebase package)

## [1.4.3] - 2026-02-16

### Fixed
- **Script Color Output**: Updated remaining shell scripts to use `tput` for colors
  - Updated acp.version-check-for-updates.sh to use tput pattern
  - Updated unacp.install.sh to use tput pattern
  - Updated acp.version-check.sh to use tput pattern
  - Updated package-acp.install.sh to use tput pattern
  - All 6 scripts now use consistent, reliable color handling
  - Removed `echo -e` flags (not needed with tput)
  - Colors work correctly across all shells (bash, sh, zsh)

## [1.4.2] - 2026-02-16

### Changed
- **Script Output**: Added "Git Commands Available" section to acp.install.sh and acp.version-update.sh
  - Separate section highlighting @git.init and @git.commit commands
  - Improves discoverability of git workflow commands for new users
  - Clear separation between ACP commands and Git commands

## [1.4.1] - 2026-02-16

### Fixed
- **Script Color Output**: Fixed color output in acp.install.sh and acp.version-update.sh
  - Replaced unreliable ANSI escape codes with `tput` commands
  - Colors now work correctly across all shells (bash, sh, zsh)
  - No more literal escape character output
  - Added fallback for non-terminal environments
  - Removed unnecessary `-e` flag from echo commands

## [1.4.0] - 2026-02-16

### Added
- **`@git.init` Command**: Intelligent git repository initialization
  - Automatically detects project type (Node.js, Python, Rust, Go, Java, PHP, Ruby, C#, and more)
  - Generates smart `.gitignore` based on detected technology stack
  - Ensures dependency lock files are NOT ignored (package-lock.json, poetry.lock, etc.)
  - Ignores build directories (dist/, build/, target/)
  - Ignores dependency directories (node_modules/, venv/, etc.)
  - Ignores package archives (*.tgz for npm)
  - Uses web search tools for unknown project types
  - Includes 5 examples covering common and uncommon scenarios

## [1.3.2] - 2026-02-16

### Changed
- **Command Namespace**: Renamed `@acp.commit` to `@git.commit`
  - Better namespace organization (git-specific operations under `git` namespace)
  - Updated all references in AGENT.md and CHANGELOG.md
  - Command functionality unchanged, only improved organization

## [1.3.1] - 2026-02-16

### Added
- **Commit Types**: New commit types for better categorization
  - `agent`: Changes to agent/ directory only (designs, tasks, milestones, patterns)
  - `version`: Version bump only (no code changes)
- **Commit Template Enhancements**: Enhanced @git.commit template with metadata
  - Task and milestone completion tracking
  - Test statistics section (tests passing, coverage)
  - Documentation links section (design docs, API docs, related resources)
  - Scope in commit type format: `<type>(<scope>)`

### Changed
- **AGENT.md**: Added rule #9 for respecting user's intentional edits
  - Do not assume missing content needs to be added back
  - Always confirm before reverting user's manual changes
  - Read files to see current state before editing
- **@git.commit**: Clarified intelligent file staging behavior
  - Command automatically determines which files to stage
  - Decision logic for staging all vs specific files
  - Removed redundant prerequisites

### Fixed
- Clarified that `BREAKING CHANGE` is a footer, not a commit type

## [1.3.0] - 2026-02-16

### Added
- **`@git.commit` Command**: Intelligent version-aware git commit automation
  - Automatically detects version impact (major/minor/patch)
  - Updates all version files (package.json, AGENT.md, etc.)
  - Generates CHANGELOG.md entries with proper formatting
  - Creates Conventional Commits format messages
  - Includes decision tree and examples for version bumping
  - Supports semantic versioning workflow

### Changed
- **AGENT.md**: Added critical emphasis on CHANGELOG.md updates for version changes
  - New rule #7 mandates CHANGELOG.md updates for all version changes
  - Recommends using `@git.commit` for version-aware commits
  - Explains rationale for changelog discipline
  - Moved secrets handling to rule #8

## [1.2.2] - 2026-02-16

### Added
- `agent/.gitignore` file to exclude reports directory from version control
- `agent/reports/` directory created during installation
- Reports are now generated locally but not committed to git

### Changed
- `acp.install.sh` now creates `agent/.gitignore` and `agent/reports/` directory
- `acp.version-update.sh` ensures `agent/.gitignore` exists for users updating from older versions

## [1.2.1] - 2026-02-16

### Changed
- Updated installation scripts to display new ACP command format
- `acp.install.sh` now shows all 11 ACP commands with descriptions
- `acp.version-update.sh` now shows all 11 ACP commands with descriptions
- Replaced old "AGENT.md: Initialize" prompt format with `@acp.init` command
- Improved user experience for new installations and updates

## [1.2.0] - 2026-02-16

### Added
- **Package Installation Enhancements**:
  - `agent/scripts/package-acp.install.sh` script for automated package installation
  - Support for installing patterns and design documents (not just commands)
  - `-y` flag to skip confirmation prompts for automated installations
  - Multi-directory installation from agent/ (commands, patterns, design)
  - Conflict detection and resolution

### Changed
- Renamed `@acp.install` to `@acp.package-install` for clarity
- Enhanced package installation to support all agent/ directories
- Simplified Milestone 2 scope by removing creation commands
- Updated package-install documentation with multi-directory examples

## [1.1.0] - 2026-02-16

### Added
- **ACP Commands System**: File-based command interface for ACP operations
  - Command template for creating custom commands
  - Flat directory structure with dot notation (acp.init.md)
  - 11 core commands implemented across 2 milestones:
  
  **Workflow Commands**:
    - `@acp.init` - Initialize agent context (replaces "AGENT.md: Initialize")
    - `@acp.proceed` - Continue with next task (replaces "AGENT.md: Proceed")
    - `@acp.status` - Display project status
  
  **Version Commands**:
    - `@acp.version-check` - Show current ACP version
    - `@acp.version-check-for-updates` - Check for updates
    - `@acp.version-update` - Update ACP to latest version
  
  **Documentation Commands**:
    - `@acp.update` - Update progress.yaml with latest status
    - `@acp.sync` - Synchronize documentation with source code
    - `@acp.validate` - Validate all ACP documents for consistency
  
  **Utility Commands**:
    - `@acp.report` - Generate comprehensive project status report
    - `@acp.package-install` - Install third-party command packages
  
  - Self-documenting commands with step-by-step instructions
  - Autocomplete-friendly namespace system with dot notation
  - Security considerations documented
  - Script-based package installation

- **Documentation Updates**:
  - ACP Commands section in AGENT.md with full documentation
  - Command examples in README.md
  - Updated directory structure diagrams
  - Command invocation syntax documented
  - Comprehensive command documentation with examples

### Changed
- Consolidated all scripts under `agent/scripts/` directory
- Updated installation script path in README
- Improved project organization with commands directory
- Simplified Milestone 2 scope by removing creation commands (natural language is sufficient)

## [1.0.3] - 2026-02-13

### Added
- **Template Files**: Complete set of reusable templates for all ACP document types
  - Design document template with comprehensive sections and examples
  - Requirements template for project planning
  - Milestone template with deliverables and success criteria
  - Task template with steps and verification checklist
  - Pattern template for documenting reusable patterns
  - Bootstrap template for project setup patterns
  - Progress tracking YAML template

- **Generic Patterns**: Database-agnostic, framework-independent patterns
  - TypeScript service layer pattern (applicable to any TypeScript project)

- **Installation & Update Scripts**:
  - `scripts/acp.install.sh` - Automated installation (run from project root)
  - `scripts/acp.version-update.sh` - Direct file updates (git handles diffs)
  - `scripts/acp.version-check-for-updates.sh` - Automatic update checking with changelog display

- **Documentation**:
  - README with quick start guide and example projects
  - CHANGELOG for version tracking
  - AGENT.md with complete ACP methodology and update instructions

- **Features**:
  - Automatic update checking on agent initialization
  - Git-friendly workflow (no backup files)
  - Template files always overwritten on install/update
  - All URLs reference `mainline` branch
  - Sample prompts for AI agents

### Changed
- Converted project-specific remember-mcp documentation to generic templates
- Made all examples platform-agnostic and framework-independent
- Reorganized scripts into dedicated `scripts/` directory
- Simplified installation to assume execution from project root

### Removed
- All project-specific content (remember-mcp milestones, tasks, designs)
- Framework-specific patterns (TanStack Router, Firebase-specific examples)
- Project-specific TypeScript patterns (Firestore users pattern)

