# Task 103: Package Index Support

**Milestone**: [M14 - Key File Index System](../../milestones/milestone-14-key-file-index-system.md)  
**Estimated Time**: 3-4 hours  
**Dependencies**: [Task 99](task-99-index-directory-infrastructure.md)  
**Status**: Completed  

---

## Objective

Update the package system to support shipping and installing index files, so packages can declare their own key files that get automatically discovered by the agent.

---

## Context

Packages like core-sdk ship many patterns, but users don't know which ones are most important. By shipping an index file (e.g., `core-sdk.main.yaml`), packages can declare their critical files with weights and descriptions. On install, these index files land in `agent/index/` and are automatically picked up.

---

## Steps

### 1. Extend package.yaml Schema

Add `indices` as a new content type in package.yaml:

```yaml
contents:
  indices:
    - name: core-sdk.main.yaml
      description: Key patterns and designs for core-sdk
```

### 2. Update @acp.package-install

Modify `acp.package-install.sh` to:
- Detect `indices` in package.yaml contents
- Copy index files from package to `agent/index/{name}`
- Track in manifest.yaml under `files.indices`
- Package index weights should be 0.3-0.7 by convention (lower than local)

### 3. Update @acp.package-remove

Modify `acp.package-remove.sh` to:
- Remove package index files from `agent/index/` on package removal
- Update manifest.yaml

### 4. Update @acp.package-update

Modify `acp.package-update.sh` to:
- Update index files when package is updated
- Respect local modifications (same conflict detection as other files)

### 5. Update @acp.package-validate

Validate that package index files:
- Follow `{namespace}.{qualifier}.yaml` naming
- Namespace matches the package name
- All entries have required fields
- Weights are in appropriate range for packages (warn if > 0.7)

### 6. Update @acp.package-info

Show index files in package info output.

---

## Verification

- [ ] Package.yaml accepts `indices` in contents
- [ ] `@acp.package-install` copies index files to `agent/index/`
- [ ] `@acp.package-remove` removes index files
- [ ] `@acp.package-update` handles index file updates
- [ ] `@acp.package-validate` validates index files in packages
- [ ] `@acp.package-info` displays index files
- [ ] Manifest tracks index files under `files.indices`
