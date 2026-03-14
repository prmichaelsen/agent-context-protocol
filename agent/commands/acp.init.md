# Command: init

> **🤖 Agent Directive**: If you are reading this file, the command `@acp-init` has been invoked. Follow the steps below to execute this command.

**Namespace**: acp
**Version**: 1.1.0
**Created**: 2026-02-16
**Last Updated**: 2026-03-09
**Status**: Active
**Scripts**: None

---

**Purpose**: Initialize agent context by loading all documentation, reviewing source code, and preparing for work
**Category**: Workflow
**Frequency**: Once Per Session

---

## Arguments

| Argument | Aliases | Description |
|---|---|---|
| `--quick` | `-q` | Fast init: skips version checks, source file review, and documentation sync. Equivalent to `--skip checks,files,sync` |
| `--skip <items>` | | Comma-separated list of steps to skip. Valid items: `checks`, `sessions`, `docs`, `global`, `keys`, `files`, `sync`, `progress` |

### Skip Items Reference

| Item | Steps Skipped | Description |
|---|---|---|
| `checks` | Step 1 | ACP version update check |
| `sessions` | Step 1.5 | Session registration and sibling display |
| `docs` | Step 2 | Reading agent documentation (progress, designs, milestones, tasks, patterns) |
| `projects` | Step 2.3 | ACP project listing |
| `global` | Step 2.5 | Global package discovery |
| `keys` | Step 2.8 | Key file index reading |
| `files` | Steps 3-4 | Source file identification and review |
| `sync` | Steps 5-6 | Documentation drift detection and stale doc updates |
| `progress` | Step 7 | Progress tracking updates |

### Argument Parsing

Arguments are parsed from the user's invocation using natural language matching:
- `@acp-init --quick` or `@acp-init -q`
- `@acp-init --skip checks,sync`
- `@acp-init --quick --skip sessions` (quick mode plus additional skips)
- `@acp-init --skip checks,files,sync,progress` (granular control)

When `--quick` is combined with `--skip`, the skip sets are merged (union).

---

## What This Command Does

This command performs a comprehensive initialization of the agent's context for working on an ACP-structured project. It checks for ACP updates, reads all documentation in the `agent/` directory, reviews key source files to understand the current implementation, updates any stale documentation, and refreshes progress tracking.

Use this command at the start of each work session to ensure you have complete project context. It's the most thorough way to get up to speed on a project, understanding both what's documented and what's actually implemented in the code.

Unlike `@acp-status` which only reads progress.yaml, or `@acp-proceed` which focuses on a single task, `@acp-init` provides comprehensive context loading across all project documentation and source code. It's designed to answer: "What is this project? Where does it stand? What needs to be done?"

---

## Prerequisites

- [ ] ACP installed in project (AGENT.md and agent/ directory exist)
- [ ] Project has source code to review
- [ ] Git repository initialized (optional, for update checking)

---

## Steps

### 1. Check for ACP Updates

**Skip item**: `checks` | **Skipped by**: `--quick`

Check if newer version of ACP is available.

**Actions**:
- Run `./agent/scripts/acp.version-check-for-updates.sh` if it exists
- Report if updates are available
- Show what changed via CHANGELOG
- Ask if user wants to update (don't auto-update)

**Expected Outcome**: User informed of ACP version status

### 1.5. Register Session and Show Siblings (Optional)

**Skip item**: `sessions`

Register this agent session and display any active sibling sessions.

**Actions**:
- If `./agent/scripts/acp.sessions.sh` exists, run `./agent/scripts/acp.sessions.sh register --project <current-project> --pid <agent-pid>`
- If `./agent/scripts/acp.sessions.sh` exists, run `./agent/scripts/acp.sessions.sh list` and display active sibling sessions

**Display format** (compact, one line per sibling):
```
Active Sessions: 2 others
  remember-core — task-12 (Implement Auth) — 20m ago
  agentbase.me — task-5 (Fix API Routes) — 8m ago
```

**Expected Outcome**: Session registered, sibling sessions displayed

**Note**: If `./agent/scripts/acp.sessions.sh` does not exist, skip this step silently.

### 2. Read All Agent Documentation

**Skip item**: `docs`

Load complete context from the agent/ directory.

**Actions**:
- Read `agent/progress.yaml` for current status
- Read `agent/design/requirements.md` for project goals
- Read all design documents in `agent/design/`
- Read current milestone document
- Read all task documents (focus on current/upcoming)
- Read relevant pattern documents in `agent/patterns/`
- Note any missing or incomplete documentation

**Expected Outcome**: Complete documentation context loaded

### 2.3. List ACP Projects (Optional)

**Skip item**: `projects`

List all registered ACP projects from the global `~/.acp` directory.

**Actions**:
- Check if `~/.acp` directory exists
- If it does not exist, skip this step silently
- If it exists, read `~/.acp/projects.yaml`
- List all projects with their name, type, description, and status

**Display format**:
```
📁 ACP Projects...
  ✓ Read ~/.acp/projects.yaml

  Found 5 projects:
    • agent-context-protocol (active)
      Path: ~/.acp/projects/agent-context-protocol
      Type: unknown
    • core-sdk (active) — package
      Path: ~/.acp/projects/core-sdk
    • agentbase.me (active) — AI Integration Registry with OAuth endpoints and MCP server catalog
      Path: ~/.acp/projects/agentbase.me
    • dmx-mcp (active) — mcp-server
      Path: ~/.acp/projects/dmx-mcp
    • gcloud-mcp (active) — mcp-server — Google Cloud MCP server for Cloud Build and Cloud Run log tools
      Path: ~/.acp/projects/gcloud-mcp
```

**Expected Outcome**: User sees all registered ACP projects at a glance

**Note**: If `~/.acp` does not exist or `~/.acp/projects.yaml` is missing, skip this step silently.

### 2.5. Discover Global Packages (Optional)

**Skip item**: `global`

Check for globally installed ACP packages.

**Actions**:
- Check if `~/.acp/manifest.yaml` exists
- If exists, read global manifest
- List globally installed packages with versions
- Report available commands and patterns from global packages
- Note that local packages take precedence over global packages

**Expected Outcome**: Global packages discovered and reported (if any)

**Example Output**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🌐 Global Packages Discovered...
  ✓ Read ~/.acp/manifest.yaml
  
  Found 2 global packages:
    • @prmichaelsen/acp-git (v1.0.0)
      Location: ~/.acp/packages/@prmichaelsen/acp-git
      2 commands: git.commit, git.init
    
    • @prmichaelsen/acp-firebase (v1.2.0)
      Location: ~/.acp/packages/@prmichaelsen/acp-firebase
      3 patterns, 2 commands
  
  ℹ️  Local packages take precedence over global packages
```

**Note**: This step is optional and graceful - if no global packages exist or manifest is not found, continue without error.

### 2.8. Read Key Files from Index

**Skip item**: `keys`

Load critical project files from the key file index.

**Actions**:
- Check if `agent/index/` directory exists
- If exists, scan for all `*.yaml` files (excluding `*.template.yaml`)
- Parse each index file's entries
- Merge entries across namespaces (`local.*` takes precedence over package indices)
- Filter entries with weight >= 0.8 (high-importance files for init)
- Sort by weight descending
- Read each qualifying file
- Produce visible output showing what was read/skipped

**Display format**:
```
📑 Reading Key Files...
  ✓ agent/design/acp-commands-design.md (weight: 0.9, design)
  ✓ agent/patterns/local.e2e-testing.md (weight: 0.8, pattern)
  ○ agent/patterns/local.tracked-untracked-directories.md (weight: 0.7, skipped — below threshold)

  2 index files scanned, 2 key files read, 1 skipped
```

**Expected Outcome**: High-importance key files loaded into context

**Note**: If `agent/index/` does not exist, skip this step silently. The index is optional but recommended.

### 3. Identify Key Source Files

**Skip item**: `files` | **Skipped by**: `--quick`

Determine which source files are most important to review.

**Actions**:
- Check project type (package.json, requirements.txt, go.mod, etc.)
- Identify main entry points (src/index.ts, main.py, cmd/main.go, etc.)
- Note key configuration files (tsconfig.json, .env.example, etc.)
- Identify core business logic files
- List test files

**Expected Outcome**: Key source files identified for review

### 4. Review Key Source Files

**Skip item**: `files` | **Skipped by**: `--quick`

Read important source files to understand current implementation.

**Actions**:
- Read main entry point files
- Review core business logic
- Check configuration files
- Note any TODOs or FIXMEs
- Understand current architecture
- Compare implementation with design documents

**Expected Outcome**: Current implementation understood

### 5. Identify Documentation Drift

**Skip item**: `sync` | **Skipped by**: `--quick`

Compare documentation with actual implementation.

**Actions**:
- Check if design documents match implementation
- Note any undocumented features in code
- Identify outdated documentation
- Flag missing documentation
- List discrepancies

**Expected Outcome**: Documentation gaps identified

### 6. Update Stale Documentation

**Skip item**: `sync` | **Skipped by**: `--quick`

Refresh outdated documentation to match current state.

**Actions**:
- Update design documents if implementation differs
- Update task documents if steps have changed
- Add notes about discovered issues
- Update progress.yaml with current understanding
- Document any new patterns found in code

**Expected Outcome**: Documentation synchronized with code

### 7. Update Progress Tracking

**Skip item**: `progress`

Refresh progress.yaml with latest status.

**Actions**:
- Verify current milestone is correct
- Confirm current task is accurate
- Update progress percentages if needed
- Add recent work entry for initialization
- Update next steps based on current state
- Note any new blockers discovered

**Expected Outcome**: Progress tracking is current and accurate

### 8. Report Status and Next Steps

Provide comprehensive status report.

**Actions**:
- Summarize project status
- Show current milestone and progress
- Identify current task
- List recent accomplishments
- Highlight next steps
- Note any blockers or concerns
- Provide recommendations

**Expected Outcome**: User has complete context and knows what to do next

### 9. Display Usage Tip

Show a helpful tip about init flags when no flags were used.

**Actions**:
- If the user invoked `@acp-init` **without** `--quick` or `--skip`, display the following tip at the end of the output:
  ```
  Tip: Use `@acp-init --quick` to skip version checks, source file review, and doc sync for faster startup. Use `--skip <items>` to skip individual steps (e.g. `--skip checks,files`).
  ```
- If the user already used `--quick` or `--skip`, do **not** display the tip (they already know about it).

**Expected Outcome**: Users discover the faster init modes naturally

### Handling Skipped Steps

When a step is skipped (via `--quick` or `--skip`), the agent should:
1. **Not execute** any actions for that step
2. **Not display** the step's section header or output block
3. Simply omit the step silently — no "skipped" messages needed unless the agent chooses to show a compact summary of what was skipped at the top of the output

---

## Verification

- [ ] ACP update check completed
- [ ] All agent/ files read successfully
- [ ] Key source files identified and reviewed
- [ ] Documentation drift identified (if any)
- [ ] Stale documentation updated
- [ ] progress.yaml updated with current status
- [ ] Comprehensive status report provided
- [ ] Next steps clearly identified
- [ ] No errors encountered during initialization

---

## Expected Output

### Files Modified
- `agent/progress.yaml` - Updated with current status, recent work entry added
- Design/task documents - Updated if stale (as needed)

### Console Output
```
🚀 Initializing Agent Context

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Checking for ACP updates...
  Current version: 1.0.3
  Status: Up to date

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📚 Reading Agent Documentation...
  ✓ Read agent/progress.yaml
  ✓ Read agent/design/requirements.md
  ✓ Read agent/design/acp-commands-design.md
  ✓ Read agent/milestones/milestone-1-acp-commands.md
  ✓ Read agent/milestones/milestone-2-acp-commands-advanced.md
  ✓ Read agent/tasks/task-1-commands-infrastructure.md
  ✓ Read agent/tasks/task-2-workflow-commands.md
  ✓ Read agent/tasks/task-3-version-commands.md
  ✓ Read agent/tasks/task-4-update-documentation.md
  
  Total: 9 agent files read

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📂 Reviewing Source Files...
  ✓ Read AGENT.md (1,055 lines)
  ✓ Read README.md (200 lines)
  ✓ Read CHANGELOG.md (50 lines)
  ✓ Read scripts/acp.install.sh
  ✓ Read scripts/acp.version-update.sh
  ✓ Read agent/commands/command.template.md
  ✓ Read agent/commands/acp.status.md
  ✓ Read agent/commands/acp.proceed.md
  
  Total: 8 source files reviewed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔍 Documentation Analysis...
  ✓ Design documents match implementation
  ✓ Task documents are current
  ⚠️  Task-2 document references old nested structure (acp/init.md)
  ✓ Progress tracking is accurate

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 Updating Documentation...
  ✓ Updated progress.yaml with initialization entry
  ℹ️  No other updates needed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Project Status

Project: agent-context-protocol (v1.0.3)
Status: in_progress
Started: 2026-02-16

Current Milestone: M1 - ACP Commands Infrastructure
Progress: 33% (1/4 tasks completed)
Status: in_progress

Current Task: task-2 - Implement Core Workflow Commands
Status: in_progress (2/3 commands complete)
File: agent/tasks/task-2-workflow-commands.md

Recent Work (2026-02-16):
  - ✅ Created comprehensive design document
  - ✅ Implemented @acp-status command
  - ✅ Implemented @acp-proceed command
  - 📋 Next: Complete workflow commands (init)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 Next Steps:
  1. Complete task-2: Implement acp.init.md command
  2. Start task-3: Implement version commands
  3. Complete milestone-1: All 6 core commands

⚠️  Current Blockers: None

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Initialization Complete!
Ready to proceed with task-2 completion.
```

### Status Update
- Recent work entry added to progress.yaml
- Context fully loaded
- Ready to work

---

## Examples

### Example 1: Starting Fresh Session

**Context**: Beginning work on a project for the first time today

**Invocation**: `@acp-init`

**Result**: Checks for updates, reads all 15 agent files, reviews 10 source files, updates progress tracking, reports you're on milestone 2 task 5, ready to continue

### Example 2: Returning After Break

**Context**: Haven't worked on project in a week

**Invocation**: `@acp-init`

**Result**: Full context reload, discovers 3 new commits since last session, updates documentation to reflect changes, shows current status (milestone 3, 80% complete), identifies next task

### Example 3: New Agent Session

**Context**: Different AI agent picking up the project

**Invocation**: `@acp-init`

**Result**: Complete onboarding - reads all documentation, understands architecture from source code, gets current status, ready to contribute immediately

### Example 4: Quick Init

**Context**: Returning to a familiar project, just need docs and status

**Invocation**: `@acp-init --quick`

**Result**: Skips version checks, source file review, and doc sync. Reads agent documentation, key files, reports status — fast startup in ~10 seconds

### Example 5: Selective Skip

**Context**: Want everything except version checks and session registration

**Invocation**: `@acp-init --skip checks,sessions`

**Result**: Full init minus the two skipped steps. All docs read, files reviewed, sync performed, status reported

---

## Related Commands

- [`@acp-proceed`](acp.proceed.md) - Use after init to start working on current task
- [`@acp-status`](acp.status.md) - Use for quick status check without full initialization
- [`@acp-sync`](acp.sync.md) - Use to sync documentation after code changes
- [`@acp-version-check-for-updates`](acp.version-check-for-updates.md) - Part of init process

---

## Troubleshooting

### Issue 1: No agent/ directory found

**Symptom**: Error message "agent/ directory not found"

**Cause**: ACP not installed in this project

**Solution**: Install ACP first using the installation script from the ACP repository

### Issue 2: Update check script not found

**Symptom**: Warning "acp.version-check-for-updates.sh not found"

**Cause**: Older ACP installation without update scripts

**Solution**: This is non-critical, continue with initialization. Consider updating ACP to latest version.

### Issue 3: No source files found

**Symptom**: Warning "No source files to review"

**Cause**: Project is new or source code is in unexpected location

**Solution**: This is fine for new projects. Specify source file locations if they're in non-standard directories.

### Issue 4: progress.yaml doesn't exist

**Symptom**: Error "Cannot read progress.yaml"

**Cause**: Progress tracking not initialized yet

**Solution**: Create progress.yaml from template: `cp agent/progress.template.yaml agent/progress.yaml`, then run `@acp-init` again

---

## Security Considerations

### File Access
- **Reads**: All files in `agent/` directory, key source files throughout project, AGENT.md, README.md, CHANGELOG.md
- **Writes**: `agent/progress.yaml` (updates status), design/task documents (if stale)
- **Executes**: `./agent/scripts/acp.version-check-for-updates.sh` (if exists)

### Network Access
- **APIs**: None directly (update check script may access GitHub)
- **Repositories**: Update check script accesses GitHub repository

### Sensitive Data
- **Secrets**: Never reads .env files or credential files
- **Credentials**: Does not access any credentials

---

## Notes

- This is the most comprehensive ACP command - expect 30-60 seconds for large projects
- Reads many files to build complete context
- Updates documentation if drift is detected
- Safe to run multiple times (idempotent)
- Replaces the old "AGENT.md: Initialize" prompt
- Consider running at start of each session for best results
- Can be run mid-session if you need to refresh context

---

**Namespace**: acp
**Command**: init
**Version**: 1.1.0
**Created**: 2026-02-16
**Last Updated**: 2026-03-09
**Status**: Active
**Compatibility**: ACP 1.0.3+
**Author**: ACP Project
