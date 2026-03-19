# Global ACP Installation

**Concept**: Auto-initialize global ACP infrastructure when using global package features  
**Created**: 2026-02-21  
**Updated**: 2026-02-21  
**Status**: Design Specification  
**Priority**: High  
**Estimated Effort**: 1-2 hours  

---

## Overview

Automatically initialize the `~/.acp/` directory structure when users first use global package features (like `@acp.package-install --global`). This creates a centralized ACP installation that serves as the foundation for all ACP work, including package development and global package management.

**Key Benefit**: Users don't need to manually install ACP globally - it's automatically initialized when they first use global features. Simple and intuitive.  

---

## Problem Statement

### Current Limitations

1. **No Global Infrastructure**: No `~/.acp/` directory for global package management
2. **Manual Setup Required**: Users would need to manually create global infrastructure
3. **Complexity**: Multiple installation commands would be confusing

### User Pain Points

**Scenario 1**: Using Global Packages  
- Problem: User runs `@acp.package-install --global` but `~/.acp/` doesn't exist
- Desired: Command automatically initializes `~/.acp/` if needed

**Scenario 2**: Package Development  
- Problem: User wants to create packages but no global infrastructure exists
- Desired: `@acp.package-create` automatically initializes `~/.acp/` if needed

**Scenario 3**: Complexity  
- Problem: Users confused about when to install globally vs locally
- Desired: System handles it automatically based on command usage

---

## Solution

### Auto-Initialization Approach

**No manual global installation needed!** The `~/.acp/` infrastructure is automatically initialized when users first use global features:

```bash
# User runs this command
@acp.package-install --global https://github.com/user/acp-firebase.git

# System automatically:
# 1. Checks if ~/.acp/ exists
# 2. If not, initializes it with AGENT.md, manifest.yaml, directories
# 3. Then proceeds with package installation

# User never needs to think about "installing ACP globally"
```

**Triggers for auto-initialization**:
- `@acp.package-install --global` - Initialize before installing package
- `@acp.package-create` (when target is ~/.acp/projects/) - Initialize before creating package
- `@acp.package-list --global` - Initialize before listing (creates empty manifest)

### Directory Structure

**Global Installation** (`--global` flag):
```
~/.acp/
├── AGENT.md                     # Global ACP documentation
├── manifest.yaml                # Global package manifest
├── agent/                       # Full ACP installation
│   ├── commands/
│   │   └── command.template.md
│   ├── design/
│   │   └── *.template.md
│   ├── milestones/
│   │   └── *.template.md
│   ├── patterns/
│   │   └── *.template.md
│   ├── tasks/
│   │   └── *.template.md
│   ├── scripts/
│   │   ├── acp.install.sh
│   │   ├── acp.common.sh
│   │   └── ... (all scripts)
│   └── schemas/
│       └── *.schema.yaml
├── packages/                    # Global packages
│   └── @org/package-name/
└── projects/                    # User projects
    └── my-project/
```

**Local Installation** (default, unchanged):
```
./
├── AGENT.md
├── agent/
│   ├── commands/
│   ├── design/
│   ├── milestones/
│   ├── patterns/
│   ├── tasks/
│   ├── scripts/
│   └── schemas/
└── (project files)
```

---

## Implementation

### 1. Create init_global_acp() Function in acp.common.sh

This function checks if `~/.acp/` exists and initializes it by running the standard install script:

```bash
# Initialize global ACP infrastructure if it doesn't exist
init_global_acp() {
    local global_dir="$HOME/.acp"
    
    # Check if already initialized
    if [ -d "$global_dir/agent" ] && [ -f "$global_dir/AGENT.md" ]; then
        return 0  # Already initialized
    fi
    
    echo "Initializing global ACP infrastructure at ~/.acp/..."
    
    # Create ~/.acp directory
    mkdir -p "$global_dir"
    
    # Run standard ACP installation in ~/.acp/
    # This installs all templates, scripts, and schemas
    (
        cd "$global_dir" || exit 1
        curl -fsSL https://raw.githubusercontent.com/prmichaelsen/agent-context-protocol/mainline/agent/scripts/acp.install.sh | bash
    ) || {
        echo "Error: Failed to initialize global ACP infrastructure" >&2
        return 1
    }
    
    # Create additional global directories
    mkdir -p "$global_dir/packages"
    mkdir -p "$global_dir/projects"
    
    # Create global manifest
    cat > "$global_dir/manifest.yaml" << EOF
# Global ACP Package Manifest
version: 1.0.0
updated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

packages: {}
EOF
    
    # Update AGENT.md to indicate this is a global installation
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
\`\`\`bash
@acp.package-install --global https://github.com/user/acp-package.git
\`\`\`

**Create packages**:
\`\`\`bash
cd ~/.acp/projects
@acp.package-create
\`\`\`

**List global packages**:
\`\`\`bash
@acp.package-list --global
\`\`\`

### Discovery

Agents can discover globally installed packages by reading `~/.acp/manifest.yaml`. Local packages always take precedence over global packages.
EOF
    
    echo "✓ Global ACP infrastructure initialized"
}
```

**Key Points**:
- Reuses standard `acp.install.sh` for consistency
- Installs full ACP (templates, scripts, schemas) to `~/.acp/`
- Creates additional global-specific directories (`packages/`, `projects/`)
- Creates global manifest for package tracking
- Appends global installation notes to AGENT.md

### 2. Call init_global_acp() in Global Package Commands

Update these scripts to call `init_global_acp()` before proceeding:

**acp.package-install.sh** (when `--global` flag is used):
```bash
if [ "$GLOBAL_INSTALL" = true ]; then
    # Initialize global infrastructure if needed
    init_global_acp
    
    # Proceed with global installation
    # ...
fi
```

**acp.package-create.sh** (when target is in ~/.acp/projects/):
```bash
if [[ "$TARGET_DIR" == "$HOME/.acp/projects/"* ]]; then
    # Initialize global infrastructure if needed
    init_global_acp
fi
```

**acp.package-list.sh** (when `--global` flag is used):
```bash
if [ "$GLOBAL_FLAG" = true ]; then
    # Initialize global infrastructure if needed
    init_global_acp
    
    # List global packages
    # ...
fi
```

### 3. Global AGENT.md Content

When installing globally, create a special `~/.acp/AGENT.md` that explains the global installation:

```markdown
# ACP Global Installation

This is your global ACP installation. It provides:

1. **Templates**: All ACP templates for creating designs, tasks, patterns, etc.
2. **Scripts**: All ACP scripts for package management and utilities
3. **Schemas**: YAML schemas for validation
4. **Global Packages**: Packages installed globally (in `~/.acp/packages/`)
5. **Projects**: Optional location for your projects (in `~/.acp/projects/`)

## For Agents

This global installation serves as the foundation for all ACP work. When working on projects:

1. **Local projects** can reference global templates and scripts
2. **Global packages** can be discovered via `~/.acp/manifest.yaml`
3. **Package development** can use global ACP installation

## Usage

### Create a New Package
```bash
cd ~/.acp/projects
@acp.package-create
```

### Install a Package Globally
```bash
@acp.package-install --global https://github.com/user/acp-package.git
```

### Use in Local Projects
Local projects can still have their own ACP installation. Local always takes precedence over global.
```

### 4. Benefits of Auto-Initialization

**Simplicity**:
- Users don't need to know about global installation
- No separate installation command to remember
- "It just works" when they use global features

**Consistency**:
- Same initialization logic used by all global commands
- Guaranteed consistent structure
- No risk of partial initialization

**Discoverability**:
- Users naturally discover global features by using them
- No need to read docs about "installing globally first"
- Progressive enhancement of their workflow

---

## Benefits

### 1. Zero Configuration
- No manual setup required
- Auto-initializes on first use
- Users don't need to think about it

### 2. Simplicity
- One less command to learn
- No confusion about when to install globally
- Progressive discovery of features

### 3. Reliability
- Consistent initialization across all commands
- No risk of forgetting to initialize
- Guaranteed correct structure

### 4. User Experience
- "It just works" approach
- Natural workflow progression
- No barriers to using global features

---

## Usage Examples

### First Time Using Global Packages

```bash
# User's first time using global packages
@acp.package-install --global https://github.com/user/acp-firebase.git

# Output:
# Initializing global ACP infrastructure at ~/.acp/...
# ✓ Global ACP infrastructure initialized
#
# Installing acp-firebase globally...
# ✓ Package installed to ~/.acp/packages/@user/acp-firebase
# ✓ Updated ~/.acp/manifest.yaml
#
# ✅ Package installed globally!
```

### Subsequent Global Package Operations

```bash
# After first initialization, no initialization message
@acp.package-install --global https://github.com/user/acp-git.git

# Output:
# Installing acp-git globally...
# ✓ Package installed to ~/.acp/packages/@user/acp-git
# ✓ Updated ~/.acp/manifest.yaml
#
# ✅ Package installed globally!
```

### Creating Packages

```bash
# Create a package (auto-initializes if needed)
@acp.package-create

# If target directory is ~/.acp/projects/my-package:
# Initializing global ACP infrastructure at ~/.acp/...
# ✓ Global ACP infrastructure initialized
#
# Creating package...
# (continues with package creation)
```

---

## Trade-offs

### 1. Implicit Initialization
**Trade-off**: Infrastructure created without explicit user action  

**Mitigation**:
- Clear message when initializing
- Lightweight initialization (just directories + 2 files)
- Non-intrusive (only in ~/.acp/)

### 2. Hidden Complexity
**Trade-off**: Users may not know ~/.acp/ was created  

**Mitigation**:
- Document in AGENT.md and README
- Clear initialization messages
- Easy to discover (ls ~/.acp/)

### 3. Idempotency Required
**Trade-off**: init_global_acp() must be safe to call multiple times  

**Mitigation**:
- Check for existing files before creating
- No-op if already initialized
- Fast check (just file existence)

---

## Implementation Plan

### Phase 1: Create init_global_acp() Function (30 minutes)
1. Add init_global_acp() to acp.common.sh
2. Create global AGENT.md template
3. Create global manifest template
4. Test function is idempotent

### Phase 2: Update Package Commands (1 hour)
1. Update acp.package-install.sh to call init_global_acp() when --global
2. Update acp.package-create.sh to call init_global_acp() when target is ~/.acp/projects/
3. Update acp.package-list.sh to call init_global_acp() when --global
4. Test all commands initialize correctly

### Phase 3: Documentation (30 minutes)
1. Update README.md explaining auto-initialization
2. Update command documentation
3. Add examples showing initialization messages
4. Document ~/.acp/ structure

---

## Related Documents

- [`agent/design/global-package-installation.md`](global-package-installation.md)
- [`agent/tasks/task-25-global-infrastructure.md`](../tasks/task-25-global-infrastructure.md)
- [`agent/scripts/acp.install.sh`](../scripts/acp.install.sh)

---

**Status**: Design Specification - Ready for implementation  
**Recommendation**: Implement before Milestone 5 (Global Package Installation)  
**Next Steps**:
1. Update acp.install.sh with --global flag support
2. Create global AGENT.md template
3. Test installation in both modes
4. Update documentation
