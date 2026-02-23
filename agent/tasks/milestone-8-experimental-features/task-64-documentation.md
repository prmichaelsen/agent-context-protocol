# Task 64: Documentation and Examples

**Milestone**: M8 - Experimental Features System
**Estimated Time**: 3-4 hours
**Dependencies**: [Task 61 - Schema and Validation](task-61-schema-validation.md), [Task 62 - Installation Filtering](task-62-installation-filtering.md), [Task 63 - Update Handling](task-63-update-handling.md)
**Status**: Not Started

---

## Objective

Update all documentation to explain the experimental features system, provide clear examples, and ensure users understand how to use and create experimental features.

---

## Context

With the experimental features system implemented, we need comprehensive documentation covering:
1. How to install packages with experimental features
2. How experimental features are marked in packages
3. How to create packages with experimental features
4. Validation requirements for experimental marking
5. Update behavior for experimental features

---

## Steps

### 1. Update @acp.package-install Command Documentation

**File**: [`agent/commands/acp.package-install.md`](../../commands/acp.package-install.md)

**Add section after existing flags**:
```markdown
### --experimental Flag

Install experimental features from the package. By default, experimental features are skipped.

**Usage**:
```bash
./agent/scripts/acp.package-install.sh --repo <url> --experimental
```

**What are experimental features?**
- Features marked as `experimental: true` in package.yaml
- Bleeding-edge features that may change or break
- Require explicit opt-in via --experimental flag
- Once installed, update normally (no flag required)

**Examples**:
```bash
# Install only stable features (default)
@acp.package-install --repo https://github.com/user/acp-firebase.git

# Install all features including experimental
@acp.package-install --repo https://github.com/user/acp-firebase.git --experimental
```

**Output**:
```
Installing commands...
  ✓ Installed: stable-command.md
  ⊘ Skipping experimental: experimental-command.md (use --experimental to install)
```
```

### 2. Update @acp.package-update Command Documentation

**File**: [`agent/commands/acp.package-update.md`](../../commands/acp.package-update.md)

**Add section**:
```markdown
## Experimental Features Behavior

The update command handles experimental features intelligently:

**Already-installed experimental features**: Updated normally (no flag required)
**New experimental features**: Skipped (use --experimental with install to add)
**Graduated features** (experimental → stable): Updated and marked as stable

**Example**:
```bash
@acp.package-update firebase

Output:
  ↻ Updating: stable-command.md
  ↻ Updating experimental: experimental-command.md  # Already installed
  ⊘ Skipping new experimental: new-feature.md       # Not installed
  🎓 Graduated to stable: formerly-experimental.md   # Now stable
```

**Rationale**: Users who opted into experimental features continue receiving updates. Users who haven't opted in are protected from new experimental features.
```

### 3. Update @acp.package-validate Command Documentation

**File**: [`agent/commands/acp.package-validate.md`](../../commands/acp.package-validate.md)

**Add validation check**:
```markdown
### Experimental Marking Consistency

Validates that experimental features are marked consistently:

**Checks**:
- If `experimental: true` in package.yaml → file MUST have `**Status**: Experimental`
- If file has `**Status**: Experimental` → package.yaml MUST have `experimental: true`

**Example Error**:
```
Validating experimental feature consistency...
  ✗ agent/commands/test.md: Marked experimental in package.yaml but missing 'Status: Experimental' in file
  ✗ agent/patterns/test.md: Has 'Status: Experimental' but not marked in package.yaml
```

**Fix**: Ensure both package.yaml and file metadata are synchronized.
```

### 4. Update AGENT.md with Experimental Features Section

**File**: [`AGENT.md`](../../AGENT.md)

**Add section after "Package Management" or in appropriate location**:
```markdown
## Experimental Features

ACP supports marking features as "experimental" to enable safe innovation without affecting stable installations.

### What are Experimental Features?

Experimental features are:
- Bleeding-edge features that may change frequently
- Features under active development
- Features that may have breaking changes
- Features requiring explicit opt-in

### Marking Features as Experimental

**In package.yaml**:
```yaml
contents:
  commands:
    - name: stable-command.md
      description: A stable command
    
    - name: experimental-command.md
      description: An experimental command
      experimental: true  # ← Mark as experimental
```

**In file metadata**:
```markdown
# Command: experimental-command

**Namespace**: mypackage
**Version**: 0.1.0
**Status**: Experimental  # ← Mark as experimental
```

### Installing Experimental Features

```bash
# Install only stable features (default)
@acp.package-install --repo https://github.com/user/package.git

# Install all features including experimental
@acp.package-install --repo https://github.com/user/package.git --experimental
```

### Updating Experimental Features

Once installed, experimental features update normally:
```bash
@acp.package-update package-name  # Updates experimental features if already installed
```

### Graduating Features

To graduate a feature from experimental to stable:
1. Remove `experimental: true` from package.yaml
2. Change `**Status**: Experimental` to `**Status**: Active` in file
3. Bump version to 1.0.0 (semantic versioning)
4. Update CHANGELOG.md noting the graduation

### Validation

Validation ensures consistency:
```bash
@acp.package-validate  # Checks experimental marking is synchronized
```

### Best Practices

1. **Use sparingly** - Only mark truly experimental features
2. **Document risks** - Explain what might change in file documentation
3. **Graduate promptly** - Move to stable once proven
4. **Version appropriately** - Use 0.x.x versions for experimental
5. **Communicate clearly** - Note experimental status in README.md
```

### 5. Update README.md with Examples

**File**: [`README.md`](../../README.md)

**Add section in Package Management area**:
```markdown
### Experimental Features

Install packages with experimental features:

```bash
# Install only stable features (default)
@acp.package-install --repo https://github.com/user/acp-firebase.git

# Install including experimental features
@acp.package-install --repo https://github.com/user/acp-firebase.git --experimental
```

**What are experimental features?**
- Bleeding-edge features that may change
- Require explicit opt-in via --experimental flag
- Once installed, update normally

See [AGENT.md](./AGENT.md#experimental-features) for complete documentation.
```

### 6. Update CHANGELOG.md

**File**: [`CHANGELOG.md`](../../CHANGELOG.md)

**Add entry for new version**:
```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added

**Experimental Features System**:
- Added `experimental` field to package.yaml schema for marking experimental features
- Added `--experimental` flag to `@acp.package-install` for opt-in installation
- Experimental features require explicit opt-in during installation
- Once installed, experimental features update normally (no flag required)
- Validation checks consistency between package.yaml and file metadata
- Graduated features (experimental → stable) automatically detected during updates
- Clear visual indicators for experimental features (⊘ skipped, ⚠ experimental, 🎓 graduated)

**Documentation**:
- Updated `@acp.package-install` command documentation with --experimental flag
- Updated `@acp.package-update` command documentation with experimental behavior
- Updated `@acp.package-validate` command documentation with consistency checks
- Added "Experimental Features" section to AGENT.md
- Added experimental features examples to README.md

### Changed

**Package Schema**:
- `agent/schemas/package.schema.yaml` now supports optional `experimental: true` field
- Backward compatible (experimental defaults to false)

**Installation Behavior**:
- Without `--experimental`: Skips features marked `experimental: true`
- With `--experimental`: Installs all features including experimental

**Update Behavior**:
- Already-installed experimental features update normally
- New experimental features are skipped (use --experimental with install)
- Graduated features automatically marked as stable

**Validation**:
- Checks experimental marking consistency (package.yaml ↔ file metadata)
- Errors if marked in one place but not the other
```

### 7. Create Example Package (Optional)

**File**: `examples/experimental-package/` (if examples directory exists)

Create a sample package demonstrating experimental features:

**package.yaml**:
```yaml
name: example-experimental
version: 1.0.0
description: Example package with experimental features
contents:
  commands:
    - name: stable-command.md
      description: A stable command
    - name: experimental-command.md
      description: An experimental command
      experimental: true
```

**README.md**:
```markdown
# Example Package with Experimental Features

This package demonstrates the experimental features system.

## Features

**Stable**:
- `stable-command.md` - A production-ready command

**Experimental** (requires --experimental flag):
- `experimental-command.md` - A bleeding-edge command under development

## Installation

```bash
# Install only stable features
@acp.package-install --repo https://github.com/user/example-experimental.git

# Install including experimental features
@acp.package-install --repo https://github.com/user/example-experimental.git --experimental
```
```

---

## Verification

- [ ] @acp.package-install.md updated with --experimental flag
- [ ] @acp.package-update.md updated with experimental behavior
- [ ] @acp.package-validate.md updated with consistency checks
- [ ] AGENT.md has "Experimental Features" section
- [ ] README.md has experimental features examples
- [ ] CHANGELOG.md has complete entry for new feature
- [ ] All examples are accurate and tested
- [ ] Documentation is clear and comprehensive
- [ ] Links between documents are correct
- [ ] Example package created (optional)

---

## Documentation Checklist

- [ ] **What**: Explain what experimental features are
- [ ] **Why**: Explain why they exist (safe innovation)
- [ ] **How**: Explain how to use them (--experimental flag)
- [ ] **When**: Explain when to mark features as experimental
- [ ] **Marking**: Explain dual marking (package.yaml + file metadata)
- [ ] **Installation**: Explain installation behavior
- [ ] **Updates**: Explain update behavior
- [ ] **Graduation**: Explain how to graduate features
- [ ] **Validation**: Explain consistency checks
- [ ] **Best Practices**: Provide guidance for package maintainers

---

## Expected Output

### Updated Documentation Structure

```
AGENT.md
  └── Experimental Features section (new)
      ├── What are Experimental Features?
      ├── Marking Features as Experimental
      ├── Installing Experimental Features
      ├── Updating Experimental Features
      ├── Graduating Features
      ├── Validation
      └── Best Practices

README.md
  └── Experimental Features section (new)
      └── Quick examples and link to AGENT.md

CHANGELOG.md
  └── [X.Y.Z] entry (new)
      ├── Added (Experimental Features System)
      ├── Changed (Schema, Installation, Update, Validation)
      └── Documentation updates

Commands
  ├── acp.package-install.md (updated)
  ├── acp.package-update.md (updated)
  └── acp.package-validate.md (updated)
```

---

## Notes

- Documentation should be clear for both users and package maintainers
- Examples should demonstrate common use cases
- Links between documents should be bidirectional
- CHANGELOG entry should be comprehensive but concise
- Consider adding FAQ section if common questions arise
- Example package helps users understand the system

---

**Milestone Complete**: After this task, Milestone 8 is complete!
**Related Design**: [`agent/design/local.experimental-features-system.md`](../../design/local.experimental-features-system.md)
