# ACP Package Management System

**Concept**: Comprehensive package management for ACP modules with versioning, selective installation, and dependency tracking  
**Created**: 2026-02-18  
**Status**: Design Specification  
**Priority**: High  
**Estimated Effort**: 15-20 hours  

---

## Table of Contents

1. [Overview](#overview)
2. [Problem Statement](#problem-statement)
3. [Solution Architecture](#solution-architecture)
4. [Package Structure](#package-structure)
5. [Manifest System](#manifest-system)
6. [Versioning Strategy](#versioning-strategy)
7. [Installation System](#installation-system)
8. [Update System](#update-system)
9. [Command Specifications](#command-specifications)
10. [Implementation Plan](#implementation-plan)
11. [Examples](#examples)

---

## Overview

The ACP Package Management System enables distribution, installation, and maintenance of reusable ACP modules (patterns, commands, designs) through GitHub repositories. It provides npm-like package management for documentation and agent directives.

### Key Features

- ✅ **Package Distribution** - Share patterns and commands via GitHub
- ✅ **Selective Installation** - Install specific files or entire packages
- ✅ **Version Tracking** - Track package and file-level versions
- ✅ **Smart Updates** - Update only changed files, detect conflicts
- ✅ **Dependency Management** - Handle package dependencies
- ✅ **Manifest Tracking** - Track installed packages in `agent/manifest.yaml`

---

## Problem Statement

### Current Limitations

1. **No Package Ecosystem** - Each project reinvents patterns
2. **Manual Sharing** - Copy-paste patterns between projects
3. **No Version Control** - Can't track which version of patterns are installed
4. **No Updates** - No way to update installed patterns
5. **All or Nothing** - Can't selectively install specific patterns
6. **No Dependencies** - Can't express that one pattern requires another

### User Pain Points

**Scenario 1**: Developer wants Firebase patterns  
- Currently: Copy-paste from another project, hope it's current
- Desired: `@acp.package-install acp-firebase` and get latest patterns

**Scenario 2**: Pattern updated with bug fix  
- Currently: Manually check for updates, copy-paste again
- Desired: `@acp.package-update` and get latest versions

**Scenario 3**: Only need one pattern from package  
- Currently: Install everything or manually extract
- Desired: `@acp.package-install acp-firebase --patterns user-scoped-collections`

---

## Solution Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     GitHub Repositories                          │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐   │
│  │  acp-firebase  │  │ acp-mcp-integ  │  │   acp-oauth    │   │
│  │                │  │                │  │                │   │
│  │  package.yaml  │  │  package.yaml  │  │  package.yaml  │   │
│  │  agent/        │  │  agent/        │  │  agent/        │   │
│  │    patterns/   │  │    patterns/   │  │    patterns/   │   │
│  │    commands/   │  │    commands/   │  │    commands/   │   │
│  │    designs/    │  │    designs/    │  │    designs/    │   │
│  └────────────────┘  └────────────────┘  └────────────────┘   │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ git clone
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Local Project                                 │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  agent/manifest.yaml (Manifest)                            │ │
│  │  - Tracks installed packages                               │ │
│  │  - Package versions                                        │ │
│  │  - File versions                                           │ │
│  │  - Installation dates                                      │ │
│  │  - Local modifications                                     │ │
│  └────────────────────────────────────────────────────────────┘ │
│                             │                                    │
│                             │ installs to                        │
│                             ▼                                    │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  agent/                                                    │ │
│  │    patterns/                                               │ │
│  │      user-scoped-collections.md (from acp-firebase)        │ │
│  │      mcp-integration-patterns.md (from acp-mcp-integ)      │ │
│  │      oauth-integration.md (from acp-oauth)                 │ │
│  │    commands/                                               │ │
│  │      firebase.init.md (from acp-firebase)                  │ │
│  │      mcp.create-server.md (from acp-mcp-integ)             │ │
│  │    designs/                                                │ │
│  │      firebase-architecture.md (from acp-firebase)          │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## Package Structure

### Repository Structure

Each package repository follows this structure:

```
acp-firebase/
├── README.md                    # Package documentation
├── LICENSE                      # Package license
├── CHANGELOG.md                 # Package changelog
├── package.yaml                 # Package metadata
└── agent/                       # ACP content
    ├── patterns/
    │   ├── user-scoped-collections.md
    │   ├── firebase-security-rules.md
    │   └── firestore-queries.md
    ├── commands/
    │   ├── firebase.init.md
    │   └── firebase.migrate.md
    └── design/
        └── firebase-architecture.md
```

### Package Metadata (`package.yaml`)

```yaml
# package.yaml
name: firebase
version: 1.2.0
description: Firebase patterns and utilities for ACP projects
author: Patrick Michaelsen
license: MIT
homepage: https://github.com/prmichaelsen/acp-firebase
repository: https://github.com/prmichaelsen/acp-firebase.git

# Package contents
contents:
  patterns:
    - name: user-scoped-collections.md
      version: 1.1.0
      description: User-scoped Firestore data organization
    
    - name: firebase-security-rules.md
      version: 1.0.0
      description: Security rules templates
    
    - name: firestore-queries.md
      version: 1.0.0
      description: Efficient query patterns
  
  commands:
    - name: firebase.init.md
      version: 1.0.0
      description: Initialize Firebase in project
    
    - name: firebase.migrate.md
      version: 1.0.0
      description: Migrate to user-scoped collections
  
  designs:
    - name: firebase-architecture.md
      version: 1.0.0
      description: Firebase integration architecture

# Dependencies (other ACP packages required)
dependencies:
  - name: acp-typescript
    version: ">=1.0.0"
    required: true

# Compatibility
requires:
  acp: ">=1.1.0"
  node: ">=18.0.0"
  
  # Project dependencies (npm/pip/cargo/etc)
  npm:
    firebase-admin: "^11.0.0 || ^12.0.0"
    "@prmichaelsen/firebase-admin-sdk-v8": ">=2.0.0"
  
  # Alternative package managers
  pnpm:
    firebase-admin: "^11.0.0 || ^12.0.0"
  
  yarn:
    firebase-admin: "^11.0.0 || ^12.0.0"

# Tags for discovery
tags:
  - firebase
  - firestore
  - database
  - backend
```

---

## Manifest System

### Local Manifest (`agent/manifest.yaml`)

Tracks installed packages in the local project:

```yaml
# agent/manifest.yaml
# Tracks installed ACP packages and their versions

packages:
  firebase:
    # Package metadata
    source: https://github.com/prmichaelsen/acp-firebase.git
    package_version: 1.2.0
    commit: a1b2c3d4e5f6
    installed_at: 2026-02-18T10:30:00Z
    updated_at: 2026-02-18T10:30:00Z
    
    # Installed files with individual versions
    installed:
      patterns:
        - name: user-scoped-collections.md
          version: 1.1.0
          installed_at: 2026-02-18T10:30:00Z
          modified: false
          checksum: sha256:abc123...
        
        - name: firebase-security-rules.md
          version: 1.0.0
          installed_at: 2026-02-18T10:30:00Z
          modified: true  # User modified this file
          checksum: sha256:def456...
      
      commands:
        - name: firebase.init.md
          version: 1.0.0
          installed_at: 2026-02-18T10:30:00Z
          modified: false
          checksum: sha256:ghi789...
      
      designs:
        - name: firebase-architecture.md
          version: 1.0.0
          installed_at: 2026-02-18T10:30:00Z
          modified: false
          checksum: sha256:jkl012...
  
  mcp-integration:
    source: https://github.com/prmichaelsen/acp-mcp-integration.git
    package_version: 2.0.1
    commit: b2c3d4e5f6g7
    installed_at: 2026-02-15T14:20:00Z
    updated_at: 2026-02-18T10:35:00Z
    installed:
      patterns:
        - name: mcp-integration-patterns.md
          version: 2.0.0
          installed_at: 2026-02-18T10:35:00Z
          modified: false
          checksum: sha256:mno345...
      commands:
        - name: mcp.create-oauth-server.md
          version: 1.0.0
          installed_at: 2026-02-15T14:20:00Z
          modified: false
          checksum: sha256:pqr678...

# Manifest metadata
manifest_version: 1.0.0
last_updated: 2026-02-18T10:35:00Z
```

---

## Versioning Strategy

### Two-Level Versioning

#### Package-Level Version (Semantic)
**Purpose**: Track the package as a whole  

```yaml
package_version: 1.2.0
```

**Semantic Versioning**:
- **Major (2.0.0)**: Breaking changes to any file
- **Minor (1.2.0)**: New files added, non-breaking updates
- **Patch (1.2.1)**: Bug fixes, typo corrections

#### File-Level Version (Granular)
**Purpose**: Track individual file changes  

```markdown
# patterns/user-scoped-collections.md

**Version**: 1.1.0  
**Last Updated**: 2026-02-18  
```

**When to Bump**:
- Content changes
- Steps added/removed
- Prerequisites updated
- Examples modified

### Version Comparison

```
Package firebase 1.2.0 includes:
  - user-scoped-collections.md v1.1.0 (updated from 1.0.0)
  - firebase-security-rules.md v1.0.0 (unchanged)
  - firestore-queries.md v1.0.0 (unchanged)
  - firestore-pagination.md v1.0.0 (NEW)
```

### Checksum Tracking

Track file checksums to detect local modifications:

```yaml
- name: user-scoped-collections.md
  version: 1.1.0
  checksum: sha256:abc123def456...
  modified: false  # Checksum matches original
```

---

## Installation System

### Installation Modes

#### Mode 1: Full Package Installation
```bash
@acp.package-install https://github.com/prmichaelsen/acp-firebase.git

# Installs: All patterns, commands, and designs
# Updates: agent/manifest.yaml with full package entry
```

#### Mode 2: Type-Selective Installation
```bash
@acp.package-install https://github.com/prmichaelsen/acp-firebase.git --patterns

# Installs: Only patterns/
# Updates: agent/manifest.yaml with patterns only
```

#### Mode 3: File-Selective Installation
```bash
@acp.package-install https://github.com/prmichaelsen/acp-firebase.git \
  --patterns user-scoped-collections firebase-security-rules

# Installs: Only specified patterns
# Updates: agent/manifest.yaml with selected files only
```

#### Mode 4: Manifest-Based Installation
```bash
# No arguments - installs from manifest
@acp.package-install

# Behavior:
# 1. Check if agent/manifest.yaml exists
# 2. If yes: Install packages listed but not yet installed
# 3. If no: Show error "No manifest found. Provide repository URL."

# Installs: Missing packages from manifest
# Updates: agent/manifest.yaml with installation metadata
```

### Installation Flow

```
1. Parse command arguments
   ├─→ Repository URL
   ├─→ Installation options (--patterns, --commands, etc.)
   └─→ Specific files (if any)

2. Clone repository
   ├─→ Clone entire repository
   └─→ Clone to temporary location

3. Read package metadata
   ├─→ Parse package.yaml from repository
   ├─→ Validate package structure
   └─→ Check compatibility (ACP version, Node version)

4. Determine files to install
   ├─→ If no options: Install everything
   ├─→ If --patterns: Install all patterns or specified ones
   ├─→ If --commands: Install all commands or specified ones
   └─→ If --designs: Install all designs or specified ones

5. Check for conflicts
   ├─→ Compare with existing files
   ├─→ Check agent/manifest.yaml for existing package
   ├─→ Detect version conflicts
   └─→ Prompt user for resolution

6. Install files
   ├─→ Copy files to agent/ directories
   ├─→ Calculate checksums
   └─→ Preserve file metadata

7. Update manifest
   ├─→ Add/update package entry in agent/manifest.yaml
   ├─→ Record installed files with versions
   ├─→ Save installation timestamp
   └─→ Calculate and save checksums

8. Cleanup
   ├─→ Remove temporary clone
   └─→ Report installation summary
```

---

## Update System

### Update Detection

```bash
@acp.package-update --check

# Process:
# 1. Read agent/manifest.yaml
# 2. For each package:
#    - Fetch latest package.yaml from repository
#    - Compare package_version
#    - Compare file versions
#    - Detect new files
#    - Detect removed files
# 3. Report available updates
```

### Update Flow

```
1. Fetch latest package metadata
   ├─→ Clone repository (or fetch if already cloned)
   ├─→ Read package.yaml
   └─→ Compare with local manifest

2. Detect changes
   ├─→ Package version changed?
   ├─→ Which files updated?
   ├─→ Which files added?
   └─→ Which files removed?

3. Check for local modifications
   ├─→ Calculate current checksums
   ├─→ Compare with manifest checksums
   ├─→ Identify modified files
   └─→ Warn about conflicts

4. Present update plan
   ├─→ Show version changes
   ├─→ List file changes
   ├─→ Highlight conflicts
   └─→ Ask for confirmation

5. Apply updates
   ├─→ Update unmodified files
   ├─→ Skip or prompt for modified files
   ├─→ Add new files
   ├─→ Remove deleted files (with confirmation)
   └─→ Update manifest

6. Report results
   ├─→ Show what was updated
   ├─→ Show what was skipped
   └─→ Show any errors
```

---

## Command Specifications

### `@acp.package-install`

**Purpose**: Install ACP packages from GitHub repositories  

**Syntax**:
```bash
# Install from repository
@acp.package-install <repo-url> [options]

# Install from manifest (no arguments)
@acp.package-install

Options:
  --patterns [files...]    Install patterns (all if no files specified)
  --commands [files...]    Install commands (all if no files specified)
  --designs [files...]     Install designs (all if no files specified)
  --list                   List available files without installing
  -y, --yes               Auto-confirm (skip prompts)
```

**Examples**:
```bash
# Install entire package
@acp.package-install https://github.com/prmichaelsen/acp-firebase.git

# Install only patterns
@acp.package-install https://github.com/prmichaelsen/acp-firebase.git --patterns

# Install specific patterns
@acp.package-install https://github.com/prmichaelsen/acp-firebase.git \
  --patterns user-scoped-collections firebase-security-rules

# List available files
@acp.package-install https://github.com/prmichaelsen/acp-firebase.git --list

# Install from manifest (no arguments)
@acp.package-install
```

---

### `@acp.package-update`

**Purpose**: Update installed packages to latest versions  

**Syntax**:
```bash
# Update specific package
@acp.package-update <package-name> [options]

# Update all packages (no arguments)
@acp.package-update

Options:
  --check                  Check for updates without installing
  -y, --yes               Auto-confirm (skip prompts)
  --force                  Overwrite modified files
  --skip-modified          Skip files modified locally
```

**Examples**:
```bash
# Check for updates (all packages)
@acp.package-update --check

# Update all packages (no arguments)
@acp.package-update

# Update specific package
@acp.package-update firebase

# Update with auto-confirm
@acp.package-update firebase -y

# Update and skip modified files
@acp.package-update --skip-modified
```

---

### `@acp.package-list`

**Purpose**: List installed packages and their details  

**Syntax**:
```bash
@acp.package-list [options]

Options:
  --verbose, -v           Show detailed file information
  --outdated              Show only packages with updates available
```

**Examples**:
```bash
# List all packages
@acp.package-list

# Show detailed information
@acp.package-list --verbose

# Show only outdated packages
@acp.package-list --outdated
```

---

### `@acp.package-remove`

**Purpose**: Remove installed packages  

**Syntax**:
```bash
@acp.package-remove <package-name> [options]

Options:
  -y, --yes               Auto-confirm (skip prompts)
  --keep-modified         Keep locally modified files
```

**Examples**:
```bash
# Remove package
@acp.package-remove firebase

# Remove with auto-confirm
@acp.package-remove firebase -y

# Remove but keep modified files
@acp.package-remove firebase --keep-modified
```

---

### `@acp.package-info`

**Purpose**: Show detailed information about a package  

**Syntax**:
```bash
@acp.package-info <package-name>
```

**Example**:
```bash
@acp.package-info firebase

# Result:
# 📦 firebase (1.2.0)
# 
# Source: https://github.com/prmichaelsen/acp-firebase.git
# Commit: a1b2c3d4e5f6
# Installed: 2026-02-18 10:30 UTC
# Updated: 2026-02-18 10:30 UTC
# 
# Description:
#   Firebase patterns and utilities for ACP projects
# 
# Contents:
#   Patterns (3):
#     - user-scoped-collections.md (v1.1.0)
#     - firebase-security-rules.md (v1.0.0)
#     - firestore-queries.md (v1.0.0)
#   
#   Commands (2):
#     - firebase.init.md (v1.0.0)
#     - firebase.migrate.md (v1.0.0)
#   
#   Designs (1):
#     - firebase-architecture.md (v1.0.0)
# 
# Modified Files: 1
#   - firebase-security-rules.md (modified locally)
```

---

## Monorepo Support

### Monorepo Structure

```
acp-packages/
├── README.md
├── manifest.yaml                # Monorepo manifest
└── packages/
    ├── firebase/
    │   ├── README.md
    │   ├── package.yaml
    │   └── agent/
    ├── mcp-integration/
    │   ├── README.md
    │   ├── package.yaml
    │   └── agent/
    └── oauth/
        ├── README.md
        ├── package.yaml
        └── agent/
```

### Monorepo Manifest (`manifest.yaml`)

```yaml
# manifest.yaml (at repository root)
name: acp-packages
description: Collection of ACP packages
version: 1.0.0

packages:
  firebase:
    path: packages/firebase
    version: 1.2.0
  
  mcp-integration:
    path: packages/mcp-integration
    version: 2.0.1
  
  oauth:
    path: packages/oauth
    version: 1.0.0
```

### Installation from Monorepo

```bash
# Install specific package
@acp.package-install https://github.com/prmichaelsen/acp-packages.git#main:packages/firebase

# List available packages in monorepo
@acp.package-install https://github.com/prmichaelsen/acp-packages.git --list-packages

# Result:
# 📦 Available packages:
# 
# firebase (1.2.0)
#   Path: packages/firebase
#   Description: Firebase patterns and utilities
# 
# mcp-integration (2.0.1)
#   Path: packages/mcp-integration
#   Description: MCP server integration patterns
# 
# oauth (1.0.0)
#   Path: packages/oauth
#   Description: OAuth 2.0 patterns and flows
```

---

## Conflict Resolution

### Conflict Types

#### Type 1: File Already Exists (Different Source)
```bash
@acp.package-install https://github.com/other/acp-firebase.git

# Result:
# ⚠️  Conflict: patterns/user-scoped-collections.md
#   Currently installed from: github.com/prmichaelsen/acp-firebase.git
#   Attempting to install from: github.com/other/acp-firebase.git
# 
# Options:
#   1. Skip (keep existing)
#   2. Overwrite (replace with new)
#   3. Rename (install as user-scoped-collections-2.md)
#   4. Abort installation
```

#### Type 2: File Modified Locally
```bash
@acp.package-update firebase

# Result:
# ⚠️  Conflict: patterns/firebase-security-rules.md
#   Remote version: 1.1.0 (updated)
#   Local version: 1.0.0 (modified)
# 
# Options:
#   1. Keep local (skip update)
#   2. Overwrite with remote (lose local changes)
#   3. Show diff
#   4. Create backup and update
```

#### Type 3: Version Downgrade
```bash
@acp.package-install https://github.com/prmichaelsen/acp-firebase.git@v1.0.0

# Result:
# ⚠️  Version downgrade detected:
#   Currently installed: 1.2.0
#   Attempting to install: 1.0.0
# 
# This may cause issues. Continue? (y/N)
```

---

## Dependency Management

### Package Dependencies

```yaml
# package.yaml
dependencies:
  - name: acp-typescript
    version: ">=1.0.0"
    required: true
  
  - name: acp-architecture
    version: "^1.0.0"
    required: false
    reason: "Service layer pattern references architecture patterns"
```

### Dependency Resolution

```bash
@acp.package-install https://github.com/prmichaelsen/acp-firebase.git

# Result:
# 📦 Installing firebase (1.2.0)
# 
# ⚠️  Missing dependencies:
#   - acp-typescript (>=1.0.0) - REQUIRED
#   - acp-architecture (^1.0.0) - OPTIONAL
# 
# Install dependencies? (Y/n) y
# 
# ✓ Installing acp-typescript (1.0.0)
# ✓ Installing acp-architecture (1.0.0)
# ✓ Installing firebase (1.2.0)
```

---

## Implementation Plan

### Phase 1: Basic Package Management (Week 1)
**Estimated Effort**: 6-8 hours  

**Deliverables**:
1. Create `agent/manifest.yaml` manifest structure
2. Enhance `package-acp.install.sh` to write manifest
3. Implement `@acp.package-list` command
4. Add package metadata tracking (source, version, commit)
5. Test basic installation and listing

**Files to Create**:
- `agent/manifest.yaml` (manifest)
- `commands/acp.package-list.md`

**Files to Modify**:
- `scripts/package-acp.install.sh` (add manifest writing)
- `commands/acp.package-install.md` (document manifest)

---

### Phase 2: Selective Installation (Week 2)
**Estimated Effort**: 4-6 hours  

**Deliverables**:
1. Implement `--patterns`, `--commands`, `--designs` flags
2. Implement file-level selection
3. Track installed files in manifest
4. Add `--list` flag to preview files
5. Test selective installation

**Files to Modify**:
- `scripts/package-acp.install.sh` (add selective installation)
- `commands/acp.package-install.md` (document options)

---

### Phase 3: Update System (Week 3)
**Estimated Effort**: 5-7 hours  

**Deliverables**:
1. Create `@acp.package-update` command
2. Implement version comparison
3. Implement checksum-based modification detection
4. Handle conflicts (modified files)
5. Test update workflows

**Files to Create**:
- `commands/acp.package-update.md`
- `scripts/package-acp.version-update.sh`

---

### Phase 4: Advanced Features (Week 4)
**Estimated Effort**: 4-6 hours  

**Deliverables**:
1. Create `@acp.package-remove` command
2. Create `@acp.package-info` command
3. Implement `--from-manifest` installation
4. Add dependency resolution (basic)
5. Test complete workflows

**Files to Create**:
- `commands/acp.package-remove.md`
- `commands/acp.package-info.md`
- `scripts/package-remove.sh`

---

## Examples

### Example 1: Fresh Project Setup

```bash
# 1. Initialize ACP
curl -fsSL https://raw.githubusercontent.com/prmichaelsen/agent-context-protocol/mainline/scripts/acp.install.sh | bash

# 2. Install packages
@acp.package-install https://github.com/prmichaelsen/acp-firebase.git
@acp.package-install https://github.com/prmichaelsen/acp-mcp-integration.git
@acp.package-install https://github.com/prmichaelsen/acp-oauth.git

# 3. Check what's installed
@acp.package-list

# Result:
# 📦 Installed ACP Packages (3)
# 
# firebase (1.2.0) - 6 files
# mcp-integration (2.0.1) - 4 files
# oauth (1.0.0) - 2 files
```

---

### Example 2: Selective Installation

```bash
# Only need user-scoped collections pattern
@acp.package-install https://github.com/prmichaelsen/acp-firebase.git \
  --patterns user-scoped-collections

# Result:
# ✓ Installed patterns/user-scoped-collections.md (v1.1.0)
# ✓ Updated agent/manifest.yaml
# 
# Package firebase (1.2.0) - partial installation
#   Installed: 1 of 6 files
```

---

### Example 3: Update Workflow

```bash
# Check for updates
@acp.package-update --check

# Result:
# 📦 Updates Available
# 
# firebase: 1.2.0 → 1.3.0
#   Changes:
#     Updated:
#       - patterns/user-scoped-collections.md (1.1.0 → 1.2.0)
#         * Added pagination examples
#     New:
#       - patterns/firestore-transactions.md (1.0.0)
#     
#   ⚠️  Modified locally:
#       - patterns/firebase-security-rules.md
#         (will be skipped unless --force used)

# Update
@acp.package-update firebase

# Result:
# ✓ Updated patterns/user-scoped-collections.md (1.1.0 → 1.2.0)
# ✓ Added patterns/firestore-transactions.md (1.0.0)
# ⊘ Skipped patterns/firebase-security-rules.md (modified locally)
# ✓ Updated agent/manifest.yaml
```

---

### Example 4: Team Collaboration

```yaml
# Developer 1 installs packages
@acp.package-install https://github.com/prmichaelsen/acp-firebase.git
@acp.package-install https://github.com/prmichaelsen/acp-oauth.git

# Commits agent/manifest.yaml to git
git add agent/manifest.yaml
git commit -m "chore: add ACP packages"
git push

# Developer 2 clones project
git clone https://github.com/team/project.git
cd project

# Installs same packages from manifest
@acp.package-install --from-manifest

# Result:
# ✓ Installed firebase (1.2.0) - 6 files
# ✓ Installed oauth (1.0.0) - 2 files
# ✓ Team has identical setup
```

---

## Benefits

### 1. **Ecosystem Growth** 🌱
- Easy to share patterns and commands
- Community can contribute packages
- Reusable across projects

### 2. **Version Control** 📊
- Track exactly what's installed
- Know when packages were added/updated
- Audit trail for changes

### 3. **Reproducibility** 🔄
- `agent/manifest.yaml` in git ensures team consistency
- New team members get same setup
- CI/CD can install packages automatically

### 4. **Smart Updates** 🧠
- Only update changed files
- Detect local modifications
- Prevent accidental overwrites

### 5. **Conflict Resolution** 🔧
- Detect file conflicts
- Show diffs for modified files
- Multiple resolution strategies

### 6. **Dependency Management** 📦
- Automatic dependency installation
- Version compatibility checking
- Dependency graph visualization

---

## Trade-offs

### 1. **Complexity vs Simplicity**
**Trade-off**: Two-level versioning adds complexity  

**Mitigation**:
- Default behavior is simple (install everything)
- Advanced features are opt-in
- Clear documentation and examples

### 2. **Storage Overhead**
**Trade-off**: Manifest and checksums add storage  

**Mitigation**:
- YAML is human-readable and compresses well
- Checksums are only 64 characters (SHA-256)
- Total overhead: ~1-5KB per package

### 3. **Network Dependency**
**Trade-off**: Requires internet to install/update  

**Mitigation**:
- Packages can be cached locally
- Offline mode (use cached versions)
- Manifest can be committed to git

---

## Testing Strategy

### Unit Tests
- Manifest parsing and writing
- Checksum calculation
- Version comparison logic
- Conflict detection

### Integration Tests
- Full installation workflow
- Update workflow with conflicts
- Dependency resolution

### End-to-End Tests
- Install package from GitHub
- Update package with local modifications
- Remove package
- Team collaboration scenario

---

## Future Considerations

### Phase 5: Package Discovery & Search
**Estimated Effort**: 8-10 hours  

**Deliverables**:
1. Create `@acp.package-search` command
2. Implement GitHub API-based package discovery
3. Support tag-based filtering
4. Display package information in search results
5. Fetch and display package.yaml metadata

**Command Specification**:

```bash
@acp.package-search <query> [options]

Options:
  --tag <tag>              Filter by tag
  --user <username>        Search specific user's repos
  --org <org>              Search specific organization
  --sort <field>           Sort by: stars, updated, name (default: stars)
  --limit <n>              Limit results (default: 10)
```

**Examples**:
```bash
# Search by keyword
@acp.package-search firebase

# Filter by tag
@acp.package-search oauth --tag authentication

# Search user's packages
@acp.package-search --user prmichaelsen

# Sort by recently updated
@acp.package-search --sort updated --limit 5
```

**Implementation Using GitHub API**:

```bash
#!/bin/bash
# scripts/package-search.sh

QUERY=$1
LIMIT=${2:-10}

# Search GitHub repositories with topic "acp-package"
curl -s -H "Accept: application/vnd.github+json" \
  "https://api.github.com/search/repositories?q=${QUERY}+topic:acp-package&sort=stars&per_page=${LIMIT}" \
  | jq -r '.items[] | {
      name: .name,
      full_name: .full_name,
      description: .description,
      stars: .stargazers_count,
      url: .html_url,
      topics: .topics
    }'

# For each result, fetch package.yaml to get version
for repo in $(echo "$results" | jq -r '.full_name'); do
  # Fetch package.yaml from repo
  package_yaml=$(curl -s "https://raw.githubusercontent.com/${repo}/main/package.yaml")
  
  # Parse version and tags
  version=$(echo "$package_yaml" | yq eval '.version' -)
  tags=$(echo "$package_yaml" | yq eval '.tags[]' -)
  
  # Display formatted result
  echo "📦 ${repo} (${version}) ⭐ ${stars}"
  echo "   ${description}"
  echo "   Tags: ${tags}"
  echo ""
done
```

**GitHub API Endpoints Used**:
- `GET /search/repositories` - Search repos by topic
- `GET /repos/{owner}/{repo}/topics` - Get repo topics
- `GET /repos/{owner}/{repo}/contents/package.yaml` - Fetch package metadata

**No Authentication Required** (for public repos):
- GitHub API allows 60 requests/hour without auth
- Sufficient for package search
- Can add token for higher limits (5000/hour)

**Package Discovery Requirements**:

To be discoverable, packages must:
1. Have `package.yaml` in repository root
2. Include GitHub topic `acp-package`
3. Include descriptive tags in `package.yaml`
4. Have clear description in GitHub repo
5. Follow ACP package structure

**Search Result Format**:

```
📦 Found 3 packages matching "firebase":

1. acp-firebase (1.2.0) ⭐ 45
   github.com/prmichaelsen/acp-firebase
   Firebase patterns and utilities for ACP projects
   Tags: firebase, firestore, database, backend
   Install: @acp.package-install https://github.com/prmichaelsen/acp-firebase.git

2. acp-firebase-v11 (1.0.0) ⭐ 12
   github.com/otheruser/acp-firebase-v11
   Firebase patterns for v11 Admin SDK
   Tags: firebase, firebase-v11, legacy
   Install: @acp.package-install https://github.com/otheruser/acp-firebase-v11.git

3. acp-fullstack (2.0.0) ⭐ 89
   github.com/community/acp-fullstack
   Complete fullstack patterns including Firebase
   Tags: firebase, cloudflare, tanstack, fullstack
   Install: @acp.package-install https://github.com/community/acp-fullstack.git
```

**Package Requirements for Discovery**:

To be discoverable, packages must:
1. Have `package.yaml` in repository root
2. Include GitHub topic `acp-package`
3. Include descriptive tags in `package.yaml`
4. Have clear description
5. Follow ACP package structure

**Verification System**:

```yaml
# package.yaml
verified: true  # Set by ACP maintainers
verification:
  verified_by: prmichaelsen
  verified_at: 2026-02-18T10:00:00Z
  verification_criteria:
    - structure_valid: true
    - documentation_complete: true
    - examples_included: true
    - security_reviewed: true
```

### Phase 6: Advanced Features
- **Ratings** - Community ratings and reviews
- **Analytics** - Track package popularity and downloads
- **Private Packages** - Support for private repositories with authentication
- **Lock Files** - `agent/manifest.lock.yaml` for exact reproducibility
- **Hooks** - Pre/post install hooks for automation
- **Aliases** - Short names for common packages (`@acp.package-install firebase` → auto-resolves to full URL)

### Phase 6: Tooling
- **VS Code Extension** - GUI for package management
- **Web Dashboard** - Browse and discover packages
- **CI/CD Integration** - Automated package updates
- **Package Validation** - Lint packages before publishing

---

## Related Documents

- [`commands/acp.package-install.md`](../commands/acp.package-install.md) - Current package install command
- [`patterns/bootstrap.md`](../patterns/bootstrap.md) - Bootstrap pattern (candidate for extraction)
- [`patterns/mcp-integration-patterns.md`](../patterns/mcp-integration-patterns.md) - MCP patterns (candidate for extraction)
- [`patterns/oauth-integration.md`](../patterns/oauth-integration.md) - OAuth patterns (candidate for extraction)

---

**Status**: Design Specification  
**Recommendation**: Implement in phases starting with basic manifest tracking  
**Next Steps**: Create implementation tasks for Phase 1  