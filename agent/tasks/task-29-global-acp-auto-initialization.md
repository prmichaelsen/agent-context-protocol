# Task 29: Global ACP Auto-Initialization

**Milestone**: [M5 - Global Package Installation](../milestones/milestone-5-global-package-installation.md)  
**Estimated Time**: 1-2 hours  
**Dependencies**: None (can be done in parallel with Task 25)  
**Status**: Not Started  

---

## Objective

Implement automatic initialization of `~/.acp/` infrastructure when users first use global package features, eliminating the need for manual global setup.

---

## Context

This task implements the design from [`global-acp-installation.md`](../design/global-acp-installation.md). Instead of requiring users to manually set up global infrastructure, the system automatically initializes `~/.acp/` when they first use global features like `@acp.package-install --global`.

**Key Benefit**: "It just works" - users don't need to think about global installation, it happens automatically when needed.  

**Triggers for auto-initialization**:
- `@acp.package-install --global` - Initialize before installing package
- `@acp.package-create` (when target is `~/.acp/projects/`) - Initialize before creating package
- `@acp.package-list --global` - Initialize before listing (creates empty manifest)

This task can be done in parallel with Task 25 since it provides an alternative approach to global infrastructure setup.

---

## Steps

### 1. Create init_global_acp() Function

Add auto-initialization function to acp.common.sh:

**Location**: `agent/scripts/acp.common.sh` (after existing initialization functions)  

**Function to add**:
```bash
# Initialize global ACP infrastructure if it doesn't exist
# This function is idempotent - safe to call multiple times
init_global_acp() {
    local global_dir="$HOME/.acp"
    
    # Check if already initialized
    if [ -d "$global_dir/agent" ] && [ -f "$global_dir/AGENT.md" ]; then
        return 0  # Already initialized, nothing to do
    fi
    
    echo "${BLUE}Initializing global ACP infrastructure at ~/.acp/...${NC}"
    echo ""
    
    # Create ~/.acp directory
    mkdir -p "$global_dir"
    
    # Get the directory where acp.common.sh is located
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Run standard ACP installation in ~/.acp/
    # This installs all templates, scripts, and schemas
    if [ -f "$script_dir/acp.install.sh" ]; then
        # Use local install script
        (
            cd "$global_dir" || exit 1
            bash "$script_dir/acp.install.sh"
        ) || {
            echo "${RED}Error: Failed to initialize global ACP infrastructure${NC}" >&2
            return 1
        }
    else
        # Fallback: Download from repository
        (
            cd "$global_dir" || exit 1
            curl -fsSL https://raw.githubusercontent.com/prmichaelsen/agent-context-protocol/mainline/agent/scripts/acp.install.sh | bash
        ) || {
            echo "${RED}Error: Failed to initialize global ACP infrastructure${NC}" >&2
            return 1
        }
    fi
    
    # Create additional global directories
    mkdir -p "$global_dir/packages"
    mkdir -p "$global_dir/projects"
    
    # Create global manifest if it doesn't exist
    if [ ! -f "$global_dir/manifest.yaml" ]; then
        cat > "$global_dir/manifest.yaml" << EOF
# Global ACP Package Manifest
version: 1.0.0
updated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

packages: {}
EOF
    fi
    
    # Append global installation notes to AGENT.md
    if [ -f "$global_dir/AGENT.md" ] && ! grep -q "## Global Installation" "$global_dir/AGENT.md"; then
        cat >> "$global_dir/AGENT.md" << 'EOF'

---

## Global Installation

This is a global ACP installation located at `~/.acp/`.

### Purpose

This installation provides:
- **Global packages** in `~/.acp/packages/` - Packages installed with `@acp.package-install --global`
- **Project workspace** in `~/.acp/projects/` - Optional location for package development
- **Global manifest** in `~/.acp/manifest.yaml` - Tracks globally installed packages
- **Templates and scripts** in `~/.acp/agent/` - All ACP templates and utilities

### Usage

**Install packages globally**:
```bash
@acp.package-install --global https://github.com/user/acp-package.git
```

**Create packages**:
```bash
cd ~/.acp/projects
@acp.package-create
```

**List global packages**:
```bash
@acp.package-list --global
```

### Discovery

Agents can discover globally installed packages by reading `~/.acp/manifest.yaml`. Local packages always take precedence over global packages.
EOF
    fi
    
    echo ""
    echo "${GREEN}✓ Global ACP infrastructure initialized${NC}"
    echo ""
    echo "Location: $global_dir"
    echo "Templates: $global_dir/agent/"
    echo "Packages: $global_dir/packages/"
    echo "Projects: $global_dir/projects/"
    echo ""
}
```

**Verification**:
- Function added to acp.common.sh
- Function is idempotent (safe to call multiple times)
- Uses local install script if available, falls back to remote
- Creates all necessary directories
- Appends global notes to AGENT.md
- Returns 0 on success, 1 on failure

### 2. Update acp.package-install.sh

Call `init_global_acp()` when `--global` flag is used:

**Location**: After parsing `--global` flag, before installation logic  

**Code to add**:
```bash
# Initialize global infrastructure if needed
if [ "$GLOBAL_INSTALL" = true ]; then
    # Source common functions if not already sourced
    if ! command -v init_global_acp &> /dev/null; then
        source "$(dirname "$0")/acp.common.sh"
    fi
    
    # Initialize global ACP infrastructure
    init_global_acp || {
        echo "${RED}Error: Failed to initialize global infrastructure${NC}" >&2
        exit 1
    }
fi
```

**Verification**:
- Function called before global installation
- Errors handled gracefully
- Installation proceeds only if initialization succeeds

### 3. Update acp.package-create.sh

Call `init_global_acp()` when creating packages in `~/.acp/projects/`:

**Location**: After determining target directory, before package creation  

**Code to add**:
```bash
# Initialize global infrastructure if creating in ~/.acp/projects/
if [[ "$TARGET_DIR" == "$HOME/.acp/projects/"* ]] || [[ "$TARGET_DIR" == ~/.acp/projects/* ]]; then
    # Source common functions if not already sourced
    if ! command -v init_global_acp &> /dev/null; then
        source "$(dirname "$0")/acp.common.sh"
    fi
    
    # Initialize global ACP infrastructure
    init_global_acp || {
        echo "${RED}Error: Failed to initialize global infrastructure${NC}" >&2
        exit 1
    }
fi
```

**Verification**:
- Function called when target is in ~/.acp/projects/
- Path matching handles both $HOME and ~ expansion
- Errors handled gracefully

### 4. Update acp.package-list.sh

Call `init_global_acp()` when `--global` flag is used:

**Location**: After parsing `--global` flag, before reading manifest  

**Code to add**:
```bash
# Initialize global infrastructure if needed
if [ "$GLOBAL_MODE" = true ]; then
    # Source common functions if not already sourced
    if ! command -v init_global_acp &> /dev/null; then
        source "$(dirname "$0")/acp.common.sh"
    fi
    
    # Initialize global ACP infrastructure (creates empty manifest if needed)
    init_global_acp || {
        echo "${RED}Error: Failed to initialize global infrastructure${NC}" >&2
        exit 1
    }
fi
```

**Verification**:
- Function called before listing global packages
- Creates empty manifest if none exists
- Allows listing to work even with no packages installed

### 5. Test Auto-Initialization

Test that auto-initialization works correctly:

```bash
# Test 1: First global package installation
# (Ensure ~/.acp/ doesn't exist first)
rm -rf ~/.acp/
@acp.package-install --global https://github.com/prmichaelsen/acp-test-package.git

# Verify:
# - Initialization message displayed
# - ~/.acp/ created with full structure
# - Package installed successfully

# Test 2: Subsequent global operations (no re-initialization)
@acp.package-list --global

# Verify:
# - No initialization message
# - Command works immediately

# Test 3: Package creation in ~/.acp/projects/
rm -rf ~/.acp/
@acp.package-create
# (Choose target: ~/.acp/projects/my-package)

# Verify:
# - Initialization message displayed
# - Package created successfully
```

**Verification**:
- Auto-initialization works on first use
- No re-initialization on subsequent uses
- All global commands trigger initialization
- Initialization is fast (<5 seconds)

### 6. Update Documentation

Update command documentation to mention auto-initialization:

**Files to update**:
- [`agent/commands/acp.package-install.md`](../commands/acp.package-install.md) - Add note about auto-initialization
- [`agent/commands/acp.package-create.md`](../commands/acp.package-create.md) - Add note about auto-initialization
- [`agent/commands/acp.package-list.md`](../commands/acp.package-list.md) - Add note about auto-initialization

**Example note to add**:
```markdown
### Auto-Initialization

When using the `--global` flag for the first time, the system automatically initializes `~/.acp/` infrastructure:
- Creates `~/.acp/` directory
- Installs full ACP (templates, scripts, schemas)
- Creates `~/.acp/packages/` and `~/.acp/projects/` directories
- Creates `~/.acp/manifest.yaml` for package tracking

This happens automatically - no manual setup required.
```

**Verification**:
- Documentation updated in 3 command files
- Auto-initialization explained clearly
- Users know what to expect

---

## Verification

- [ ] `init_global_acp()` function added to acp.common.sh
- [ ] Function is idempotent (safe to call multiple times)
- [ ] Function installs full ACP to ~/.acp/
- [ ] Function creates packages/ and projects/ directories
- [ ] Function creates global manifest
- [ ] Function appends global notes to AGENT.md
- [ ] acp.package-install.sh calls init_global_acp() when --global
- [ ] acp.package-create.sh calls init_global_acp() when target is ~/.acp/projects/
- [ ] acp.package-list.sh calls init_global_acp() when --global
- [ ] Auto-initialization tested successfully
- [ ] No re-initialization on subsequent uses
- [ ] Command documentation updated with auto-initialization notes
- [ ] All tests pass

---

## Expected Output

### First Global Package Installation
```
Initializing global ACP infrastructure at ~/.acp/...

✓ Installing ACP to ~/.acp/
✓ Created agent/ directory structure
✓ Copied templates and scripts
✓ Created packages/ directory
✓ Created projects/ directory
✓ Created global manifest

✓ Global ACP infrastructure initialized

Location: /home/user/.acp
Templates: /home/user/.acp/agent/
Packages: /home/user/.acp/packages/
Projects: /home/user/.acp/projects/

Installing acp-firebase globally...
✓ Package installed to ~/.acp/packages/@user/acp-firebase
✓ Updated ~/.acp/manifest.yaml

✅ Package installed globally!
```

### Subsequent Global Operations (No Initialization)
```
Installing acp-git globally...
✓ Package installed to ~/.acp/packages/@user/acp-git
✓ Updated ~/.acp/manifest.yaml

✅ Package installed globally!
```

### Directory Structure After Initialization
```
~/.acp/
├── AGENT.md                     # With global installation notes
├── manifest.yaml                # Global package manifest
├── agent/                       # Full ACP installation
│   ├── commands/
│   ├── design/
│   ├── milestones/
│   ├── patterns/
│   ├── tasks/
│   ├── scripts/
│   └── schemas/
├── packages/                    # Global packages directory
└── projects/                    # Projects directory
```

---

## Common Issues and Solutions

### Issue 1: Installation script not found

**Symptom**: Error "acp.install.sh not found"  

**Solution**: Function should fallback to downloading from repository. Verify curl is installed and network connection is available.  

### Issue 2: Permission denied creating ~/.acp/

**Symptom**: Error "Permission denied"  

**Solution**: Ensure user has write permissions to home directory. This should not require sudo. Check: `ls -la ~/`  

### Issue 3: init_global_acp() called multiple times

**Symptom**: Initialization message appears on every command  

**Solution**: Bug in idempotency check. Verify that function checks for `~/.acp/agent` AND `~/.acp/AGENT.md` before initializing.  

### Issue 4: Partial initialization

**Symptom**: Some directories exist but not others  

**Solution**: Initialization failed partway through. Remove `~/.acp/` and try again: `rm -rf ~/.acp/`, then run global command again.  

---

## Resources

- [Global ACP Installation Design](../design/global-acp-installation.md): Complete design specification
- [acp.common.sh](../scripts/acp.common.sh): Shared utility functions
- [acp.install.sh](../scripts/acp.install.sh): Standard installation script
- [Task 25: Global Infrastructure](task-25-global-infrastructure.md): Related task

---

## Notes

- This task provides auto-initialization, Task 25 provides manual initialization
- Both approaches are valid and can coexist
- Auto-initialization uses standard acp.install.sh for consistency
- Function is idempotent - safe to call on every global command
- Fast check (just file existence) makes overhead negligible
- Users never need to think about "installing ACP globally"
- This is a "progressive enhancement" - features work automatically when needed
- Can be implemented in parallel with Task 25 (different approaches to same goal)

---

**Next Task**: Task 25 or Task 26 (can be done in any order)  
**Related Design Docs**: [global-acp-installation.md](../design/global-acp-installation.md), [global-package-installation.md](../design/global-package-installation.md)  
**Estimated Completion Date**: TBD  
