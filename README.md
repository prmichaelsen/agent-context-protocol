# What is Agent Context Protocol (ACP)
ACP is an agent harness. It centers around markdown command files located in a project-level
or user-level `agent/commands` directory that agents treat as
directives. When an agent reads a command file, it enters "script execution mode".
In this mode, the agent will follow all steps and directives in that file the same way a standard scripting language might work. Commands support if statements,
branching, loops, subroutines, invoking external programs, arguments, and verification steps.
The second flagship feature is pattern documents to enforce best practices. Patterns are distributed via publishable,
consumable, and portable ACP patterns packages.

> **ACP Formal Definition**: documentation-first development methodology that enables AI agents to understand, build, and maintain complex software projects through structured knowledge capture.

If it's still unclear to you what ACP is or does or why it exists,
please read the section below. It's easier to show you common ACP
workflows and usecases than it is to try and explain ACP in abstract terms.

## Primary ACP workflow

### Generate and implement milestone from feature concept
ACP's primary workflow centers around generating markdown artifacts
complete enough for your agent to autonomously implement an 
entire milestone with no guidance in a single
continuous session. Milestones often contain anywhere from
three to twelve tasks. ACP faithfully and autonomously executes
milestones and tasks effectively even at the higher bound.
Below is a typical ACP workflow from concept to feature 
complete.

#### Define draft
Start by creating a file such as `agent/drafts/my-feature.draft.md`.

Drafts are free-form, but you may consider providing
any or none of following items:
- Feature concept
- Goal
- Pain point
- Problem statement
- Proposed solution
- Requirements

Instead of creating a draft, you may also discuss your feature interactively via chat.

#### Clarification
Once you have completed your draft, invoke `@acp.clarification-create` and your
agent will generate a comprehensive clarifications document which focuses on:
- Gaps in your requirements or proposed solution
- Ambiguous requirements
- Open questions
- Poorly defined specs

Respond to the agent's questions in part or in whole by providing your
input on the lines marked `>`. Your responses can include directives,
such as:
- Explore the codebase to answer this question yourself
- Research this using the web
- Read `agent/design/existing-relevant-design.md`
- Clarify your question
- Provide tradeoffs
- Propose alternate solutions
- Provide a recommendation
- Analyze this approach
- Use MCP tool `tool_name`

> Tip: If an answer you provided would have cascading effects
> on all subsequent questions, for instance, your response
> would make subsequent questions null and void,
> respond with "This decision has cascading effects on the
> rest of your questions".

Once you are satisfied with your partial or complete responses,
invoke `@acp.clarification-address`. This instructs the agent
to process your responses, execute any directives, and consider
any cascading effects of decisions. Once your agent completes your directives,
it rewrites the clarifications document, inserting its analysis,
recommendations, tradeoffs and other perspectives into the document
in `<!-- comment blocks -->` to provide visual emphasis on the portions
of the document it addressed or updated.

Proof the agent responses in the document and provide follow up
responses if necessary. It is recommended to iterate on your
clarifications doc via several chained `@acp.clarification-address`
invocations until all gaps and open questions are addressed
with concrete decisions. 

Simple features with low impact may require a single pass while
larger architectural features with high impact on your system would
benefit from many passes. It's not uncommon to make up to 
ten passes on features such as this. This part of the workflow
is key to the effectiveness of the rest of the ACP workflow.

It is recommended to spend the most time on clarifications and
to use as many passes as necessary to generate a bullet proof
mutual understanding of your feature specification. Gaps in your
specification will lead to subpar, unexpected and undesirable results.

The more gaps you leave in your clarification, the more likely
your agent will make implementation decisions you would not make yourself and
you will spend more time directing your agent to rewrite features
than you would have spent simply iterating on your clarifications 
document.

#### Design
If you took the time to generate a bullet proof clarifications document,
this step is essentially a noop. Invoke `@acp.design-create --from clar`.
This command invokes the subroutine `@acp.clarification-capture` in addition
to its primary routine. `@acp.clarification-capture` ensures every decision
made in your clarification document is captured in a key decisions appendix.
Clarifications are designed to be ephemeral which means your design is the
ultimate source of truth for your feature. Review the design carefully
and optionally iterate on it using chat. 

#### Planning
Once you are satisfied with the design, invoke `@acp.plan`. 
Your agent will propose a milestone and task breakdown.
Once you approve the proposal, the agent will generate planning
artifacts autonomously in one pass.

#### Proof the planning artifacts
Reviewing the planning artifacts is the second most important
part of the ACP workflow after clarifications. It is recommended
to thoroughly read and evaluate all planning documents meticulously.

Each planning artifact describes the specific changes the agent
will make and should be completely self contained. 

Planning artifacts are complete enough
that the agent does not need to read other documents in order to implement them.

However, they do include references to relevant design documents and patterns.
Your agent will do exactly what the planning artifacts instruct the agent to do.
If your planning artifacts do not match your expectations, you must iterate
on them or your agent will produce garbage. Therefore it is critical
to interrogate the planning artifacts rigorously.

You may consider using the [ACP visualizer](https://github.com/prmichaelsen/acp-visualizer)
to review your planning artifacts by running `npx @prmichaelsen/acp-visualizer`
in your project directory. This launches a web portal that ingests your
`progress.yaml` and generates a project status dashboard. The dashboard includes
milestone tree views, a kanban board, and dependency graphs. You can preview
milestones and tasks in a side panel or drill into them directly.

> **Why write planning documents?** Planning documents are essential to
> ACP's two primary value propositions: **a)** solving the agent context problem and
> **b)** maintaining context on long-lived, large scope projects.
> Because planning documents are self contained, your agent can refresh
> context on a task easily after context is condensed. Planning artifacts
> generate auditable and historical artifacts that inform how features were
> implemented and why they were implemented. They capture the entire history
> of your project and stay in sync with `progress.yaml`. They enable your
> agent to understand the entire lifecycle of your project as the scope
> of your project inevitably grows.

#### Fully autonomous implementation
The final and easiest step in the ACP workflow is invoking 
`@acp.proceed` to actually implement your feature.

If you are confident in your planning, run 
`@acp.proceed --yolo`, and the agent will
implement your entire milestone from start to finish,
committing each task along the way, with no input from
you. 

The agent will:
- Capture each milestone and task start timestamps in `progress.yaml`
- Use sub-agents as necessary (use `--noworktrees` if you do not want to use subagents)
- Run task completion verification steps, including tests or E2E tests
- Make atomic git commits after each task completion
- Update `progress.yaml` and capture completion timestamps
- Track metadata such as implementation notes

While it runs:
- Generate other planning docs for other features
- Play with dog at dog park (if vibecoding remotely)

#### Key Takeaways
- Crystal clear picture before 4-hour agent runs
- Task files create audit trails and reusable SOP
- Manual review gates prevent scope creep
- Use autonmous execution only after thorough planning

## How commands work
Each command file has a very heavy handed, hardened prompt directive at the top of each
command file that essentially hijacks your agent.

> **🤖 Agent Directive**: If you are reading this file, the command `@acp-index` has been invoked. Follow the steps below to execute this command.
> Pretend this command was entered with this additional context: "Execute directive `@acp-index` NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."

In general, all agents respect this directive, however, Claude is the only agent I've tested ACP
with that never fails to enter execution mode on the first command read (which is just one of the
many reasons I recommend Claude over any other agent provider).

---

## Useful References

> *[Search ACP packages](https://prmichaelsen.github.io/agent-context-protocol/)*  

> *[Visualize your project](https://github.com/prmichaelsen/agent-context-protocol-visualizer)*   - `yes | npx @prmichaelsen/acp-visualizer` 

> *[CLI visualizer](https://github.com/prmichaelsen/acp-visualizer-tui)* - `npx acp-visualizer-tui` 

> *[Project dashboard](https://viz.agentcontextprotocol.net/?repo=prmichaelsen%2Fagent-context-protocol)*

> *[Claude Code](https://code.claude.com/docs/en/overview) is ACP's preferred coding agent provider, however any provider will work out of the box.*
---

## Quick Start

### Requirements

- **OS**: Linux or macOS
- **Shell**: Bash 4+ (`bash --version` to check)
- **Git**: 2.x+

> macOS note: The default `/bin/bash` on macOS is 3.2. Homebrew's bash (`/opt/homebrew/bin/bash` or `/usr/local/bin/bash`) is typically 5.x and works out of the box.

### Bootstrap a New Project

```bash
curl -fsSL https://raw.githubusercontent.com/prmichaelsen/agent-context-protocol/mainline/agent/scripts/acp.install.sh | bash
```

### Update an Existing Project

You can update an existing project via `@acp.version-update` command or by running the update script directly:

```bash
curl -fsSL https://raw.githubusercontent.com/prmichaelsen/agent-context-protocol/mainline/agent/scripts/acp.version-update.sh | bash
```

Or if you have ACP already installed locally:

```bash
./agent/scripts/acp.version-update.sh
```

---

## Visualize Your Project

See your milestones, tasks, and progress in a live dashboard:

```bash
npx @prmichaelsen/acp-visualizer
```

Runs a local dashboard that reads your `agent/progress.yaml` and renders it as an interactive admin panel with table/tree views, search, filtering, and auto-refresh.

```bash
# Run from any ACP project directory
cd my-project
npx @prmichaelsen/acp-visualizer

# Or point at a specific file
npx @prmichaelsen/acp-visualizer /path/to/agent/progress.yaml

# Custom port
npx @prmichaelsen/acp-visualizer --port 4000
```

**Features**: Sortable milestone table, expandable tree view, fuse.js fuzzy search, status filtering, SSE auto-refresh (updates live as agents work), lenient YAML parsing that handles agent-maintained drift.

---

## What is ACP?

The **Agent Context Protocol** is a standardized directory structure and documentation pattern that transforms implicit project knowledge into explicit, machine-readable documentation. It provides:

- **Design Documents** - Architectural decisions and technical specifications
- **Milestones** - Project phases with clear deliverables
- **Tasks** - Granular, actionable work items
- **Patterns** - Reusable architectural and coding patterns
- **Progress Tracking** - YAML-based progress monitoring

This enables AI agents to pick up where previous agents left off, preserving all context and decisions across sessions.

---

This will create:
- `AGENT.md` - Complete ACP methodology documentation
- `agent/` directory with all template files
- `agent/scripts/` directory with update utilities

---

## Usage

Once ACP is installed, use these commands with your AI agent:

### Start Working on a Project

Type: **`@acp.init`** (or `AGENT.md: Initialize`)

This will:
- Check for ACP updates
- Read all agent documentation
- Review source code
- Update stale documentation
- Prepare to work on tasks

### Continue Working

Type: **`@acp.proceed`** (or `AGENT.md: Proceed`)

This will:
- Continue with current or next task
- Update progress tracking
- Maintain documentation

### Resume a Previous Session

Type: **`@acp.resume`** ⭐ Recommended

This convenient command automatically:
- Initializes context (`@acp.init`)
- Reviews latest session report
- Continues with next task (`@acp.proceed`)

Perfect for starting new sessions or returning after breaks.

### Check Project Status

Type: **`@acp.status`**

This will:
- Display current milestone and progress
- Show current task
- List recent work and next steps

### Available Commands

**Workflow Commands**:
- **`@acp.resume`** ⭐ - Resume work (init + report + proceed)
- **`@acp.init`** - Initialize agent context
- **`@acp.proceed`** - Continue with next task
- **`@acp.status`** - Display project status
- **`@acp.sync`** - Sync documentation with code
- **`@acp.validate`** - Validate ACP structure
- **`@acp.report`** - Generate session report
- **`@acp.index`** - Manage the key file index (list, add, remove, explore, show)

**Package Management**:
- **`@acp.package-install`** - Install packages (supports `--global` flag)
- **`@acp.package-list`** - List installed packages (supports `--global` flag)
- **`@acp.package-info`** - Show package details (supports `--global` flag)
- **`@acp.package-update`** - Update packages (supports `--global` flag)
- **`@acp.package-remove`** - Remove packages (supports `--global` flag)
- **`@acp.package-search`** - Search for packages
- **`@acp.package-validate`** - Validate package structure
- **`@acp.package-publish`** - Publish package
- **`@acp.package-create`** - Create new package

**Entity Creation**:
- **`@acp.command-create`** - Create command files
- **`@acp.pattern-create`** - Create pattern files
- **`@acp.design-create`** - Create design documents
- **`@acp.task-create`** - Create task files
- **`@acp.spec`** - Generate spec from clarification, design, draft, requirements, or interactive

**Version Commands**:
- **`@acp.version-check`** - Show current ACP version
- **`@acp.version-check-for-updates`** - Check for updates
- **`@acp.version-update`** - Update ACP to latest version

**Project Registry**:
- **`@acp.project-list`** - List registered projects
- **`@acp.project-set`** - Switch to a project
- **`@acp.project-info`** - Show project details
- **`@acp.project-update`** - Update project metadata
- **`@acp.project-remove`** - Remove project from registry
- **`@acp.projects-sync`** - Discover unregistered projects

**Sessions** (Experimental):
- **`@acp.sessions`** - Manage and view active agent sessions across projects

**Git Commands**:
- **`@git.commit`** - Intelligent version-aware commits
- **`@git.init`** - Initialize git repository

See [AGENT.md](./AGENT.md) for complete command documentation and methodology.

---

## Global Package Installation

Install packages globally to `~/.acp/agent/` for package development or global command libraries:

```bash
# Install package globally
./agent/scripts/acp.package-install.sh --global https://github.com/user/acp-firebase.git

# Or via command
@acp.package-install --global https://github.com/user/acp-firebase.git

# List global packages
@acp.package-list --global

# Update global packages
@acp.package-update --global firebase

# Remove global packages
@acp.package-remove --global firebase
```

**Global vs Local**:
- **Global**: Installed to `~/.acp/agent/`, available for discovery in any project
- **Local**: Installed to `./agent/`, only available in current project
- **Precedence**: Local packages always override global packages

**Use cases for global installation**:
- Package development with full ACP tooling
- Common utilities used across many projects
- Building a personal command library
- Experimenting with packages before local installation

---

## Experimental Features

Install packages with experimental features:

```bash
# Install only stable features (default)
@acp.package-install --repo https://github.com/user/acp-firebase.git

# Install including experimental features
@acp.package-install --repo https://github.com/user/acp-firebase.git --experimental
```

**What are experimental features?**
- Bleeding-edge features that may change
- Require explicit opt-in via --experimental flag
- Once installed, update normally

See [AGENT.md](./AGENT.md#experimental-features) for complete documentation.

---

## Key File Index

ACP includes a weighted key file index (`agent/index/`) that ensures agents read critical project files before making decisions. Each entry declares a file path, priority weight, and which commands should read it.

```bash
# Manage the key file index
@acp.index list              # List all indexed key files
@acp.index add <path>        # Add a file to the index
@acp.index remove <path>     # Remove a file from the index
```

Packages can ship their own index files (`contents.indices` in package.yaml), which are automatically installed to `agent/index/` and discovered by commands.

See [AGENT.md](./AGENT.md#key-file-index) for complete documentation.

---

## Benchmark Suite

ACP includes an automated benchmark system that measures the impact of ACP on AI-driven development. It runs identical tasks with and without ACP, comparing metrics like token usage, code quality, and task completion.

```bash
# Run all benchmarks
bash agent/benchmarks/runner/run-benchmark.sh

# Run a specific task
bash agent/benchmarks/runner/run-benchmark.sh --task complex-auth-system

# View HTML reports
bash agent/benchmarks/runner/serve-reports.sh
```

**6 benchmark tasks** ranging from simple (hello-world) to complex (order pipeline with event-driven refactor). Each task includes automated verification and LLM-based quality evaluation.

See [AGENT.md](./AGENT.md#benchmark-suite) for complete documentation. On-demand CI via GitHub Actions (`workflow_dispatch`).

---

## Project Registry

Manage multiple ACP projects with the global project registry at `~/.acp/projects.yaml`:

```bash
# List all registered projects
@acp.project-list

# Switch to a specific project
@acp.project-set my-project

# View current project details
@acp.project-info

# Update project metadata (tags, status, description)
@acp.project-update --tags "typescript,api" --status in_progress

# Discover unregistered projects in ~/.acp/projects/
@acp.projects-sync

# Remove project from registry (keeps files)
@acp.project-remove old-project
```

**Key Features**:
- **Project Discovery**: List and filter projects by type, status, or tags
- **Context Switching**: Quickly switch between projects
- **Metadata Tracking**: Track type, status, tags, and relationships
- **Auto-Registration**: Projects auto-register when created via `@acp.project-create`

See [AGENT.md](./AGENT.md#project-registry-system) for complete documentation.

---

## Examples

### Sample ACP Projects

See these repositories for real-world examples of ACP in action:

- **[remember-mcp-server](https://github.com/prmichaelsen/remember-mcp-server)** - Multi-tenant memory system with vector search
- **[remember-mcp](https://github.com/prmichaelsen/remember-mcp)** - Memory management MCP implementation
- **[agentbase-mcp-server](https://github.com/prmichaelsen/agentbase-mcp-server)** - Agent base server implementation
- **[agentbase-mcp](https://github.com/prmichaelsen/agentbase-mcp)** - Agent base MCP tools
- **[google-calendar-mcp](https://github.com/prmichaelsen/google-calendar-mcp)** - Google Calendar integration MCP server
- **[mcp-auth](https://github.com/prmichaelsen/mcp-auth)** - Authentication framework for MCP servers

---

## Directory Structure

```
project-root/
├── AGENT.md                        # ACP documentation (this pattern)
├── agent/                          # Agent directory
│   ├── commands/                   # Command system
│   │   ├── .gitkeep
│   │   ├── command.template.md     # Command template
│   │   ├── acp.init.md             # @acp.init
│   │   ├── acp.proceed.md          # @acp.proceed
│   │   ├── acp.status.md           # @acp.status
│   │   └── ...                     # More commands
│   │
│   ├── design/                     # Design documents
│   │   ├── .gitkeep
│   │   ├── design.template.md      # Template for design docs
│   │   └── requirements.md         # Your project requirements
│   │
│   ├── milestones/                 # Project milestones
│   │   ├── .gitkeep
│   │   ├── milestone-1-{title}.template.md
│   │   └── milestone-1-foundation.md
│   │
│   ├── patterns/                   # Architectural patterns
│   │   ├── .gitkeep
│   │   ├── pattern.template.md
│   │   ├── bootstrap.template.md
│   │   └── typescript/             # Language-specific patterns
│   │       └── *.md
│   │
│   ├── tasks/                      # Granular tasks
│   │   ├── .gitkeep
│   │   ├── task-1-{title}.template.md
│   │   └── task-1-setup.md
│   │
│   ├── index/                      # Key file index
│   │   ├── local.main.yaml         # Project's key files
│   │   └── {pkg}.main.yaml         # Package-shipped indices
│   │
│   └── progress.yaml               # Progress tracking
│
└── (your project files)
```

---

## Template Files

ACP provides template files for each document type:

- **`design.template.md`** - Template for design documents
- **`milestone-1-{title}.template.md`** - Template for milestone documents
- **`task-1-{title}.template.md`** - Template for task documents
- **`pattern.template.md`** - Template for pattern documents
- **`bootstrap.template.md`** - Template for project bootstrap patterns
- **`progress.template.yaml`** - Template for progress tracking

Each template includes:
- Section headers with descriptions
- Example content showing proper usage
- Guidance on what to include
- Best practices and conventions

---

## Key Principles

1. **Documentation is Infrastructure** - Treat it with the same care as code
2. **Explicit Over Implicit** - Document everything that matters
3. **Structure Enables Scale** - Organization makes complexity manageable
4. **Agents Need Context** - Provide complete, accessible context
5. **Progress is Measurable** - Track objectively with YAML
6. **Patterns Ensure Quality** - Document and follow best practices
7. **Knowledge Persists** - No more lost tribal knowledge

---

## When to Use ACP

✅ **Use ACP when:**
- Complex projects (>1 month)
- Multiple contributors (agents or humans)
- Long-term maintenance required
- Quality and consistency critical
- Knowledge preservation important

❌ **Don't use ACP for:**
- Trivial scripts (<100 lines)
- One-off prototypes
- Throwaway code
- Simple, well-understood problems

---

## Documentation

For complete documentation, see [`AGENT.md`](./AGENT.md), which includes:

- Detailed explanation of each component
- Step-by-step usage instructions
- Best practices and conventions
- Problem-solving patterns
- Real-world examples

---

## Contributing

Contributions are welcome! Please:

1. Follow the existing template structure
2. Document your changes in design documents
3. Update relevant patterns
4. Add examples where helpful

---

## License

MIT License - See [LICENSE](./LICENSE) for details

---

## Links

- **Repository**: https://github.com/prmichaelsen/agent-context-protocol
- **Issues**: https://github.com/prmichaelsen/agent-context-protocol/issues
- **Documentation**: See [AGENT.md](./AGENT.md)

---

**The Agent Context Protocol is not just documentation—it's a development methodology that makes complex software projects tractable for AI agents.**
