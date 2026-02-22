# Command: project-create

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.project-create` has been invoked. Follow the steps below to execute this command.
> Pretend this command was entered with this additional context: "Execute directive `@{namespace}-{command-name} NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."

**Namespace**: acp
**Version**: 1.0.0
**Created**: 2026-02-22
**Last Updated**: 2026-02-22
**Status**: Active

---

**Purpose**: Create a new generic ACP project (not a package) with full ACP installation and guided setup
**Category**: Creation
**Frequency**: Once per project

---

## What This Command Does

This command creates a new **generic ACP project** (not a package) with full ACP installation, project metadata, and git initialization. It's designed for creating applications, tools, or experiments that use ACP for development but aren't meant to be published as ACP packages.

**Key Features**:
- Creates projects in `~/.acp/projects/` (or custom location)
- Installs full ACP (all templates, commands, scripts)
- Creates project-focused README.md
- Initializes git repository
- Creates progress.yaml with project metadata
- **No package.yaml** (not a package)
- **No release branches** (not for distribution)
- **No pre-commit hooks** (no package.yaml to validate)
- **Uses `local` namespace** (not configurable)

**Use this when**: Starting a new application, tool, or experiment that will use ACP for development.

### Comparison with @acp.package-create

| Feature | @acp.package-create | @acp.project-create |
|---------|---------------------|---------------------|
| **Purpose** | Create distributable ACP packages | Create generic ACP projects |
| **Creates package.yaml** | ✅ Yes | ❌ No |
| **Release branch config** | ✅ Yes | ❌ No |
| **Pre-commit hooks** | ✅ Yes | ❌ No |
| **Namespace** | Configurable (from package.yaml) | Always `local` |
| **README template** | Package-focused | Project-focused |
| **Use case** | Sharing patterns/commands | Building apps/tools |

---

## Prerequisites

- [ ] ACP installed in current directory (to access this command)
- [ ] Git installed on system
- [ ] Understanding of what you want to build

---

## Steps

### 1. Collect Project Information

Gather project metadata via chat:

**Required Information**:
- **Project name** (kebab-case, will be directory name)
  - Ask: "What would you like to name your project? (lowercase, hyphens allowed)"
  - Example: "my-awesome-app", "task-manager", "ai-assistant"
  - Validation: lowercase, alphanumeric, hyphens only
  
- **Project description** (one-line summary)
  - Ask: "Provide a one-line description of your project:"
  - Example: "A task management application with AI assistance"
  - Validation: Clear and concise

**Optional Information**:
- **Project type** (for context and README template)
  - Ask: "What type of project is this? (web-app, cli-tool, library, mcp-server, api, other)"
  - Default: "other" if not specified
  - Used for: README template selection, .gitignore patterns
  
- **Author name** (for documentation)
  - Ask: "What is your name (project author)? (optional, press Enter to skip)"
  - Example: "Patrick Michaelsen"
  
- **License** (default: MIT)
  - Ask: "What license would you like to use? (default: MIT)"
  - Common options: MIT, Apache-2.0, GPL-3.0, BSD-3-Clause
  - Default: MIT if not specified

- **Target directory** (default: ~/.acp/projects/{project-name})
  - Ask: "Where would you like to create the project? (default: ~/.acp/projects/{project-name})"
  - Supports: `~` expansion, `$HOME` expansion, relative paths, absolute paths
  - Default: `~/.acp/projects/{project-name}` if not specified

**Expected Outcome**: All project metadata collected

### 2. Validate and Confirm

Show collected information and ask for confirmation:

**Actions**:
- Display summary of collected information
- Ask: "Does this look correct? (yes/no)"
- If no: Allow user to correct information
- If yes: Proceed to creation

**Expected Outcome**: User confirms project details

### 3. Determine Target Directory

Calculate and validate target directory path:

**Actions**:
- Expand `~` to `$HOME` if present
- Expand `$HOME` to actual home directory
- Resolve relative paths from current directory
- Check if directory already exists
- If exists: Ask user to choose different name or confirm overwrite

**Expected Outcome**: Target directory path determined and validated

### 4. Create Project Directory

Create the project directory:

**Actions**:
- Execute: `mkdir -p {target-directory}`
- Verify directory created successfully
- Report directory location

**Expected Outcome**: Empty project directory exists

### 5. Install ACP

Run ACP installation in the new project directory:

**Actions**:
- Get path to current ACP installation: `./agent/scripts/acp.install.sh`
- Execute installation in new directory:
  ```bash
  cd {target-directory} && {path-to-acp}/agent/scripts/acp.install.sh
  ```
- Verify AGENT.md created
- Verify agent/ directory created with all subdirectories
- Verify all templates installed
- Verify all commands installed
- Verify all scripts installed

**Expected Outcome**: Full ACP installation in project directory

### 6. Create Project README.md

Generate project-focused README with metadata:

**Actions**:
- Create README.md in project directory
- Fill in project name, description, type
- Include ACP attribution link
- Add development section with ACP commands
- Add license section
- Use project-type-specific template if available

**Template**:
```markdown
# {Project Name}

{Description}

> Built with [Agent Context Protocol](https://github.com/prmichaelsen/agent-context-protocol)

## Quick Start

[Add installation and usage instructions here]

## Features

- Feature 1
- Feature 2
- Feature 3

## Development

This project uses the Agent Context Protocol for development:

- `@acp.init` - Initialize agent context
- `@acp.plan` - Plan milestones and tasks
- `@acp.proceed` - Continue with next task
- `@acp.status` - Check project status

See [AGENT.md](./AGENT.md) for complete ACP documentation.

## Project Structure

```
project-root/
├── AGENT.md              # ACP methodology
├── agent/                # ACP directory
│   ├── design/          # Design documents
│   ├── milestones/      # Project milestones
│   ├── tasks/           # Task breakdown
│   ├── patterns/        # Architectural patterns
│   └── progress.yaml    # Progress tracking
└── (your project files)
```

## Getting Started

1. Initialize context: `@acp.init`
2. Plan your project: `@acp.plan`
3. Start building: `@acp.proceed`

## License

{License}

## Author

{Author}
```

**Expected Outcome**: README.md created with project metadata

### 7. Create .gitignore

Create appropriate .gitignore for project type:

**Actions**:
- Create .gitignore in project directory
- Add common patterns:
  - IDE patterns (.vscode/, .idea/, *.swp)
  - OS patterns (.DS_Store, Thumbs.db, desktop.ini)
  - Environment files (.env, .env.local, .env.*.local)
  - ACP local files (agent/reports/, agent/clarifications/, agent/feedback/)
- Add project-type-specific patterns:
  - **web-app/api**: node_modules/, dist/, build/, .next/, .nuxt/
  - **cli-tool**: node_modules/, dist/, bin/
  - **library**: node_modules/, dist/, lib/
  - **mcp-server**: node_modules/, dist/, build/
  - **other**: node_modules/, dist/

**Template**:
```gitignore
# Dependencies
node_modules/
.pnp
.pnp.js

# Build output
dist/
build/
out/
.next/
.nuxt/

# Environment files
.env
.env.local
.env.*.local

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db
desktop.ini

# ACP local files (not committed)
agent/reports/
agent/clarifications/
agent/feedback/
agent/drafts/

# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Testing
coverage/
.nyc_output/

# Misc
.cache/
.temp/
.tmp/
```

**Expected Outcome**: .gitignore created with appropriate patterns

### 8. Initialize Git Repository

Set up version control:

**Actions**:
- Execute in project directory: `git init`
- Execute: `git add .`
- Execute: `git commit -m "chore: initialize project with ACP"`
- Verify git repository initialized
- Verify initial commit created

**Expected Outcome**: Git repository initialized with initial commit

### 9. Create Initial progress.yaml

Create minimal progress.yaml for project:

**Actions**:
- Read `agent/progress.template.yaml` from project
- Create `agent/progress.yaml` with:
  ```yaml
  project:
    name: {project-name}
    version: 0.1.0
    started: {current-date}
    status: in_progress
    description: |
      {project-description}
  
  milestones: []
  
  tasks: {}
  
  documentation:
    design_documents: 0
    milestone_documents: 0
    pattern_documents: 0
    task_documents: 0
  
  progress:
    planning: 0
    implementation: 0
    overall: 0
  
  recent_work: []
  
  next_steps:
    - Define project requirements in agent/design/requirements.md
    - Plan milestones and tasks with @acp.plan
    - Start development with @acp.proceed
  
  notes: []
  
  current_blockers: []
  ```
- Save to `agent/progress.yaml`

**Expected Outcome**: progress.yaml created with project metadata

### 10. Display Success Message

Show comprehensive next steps:

**Output**:
```
✅ Project Created Successfully!

Location: {target-directory}
Project: {project-name}
Description: {description}
Type: {type}
License: {license}

✓ ACP installed (AGENT.md, agent/ directory)
✓ README.md created
✓ .gitignore created
✓ Git repository initialized
✓ progress.yaml created

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Next Steps:

1. Navigate to project:
   cd {target-directory}

2. Define requirements:
   Edit agent/design/requirements.md with your project goals

3. Plan your project:
   @acp.plan
   
   This will help you:
   - Create milestones
   - Break down into tasks
   - Define deliverables

4. Start development:
   @acp.proceed
   
   This will begin implementing your first task

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📚 ACP Commands Available:

Workflow:
- @acp.init - Initialize agent context
- @acp.proceed - Continue with next task
- @acp.status - Check project status
- @acp.plan - Plan milestones and tasks

Documentation:
- @acp.sync - Sync documentation with code
- @acp.validate - Validate ACP structure
- @acp.report - Generate session report

See AGENT.md for complete command documentation.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Happy building! 🚀
```

**Expected Outcome**: User knows project was created and how to proceed

---

## Verification

- [ ] Project directory created at specified location
- [ ] ACP fully installed (AGENT.md, agent/ directory with all files)
- [ ] All templates available (design, milestone, pattern, task, command)
- [ ] All ACP commands available (acp.init.md, acp.proceed.md, etc.)
- [ ] All ACP scripts available (acp.common.sh, acp.install.sh, etc.)
- [ ] README.md created with project metadata
- [ ] .gitignore created with appropriate patterns
- [ ] Git repository initialized
- [ ] Initial commit created
- [ ] progress.yaml created with project metadata
- [ ] Success message displayed with next steps
- [ ] User can navigate to project and use ACP commands

---

## Expected Output

### Files Created

```
{target-directory}/
├── AGENT.md                        # ACP documentation
├── README.md                       # Project documentation
├── .gitignore                      # Git exclusions
├── .git/                           # Git repository
└── agent/                          # ACP directory
    ├── .gitignore                  # Agent-specific exclusions
    ├── progress.yaml               # Progress tracking (initialized)
    ├── progress.template.yaml      # Template
    ├── manifest.template.yaml      # Template
    ├── commands/
    │   ├── command.template.md
    │   ├── acp.init.md
    │   ├── acp.proceed.md
    │   └── ... (all ACP commands)
    ├── design/
    │   ├── .gitkeep
    │   ├── requirements.template.md
    │   └── design.template.md
    ├── milestones/
    │   ├── .gitkeep
    │   └── milestone-1-{title}.template.md
    ├── patterns/
    │   ├── .gitkeep
    │   ├── bootstrap.template.md
    │   └── pattern.template.md
    ├── tasks/
    │   ├── .gitkeep
    │   └── task-1-{title}.template.md
    ├── scripts/
    │   ├── acp.common.sh
    │   ├── acp.install.sh
    │   └── ... (all ACP scripts)
    └── schemas/
        └── package.schema.yaml
```

---

## Examples

### Example 1: Creating Web Application

**Context**: Want to build a web app with ACP

**Invocation**: `@acp.project-create`

**Interaction**:
```
Agent: Let's create a new ACP project! I'll need some information.

Agent: What would you like to name your project? (lowercase, hyphens allowed)
User: task-manager-app

Agent: ✓ Valid project name

Agent: Provide a one-line description of your project:
User: A task management application with AI assistance

Agent: ✓

Agent: What type of project is this? (web-app, cli-tool, library, mcp-server, api, other)
User: web-app

Agent: ✓

Agent: What is your name (project author)? (optional, press Enter to skip)
User: Patrick Michaelsen

Agent: ✓

Agent: What license would you like to use? (default: MIT)
User: [Enter]

Agent: Using MIT license ✓

Agent: Where would you like to create the project? (default: ~/.acp/projects/task-manager-app)
User: [Enter]

Agent: Using ~/.acp/projects/task-manager-app ✓

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Summary:
  Project name: task-manager-app
  Description: A task management application with AI assistance
  Type: web-app
  Author: Patrick Michaelsen
  License: MIT
  Location: ~/.acp/projects/task-manager-app

Agent: Does this look correct? (yes/no)
User: yes

Agent: Creating project...

✓ Created directory: ~/.acp/projects/task-manager-app/
✓ Installing ACP...
✓ Created README.md
✓ Created .gitignore
✓ Initialized git repository
✓ Created progress.yaml

✅ Project Created Successfully!

[Next steps displayed...]
```

### Example 2: Creating MCP Server

**Context**: Want to build an MCP server

**Invocation**: `@acp.project-create`

**Interaction**:
```
Project name: my-mcp-server
Description: Custom MCP server for data integration
Type: mcp-server
Author: [Enter]
License: [Enter]
Location: [Enter]

✅ Project Created Successfully!
Location: ~/.acp/projects/my-mcp-server/
```

### Example 3: Creating in Custom Location

**Context**: Want to create project in specific directory

**Invocation**: `@acp.project-create`

**Interaction**:
```
Project name: experiment
Description: Experimental project for testing ideas
Type: other
Author: [Enter]
License: [Enter]
Location: ~/dev/experiments/experiment

✅ Project Created Successfully!
Location: ~/dev/experiments/experiment/
```

---

## Related Commands

- [`@acp.package-create`](acp.package-create.md) - Create distributable ACP packages
- [`@acp.init`](acp.init.md) - Initialize context in created project
- [`@acp.plan`](acp.plan.md) - Plan milestones and tasks
- [`@git.init`](git.init.md) - Initialize git repository

---

## Troubleshooting

### Issue 1: Directory already exists

**Symptom**: Error "Directory already exists"

**Solution**: Choose a different project name, or remove existing directory, or confirm overwrite

### Issue 2: Permission denied

**Symptom**: Error creating directory

**Solution**: Check permissions for target location, or choose different location

### Issue 3: ACP installation failed

**Symptom**: Error during ACP installation

**Solution**: Verify you're in an ACP-installed directory, check internet connection, verify acp.install.sh exists

### Issue 4: Git not installed

**Symptom**: Error "git: command not found"

**Solution**: Install git from https://git-scm.com/downloads

---

## Security Considerations

### File Access
- **Reads**: None (creates new files)
- **Writes**: Creates entire project directory structure
- **Executes**: `acp.install.sh`, `git init`, `git add`, `git commit`

### Network Access
- **APIs**: None
- **Repositories**: May clone ACP repository during installation

### Sensitive Data
- **Secrets**: Never include secrets in project files
- **Credentials**: Never commit credentials to git

---

## Notes

- Project name becomes directory name
- Projects always use `local` namespace (not configurable)
- No package.yaml created (projects aren't packages)
- No release branch configuration (not for distribution)
- No pre-commit hooks (no package.yaml to validate)
- README is project-focused (usage, development, deployment)
- Use `@acp.package-create` if you want to create a distributable package
- Projects can be created anywhere, not just ~/.acp/projects/
- Full ACP installation means all commands and templates are available
- progress.yaml starts empty (plan milestones with @acp.plan)

---

**Namespace**: acp
**Command**: project-create
**Version**: 1.0.0
**Created**: 2026-02-22
**Last Updated**: 2026-02-22
**Status**: Active
**Compatibility**: ACP 3.9.0+
**Author**: ACP Project
