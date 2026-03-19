# Task 14: YAML Schema System

**Milestone**: [M4 - ACP Package Development System](../milestones/milestone-4-package-development.md)  
**Estimated Time**: 6-8 hours  
**Dependencies**: None  
**Status**: Not Started  

---

## Objective

Create a pure bash YAML schema validation system that can validate package.yaml, manifest.yaml, and other YAML files against schema definitions. This provides structural validation without requiring external dependencies.

---

## Context

From clarifications:
- Pure bash implementation (zero dependencies)
- YAML-based schema definitions (not JSON Schema)
- Store schemas in agent/schemas/
- Priority: package.yaml schema first
- Follow industry patterns if they exist

---

## Steps

### 1. Research YAML Schema Standards

Research existing YAML schema validation approaches:

**Actions**:
- Research YAML Schema specification (if exists)
- Research JSON Schema for YAML (common approach)
- Look for existing bash YAML validators
- Document findings in design doc

**Expected Outcome**: Understanding of validation approaches and patterns  

### 2. Create agent/schemas/ Directory

Create directory structure for schema definitions:

**Actions**:
```bash
mkdir -p agent/schemas
touch agent/schemas/.gitkeep
```

**Expected Outcome**: Directory ready for schema files  

### 3. Create package.schema.yaml

Define schema for package.yaml validation:

**Actions**:
- Create agent/schemas/package.schema.yaml
- Define required fields (name, version, description, author, license, repository)
- Define field types and formats
- Define validation rules

**Schema Structure**:
```yaml
# agent/schemas/package.schema.yaml
schema_version: 1.0.0
description: Schema for ACP package.yaml files

required_fields:
  - name
  - version
  - description
  - author
  - license
  - repository

fields:
  name:
    type: string
    pattern: "^[a-z0-9-]+$"
    description: Package name (lowercase, alphanumeric, hyphens)
    
  version:
    type: string
    pattern: "^[0-9]+\\.[0-9]+\\.[0-9]+$"
    description: Semantic version (X.Y.Z)
    
  description:
    type: string
    min_length: 10
    max_length: 200
    description: One-line package description
    
  author:
    type: string
    description: Package author name
    
  license:
    type: string
    description: License identifier (e.g., MIT, Apache-2.0)
    
  repository:
    type: string
    pattern: "^https?://.*\\.git$"
    description: Git repository URL
    
  homepage:
    type: string
    pattern: "^https?://.*"
    required: false
    description: Package homepage URL
    
  tags:
    type: array
    item_type: string
    required: false
    description: Tags for package discovery
    
  release:
    type: object
    required: false
    fields:
      branch:
        type: string
        description: Release branch name
    
  contents:
    type: object
    required: true
    fields:
      patterns:
        type: array
        required: false
      commands:
        type: array
        required: false
      designs:
        type: array
        required: false
    
  requires:
    type: object
    required: false
    fields:
      acp:
        type: string
        pattern: "^>=?[0-9]+\\.[0-9]+\\.[0-9]+$"
```

**Expected Outcome**: Complete schema definition for package.yaml  

### 4. Implement acp.yaml-validate.sh

Create pure bash YAML schema validator:

**Actions**:
- Create agent/scripts/acp.yaml-validate.sh
- Implement validate_yaml_file() function
- Check required fields
- Validate field types
- Validate formats (regex patterns)
- Provide helpful error messages
- Make sourceable by other scripts

**Key Functions**:
```bash
# Validate YAML file against schema
# Usage: validate_yaml_file "file.yaml" "schema.yaml"
# Returns: 0 if valid, 1 if invalid
validate_yaml_file() {
    local yaml_file="$1"
    local schema_file="$2"
    
    # Implementation here
}

# Check if field exists and matches type
# Usage: validate_field "field_name" "expected_type" "value"
validate_field() {
    local field="$1"
    local type="$2"
    local value="$3"
    
    # Implementation here
}

# Validate string pattern (regex)
# Usage: validate_pattern "value" "pattern"
validate_pattern() {
    local value="$1"
    local pattern="$2"
    
    # Implementation here
}
```

**Expected Outcome**: Working YAML validator script  

### 5. Test Validation

Test validator with valid and invalid package.yaml files:

**Actions**:
- Create test/valid-package.yaml (passes validation)
- Create test/invalid-package.yaml (fails validation)
- Run validator on both
- Verify error messages are helpful
- Test edge cases

**Expected Outcome**: Validator works correctly  

### 6. Document Schema System

Update documentation:

**Actions**:
- Document schema format in design doc
- Add usage examples
- Document validation capabilities
- Add troubleshooting section

**Expected Outcome**: Schema system fully documented  

---

## Verification

- [ ] agent/schemas/ directory created
- [ ] package.schema.yaml created with complete schema
- [ ] acp.yaml-validate.sh implemented
- [ ] validate_yaml_file() function works
- [ ] Validation tested with valid/invalid files
- [ ] Error messages are clear and helpful
- [ ] Script is sourceable by other scripts
- [ ] Documentation updated

---

## Expected Output

**Files Created**:
- `agent/schemas/package.schema.yaml` - Schema definition
- `agent/scripts/acp.yaml-validate.sh` - Validator script

**Validation Output Example**:
```
Validating package.yaml...

❌ Validation failed:

Required field missing: 'version'
Field 'name' invalid: Must match pattern ^[a-z0-9-]+$
  Current value: 'My Package' (contains spaces and uppercase)
Field 'repository' invalid: Must end with .git
  Current value: 'https://github.com/user/repo'

3 errors found
```

---

**Next Task**: [Task 15: Namespace Utilities](task-15-namespace-utilities.md)  
**Related Design Docs**: [ACP Package Development System](../design/acp-package-development-system.md)  
