# Command: package-remove

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.package-remove` has been invoked. Follow the steps below to execute this command.

> **🔌 Driver Override Check** (TOP-OF-FILE — runs BEFORE any other step in this file)
>
> 1. Read `agent/driver.yaml`. If the file does not exist OR there is no `workflows.acp.package-remove` mapping, jump to step 5 (fallback to the markdown steps below).
> 2. Look up `bindings.workflow.run` — the MCP tool name this driver uses for workflow dispatch. If the mapping exists but `workflow.run` is unbound, surface a clear configuration error (`"workflows.acp.package-remove is mapped but bindings.workflow.run is unset in agent/driver.yaml"`) and STOP.
> 3. Invoke that MCP tool with input `{action: "start", workflow: <mapped-value>, args: <user-arguments-from-this-invocation>}`. The command is now BLOCKED — execute the workflow loop per the canonical pattern (`agent/patterns/local.driver-dispatch-directive.md`, Core Principle 6): follow each returned `instruction`, return the requested output to the same MCP tool, repeat until the workflow signals completion or termination. The workflow's final output IS this command's output. **STOP. Do NOT execute any of the markdown steps below.**
> 4. **Error handling** (one-shot AND every loop iteration):
>    - If any tool response contains an `"error"` key, surface that message to the user and STOP. Do NOT fall through to the markdown steps below — a failed dispatch is NOT permission to use the fallback.
>    - If the tool call raises an MCP infrastructure exception (server unreachable, timeout), surface the exception and STOP. Same rule.
> 5. **Fallback (only when `workflows.acp.package-remove` is unmapped or `agent/driver.yaml` is absent):** Proceed to the markdown steps below as written — they describe ACP's default behavior for this command.
>
> ⚠️  **The rest of this file is the unbound-case fallback.** If the override block above dispatched a workflow (whether it completed successfully or errored), do NOT also execute the steps below. They are "execute only if step 5 above is the path you took."

**Namespace**: acp  
**Version**: 2.0.0  
**Created**: 2026-02-18  
**Last Updated**: 2026-02-22  
**Status**: Active  
**Scripts**: acp.package-remove.sh, acp.common.sh, acp.yaml-parser.sh  

---

**Purpose**: Remove installed ACP packages and clean up manifest  
**Category**: Maintenance  
**Frequency**: As Needed  

---

## What This Command Does

This command removes installed ACP packages by deleting their files from `agent/` directories and removing their entries from `agent/manifest.yaml`. It can optionally preserve locally modified files to prevent accidental loss of customizations.

Use this command when you no longer need a package, want to clean up unused dependencies, or need to reinstall a package from scratch.

---

## Prerequisites

- [ ] ACP installed in project
- [ ] `agent/manifest.yaml` exists with installed packages
- [ ] `agent/scripts/acp.package-remove.sh` exists
- [ ] Package to remove is actually installed

---

## Steps

### 0. Display Command Header

```
⚡ @acp.package-remove
  Remove installed ACP packages and clean up manifest

  Usage:
    @acp.package-remove <package-name>             Remove package (prompted)
    @acp.package-remove -y <package-name>          Remove without confirmation
    @acp.package-remove --keep-modified <name>     Keep locally modified files

  Related:
    @acp.package-install       Install packages
    @acp.package-list          List installed packages
    @acp.package-info          Show package details
    @acp.package-update        Update packages
```

### 1. Run Package Remove Script

Execute the remove script with the package name.

**Actions**:
- Run `./agent/scripts/acp.package-remove.sh` with package name:
  ```bash
  # Interactive mode (asks for confirmation)
  ./agent/scripts/acp.package-remove.sh <package-name>
  
  # Auto-confirm mode (skips prompts)
  ./agent/scripts/acp.package-remove.sh -y <package-name>
  
  # Keep modified files
  ./agent/scripts/acp.package-remove.sh --keep-modified <package-name>
  ```
- The script will:
  - Verify package is installed
  - List files that will be removed
  - Detect locally modified files via checksums
  - Ask for confirmation (unless -y flag used)
  - Remove files (or keep modified ones if --keep-modified)
  - Remove package entry from manifest
  - Update manifest timestamp
  - Report removal summary

**Expected Outcome**: Package removed successfully  

### 2. Verify Removal

Check that files were removed correctly.

**Actions**:
- Verify files deleted from `agent/` directories
- Check `agent/manifest.yaml` no longer has package entry
- If `--keep-modified` used, verify modified files were kept
- Confirm no orphaned files remain

**Expected Outcome**: Package completely removed (or modified files kept)  

### 3. Document Removal

Update progress tracking with removal notes.

**Actions**:
- Add note to `agent/progress.yaml` about package removal
- Document which package was removed
- Note removal date
- List any kept files (if --keep-modified used)

**Expected Outcome**: Removal tracked in progress  

---

## Verification

- [ ] Script executed successfully
- [ ] Package files removed from agent/ directories
- [ ] Package entry removed from manifest
- [ ] Modified files kept if --keep-modified used
- [ ] Manifest timestamp updated
- [ ] Removal summary displayed
- [ ] No errors during removal

---

## Expected Output

### Files Modified
- `agent/manifest.yaml` - Package entry removed, timestamp updated
- `agent/patterns/*.md` - Pattern files deleted
- `agent/commands/*.md` - Command files deleted
- `agent/design/*.md` - Design files deleted

### Console Output

**Standard Removal**:
```
📦 ACP Package Remover
========================================

Package: firebase (1.2.0)

⚠️  This will remove:
  - 3 pattern(s)
  - 2 command(s)
  - 1 design(s)

Total: 6 file(s)

Remove package 'firebase'? (y/N) y

Removing files...
  ✓ Removed patterns/user-scoped-collections.md
  ✓ Removed patterns/firebase-security-rules.md
  ✓ Removed patterns/firestore-queries.md
  ✓ Removed commands/firebase.init.md
  ✓ Removed commands/firebase.migrate.md
  ✓ Removed design/firebase-architecture.md

Updating manifest...
✓ Manifest updated

✅ Removal complete!

Removed: 6 file(s)
```

**With Modified Files** (`--keep-modified`):
```
📦 ACP Package Remover
========================================

Package: firebase (1.2.0)

⚠️  This will remove:
  - 3 pattern(s)
  - 2 command(s)
  - 1 design(s)

Total: 6 file(s)

⚠️  Modified files detected:
  - patterns/firebase-security-rules.md

Modified files will be kept (--keep-modified)

Remove package 'firebase'? (y/N) y

Removing files...
  ✓ Removed patterns/user-scoped-collections.md
  ⊙ Kept patterns/firebase-security-rules.md (modified)
  ✓ Removed patterns/firestore-queries.md
  ✓ Removed commands/firebase.init.md
  ✓ Removed commands/firebase.migrate.md
  ✓ Removed design/firebase-architecture.md

Updating manifest...
✓ Manifest updated

✅ Removal complete!

Removed: 5 file(s)
Kept: 1 file(s) (modified)
```

---

## Examples

### Example 1: Remove Package

**Context**: No longer need firebase package  

**Invocation**: `@acp.package-remove firebase`  

**Result**: Prompts for confirmation, removes all 6 files, updates manifest  

### Example 2: Remove with Auto-Confirm

**Context**: Want to remove without prompts  

**Invocation**: `@acp.package-remove -y firebase`  

**Result**: Removes package immediately without confirmation  

### Example 3: Keep Modified Files

**Context**: Want to remove package but keep customized files  

**Invocation**: `@acp.package-remove --keep-modified firebase`  

**Result**: Removes 5 unmodified files, keeps 1 modified file, updates manifest  

### Example 4: Package Not Installed

**Context**: Try to remove non-existent package  

**Invocation**: `@acp.package-remove nonexistent`  

**Result**: Error message "Package not installed: nonexistent", exits without changes  

---

## Related Commands

- [`@acp.package-install`](acp.package-install.md) - Install packages
- [`@acp.package-list`](acp.package-list.md) - List installed packages
- [`@acp.package-info`](acp.package-info.md) - Show package details
- [`@acp.package-update`](acp.package-update.md) - Update packages

---

## Troubleshooting

### Issue 1: Package not found

**Symptom**: Error "Package not installed"  

**Cause**: Package name incorrect or not installed  

**Solution**: Run `@acp.package-list` to see installed packages, check spelling  

### Issue 2: Files not removed

**Symptom**: Files still exist after removal  

**Cause**: Files were modified and --keep-modified was used  

**Solution**: This is intentional. Remove manually or run without --keep-modified  

### Issue 3: Manifest corrupted after removal

**Symptom**: Manifest has syntax errors  

**Cause**: Rare edge case in awk processing  

**Solution**: Restore from git backup, reinstall packages  

---

## Security Considerations

### File Deletion
- **Deletes**: All files installed by the package
- **Preserves**: Modified files if --keep-modified used
- **Irreversible**: Deleted files cannot be recovered (unless in git)

### Best Practices
- **Use git**: Commit before removing packages
- **Review first**: Use `@acp.package-info` to see what will be removed
- **Keep modified**: Use --keep-modified if you've customized files
- **Backup**: Consider git commit or manual backup before removal

---

## Notes

- Removal is permanent (unless files are in git)
- Modified files detected via checksum comparison
- Manifest entry completely removed
- --keep-modified preserves customizations
- Safe to remove and reinstall packages
- Use `@acp.package-list --modified` to see which files would be kept

---

**Namespace**: acp  
**Command**: package-remove  
**Version**: 1.0.0  
**Created**: 2026-02-18  
**Last Updated**: 2026-02-18  
**Status**: Active  
**Compatibility**: ACP 2.0.0+  
**Author**: ACP Project  
