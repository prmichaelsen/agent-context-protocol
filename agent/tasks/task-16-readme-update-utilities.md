# Task 16: README Update Utilities

**Milestone**: [M4 - ACP Package Development System](../milestones/milestone-4-package-development.md)  
**Estimated Time**: 3-4 hours  
**Dependencies**: Task 15 (Namespace Utilities)  
**Status**: Not Started  

---

## Objective

Add README.md auto-update utilities to acp.common.sh that can update the "What's Included" section when new patterns, commands, or designs are added.

---

## Context

From clarifications:
- Auto-update "What's Included" section
- Brief list format with descriptions
- Use HTML comment markers for boundaries
- Extract descriptions from package.yaml
- Update on entity creation

---

## Steps

### 1. Define README Structure

Define standard README structure with update markers:

**Template**:
```markdown
## What's Included

<!-- ACP_AUTO_UPDATE_START:CONTENTS -->
### Commands
- `namespace.command1` - Description

### Patterns
- `namespace.pattern1` - Description

### Designs
- `namespace.design1` - Description
<!-- ACP_AUTO_UPDATE_END:CONTENTS -->
```

**Expected Outcome**: Standard structure defined  

### 2. Implement update_readme_contents() Function

Create function to update README contents section:

**Implementation**:
```bash
# Update README.md contents section
# Usage: update_readme_contents
# Reads package.yaml and updates README.md
update_readme_contents() {
    local readme="README.md"
    local package_yaml="package.yaml"
    
    if [ ! -f "$readme" ]; then
        echo "${YELLOW}Warning: README.md not found${NC}" >&2
        return 1
    fi
    
    if [ ! -f "$package_yaml" ]; then
        echo "${YELLOW}Warning: package.yaml not found${NC}" >&2
        return 1
    fi
    
    # Generate contents section
    local contents=$(generate_contents_section)
    
    # Replace section between markers
    awk -v contents="$contents" '
        /<!-- ACP_AUTO_UPDATE_START:CONTENTS -->/ {
            print
            print contents
            skip=1
            next
        }
        /<!-- ACP_AUTO_UPDATE_END:CONTENTS -->/ {
            skip=0
        }
        !skip
    ' "$readme" > "${readme}.tmp"
    
    mv "${readme}.tmp" "$readme"
    echo "${GREEN}✓${NC} Updated README.md"
}
```

**Expected Outcome**: Function updates README contents  

### 3. Implement generate_contents_section() Function

Generate contents section from package.yaml:

**Implementation**:
```bash
# Generate contents section from package.yaml
# Usage: contents=$(generate_contents_section)
# Returns: Formatted markdown content list
generate_contents_section() {
    local package_yaml="package.yaml"
    local output=""
    
    # Get namespace
    local namespace=$(yaml_get "$package_yaml" "name")
    
    # Commands
    local commands=$(yaml_get_array "$package_yaml" "contents.commands")
    if [ -n "$commands" ]; then
        output+="### Commands\n"
        # Parse each command
        # Format: - `namespace.command` - Description
        output+="\n"
    fi
    
    # Patterns
    local patterns=$(yaml_get_array "$package_yaml" "contents.patterns")
    if [ -n "$patterns" ]; then
        output+="### Patterns\n"
        # Parse each pattern
        output+="\n"
    fi
    
    # Designs
    local designs=$(yaml_get_array "$package_yaml" "contents.designs")
    if [ -n "$designs" ]; then
        output+="### Designs\n"
        # Parse each design
        output+="\n"
    fi
    
    echo -e "$output"
}
```

**Expected Outcome**: Function generates formatted content list  

### 4. Implement add_file_to_readme() Function

Add single file to README:

**Implementation**:
```bash
# Add file to README contents
# Usage: add_file_to_readme "patterns" "firebase.my-pattern.md" "Description"
add_file_to_readme() {
    local type="$1"  # patterns, commands, designs
    local filename="$2"
    local description="$3"
    
    # Update entire contents section
    update_readme_contents
}
```

**Expected Outcome**: Function adds file to README  

### 5. Test README Updates

Test README update functions:

**Actions**:
- Create test README.md with markers
- Create test package.yaml with contents
- Run update_readme_contents()
- Verify contents section updated correctly
- Test with empty contents
- Test with multiple files

**Expected Outcome**: README updates work correctly  

### 6. Document README Utilities

Update documentation:

**Actions**:
- Add function documentation to common.sh
- Update design doc
- Add usage examples

**Expected Outcome**: Utilities documented  

---

## Verification

- [ ] update_readme_contents() function implemented
- [ ] generate_contents_section() function implemented
- [ ] add_file_to_readme() function implemented
- [ ] Functions tested with various scenarios
- [ ] HTML comment markers work correctly
- [ ] Descriptions extracted from package.yaml
- [ ] Empty sections handled gracefully
- [ ] Documentation updated

---

**Next Task**: [Task 17: @acp.pattern-create Command](task-17-pattern-create-command.md)  
**Related Design Docs**: [ACP Package Development System](../design/acp-package-development-system.md)  
