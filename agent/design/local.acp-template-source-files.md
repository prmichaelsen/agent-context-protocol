# Design: ACP Template Source Files Support

**Concept**: Extend ACP package system to bundle and install template source files (TypeScript, config files, etc.) in agent/files/ directory

**Created**: 2026-02-26
**Version**: 1.1.0
**Status**: Implemented (v5.0.0)
**Last Updated**: 2026-02-28

---

## Overview

Currently, ACP packages can only bundle documentation-style files (patterns, commands, designs, scripts). This design proposes adding support for **template source files** in `agent/files/` - actual code files, configuration files, and project structure templates that can be bundled in packages and installed into the agent directory.

This would enable packages like `acp-core-sdk` to provide ready-to-use TypeScript configurations, build scripts, and source code templates instead of requiring users to manually create these files or embedding them as heredocs in commands.

**Key Architectural Decision**: Templates install to `agent/files/` (not project root) to maintain ACP's principle of keeping all package content within the `agent/` directory. Users copy files from `agent/files/` to their project as needed.

---

## Problem Statement

### Current Limitations

The ACP package system currently supports:
- ✅ Patterns (`.md` files in `agent/patterns/`)
- ✅ Commands (`.md` files in `agent/commands/`)
- ✅ Designs (`.md` files in `agent/design/`)
- ✅ Scripts (`.sh` files in `agent/scripts/`)

**What's missing**:
- ❌ Template source files (`.ts`, `.js`, `.json`, etc.)
- ❌ Configuration file templates (`tsconfig.json`, `package.json`, etc.)
- ❌ Project structure scaffolding
- ❌ Sample/incomplete source code

### Why This Matters

When creating packages like `acp-core-sdk` (patterns for building reusable core libraries), we want to provide:

1. **Pre-configured files** - Users get working configurations out of the box
2. **Copy-paste ready code** - Template source files they can customize
3. **Complete project structure** - Scaffold entire directory layouts
4. **Less command complexity** - Avoid embedding large code blocks in command heredocs

### Current Workarounds (Suboptimal)

**Workaround 1: Embed in Commands**
```markdown
# Command: core-sdk.init

cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    ... 50+ lines of config ...
  }
}
EOF
```

**Problems**:
- Commands become massive
- Hard to maintain
- No syntax highlighting
- Difficult to version individual files
- Can't selectively install files

**Workaround 2: External Repository**
```markdown
# Pattern: Core Library Setup

Download configuration files from:
https://github.com/user/templates/tsconfig.json
```

**Problems**:
- Requires manual steps
- Not integrated with ACP workflow
- No version tracking
- Breaks offline usage

---

## Solution

### Proposed Architecture

Add a new `agent/files/` directory to ACP packages:

```
acp-core-sdk/
├── agent/                          # ACP entities
│   ├── patterns/
│   ├── commands/
│   ├── designs/
│   ├── scripts/
│   │
│   └── files/                      # NEW: Template source files
│       ├── config/                 # Configuration templates
│       │   ├── tsconfig.json
│       │   ├── package.json.template
│       │   ├── jest.config.js
│       │   └── esbuild.build.js
│       │
│       ├── src/                    # Source code templates
│       │   ├── schemas/
│       │   │   └── example.schema.ts
│       │   ├── services/
│       │   │   └── example.service.ts
│       │   ├── dto/
│       │   │   ├── example.dto.ts
│       │   │   └── transformers.ts
│       │   ├── client.ts
│       │   └── index.ts
│       │
│       ├── test/                   # Test templates
│       │   └── example.spec.ts
│       │
│       └── README.md               # Template usage guide
│
├── package.yaml                    # Package metadata
└── README.md
```

### package.yaml Schema Extension

Extend `package.yaml` to declare template files:

```yaml
name: core-sdk
version: 1.0.0
description: Patterns for creating reusable core libraries

contents:
  patterns:
    - name: core-library-extraction.md
      description: Pattern for extracting shared logic
  
  commands:
    - name: core-sdk.init.md
      description: Initialize core library project
  
  # NEW: Template files (stored in agent/files/)
  files:
    - name: config/tsconfig.json
      description: TypeScript configuration for core libraries
      target: ./
      required: true
      
    - name: config/package.json.template
      description: npm package.json with subpath exports
      target: ./
      required: true
      variables:
        - PACKAGE_NAME
        - PACKAGE_DESCRIPTION
        - AUTHOR_NAME
      
    - name: config/jest.config.js
      description: Jest configuration for ESM + TypeScript
      target: ./
      required: false
      
    - name: src/schemas/example.schema.ts
      description: Example Zod schema structure
      target: src/schemas/
      required: false
      
    - name: src/services/example.service.ts
      description: Example service layer pattern
      target: src/services/
      required: false
```

### Template File Metadata

Each template entry supports:

- **`name`** (required): Path to template file relative to `agent/files/` directory
- **`description`** (required): What this template provides
- **`target`** (required): Where to install (relative to project root)
- **`required`** (optional, default: false): Must be installed or optional
- **`variables`** (optional): Placeholder variables for substitution
- **`experimental`** (optional, default: false): Requires `--experimental` flag

### Installation Workflow

**1. List Available Files**
```bash
./agent/scripts/acp.package-install.sh --list --repo https://github.com/user/acp-core-sdk.git
```

Output:
```
📦 Available Content:

📁 patterns/ (2 files)
  ✓ core-library-extraction.md
  ✓ npm-package-structure.md

📁 commands/ (1 file)
  ✓ core-sdk.init.md

📁 files/ (8 files)
  ✓ config/tsconfig.json (required)
  ✓ config/package.json.template (required, has variables)
  ✓ config/jest.config.js
  ✓ src/schemas/example.schema.ts
  ✓ src/services/example.service.ts
  ...
```

**2. Install All Files**
```bash
./agent/scripts/acp.package-install.sh --repo https://github.com/user/acp-core-sdk.git
```

**3. Install Selective Files**
```bash
# Install only config files
./agent/scripts/acp.package-install.sh --files config/* --repo <url>

# Install specific files
./agent/scripts/acp.package-install.sh --files config/tsconfig.json src/schemas/example.schema.ts --repo <url>
```

**4. Variable Substitution**

For templates with variables, prompt user:
```
Template config/package.json.template requires variables:
  PACKAGE_NAME: @scope/package-name
  PACKAGE_DESCRIPTION: Package description
  AUTHOR_NAME: Your Name

Enter PACKAGE_NAME: @myorg/my-core
Enter PACKAGE_DESCRIPTION: Core business logic library
Enter AUTHOR_NAME: Patrick Michaelsen

✓ Variables collected
✓ Substituting variables in template
✓ Installing to ./package.json
```

### Command Integration

Commands can reference templates:

```markdown
# Command: core-sdk.init

## Steps

### 1. Install Template Files

Template files are available in `agent/files/`:
- agent/files/config/tsconfig.json
- agent/files/config/package.json.template
- agent/files/config/jest.config.js
- agent/files/config/esbuild.build.js

### 2. Copy Files to Project Root

Copy configuration files from agent/files/ to project root:

```bash
cp agent/files/config/tsconfig.json ./
cp agent/files/config/package.json.template ./package.json
cp agent/files/config/jest.config.js ./
cp agent/files/config/esbuild.build.js ./
```

### 3. Customize Configuration

Update package.json with:
- Package name
- Description
- Author

### 4. Install Dependencies

npm install

### 5. Verify Setup

npm run typecheck
npm test
```

---

## Implementation

### Phase 1: Schema Extension

1. Update `agent/schemas/package.schema.yaml`:
   - Add `files` array to `contents` object
   - Define file metadata fields
   - Add validation rules

2. Update validation scripts:
   - Validate file existence in agent/files/
   - Check target paths are safe
   - Verify variable declarations

### Phase 2: Installation Script Updates

Update `agent/scripts/acp.package-install.sh`:

1. **Scan for files**:
   ```bash
   # Scan agent/files/ directory
   find agent/files/ -type f
   ```

2. **Parse file metadata** from package.yaml

3. **Add installation flags**:
   ```bash
   --files [file1] [file2]  # Install specific files
   --files-only             # Install only files
   --no-files               # Skip files
   ```

4. **Variable substitution**:
   ```bash
   # Collect variables from user
   # Replace {{VARIABLE}} in template content
   # Write to target location
   ```

5. **Target path handling**:
   ```bash
   # Create target directories if needed
   # Respect target path from package.yaml
   # Warn on overwrites
   ```

### Phase 3: Manifest Tracking

Update `agent/manifest.yaml` to track installed files:

```yaml
packages:
  core-sdk:
    source: https://github.com/user/acp-core-sdk.git
    package_version: 1.0.0
    installed:
      files:
        - name: config/tsconfig.json
          version: 1.0.0
          installed_at: 2026-02-26T10:00:00Z
          installed_to: agent/files/config/tsconfig.json
          target: ./tsconfig.json
          modified: false
          checksum: sha256:abc123...
          variables:
            PACKAGE_NAME: "@myorg/my-core"
```

### Phase 4: Update Commands

Update existing commands to support files:
- `@acp.package-install` - Install files to agent/files/
- `@acp.package-update` - Update files (with conflict detection)
- `@acp.package-remove` - Remove files from agent/files/
- `@acp.package-validate` - Validate file declarations

---

## Benefits

### For Package Authors

1. **Better organization** - Files separate from commands, within agent/ directory
2. **Easier maintenance** - Edit actual files, not heredocs
3. **Version control** - Track file changes independently
4. **Syntax highlighting** - Files are real code files
5. **Selective sharing** - Users can install specific files

### For Package Users

1. **Ready-to-use files** - Files available in agent/files/ for copying
2. **Pre-configured** - Files work out of the box
3. **Customizable** - Variable substitution for personalization
4. **Selective installation** - Install only what's needed
5. **Organized storage** - All package files in agent/ directory
6. **Safe installation** - Files stay in agent/ until explicitly copied

### For ACP Ecosystem

1. **Richer packages** - More than just documentation
2. **Code reuse** - Share actual implementations
3. **Best practices** - Distribute proven configurations
4. **Consistency** - Standard project structures
5. **Discoverability** - Templates listed in package metadata

---

## Trade-offs

### Advantages

✅ **Native support** - Integrated with ACP workflow
✅ **Version tracked** - Files tracked in manifest
✅ **Selective install** - Install only needed files
✅ **Variable substitution** - Personalize files
✅ **Safe storage** - Files in agent/ directory, not project root
✅ **Offline capable** - Files bundled in package
✅ **Consistent location** - All package content in agent/

### Disadvantages

❌ **Complexity** - More moving parts in package system
❌ **Storage** - Packages become larger
❌ **Maintenance** - Files need updates
❌ **Extra step** - Users must copy from agent/files/ to project
❌ **Learning curve** - Users need to understand file system

### Mitigations

- **Size limits** - Warn if files exceed reasonable size
- **Clear documentation** - Guide on copying from agent/files/
- **Validation** - Strict validation of file declarations
- **Checksums** - Track modifications to detect changes
- **Commands can automate** - Commands can copy files automatically

---

## Examples

### Example 1: Core Library Package

**Package**: `acp-core-sdk`

**Templates**:
- `config/tsconfig.json` - TypeScript configuration
- `config/package.json.template` - npm package with subpath exports
- `config/jest.config.js` - Jest for ESM + TypeScript
- `config/esbuild.build.js` - esbuild for multiple entry points
- `src/schemas/example.schema.ts` - Zod schema pattern
- `src/services/example.service.ts` - Service layer pattern
- `src/dto/transformers.ts` - DTO transformer pattern
- `src/client.ts` - Client wrapper pattern

**Usage**:
```bash
# Install all files
@acp.package-install --repo https://github.com/user/acp-core-sdk.git

# Files installed to agent/files/config/, agent/files/src/, etc.
# Copy to project root as needed:
cp agent/files/config/tsconfig.json ./
cp agent/files/config/package.json ./

# Or install selectively
@acp.package-install --files config/* --repo <url>
```

### Example 2: Firebase Package

**Package**: `acp-firebase`

**Templates**:
- `config/firebase.json` - Firebase configuration
- `config/firestore.rules` - Firestore security rules
- `src/firebase/client.ts` - Firebase client wrapper
- `src/firebase/collections.ts` - Collection path helpers

**Usage**:
```bash
@acp.package-install --repo https://github.com/user/acp-firebase.git
```

### Example 3: MCP Server Package

**Package**: `acp-mcp-server`

**Templates**:
- `src/server.ts` - MCP server boilerplate
- `src/tools/example-tool.ts` - Tool implementation pattern
- `config/mcp-config.json` - MCP server configuration

**Usage**:
```bash
@acp.package-install --templates src/* --repo <url>
```

---

## Migration Path

### For Existing Packages

1. **Create `agent/files/` directory** in package
2. **Move embedded code** from commands to files
3. **Update `package.yaml`** with file declarations
4. **Update commands** to reference agent/files/ paths
5. **Test installation** with new file system
6. **Publish new version** with files

### For Existing Users

1. **Backward compatible** - Old packages still work
2. **Opt-in** - Files only installed if declared
3. **Gradual adoption** - Packages can add files incrementally
4. **Documentation** - Clear migration guide
5. **Safe by default** - Files stay in agent/ until copied

---

## Architectural Decision: agent/files/ vs Project Root

### Why agent/files/ Instead of Project Root?

**Decision**: Install template files to `agent/files/` directory, not directly to project root.

**Rationale**:

1. **Consistency** - All package content stays within `agent/` directory
   - Patterns → `agent/patterns/`
   - Commands → `agent/commands/`
   - Designs → `agent/design/`
   - Scripts → `agent/scripts/`
   - Files → `agent/files/` ✅

2. **Safety** - No accidental overwrites of user code
   - Files don't automatically overwrite project files
   - User explicitly copies what they need
   - Clear separation between package content and project code

3. **Discoverability** - Easy to find package-provided files
   - All in one location: `agent/files/`
   - Can browse available files
   - Clear what came from packages

4. **Version Control** - Cleaner git history
   - Package files tracked separately from project code
   - Can .gitignore agent/files/ if desired
   - Updates don't pollute project commits

5. **Flexibility** - Users control what gets used
   - Copy all files or just some
   - Customize before copying
   - Keep originals for reference

### Workflow

**Installation**:
```bash
@acp.package-install --repo https://github.com/user/acp-core-sdk.git
# Installs to: agent/files/config/tsconfig.json
```

**Usage**:
```bash
# User copies files as needed
cp agent/files/config/tsconfig.json ./
cp agent/files/config/package.json ./

# Or command automates copying
@core-sdk.init
# Command copies files from agent/files/ to project root
```

### Comparison with Project Root Installation

| Aspect | agent/files/ (Chosen) | Project Root (Rejected) |
|--------|----------------------|-------------------------|
| Safety | ✅ No accidental overwrites | ❌ May overwrite user files |
| Consistency | ✅ All package content in agent/ | ❌ Package content scattered |
| Discoverability | ✅ Easy to find in agent/files/ | ❌ Mixed with project files |
| Version Control | ✅ Clean separation | ❌ Package files mixed with code |
| User Control | ✅ Explicit copying | ❌ Automatic installation |
| ACP Principles | ✅ Follows agent/ pattern | ❌ Breaks containment |

**Conclusion**: `agent/files/` provides better safety, consistency, and user control while maintaining ACP's principle of keeping all package content within the `agent/` directory.

---

## Future Enhancements

### Template Composition

Allow templates to reference other templates:

```yaml
templates:
  - name: config/package.json.template
    depends_on:
      - config/tsconfig.json
      - config/jest.config.js
```

### Template Variants

Support multiple variants of same template:

```yaml
templates:
  - name: config/tsconfig.json
    variants:
      - strict: config/tsconfig.strict.json
      - relaxed: config/tsconfig.relaxed.json
```

### Template Hooks

Run scripts after template installation:

```yaml
templates:
  - name: config/package.json.template
    post_install: npm install
```

---

## Status

**Current**: Proposal  
**Next Steps**:
1. Gather feedback from ACP community
2. Prototype implementation
3. Test with core-sdk package
4. Document usage patterns
5. Submit as ACP enhancement proposal

**Recommendation**: Implement this feature to enable richer, more useful ACP packages that can distribute actual code and configuration files, not just documentation.

---

**Version**: 1.0.0  
**Created**: 2026-02-26  
**Status**: Proposal  
**Author**: Patrick Michaelsen (based on task-core project learnings)
