# Agent Context Protocol (ACP)

A documentation-first development methodology that enables AI agents to understand, build, and maintain complex software projects through structured knowledge capture.

> *[Search ACP packages](https://prmichaelsen.github.io/agent-context-protocol/)*
---

## Quick Start

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

**Version Commands**:
- **`@acp.version-check`** - Show current ACP version
- **`@acp.version-check-for-updates`** - Check for updates
- **`@acp.version-update`** - Update ACP to latest version

See [AGENT.md](./AGENT.md) for complete command documentation and methodology.

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
