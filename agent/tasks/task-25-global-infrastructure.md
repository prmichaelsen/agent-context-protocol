# Task 25: Global Infrastructure Setup

**Milestone**: [M5 - Global Package Installation](../milestones/milestone-5-global-package-installation.md)  
**Estimated Time**: 2-3 hours  
**Dependencies**: None  
**Status**: Not Started  

---

## Objective

Create the `~/.acp/` directory structure with AGENT.md, manifest.yaml, and global manifest management functions to support global package installation and discovery.

---

## Context

This task establishes the foundation for global package installation. The `~/.acp/` directory serves as a centralized location for:

1. **Global packages** (`~/.acp/packages/`) - Packages installed globally for development or reuse
2. **Global manifest** (`~/.acp/manifest.yaml`) - Tracks all globally installed packages
3. **Discovery instructions** (`~/.acp/AGENT.md`) - Tells agents how to discover global packages
4. **Projects directory** (`~/.acp/projects/`) - Optional location for user projects (future monorepo support)

This infrastructure enables agents to discover and use globally installed packages while maintaining project independence. Local packages always take precedence over global packages.

---

## Steps

### 1. Create Global Directory Structure

Create the `~/.acp/` directory with all necessary subdirectories:

```bash
mkdir -p ~/.acp/packages
mkdir -p ~/.acp/projects
```

**Verification**:
- Directory `~/.acp/` exists
- Directory `~/.acp/packages/` exists
- Directory `~/.acp/projects/` exists

### 2. Create Global AGENT.md

Create `~/.acp/AGENT.md` with discovery instructions for agents:

**File**: `~/.acp/AGENT.md`  

**Content**:
```markdown
# ACP Global Packages

This directory contains globally installed ACP packages.

**Version**: 1.0.0  
**Created**: 2026-02-21  
**Purpose**: Global package installation and discovery  

---

## For Agents

When working in any project, you can discover globally installed packages by reading `~/.acp/manifest.yaml`.

Global packages provide:
- **Commands** (in `~/.acp/packages/{package}/agent/commands/`)
- **Patterns** (in `~/.acp/packages/{package}/agent/patterns/`)
- **Design documents** (in `~/.acp/packages/{package}/agent/design/`)

### Namespace Precedence

**Local packages always take precedence over global packages.**

If both local and global packages define `@firebase.deploy`:
1. Check `./agent/commands/firebase.deploy.md` (local) first
2. If not found locally, check `~/.acp/packages/*/agent/commands/firebase.deploy.md` (global)
3. Use the first match found

### Discovery Workflow

To discover available global packages:

1. **Read global manifest**: `~/.acp/manifest.yaml`
2. **Check package locations**: Each package entry contains the installation path
3. **Navigate to packages**: Read package AGENT.md and command/pattern files
4. **Use commands**: Reference via `@namespace.command` syntax

### Example Discovery

```yaml
# ~/.acp/manifest.yaml
packages:
  firebase:
    name: firebase
    version: 1.2.0
    location: /home/user/.acp/packages/@prmichaelsen/acp-firebase
    files:
      commands:
        - name: firebase.deploy.md
```

From this manifest, you know:
- Package `firebase` is installed globally
- It provides a `firebase.deploy` command
- You can read it at: `~/.acp/packages/@prmichaelsen/acp-firebase/agent/commands/firebase.deploy.md`

---

## For Users

### Installing Packages Globally

```bash
# Install a package globally
@acp.package-install --global https://github.com/user/acp-firebase.git

# List global packages
@acp.package-list --global

# Update global packages
@acp.package-update --global firebase

# Remove global packages
@acp.package-remove --global firebase
```

### Global vs Local Installation

**Global Installation** (`--global` flag):
- Installs to `~/.acp/packages/{package-name}/`
- Tracked in `~/.acp/manifest.yaml`
- Available for discovery by agents in any project
- Useful for package development and common utilities

**Local Installation** (default):
- Installs to `./agent/patterns/`, `./agent/commands/`, `./agent/design/`
- Tracked in `./agent/manifest.yaml`
- Only available in current project
- Always takes precedence over global packages

### Use Cases

**Use global installation for**:
- Package development (work on packages with full ACP tooling)
- Common utilities you use across many projects (git helpers, firebase patterns)
- Building a personal command library

**Use local installation for**:
- Project-specific packages
- Packages that are part of project dependencies
- When you want version control over package versions

---

## Directory Structure

```
~/.acp/
├── AGENT.md                     # This file - discovery instructions
├── manifest.yaml                # Global package manifest
├── packages/                    # Global packages
│   ├── @prmichaelsen/
│   │   ├── acp-firebase/
│   │   │   ├── package.yaml
│   │   │   ├── AGENT.md
│   │   │   └── agent/
│   │   │       ├── patterns/
│   │   │       │   └── firebase.firestore-pattern.md
│   │   │       └── commands/
│   │   │           └── firebase.deploy.md
│   │   └── acp-git/
│   │       ├── package.yaml
│   │       └── agent/
│   │           └── commands/
│   │               ├── git.commit.md
│   │               └── git.init.md
│   └── @someorg/
│       └── acp-mcp/
│           ├── package.yaml
│           └── agent/
│               └── commands/
│                   └── mcp.bootstrap.md
└── projects/                    # Optional: User projects (future)
    ├── my-app/
    └── another-project/
```

---

**For more information, see the main ACP documentation in your project's AGENT.md file.**
```

**Verification**:
- File `~/.acp/AGENT.md` created
- Contains discovery instructions for agents
- Documents namespace precedence rules
- Includes usage examples

### 3. Create Global Manifest Template

Create `~/.acp/manifest.yaml` with initial structure:

**File**: `~/.acp/manifest.yaml`  

**Content**:
```yaml
# Global ACP Package Manifest
# This file tracks all globally installed ACP packages

version: 1.0.0
updated: 2026-02-21T04:45:00Z

packages: {}
  # Example structure:
  # firebase:
  #   name: firebase
  #   version: 1.2.0
  #   source: https://github.com/prmichaelsen/acp-firebase.git
  #   commit: abc123def456
  #   installed: 2026-02-21T03:28:00Z
  #   updated: 2026-02-21T03:28:00Z
  #   location: /home/user/.acp/packages/@prmichaelsen/acp-firebase
  #   files:
  #     patterns:
  #       - name: firebase.firestore-pattern.md
  #         version: 1.0.0
  #         checksum: sha256:...
  #     commands:
  #       - name: firebase.deploy.md
  #         version: 1.0.0
  #         checksum: sha256:...
  #     designs:
  #       - name: firebase.architecture-design.md
  #         version: 1.0.0
  #         checksum: sha256:...
```

**Verification**:
- File `~/.acp/manifest.yaml` created
- Valid YAML structure
- Contains version and updated timestamp
- Empty packages object ready for installations

### 4. Add Global Manifest Functions to acp.common.sh

Add functions to manage global manifest operations:

**Functions to add**:

```bash
# Get global manifest path
get_global_manifest_path() {
    echo "$HOME/.acp/manifest.yaml"
}

# Check if global manifest exists
global_manifest_exists() {
    local manifest_path
    manifest_path=$(get_global_manifest_path)
    [ -f "$manifest_path" ]
}

# Initialize global manifest if it doesn't exist
init_global_manifest() {
    local manifest_path
    manifest_path=$(get_global_manifest_path)
    
    if [ -f "$manifest_path" ]; then
        return 0
    fi
    
    # Create ~/.acp directory if needed
    mkdir -p "$HOME/.acp/packages"
    mkdir -p "$HOME/.acp/projects"
    
    # Create manifest
    cat > "$manifest_path" << 'EOF'
# Global ACP Package Manifest
version: 1.0.0
updated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

packages: {}
EOF
    
    echo "✓ Initialized global manifest at $manifest_path"
}

# Read global manifest (returns full content)
read_global_manifest() {
    local manifest_path
    manifest_path=$(get_global_manifest_path)
    
    if [ ! -f "$manifest_path" ]; then
        echo "Error: Global manifest not found at $manifest_path" >&2
        return 1
    fi
    
    cat "$manifest_path"
}

# Update global manifest timestamp
update_global_manifest_timestamp() {
    local manifest_path
    manifest_path=$(get_global_manifest_path)
    
    if [ ! -f "$manifest_path" ]; then
        echo "Error: Global manifest not found" >&2
        return 1
    fi
    
    # Update timestamp using sed
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    sed -i "s/^updated: .*/updated: $timestamp/" "$manifest_path"
}

# Check if package exists in global manifest
global_package_exists() {
    local package_name="$1"
    local manifest_path
    manifest_path=$(get_global_manifest_path)
    
    if [ ! -f "$manifest_path" ]; then
        return 1
    fi
    
    # Check if package exists in manifest
    grep -q "^  $package_name:" "$manifest_path"
}

# Get global package location
get_global_package_location() {
    local package_name="$1"
    local manifest_path
    manifest_path=$(get_global_manifest_path)
    
    if [ ! -f "$manifest_path" ]; then
        return 1
    fi
    
    # Extract location using awk
    awk -v pkg="$package_name" '
        $0 ~ "^  " pkg ":" { in_package=1; next }
        in_package && /^    location:/ { print $2; exit }
        /^  [a-z]/ && in_package { exit }
    ' "$manifest_path"
}
```

**Location**: Add to `agent/scripts/acp.common.sh` after existing manifest functions  

**Verification**:
- Functions added to acp.common.sh
- Functions are POSIX-compliant
- Functions handle missing manifest gracefully
- Functions follow existing code style

### 5. Test Global Infrastructure

Test that all infrastructure components work:

```bash
# Test directory creation
ls -la ~/.acp/

# Test AGENT.md
cat ~/.acp/AGENT.md

# Test manifest
cat ~/.acp/manifest.yaml

# Test functions (source acp.common.sh first)
source agent/scripts/acp.common.sh
get_global_manifest_path
global_manifest_exists && echo "✓ Global manifest exists"
init_global_manifest
```

**Verification**:
- All directories exist
- AGENT.md is readable and complete
- manifest.yaml is valid YAML
- Functions execute without errors
- init_global_manifest is idempotent (safe to run multiple times)

### 6. Update Documentation

Update command documentation to reference global infrastructure:

**Files to update**:
- [`agent/commands/acp.package-install.md`](../commands/acp.package-install.md) - Add note about `--global` flag (coming in Task 26)
- [`agent/commands/acp.init.md`](../commands/acp.init.md) - Add note about global package discovery (coming in Task 27)

**Changes**:
- Add "Global Installation" section to acp.package-install.md
- Add "Global Package Discovery" section to acp.init.md
- Note that these features are implemented in Tasks 26-27

**Verification**:
- Documentation updated
- References to global features added
- Clear that features are coming in next tasks

---

## Verification

- [ ] `~/.acp/` directory exists
- [ ] `~/.acp/packages/` directory exists
- [ ] `~/.acp/projects/` directory exists
- [ ] `~/.acp/AGENT.md` created with discovery instructions
- [ ] `~/.acp/manifest.yaml` created with valid structure
- [ ] Global manifest functions added to acp.common.sh (7 functions)
- [ ] Functions are POSIX-compliant
- [ ] Functions handle errors gracefully
- [ ] All functions tested and working
- [ ] Documentation updated with references to global features
- [ ] No errors during infrastructure setup

---

## Expected Output

### Directory Structure
```
~/.acp/
├── AGENT.md                     # Discovery instructions (NEW)
├── manifest.yaml                # Global package manifest (NEW)
├── packages/                    # Global packages directory (NEW)
└── projects/                    # Projects directory (NEW)
```

### Key Files Created
- `~/.acp/AGENT.md`: Instructions for agents to discover global packages
- `~/.acp/manifest.yaml`: Empty manifest ready for package installations
- `~/.acp/packages/`: Directory for global package installations
- `~/.acp/projects/`: Directory for future monorepo support

### Functions Added to acp.common.sh
1. `get_global_manifest_path()` - Returns path to global manifest
2. `global_manifest_exists()` - Checks if global manifest exists
3. `init_global_manifest()` - Creates global manifest if missing
4. `read_global_manifest()` - Returns full manifest content
5. `update_global_manifest_timestamp()` - Updates manifest timestamp
6. `global_package_exists()` - Checks if package is installed globally
7. `get_global_package_location()` - Returns package installation path

---

## Common Issues and Solutions

### Issue 1: Permission denied creating ~/.acp/

**Symptom**: Error message "Permission denied" when creating directory  

**Solution**: Ensure you have write permissions to home directory. This should not require sudo. If permission issues persist, check home directory permissions: `ls -la ~/`  

### Issue 2: manifest.yaml creation fails

**Symptom**: Error creating manifest.yaml file  

**Solution**: Ensure `~/.acp/` directory exists first. Run `mkdir -p ~/.acp` before creating manifest.  

### Issue 3: Functions not found after adding to acp.common.sh

**Symptom**: "command not found" when testing functions  

**Solution**: Source the file first: `source agent/scripts/acp.common.sh`, then test functions.  

### Issue 4: YAML syntax errors in manifest

**Symptom**: YAML parser complains about syntax  

**Solution**: Validate YAML structure. Ensure proper indentation (2 spaces), no tabs, and valid YAML syntax. Test with: `./agent/scripts/acp.yaml-validate.sh ~/.acp/manifest.yaml agent/schemas/manifest.schema.yaml`  

---

## Resources

- [Global Package Installation Design](../design/global-package-installation.md): Complete design specification
- [Milestone 5 Document](../milestones/milestone-5-global-package-installation.md): Milestone overview
- [acp.common.sh](../scripts/acp.common.sh): Shared utility functions
- [YAML Specification](https://yaml.org/spec/1.2/spec.html): YAML format reference

---

## Notes

- This task creates infrastructure only - no package installation yet
- Global manifest uses same format as project manifests (agent/manifest.yaml)
- `~/.acp/projects/` directory is created for future monorepo support but not used yet
- Functions are designed to be idempotent (safe to run multiple times)
- Global infrastructure is optional - projects work fine without it
- This enables Task 26 (global installation) and Task 27 (global commands)

---

**Next Task**: [task-26-global-installation.md](task-26-global-installation.md)  
**Related Design Docs**: [global-package-installation.md](../design/global-package-installation.md)  
**Estimated Completion Date**: TBD  
