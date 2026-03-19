# Install Local Patterns Feature

**Concept**: Add --install-local flag to @acp.package-install to install local namespace patterns from source repository with automatic namespace conversion  
**Created**: 2026-02-21  
**Status**: Design Proposal  
**Priority**: Medium  
**Estimated Effort**: 3-4 hours  

---

## Overview

Add a `--install-local` flag to the `@acp.package-install` command that allows installing patterns marked with the `local` namespace from a source repository. When installed, these patterns are automatically renamed to use the installing package's namespace instead of `local`.

This enables package authors to share implementation-specific patterns that consumers can adapt to their own projects.

---

## Problem Statement

### Current Limitation

When a package repository contains patterns with `local` namespace (implementation-specific patterns for that package's development), these patterns cannot be installed by consumers because:

1. **Namespace Collision**: Installing `local.*` patterns would overwrite consumer's own local patterns
2. **No Selective Installation**: Current `--patterns` flag installs all patterns or specific ones, but doesn't handle namespace conversion
3. **Lost Value**: Useful implementation patterns in the source repo can't be shared

### Use Case Example

**Scenario**: acp-firebase package repository contains:  
- `firebase.user-scoped-collections.md` (exportable pattern)
- `firebase.security-rules.md` (exportable pattern)
- `local.firebase-testing.md` (implementation pattern for firebase package development)
- `local.firebase-deployment.md` (implementation pattern for firebase package development)

**Current Behavior**:
```bash
@acp.package-install https://github.com/user/acp-firebase.git
# Installs: firebase.* patterns only
# Skips: local.* patterns (not in package.yaml)
```

**Desired Behavior**:
```bash
@acp.package-install https://github.com/user/acp-firebase.git --install-local
# Installs: firebase.* patterns (as-is)
# Also installs: local.* patterns renamed to firebase.* in consumer's project
```

---

## Solution

### Flag Specification

**Syntax**:
```bash
@acp.package-install <repo-url> --install-local
```

**Behavior**:
1. Install all regular patterns from package.yaml (normal behavior)
2. Scan source repository for `local.*` patterns in `agent/patterns/`
3. For each `local.*` pattern found:
   - Rename to `{consumer-namespace}.{pattern-name}.md`
   - Install to consumer's `agent/patterns/` directory
   - Add to consumer's package.yaml (if consumer is a package)
   - Update consumer's README.md (if consumer is a package)

### Namespace Conversion

**Source Repository** (acp-firebase):
```
agent/patterns/
├── firebase.user-scoped-collections.md  (exported in package.yaml)
├── firebase.security-rules.md           (exported in package.yaml)
├── local.firebase-testing.md            (NOT in package.yaml)
└── local.firebase-deployment.md         (NOT in package.yaml)
```

**Consumer Project** (acp-myapp):
```bash
# Install with --install-local
@acp.package-install https://github.com/user/acp-firebase.git --install-local
```

**Result in Consumer**:
```
agent/patterns/
├── firebase.user-scoped-collections.md  (from package.yaml)
├── firebase.security-rules.md           (from package.yaml)
├── myapp.firebase-testing.md            (converted from local.firebase-testing.md)
└── myapp.firebase-deployment.md         (converted from local.firebase-deployment.md)
```

### Implementation Details

**Detection**:
```bash
# Find local patterns in source repo
find agent/patterns -name "local.*.md"
```

**Conversion**:
```bash
# For each local pattern:
source_file="local.firebase-testing.md"
pattern_name="firebase-testing"  # Strip "local." prefix
consumer_namespace=$(infer_namespace)  # e.g., "myapp"
target_file="${consumer_namespace}.${pattern_name}.md"

# Copy and rename
cp "agent/patterns/$source_file" "agent/patterns/$target_file"
```

**Content Update**:
```bash
# Update namespace metadata in file
sed -i "s/^**Namespace**: local$/**Namespace**: $consumer_namespace/" "$target_file"
```

---

## Use Cases

### Use Case 1: Learning from Implementation Patterns

**Scenario**: Developer wants to see how firebase package itself is tested  

**Action**:
```bash
@acp.package-install https://github.com/user/acp-firebase.git --install-local
```

**Result**: Gets firebase testing patterns renamed to their own namespace, can adapt for their project  

### Use Case 2: Package Development Patterns

**Scenario**: Creating a new package, want to use patterns from established packages  

**Action**:
```bash
@acp.package-install https://github.com/user/acp-firebase.git --install-local
```

**Result**: Gets implementation patterns that show how to structure package development  

### Use Case 3: Best Practices Transfer

**Scenario**: Want to adopt deployment patterns from another package  

**Action**:
```bash
@acp.package-install https://github.com/user/acp-firebase.git --install-local
```

**Result**: Gets deployment patterns adapted to their namespace  

---

## Implementation

### Changes to acp.package-install.sh

**Add Flag Parsing**:
```bash
INSTALL_LOCAL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --install-local)
            INSTALL_LOCAL=true
            shift
            ;;
        # ... existing flags
    esac
done
```

**Add Local Pattern Installation**:
```bash
if [ "$INSTALL_LOCAL" = true ]; then
    echo ""
    echo "${BOLD}Installing local patterns...${NC}"
    
    # Find local patterns in source
    local_patterns=$(find "$TEMP_DIR/agent/patterns" -name "local.*.md" 2>/dev/null)
    
    if [ -z "$local_patterns" ]; then
        echo "  ${YELLOW}No local patterns found${NC}"
    else
        # Get consumer namespace
        consumer_namespace=$(infer_namespace)
        if [ -z "$consumer_namespace" ]; then
            consumer_namespace="local"
        fi
        
        # Install each local pattern
        for source_file in $local_patterns; do
            filename=$(basename "$source_file")
            pattern_name="${filename#local.}"  # Remove "local." prefix
            target_filename="${consumer_namespace}.${pattern_name}"
            
            # Copy file
            cp "$source_file" "agent/patterns/$target_filename"
            
            # Update namespace in file
            sed -i "s/^\\*\\*Namespace\\*\\*: local$/\\*\\*Namespace\\*\\*: $consumer_namespace/" \
                "agent/patterns/$target_filename"
            
            echo "  ${GREEN}✓${NC} Installed $target_filename (from $filename)"
            
            # Add to package.yaml if consumer is a package
            if is_acp_package; then
                # Add to package.yaml contents
                # (implementation here)
            fi
        done
    fi
fi
```

---

## Benefits

### 1. Knowledge Sharing
- Package authors can share their development patterns
- Consumers learn from established packages
- Best practices transfer between projects

### 2. No Namespace Conflicts
- Automatic namespace conversion prevents collisions
- Each project has its own namespaced versions
- Can install from multiple sources without conflicts

### 3. Adaptation Friendly
- Patterns are copied, not referenced
- Consumers can modify for their needs
- No dependency on source repository

### 4. Discoverability
- Developers can see how packages are built
- Implementation patterns become learning resources
- Encourages pattern documentation

---

## Trade-offs

### 1. Potential Confusion
**Downside**: Users might not understand why local patterns are being installed  

**Mitigation**:
- Clear documentation
- Explicit flag (--install-local)
- Show what's being converted in output

### 2. Namespace Metadata Mismatch
**Downside**: Pattern content might reference "local" namespace in examples  

**Mitigation**:
- Only update metadata header
- Add note in pattern: "Adapted from {source-package}"
- Consumers expected to adapt content

### 3. Not in package.yaml
**Downside**: Local patterns aren't tracked in source package.yaml  

**Mitigation**:
- This is intentional (they're not exported)
- Discovery via filesystem scan
- Document in source README that local patterns exist

### 4. Version Tracking
**Downside**: Local patterns don't have version tracking from source  

**Mitigation**:
- Assign version 1.0.0 on installation
- Track in consumer's package.yaml
- Consumer maintains versions independently

---

## Alternatives Considered

### Alternative 1: Keep Local Namespace

**Approach**: Install local patterns as-is without renaming  

**Pros**:
- Simpler implementation
- No namespace conversion needed

**Cons**:
- Namespace collisions with consumer's local patterns
- Confusing which patterns are from which source

**Decision**: Rejected - namespace conversion is essential  

### Alternative 2: Separate Flag for Each Pattern

**Approach**: `--install-local-patterns firebase-testing firebase-deployment`  

**Pros**:
- More granular control
- Can choose specific patterns

**Cons**:
- More complex syntax
- Harder to discover available patterns

**Decision**: Could add later, start with --install-local for all  

### Alternative 3: New Namespace (e.g., "imported")

**Approach**: Rename to `imported.{pattern-name}.md` instead of consumer namespace  

**Pros**:
- Clear these are imported
- No namespace inference needed

**Cons**:
- Creates new namespace to manage
- Less integrated with consumer's patterns

**Decision**: Rejected - consumer namespace is more intuitive  

---

## Documentation Updates

### acp.package-install.md

Add section:

```markdown
### Installing Local Patterns

Use `--install-local` to install implementation patterns from the source repository:

\`\`\`bash
@acp.package-install https://github.com/user/acp-firebase.git --install-local
\`\`\`

**What This Does**:
- Installs all patterns from package.yaml (normal behavior)
- Also installs patterns with `local` namespace from source
- Renames local patterns to your project's namespace
- Example: `local.firebase-testing.md` → `myapp.firebase-testing.md`

**Use When**:
- You want to learn from the source package's implementation patterns
- You want to adapt their development/testing patterns
- You want to see how the package itself is built

**Note**: Local patterns are copied and adapted - you can modify them for your needs.  
```

---

## Testing Strategy

### Test Cases

1. **Install with --install-local in package**
   - Source has local patterns
   - Consumer is a package
   - Verify patterns renamed correctly
   - Verify package.yaml updated
   - Verify README.md updated

2. **Install with --install-local in project**
   - Source has local patterns
   - Consumer is a project (no package.yaml)
   - Verify patterns renamed to consumer namespace
   - Verify no package.yaml updates

3. **Install with --install-local, no local patterns**
   - Source has no local patterns
   - Verify graceful handling
   - Verify message shown

4. **Install without --install-local**
   - Verify local patterns NOT installed
   - Verify normal behavior unchanged

---

## Future Enhancements

### Phase 2: Selective Local Pattern Installation

```bash
@acp.package-install <repo> --install-local firebase-testing firebase-deployment
```

Install only specified local patterns.

### Phase 3: Local Pattern Discovery

```bash
@acp.package-install <repo> --list-local
```

List available local patterns without installing.

### Phase 4: Namespace Prefix Option

```bash
@acp.package-install <repo> --install-local --prefix imported
```

Use custom prefix instead of consumer namespace.

---

## Related Features

- **@acp.pattern-create**: Creates patterns with namespace
- **Namespace Utilities**: Infer and validate namespaces
- **Package Validation**: Validate installed patterns

---

**Status**: Design Proposal  
**Recommendation**: Implement as enhancement to existing package-install  
**Next Steps**: 
1. Review and approve design
2. Add to Milestone 4 or create Milestone 5
3. Implement flag in acp.package-install.sh
4. Update documentation
5. Test with real packages
