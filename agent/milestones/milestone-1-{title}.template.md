# Milestone {N}: {Descriptive Name}

**Goal**: [One-line objective that clearly states what this milestone achieves]  
**Duration**: [Estimated time: e.g., "1-2 weeks", "3-5 days"]  
**Dependencies**: [List prerequisite milestones or external dependencies, or "None"]  
**Status**: Not Started | In Progress | Completed  

---

## Overview

[Provide a comprehensive description of what this milestone accomplishes and why it's important to the project. Explain how it fits into the overall project roadmap.]

**Example**: "This milestone establishes the foundational infrastructure for the project, including build system, database connections, and basic server setup. It creates the scaffolding that all future features will build upon."  

---

## Deliverables

[List concrete, measurable outputs this milestone will produce. Be specific about what will exist when this milestone is complete.]

### 1. [Deliverable Category 1]
- Specific item 1
- Specific item 2
- Specific item 3

### 2. [Deliverable Category 2]
- Specific item 1
- Specific item 2

### 3. [Deliverable Category 3]
- Specific item 1
- Specific item 2

**Example**:

### 1. Project Structure
- New `project-name/` directory with organized subdirectories
- package.json with all metadata and scripts
- TypeScript configuration (tsconfig.json)
- Build system using esbuild
- Directory structure: src/, tests/, agent/

### 2. Core Dependencies
- @modelcontextprotocol/sdk installed and configured
- Database client libraries installed
- Development tools (TypeScript, testing framework)

---

## Success Criteria

[Define objective, verifiable criteria that indicate this milestone is complete. Each criterion should be testable.]

- [ ] Criterion 1: [Specific, measurable condition]
- [ ] Criterion 2: [Specific, measurable condition]
- [ ] Criterion 3: [Specific, measurable condition]
- [ ] Criterion 4: [Specific, measurable condition]
- [ ] Criterion 5: [Specific, measurable condition]

**Example**:
- [ ] Project builds successfully (`npm run build` completes without errors)
- [ ] TypeScript compiles without errors (`npm run typecheck` passes)
- [ ] All dependencies install correctly (`npm install` succeeds)
- [ ] Basic server starts and responds to health check
- [ ] All tests pass (`npm test` succeeds)

---

## Key Files to Create

[List the specific files and directories that will be created during this milestone. Use a tree structure for clarity.]

```
project-root/
├── file1.ext
├── file2.ext
├── directory1/
│   ├── file3.ext
│   └── file4.ext
└── directory2/
    ├── subdirectory/
    │   └── file5.ext
    └── file6.ext
```

**Example**:
```
my-project/
├── package.json
├── tsconfig.json
├── esbuild.build.js
├── .gitignore
├── .env.example
├── README.md
├── src/
│   ├── index.ts
│   ├── server.ts
│   ├── types/
│   │   └── index.ts
│   └── utils/
│       └── logger.ts
└── tests/
    └── setup.test.ts
```

---

## Tasks

[List the tasks that comprise this milestone. Reference task documents if they exist.]

1. [Task 1: task-N-{name}.md](../tasks/task-N-{name}.md) - [Brief description]
2. [Task 2: task-N-{name}.md](../tasks/task-N-{name}.md) - [Brief description]
3. [Task 3: task-N-{name}.md](../tasks/task-N-{name}.md) - [Brief description]
4. [Task 4: task-N-{name}.md](../tasks/task-N-{name}.md) - [Brief description]

**Example**:
1. [Task 1: Initialize Project Structure](../tasks/task-1-initialize-project-structure.md) - Set up directories and config files
2. [Task 2: Install Dependencies](../tasks/task-2-install-dependencies.md) - Install and configure npm packages
3. [Task 3: Create Basic Server](../tasks/task-3-create-basic-server.md) - Implement minimal MCP server

---

## Environment Variables

[If this milestone requires environment configuration, document it here:]

```env
# Category 1
VAR_NAME_1=example_value
VAR_NAME_2=example_value

# Category 2
VAR_NAME_3=example_value
VAR_NAME_4=example_value
```

**Example**:
```env
# Database Configuration
DATABASE_URL=postgresql://localhost:5432/mydb
DATABASE_POOL_SIZE=10

# API Configuration
API_KEY=your_api_key_here
API_URL=https://api.example.com

# Server Configuration
PORT=3000
NODE_ENV=development
```

---

## Testing Requirements

[Describe what testing should be in place by the end of this milestone:]

- [ ] Test category 1: [Description]
- [ ] Test category 2: [Description]
- [ ] Test category 3: [Description]

**Example**:
- [ ] Unit tests for core utilities
- [ ] Integration test for database connection
- [ ] Server initialization test
- [ ] Environment variable loading test

---

## Documentation Requirements

[List documentation that should be created or updated:]

- [ ] Document 1: [Description]
- [ ] Document 2: [Description]
- [ ] Document 3: [Description]

**Example**:
- [ ] README.md with project overview and quick start
- [ ] API documentation for core interfaces
- [ ] Development setup guide

---

## Risks and Mitigation

[Identify potential risks and how to address them:]

| Risk | Impact | Probability | Mitigation Strategy |
|------|--------|-------------|---------------------|
| [Risk 1] | High/Medium/Low | High/Medium/Low | [How to mitigate] |
| [Risk 2] | High/Medium/Low | High/Medium/Low | [How to mitigate] |

**Example**:
| Risk | Impact | Probability | Mitigation Strategy |
|------|--------|-------------|---------------------|
| Database connection issues | High | Medium | Provide clear error messages and connection testing utilities |
| Dependency conflicts | Medium | Low | Pin dependency versions and test thoroughly |

---

**Next Milestone**: [Link to next milestone: milestone-{N+1}-{name}.md]  
**Blockers**: [List any current blockers, or "None"]  
**Notes**: [Any additional context or considerations]  
