# Task 28: Documentation and Agent Instructions

**Milestone**: [M5 - Global Package Installation](../milestones/milestone-5-global-package-installation.md)  
**Estimated Time**: 1-2 hours  
**Dependencies**: Task 27 (Global Package Commands)  
**Status**: Not Started  

---

## Objective

Update AGENT.md, README.md, and CHANGELOG.md with comprehensive documentation about global package installation, discovery workflow, and namespace precedence rules.

---

## Context

With global package installation fully implemented (Tasks 25-27), the documentation needs to be updated to:

1. **Teach agents** how to discover and use global packages
2. **Teach users** when to use global vs local installation
3. **Document precedence rules** for namespace resolution
4. **Provide examples** of global package workflows
5. **Update version** to reflect new feature (minor version bump)

This documentation is critical for adoption - without clear instructions, agents won't know to read `~/.acp/manifest.yaml` and users won't understand when to use global installation.

---

## Steps

### 1. Update AGENT.md with Global Package Discovery

Add new section to AGENT.md about global packages:

**File**: `AGENT.md`  

**Location**: After "ACP Commands" section, before "Sample Prompts"  

**Section to add**:
```markdown
## Global Package Discovery

ACP supports global package installation to `~/.acp/packages/` for package development and global command libraries.

### For Agents: How to Discover Global Packages

When working in any project, you can discover globally installed packages:

1. **Check if global manifest exists**: `~/.acp/manifest.yaml`
2. **Read global manifest**: Contains all globally installed packages
3. **Navigate to packages**: Each package entry contains installation path
4. **Use commands/patterns**: Reference via `@namespace.command` syntax

**Automatic Discovery**: The `@acp.init` command automatically reads `~/.acp/manifest.yaml` and reports globally installed packages.  

### Namespace Precedence Rules

**CRITICAL**: Local packages always take precedence over global packages.  

**Resolution order**:
1. Check local: `./agent/commands/{namespace}.{command}.md`
2. If not found, check global: `~/.acp/packages/*/agent/commands/{namespace}.{command}.md`
3. Use first match found

**Example**: If both local and global packages define `@firebase.deploy`:  
- ✅ Use `./agent/commands/firebase.deploy.md` (local takes precedence)
- ❌ Ignore `~/.acp/packages/@prmichaelsen/acp-firebase/agent/commands/firebase.deploy.md`

### Global Package Structure

```
~/.acp/
├── AGENT.md                     # Discovery instructions
├── manifest.yaml                # Global package manifest
├── packages/                    # Global packages
│   ├── @prmichaelsen/
│   │   ├── acp-firebase/
│   │   │   ├── package.yaml
│   │   │   ├── AGENT.md
│   │   │   └── agent/
│   │   │       ├── patterns/
│   │   │       └── commands/
│   │   └── acp-git/
│   │       └── agent/
│   │           └── commands/
│   └── @someorg/
│       └── acp-mcp/
└── projects/                    # Optional: User projects
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
# Output: "Found 1 global package: @prmichaelsen/acp-git (2 commands)"

# Use global command
@git.commit
# Agent reads: ~/.acp/packages/@prmichaelsen/acp-git/agent/commands/git.commit.md
```
```

**Verification**:
- Section added to AGENT.md
- Discovery workflow documented
- Precedence rules clearly explained
- Examples provided
- Use cases documented

### 2. Update README.md with Global Installation

Add global installation section to README.md:

**File**: `README.md`  

**Location**: In "Package Management" section  

**Content to add**:
```markdown
### Global Package Installation

Install packages globally to `~/.acp/packages/` for package development or global command libraries:

```bash
# Install package globally
./agent/scripts/acp.package-install.sh --global https://github.com/user/acp-firebase.git

# Or via command
@acp.package-install --global https://github.com/user/acp-firebase.git

# List global packages
@acp.package-list --global

# Update global packages
@acp.package-update --global firebase

# Remove global packages
@acp.package-remove --global firebase
```

**Global vs Local**:
- **Global**: Installed to `~/.acp/packages/`, available for discovery in any project
- **Local**: Installed to `./agent/`, only available in current project
- **Precedence**: Local packages always override global packages

**Use cases for global installation**:
- Package development with full ACP tooling
- Common utilities used across many projects
- Building a personal command library
```

**Verification**:
- Section added to README.md
- Examples show global installation
- Clear comparison of global vs local
- Use cases documented

### 3. Update CHANGELOG.md

Add entry for Milestone 5 completion:

**File**: `CHANGELOG.md`  

**Entry to add**:
```markdown
## [2.12.0] - 2026-02-21

### Added
- **Global Package Installation**: Install packages to `~/.acp/packages/` with `--global` flag
- **Global Package Discovery**: Agents can discover global packages via `~/.acp/manifest.yaml`
- **Global Package Commands**: All package commands support `--global` flag (list, update, remove, info)
- **Global Infrastructure**: Created `~/.acp/` directory with AGENT.md and manifest.yaml
- **Enhanced @acp.init**: Automatically discovers and reports globally installed packages
- **Namespace Precedence**: Local packages always take precedence over global packages

### Changed
- **@acp.package-install**: Added `--global` flag to install packages globally
- **@acp.package-list**: Added `--global` flag to list global packages
- **@acp.package-update**: Added `--global` flag to update global packages
- **@acp.package-remove**: Added `--global` flag to remove global packages
- **@acp.package-info**: Added `--global` flag to show global package info
- **@acp.init**: Now reads `~/.acp/manifest.yaml` and reports global packages

### Documentation
- Updated AGENT.md with global package discovery section
- Updated README.md with global installation examples
- Updated all package command documentation with `--global` flag
- Documented namespace precedence rules
- Added global package use cases and best practices
```

**Verification**:
- CHANGELOG.md updated
- Version number incremented (2.11.0 → 2.12.0)
- All changes documented
- Clear description of new features

### 4. Update AGENT.md Version

Update version number in AGENT.md:

**File**: `AGENT.md`  

**Change**:
```markdown
**Version**: 2.11.0  →  **Version**: 2.12.0  
```

**Verification**:
- Version updated in AGENT.md header
- Matches CHANGELOG.md version

### 5. Create Usage Examples Document

Create comprehensive examples document for global packages:

**File**: `agent/design/global-package-usage-examples.md`  

**Content**: Document with 5-10 real-world examples:  
1. Installing git helpers globally
2. Developing a new package in `~/.acp/packages/`
3. Using global commands in a project
4. Updating global packages
5. Managing both global and local packages
6. Namespace collision resolution
7. Package development workflow

**Verification**:
- Examples document created
- Covers common use cases
- Shows complete workflows
- Includes troubleshooting

### 6. Update Installation Scripts

Update installation scripts to create global infrastructure:

**Files to update**:
- `agent/scripts/acp.install.sh` - Add note about global packages
- `agent/scripts/acp.version-update.sh` - Ensure updates preserve global infrastructure

**Changes**:
- Add informational message about global packages
- Note that global infrastructure is optional
- Provide command to install packages globally

**Verification**:
- Scripts updated
- Messages are informative
- No breaking changes to existing behavior

### 7. Final Documentation Review

Review all documentation for consistency:

**Check**:
- [ ] All references to global packages are consistent
- [ ] Version numbers match across all files
- [ ] Examples are accurate and tested
- [ ] No broken links between documents
- [ ] Terminology is consistent (global vs local)
- [ ] Precedence rules clearly stated everywhere

**Verification**:
- Documentation is consistent
- No contradictions
- All examples work
- Links are valid

---

## Verification

- [ ] AGENT.md updated with global package discovery section
- [ ] README.md updated with global installation examples
- [ ] CHANGELOG.md updated with version 2.12.0 entry
- [ ] AGENT.md version updated to 2.12.0
- [ ] Usage examples document created
- [ ] Installation scripts updated with global package notes
- [ ] All documentation reviewed for consistency
- [ ] No broken links in documentation
- [ ] All examples tested and working
- [ ] Terminology consistent across all docs
- [ ] Namespace precedence rules documented clearly

---

## Expected Output

### Files Modified
- `AGENT.md` - Added global package discovery section, version bump
- `README.md` - Added global installation section
- `CHANGELOG.md` - Added [2.12.0] entry
- `agent/commands/acp.init.md` - Updated with global discovery
- `agent/commands/acp.package-list.md` - Added `--global` flag docs
- `agent/commands/acp.package-update.md` - Added `--global` flag docs
- `agent/commands/acp.package-remove.md` - Added `--global` flag docs
- `agent/commands/acp.package-info.md` - Added `--global` flag docs
- `agent/scripts/acp.install.sh` - Added global package note

### Files Created
- `agent/design/global-package-usage-examples.md` - Comprehensive usage examples

### Documentation Quality
- ✅ Clear and comprehensive
- ✅ Consistent terminology
- ✅ Accurate examples
- ✅ No broken links
- ✅ Version numbers match
- ✅ Ready for users and agents

---

## Common Issues and Solutions

### Issue 1: Version number mismatch

**Symptom**: Different version numbers in AGENT.md and CHANGELOG.md  

**Solution**: Ensure both files are updated to 2.12.0. Use search to find all version references: `grep -r "2.11.0" .`  

### Issue 2: Broken links in documentation

**Symptom**: Links to task/design files don't work  

**Solution**: Verify all relative paths are correct. Use format: `[Link Text](../relative/path.md)` for cross-references.  

### Issue 3: Examples don't work

**Symptom**: Users report examples fail  

**Solution**: Test all examples before committing. Ensure commands are invoked correctly and output matches documentation.  

### Issue 4: Inconsistent terminology

**Symptom**: Some docs say "global packages", others say "system packages"  

**Solution**: Use consistent terminology: "global packages" (not "system packages"). Search and replace inconsistencies.  

---

## Resources

- [Global Package Installation Design](../design/global-package-installation.md): Design specification
- [Milestone 5 Document](../milestones/milestone-5-global-package-installation.md): Milestone overview
- [AGENT.md](../../AGENT.md): Main documentation file
- [README.md](../../README.md): User-facing documentation
- [CHANGELOG.md](../../CHANGELOG.md): Version history

---

## Notes

- This task completes Milestone 5 implementation
- Documentation is critical for feature adoption
- Version bump to 2.12.0 (minor - new feature)
- All documentation should be clear for both agents and users
- Examples should be tested and verified
- Consider creating video tutorial or blog post after completion
- Global packages are optional - projects work fine without them
- This feature enables package ecosystem growth

---

**Next Task**: None (Milestone 5 complete)  
**Related Design Docs**: [global-package-installation.md](../design/global-package-installation.md)  
**Estimated Completion Date**: TBD  
