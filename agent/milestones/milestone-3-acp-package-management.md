# Milestone 3: ACP Package Management System

**Goal**: Implement comprehensive package management for ACP modules with versioning, selective installation, and discovery  
**Duration**: 5-7 weeks  
**Dependencies**: None  
**Status**: Not Started  
**Design Document**: [`agent/design/acp-package-management-system.md`](../design/acp-package-management-system.md)  

---

## Overview

Implement a complete package management system for ACP that enables distribution, installation, and maintenance of reusable ACP modules (patterns, commands, designs) through GitHub repositories. This milestone provides npm-like package management for documentation and agent directives, enabling ecosystem growth and code reuse across projects.

---

## Deliverables

### 1. Manifest System
- `agent/manifest.yaml` structure and schema
- Package metadata tracking (source, version, commit)
- File-level version tracking
- Checksum-based modification detection
- Installation timestamp tracking

### 2. Installation System
- Enhanced `package-acp.install.sh` script with manifest writing
- Selective installation (by type: patterns/commands/designs)
- File-level selective installation
- Conflict detection and resolution
- Project dependency compatibility checking

### 3. Update System
- `@acp.package-update` command and script
- Version comparison logic
- Smart updates (only changed files)
- Local modification detection
- Conflict resolution strategies

### 4. Package Management Commands
- `@acp.package-list` - List installed packages
- `@acp.package-remove` - Remove packages
- `@acp.package-info` - Show package details
- Manifest-based installation (no args)

### 5. Package Discovery
- `@acp.package-search` command
- GitHub API integration
- Topic-based search (`acp-package`)
- Package metadata fetching
- Formatted search results

---

## Success Criteria

- [ ] `agent/manifest.yaml` created on package installation
- [ ] Manifest tracks package version, commit, and installed files
- [ ] Checksums calculated and tracked for all installed files
- [ ] `@acp.package-install` with URL installs and updates manifest
- [ ] `@acp.package-install` without args installs from manifest
- [ ] Selective installation works (`--patterns`, `--commands`, `--designs`)
- [ ] File-level selection works (`--patterns file1 file2`)
- [ ] `@acp.package-update` detects available updates
- [ ] `@acp.package-update` without args updates all packages
- [ ] Local modifications detected via checksum comparison
- [ ] Conflict resolution prompts user for action
- [ ] `@acp.package-list` shows installed packages with versions
- [ ] `@acp.package-remove` removes package and updates manifest
- [ ] `@acp.package-info` shows detailed package information
- [ ] `@acp.package-search` finds packages via GitHub API
- [ ] Search results show version, stars, description, tags
- [ ] Project dependency compatibility checking works
- [ ] All commands have documentation
- [ ] All scripts tested and working
- [ ] No breaking changes to existing ACP functionality

---

## Key Files to Create

```
agent-context-protocol/
├── agent/
│   ├── milestones/
│   │   └── milestone-3-acp-package-management.md (this file)
│   ├── tasks/
│   │   ├── task-5-manifest-system.md
│   │   ├── task-6-selective-installation.md
│   │   ├── task-7-update-system.md
│   │   ├── task-8-package-list-command.md
│   │   ├── task-9-package-remove-command.md
│   │   ├── task-10-package-info-command.md
│   │   ├── task-11-package-search-command.md
│   │   └── task-12-dependency-checking.md
│   ├── commands/
│   │   ├── acp.package-list.md
│   │   ├── acp.package-update.md
│   │   ├── acp.package-remove.md
│   │   ├── acp.package-info.md
│   │   └── acp.package-search.md
│   └── scripts/
│       ├── package-list.sh
│       ├── package-acp.version-update.sh
│       ├── package-remove.sh
│       ├── package-info.sh
│       └── package-search.sh
```

---

## Tasks

### Task 5: Manifest System Implementation
**Estimated Time**: 6-8 hours  
**Priority**: High  
**Description**: Create manifest structure and enhance package-acp.install.sh to write manifest  

**Deliverables**:
- `agent/manifest.yaml` structure and schema
- Enhanced `package-acp.install.sh` with manifest writing
- Checksum calculation and tracking
- Package metadata tracking

### Task 6: Selective Installation
**Estimated Time**: 4-6 hours  
**Priority**: High  
**Description**: Implement selective installation by type and file  

**Deliverables**:
- `--patterns`, `--commands`, `--designs` flags
- File-level selection support
- `--list` flag for preview
- Manifest tracking of partial installations

### Task 7: Update System
**Estimated Time**: 5-7 hours  
**Priority**: High  
**Description**: Implement package update system with conflict detection  

**Deliverables**:
- `@acp.package-update` command
- `scripts/package-acp.version-update.sh`
- Version comparison logic
- Checksum-based modification detection
- Conflict resolution

### Task 8: Package List Command
**Estimated Time**: 2-3 hours  
**Priority**: Medium  
**Description**: Implement package listing command  

**Deliverables**:
- `@acp.package-list` command
- `scripts/package-list.sh`
- Verbose and filtered output modes

### Task 9: Package Remove Command
**Estimated Time**: 3-4 hours  
**Priority**: Medium  
**Description**: Implement package removal command  

**Deliverables**:
- `@acp.package-remove` command
- `scripts/package-remove.sh`
- File removal and manifest cleanup
- Keep-modified option

### Task 10: Package Info Command
**Estimated Time**: 2-3 hours  
**Priority**: Low  
**Description**: Implement package info display command  

**Deliverables**:
- `@acp.package-info` command
- `scripts/package-info.sh`
- Detailed package information display

### Task 11: Package Search Command
**Estimated Time**: 6-8 hours  
**Priority**: High  
**Description**: Implement GitHub API-based package discovery  

**Deliverables**:
- `@acp.package-search` command
- `scripts/package-search.sh`
- GitHub API integration
- Package metadata fetching
- Formatted search results

### Task 12: Dependency Checking
**Estimated Time**: 3-4 hours  
**Priority**: Medium  
**Description**: Implement project dependency compatibility checking  

**Deliverables**:
- Dependency detection (npm/pip/cargo)
- Version compatibility validation
- Warning messages for incompatible versions
- Recommendation display

---

## Timeline

### Week 1: Foundation
- Task 5: Manifest System Implementation

### Week 2: Installation
- Task 6: Selective Installation

### Week 3: Updates
- Task 7: Update System

### Week 4: Management Commands
- Task 8: Package List Command
- Task 9: Package Remove Command
- Task 10: Package Info Command

### Week 5: Discovery
- Task 11: Package Search Command
- Task 12: Dependency Checking

### Week 6-7: Testing & Polish
- Integration testing
- Documentation updates
- Bug fixes
- User acceptance testing

---

## Dependencies

**External**:
- GitHub API (public, no auth required)
- `jq` for JSON parsing
- `yq` for YAML parsing
- `curl` for HTTP requests
- `sha256sum` for checksums

**Internal**:
- None (can be implemented independently)

---

## Risks & Mitigations

### Risk 1: GitHub API Rate Limits
**Risk**: 60 requests/hour without authentication  

**Mitigation**:
- Cache search results locally
- Implement exponential backoff
- Support GitHub token for higher limits (5000/hour)
- Batch requests where possible

### Risk 2: Manifest Corruption
**Risk**: Manifest file could become corrupted  

**Mitigation**:
- Validate YAML before writing
- Create backups before modifications
- Implement manifest repair command
- Version manifest format for future changes

### Risk 3: Checksum Mismatches
**Risk**: False positives for file modifications  

**Mitigation**:
- Use SHA-256 (collision-resistant)
- Normalize line endings before checksum
- Provide override flag (--force)
- Show diff for verification

### Risk 4: Breaking Changes to Existing Workflow
**Risk**: New system disrupts current package-install  

**Mitigation**:
- Maintain backward compatibility
- Make manifest optional initially
- Gradual rollout
- Clear migration guide

---

## Next Milestone

**Milestone 4**: ACP Package Ecosystem  
- Create initial package repositories (acp-firebase, acp-mcp-integration, acp-oauth)
- Publish packages to GitHub
- Add `acp-package` topics
- Create package.yaml for each
- Test end-to-end workflows

---

**Status**: Ready to begin  
**Estimated Duration**: 5-7 weeks  
**Estimated Effort**: 31-43 hours  
**Priority**: High  
