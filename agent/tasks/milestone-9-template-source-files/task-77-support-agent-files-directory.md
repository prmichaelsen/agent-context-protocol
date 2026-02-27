# Task 77: Support agent/files/ Directory in Package Installer

**Milestone**: [M9 - Template Source Files Support](../../milestones/milestone-9-template-source-files.md)
**Estimated Time**: 4-6 hours
**Dependencies**: None (can be done independently of Tasks 71-76)
**Status**: Completed

---

## Objective

Extend `acp.package-install.sh` to support `agent/files/` as an installable directory, and fix manifest tracking so installed files are properly recorded. This addresses GitHub Issue #6.

---

## Context

The package installer currently only processes four directories: `commands/`, `patterns/`, `design/`, and `scripts/`. Packages that ship source code or assets in `agent/files/` (e.g., `acp-core-sdk` with TypeScript source) have that directory silently ignored during installation. Additionally, the manifest records empty arrays for installed files even when files are successfully installed.

**GitHub Issue**: https://github.com/prmichaelsen/agent-context-protocol/issues/6

**Affected Script**: `agent/scripts/acp.package-install.sh`

---

## Steps

### 1. Add `files/` to INSTALL_DIRS

Add `files` to the `INSTALL_DIRS` array in `acp.package-install.sh` so the existing scanning/copying logic processes it alongside commands, patterns, design, and scripts.

**Actions**:
- Locate the `INSTALL_DIRS` array definition
- Add `"files"` to the array
- Verify the directory scanning loop handles it correctly
- Ensure no `acp.*` namespace filtering is applied to files (only relevant for commands/scripts)

### 2. Handle files/ Directory Specifics

The `files/` directory may contain nested subdirectories (e.g., `src/client/`, `config/`). Ensure recursive copying works.

**Actions**:
- Verify the file scanning handles nested directories in `files/`
- Ensure target path maps to project root: `agent/files/src/foo.ts` -> `./src/foo.ts` (files/ contents install to `.`, not `./agent/files/`)
- Handle potential conflicts with existing files in the target project

### 3. Fix Manifest File Tracking

The manifest currently records empty arrays even when files are installed. Fix the manifest update logic to populate installed file lists.

**Actions**:
- Trace the manifest update code path in `acp.package-install.sh`
- Identify where file entries should be appended to manifest arrays
- Fix the logic so each installed file is recorded in the appropriate manifest array (patterns, commands, designs, scripts, files)
- Verify manifest correctly reflects installed content after installation

### 4. Add Warning for Unrecognized Directories

If a package contains directories not in `INSTALL_DIRS`, warn the user so content is not silently dropped.

**Actions**:
- After scanning, check for directories in the cloned package's `agent/` that aren't in `INSTALL_DIRS`
- Print a warning listing unrecognized directories (e.g., `milestones/`, `tasks/`)
- Suggest user manually copy if needed

### 5. Test Installation

**Actions**:
- Test with `acp-core-sdk` package which has `agent/files/` with TypeScript source
- Verify all files from `agent/files/` are copied to target
- Verify manifest entries are populated correctly
- Verify existing directory types (commands, patterns, design, scripts) still work
- Verify warning appears for unrecognized directories

---

## Verification

- [ ] `agent/files/` directory is processed during package installation
- [ ] Nested subdirectories within `files/` are preserved
- [ ] Manifest correctly lists all installed files (not empty arrays)
- [ ] Warning shown for unrecognized directories in package
- [ ] Existing installation behavior for commands/patterns/design/scripts unchanged
- [ ] No `acp.*` namespace filtering applied to files directory
- [ ] Integration test with `acp-core-sdk` package passes

---

## Expected Output

After fix, installing `acp-core-sdk` should show:

```
📁 files/ (N file(s)) → installs to ./
  ✓ src/client/index.ts → ./src/client/index.ts
  ✓ src/config/defaults.ts → ./src/config/defaults.ts
  ...

Manifest updated:
  files: [src/client/index.ts, src/config/defaults.ts, ...]
```

---

## Common Issues and Solutions

### Issue 1: Nested directories not created
**Symptom**: Installation fails because target subdirectories don't exist
**Solution**: Use `mkdir -p` before copying to ensure parent directories are created

### Issue 2: Manifest YAML structure mismatch
**Symptom**: Manifest has wrong structure for files array
**Solution**: Ensure manifest template includes `files: []` in the installed section

---

## Resources

- GitHub Issue #6: https://github.com/prmichaelsen/agent-context-protocol/issues/6
- `agent/scripts/acp.package-install.sh`: Main installer script
- `agent/manifest.template.yaml`: Manifest structure definition

---

## Notes

- This is a pragmatic fix that can be done independently of the full M9 template system (Tasks 71-76)
- The `files/` directory is a simpler case than `templates/` (no variable substitution needed)
- Consider whether `milestones/` and `tasks/` should also be installable (probably not by default, as they're project-specific)
- The secondary manifest tracking bug affects all directory types, not just files

---

**Next Task**: Task 72 (Template Installation System) for full template support
**Related Design Docs**: [Template Source Files Design](../../design/local.acp-template-source-files.md)
**GitHub Issue**: #6
