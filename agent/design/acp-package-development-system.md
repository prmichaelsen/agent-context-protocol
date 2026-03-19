# ACP Package Development System

**Concept**: Complete package development workflow with entity creation, validation, and publishing  
**Created**: 2026-02-20  
**Status**: Design Specification  
**Priority**: High  
**Estimated Effort**: 40-60 hours  

---

## Table of Contents

1. [Overview](#overview)
2. [Problem Statement](#problem-statement)
3. [Solution Architecture](#solution-architecture)
4. [Key Features](#key-features)
5. [Component Specifications](#component-specifications)
6. [Implementation Plan](#implementation-plan)
7. [Benefits](#benefits)
8. [Trade-offs](#trade-offs)

---

## Overview

The ACP Package Development System provides a complete workflow for creating, developing, validating, and publishing ACP packages. It extends the existing package management system (Milestone 3) with tools for package authors to efficiently create and maintain high-quality packages.

### Key Components

1. **Entity Creation Commands** - Create patterns, commands, and designs with namespace enforcement
2. **Draft File Support** - Convert loose drafts into structured documentation via clarifications
3. **YAML Schema Validation** - Pure bash schema validator for package.yaml and manifest.yaml
4. **Package Validation** - Comprehensive validation with auto-fix capabilities
5. **Package Publishing** - Automated workflow with version bumping and testing
6. **Pre-Commit Hooks** - Automatic validation before commits

---

## Problem Statement

### Current Limitations

From Milestone 3, we have package installation and management, but package **creation and development** is manual and error-prone:

1. **No Guided Creation** - Package authors must manually create all files
2. **Namespace Errors** - Easy to forget namespace prefixes
3. **Invalid Manifests** - No validation of package.yaml structure
4. **Manual Updates** - Adding files requires manual package.yaml updates
5. **No Publishing Workflow** - Authors must manually commit, version, and push
6. **No Testing** - No way to verify package works before publishing

### User Pain Points

**Scenario 1**: Creating a new pattern in a package  
- Currently: Manually create file, remember namespace, update package.yaml, update README
- Desired: `@acp.pattern-create` handles everything automatically

**Scenario 2**: Publishing a package update  
- Currently: Manually bump version, update CHANGELOG, commit, push, hope it works
- Desired: `@acp.package-publish` validates, versions, commits, pushes, and tests

**Scenario 3**: Validating package before publishing  
- Currently: No validation, discover errors after publishing
- Desired: `@acp.package-validate` catches all issues with auto-fix

---

## Solution Architecture

### High-Level Flow

```
Package Creation
    ↓
@acp.package-create
    ↓
Full ACP Installation + package.yaml
    ↓
Entity Creation (@acp.pattern-create, etc.)
    ↓
Draft → Clarification → Final File
    ↓
Auto-update package.yaml + README.md
    ↓
Validation (@acp.package-validate)
    ↓
Shell Validation + LLM Validation
    ↓
Auto-Fix Issues
    ↓
Publishing (@acp.package-publish)
    ↓
Validate → Version Bump → Commit → Push → Test
    ↓
Package Available on GitHub
```

### Context-Aware Behavior

```
Is package.yaml present?
    ↓
YES → Package Directory
    ↓
    - Use package namespace (from package.yaml)
    - Update package.yaml when creating entities
    - Update README.md
    - Enforce namespace in all files
    ↓
NO → Project Directory
    ↓
    - Use @local namespace
    - Skip package.yaml updates
    - No README updates
    - No namespace enforcement
```

---

## Key Features

### 1. Entity Creation Commands

**@acp.pattern-create**
- Collects pattern information via chat
- Supports draft file input (`@acp.pattern-create @draft.md`)
- Creates clarification if draft is ambiguous
- Generates pattern from template with namespace
- Updates package.yaml contents section
- Updates README.md "What's Included" section
- Validates pattern name format

**@acp.command-create**
- Similar to pattern-create
- Creates command from command.template.md
- Enforces namespace prefix
- Updates package.yaml and README.md

**@acp.design-create**
- Similar to pattern-create and command-create
- Creates design document from template
- Enforces namespace prefix

**Context-Aware**:
- Detects if in package (package.yaml exists)
- Uses package namespace or @local namespace
- Updates package files only if in package

### 2. Draft File Support

**Draft Processing Workflow**:
1. User provides draft file (any format, any location)
2. Command reads draft
3. Analyzes what's unclear or missing
4. Creates clarification document
5. User answers clarification questions
6. Command generates final file from template + clarification answers
7. Prompts to delete draft file

**Supported Syntax**:
- `@acp.pattern-create @my-draft.md` (@ reference, searches for file)
- `@acp.pattern-create agent/drafts/my-draft.md` (explicit path)
- `@acp.pattern-create` (no draft, prompt for description or create empty draft)

### 3. YAML Schema Validation

**agent/scripts/acp.yaml-validate.sh**
- Pure bash implementation (zero dependencies)
- Validates YAML against schema definition
- Supports required fields, types, formats
- Provides helpful error messages
- Sourceable by other scripts

**Schema Definitions** (agent/schemas/):
- `package.schema.yaml` - Validates package.yaml structure
- `manifest.schema.yaml` - Validates manifest.yaml structure (future)
- `progress.schema.yaml` - Validates progress.yaml structure (future)

**Schema Format**: YAML-based (not JSON Schema)  
```yaml
# package.schema.yaml
schema:
  required:
    - name
    - version
    - description
  fields:
    name:
      type: string
      pattern: "^[a-z0-9-]+$"
    version:
      type: string
      pattern: "^[0-9]+\\.[0-9]+\\.[0-9]+$"
    description:
      type: string
```

### 4. Package Validation

**@acp.package-validate**

**Shell-Based Validation**:
- package.yaml is valid YAML
- Required fields present
- Version format valid (semver)
- All files in contents exist
- All agent/ files listed in contents
- Namespace consistency (filenames)
- Git repository initialized
- Git remote configured

**LLM-Based Validation**:
- Documentation sections complete
- Content quality and clarity
- README.md structure
- Namespace consistency (file content)

**Auto-Fix Capabilities**:
- Add missing files to package.yaml
- Add namespace prefix to files
- Create missing README sections
- Initialize git repository
- Add git remote

**Test Installation**:
- Installs package to /tmp directory
- Validates installation succeeded
- Cleans up temp directory

**Remote Availability Check**:
- Verifies remote repository exists
- Checks if package is accessible

### 5. Package Publishing

**@acp.package-publish**

**Workflow**:
1. **Validate** - Run @acp.package-validate (all checks)
2. **Report** - Show validation results (non-destructive)
3. **Fix** - Offer to auto-fix issues if validation failed
4. **Version** - Detect version bump from commits (Conventional Commits)
5. **Confirm** - Show version bump recommendation, ask user to confirm
6. **CHANGELOG** - LLM generates CHANGELOG entry from commits
7. **Commit** - Commit changes (reuse @git.commit logic)
8. **Tag** - Create git tag (v{version})
9. **Push** - Push commits and tags to remote
10. **Test** - Install from remote to verify availability
11. **Report** - Final success/failure report

**Error Handling**:
- Run all non-destructive checks first
- Present comprehensive report
- Stop before destructive operations if checks fail
- Offer to fix and retry
- User chooses: fix all at once or step-by-step

**Branch Validation**:
- Check current branch against configured release branches
- Default: main, master, mainline, release
- Configurable in package.yaml: `release.branch`

### 6. Pre-Commit Hooks

**Automatic Installation**:
- Created by @acp.package-create
- Installed to .git/hooks/pre-commit
- Made executable automatically

**Initial Scope** (simple):
- Validate package.yaml is valid YAML
- Check required fields present
- Validate version format

**Future Enhancements** (documented in hook):
- Namespace consistency checking
- CHANGELOG.md validation
- File existence verification

**No Bypass**:
- No --no-verify support
- User must explicitly override by editing hook file
- Encourages proper validation

---

## Component Specifications

### Namespace System

**Reserved Namespaces**:
- `@acp.*` - Core ACP commands (reserved)
- `@local.*` - Project-specific commands (reserved for non-packages)

**Package Namespaces**:
- `@{package-name}.*` - Package commands
- Must match package.yaml name field
- Enforced by validation

**Namespace Inference Priority**:
1. Read from package.yaml name field (highest)
2. Parse from directory name (acp-{namespace}/)
3. Parse from git remote URL
4. Ask user to confirm (lowest)

**Validation**:
- Reject package names: "local", "acp"
- Check all files use correct namespace
- Validate namespace in filename and content

### Package.yaml Structure

**Required Fields**:
```yaml
name: string (lowercase, alphanumeric, hyphens)
version: string (semver: X.Y.Z)
description: string
author: string
license: string
repository: string (git URL)
```

**Optional Fields**:
```yaml
homepage: string (URL)
tags: array of strings
release:
  branch: string (default: main)
  branches: array of strings
```

**Contents Section**:
```yaml
contents:
  patterns:
    - name: namespace.pattern-name.md
      version: 1.0.0
      description: Brief description
      deprecated: false  # optional
  commands:
    - name: namespace.command-name.md
      version: 1.0.0
      description: Brief description
  designs:
    - name: namespace.design-name.md
      version: 1.0.0
      description: Brief description
```

**Compatibility**:
```yaml
requires:
  acp: ">=2.0.0"
  npm:
    package-name: "^1.0.0"
  pip:
    package-name: ">=1.0.0"
```

**No Inter-Package Dependencies**:
- Removed `dependencies` field (too complex)
- Packages are standalone
- Note in design doc: Future consideration for ACP repository mirror

### README.md Structure

**Standard Sections**:
```markdown
# ACP Package: {name}

## Overview
{description}

## What's Included

<!-- ACP_AUTO_UPDATE_START:CONTENTS -->
### Commands
- `namespace.command1` - Description
- `namespace.command2` - Description

### Patterns
- `namespace.pattern1` - Description
- `namespace.pattern2` - Description

### Designs
- `namespace.design1` - Description
<!-- ACP_AUTO_UPDATE_END:CONTENTS -->

## Why Use This Package
- Benefit 1
- Benefit 2

## Installation

\`\`\`bash
@acp.package-install {repository-url}
\`\`\`

## Development

### Setup
1. Clone repository
2. Make changes
3. Run @acp.package-validate
4. Run @acp.package-publish

### Adding New Content
- Use @acp.pattern-create for patterns
- Use @acp.command-create for commands
- Use @acp.design-create for designs

### Testing
Run @acp.package-validate to test locally

### Publishing
Run @acp.package-publish to publish updates

## Namespace Convention
All files in this package use the `{namespace}` namespace:
- Commands: `{namespace}.command-name.md`
- Patterns: `{namespace}.pattern-name.md`
- Designs: `{namespace}.design-name.md`

## License
{license}

## Author
{author}
```

**Auto-Update Sections**:
- "What's Included" - Updated by @acp.{type}-create
- Uses HTML comment markers for boundaries
- Descriptions from package.yaml

---

## Implementation Plan

### Phase 1: Infrastructure (Tasks 1-3)
**Estimated**: 12-15 hours  

1. **YAML Schema System** (6-8 hours)
   - Research YAML schema standards
   - Create agent/schemas/ directory
   - Create package.schema.yaml
   - Implement acp.yaml-validate.sh (pure bash)
   - Test validation with valid/invalid package.yaml files

2. **Namespace Utilities** (3-4 hours)
   - Add is_acp_package() to common.sh
   - Add infer_namespace() to common.sh
   - Add validate_namespace() to common.sh
   - Add reserved namespace checking

3. **README Update Utilities** (3-4 hours)
   - Add update_readme_contents() to common.sh
   - Parse HTML comment markers
   - Extract descriptions from package.yaml
   - Format content lists

### Phase 2: Entity Creation Commands (Tasks 4-6)
**Estimated**: 15-20 hours  

4. **@acp.pattern-create** (6-8 hours)
   - Create command documentation
   - Implement chat-based collection
   - Support draft file input
   - Create clarification if needed
   - Generate pattern from template
   - Update package.yaml
   - Update README.md
   - Validate pattern name

5. **@acp.command-create** (5-6 hours)
   - Similar to pattern-create
   - Use command.template.md
   - Enforce namespace
   - Update package.yaml and README

6. **@acp.design-create** (4-5 hours)
   - Similar to pattern-create and command-create
   - Use design.template.md
   - Enforce namespace

### Phase 3: Validation System (Tasks 7-8)
**Estimated**: 10-12 hours  

7. **@acp.package-validate** (7-9 hours)
   - Create command documentation
   - Implement shell validation
   - Implement LLM validation
   - Test installation to /tmp
   - Check remote availability
   - Auto-fix capabilities
   - Comprehensive reporting

8. **Enhanced @acp.validate** (3-4 hours)
   - Add namespace checking
   - Add reserved name validation
   - Integrate with existing validation

### Phase 4: Publishing System (Task 9)
**Estimated**: 8-10 hours  

9. **@acp.package-publish** (8-10 hours)
   - Create command documentation
   - Implement validation step
   - Implement version detection (Conventional Commits)
   - Implement CHANGELOG generation (LLM)
   - Integrate @git.commit logic
   - Create git tags
   - Push to remote
   - Test installation from remote
   - Comprehensive error handling

### Phase 5: Package Create Rewrite (Task 10)
**Estimated**: 6-8 hours  

10. **Rewrite @acp.package-create** (6-8 hours)
    - Run acp.install.sh in new directory
    - Create package.yaml with metadata
    - Configure release branch
    - Install pre-commit hook
    - Initialize git repository
    - Remove example file creation
    - Update documentation

### Phase 6: Pre-Commit Hooks (Task 11)
**Estimated**: 3-4 hours  

11. **Pre-Commit Hook System** (3-4 hours)
    - Create hook template
    - Implement basic validation
    - Document future enhancements
    - Test hook installation
    - Update documentation

---

## Component Specifications

### 1. @acp.pattern-create

**Command**: [`agent/commands/acp.pattern-create.md`](../commands/acp.pattern-create.md)  
**Script**: `agent/scripts/acp.pattern-create.sh`  

**Workflow**:
1. Detect context (package vs project)
2. Infer namespace (if package)
3. Check for draft file argument
4. If draft provided:
   - Read draft
   - Create clarification
   - Wait for user responses
   - Generate pattern from clarification
5. If no draft:
   - Prompt for description in chat OR
   - Offer to create empty draft
6. Generate pattern file from template
7. Update package.yaml (if package)
8. Update README.md (if package)
9. Validate pattern name format
10. Report success

**Information Collected**:
- Pattern name (without namespace)
- Pattern description
- Pattern version (default: 1.0.0)
- Draft file path (optional)

### 2. @acp.command-create

**Command**: [`agent/commands/acp.command-create.md`](../commands/acp.command-create.md)  
**Script**: `agent/scripts/acp.command-create.sh`  

**Similar to @acp.pattern-create** with command-specific fields:
- Command category (Workflow | Documentation | Maintenance | Creation)
- Command frequency (Once | Per Session | As Needed)

### 3. @acp.design-create

**Command**: [`agent/commands/acp.design-create.md`](../commands/acp.design-create.md)  
**Script**: `agent/scripts/acp.design-create.sh`  

**Similar to @acp.pattern-create** with design-specific fields.

### 4. @acp.package-validate

**Command**: [`agent/commands/acp.package-validate.md`](../commands/acp.package-validate.md)  
**Script**: `agent/scripts/acp.package-validate.sh`  

**Validation Checks**:

**Shell-Based** (fast, no LLM):
- ✅ package.yaml is valid YAML (via acp.yaml-validate.sh)
- ✅ Required fields present
- ✅ Version format valid (semver regex)
- ✅ All files in contents exist
- ✅ All agent/ files listed in contents
- ✅ Namespace consistency (filenames)
- ✅ Git repository initialized
- ✅ Git remote configured
- ✅ Remote repository accessible

**LLM-Based** (thorough, requires agent):
- ✅ Documentation sections complete
- ✅ Content quality and clarity
- ✅ README.md structure correct
- ✅ Namespace consistency (file content)

**Test Installation**:
- Create temp directory
- Install package to temp
- Validate installation
- Clean up

**Auto-Fix**:
- Add missing files to package.yaml
- Add namespace prefix to files
- Create missing README sections
- Initialize git repository
- Add git remote
- Prompt for missing information

**Output**: Chat window with comprehensive report  

### 5. @acp.package-publish

**Command**: [`agent/commands/acp.package-publish.md`](../commands/acp.package-publish.md)  
**Script**: `agent/scripts/acp.package-publish.sh`  

**Workflow**:

**Phase 1: Non-Destructive Checks**
- Run @acp.package-validate
- Check working directory clean
- Check current branch valid
- Check remote not ahead
- Generate report

**Phase 2: Fix Issues** (if validation failed)
- Show comprehensive report
- Offer to fix automatically
- User chooses: all at once or step-by-step
- Re-run validation after fixes

**Phase 3: Version Management**
- Analyze commits since last tag
- Detect version bump type (Conventional Commits)
- Show recommendation with reasoning
- User confirms or overrides
- Update package.yaml version
- Generate CHANGELOG entry (LLM)
- Update CHANGELOG.md

**Phase 4: Publish**
- Commit changes (via @git.commit logic)
- Create git tag (v{version})
- Push commits and tags
- Wait for GitHub processing
- Test installation from remote
- Report final status

**Branch Validation**:
- Check against package.yaml release.branch
- Default branches: main, master, mainline, release
- User can configure additional branches

### 6. Rewritten @acp.package-create

**New Workflow**:
1. Collect package information via chat (existing)
2. Collect target directory (existing)
3. Collect release branch name (new)
4. Create target directory
5. **Run acp.install.sh in target directory** (new)
6. Create package.yaml with metadata
7. Configure release branch in package.yaml (new)
8. Initialize git repository
9. **Install pre-commit hook** (new)
10. Create initial commit
11. Display next steps

**No Example Files**:
- Remove example file creation
- Users have templates from ACP installation

### 7. Pre-Commit Hook

**File**: `.git/hooks/pre-commit`  

**Initial Scope** (simple):
```bash
#!/bin/sh
# ACP Package Pre-Commit Hook
# Validates package.yaml before allowing commit

# Source validation script
. ./agent/scripts/acp.yaml-validate.sh

# Validate package.yaml
if ! validate_yaml_file "package.yaml" "agent/schemas/package.schema.yaml"; then
    echo "Error: package.yaml validation failed"
    echo "Fix errors and try again"
    exit 1
fi

# Future enhancements:
# - Namespace consistency checking
# - CHANGELOG.md validation for version changes
# - File existence verification

exit 0
```

---

## Benefits

### 1. Streamlined Package Development
- Create entities with single command
- Automatic namespace enforcement
- Auto-update package.yaml and README.md
- No manual file management

### 2. Quality Assurance
- Comprehensive validation before publishing
- Auto-fix common issues
- LLM validates content quality
- Test installation before release

### 3. Version Management
- Intelligent version bump detection
- Automatic CHANGELOG generation
- Git tag creation
- Conventional Commits integration

### 4. Error Prevention
- Pre-commit hooks catch issues early
- Namespace validation prevents conflicts
- Schema validation ensures valid YAML
- Test installation catches installation issues

### 5. Developer Experience
- Draft file support for iterative development
- Clarification workflow for ambiguous drafts
- Context-aware behavior (package vs project)
- Comprehensive error reporting with fixes

---

## Trade-offs

### 1. Complexity vs Simplicity
**Trade-off**: System is more complex than simple file creation  

**Mitigation**:
- Commands handle complexity automatically
- Users just provide information
- Clear documentation and examples
- Incremental adoption (can still create files manually)

### 2. Pure Bash Constraint
**Trade-off**: YAML schema validation limited in pure bash  

**Mitigation**:
- Start with basic validation
- LLM handles complex validation
- Incremental enhancement over time
- Hybrid approach (bash + LLM)

### 3. LLM Dependency
**Trade-off**: Some features require LLM (CHANGELOG generation, content validation)  

**Mitigation**:
- Shell validation works without LLM
- LLM features are enhancements
- Clear separation of shell vs LLM features
- Graceful degradation if LLM unavailable

### 4. Git Hook Strictness
**Trade-off**: No easy bypass for pre-commit hook  

**Mitigation**:
- Hook starts simple (minimal checks)
- User can edit hook file if truly needed
- Encourages proper validation workflow
- Documented in README.md

---

## Testing Strategy

### Unit Testing
- Test each utility function in common.sh
- Test YAML schema validator with valid/invalid inputs
- Test namespace inference with various scenarios
- Test README update logic

### Integration Testing
- Test entity creation end-to-end
- Test validation with various package states
- Test publishing workflow
- Test auto-fix capabilities

### End-to-End Testing
- Create package from scratch
- Add patterns, commands, designs
- Validate package
- Publish package
- Install published package
- Verify everything works

---

## Success Metrics

### Adoption
- Package authors use entity creation commands
- Validation catches issues before publishing
- Publishing workflow reduces errors

### Quality
- Packages have consistent structure
- Namespace conventions followed
- Valid package.yaml in all packages
- Complete documentation

### Efficiency
- Time to create pattern: < 2 minutes
- Time to publish update: < 5 minutes
- Validation catches 95%+ of issues

---

## Future Enhancements

### Phase 7: Advanced Features (Future)
- @acp.package-deprecate - Mark files as deprecated
- @acp.package-version - Manual version management
- Enhanced pre-commit hooks
- Package analytics and metrics
- VS Code extension for package development

### Phase 8: Repository Mirror (Future Consideration)
- Centralized ACP package repository
- Faster package discovery
- Package verification system
- Download statistics
- Community ratings

---

## Related Documents

- [`agent/clarifications/clarification-1-package-create-enhancements.md`](../clarifications/clarification-1-package-create-enhancements.md)
- [`agent/clarifications/clarification-2-package-development-commands.md`](../clarifications/clarification-2-package-development-commands.md)
- [`agent/clarifications/clarification-3-draft-files-schema-validation.md`](../clarifications/clarification-3-draft-files-schema-validation.md)
- [`agent/clarifications/clarification-4-implementation-edge-cases.md`](../clarifications/clarification-4-implementation-edge-cases.md)
- [`agent/design/acp-package-management-system.md`](acp-package-management-system.md)
- [`agent/commands/git.commit.md`](../commands/git.commit.md)

---

**Status**: Design Specification - Ready for Implementation  
**Recommendation**: Implement in phases via Milestone 4  
**Next Steps**: Create Milestone 4 and break into 11 tasks  
