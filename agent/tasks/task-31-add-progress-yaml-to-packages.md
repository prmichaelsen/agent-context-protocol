# Task 31: Add progress.yaml to Package Repositories

**Milestone**: Future Enhancement  
**Estimated Time**: 1-2 hours  
**Dependencies**: None  
**Status**: Not Started  

---

## Objective

Update `@acp.package-create` to initialize `progress.yaml` in package repositories so package developers can use the full ACP workflow for tracking package development.

---

## Context

ACP packages ARE projects managed by ACP, but currently `@acp.package-create` doesn't create `progress.yaml`. This means:
- ❌ Package developers can't use `@acp.init`, `@acp.proceed`, `@acp.status`
- ❌ No progress tracking for package development
- ❌ Can't track milestones like "Add Core Patterns", "Documentation", "Publishing"
- ❌ Inconsistent experience between projects and packages

**Solution**: `@acp.package-create` should create `progress.yaml` with package-specific milestones.  

**Note**: `progress.yaml` is for package development only - it's NOT installed to user projects (already excluded via `.gitignore` in packages).  

---

## Steps

### 1. Verify progress.yaml is Excluded from Installation

Check that `progress.yaml` is already excluded:

**Actions**:
- Verify `.gitignore` in packages includes `agent/progress.yaml`
- Verify `acp.package-install.sh` doesn't copy `progress.yaml`
- Confirm `progress.yaml` is for development only

**Expected Outcome**: Confirmed progress.yaml won't be installed to user projects  

### 2. Update acp.package-create.sh

Add step to create `progress.yaml` after ACP installation:

```bash
# After: bash "${SCRIPT_DIR}/acp.install.sh"

# Step 3.5: Create progress.yaml for package development
echo "${BOLD}Creating Progress Tracking${NC}"
echo ""

# Get current date
CURRENT_DATE=$(date +%Y-%m-%d)

cat > "agent/progress.yaml" << EOF
# Package Development Progress Tracking
# ACP Package: ${PACKAGE_NAME}

project:
  name: ${PACKAGE_NAME}
  version: 1.0.0
  type: package
  started: ${CURRENT_DATE}
  status: in_progress
  current_milestone: null
  description: |
    ACP Package: ${DESCRIPTION}

milestones: []

tasks: {}

documentation:
  design_documents: 0
  milestone_documents: 0
  pattern_documents: 0
  task_documents: 0
  command_documents: 0
  last_updated: ${CURRENT_DATE}

progress:
  planning: 0
  implementation: 0
  testing: 0
  documentation: 0
  overall: 0

recent_work:
  - date: ${CURRENT_DATE}
    description: |
      📦 Package Created: ${PACKAGE_NAME}
      Initial package structure created. Ready for content development.
    items:
      - ✅ Created package.yaml with metadata
      - ✅ Installed full ACP (templates, commands, scripts)
      - ✅ Created README.md, LICENSE, CHANGELOG.md
      - ✅ Initialized git repository
      - ✅ Installed pre-commit hook
      - ✅ Created progress.yaml for development tracking
      - 📋 Ready to add content with entity creation commands

next_steps:
  - Add patterns using @acp.pattern-create
  - Add commands using @acp.command-create
  - Add designs using @acp.design-create
  - Create milestones and tasks as needed
  - Validate package with @acp.package-validate
  - Publish with @acp.package-publish

notes:
  - This is an ACP package repository
  - Use entity creation commands to add content
  - Create milestones and tasks as you plan development
  - progress.yaml is for development only (not installed to user projects)

current_blockers: []

team:
  - role: Package Author
    name: ${AUTHOR}
    focus: |
      Developing ${PACKAGE_NAME} package
EOF

echo "${GREEN}✓${NC} Created progress.yaml for package development tracking"
echo ""
```

**Expected Outcome**: progress.yaml created with package-specific structure  

### 3. Update Success Message

Add progress.yaml to the success message:

```bash
echo "Your package has:"
echo "  ${GREEN}✓${NC} Full ACP installation (all templates and commands)"
echo "  ${GREEN}✓${NC} Pre-commit hook (validates package.yaml before commits)"
echo "  ${GREEN}✓${NC} Release branch configured (${RELEASE_BRANCH})"
echo "  ${GREEN}✓${NC} Git repository initialized"
echo "  ${GREEN}✓${NC} Bootstrap script (scripts/bootstrap.sh)"
echo "  ${GREEN}✓${NC} Progress tracking (agent/progress.yaml)"  # NEW
```

**Expected Outcome**: Users know progress.yaml was created  

### 4. Update Documentation

Update `agent/commands/acp.package-create.md` to mention progress.yaml:

**Add section**:
```markdown
## Progress Tracking

The created package includes `agent/progress.yaml` for tracking package development:
- Track milestones (Infrastructure, Content, Publishing)
- Track tasks (pattern creation, command creation, etc.)
- Use standard ACP commands (@acp.init, @acp.proceed, @acp.status)
- Monitor development progress

**Note**: progress.yaml is for package development only and is NOT installed to user projects (excluded via .gitignore).  
```

**Expected Outcome**: Documentation explains progress.yaml usage  

### 5. Test Package Creation

Test that progress.yaml is created correctly:

**Actions**:
- Create test package: `./agent/scripts/acp.package-create.sh test-package`
- Verify `agent/progress.yaml` exists
- Verify progress.yaml has package-specific structure
- Test ACP commands work: `@acp.init`, `@acp.status`
- Verify progress.yaml is in `.gitignore`

**Expected Outcome**: progress.yaml works correctly in packages  

---

## Verification

- [ ] acp.package-create.sh creates progress.yaml
- [ ] progress.yaml has package-specific structure
- [ ] Milestone 1 (Infrastructure) marked as completed
- [ ] Milestone 2 (Content Development) ready for work
- [ ] Initial tasks documented in progress.yaml
- [ ] Success message mentions progress.yaml
- [ ] Documentation updated
- [ ] Tested with new package creation
- [ ] ACP commands work in package repositories
- [ ] progress.yaml excluded from user installations

---

## Expected Output

### Files Modified
- `agent/scripts/acp.package-create.sh` - Add progress.yaml creation step
- `agent/commands/acp.package-create.md` - Document progress.yaml

### Example progress.yaml Structure

```yaml
project:
  name: my-package
  version: 1.0.0
  type: package  # Indicates this is a package
  status: in_progress
  current_milestone: M2

milestones:
  - id: M1
    name: Package Infrastructure
    status: completed
    progress: 100
  
  - id: M2
    name: Core Content Development
    status: in_progress
    progress: 0

tasks:
  milestone_1:
    - id: task-1
      name: Initialize Package Structure
      status: completed
  
  milestone_2: []
```

---

## Common Issues and Solutions

### Issue 1: progress.yaml conflicts with template

**Symptom**: Error creating progress.yaml  

**Solution**: Ensure progress.template.yaml exists from ACP installation. Use custom content instead of copying template.  

### Issue 2: ACP commands still don't work

**Symptom**: Commands fail even with progress.yaml  

**Solution**: Verify progress.yaml is valid YAML. Check that current_milestone exists in milestones section.  

### Issue 3: progress.yaml installed to user projects

**Symptom**: Users get progress.yaml when installing package  

**Solution**: Verify .gitignore includes agent/progress.yaml. Verify acp.package-install.sh doesn't copy progress.yaml.  

---

## Resources

- [Package Create Script](../scripts/acp.package-create.sh)
- [Package Create Command](../commands/acp.package-create.md)
- [Progress Template](../progress.template.yaml)

---

## Notes

- progress.yaml is for package development only
- NOT installed to user projects (excluded via .gitignore)
- Enables full ACP workflow for package development
- Package-specific milestones (Infrastructure, Content, Publishing)
- Backward compatible (doesn't affect existing packages)
- Low effort, high impact enhancement

---

**Next Task**: TBD  
**Estimated Completion Date**: TBD  
