# Task 27: Global Package Commands

**Milestone**: [M5 - Global Package Installation](../milestones/milestone-5-global-package-installation.md)  
**Estimated Time**: 2-3 hours  
**Dependencies**: Task 26 (Global Installation Implementation)  
**Status**: Not Started  

---

## Objective

Add `--global` flag support to package management commands (`@acp.init`, `@acp.package-list`, `@acp.package-update`, `@acp.package-remove`, `@acp.package-info`) to enable management and discovery of globally installed packages.

---

## Context

With global installation implemented (Task 26), users need commands to manage globally installed packages. This task adds `--global` flag support to existing package management commands, enabling users to:

1. **Discover global packages** via `@acp.init`
2. **List global packages** via `@acp.package-list --global`
3. **Update global packages** via `@acp.package-update --global`
4. **Remove global packages** via `@acp.package-remove --global`
5. **View global package info** via `@acp.package-info --global`

Each command operates on the global manifest (`~/.acp/manifest.yaml`) and global package directory (`~/.acp/packages/`) when the `--global` flag is present.

---

## Steps

### 1. Update @acp.init Command

Enhance `@acp.init` to discover and report globally installed packages:

**File**: `agent/commands/acp.init.md`  

**Changes**:
1. Add new step after "Read All Agent Documentation":
   - **Step 2.5: Discover Global Packages**
   - Read `~/.acp/manifest.yaml` if it exists
   - List globally installed packages
   - Report package names, versions, and available commands/patterns
   - Note: This is informational only, not required

2. Update "Report Status and Next Steps" to include global packages:
   - Show count of global packages discovered
   - List global package names
   - Note that local packages take precedence

**Example output addition**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🌐 Global Packages Discovered...
  ✓ Read ~/.acp/manifest.yaml
  
  Found 2 global packages:
    • @prmichaelsen/acp-git (v1.0.0)
      - 2 commands: git.commit, git.init
    • @prmichaelsen/acp-firebase (v1.2.0)
      - 3 patterns, 2 commands
  
  ℹ️  Local packages take precedence over global packages
```

**Verification**:
- Step 2.5 added to command document
- Output section updated with global packages
- Clear that this is optional (graceful if no global packages)

### 2. Update @acp.package-list Script

Add `--global` flag to list global packages:

**File**: `agent/scripts/acp.package-list.sh`  

**Changes**:
```bash
# Parse arguments
GLOBAL_MODE=false
VERBOSE=false
FILTER=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --global|-g)
            GLOBAL_MODE=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --outdated|--modified)
            FILTER="$1"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Determine manifest file
if [ "$GLOBAL_MODE" = true ]; then
    MANIFEST_FILE="$HOME/.acp/manifest.yaml"
    echo "${BLUE}Global Packages (installed to ~/.acp/packages/):${NC}"
    echo ""
else
    MANIFEST_FILE="./agent/manifest.yaml"
    echo "${BLUE}Installed Packages:${NC}"
    echo ""
fi

# Rest of script uses $MANIFEST_FILE
```

**Verification**:
- `--global` flag parsed correctly
- Uses global manifest when flag present
- Uses local manifest by default
- Output header indicates mode

### 3. Update @acp.package-update Script

Add `--global` flag to update global packages:

**File**: `agent/scripts/acp.package-update.sh`  

**Changes**:
```bash
# Parse arguments
GLOBAL_MODE=false
CHECK_ONLY=false
SKIP_MODIFIED=false
FORCE_UPDATE=false
AUTO_YES=false
PACKAGE_NAME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --global|-g)
            GLOBAL_MODE=true
            shift
            ;;
        --check)
            CHECK_ONLY=true
            shift
            ;;
        --skip-modified)
            SKIP_MODIFIED=true
            shift
            ;;
        --force)
            FORCE_UPDATE=true
            shift
            ;;
        -y|--yes)
            AUTO_YES=true
            shift
            ;;
        *)
            PACKAGE_NAME="$1"
            shift
            ;;
    esac
done

# Determine manifest and installation directory
if [ "$GLOBAL_MODE" = true ]; then
    MANIFEST_FILE="$HOME/.acp/manifest.yaml"
    INSTALL_BASE="$HOME/.acp/packages"
    echo "${BLUE}Updating global packages...${NC}"
else
    MANIFEST_FILE="./agent/manifest.yaml"
    INSTALL_BASE="./agent"
    echo "${BLUE}Updating local packages...${NC}"
fi
```

**Verification**:
- `--global` flag parsed correctly
- Updates packages in `~/.acp/packages/` when global
- Updates packages in `./agent/` when local
- Clear output shows update mode

### 4. Update @acp.package-remove Script

Add `--global` flag to remove global packages:

**File**: `agent/scripts/acp.package-remove.sh`  

**Changes**:
```bash
# Parse arguments
GLOBAL_MODE=false
KEEP_MODIFIED=false
AUTO_YES=false
PACKAGE_NAME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --global|-g)
            GLOBAL_MODE=true
            shift
            ;;
        --keep-modified)
            KEEP_MODIFIED=true
            shift
            ;;
        -y|--yes)
            AUTO_YES=true
            shift
            ;;
        *)
            PACKAGE_NAME="$1"
            shift
            ;;
    esac
done

# Determine manifest and installation directory
if [ "$GLOBAL_MODE" = true ]; then
    MANIFEST_FILE="$HOME/.acp/manifest.yaml"
    PACKAGE_DIR=$(get_global_package_location "$PACKAGE_NAME")
    echo "${BLUE}Removing global package: $PACKAGE_NAME${NC}"
else
    MANIFEST_FILE="./agent/manifest.yaml"
    # Existing local removal logic
    echo "${BLUE}Removing local package: $PACKAGE_NAME${NC}"
fi
```

**Note**: For global removal, delete entire package directory, not individual files.  

**Verification**:
- `--global` flag parsed correctly
- Removes from `~/.acp/packages/` when global
- Removes from `./agent/` when local
- Updates correct manifest file

### 5. Update @acp.package-info Script

Add `--global` flag to show global package info:

**File**: `agent/scripts/acp.package-info.sh`  

**Changes**:
```bash
# Parse arguments
GLOBAL_MODE=false
PACKAGE_NAME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --global|-g)
            GLOBAL_MODE=true
            shift
            ;;
        *)
            PACKAGE_NAME="$1"
            shift
            ;;
    esac
done

# Determine manifest file
if [ "$GLOBAL_MODE" = true ]; then
    MANIFEST_FILE="$HOME/.acp/manifest.yaml"
    echo "${BLUE}Global Package Information:${NC}"
else
    MANIFEST_FILE="./agent/manifest.yaml"
    echo "${BLUE}Package Information:${NC}"
fi
```

**Verification**:
- `--global` flag parsed correctly
- Reads global manifest when flag present
- Shows global package details
- Output header indicates mode

### 6. Update Command Documentation

Update all command documentation files with `--global` flag:

**Files to update**:
1. `agent/commands/acp.init.md` - Add global discovery step
2. `agent/commands/acp.package-list.md` - Add `--global` flag and examples
3. `agent/commands/acp.package-update.md` - Add `--global` flag and examples
4. `agent/commands/acp.package-remove.md` - Add `--global` flag and examples
5. `agent/commands/acp.package-info.md` - Add `--global` flag and examples

**For each file, add**:
- Parameter description for `--global` flag
- Usage examples with global flag
- Note about global vs local behavior
- Security considerations for global operations

**Example parameter documentation**:
```markdown
### Parameters

- `--global`, `-g` (optional): Operate on global packages in `~/.acp/packages/` instead of local packages in `./agent/`
```

**Example usage**:
```markdown
### Example 3: List Global Packages

**Context**: Want to see all globally installed packages  

**Invocation**: `@acp.package-list --global`  

**Result**: Lists all packages from `~/.acp/manifest.yaml` with their locations in `~/.acp/packages/`  
```

**Verification**:
- All 5 command documents updated
- `--global` flag documented consistently
- Examples show global usage
- Clear explanation of global vs local

### 7. Test All Global Commands

Test each command with `--global` flag:

```bash
# Test global package list
@acp.package-list --global

# Test global package info
@acp.package-info --global test-package

# Test global package update (if package exists)
@acp.package-update --global test-package --check

# Test global package removal (with confirmation)
@acp.package-remove --global test-package

# Test @acp.init discovers global packages
@acp.init
```

**Verification**:
- All commands execute without errors
- Commands operate on global manifest
- Commands show correct output for global mode
- `@acp.init` discovers and reports global packages
- No impact on local packages

---

## Verification

- [ ] `@acp.init` discovers global packages from `~/.acp/manifest.yaml`
- [ ] `@acp.init` reports global package names and versions
- [ ] `@acp.package-list --global` lists global packages
- [ ] `@acp.package-update --global` updates global packages only
- [ ] `@acp.package-remove --global` removes from global location only
- [ ] `@acp.package-info --global` shows global package details
- [ ] All scripts parse `--global` flag correctly
- [ ] All scripts use correct manifest file (global vs local)
- [ ] All command documentation updated with `--global` examples
- [ ] Global operations don't affect local packages
- [ ] Local operations don't affect global packages
- [ ] All commands tested successfully

---

## Expected Output

### @acp.init with Global Packages
```
🚀 Initializing Agent Context

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Checking for ACP updates...
  Current version: 2.11.0
  Status: Up to date

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📚 Reading Agent Documentation...
  ✓ Read agent/progress.yaml
  ✓ Read agent/design/requirements.md
  ...
  
  Total: 9 agent files read

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🌐 Global Packages Discovered...
  ✓ Read ~/.acp/manifest.yaml
  
  Found 2 global packages:
    • @prmichaelsen/acp-git (v1.0.0)
      Location: ~/.acp/packages/@prmichaelsen/acp-git
      2 commands: git.commit, git.init
    
    • @prmichaelsen/acp-firebase (v1.2.0)
      Location: ~/.acp/packages/@prmichaelsen/acp-firebase
      3 patterns, 2 commands
  
  ℹ️  Local packages take precedence over global packages

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Rest of initialization output...]
```

### @acp.package-list --global
```
Global Packages (installed to ~/.acp/packages/):

  @prmichaelsen/acp-git (v1.0.0)
    Location: ~/.acp/packages/@prmichaelsen/acp-git
    Installed: 2026-02-21
    2 commands, 0 patterns, 0 designs

  @prmichaelsen/acp-firebase (v1.2.0)
    Location: ~/.acp/packages/@prmichaelsen/acp-firebase
    Installed: 2026-02-20
    2 commands, 3 patterns, 1 design

Total: 2 global packages
```

### @acp.package-update --global
```
Updating global packages...

Checking for updates:
  • @prmichaelsen/acp-git: v1.0.0 → v1.1.0 (update available)
  • @prmichaelsen/acp-firebase: v1.2.0 (up to date)

Update @prmichaelsen/acp-git to v1.1.0? (Y/n): y

✓ Updated @prmichaelsen/acp-git to v1.1.0
✓ Updated ~/.acp/manifest.yaml

Note: Projects using local installations are not affected
```

---

## Common Issues and Solutions

### Issue 1: Global manifest not found

**Symptom**: Error "Cannot read ~/.acp/manifest.yaml"  

**Solution**: Global infrastructure not set up. Run Task 25 first to create global directory structure. Or install a package globally to auto-initialize: `@acp.package-install --global {repo-url}`  

### Issue 2: Commands don't recognize --global flag

**Symptom**: Error "Unknown option: --global"  

**Solution**: Ensure scripts are updated with flag parsing. Check that `--global|-g)` case is added to argument parsing loop.  

### Issue 3: @acp.init doesn't show global packages

**Symptom**: No global packages section in output  

**Solution**: Verify `~/.acp/manifest.yaml` exists and contains packages. Check that Step 2.5 is implemented in acp.init.md. If manifest is empty, install a package globally first.  

### Issue 4: Global operations affect local packages

**Symptom**: Local packages modified when using `--global` flag  

**Solution**: Bug in script - verify that `$MANIFEST_FILE` is set correctly based on `$GLOBAL_MODE`. Global should use `$HOME/.acp/manifest.yaml`, local should use `./agent/manifest.yaml`.  

---

## Resources

- [Global Package Installation Design](../design/global-package-installation.md): Complete design specification
- [acp.init.md](../commands/acp.init.md): Init command to update
- [acp.package-list.sh](../scripts/acp.package-list.sh): List script to update
- [acp.package-update.sh](../scripts/acp.package-update.sh): Update script to update
- [acp.package-remove.sh](../scripts/acp.package-remove.sh): Remove script to update
- [acp.package-info.sh](../scripts/acp.package-info.sh): Info script to update

---

## Notes

- All scripts already have argument parsing - just add `--global` case
- Global operations are completely independent from local operations
- `@acp.init` global discovery is optional (graceful if no global packages)
- Local packages always take precedence (documented in output)
- Global manifest uses same format as local manifest (reuse existing functions)
- Scripts should validate that global manifest exists before operating on it
- Consider adding `--all` flag to update/remove commands to affect both global and local

---

**Next Task**: [task-28-global-documentation.md](task-28-global-documentation.md)  
**Related Design Docs**: [global-package-installation.md](../design/global-package-installation.md)  
**Estimated Completion Date**: TBD  
