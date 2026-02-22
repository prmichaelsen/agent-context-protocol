# Task 49: @acp.project-create Command

**Milestone**: M5 - Global Package Installation
**Estimated Time**: 3-4 hours
**Dependencies**: Task 29 (Global ACP Auto-Initialization)
**Status**: Not Started

---

## Objective

Create the `@acp.project-create` command that enables users to quickly bootstrap new **generic ACP projects** (not packages) in `~/.acp/projects/` with guided setup for project metadata.

---

## Context

Users currently have two ways to start new work:
1. Run `acp.install.sh` in an existing directory (manual)
2. Use `@acp.package-create` (creates **packages** with package.yaml, release branches, pre-commit hooks)

**The Problem**: `@acp.package-create` creates **packages** designed for distribution (with package.yaml, publishing workflow, etc.). But users also need to create **generic projects** - applications, tools, or experiments that use ACP for development but aren't meant to be published as ACP packages.

**The Solution**: `@acp.project-create` creates **generic ACP projects** without package-specific infrastructure.

### Key Differences from @acp.package-create

| Feature | @acp.package-create | @acp.project-create |
|---------|---------------------|---------------------|
| **Purpose** | Create distributable ACP packages | Create generic ACP projects |
| **Creates package.yaml** | ✅ Yes (required for packages) | ❌ No (not a package) |
| **Release branch config** | ✅ Yes (for publishing) | ❌ No (not publishing) |
| **Pre-commit hooks** | ✅ Yes (validates package.yaml) | ❌ No (no package.yaml to validate) |
| **Target location** | `~/.acp/projects/` or custom | `~/.acp/projects/` or custom |
| **README template** | Package-focused (installation, publishing) | Project-focused (development, usage) |
| **Use case** | Sharing patterns/commands with others | Building apps, tools, experiments |

**Both commands**:
- Can create in `~/.acp/projects/` (or any directory)
- Install full ACP (templates, commands, scripts)
- Initialize git repository
- Create README.md and .gitignore

---

## Steps

### 1. Collect Project Information

Gather project metadata via chat:

**Required Information**:
- **Project name** (kebab-case, will be directory name)
  - Example: "my-awesome-app"
  - Validation: lowercase, alphanumeric, hyphens only
- **Project description** (one-line summary)
  - Example: "A task management application with AI assistance"
- **Project type** (optional, for context)
  - Options: web-app, cli-tool, library, mcp-server, api, other
  - Used for README template selection

**Optional Information**:
- **Author name** (for documentation)
- **License** (default: MIT)

**Note**: Projects always use the `local` namespace for project-specific commands. Namespace configuration is only available for packages (via `@acp.package-create`).

### 2. Determine Target Directory

Calculate target directory path:

**Actions**:
- Default: `~/.acp/projects/{project-name}/`
- Expand `~` to `$HOME`
- Validate directory doesn't already exist
- If exists: Ask user to choose different name or confirm overwrite

**Expected Outcome**: Target directory path determined

### 3. Create Project Directory

Create the project directory structure:

**Actions**:
- Create target directory: `mkdir -p ~/.acp/projects/{project-name}/`
- Verify directory created successfully

**Expected Outcome**: Empty project directory exists

### 4. Install ACP

Run ACP installation in the new directory:

**Actions**:
- Execute: `cd ~/.acp/projects/{project-name}/ && {path-to-current-acp}/agent/scripts/acp.install.sh`
- Since we're guaranteed to be in an ACP-installed directory, use: `./agent/scripts/acp.install.sh`
- The script should be invoked from the new project directory
- Verify AGENT.md and agent/ directory created
- Verify all templates and scripts installed

**Implementation Note**: The command is invoked from an ACP-installed directory, so `./agent/scripts/acp.install.sh` is always available. The script needs to be executed in the context of the new project directory.

**Expected Outcome**: Full ACP installation in project directory

### 5. Create Project README.md

Generate project README with metadata:

**Actions**:
- Create README.md with:
  - Project name as title
  - Description
  - Project type badge (if specified)
  - Quick start section (placeholder)
  - Development section (placeholder)
  - License section
  - ACP attribution link
- Use project-type-specific template if available

**Template**:
```markdown
# {Project Name}

{Description}

> Built with [Agent Context Protocol](https://github.com/prmichaelsen/agent-context-protocol)

## Quick Start

[Add installation and usage instructions]

## Development

This project uses the Agent Context Protocol for development:

- `@acp.init` - Initialize agent context
- `@acp.proceed` - Continue with next task
- `@acp.status` - Check project status

See [AGENT.md](./AGENT.md) for complete documentation.

## License

{License}
```

**Expected Outcome**: README.md created with project metadata

### 6. Create .gitignore

Create appropriate .gitignore for project:

**Actions**:
- Create .gitignore with common patterns:
  - Node.js patterns (if web-app or api)
  - Python patterns (if applicable)
  - IDE patterns (.vscode/, .idea/)
  - OS patterns (.DS_Store, Thumbs.db)
  - Environment files (.env, .env.local)
  - ACP local files (agent/reports/, agent/clarifications/, agent/feedback/)
- Include project-type-specific patterns

**Expected Outcome**: .gitignore created

### 7. Initialize Git Repository

Set up version control:

**Actions**:
- Run: `git init` in project directory
- Run: `git add .`
- Run: `git commit -m "chore: initialize project with ACP"`
- Verify git repository initialized

**Expected Outcome**: Git repository initialized with initial commit

### 8. Create Initial progress.yaml

Create minimal progress.yaml for project:

**Actions**:
- Copy from progress.template.yaml
- Fill in project metadata:
  - name: {project-name}
  - version: 0.1.0
  - started: {current-date}
  - status: in_progress
  - description: {project-description}
- Leave milestones and tasks empty (to be planned later)
- Save to agent/progress.yaml

**Expected Outcome**: progress.yaml created with project metadata

### 9. Display Success Message

Show comprehensive next steps:

**Output**:
```
✅ Project Created Successfully!

Location: ~/.acp/projects/{project-name}/
Project: {project-name}
Description: {description}
Type: {type}

✓ ACP installed (AGENT.md, agent/ directory)
✓ README.md created
✓ .gitignore created
✓ Git repository initialized
✓ progress.yaml created

Next steps:
1. Navigate to project: cd ~/.acp/projects/{project-name}/
2. Define requirements: Edit agent/design/requirements.md
3. Plan milestones: Use @acp.plan to create milestones and tasks
4. Start development: Use @acp.proceed to begin first task

ACP Commands available:
- @acp.init - Initialize context
- @acp.plan - Plan milestones and tasks
- @acp.proceed - Start working
- @acp.status - Check progress

Happy building! 🚀
```

**Expected Outcome**: User knows project was created and how to proceed

---

## Verification

- [ ] Project directory created in ~/.acp/projects/
- [ ] ACP fully installed (AGENT.md, agent/ directory with all templates)
- [ ] README.md created with project metadata
- [ ] .gitignore created with appropriate patterns
- [ ] Git repository initialized with initial commit
- [ ] progress.yaml created with project metadata
- [ ] All files have correct permissions
- [ ] Directory structure follows ACP conventions
- [ ] Success message displayed with next steps

---

## Files to Create

```
~/.acp/projects/{project-name}/
├── AGENT.md                        # From ACP installation
├── README.md                       # Generated with project metadata
├── .gitignore                      # Project-appropriate patterns
├── .git/                           # Git repository
└── agent/                          # From ACP installation
    ├── commands/
    ├── design/
    ├── milestones/
    ├── patterns/
    ├── tasks/
    ├── scripts/
    └── progress.yaml               # Created with project metadata
```

---

## Implementation Notes

### Command File Location
- Create: `agent/commands/acp.project-create.md`
- No shell script needed (LLM-based, like other entity creation commands)

### Similarities to @acp.package-create
- Collects metadata via chat
- Creates directory in standard location
- Runs acp.install.sh for full ACP installation
- Initializes git repository
- Creates README.md

### Differences from @acp.package-create
- **No package.yaml** (projects aren't packages)
- **No release branch** (not publishing to package registry)
- **No pre-commit hook** (not needed for general projects)
- **Simpler .gitignore** (no package-specific patterns)
- **Different README template** (project-focused, not package-focused)
- **Creates in ~/.acp/projects/** (not ~/.acp/packages/)

### Integration with Global ACP
- Leverages init_global_acp() from Task 29
- Ensures ~/.acp/ exists before creating project
- Can reference global packages if needed

### Project Types and Templates

Support different project types with appropriate templates:
- **web-app**: Node.js/TypeScript web application
- **cli-tool**: Command-line tool
- **library**: Reusable library/package
- **mcp-server**: Model Context Protocol server
- **api**: REST/GraphQL API
- **other**: Generic project

Each type can have:
- Type-specific .gitignore patterns
- Type-specific README sections
- Type-specific initial milestones (optional)

---

## Testing

### Manual Testing
1. Run `@acp.project-create` with various project types
2. Verify all files created correctly
3. Verify git repository initialized
4. Verify ACP commands work in new project
5. Test with existing directory (should prompt)
6. Test with invalid project names (should reject)

### Integration Testing
1. Create project with `@acp.project-create`
2. Navigate to project directory
3. Run `@acp.init` to verify ACP works
4. Run `@acp.plan` to create milestones
5. Verify full workflow functions correctly

---

## Related Tasks

- Task 23: Rewrite @acp.package-create (similar workflow)
- Task 29: Global ACP Auto-Initialization (ensures ~/.acp/ exists)
- Task 25: Global Infrastructure Setup (creates ~/.acp/ structure)

---

## Success Criteria

- [ ] Command creates project in ~/.acp/projects/
- [ ] Full ACP installation in project directory
- [ ] README.md generated with project metadata
- [ ] .gitignore appropriate for project type
- [ ] Git repository initialized with initial commit
- [ ] progress.yaml created with project metadata
- [ ] Command documentation complete
- [ ] All verification items pass
- [ ] User can immediately start using ACP commands in new project

---

**Next Task**: TBD
**Estimated Completion**: 3-4 hours
**Priority**: Medium
**Complexity**: Medium (similar to @acp.package-create but simpler)
