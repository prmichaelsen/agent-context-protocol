# ACP Commands System

**Concept**: Standardized command interface for ACP operations using file-based triggers  
**Created**: 2026-02-16  
**Status**: Design Specification  

---

## Overview

The ACP Commands System introduces a standardized, file-based interface for invoking common ACP operations. Instead of typing long prompts like "AGENT.md: Initialize", users can simply reference command files like `@acp-init` to trigger specific workflows. This provides a more intuitive, discoverable, and consistent user experience.

Commands are implemented as markdown files in the `agent/commands/` directory, each containing:
- Clear description of what the command does
- Step-by-step instructions for the AI agent
- Expected outcomes and verification steps
- Usage examples

---

## Problem Statement

### Current Issues

1. **Discoverability**: Users must read AGENT.md to find available prompts
2. **Inconsistency**: Prompt format varies ("AGENT.md: Initialize" vs "AGENT.md: Proceed")
3. **Verbosity**: Long prompts are tedious to type repeatedly
4. **No Autocomplete**: Users can't discover commands through IDE autocomplete
5. **Limited Extensibility**: Adding new workflows requires updating AGENT.md
6. **No Command Documentation**: Each prompt's behavior is scattered in AGENT.md

### User Pain Points

- "What commands are available?"
- "How do I update progress tracking?"
- "What's the difference between update and sync?"
- "Can I create custom commands?"

---

## Solution

### Command File System

Introduce a flat command directory structure where commands use dot notation for namespaces:

```
agent/
├── commands/
│   ├── command.template.md          # Command template
│   │
│   ├── acp.init.md                  # @acp-init
│   ├── acp.proceed.md               # @acp-proceed
│   ├── acp.status.md                # @acp-status
│   ├── acp.update.md                # @acp-update
│   ├── acp.sync.md                  # @acp-sync
│   ├── acp.version-check.md         # @acp-version-check
│   ├── acp.version-check-for-updates.md  # @acp-version-check-for-updates
│   ├── acp.version-update.md        # @acp-version-update
│   ├── acp.milestone-create.md      # @acp-milestone-create
│   ├── acp.task-create.md           # @acp-task-create
│   ├── acp.design-create.md         # @acp-design-create
│   ├── acp.install.md               # @acp-install
│   │
│   ├── custom.deploy.md             # @custom-deploy
│   ├── custom.backup.md             # @custom-backup
│   │
│   ├── deploy.production.md         # @deploy-production
│   └── deploy.staging.md            # @deploy-staging
```

**Flat Structure Benefits**:
- **Explicit Autocomplete**: Type `acp.` to see all ACP commands
- **Namespace Visible**: Namespace is part of filename
- **Single Directory**: All commands in one place
- **Easier Discovery**: No need to navigate subdirectories
- **Clear Ownership**: Namespace prefix shows command source
- **Isolation**: Commands from different sources don't conflict

### Command Invocation

Users invoke commands using the namespace-action format with hyphens:
- `@acp-init` - Resolves to `agent/commands/acp.init.md`
- `@acp-proceed` - Resolves to `agent/commands/acp.proceed.md`
- `@acp-status` - Resolves to `agent/commands/acp.status.md`
- `@custom-deploy` - Resolves to `agent/commands/custom.deploy.md`
- `@deploy-production` - Resolves to `agent/commands/deploy.production.md`

**Resolution Rules**:
1. Parse command as `@{namespace}-{action}`
2. Convert to filename: `{namespace}.{action}.md`
3. Look for file at `agent/commands/{namespace}.{action}.md`
4. If not found, show error with available commands

**Examples**:
- `@acp-version-check` → `acp.version-check.md`
- `@deploy-production` → `deploy.production.md`
- `@custom-backup` → `custom.backup.md`

### Command Structure

Each command file follows a standard structure:

```markdown
# Command: {command-name}

**Purpose**: One-line description  
**Category**: [Workflow | Documentation | Maintenance | Creation]  
**Frequency**: [Once | Per Session | As Needed | Continuous]  

---

## What This Command Does

[Clear explanation of the command's purpose and when to use it]

---

## Prerequisites

- [ ] Prerequisite 1
- [ ] Prerequisite 2

---

## Steps

1. **Step 1**: [Action]
   - Details
   - Expected outcome

2. **Step 2**: [Action]
   - Details
   - Expected outcome

---

## Verification

- [ ] Verification item 1
- [ ] Verification item 2

---

## Expected Output

[Description of what should happen after command execution]

---

## Related Commands

- `@acp-related-command` - [When to use instead]
```

---

## Implementation

### Phase 1: Core Commands

Create essential commands that replace existing prompts. All core commands live in the `acp/` namespace directory.

#### 1. `acp.init.md` - Initialize (@acp-init)
Replaces: "AGENT.md: Initialize"

**Purpose**: Bootstrap agent context and prepare for work  

**Steps**:
1. Check for ACP updates (`./agent/scripts/acp.version-check-for-updates.sh`)
2. Read all files in `agent/` directory
3. Read key source files based on project type
4. Update stale documentation
5. Update `agent/progress.yaml`
6. Report current status and next steps

#### 2. `acp.proceed.md` - Proceed (@acp-proceed)
Replaces: "AGENT.md: Proceed"

**Purpose**: Continue with current or next task  

**Steps**:
1. Read `agent/progress.yaml` to find current task
2. Read current task document
3. Execute task steps
4. Verify completion
5. Update `agent/progress.yaml`
6. Report progress

#### 3. `acp.update.md` - Update Progress (@acp-update)
New command

**Purpose**: Update progress.yaml with latest status  

**Steps**:
1. Read `agent/progress.yaml`
2. Review recent work completed
3. Update task statuses
4. Update milestone progress percentages
5. Add recent work entries
6. Update next steps
7. Save changes

#### 4. `acp.sync.md` - Sync Documentation (@acp-sync)
New command

**Purpose**: Read code and update stale documentation  

**Steps**:
1. Read source code files
2. Compare with design documents
3. Identify discrepancies
4. Update design documents
5. Update pattern documents if needed
6. Update progress.yaml with sync notes

#### 5. `acp-version-update.md` - Update ACP
Replaces: "AGENT.md: Update"

**Purpose**: Update ACP files to latest version  

**Steps**:
1. Run `./agent/scripts/acp.version-update.sh`
2. Review changes
3. Report what was updated
4. Suggest next actions

#### 6. `acp-status.md` - Show Status
New command

**Purpose**: Display current project status  

**Steps**:
1. Read `agent/progress.yaml`
2. Show current milestone and progress
3. Show current task
4. List recent work
5. List next steps
6. List blockers

### Phase 2: Creation Commands

Commands for creating new documents:

#### 7. `acp-milestone-create.md`
Create new milestone from template

#### 8. `acp-task-create.md`
Create new task from template

#### 9. `acp-design-create.md`
Create new design document from template

#### 10. `acp-pattern-create.md`
Create new pattern document from template

### Phase 3: Advanced Commands

#### 11. `acp-validate.md`
Validate all ACP documents for consistency

#### 12. `acp-report.md`
Generate comprehensive project report

#### 13. `acp-archive.md`
Archive completed milestones and tasks

---

## Benefits

### 1. Discoverability
- Users can see all available commands in `agent/commands/`
- IDE autocomplete shows command files
- README.md in commands directory lists all commands

### 2. Consistency
- All commands follow the same structure
- Predictable naming convention (`acp-{action}`)
- Standardized output format

### 3. Extensibility
- Users can create custom commands
- Project-specific commands in same directory
- Commands can reference other commands

### 4. Documentation
- Each command is self-documenting
- Clear prerequisites and verification steps
- Related commands linked

### 5. Maintainability
- Commands are versioned with ACP
- Easy to update individual commands
- Clear separation of concerns

### 6. User Experience
- Shorter invocation (`@acp-init` vs "AGENT.md: Initialize")
- Tab completion in IDEs
- Visual file icons in file explorers

---

## Trade-offs

### 1. Additional Files
**Downside**: More files in the repository (10-15 command files)  
**Mitigation**: Commands are organized in dedicated directory, templates provided  

### 2. Learning Curve
**Downside**: Users need to learn new command system  
**Mitigation**: 
- Backward compatibility with old prompts
- Clear migration guide
- README.md with command list

### 3. Maintenance Overhead
**Downside**: Commands need to be kept in sync with AGENT.md  
**Mitigation**:
- Commands are source of truth
- AGENT.md references commands
- Update scripts update both

### 4. File Proliferation
**Downside**: Many small files instead of one large document  
**Mitigation**:
- Better organization than single file
- Each command is focused and clear
- Easier to find specific functionality

---

## Command Categories

### Workflow Commands
- `acp-init` - Initialize agent context
- `acp-proceed` - Continue with next task
- `acp-status` - Show current status

### Documentation Commands
- `acp-sync` - Sync code with documentation
- `acp-update` - Update progress tracking
- `acp-validate` - Validate documentation

### Maintenance Commands
- `acp-version-update` - Update ACP version
- `acp-archive` - Archive completed work

### Creation Commands
- `acp-milestone-create` - Create milestone
- `acp-task-create` - Create task
- `acp-design-create` - Create design document
- `acp-pattern-create` - Create pattern document

---

## Command Naming Convention

### Invocation Format
Commands are invoked as: `@{namespace}-{action}`

**Examples**:
- `@acp-init` → `agent/commands/acp.init.md` (reserved)
- `@acp-milestone-create` → `agent/commands/acp.milestone-create.md` (reserved)
- `@deploy-production` → `agent/commands/deploy.production.md`
- `@custom-backup` → `agent/commands/custom.backup.md`

### File Naming Rules
1. **Namespace directory**: Use lowercase, single word (e.g., `acp/`, `custom/`, `deploy/`)
2. **Command files**: Use kebab-case (e.g., `init.md`, `milestone-create.md`)
3. **Imperative verbs**: Use action words (init, create, update, sync)
4. **Be descriptive**: Clear purpose from filename
5. **Avoid abbreviations**: Unless standard (init, sync)

### Reserved Namespaces

**⚠️ RESERVED: `acp/` namespace**

The `acp/` namespace is **reserved for core ACP commands only**. Users and third-party packages **must not** create commands in this namespace.

**Reserved Commands**:
- All commands starting with `@acp-*` are reserved
- Examples: `@acp-init`, `@acp-proceed`, `@acp-sync`, etc.
- Maintained by the ACP project
- Updated via `@acp-version-update`

### Namespace Guidelines

**For Users (Project-Specific Commands)**:
- Use descriptive namespace: `deploy`, `test`, `build`, `custom`
- Single word, no hyphens
- Lowercase only
- Examples: `@deploy-production`, `@test-integration`, `@build-docker`

**For Third-Party Packages**:
- Use package/organization name as namespace
- Examples: `github`, `aws`, `docker`, `vercel`
- Document namespace in package README
- Examples: `@github-create-pr`, `@aws-deploy`, `@docker-build`

**Valid User/Third-Party Examples**:
- ✅ `deploy.production.md` → `@deploy-production`
- ✅ `custom.backup.md` → `@custom-backup`
- ✅ `github.create-pr.md` → `@github-create-pr`
- ✅ `test.e2e.md` → `@test-e2e`

**Invalid Examples**:
- ❌ `acp.my-command.md` → `@acp-my-command` (reserved namespace!)
- ❌ `my-custom.deploy.md` (namespace has hyphen)
- ❌ `Deploy.production.md` (uppercase not allowed)
- ❌ `deploy-production.md` (missing namespace dot separator)

---

## Directory Structure

### Flat Structure with Dot Notation (Recommended)

```
agent/
├── commands/
│   ├── command.template.md          # Command template
│   │
│   ├── acp.init.md                  # @acp-init
│   ├── acp.proceed.md               # @acp-proceed
│   ├── acp.status.md                # @acp-status
│   ├── acp.update.md                # @acp-update
│   ├── acp.sync.md                  # @acp-sync
│   ├── acp.validate.md              # @acp-validate
│   ├── acp.version-check.md         # @acp-version-check
│   ├── acp.version-check-for-updates.md  # @acp-version-check-for-updates
│   ├── acp.version-update.md        # @acp-version-update
│   ├── acp.milestone-create.md      # @acp-milestone-create
│   ├── acp.task-create.md           # @acp-task-create
│   ├── acp.design-create.md         # @acp-design-create
│   ├── acp.pattern-create.md        # @acp-pattern-create
│   ├── acp.report.md                # @acp-report
│   ├── acp.install.md               # @acp-install
│   │
│   ├── custom.deploy.md             # @custom-deploy
│   ├── custom.backup.md             # @custom-backup
│   │
│   ├── deploy.production.md         # @deploy-production
│   ├── deploy.staging.md            # @deploy-staging
│   └── deploy.rollback.md           # @deploy-rollback
```

### Benefits of Flat Structure with Dot Notation

1. **Explicit Autocomplete**: Type `acp.` to see all ACP commands immediately
   - IDE autocomplete shows all commands with that namespace prefix
   - No need to navigate into subdirectories

2. **Clear Namespace Separation**: Dot visually separates namespace from command
   - `acp.status` is clearly namespace.command
   - Follows common conventions (Java packages, npm scopes)

3. **Single Directory**: All commands visible in one place
   - `ls agent/commands/` shows everything
   - Easy to browse and discover

4. **No Conflicts**: Namespace prefix prevents collisions
   - `acp.deploy` vs `custom.deploy` vs `aws.deploy`

5. **Easy Parsing**: Split on dot to extract namespace
   - `acp.status` → namespace: `acp`, command: `status`

6. **Grep-Friendly**: Find all commands in a namespace
   - `ls agent/commands/acp.*` shows all ACP commands
   - `ls agent/commands/deploy.*` shows all deploy commands

### Discovery Examples

```bash
# List all ACP commands
ls agent/commands/acp.*

# List all deploy commands
ls agent/commands/deploy.*

# List all commands
ls agent/commands/*.md | grep -v template
```

---

## Command Template

```markdown
# Command: {command-name}

**Purpose**: [One-line description of what this command does]  
**Category**: [Workflow | Documentation | Maintenance | Creation]  
**Frequency**: [Once | Per Session | As Needed | Continuous]  
**Aliases**: [Alternative names or shortcuts]  

---

## What This Command Does

[2-3 paragraph explanation of:
- What the command accomplishes
- When to use it
- What problems it solves]

---

## Prerequisites

[List any requirements before running this command:]

- [ ] Prerequisite 1 (e.g., "ACP must be installed")
- [ ] Prerequisite 2 (e.g., "progress.yaml must exist")
- [ ] Prerequisite 3 (e.g., "Git repository initialized")

---

## Steps

[Detailed, sequential steps the agent should follow:]

### 1. [Step Name]

[Description of what to do]

**Actions**:
- Action item 1
- Action item 2

**Expected Outcome**: [What should happen]  

### 2. [Step Name]

[Description of what to do]

**Actions**:
- Action item 1
- Action item 2

**Expected Outcome**: [What should happen]  

---

## Verification

[Checklist to confirm command executed successfully:]

- [ ] Verification item 1
- [ ] Verification item 2
- [ ] Verification item 3

---

## Expected Output

[Describe what the user should see after command execution:]

**Files Modified**:
- `path/to/file1` - [What changed]
- `path/to/file2` - [What changed]

**Console Output**:
```
Example output message
```

**Status Update**:
[Description of status changes]

---

## Examples

### Example 1: [Scenario Name]

**Context**: [When you'd use this]  

**Invocation**: `@acp-command-name`  

**Result**: [What happens]  

### Example 2: [Scenario Name]

**Context**: [When you'd use this]  

**Invocation**: `@acp-command-name`  

**Result**: [What happens]  

---

## Related Commands

- [`@acp-related-command`](./acp-related-command.md) - [When to use instead]
- [`@acp-another-command`](./acp-another-command.md) - [How it relates]

---

## Troubleshooting

### Issue 1: [Common Problem]
**Symptom**: [What the user sees]  
**Solution**: [How to fix it]  

### Issue 2: [Common Problem]
**Symptom**: [What the user sees]  
**Solution**: [How to fix it]  

---

## Notes

- Note 1: [Important information]
- Note 2: [Important information]

---

**Version**: 1.0.0  
**Last Updated**: YYYY-MM-DD  
**Compatibility**: ACP 1.0.3+  
```

---

## Migration Strategy

### Phase 1: Create Command Infrastructure (Week 1)
1. Create `agent/commands/` directory structure
2. Create `agent/commands/README.md` with overview
3. Create command template file
4. Update installation scripts to include commands directory

### Phase 2: Implement Core Commands (Week 2)
1. Create `acp-init.md` (replaces "AGENT.md: Initialize")
2. Create `acp-proceed.md` (replaces "AGENT.md: Proceed")
3. Create `acp-version-update.md` (replaces "AGENT.md: Update")
4. Test commands with AI agents

### Phase 3: Add New Commands (Week 3)
1. Create `acp-update.md` (new)
2. Create `acp-sync.md` (new)
3. Create `acp-status.md` (new)
4. Document all commands in README

### Phase 4: Creation Commands (Week 4)
1. Create `acp-milestone-create.md`
2. Create `acp-task-create.md`
3. Create `acp-design-create.md`
4. Create `acp-pattern-create.md`

### Phase 5: Update Documentation (Week 5)
1. Update AGENT.md to reference commands
2. Update README.md with command examples
3. Add migration guide for existing users
4. Update CHANGELOG.md

### Phase 6: Advanced Features (Future)
1. Command composition (commands calling commands)
2. Command parameters
3. Custom user commands
4. Command validation

---

## Backward Compatibility

### Maintaining Old Prompts

Keep existing prompt system working:
- "AGENT.md: Initialize" still works
- "AGENT.md: Proceed" still works
- "AGENT.md: Update" still works

### Migration Path

1. **Soft Launch**: Commands available but optional
2. **Documentation**: Show both methods in examples
3. **Deprecation Notice**: After 2-3 versions, mark old prompts as deprecated
4. **Removal**: After 6+ months, remove old prompt documentation

### Example Migration

**Old Way**:
```
User: "AGENT.md: Initialize"
```

**New Way**:
```
User: "@acp-init"
```

**Both Work**: For at least 6 months after command system launch  

---

## Testing Strategy

### Unit Testing Commands

Each command should be testable:

1. **Prerequisites Check**: Verify prerequisites are met
2. **Step Execution**: Verify each step executes correctly
3. **Verification**: Confirm verification items pass
4. **Output**: Validate expected output produced

### Integration Testing

Test command workflows:

1. **Fresh Project**: Test `@acp-init` on new project
2. **Existing Project**: Test `@acp-sync` on existing project
3. **Command Chaining**: Test `@acp-init` → `@acp-proceed` → `@acp-update`
4. **Error Handling**: Test commands with missing prerequisites

### User Acceptance Testing

1. Test with multiple AI agents (Claude, GPT-4, etc.)
2. Test with different project types
3. Gather feedback on command clarity
4. Measure time savings vs old prompts

---

## Success Metrics

### Adoption Metrics
- % of users using commands vs old prompts
- Number of custom commands created by users
- Command invocation frequency

### Quality Metrics
- Command execution success rate
- Time to complete workflows
- User satisfaction scores

### Documentation Metrics
- Command documentation completeness
- Number of troubleshooting issues resolved
- Command discovery rate (how quickly users find commands)

---

## Future Enhancements

### Command Parameters

Allow commands to accept parameters:
```
@acp-milestone-create name="Foundation" duration="2 weeks"
```

### Command Composition

Allow commands to call other commands:
```markdown
# In acp-full-sync.md
1. Execute @acp-sync
2. Execute @acp-update
3. Execute @acp-validate
```

### Custom Commands

Allow users to create project-specific commands:
```
agent/
├── commands/
│   ├── acp-init.md              # Standard ACP command
│   └── custom-deploy.md         # Project-specific command
```

### Command Aliases

Support shorter aliases:
```
@init → @acp-init
@go → @acp-proceed
@sync → @acp-sync
```

### Interactive Commands

Commands that prompt for input:
```
@acp-milestone-create
> Milestone name: Foundation
> Duration: 2 weeks
> Dependencies: None
```

### Command History

Track command execution:
```yaml
# agent/command-history.yaml
history:
  - command: acp-init
    timestamp: 2026-02-16T10:00:00Z
    status: success
  - command: acp-proceed
    timestamp: 2026-02-16T10:15:00Z
    status: success
```

---

## Security Considerations

### ⚠️ Third-Party Command Risk

**Users assume all risk when installing third-party commands.**

Commands are markdown files containing instructions for AI agents. While core ACP commands (`acp/` namespace) are maintained by the ACP project, third-party commands can:

1. **Modify any files**: Commands can instruct agents to modify files anywhere in the project, not just `agent/` directory
2. **Execute scripts**: Commands can instruct agents to run shell scripts, build commands, deployment scripts, etc.
3. **Access sensitive data**: Commands could potentially instruct agents to read configuration files, environment variables, or other sensitive data
4. **Make network requests**: Commands could instruct agents to make API calls, clone repositories, or interact with external services

### Security Best Practices

**For Users**:
1. **Review before installing**: Always review third-party command files before installation
2. **Trust the source**: Only install commands from trusted authors and repositories
3. **Understand the commands**: Read what each command does before using it
4. **Use version control**: Commit before installing new commands so you can revert if needed
5. **Audit regularly**: Periodically review installed third-party commands

**For Command Authors**:
1. **Be explicit**: Clearly document what your commands do
2. **Minimize scope**: Commands should do one thing well
3. **Avoid secrets**: Never hardcode secrets or credentials
4. **Document risks**: Clearly state if commands modify files outside `agent/` or execute scripts
5. **Version your commands**: Use semantic versioning for command packages

### Core ACP Commands (`acp/` namespace)

Core ACP commands are designed with safety in mind:
- Primarily operate within `agent/` directory
- Explicit about file modifications
- No arbitrary script execution without clear documentation
- Maintained by ACP project with security reviews
- Updated via `@acp-version-update`

### Command Capabilities

Commands can instruct agents to:
- ✅ Read any file in the project
- ✅ Modify files in `agent/` directory (standard)
- ✅ Modify files outside `agent/` directory (if documented)
- ✅ Execute shell scripts (if documented)
- ✅ Make network requests (if documented)
- ❌ Should never expose secrets or credentials

---

## Documentation Requirements

### Command Template

A command template is provided at [`agent/commands/command.template.md`](../../commands/command.template.md) for creating new commands.

**Usage**:
```bash
# Copy template to create new command
cp agent/commands/command.template.md agent/commands/{namespace}/{command-name}.md

# Edit and fill in the template sections
```

The template includes:
- Command metadata (namespace, purpose, category)
- Detailed steps for execution
- Prerequisites and verification checklists
- Examples and troubleshooting
- Security considerations
- Related commands

### Command Discovery

Commands are self-documenting through the file system:

1. **Browse by namespace**: List commands in `agent/commands/{namespace}/`
2. **Read command files**: Each command file contains complete documentation
3. **Use IDE features**: Autocomplete shows available command files
4. **Use template**: Copy `command.template.md` to create new commands

**No central README needed** - Commands are discovered by browsing the namespace directories. This prevents documentation drift and keeps command documentation co-located with the command itself.

### AGENT.md Updates

Update AGENT.md to mention commands exist and reference the command template:

```markdown
## ACP Commands

ACP supports a command system for common workflows. Commands are organized by namespace in `agent/commands/`.

### Core Commands (`acp/` namespace)

Core ACP commands are available in `agent/commands/` with the `acp.` prefix. Browse this directory or use autocomplete to see available commands by typing `@acp-` (e.g., `@acp-init`, `@acp-proceed`).

### Creating Custom Commands

To create custom commands for your project:

1. Choose a namespace (e.g., `deploy`, `test`, `custom`)
2. Copy the command template: `cp agent/commands/command.template.md agent/commands/{namespace}.{command-name}.md`
3. Fill in the template sections with your command details

**Example**:
```bash
# Create a deployment command
cp agent/commands/command.template.md agent/commands/deploy.production.md

# Create a custom backup command
cp agent/commands/command.template.md agent/commands/custom.backup.md
```

See [`agent/commands/command.template.md`](agent/commands/command.template.md) for the template.

### Installing Third-Party Commands

Use `@acp-install` to install command packages from git repositories (copies files with namespace prefix to `agent/commands/`).
```

**Rationale**:
- No central README to maintain and keep in sync
- Commands are self-documenting
- Discovery happens through file system browsing
- IDE autocomplete works naturally
- Template file provides consistent structure
- Each namespace can have its own README if desired

---

## Implementation Checklist

### Phase 1: Infrastructure
- [ ] Create `agent/commands/` directory (flat structure)
- [ ] Create `agent/commands/command.template.md` template file
- [ ] Update installation scripts to copy command files with dot notation
- [ ] Remove nested directory structure

### Phase 2: Core Commands
- [ ] Implement `acp-init.md`
- [ ] Implement `acp-proceed.md`
- [ ] Implement `acp-version-check.md`
- [ ] Implement `acp-version-check-for-updates.md`
- [ ] Implement `acp-version-update.md`
- [ ] Test core commands

### Phase 3: Documentation Commands
- [ ] Implement `acp-update.md`
- [ ] Implement `acp-sync.md`
- [ ] Implement `acp-status.md`
- [ ] Implement `acp-validate.md`
- [ ] Test documentation commands

### Phase 4: Creation Commands
- [ ] Implement `acp-milestone-create.md`
- [ ] Implement `acp-task-create.md`
- [ ] Implement `acp-design-create.md`
- [ ] Implement `acp-pattern-create.md`
- [ ] Test creation commands

### Phase 5: Documentation
- [ ] Update AGENT.md
- [ ] Update README.md
- [ ] Update CHANGELOG.md
- [ ] Create migration guide
- [ ] Add examples

### Phase 6: Release
- [ ] Version bump to 1.1.0
- [ ] Tag release
- [ ] Announce to users
- [ ] Monitor feedback

---

## Dependencies

### Internal Dependencies
- AGENT.md (references commands)
- Installation scripts (install commands)
- Update scripts (update commands)

### External Dependencies
- None (commands are pure markdown)

### Tool Dependencies
- AI agents that support file references (@-syntax)
- IDEs with autocomplete for file references

---

## Risks and Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| AI agents don't support @-syntax | High | Low | Maintain backward compatibility with old prompts |
| Command proliferation | Medium | Medium | Limit to essential commands, clear naming |
| Documentation drift | Medium | Medium | Automated validation, update scripts |
| User confusion | Medium | Low | Clear README, migration guide, examples |
| Maintenance burden | Low | Medium | Template-based, automated updates |

---

## Alternatives Considered

### Alternative 1: Single Commands File

**Approach**: One `agent/commands.md` file with all commands  

**Pros**:
- Single file to maintain
- Easy to search
- No file proliferation

**Cons**:
- Large file (hard to navigate)
- No autocomplete per command
- Can't reference specific commands
- Harder to extend

**Decision**: Rejected - Multiple files provide better UX  

### Alternative 2: JSON/YAML Command Definitions

**Approach**: Define commands in structured data format  

**Pros**:
- Machine-readable
- Easy to parse
- Validation possible

**Cons**:
- Less human-readable
- Requires parsing logic
- Not self-documenting
- Harder for users to create

**Decision**: Rejected - Markdown is more accessible  

### Alternative 3: Script-Based Commands

**Approach**: Executable scripts instead of markdown  

**Pros**:
- Can execute directly
- More powerful
- Automated execution

**Cons**:
- Security concerns
- Platform-dependent
- Not agent-friendly
- Harder to customize

**Decision**: Rejected - Markdown is safer and more flexible  

---

## References

- [AGENT.md](../../AGENT.md) - Current prompt system
- [README.md](../../README.md) - User documentation
- [Command Pattern](https://en.wikipedia.org/wiki/Command_pattern) - Design pattern inspiration
- [GitHub Actions](https://docs.github.com/en/actions) - Similar workflow system

---

**Status**: Design Specification - Ready for Implementation  
**Recommendation**: Implement in phases starting with core commands  
**Next Steps**: 
1. Review and approve design
2. Create milestone for implementation
3. Break into tasks
4. Begin Phase 1 implementation

**Related Documents**:
- [Bootstrap Pattern](../patterns/bootstrap.template.md) - Project setup
- [Pattern Template](../patterns/pattern.template.md) - Pattern documentation

**Version**: 1.0.0  
**Last Updated**: 2026-02-16  
**Compatibility**: ACP 1.0.3+  
