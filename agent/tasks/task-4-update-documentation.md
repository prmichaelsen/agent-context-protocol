# Task 4: Update Documentation

**Milestone**: [M1 - ACP Commands Infrastructure](../milestones/milestone-1-acp-commands.md)  
**Estimated Time**: 2 hours  
**Dependencies**: Tasks 1, 2, 3  
**Status**: Not Started  

---

## Objective

Update AGENT.md and README.md to document the new ACP Commands system.

---

## Steps

### 1. Update AGENT.md

Add a new section about ACP Commands:

```markdown
## ACP Commands

ACP supports a command system for common workflows. Commands are organized by namespace in `agent/commands/`.

### Core Commands (`acp/` namespace)

Core ACP commands are available in `agent/commands/acp/`. Browse this directory to see available commands, or reference commands using `@acp-{action}` syntax (e.g., `@acp-init`, `@acp-proceed`).

### Creating Custom Commands

To create custom commands for your project:

1. Choose a namespace (e.g., `deploy/`, `test/`, `custom/`)
2. Create directory: `agent/commands/{namespace}/`
3. Copy the command template: `cp agent/commands/command.template.md agent/commands/{namespace}/{command-name}.md`
4. Fill in the template sections with your command details

See [`agent/commands/command.template.md`](agent/commands/command.template.md) for the template.

### Installing Third-Party Commands

Use `@acp-install` to install command packages from git repositories (available in future release).
```

### 2. Update README.md

Add commands to the Quick Start section and examples.

### 3. Update Directory Structure Diagram

Update the directory structure in AGENT.md to include `commands/`:

```
agent/
├── commands/                   # Command system
│   ├── command.template.md
│   └── acp/                    # Core commands
├── design/
├── milestones/
├── patterns/
├── tasks/
└── progress.yaml
```

---

## Verification

- [ ] AGENT.md includes commands section
- [ ] README.md includes command examples
- [ ] Directory structure diagram updated
- [ ] Links to command template work
- [ ] Documentation is clear and concise

---

**Next Task**: None (Milestone 1 complete)  
