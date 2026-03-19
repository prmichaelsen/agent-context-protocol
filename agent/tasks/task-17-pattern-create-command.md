# Task 17: @acp.pattern-create Command

**Milestone**: [M4 - ACP Package Development System](../milestones/milestone-4-package-development.md)  
**Estimated Time**: 6-8 hours  
**Dependencies**: Task 14 (YAML Schema), Task 15 (Namespace Utilities), Task 16 (README Utilities)  
**Status**: Not Started  

---

## Objective

Implement @acp.pattern-create command that creates pattern files with namespace enforcement, draft file support, clarification workflow, and automatic package.yaml/README.md updates.

---

## Context

From clarifications:
- Chat-based information collection
- Support draft file input (@draft.md or path)
- Create clarification if draft is ambiguous
- Context-aware (package vs project)
- Auto-update package.yaml and README.md
- Namespace enforcement

---

## Steps

### 1. Create Command Documentation

Create agent/commands/acp.pattern-create.md:

**Sections**:
- Purpose and description
- Prerequisites
- Steps (detailed workflow)
- Verification checklist
- Examples (with and without draft)
- Troubleshooting
- Security considerations

**Expected Outcome**: Complete command documentation  

### 2. Implement acp.pattern-create.sh Script

Create agent/scripts/acp.pattern-create.sh:

**Workflow**:
1. Detect context (is_acp_package)
2. Get namespace (infer_namespace or "local")
3. Check for draft file argument
4. If draft provided:
   - Read draft file
   - Analyze for clarity
   - Create clarification if needed
   - Wait for user responses
   - Generate pattern from clarification
5. If no draft:
   - Prompt for description in chat
   - Or offer to create empty draft
6. Collect pattern metadata (name, description, version)
7. Validate pattern name format
8. Generate pattern file from template
9. If in package:
   - Add to package.yaml contents
   - Update README.md
10. Report success

**Expected Outcome**: Working script  

### 3. Implement Draft File Support

Add draft file handling:

**Functions**:
```bash
# Find draft file (supports @ syntax and paths)
find_draft_file() {
    local draft_ref="$1"
    # Implementation
}

# Read and analyze draft
analyze_draft() {
    local draft_file="$1"
    # Implementation
}

# Create clarification from draft
create_clarification_from_draft() {
    local draft_file="$1"
    local pattern_name="$2"
    # Implementation
}
```

**Expected Outcome**: Draft files can be processed  

### 4. Implement Clarification Workflow

Add clarification creation and processing:

**Actions**:
- Find next clarification number
- Create clarification-{N}-pattern-{name}.md
- Generate questions from draft analysis
- Wait for user to answer
- Read answered clarification
- Generate pattern from answers

**Expected Outcome**: Clarification workflow works  

### 5. Implement Package Updates

Add package.yaml and README updates:

**Actions**:
- Add pattern to package.yaml contents.patterns
- Extract or prompt for description
- Set version to 1.0.0
- Update README.md via update_readme_contents()

**Expected Outcome**: Package files updated automatically  

### 6. Test Pattern Creation

Test all scenarios:

**Actions**:
- Test in package directory
- Test in project directory
- Test with draft file
- Test without draft file
- Test with clarification workflow
- Test package.yaml updates
- Test README.md updates
- Test namespace enforcement

**Expected Outcome**: All scenarios work correctly  

---

## Verification

- [ ] acp.pattern-create.md created
- [ ] acp.pattern-create.sh implemented
- [ ] Chat-based collection works
- [ ] Draft file support works
- [ ] Clarification workflow works
- [ ] Context detection works (package vs project)
- [ ] Namespace enforcement works
- [ ] package.yaml updated automatically
- [ ] README.md updated automatically
- [ ] All scenarios tested
- [ ] Documentation complete

---

**Next Task**: [Task 18: @acp.command-create Command](task-18-command-create-command.md)  
**Related Design Docs**: [ACP Package Development System](../design/acp-package-development-system.md)  
