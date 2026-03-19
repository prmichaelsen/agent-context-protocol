# Milestone 5: Global Package Installation

**Goal**: Enable global package installation to `~/.acp/packages/` for package development and global command library  
**Duration**: 1-2 weeks  
**Dependencies**: Milestone 3 (Package Management System) complete  
**Status**: Planning Complete - Ready for Implementation  

---

## Overview

This milestone implements global package installation to `~/.acp/packages/` where packages are tracked in `~/.acp/manifest.yaml`. Global packages serve two primary purposes:

1. **Package Development**: Developers can work on packages in `~/.acp/packages/` with full ACP tooling
2. **Global Command Library**: Agents can discover and use commands/patterns from globally installed packages

**Key Design Principles**:
- **No symlinks** - packages stay in `~/.acp/packages/` only
- **Independent from projects** - projects don't depend on global packages
- **Agent discovery** - agents read `~/.acp/manifest.yaml` to find global packages
- **Local precedence** - local packages always override global packages
- **Simple architecture** - just install to global location and track in manifest

This feature is optional and backward-compatible. Local installation remains the default behavior.

---

## Deliverables

### 1. Global Package Infrastructure
- `~/.acp/` directory structure
- `~/.acp/AGENT.md` with discovery instructions
- `~/.acp/manifest.yaml` for global package tracking (standard format)
- `~/.acp/packages/` directory for global packages
- `~/.acp/projects/` directory (for future monorepo support)

### 2. Enhanced Installation System
- `--global` flag support in `@acp.package-install`
- Installation to `~/.acp/packages/{package-name}/`
- Global manifest tracking (same format as project manifests)
- No symlinks, no project manifest updates

### 3. Updated Package Commands
- `@acp.init` reads `~/.acp/manifest.yaml` and reports global packages
- `@acp.package-list --global` lists global packages
- `@acp.package-update --global` updates global packages
- `@acp.package-remove --global` removes global packages
- `@acp.package-info --global` shows global package details

### 4. Documentation and Agent Instructions
- Updated AGENT.md with global package discovery
- Updated command documentation with `--global` examples
- Namespace precedence rules documented
- Agent discovery workflow documented

---

## Success Criteria

- [ ] `~/.acp/` directory structure created with AGENT.md and manifest.yaml
- [ ] Global packages install to `~/.acp/packages/{package-name}/`
- [ ] Global manifest tracks all globally installed packages (standard format)
- [ ] `@acp.package-install --global` works without errors
- [ ] `@acp.package-list --global` lists global packages correctly
- [ ] `@acp.package-update --global` updates global packages only
- [ ] `@acp.package-remove --global` removes from global location only
- [ ] `@acp.package-info --global` shows global package details
- [ ] Agents can discover global packages by reading `~/.acp/manifest.yaml`
- [ ] Local packages take precedence over global packages
- [ ] All existing local installation workflows remain functional
- [ ] AGENT.md includes global package discovery instructions
- [ ] Command documentation includes `--global` flag examples

---

## Key Files to Create

```
~/.acp/
├── AGENT.md                     # Discovery instructions for agents
├── manifest.yaml                # Global package manifest (standard format)
├── packages/                    # Global packages directory
│   ├── @prmichaelsen/
│   │   ├── acp-firebase/
│   │   │   ├── package.yaml
│   │   │   ├── AGENT.md
│   │   │   └── agent/
│   │   └── acp-git/
│   │       ├── package.yaml
│   │       └── agent/
│   └── other-packages/
└── projects/                    # Optional: User projects (future)

agent/scripts/
├── acp.common.sh                # Enhanced with global manifest functions
└── acp.package-install.sh       # Enhanced with --global flag

agent/commands/
├── acp.init.md                  # Updated to read global manifest
├── acp.package-install.md       # Updated with --global docs
├── acp.package-list.md          # Updated with --global flag
├── acp.package-update.md        # Updated with --global flag
├── acp.package-remove.md        # Updated with --global flag
└── acp.package-info.md          # Updated with --global flag

AGENT.md                         # Updated with global discovery instructions
```

---

## Tasks

1. [Task 25: Global Infrastructure Setup](../tasks/task-25-global-infrastructure.md) - Create `~/.acp/` structure, AGENT.md, and manifest (2-3 hours)
2. [Task 26: Global Installation Implementation](../tasks/task-26-global-installation.md) - Add `--global` flag to install command (2-3 hours)
3. [Task 27: Global Package Commands](../tasks/task-27-global-package-commands.md) - Add `--global` to list, update, remove, info (2-3 hours)
4. [Task 28: Documentation and Agent Instructions](../tasks/task-28-global-documentation.md) - Update AGENT.md and command docs (1-2 hours)
5. [Task 29: Global ACP Auto-Initialization](../tasks/task-29-global-acp-auto-initialization.md) - Auto-initialize ~/.acp/ on first global command use (1-2 hours)

---

## Environment Variables

No new environment variables required. Uses existing `$HOME` for global directory location.

---

## Testing Requirements

- [ ] Test global directory creation
- [ ] Test global manifest operations (read, write, update)
- [ ] Test global installation workflow
- [ ] Test global package listing
- [ ] Test global package updates
- [ ] Test global package removal
- [ ] Test namespace precedence (local overrides global)
- [ ] Test agent discovery workflow

---

## Documentation Requirements

- [ ] Create `~/.acp/AGENT.md` with discovery instructions
- [ ] Update main AGENT.md with global package discovery section
- [ ] Update `@acp.init` to read and report global packages
- [ ] Update `@acp.package-install` with `--global` flag
- [ ] Update `@acp.package-list` with `--global` flag
- [ ] Update `@acp.package-update` with `--global` flag
- [ ] Update `@acp.package-remove` with `--global` flag
- [ ] Update `@acp.package-info` with `--global` flag
- [ ] Document namespace precedence rules
- [ ] Add global installation examples to README.md

---

## Risks and Mitigation

| Risk | Impact | Probability | Mitigation Strategy |
|------|--------|-------------|---------------------|
| Agents don't discover global packages | Medium | Low | Clear documentation in AGENT.md, simple discovery pattern |
| Namespace collisions | Low | Low | Local always takes precedence, clear rules documented |
| Permission issues with global directory | Low | Low | Use `$HOME/.acp/` (no sudo needed), clear error messages |
| Confusion about global vs local | Medium | Medium | Clear documentation, `--global` flag is explicit |
| Projects accidentally depending on global | Low | Low | Projects are independent by design, no automatic linking |

---

## Implementation Phases

### Phase 1: Infrastructure (Task 25)
- Create `~/.acp/` directory structure
- Create `~/.acp/AGENT.md` with discovery instructions
- Create `~/.acp/manifest.yaml` (standard format)
- Add global manifest functions to acp.common.sh

### Phase 2: Installation (Task 26)
- Add `--global` flag parsing to acp.package-install.sh
- Implement installation to `~/.acp/packages/`
- Update global manifest after installation
- Test global installation workflow

### Phase 3: Command Updates (Task 27)
- Update `@acp.init` to read and report global packages
- Add `--global` flag to acp.package-list.sh
- Add `--global` flag to acp.package-update.sh
- Add `--global` flag to acp.package-remove.sh
- Add `--global` flag to acp.package-info.sh

### Phase 4: Documentation (Task 28)
- Update AGENT.md with global discovery section
- Update all command documentation
- Document namespace precedence
- Add usage examples

---

**Next Milestone**: TBD (Monorepo Management)  
**Blockers**: None  
**Notes**:
- This feature is optional and backward-compatible
- Local installation remains default behavior
- Global packages are for package development and optional discovery
- Projects remain independent (no dependencies on global packages)
- Local packages always take precedence over global packages
- Future enhancement: Monorepo management in `~/.acp/projects/`
