# Task 71: Schema Extension for Templates

**Milestone**: [M9 - Template Source Files Support](../../milestones/milestone-9-template-source-files.md)
**Estimated Time**: 3-4 hours
**Dependencies**: None
**Status**: Not Started

---

## Objective

Extend the `package.yaml` schema to support template source files with metadata fields for name, description, target path, required flag, variables, and experimental status.

---

## Context

This is Phase 1 of the Template Source Files Support implementation. The schema extension provides the foundation for declaring templates in `package.yaml`, enabling the package system to understand, validate, and install template files.

**Design Document**: [`agent/design/local.acp-template-source-files.md`](../../design/local.acp-template-source-files.md)

---

## Steps

### 1. Update package.schema.yaml

Add templates section to contents object:

**Actions**:
- Open `agent/schemas/package.schema.yaml`
- Find the `contents` object definition
- Add `templates` array after `scripts` section
- Define template metadata structure

**Schema Addition**:
```yaml
contents:
  properties:
    templates:
      type: array
      required: false
      description: "Template source files (code, configs, etc.) to bundle with package"
      items:
        type: object
        required_fields:
          - name
          - description
          - target
        properties:
          name:
            type: string
            required: true
            description: "Path to template file relative to templates/ directory"
            pattern: "^[a-zA-Z0-9_/-]+\\.[a-zA-Z0-9]+$"
            examples:
              - "config/tsconfig.json"
              - "src/schemas/example.schema.ts"
          
          description:
            type: string
            required: true
            description: "What this template provides"
            min_length: 10
            max_length: 200
          
          target:
            type: string
            required: true
            description: "Where to install (relative to project root)"
            pattern: "^\\./.*$|^[a-zA-Z0-9_/-]+/$"
            examples:
              - "./"
              - "src/schemas/"
              - "config/"
          
          required:
            type: boolean
            required: false
            default: false
            description: "Must be installed or optional"
          
          variables:
            type: array
            required: false
            description: "Placeholder variables for substitution"
            items:
              type: string
              pattern: "^[A-Z_][A-Z0-9_]*$"
            examples:
              - ["PACKAGE_NAME", "AUTHOR_NAME"]
          
          experimental:
            type: boolean
            required: false
            default: false
            description: "Requires --experimental flag to install"
```

### 2. Add Template Validation Rules

Add validation functions for template-specific checks:

**Actions**:
- Document validation rules in schema comments
- Add examples of valid and invalid template declarations
- Note security considerations for target paths

**Validation Rules**:
```yaml
# Validation Rules for Templates:
# 1. name must be valid file path (no .., no absolute paths)
# 2. target must be relative path (starts with ./ or directory name)
# 3. target must not escape project root (no ../)
# 4. variables must be UPPER_SNAKE_CASE
# 5. File must exist in templates/ directory
# 6. If experimental: true, file must have **Status**: Experimental
```

### 3. Update package.template.yaml

Add templates example to package template:

**Actions**:
- Open `agent/package.template.yaml`
- Add templates section with comprehensive examples
- Show required vs optional templates
- Show templates with variables
- Show experimental templates

**Template Addition**:
```yaml
contents:
  # ... existing patterns, commands, designs, scripts ...
  
  templates:
    # Required configuration template
    - name: config/tsconfig.json
      description: TypeScript configuration for core libraries
      target: ./
      required: true
      experimental: false
    
    # Template with variable substitution
    - name: config/package.json.template
      description: npm package.json with subpath exports
      target: ./
      required: true
      variables:
        - PACKAGE_NAME
        - PACKAGE_DESCRIPTION
        - AUTHOR_NAME
    
    # Optional source code template
    - name: src/schemas/example.schema.ts
      description: Example Zod schema structure
      target: src/schemas/
      required: false
    
    # Experimental template
    - name: src/experimental/feature.ts
      description: Experimental feature template
      target: src/experimental/
      required: false
      experimental: true
```

### 4. Document Template Structure

Add comments explaining template system:

**Actions**:
- Add header comment to templates section
- Explain target path behavior
- Document variable substitution format
- Note security considerations

**Documentation**:
```yaml
# Templates: Source code files, configurations, and project scaffolding
# 
# Templates are installed to target paths (relative to project root)
# NOT to agent/ directory like patterns/commands/designs
# 
# Variable Substitution:
#   - Templates can contain {{VARIABLE_NAME}} placeholders
#   - User prompted for values during installation
#   - Variables must be declared in variables array
# 
# Security:
#   - Target paths validated (no ../, no absolute paths)
#   - User warned when installing outside agent/ directory
#   - Conflict detection before overwriting existing files
```

### 5. Validate Schema Syntax

Ensure schema is valid YAML:

**Actions**:
- Run `agent/scripts/acp.yaml-parser.sh` to parse schema
- Check for syntax errors
- Verify all required fields are present
- Test with example package.yaml

```bash
# Validate schema syntax
./agent/scripts/acp.yaml-parser.sh agent/schemas/package.schema.yaml

# Test with example
cat > /tmp/test-package.yaml << 'EOF'
name: test
version: 1.0.0
contents:
  templates:
    - name: config/test.json
      description: Test template
      target: ./
EOF

./agent/scripts/acp.yaml-validate.sh /tmp/test-package.yaml
```

---

## Verification

- [ ] `agent/schemas/package.schema.yaml` updated with templates section
- [ ] Template metadata fields defined (name, description, target, required, variables, experimental)
- [ ] Validation rules documented in schema
- [ ] `agent/package.template.yaml` includes templates examples
- [ ] Examples show required, optional, variables, and experimental templates
- [ ] Schema syntax is valid (parses without errors)
- [ ] Test package.yaml with templates validates correctly
- [ ] Documentation comments added to schema
- [ ] Security considerations documented

---

## Expected Output

### Files Modified

**agent/schemas/package.schema.yaml**:
- Added `templates` array to `contents` object
- Defined 6 template metadata fields
- Added validation rules and examples

**agent/package.template.yaml**:
- Added templates section with 4 example templates
- Shows required, optional, variables, and experimental usage

### Schema Structure

```yaml
contents:
  patterns: [...]
  commands: [...]
  designs: [...]
  scripts: [...]
  templates:  # NEW
    - name: string (required, pattern validated)
      description: string (required, 10-200 chars)
      target: string (required, relative path)
      required: boolean (optional, default: false)
      variables: string[] (optional, UPPER_SNAKE_CASE)
      experimental: boolean (optional, default: false)
```

---

## Common Issues and Solutions

### Issue 1: Schema validation fails

**Symptom**: `acp.yaml-validate.sh` reports schema errors
**Solution**: Check YAML syntax, ensure proper indentation, verify all required fields present

### Issue 2: Target path validation unclear

**Symptom**: Confusion about valid target paths
**Solution**: Document that target must be relative (`./ or dirname/`), no `../`, no absolute paths

### Issue 3: Variable naming confusion

**Symptom**: Unclear what variable names are valid
**Solution**: Document UPPER_SNAKE_CASE requirement, provide examples (PACKAGE_NAME, AUTHOR_EMAIL)

---

## Resources

- [`agent/schemas/package.schema.yaml`](../../schemas/package.schema.yaml): Current schema
- [`agent/design/local.acp-template-source-files.md`](../../design/local.acp-template-source-files.md): Design document
- [`agent/schemas/projects.schema.yaml`](../../schemas/projects.schema.yaml): Example schema structure

---

## Notes

- Templates are optional - packages can omit templates section
- Target paths are relative to project root, NOT agent/ directory
- This is different from patterns/commands/designs which install to agent/
- Security validation critical - target paths must be safe
- Variable substitution format: `{{VARIABLE_NAME}}`
- Experimental templates follow same rules as experimental commands/patterns

---

**Next Task**: [Task 72: Installation System](task-72-installation-system.md)
**Related Design Docs**: [Template Source Files Support](../../design/local.acp-template-source-files.md)
**Estimated Completion Date**: TBD
