# Task 26: Global Installation Implementation

**Milestone**: [M5 - Global Package Installation](../milestones/milestone-5-global-package-installation.md)  
**Estimated Time**: 2-3 hours  
**Dependencies**: Task 25 (Global Infrastructure Setup)  
**Status**: Not Started  

---

## Objective

Implement `--global` flag support in `@acp.package-install` command to enable installation of packages to `~/.acp/packages/` with global manifest tracking.

---

## Context

This task extends the existing package installation system to support global installation. When users specify the `--global` flag, packages are installed to `~/.acp/packages/{package-name}/` instead of the project's `./agent/` directory.

Global installation serves two purposes:
1. **Package Development**: Developers can work on packages in a standard location with full ACP tooling
2. **Global Command Library**: Common utilities can be installed once and discovered by agents in any project

The implementation reuses existing installation logic but changes the target directory and manifest file. Projects remain independent - they don't depend on global packages.

---

## Steps

### 1. Add --global Flag Parsing

Update `agent/scripts/acp.package-install.sh` to parse `--global` flag:

**Location**: Near top of script, after shebang and before main logic  

**Code to add**:
```bash
# Parse command-line arguments
GLOBAL_INSTALL=false
REPO_URL=""
INSTALL_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --global|-g)
            GLOBAL_INSTALL=true
            shift
            ;;
        --patterns|--commands|--designs|--list|-y|--yes)
            INSTALL_ARGS+=("$1")
            shift
            ;;
        --patterns=*|--commands=*|--designs=*)
            INSTALL_ARGS+=("$1")
            shift
            ;;
        *)
            if [ -z "$REPO_URL" ]; then
                REPO_URL="$1"
            else
                INSTALL_ARGS+=("$1")
            fi
            shift
            ;;
    esac
done
```

**Verification**:
- Flag parsing handles `--global` and `-g`
- Other flags preserved in INSTALL_ARGS
- REPO_URL extracted correctly

### 2. Determine Installation Directory

Add logic to choose installation directory based on `--global` flag:

**Location**: After argument parsing, before clone operation  

**Code to add**:
```bash
# Determine installation directory and manifest
if [ "$GLOBAL_INSTALL" = true ]; then
    # Global installation
    PACKAGE_NAME=$(basename "$REPO_URL" .git | sed 's/^acp-//')
    INSTALL_DIR="$HOME/.acp/packages/$PACKAGE_NAME"
    MANIFEST_FILE="$HOME/.acp/manifest.yaml"
    
    echo "${BLUE}Installing globally to ~/.acp/packages/$PACKAGE_NAME/${NC}"
    
    # Initialize global manifest if needed
    if [ ! -f "$MANIFEST_FILE" ]; then
        init_global_manifest
    fi
else
    # Local installation (existing behavior)
    INSTALL_DIR="./agent"
    MANIFEST_FILE="./agent/manifest.yaml"
    
    echo "${BLUE}Installing locally to ./agent/${NC}"
fi
```

**Verification**:
- Global installation uses `~/.acp/packages/{package-name}/`
- Local installation uses `./agent/` (unchanged)
- Global manifest initialized if missing
- Clear output shows installation mode

### 3. Update Installation Logic

Modify installation logic to handle global installation:

**Changes needed**:

1. **Clone to temporary directory** (existing behavior, no change)
2. **Copy files to installation directory**:
   - Global: Copy entire package to `~/.acp/packages/{package-name}/`
   - Local: Copy patterns/commands/designs to `./agent/` (existing)

**Code to modify**:
```bash
# After cloning to temp directory
if [ "$GLOBAL_INSTALL" = true ]; then
    # Global installation - copy entire package
    echo "${BLUE}Copying package to global location...${NC}"
    
    # Create target directory
    mkdir -p "$INSTALL_DIR"
    
    # Copy entire package structure
    cp -r "$TEMP_DIR"/* "$INSTALL_DIR/"
    
    echo "✓ Package copied to $INSTALL_DIR"
else
    # Local installation - copy patterns/commands/designs (existing logic)
    # ... existing code ...
fi
```

**Verification**:
- Global installation copies entire package
- Local installation copies only patterns/commands/designs (unchanged)
- Directory structure preserved
- All files copied successfully

### 4. Update Manifest Tracking

Update manifest tracking to use correct manifest file:

**Changes needed**:

The existing manifest functions in acp.common.sh already accept a manifest path parameter. Update calls to use `$MANIFEST_FILE` variable:

```bash
# Initialize manifest
init_manifest "$MANIFEST_FILE"

# Add package to manifest
add_package_to_manifest "$MANIFEST_FILE" "$PACKAGE_NAME" "$REPO_URL" "$VERSION" "$COMMIT_HASH"

# Add files to manifest
add_file_to_manifest "$MANIFEST_FILE" "$PACKAGE_NAME" "patterns" "$file" "$version"
```

**Verification**:
- Correct manifest file used (global or local)
- Package metadata tracked correctly
- File versions and checksums recorded
- Manifest timestamp updated

### 5. Update Success Message

Update success message to indicate installation mode:

**Code to modify**:
```bash
if [ "$GLOBAL_INSTALL" = true ]; then
    echo ""
    echo "${GREEN}✓ Package installed globally!${NC}"
    echo ""
    echo "Location: $INSTALL_DIR"
    echo "Manifest: $MANIFEST_FILE"
    echo ""
    echo "Agents can now discover this package by reading ~/.acp/manifest.yaml"
    echo ""
    echo "To use in any project:"
    echo "  1. Run @acp.init to discover global packages"
    echo "  2. Reference commands via @namespace.command"
    echo ""
    echo "To list global packages: @acp.package-list --global"
else
    # Existing local installation message
    echo ""
    echo "${GREEN}✓ Package installed successfully!${NC}"
    echo ""
    # ... existing message ...
fi
```

**Verification**:
- Success message shows installation mode
- Global installation shows discovery instructions
- Local installation message unchanged

### 6. Update Command Documentation

Update `agent/commands/acp.package-install.md` with `--global` flag documentation:

**Sections to add**:

1. **Global Installation** section in "What This Command Does"
2. **--global flag** in parameters list
3. **Global installation examples** in Examples section
4. **Global vs Local** comparison table

**Example content**:
```markdown
## Global Installation

Use the `--global` flag to install packages globally to `~/.acp/packages/`:

```bash
@acp.package-install --global https://github.com/user/acp-firebase.git
```

**Global installation**:
- Installs to `~/.acp/packages/{package-name}/`
- Tracked in `~/.acp/manifest.yaml`
- Available for discovery by agents in any project
- Useful for package development and common utilities

**Local installation** (default):
- Installs to `./agent/patterns/`, `./agent/commands/`, `./agent/design/`
- Tracked in `./agent/manifest.yaml`
- Only available in current project
- Always takes precedence over global packages
```

**Verification**:
- Documentation updated with global installation
- Examples show both global and local usage
- Clear explanation of differences

### 7. Test Global Installation

Test the complete global installation workflow:

```bash
# Test global installation
@acp.package-install --global https://github.com/prmichaelsen/acp-test-package.git

# Verify installation
ls -la ~/.acp/packages/
cat ~/.acp/manifest.yaml

# Test that package is tracked
source agent/scripts/acp.common.sh
global_package_exists "test-package" && echo "✓ Package tracked in global manifest"
get_global_package_location "test-package"
```

**Verification**:
- Package installed to `~/.acp/packages/test-package/`
- Global manifest updated with package entry
- All package files present
- Manifest contains correct metadata

---

## Verification

- [ ] `--global` flag parsing implemented
- [ ] Installation directory determined correctly (global vs local)
- [ ] Global manifest initialized if missing
- [ ] Global installation copies entire package structure
- [ ] Local installation behavior unchanged
- [ ] Manifest tracking uses correct manifest file
- [ ] Success message shows installation mode
- [ ] Command documentation updated with `--global` examples
- [ ] Global installation tested successfully
- [ ] Package tracked in global manifest
- [ ] No errors during installation
- [ ] Existing local installation still works

---

## Expected Output

### Console Output (Global Installation)
```
Installing globally to ~/.acp/packages/firebase/

✓ Cloning repository...
✓ Copying package to global location...
✓ Package copied to /home/user/.acp/packages/firebase
✓ Updating global manifest...
✓ Package metadata tracked

✓ Package installed globally!

Location: /home/user/.acp/packages/firebase
Manifest: /home/user/.acp/manifest.yaml

Agents can now discover this package by reading ~/.acp/manifest.yaml

To use in any project:
  1. Run @acp.init to discover global packages
  2. Reference commands via @namespace.command

To list global packages: @acp.package-list --global
```

### Global Manifest After Installation
```yaml
version: 1.0.0
updated: 2026-02-21T05:00:00Z

packages:
  firebase:
    name: firebase
    version: 1.2.0
    source: https://github.com/prmichaelsen/acp-firebase.git
    commit: abc123def456
    installed: 2026-02-21T05:00:00Z
    updated: 2026-02-21T05:00:00Z
    location: /home/user/.acp/packages/firebase
    files:
      patterns:
        - name: firebase.firestore-pattern.md
          version: 1.0.0
          checksum: sha256:...
      commands:
        - name: firebase.deploy.md
          version: 1.0.0
          checksum: sha256:...
```

---

## Common Issues and Solutions

### Issue 1: Global manifest not initialized

**Symptom**: Error "Global manifest not found"  

**Solution**: Run `init_global_manifest` function or create `~/.acp/manifest.yaml` manually. The script should auto-initialize, but if it doesn't, run: `source agent/scripts/acp.common.sh && init_global_manifest`  

### Issue 2: Package already exists globally

**Symptom**: Error "Package already installed globally"  

**Solution**: Remove existing package first: `@acp.package-remove --global {package-name}`, then install again. Or use `@acp.package-update --global` to update instead.  

### Issue 3: Wrong directory structure

**Symptom**: Package installed to wrong location  

**Solution**: Verify `--global` flag is parsed correctly. Check that `GLOBAL_INSTALL` variable is set to `true`. Debug with: `echo "GLOBAL_INSTALL=$GLOBAL_INSTALL"`  

### Issue 4: Manifest not updated

**Symptom**: Package installed but not in manifest  

**Solution**: Check that manifest functions are being called with correct path. Verify `$MANIFEST_FILE` points to `~/.acp/manifest.yaml` for global installations.  

---

## Resources

- [Global Package Installation Design](../design/global-package-installation.md): Complete design specification
- [acp.package-install.sh](../scripts/acp.package-install.sh): Installation script to modify
- [acp.common.sh](../scripts/acp.common.sh): Shared utility functions
- [Task 25: Global Infrastructure](task-25-global-infrastructure.md): Prerequisites

---

## Notes

- Reuses existing installation logic where possible
- Only changes: target directory and manifest file
- Global installation copies entire package (not just patterns/commands/designs)
- Local installation behavior completely unchanged
- `--global` flag can be combined with `--patterns`, `--commands`, etc. (selective installation)
- Global packages are independent from projects (no dependencies created)
- This enables package development in standard location with full ACP tooling

---

**Next Task**: [task-27-global-package-commands.md](task-27-global-package-commands.md)  
**Related Design Docs**: [global-package-installation.md](../design/global-package-installation.md)  
**Estimated Completion Date**: TBD  
