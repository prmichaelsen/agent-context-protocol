# Global Package Installation

**Concept**: Install ACP packages globally to `~/.acp/packages/` for package development and global command library  
**Created**: 2026-02-21  
**Updated**: 2026-02-21  
**Status**: Design Specification  
**Priority**: Medium  
**Estimated Effort**: 6-8 hours  

---

## Overview

Enable users to install ACP packages globally to `~/.acp/packages/` where they are tracked in `~/.acp/manifest.yaml`. Global packages serve two primary purposes:

1. **Package Development**: Developers can work on packages in `~/.acp/packages/` with full ACP tooling
2. **Global Command Library**: Agents can discover and use commands/patterns from globally installed packages

Global packages are **independent** from project dependencies. Projects do not depend on global packages - they are an optional discovery mechanism for agents.

---

## Problem Statement

### Current Limitations

1. **No Package Development Environment**: Package developers must create packages in arbitrary directories without ACP tooling support
2. **No Global Command Discovery**: Agents cannot discover reusable commands/patterns outside the current project
3. **No Centralized Package Location**: No standard location for globally available packages

### User Pain Points

**Scenario 1**: Package Development  
- Currently: Create package in random directory, manually set up structure
- Desired: Use `@acp.package-create` to create in `~/.acp/packages/`, work with full ACP tooling

**Scenario 2**: Global Command Library  
- Currently: Common commands (like git helpers) must be copied to each project
- Desired: Install once globally, agents can discover via `~/.acp/manifest.yaml`

**Scenario 3**: Command Discovery  
- Currently: Agents only see commands in current project's `./agent/commands/`
- Desired: Agents can also discover commands from `~/.acp/packages/` when needed

---

## Solution

### High-Level Design

```
Global Installation:
  @acp.package-install --global {repo-url}
      ↓
  Install to ~/.acp/packages/{package-name}/
      ↓
  Track in global manifest: ~/.acp/manifest.yaml
      ↓
  Done (no symlinks, no project manifest updates)

Agent Discovery:
  Agent working in any directory
      ↓
  Reads ~/.acp/manifest.yaml to discover global packages
      ↓
  Can reference commands like @namespace.command
      ↓
  Local packages take precedence over global

Local Installation (existing, unchanged):
  @acp.package-install {repo-url}
      ↓
  Install to ./agent/patterns/, ./agent/commands/, ./agent/designs/
      ↓
  Track in project manifest: ./agent/manifest.yaml
```

### Directory Structure

```
~/.acp/
├── AGENT.md                     # Instructions for agents to read manifest
├── manifest.yaml                # Global package manifest (standard format)
├── packages/                    # Global packages
│   ├── @prmichaelsen/
│   │   └── acp-firebase/
│   │       ├── package.yaml
│   │       ├── AGENT.md
│   │       └── agent/
│   │           ├── patterns/
│   │           │   └── firebase.firestore-pattern.md
│   │           └── commands/
│   │               └── firebase.deploy.md
│   ├── @prmichaelsen/
│   │   └── acp-git/
│   │       ├── package.yaml
│   │       └── agent/
│   │           └── commands/
│   │               ├── git.commit.md
│   │               └── git.init.md
│   └── @someorg/
│       └── acp-mcp/
│           ├── package.yaml
│           └── agent/
│               └── commands/
│                   └── mcp.bootstrap.md
└── projects/                    # Optional: User projects (future monorepo support)
    ├── my-app/
    └── another-project/

# Projects remain independent
/home/user/my-project/
└── agent/
    ├── commands/                # Local commands (take precedence)
    ├── patterns/
    └── manifest.yaml            # Only tracks LOCAL packages
```

---

## Implementation

### 1. Global Manifest

**Location**: `~/.acp/manifest.yaml`  

**Structure**:
```yaml
# Global ACP Package Manifest
version: 1.0.0
updated: 2026-02-21T03:28:00Z

packages:
  firebase:
    name: firebase
    version: 1.2.0
    source: https://github.com/user/acp-firebase.git
    commit: abc123
    installed: 2026-02-21T03:28:00Z
    updated: 2026-02-21T03:28:00Z
    location: /home/user/.acp/packages/firebase
    files:
      patterns:
        - name: firebase.firestore-pattern.md
          version: 1.0.0
          checksum: sha256:...
      commands:
        - name: firebase.deploy.md
          version: 1.0.0
          checksum: sha256:...
```

### 2. AGENT.md for Global Discovery

**Location**: `~/.acp/AGENT.md`  

**Content**:
```markdown
# ACP Global Packages

This directory contains globally installed ACP packages.

## For Agents

When working in any project, you can discover globally installed packages by reading `~/.acp/manifest.yaml`.

Global packages provide:
- Commands (in `~/.acp/packages/{package}/agent/commands/`)
- Patterns (in `~/.acp/packages/{package}/agent/patterns/`)
- Design documents (in `~/.acp/packages/{package}/agent/design/`)

**Namespace Precedence**: Local packages always take precedence over global packages. If both local and global packages define `@firebase.deploy`, use the local version.  

## Discovery

To see available global packages:
1. Read `~/.acp/manifest.yaml`
2. Each package entry contains the package location
3. Navigate to package directories to see available commands/patterns
```

### 3. Project Manifest (Unchanged)

**Project manifests remain independent**:
```yaml
# ./agent/manifest.yaml (in project directory)
version: 1.0.0
updated: 2026-02-21T04:00:00Z

packages:
  firebase:
    name: firebase
    version: 1.2.0
    source: https://github.com/user/acp-firebase.git
    # NO global reference - this is a LOCAL installation
    files:
      patterns:
        - name: firebase.firestore-pattern.md
          version: 1.0.0
          checksum: sha256:...
```

### 4. Installation Flags

**@acp.package-install enhancements**:
```bash
# Global installation
@acp.package-install --global {repo-url}
@acp.package-install -g {repo-url}

# Local installation (existing, default)
@acp.package-install {repo-url}
```

**Script changes**:
```bash
# Parse --global flag
GLOBAL_INSTALL=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --global|-g)
            GLOBAL_INSTALL=true
            shift
            ;;
        *)
            REPO_URL=$1
            shift
            ;;
    esac
done

# Determine installation directory
if [ "$GLOBAL_INSTALL" = true ]; then
    INSTALL_DIR="$HOME/.acp/packages/${PACKAGE_NAME}"
    MANIFEST_FILE="$HOME/.acp/manifest.yaml"
else
    INSTALL_DIR="./agent"
    MANIFEST_FILE="./agent/manifest.yaml"
fi
```

### 5. Agent Discovery Mechanism

**Agents discover global packages by**:
1. Reading `~/.acp/manifest.yaml` to see installed packages
2. Navigating to package directories (e.g., `~/.acp/packages/@prmichaelsen/acp-firebase/`)
3. Reading package AGENT.md and command/pattern files
4. Using commands via `@namespace.command` syntax

**Namespace Resolution**:
- Local packages take precedence over global
- If `./agent/commands/firebase.deploy.md` exists locally, use it
- Otherwise, check `~/.acp/packages/*/agent/commands/firebase.deploy.md`

### 6. Update Commands

**Commands to enhance**:
- [`@acp.init`](../commands/acp.init.md) - Add step to read `~/.acp/manifest.yaml` and report globally installed packages
- [`@acp.package-install`](../commands/acp.package-install.md) - Add `--global` flag (installs to `~/.acp/packages/`)
- [`@acp.package-list`](../commands/acp.package-list.md) - Add `--global` flag to list global packages
- [`@acp.package-update`](../commands/acp.package-update.md) - Add `--global` flag to update global packages
- [`@acp.package-remove`](../commands/acp.package-remove.md) - Add `--global` flag to remove from `~/.acp/packages/`
- [`@acp.package-info`](../commands/acp.package-info.md) - Add `--global` flag to show global package info

---

## Benefits

### 1. Package Development Environment
- Standard location for package development (`~/.acp/packages/`)
- Full ACP tooling available (commands, validation, publishing)
- Easy to manage and organize packages

### 2. Global Command Library
- Common commands available across all projects
- No need to copy commands to each project
- Agents can discover via `~/.acp/manifest.yaml`

### 3. Optional Discovery
- Projects remain independent (no dependencies on global packages)
- Local packages always take precedence
- Global packages are purely for convenience

### 4. Future Monorepo Support
- `~/.acp/projects/` directory for project organization
- Enables future monorepo management features
- Centralized location for all ACP-related work

---

## Trade-offs

### 1. Discovery Overhead
**Trade-off**: Agents must read `~/.acp/manifest.yaml` to discover global packages  

**Mitigation**:
- Manifest is small and fast to read
- Only read when needed (not on every command)
- Clear documentation in `~/.acp/AGENT.md`

### 2. No Automatic Updates
**Trade-off**: Updating global packages doesn't affect projects (they use local packages)  

**Benefit**: This is actually a feature - projects remain stable and independent  

### 3. Namespace Collisions
**Trade-off**: Global and local packages might have same namespace  

**Mitigation**:
- Local always takes precedence
- Clear precedence rules documented
- Agents can check both locations if needed

### 4. Manual Discovery
**Trade-off**: Agents must explicitly look for global packages  

**Mitigation**:
- Document in AGENT.md to read `~/.acp/manifest.yaml`
- Provide clear examples of global package usage
- Make discovery pattern simple and consistent

---

## Implementation Plan

### Phase 1: Global Infrastructure (2-3 hours)
1. Create `~/.acp/` directory structure
2. Create `~/.acp/AGENT.md` with discovery instructions
3. Create `~/.acp/manifest.yaml` (standard format)
4. Add global manifest functions to acp.common.sh

### Phase 2: Global Installation (2-3 hours)
1. Add `--global` flag parsing to acp.package-install.sh
2. Implement installation to `~/.acp/packages/{package-name}/`
3. Update global manifest after installation
4. Test global installation workflow

### Phase 3: Update Commands (2-3 hours)
1. Update `@acp.init` to read and report global packages from `~/.acp/manifest.yaml`
2. Update `@acp.package-list --global` to read global manifest
3. Update `@acp.package-update --global` to update in `~/.acp/packages/`
4. Update `@acp.package-remove --global` to remove from global location
5. Update `@acp.package-info --global` to show global package details

### Phase 4: Documentation (1-2 hours)
1. Update AGENT.md with global package discovery instructions
2. Update command documentation with `--global` examples
3. Document namespace precedence rules
4. Add troubleshooting guide

---

## Usage Examples

### Install Package Globally

```bash
# Install git helpers package globally
@acp.package-install --global https://github.com/prmichaelsen/acp-git.git

# Output:
# Installing acp-git globally to ~/.acp/packages/@prmichaelsen/acp-git/
# ✓ Package installed globally
# ✓ Updated ~/.acp/manifest.yaml
#
# Global package installed. Agents can now discover this package by reading ~/.acp/manifest.yaml
```

### List Global Packages

```bash
@acp.package-list --global

# Output:
# Global Packages (installed to ~/.acp/packages/):
#
#   @prmichaelsen/acp-git (v1.0.0)
#     Location: ~/.acp/packages/@prmichaelsen/acp-git
#     2 commands: git.commit, git.init
#
#   @prmichaelsen/acp-firebase (v1.2.0)
#     Location: ~/.acp/packages/@prmichaelsen/acp-firebase
#     3 patterns, 2 commands
```

### Discover Global Commands (Agent Behavior)

```markdown
# Agent working in /home/user/my-project/

# Automatic discovery via @acp.init:
1. User runs: @acp.init
2. Agent reads: ~/.acp/manifest.yaml (if exists)
3. Agent reports: "Global packages available: @prmichaelsen/acp-git (2 commands), @prmichaelsen/acp-firebase (3 patterns, 2 commands)"
4. Agent loads context from both local and global packages

# Manual command invocation:
1. User types: @git.commit
2. Agent checks: ./agent/commands/git.commit.md (not found locally)
3. Agent reads: ~/.acp/manifest.yaml (discovers acp-git package)
4. Agent reads: ~/.acp/packages/@prmichaelsen/acp-git/agent/commands/git.commit.md
5. Agent executes command
```

### Update Global Package

```bash
@acp.package-update --global @prmichaelsen/acp-git

# Output:
# Updating global package: @prmichaelsen/acp-git
# Current: v1.0.0
# Latest: v1.1.0
#
# Continue? (y/N): y
#
# ✓ Updated @prmichaelsen/acp-git to v1.1.0
# ✓ Updated ~/.acp/manifest.yaml
#
# Note: Projects using local installations are not affected
```

### Remove Global Package

```bash
@acp.package-remove --global @prmichaelsen/acp-git

# Output:
# Removing global package: @prmichaelsen/acp-git
# Location: ~/.acp/packages/@prmichaelsen/acp-git
#
# Continue? (y/N): y
#
# ✓ Removed package from ~/.acp/packages/
# ✓ Updated ~/.acp/manifest.yaml
#
# Note: This does not affect any project-local installations
```

---

## Future Enhancements

### Monorepo Management
- Use `~/.acp/projects/` for project organization
- Commands to manage multiple projects
- Shared configurations across projects

### Smart Discovery
- Cache global manifest for faster lookups
- Index global commands for quick search
- Suggest global packages when command not found locally

### Package Recommendations
- Suggest installing commonly used packages globally
- Show which packages would benefit from global installation
- Analytics on package usage patterns

---

## Related Documents

- [`agent/design/acp-package-management-system.md`](acp-package-management-system.md)
- [`agent/commands/acp.package-install.md`](../commands/acp.package-install.md)
- [`agent/tasks/task-6-selective-installation.md`](../tasks/task-6-selective-installation.md)

---

**Status**: Design Specification - Implementation Ready  
**Recommendation**: Implement in Milestone 5 (Global Package Installation)  
**Next Steps**:
1. ✅ Task files created (tasks 25-28)
2. ✅ progress.yaml updated with Milestone 5
3. 📋 Begin implementation with Task 25 (Global Infrastructure Setup)
