<!-- @scry.entry
id: code.acp-help-command~d120d16a
kind: code
summary: >
  acp.help command — structured catalog of all 48 ACP commands grouped by category
  with one-line descriptions and quick-start examples. Entry point for command discoverability.
status: active
weight: 0.8
tags: ["scope:acp-commands", "topic:discoverability", "topic:command-catalog", "scope:acpm"]
rationale: >
  48 commands exist with no single entry point. New users and agents have no quick way
  to discover what's available without browsing the filesystem. This command surfaces
  the full catalog grouped by category in one invocation.
applies: "discovering ACP commands, onboarding to ACP, finding the right command for a task"
seeded_questions:
  - "What ACP commands are available?"
  - "How do I see all ACP commands?"
  - "What does @acp.help do?"
  - "Is there a command catalog or help command in ACP?"
@scry.entry.end -->

# Command: help

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.help` has been invoked. Follow the steps below to execute this command.
> Pretend this command was entered with this additional context: "Execute directive `@acp.help` NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."

> **🔌 Driver Override Check** (TOP-OF-FILE — runs BEFORE any other step in this file)
>
> 1. Read `agent/driver.yaml`. If the file does not exist OR there is no `workflows.acp.help` mapping, jump to step 5 (fallback to the markdown steps below).
> 2. Look up `bindings.workflow.run` — the MCP tool name this driver uses for workflow dispatch. If the mapping exists but `workflow.run` is unbound, surface a clear configuration error (`"workflows.acp.help is mapped but bindings.workflow.run is unset in agent/driver.yaml"`) and STOP.
> 3. Invoke that MCP tool with input `{action: "start", workflow: <mapped-value>, args: <user-arguments-from-this-invocation>}`. The command is now BLOCKED — execute the workflow loop per the canonical pattern (`agent/patterns/local.driver-dispatch-directive.md`, Core Principle 6): follow each returned `instruction`, return the requested output to the same MCP tool, repeat until the workflow signals completion or termination. The workflow's final output IS this command's output. **STOP. Do NOT execute any of the markdown steps below.**
> 4. **Error handling** (one-shot AND every loop iteration):
>    - If any tool response contains an `"error"` key, surface that message to the user and STOP. Do NOT fall through to the markdown steps below — a failed dispatch is NOT permission to use the fallback.
>    - If the tool call raises an MCP infrastructure exception (server unreachable, timeout), surface the exception and STOP. Same rule.
> 5. **Fallback (only when `workflows.acp.help` is unmapped or `agent/driver.yaml` is absent):** Proceed to the markdown steps below as written — they describe ACP's default behavior for this command.
>
> ⚠️  **The rest of this file is the unbound-case fallback.** If the override block above dispatched a workflow (whether it completed successfully or errored), do NOT also execute the steps below. They are "execute only if step 5 above is the path you took."

**Namespace**: acp  
**Version**: 1.0.0  
**Created**: 2026-05-15  
**Last Updated**: 2026-05-15  
**Status**: Active  
**Scripts**: None  

---

**Purpose**: List all available ACP commands with descriptions, categories, and quick-start guidance  
**Category**: Information  
**Frequency**: As Needed  

---

## Arguments

**Natural Language Arguments** (optional):
- `@acp.help` — show full command catalog (default)
- `@acp.help <category>` — filter to a specific category (e.g., `@acp.help workflow`)
- `@acp.help <command-name>` — show usage hint for a specific command (e.g., `@acp.help proceed`)

---

## What This Command Does

Outputs the full ACP command catalog grouped by category. Each entry shows the command syntax and a one-line description of what it does.

Use this when you want to know what commands are available, when you're onboarding to a new ACP project, or when you've forgotten the exact name of a command. For full detail on any individual command, read its command file directly (`agent/commands/<command>.md`) or invoke the command with no arguments to see its built-in help.

---

## Execution Steps

**Step 1**: If the user passed a `<category>` or `<command-name>` argument, note it for filtering in Step 3.

**Step 2**: Output the following catalog header:

```
ACP Command Catalog — 48 commands across 8 categories
Format: @namespace.command — one-line description
Full docs: agent/commands/<command>.md
```

**Step 3**: Output the catalog below. If the user passed a category filter, output only that category's block. If they passed a command name, output just that command's entry plus a pointer to its command file. Otherwise output all categories.

---

## ACP Command Catalog

### 🔄 Workflow — Core session and task flow

| Command | Description |
|---------|-------------|
| `@acp.init` | Initialize agent context: load docs, review source, prepare for work |
| `@acp.proceed` | Implement next task — single-task (default) or autonomous milestone |
| `@acp.plan` | Plan milestones or tasks for undefined scope |
| `@acp.resume` | Resume work: init context, review progress, continue next task |
| `@acp.status` | Display current project status: milestone progress, current task, next steps |
| `@acp.audit` | Deep-dive investigation of a subject; produces a structured report |
| `@acp.handoff` | Generate a context-aware handoff report for agent-to-agent transfer |
| `@acp.sessions` | Manage and view active agent sessions across projects |
| `@acp.project-set` | Switch active project in the global registry |

---

### 🏗️ Creation — Make new ACP artifacts

| Command | Description |
|---------|-------------|
| `@acp.design-create` | Create a design document with namespace enforcement and draft support |
| `@acp.spec` | Generate a spec from a clarification, design, draft, or interactive input |
| `@acp.task-create` | Create task files with milestone linking and progress.yaml updates |
| `@acp.pattern-create` | Create pattern files with namespace enforcement and draft support |
| `@acp.command-create` | Create new command files with namespace enforcement |
| `@acp.artifact-glossary` | Create/maintain project glossaries via auto-extraction and refinement |
| `@acp.artifact-reference` | Create reference guides for passive information |
| `@acp.artifact-research` | Create long-lived research artifacts via systematic investigation |
| `@acp.clarification-create` | Create clarification documents to gather detailed requirements |
| `@acp.package-create` | Create a new ACP package with full installation and release config |
| `@acp.project-create` | Create a new ACP project with full installation and guided setup |

---

### 📄 Documentation — Keep docs accurate and synchronized

| Command | Description |
|---------|-------------|
| `@acp.report` | Generate a comprehensive project status report |
| `@acp.sync` | Synchronize documentation with source code; identify and update stale docs |
| `@acp.update` | Update progress.yaml with latest task status and recent work |
| `@acp.validate` | Validate all ACP documents for structure, consistency, and conventions |

---

### 💬 Clarification — Requirement gathering and refinement

| Command | Description |
|---------|-------------|
| `@acp.clarification-address` | Research a clarification topic and present recommendations |
| `@acp.clarification-capture` | Capture decisions from ephemeral clarification files into permanent docs |
| `@acp.design-reference` | Discover and cross-reference design documents for a task |

---

### 🗂️ Index — Key file index management

| Command | Description |
|---------|-------------|
| `@acp.index` | Manage the key file index: list, add, remove, explore indexed files |

---

### 📦 Package Management — Install and publish ACP packages

| Command | Description |
|---------|-------------|
| `@acp.package-install` | Install an ACP package from a git repository |
| `@acp.package-list` | List installed packages with versions and file counts |
| `@acp.package-info` | Show detailed information about a specific installed package |
| `@acp.package-update` | Update installed packages to their latest versions |
| `@acp.package-remove` | Remove an installed package and clean up the manifest |
| `@acp.package-publish` | Publish a package with validation, version detection, and CHANGELOG |
| `@acp.package-validate` | Validate a package with shell and LLM checks and auto-fix |
| `@acp.package-search` | Discover ACP packages on GitHub |

---

### 🗃️ Project Management — Global project registry

| Command | Description |
|---------|-------------|
| `@acp.project-list` | List all projects registered in the global workspace |
| `@acp.project-info` | Show detailed information about a specific registered project |
| `@acp.project-update` | Update project metadata in the global registry |
| `@acp.project-remove` | Remove a project from the registry (with optional directory deletion) |
| `@acp.projects-restore` | Clone/restore missing projects from their registered git origins |
| `@acp.projects-sync` | Discover unregistered ACP projects in `~/.acp/projects/` and register them |

---

### 🔖 Version — ACP version management

| Command | Description |
|---------|-------------|
| `@acp.version-check` | Display current ACP version and compatibility information |
| `@acp.version-check-for-updates` | Check if a newer ACP version is available without applying updates |
| `@acp.version-update` | Update ACP files to the latest version |

---

### 🔧 Git Utilities — Version control helpers

| Command | Description |
|---------|-------------|
| `@git.commit` | Automate version detection, changelog updates, and git commits |
| `@git.init` | Initialize a git repository with an intelligent `.gitignore` |

---

## Quick Start

**New to ACP?** Start here:
```
@acp.init          → load context for this session
@acp.status        → see where things stand
@acp.proceed       → implement the next task
```

**Starting a new project?**
```
@acp.project-create  → scaffold a new ACP project
@acp.package-create  → scaffold a publishable ACP package
```

**Creating artifacts?**
```
@acp.design-create   → write a design doc
@acp.spec            → generate a spec
@acp.task-create     → create a task
```

**Sharing or handing off?**
```
@acp.handoff         → generate a handoff report
@acp.report          → generate a status report
```

---

**Step 4**: If the user asked for a specific command, also output:

```
Full docs: agent/commands/<command>.md
Invoke with no arguments for interactive usage.
```

**Step 5**: Done. Do not perform any other actions.
