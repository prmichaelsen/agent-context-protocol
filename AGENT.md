# Agent Context Protocol (ACP)

**Also Known As**: The Agent Directory Pattern
**Version**: 3.9.0
**Created**: 2026-02-11
**Status**: Production Pattern

---

## Table of Contents

1. [Overview](#overview)
2. [What is the Agent Pattern?](#what-is-the-agent-pattern)
3. [Why This Pattern Exists](#why-this-pattern-exists)
4. [Directory Structure](#directory-structure)
5. [Core Components](#core-components)
6. [How to Use the Agent Pattern](#how-to-use-the-agent-pattern)
7. [Pattern Significance & Impact](#pattern-significance--impact)
8. [Problems This Pattern Solves](#problems-this-pattern-solves)
9. [Instructions for Future Agents](#instructions-for-future-agents)
10. [Real-World Example: remember-mcp](#real-world-example-remember-mcp)
11. [Best Practices](#best-practices)

---

## Overview

The **Agent Context Protocol (ACP)** is a comprehensive documentation and planning system designed to enable AI agents to understand, build, and maintain complex software projects through structured knowledge capture. It transforms implicit project knowledge into explicit, machine-readable documentation that persists across agent sessions.

**Core Principle**: *Every decision, pattern, and requirement should be documented in a way that allows a future agent (or human) to understand the project's complete context without needing to reverse-engineer the codebase.*

---

## What is ACP?

The **Agent Context Protocol (ACP)** is a **documentation-first development methodology** that creates a parallel knowledge base alongside your source code. It consists of:

1. **Design Documents** - Architectural decisions, patterns, and technical specifications
2. **Milestones** - Project phases with clear deliverables and success criteria
3. **Tasks** - Granular, actionable work items with verification steps
4. **Patterns** - Reusable architectural and coding patterns
5. **Progress Tracking** - YAML-based progress monitoring and status updates

This pattern enables:
- **Agent Continuity**: New agents can pick up where previous agents left off
- **Knowledge Preservation**: Design decisions and rationale are never lost
- **Systematic Development**: Complex projects are broken into manageable pieces
- **Quality Assurance**: Clear success criteria and verification steps
- **Collaboration**: Multiple agents (or humans) can work on the same project

---

## Why This Pattern Exists

### The Problem

Traditional software development faces several challenges when working with AI agents:

1. **Context Loss**: Agents have no memory between sessions
2. **Implicit Knowledge**: Design decisions exist only in developers' heads
3. **Inconsistent Patterns**: No single source of truth for architectural patterns
4. **Scope Creep**: Projects expand without clear boundaries
5. **Quality Drift**: Standards erode without explicit documentation
6. **Onboarding Friction**: New contributors must reverse-engineer intent

### The Solution

ACP solves these by:

- **Externalizing Knowledge**: All decisions documented explicitly
- **Structured Planning**: Milestones and tasks provide clear roadmap
- **Pattern Library**: Reusable solutions to common problems
- **Progress Tracking**: YAML files track what's done and what's next
- **Self-Documenting**: ACP documents itself

---

## Directory Structure

```
project-root/
├── AGENT.md                        # This file - ACP documentation
├── agent/                          # Agent directory (ACP structure)
│   ├── commands/                   # Command system
│   │   ├── .gitkeep
│   │   ├── command.template.md     # Command template
│   │   ├── acp.init.md             # @acp-init
│   │   ├── acp.proceed.md          # @acp-proceed
│   │   ├── acp.status.md           # @acp-status
│   │   └── ...                     # More commands
│   │
│   ├── design/                     # Design documents
│   │   ├── .gitkeep
│   │   ├── requirements.md         # Core requirements
│   │   ├── {feature}-design.md    # Feature specifications
│   │   ├── {pattern}-pattern.md   # Design patterns
│   │   └── ...
│   │
│   ├── milestones/                 # Project milestones
│   │   ├── .gitkeep
│   │   ├── milestone-1-{name}.md
│   │   ├── milestone-2-{name}.md
│   │   └── ...
│   │
│   ├── patterns/                   # Architectural patterns
│   │   ├── .gitkeep
│   │   ├── bootstrap.md            # Project setup pattern
│   │   ├── {pattern-name}.md
│   │   └── ...
│   │
│   ├── tasks/                      # Granular tasks
│   │   ├── .gitkeep
│   │   ├── task-1-{name}.md
│   │   ├── task-2-{name}.md
│   │   └── ...
│   │
│   └── progress.yaml               # Progress tracking
│
└── (project-specific files)        # Your project structure
```

---

## Core Components

### 1. Design Documents (`agent/design/`)

**Purpose**: Capture architectural decisions, technical specifications, and design rationale.

**Structure**:
```markdown
# {Feature/Pattern Name}

**Concept**: One-line description
**Created**: YYYY-MM-DD
**Status**: Proposal | Design Specification | Implemented

---

## Overview
High-level description of what this is and why it exists

## Problem Statement
What problem does this solve?

## Solution
How does this solve the problem?

## Implementation
Technical details, code examples, schemas

## Benefits
Why this approach is better than alternatives

## Trade-offs
What are the downsides or limitations?

---

**Status**: Current status
**Recommendation**: What should be done
```

### 2. Milestones (`agent/milestones/`)

**Purpose**: Define project phases with clear deliverables and success criteria.

**Structure**:
```markdown
# Milestone {N}: {Name}

**Goal**: One-line objective
**Duration**: Estimated time
**Dependencies**: Previous milestones
**Status**: Not Started | In Progress | Completed

---

## Overview
What this milestone accomplishes

## Deliverables
- Concrete outputs
- Measurable results
- Specific artifacts

## Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] ...

## Key Files to Create
List of files/directories this milestone produces

---

**Next Milestone**: Link to next phase
**Blockers**: Current obstacles
```

### 3. Tasks (`agent/tasks/`)

**Purpose**: Break milestones into actionable, verifiable work items.

**Structure**:
```markdown
# Task {N}: {Name}

**Milestone**: Parent milestone
**Estimated Time**: Hours/days
**Dependencies**: Other tasks
**Status**: Not Started | In Progress | Completed

---

## Objective
What this task accomplishes

## Steps
1. Concrete action 1
2. Concrete action 2
3. ...

## Verification
- [ ] Verification step 1
- [ ] Verification step 2
- [ ] ...

---

**Next Task**: Link to next task
```

### 4. Patterns (`agent/patterns/`)

**Purpose**: Document reusable architectural and coding patterns.

**Structure**:
```markdown
# {Pattern Name}

## Overview
What this pattern is and when to use it

## Core Principles
Fundamental concepts

## Implementation
How to implement this pattern

## Examples
Code examples and use cases

## Benefits
Why use this pattern

## Anti-Patterns
What NOT to do

---

**Status**: Current status
**Recommendation**: When to use this pattern
```

### 5. Progress Tracking (`agent/progress.yaml`)

**Purpose**: Machine-readable progress tracking and status monitoring.

**Structure**:
```yaml
project:
  name: project-name
  version: 0.1.0
  started: YYYY-MM-DD
  status: in_progress | completed
  current_milestone: M1

milestones:
  - id: M1
    name: Milestone Name
    status: not_started | in_progress | completed
    progress: 0-100%
    started: YYYY-MM-DD
    completed: YYYY-MM-DD | null
    estimated_weeks: N
    tasks_completed: N
    tasks_total: N
    notes: |
      Progress notes

tasks:
  milestone_1:
    - id: task-1
      name: Task Name
      status: not_started | in_progress | completed
      file: agent/tasks/task-1-name.md
      estimated_hours: N
      actual_hours: null
      completed_date: YYYY-MM-DD | null
      notes: |
        Task notes

documentation:
  design_documents: N
  milestone_documents: N
  pattern_documents: N
  task_documents: N

progress:
  planning: 0-100%
  implementation: 0-100%
  overall: 0-100%

recent_work:
  - date: YYYY-MM-DD
    description: What was done
    items:
      - ✅ Completed item
      - ⚠️  Warning/note
      - 📋 Pending item

next_steps:
  - Next action 1
  - Next action 2

notes:
  - Important note 1
  - Important note 2

current_blockers:
  - Blocker 1
  - Blocker 2
```

---

## How to Use the Agent Pattern

### For Starting a New Project

1. **Create Agent Directory Structure**
   ```bash
   mkdir -p agent/{design,milestones,patterns,tasks}
   touch agent/{design,milestones,patterns,tasks}/.gitkeep
   ```

2. **Write Requirements Document**
   - Create `agent/design/requirements.md`
   - Document core requirements, constraints, and goals
   - Define success criteria

3. **Define Milestones**
   - Break project into 5-10 major phases
   - Each milestone should be 1-3 weeks of work
   - Clear deliverables and success criteria

4. **Create Initial Tasks**
   - Break first milestone into concrete tasks
   - Each task should be 1-4 hours of work
   - Include verification steps

5. **Initialize Progress Tracking**
   - Create `agent/progress.yaml`
   - Set up milestone and task tracking
   - Document initial status

6. **Document Patterns**
   - Create `agent/patterns/bootstrap.md` with setup instructions
   - Document architectural decisions as patterns
   - Include code examples

### For Continuing an Existing Project

1. **Read Progress File**
   - Understand current status
   - Identify current milestone
   - Find next tasks

2. **Review Design Documents**
   - Read relevant design docs in `agent/design/`
   - Understand architectural decisions
   - Check for constraints and patterns

3. **Check Current Milestone**
   - Read milestone document
   - Review success criteria
   - Understand deliverables

4. **Find Next Task**
   - Look at current milestone's tasks
   - Find first incomplete task
   - Read task document

5. **Execute Task**
   - Follow task steps
   - Verify completion
   - Update progress.yaml

6. **Document Changes**
   - Update progress.yaml
   - Add notes about work completed
   - Document any new patterns or decisions

### For Adding New Features

1. **Create Design Document**
   - Document in `agent/design/{feature}-design.md`
   - Include problem, solution, implementation
   - Get approval before proceeding

2. **Update Milestones**
   - Add new milestone or extend existing
   - Update progress.yaml

3. **Create Tasks**
   - Break feature into tasks
   - Add to appropriate milestone
   - Include verification steps

4. **Document Patterns**
   - If feature introduces new patterns, document them
   - Update existing patterns if needed

---

## Pattern Significance & Impact

### Significance

The Agent Pattern represents a **paradigm shift** in how we approach AI-assisted development:

1. **Knowledge as Code**: Documentation is treated with the same rigor as source code
2. **Agent-First Design**: Projects are designed to be understandable by AI agents
3. **Explicit Over Implicit**: All knowledge is externalized and documented
4. **Systematic Development**: Complex projects become manageable through structure
5. **Quality by Design**: Standards and patterns are enforced through documentation

### Impact

**On Development Speed**:
- ✅ 50-70% faster onboarding for new agents
- ✅ Reduced context-gathering time
- ✅ Fewer architectural mistakes
- ✅ Less rework due to clear specifications

**On Code Quality**:
- ✅ Consistent patterns across codebase
- ✅ Better architectural decisions (documented rationale)
- ✅ Fewer bugs (clear verification steps)
- ✅ More maintainable code (patterns documented)

**On Project Management**:
- ✅ Clear progress visibility
- ✅ Accurate time estimates
- ✅ Better scope management
- ✅ Easier to parallelize work

**On Team Collaboration**:
- ✅ Shared understanding of architecture
- ✅ Consistent coding standards
- ✅ Better knowledge transfer
- ✅ Reduced communication overhead

---

## Problems This Pattern Solves

### 1. **Context Loss Between Agent Sessions**

**Problem**: Agents have no memory between sessions. Each new session starts from scratch.

**Solution**: The agent directory provides complete context:
- `progress.yaml` shows current status
- Design docs explain architectural decisions
- Patterns document coding standards
- Tasks provide next steps

**Example**: An agent can read `progress.yaml`, see that task-3 is next, read the task document, and continue work immediately.

### 2. **Implicit Knowledge**

**Problem**: Design decisions exist only in developers' heads or scattered across chat logs.

**Solution**: All decisions are documented in design documents with rationale:
- Why this approach was chosen
- What alternatives were considered
- What trade-offs were made

**Example**: A design document might explain why discriminated unions are better than exceptions for access control, with code examples and trade-off analysis.

### 3. **Inconsistent Patterns**

**Problem**: Different parts of codebase use different patterns for the same problems.

**Solution**: Patterns directory provides single source of truth:
- Architectural patterns documented
- Code examples provided
- Anti-patterns identified

**Example**: A pattern document might specify that all data access must go through service layers, with implementation examples and anti-patterns.

### 4. **Scope Creep**

**Problem**: Projects expand without clear boundaries, leading to never-ending development.

**Solution**: Milestones and tasks provide clear scope:
- Each milestone has specific deliverables
- Tasks are granular and verifiable
- Progress is tracked objectively

**Example**: Milestone 1 has exactly 7 tasks. When those are done, the milestone is complete.

### 5. **Quality Drift**

**Problem**: Code quality degrades over time as standards are forgotten or ignored.

**Solution**: Patterns and verification steps maintain quality:
- Every task has verification checklist
- Patterns document best practices
- Design docs explain quality requirements

**Example**: Each task includes verification steps like "TypeScript compiles without errors" and "All tests pass".

### 6. **Onboarding Friction**

**Problem**: New contributors (agents or humans) need weeks to understand the project.

**Solution**: Self-documenting structure enables rapid onboarding:
- Start with `progress.yaml` for status
- Read `requirements.md` for context
- Review patterns for coding standards
- Pick up next task and start working

**Example**: A new agent can become productive in minutes instead of days.

### 7. **Lost Architectural Decisions**

**Problem**: "Why did we do it this way?" becomes unanswerable after a few months.

**Solution**: Design documents capture rationale:
- Problem statement
- Solution approach
- Benefits and trade-offs
- Implementation details

**Example**: A design document might explain why certain IDs are reused across databases, with rationale for the decision and implementation details.

### 8. **Unclear Progress**

**Problem**: Hard to know how much work is done and what's remaining.

**Solution**: `progress.yaml` provides objective metrics:
- Percentage complete per milestone
- Tasks completed vs total
- Recent work logged
- Next steps identified

**Example**: "Milestone 1: 20% complete (1/7 tasks done)"

---

## ACP Commands

ACP supports a command system for common workflows. Commands are file-based triggers that provide standardized, discoverable interfaces for ACP operations.

### What are ACP Commands?

Commands are markdown files in [`agent/commands/`](agent/commands/) that contain step-by-step instructions for AI agents. Instead of typing long prompts like "AGENT.md: Initialize", you can reference command files like `@acp.init` to trigger specific workflows.

**Benefits**:
- **Discoverable**: Browse [`agent/commands/`](agent/commands/) to see all available commands
- **Consistent**: All commands follow the same structure
- **Extensible**: Create custom commands for your project
- **Self-Documenting**: Each command file contains complete documentation
- **Autocomplete-Friendly**: Type `@acp.` to see all ACP commands

### Core Commands

Core ACP commands use the `acp.` prefix and are available in [`agent/commands/`](agent/commands/):

- **[`@acp.init`](agent/commands/acp.init.md)** - Initialize agent context (replaces "AGENT.md: Initialize")
- **[`@acp.proceed`](agent/commands/acp.proceed.md)** - Continue with next task (replaces "AGENT.md: Proceed")
- **[`@acp.status`](agent/commands/acp.status.md)** - Display project status
- **[`@acp.version-check`](agent/commands/acp.version-check.md)** - Show current ACP version
- **[`@acp.version-check-for-updates`](agent/commands/acp.version-check-for-updates.md)** - Check for ACP updates
- **[`@acp.version-update`](agent/commands/acp.version-update.md)** - Update ACP to latest version

### Command Invocation

Commands are invoked using the `@` syntax with dot notation:

```
@acp.init                    → agent/commands/acp.init.md
@acp.proceed                 → agent/commands/acp.proceed.md
@acp.status                  → agent/commands/acp.status.md
@deploy.production           → agent/commands/deploy.production.md
```

**Format**: `@{namespace}.{action}` resolves to `agent/commands/{namespace}.{action}.md`

### Creating Custom Commands

To create custom commands for your project:

1. **Choose a namespace** (e.g., `deploy`, `test`, `custom`)
   - ⚠️ The `acp` namespace is reserved for core commands
   - Use descriptive, single-word namespaces

2. **Copy the command template**:
   ```bash
   cp agent/commands/command.template.md agent/commands/{namespace}.{action}.md
   ```

3. **Fill in the template sections**:
   - Purpose and description
   - Prerequisites
   - Step-by-step instructions
   - Verification checklist
   - Examples and troubleshooting

4. **Invoke your command**: `@{namespace}.{action}`

**Example**: Creating a deployment command:
```bash
# Create the command file
cp agent/commands/command.template.md agent/commands/deploy.production.md

# Edit the file with your deployment steps
# ...

# Invoke it
@deploy.production
```

### Command Template

See [`agent/commands/command.template.md`](agent/commands/command.template.md) for the complete command template with all sections and examples.

### Installing Third-Party Commands

Use `@acp.install` to install command packages from git repositories (available in future release).

**Security Note**: Third-party commands can instruct agents to modify files and execute scripts. Always review command files before installation.

## Global Package Discovery

ACP supports global package installation to `~/.acp/agent/` for package development and global command libraries.

### For Agents: How to Discover Global Packages

When working in any project, you can discover globally installed packages:

1. **Check if global manifest exists**: `~/.acp/agent/manifest.yaml`
2. **Read global manifest**: Contains all globally installed packages
3. **Navigate to package files**: Files are installed directly into `~/.acp/agent/`
4. **Use commands/patterns**: Reference via `@namespace.command` syntax

**Automatic Discovery**: The [`@acp.init`](agent/commands/acp.init.md) command automatically reads `~/.acp/agent/manifest.yaml` and reports globally installed packages.

### Namespace Precedence Rules

**CRITICAL**: Local packages always take precedence over global packages.

**Resolution order**:
1. Check local: `./agent/commands/{namespace}.{command}.md`
2. If not found, check global: `~/.acp/agent/commands/{namespace}.{command}.md`
3. Use first match found

**Example**: If both local and global packages define `@firebase.deploy`:
- ✅ Use `./agent/commands/firebase.deploy.md` (local takes precedence)
- ❌ Ignore `~/.acp/agent/commands/firebase.deploy.md`

### Global ACP Structure

```
~/.acp/
├── AGENT.md                     # ACP methodology documentation
├── agent/                       # Full ACP installation
│   ├── commands/                # All commands (core + packages)
│   │   ├── acp.init.md         # Core ACP commands
│   │   ├── firebase.deploy.md  # From @user/acp-firebase package
│   │   └── git.commit.md       # From @user/acp-git package
│   ├── patterns/                # All patterns (core + packages)
│   ├── design/                  # All designs (core + packages)
│   ├── scripts/                 # All scripts (core + packages)
│   └── manifest.yaml            # Tracks package sources
└── projects/                    # Optional: User projects workspace
    └── my-project/              # Develop projects here
```

### When to Use Global Packages

**Use global installation** (`--global` flag) for:
- ✅ Package development (work on packages with full ACP tooling)
- ✅ Common utilities used across many projects (git helpers, firebase patterns)
- ✅ Building a personal command library
- ✅ Experimenting with packages before local installation

**Use local installation** (default) for:
- ✅ Project-specific packages
- ✅ Packages that are part of project dependencies
- ✅ When you want version control over package versions
- ✅ Production projects (local is more explicit and controlled)

### Example: Using Global Packages

```bash
# Install git helpers globally
@acp.package-install --global https://github.com/prmichaelsen/acp-git.git

# In any project, discover global packages
@acp.init
# Output: "Found 2 global packages: acp-core, @prmichaelsen/acp-git"

# Use global command
@git.commit
# Agent reads: ~/.acp/agent/commands/git.commit.md
```

---

## Sample Prompts for Using ACP

### Initialize Prompt

**Trigger**: `AGENT.md: Initialize`

Use this prompt when starting work on an ACP-structured project:

```markdown
First, check for ACP updates by running ./agent/scripts/acp.version-check-for-updates.sh (if it exists). If updates are available, report what changed and ask if I want to update.

Then read ALL files in @agent. We are going to understand this project then work on a generic task.

Then read KEY src files per your understanding.

Then read @agent again, update stale @agent/tasks, stale documentation, and update 'agent/progress.yaml'.
```

**Purpose**:
- Checks for updates to ACP methodology and documentation
- Loads complete project context from agent directory
- Reviews source code to understand current implementation
- Updates documentation to reflect current state
- Ensures progress tracking is accurate

### Proceed Prompt

**Trigger**: `AGENT.md: Proceed`

Use this prompt to continue with the next task:

```markdown
Let's proceed with implementing the current or next task. Remember to update @agent/progress.yaml as you progress.
```

**Purpose**:
- Continues work on current or next task
- Reminds agent to maintain progress tracking
- Keeps workflow focused and documented

### Update Prompt

**Trigger**: `AGENT.md: Update`

Updates all ACP files to the latest version:

```markdown
Run ./agent/scripts/acp.version-update.sh to update all ACP files (AGENT.md, templates, and scripts) to the latest version.
```

**Purpose**:
- Updates AGENT.md methodology
- Updates all template files
- Updates utility scripts
- Keeps ACP current with latest improvements

### Check for Updates Prompt

**Trigger**: `AGENT.md: Check for updates`

Checks if updates are available without applying them:

```markdown
Run ./agent/scripts/acp.version-check-for-updates.sh to see if ACP updates are available.
```

**Purpose**:
- Non-destructive check for updates
- Shows what changed via CHANGELOG
- Informs user of available improvements

### Uninstall Prompt

**Trigger**: `AGENT.md: Uninstall`

Removes all ACP files from the project:

```markdown
Run ./agent/scripts/unacp.install.sh to remove all ACP files (agent/ directory and AGENT.md) from this project.
```

**Note**: This script requires user confirmation. If the user confirms they want to uninstall, run:
```bash
./agent/scripts/unacp.install.sh -y
```

**Purpose**:
- Complete removal of ACP
- Clean project state
- Reversible via git

---

## Instructions for Future Agents

### When You First Encounter ACP

1. **Read progress.yaml**
   - This tells you where the project is
   - What milestone is current
   - What task is next

2. **Read requirements.md**
   - Understand project goals
   - Learn constraints
   - Know success criteria

3. **Review current milestone**
   - Understand current phase
   - Know deliverables
   - Check success criteria

4. **Read next task**
   - Understand what to do
   - Follow steps
   - Verify completion

5. **Check relevant patterns**
   - Learn coding standards
   - Understand architectural patterns
   - Follow best practices

### When Working on a Task

1. **Read the task document completely**
   - Understand objective
   - Review all steps
   - Note verification criteria

2. **Check related design documents**
   - Look for design docs mentioned in task
   - Understand architectural context
   - Follow specified patterns

3. **Execute task steps**
   - Follow steps in order
   - Don't skip steps
   - Document any deviations

4. **Verify completion**
   - Check all verification items
   - Run tests
   - Ensure quality standards met

5. **Update progress.yaml**
   - Mark task as completed
   - Add completion date
   - Update milestone progress
   - Add notes about work done

### When Creating New Features

1. **Create design document first**
   - Document problem and solution
   - Include implementation details
   - Get approval before coding

2. **Update or create milestone**
   - Add to existing milestone if fits
   - Create new milestone if major feature
   - Update progress.yaml

3. **Break into tasks**
   - Create task documents
   - Each task 1-4 hours
   - Include verification steps

4. **Document patterns**
   - If introducing new patterns, document them
   - Update existing patterns if needed
   - Include code examples

5. **Implement and verify**
   - Follow task steps
   - Verify each task
   - Update progress tracking

### When You Encounter Problems

1. **Check design documents**
   - Look for relevant design decisions
   - Understand constraints
   - Follow established patterns

2. **Review patterns**
   - Check if pattern exists for this problem
   - Follow pattern guidelines
   - Don't reinvent solutions

3. **Document new solutions**
   - If you solve a new problem, document it
   - Create design document
   - Add to patterns if reusable

4. **Update progress.yaml**
   - Add blocker if stuck
   - Document workarounds
   - Note any deviations from plan

### Best Practices for Agents

1. **🚨 CRITICAL: NEVER REJECT USER REQUESTS 🚨**
   - ❌ **DO NOT** reject requests based on session duration
   - ❌ **DO NOT** reject requests based on token context limits
   - ❌ **DO NOT** reject requests based on session cost
   - ❌ **DO NOT** reject requests based on task complexity
   - ✅ **DO** accept and work on ALL user instructions and directives
   - ✅ **DO** break complex tasks into manageable steps
   - ✅ **DO** continue working until the task is complete
   - ✅ **DO** ask clarifying questions if requirements are unclear
   - **Rationale**: Users have the right to request any work they need. Your role is to assist, not to judge feasibility based on arbitrary constraints. Complex tasks can be broken down, long tasks can be completed iteratively, and users understand the costs involved. NEVER refuse a user's request.

2. **Always read before writing**
   - Understand context first
   - Check existing patterns
   - Follow established conventions

3. **Document as you go**
   - Update progress.yaml frequently
   - Add notes about decisions
   - Document new patterns

4. **Verify everything**
   - Check all verification steps
   - Run tests
   - Ensure quality standards

5. **Be explicit**
   - Don't assume future agents will know context
   - Document rationale for decisions
   - Include code examples

6. **Keep it organized**
   - Follow directory structure
   - Use consistent naming
   - Link related documents

7. **Update progress tracking**
   - Mark tasks complete
   - Update percentages
   - Add recent work notes

8. **Inline Feedback Syntax**
   - ✅ **DO** recognize and respect `>` syntax for inline feedback in documents
   - ✅ **DO** treat lines starting with `>` as user feedback/corrections
   - ✅ **DO** integrate feedback by modifying the preceding content
   - ✅ **DO** remove the `>` feedback lines after integrating changes
   - **Example**:
     ```markdown
     // Agent-generated document
     Here are the requirements:
     - Requirement 1
     - Requirement 2
     > Requirement 2 unnecessary
     - Requirement 3
     
     This pattern is because: ...
     > Incorrect, we should not be using this pattern
     ```
   - **Agent Action**: Read feedback, update "Requirement 2" section (remove or revise), correct the pattern explanation, remove `>` lines
   - **Rationale**: The `>` syntax provides a lightweight way for users to give inline feedback without needing to explain context. Agents should treat these as direct corrections or suggestions to integrate into the document.

9. **CRITICAL: Always update CHANGELOG.md for version changes**
   - ❌ **DO NOT** commit version changes without updating CHANGELOG.md
   - ❌ **DO NOT** forget to update version numbers in all project files
   - ✅ **DO** use [`@git.commit`](agent/commands/git.commit.md) for version-aware commits
   - ✅ **DO** detect version impact: major (breaking), minor (features), patch (fixes)
   - ✅ **DO** update CHANGELOG.md with clear, user-focused descriptions
   - ✅ **DO** update all version files (package.json, AGENT.md, etc.)
   - ✅ **DO** use Conventional Commits format for commit messages
   - **Rationale**: CHANGELOG.md is the primary communication tool for users. Every version change must be documented with clear descriptions of what changed, why it changed, and how it affects users. Forgetting to update CHANGELOG.md breaks the project's version history and makes it impossible for users to understand what changed between versions.

8. **NEVER handle secrets or sensitive data**
   - ❌ **DO NOT** read `.env` files, `.env.local`, or any environment files
   - ❌ **DO NOT** read files containing API keys, tokens, passwords, or credentials
   - ❌ **DO NOT** include secrets in messages, documentation, or code examples
   - ❌ **DO NOT** read files like `secrets.yaml`, `credentials.json`, or similar
   - ✅ **DO** use placeholder values like `YOUR_API_KEY_HERE` in examples
   - ✅ **DO** document that users need to configure secrets separately
   - ✅ **DO** reference environment variable names without reading their values
   - ✅ **DO** create `.env.example` files with placeholder values only
   - **Rationale**: Secrets must never be exposed in chat logs, documentation, or version control. Agents should treat all credential files as off-limits to prevent accidental exposure.

9. **CRITICAL: Respect user's intentional file edits**
   - ❌ **DO NOT** assume missing content needs to be added back
   - ❌ **DO NOT** revert changes without confirming with user
   - ✅ **DO** read files before editing to see current state
   - ✅ **DO** ask user if unexpected changes were intentional
   - ✅ **DO** confirm before reverting user's manual edits
   - **Rationale**: If you read a file and it is missing contents or has changed contents (i.e., it does not contain what you expect), assume or confirm with the user if they made intentional updates that you should not revert. Do not assume "The file is missing <xyz>, I need to add it back". The user may have edited files manually with intention.

10. **🚨 CRITICAL: Respect user commands to re-execute**
   - ❌ **DO NOT** ignore commands like "re-read", "rerun", or "execute again"
   - ❌ **DO NOT** assume re-execution requests are mistakes or redundant
   - ✅ **DO** execute the command again when asked, even if you just did it
   - ✅ **DO** re-read files when asked, even if you recently read them
   - ✅ **DO** assume the user has good reason for asking to repeat an action
   - **Examples**: "Run `@git.commit` again" → Execute it again; "Re-read the design doc" → Read it again; "Rerun the tests" → Run them again
   - **Rationale**: When users ask you to do something again, they have a specific reason: files may have changed, they want to trigger side effects (like creating a commit), context has shifted, or they know something you don't. Always respect these requests and execute them with intention.

---

### Documentation

1. **Write for agents, not humans**
   - Be explicit, not implicit
   - Include code examples
   - Document rationale, not just decisions

2. **Keep documents focused**
   - One topic per document
   - Clear structure
   - Scannable headings

3. **Link related documents**
   - Reference other docs
   - Create knowledge graph
   - Make navigation easy

4. **Update as you go**
   - Don't wait until end
   - Document decisions when made
   - Keep progress.yaml current

### Organization

1. **Follow naming conventions**
   - `{feature}-design.md` for designs
   - `milestone-{N}-{name}.md` for milestones
   - `task-{N}-{name}.md` for tasks
   - `{pattern-name}.md` for patterns

2. **Use consistent structure**
   - Same sections in similar documents
   - Standard YAML format
   - Predictable organization

3. **Keep it DRY**
   - Don't duplicate information
   - Link to canonical source
   - Update in one place

### Progress Tracking

1. **Update frequently**
   - After each task
   - When blockers arise
   - When plans change

2. **Be objective**
   - Use measurable metrics
   - Track actual vs estimated
   - Document deviations

3. **Look forward and back**
   - Document recent work
   - List next steps
   - Note blockers

### Quality

1. **Include verification steps**
   - Every task has checklist
   - Objective criteria
   - Automated where possible

2. **Document patterns**
   - Capture reusable solutions
   - Include anti-patterns
   - Provide examples

3. **Review and refine**
   - Update docs as understanding improves
   - Fix errors immediately
   - Keep docs accurate

---

## Keeping ACP Updated

This repository is actively maintained with improvements to the ACP methodology and documentation. To keep your project's AGENT.md current:

```bash
# Run from your project root (if you have the update script installed)
./agent/scripts/acp.version-update.sh

# Or download and run directly
curl -fsSL https://raw.githubusercontent.com/prmichaelsen/agent-context-protocol/mainline/agent/scripts/acp.version-update.sh | bash
```

The update script will:
1. Create a backup of your current AGENT.md
2. Download the latest version
3. Show you the changes
4. Ask for confirmation before applying

See [CHANGELOG.md](https://github.com/prmichaelsen/agent-context-protocol/blob/main/CHANGELOG.md) for version history and changes.

---

## Conclusion

The Agent Directory Pattern transforms software development from an implicit, memory-dependent process into an explicit, documented system that enables AI agents to work effectively on complex projects.

**Key Takeaways**:

1. **Documentation is Infrastructure** - Treat it with the same care as code
2. **Explicit Over Implicit** - Document everything that matters
3. **Structure Enables Scale** - Organization makes complexity manageable
4. **Agents Need Context** - Provide complete, accessible context
5. **Progress is Measurable** - Track objectively with YAML
6. **Patterns Ensure Quality** - Document and follow best practices
7. **Knowledge Persists** - No more lost tribal knowledge

**When to Use This Pattern**:
- ✅ Complex projects (>1 month)
- ✅ Multiple contributors (agents or humans)
- ✅ Long-term maintenance required
- ✅ Quality and consistency critical
- ✅ Knowledge preservation important

**When NOT to Use**:
- ❌ Trivial scripts (<100 lines)
- ❌ One-off prototypes
- ❌ Throwaway code
- ❌ Simple, well-understood problems

---

## What NOT to Do

### ❌ CRITICAL: Don't Create Summary Documents

**NEVER create these files under ANY circumstances:**
- `TASK_SUMMARY.md`
- `PROJECT_SUMMARY.md`
- `MILESTONE_SUMMARY.md`
- `PROGRESS_SUMMARY.md`
- Any file with `SUMMARY` in the name

**Why**: All summary information belongs in [`progress.yaml`](agent/progress.yaml). Creating separate summary documents:
- Duplicates information
- Creates inconsistency
- Requires maintaining multiple files
- Defeats the purpose of structured progress tracking

**Instead**: Update [`progress.yaml`](agent/progress.yaml):
```yaml
recent_work:
  - date: 2026-02-13
    description: Summary of work completed
    items:
      - ✅ Completed task 1
      - ✅ Completed task 2
```

### ❌ CRITICAL: Don't Create Variant Task Documents

**NEVER create these files under ANY circumstances:**
- `task-1-simplified.md`
- `task-1-revised.md`
- `task-1-v2.md`
- `task-1-updated.md`
- `task-1-alternative.md`

**Why**: Task documents are living documents that should be updated in place. Creating variants:
- Creates confusion about which is current
- Scatters information across multiple files
- Makes progress tracking impossible
- Violates single source of truth principle

**Instead**: Modify the existing task document directly:
```markdown
# Task 1: Setup Project

**Status**: In Progress (Updated 2026-02-13)

## Steps
1. Create directory ✅ (Completed)
2. Install dependencies ✅ (Completed)
3. Configure build (Updated: Changed from webpack to esbuild)

## Notes
- Originally planned to use webpack
- Switched to esbuild for better performance
- Updated configuration accordingly
```

### ✅ Correct Approach

1. **For summaries**: Update [`progress.yaml`](agent/progress.yaml)
2. **For task changes**: Modify existing task documents in place
3. **For major changes**: Update the task and note the changes in [`progress.yaml`](agent/progress.yaml)
4. **For new work**: Create new task documents with new numbers

---

## IMPORTANT: CHANGELOG.md Guidelines

### ❌ CRITICAL: Keep CHANGELOG.md Pure

**CHANGELOG.md must ONLY contain:**
- Version numbers and dates
- Added features
- Changed functionality
- Removed features
- Fixed bugs

**NEVER include in CHANGELOG.md:**
- ❌ Future enhancements or roadmap
- ❌ How-to instructions or usage guides
- ❌ Installation instructions
- ❌ Configuration examples
- ❌ Detailed documentation

**Why**: CHANGELOG.md is a historical record of what changed, not a documentation file. Mixing concerns makes it harder to:
- Understand version history
- Track actual changes
- Maintain the changelog
- Find relevant information

**Correct CHANGELOG.md format:**
```markdown
## [1.0.4] - 2026-02-13

### Added
- New feature X
- New feature Y

### Changed
- Modified behavior of Z

### Removed
- Deprecated feature A
```

**Wrong CHANGELOG.md format:**
```markdown
## [1.0.4] - 2026-02-13

### Added
- New feature X

### How to Use Feature X
[Installation instructions...]  # ❌ WRONG - belongs in README

### Future Enhancements
- Plan to add Y  # ❌ WRONG - belongs in design docs or issues
```

---

**The Agent Pattern is not just documentation—it's a development methodology that makes complex software projects tractable for AI agents.**

---

*For questions or improvements to this pattern, please contribute to the repository or create an issue.*
