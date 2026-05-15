# Task {N}: {Descriptive Task Name}

<!-- @scry.entry
id: task.{name}~{hash}
kind: task
summary: {one-line summary, <=150 chars}
status: draft
weight: 0.6
tags: [{comma-separated "topic:keyword" strings}]
rationale: ""
applies: ""
seeded_questions: []
milestone: M{N}
spec: {agent/specs/{namespace}.{spec-name}.md or omit line if no spec}
covers: {FR10, FR11 — FR-IDs (Functional Requirements) claimed from the spec, or omit if no spec}
design: {agent/design/{namespace}.{name}.md or omit if no design}
incorporates: {DR1, DR3 — DR-IDs (Design Requirements) incorporated from the design, or omit if none}
depends_on: []
updated: {YYYY-MM-DD}
@scry.entry.end -->

**Milestone**: [M{N} - Milestone Name](../milestones/milestone-{N}-{name}.md)  
**Design Reference**: [{Design Name}](../design/{namespace}.{design-name}.md) | None  
**Estimated Time**: [e.g., "2 hours", "4 hours", "1 day"]  

---

## Objective

[Clearly state what this task accomplishes. Be specific and focused on a single, achievable goal.]

**Example**: "Create the basic project structure with all necessary configuration files and directory organization for a TypeScript-based MCP server."  

---

## Context

[Provide background information that helps understand why this task is necessary and how it fits into the larger milestone.]

**Example**: "This task establishes the foundation for the project. Without proper structure and configuration, subsequent development tasks cannot proceed. The structure follows industry best practices for TypeScript projects and MCP server organization."  

---

## Steps

[Provide a detailed, sequential list of actions to complete this task. Each step should be concrete and actionable.]

### 1. [Step Category or Action]
[Detailed description of what to do]

```bash
# Command examples if applicable
command --with-flags
```

```typescript
// Code examples if applicable
const example = "code";
```

### 2. [Next Step]
[Detailed description]

### 3. [Next Step]
[Detailed description]

**Example**:

### 1. Create Project Directory
Create the root directory for the project and navigate into it:

```bash
mkdir -p my-project
cd my-project
```

### 2. Initialize npm Project
Initialize a new npm project with default settings:

```bash
npm init -y
```

### 3. Update package.json
Edit the generated package.json to include proper metadata and scripts:

```json
{
  "name": "my-project",
  "version": "0.1.0",
  "description": "Description of what this project does",
  "main": "dist/index.js",
  "type": "module",
  "scripts": {
    "build": "node esbuild.build.js",
    "dev": "tsx watch src/index.ts",
    "start": "node dist/index.js",
    "test": "vitest",
    "typecheck": "tsc --noEmit"
  },
  "keywords": ["mcp", "relevant", "keywords"],
  "author": "Your Name",
  "license": "MIT"
}
```

### 4. Create Directory Structure
Create all necessary directories:

```bash
mkdir -p src/{types,utils,tools}
mkdir -p tests/{unit,integration}
mkdir -p agent/{design,milestones,patterns,tasks}
```

### 5. Create Configuration Files
Create TypeScript configuration, build scripts, and other config files.

**tsconfig.json**:
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "Node16",
    "moduleResolution": "Node16",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "tests"]
}
```

[Continue with other config files...]

---

## User-Observable Acceptance

<!-- REQUIRED. At least one user-observable acceptance criterion, OR an
     N/A line with a justification of >= 10 characters.

     An observable criterion is something you could check in a fresh
     browser session, CLI invocation, API call, or file on disk AFTER
     the task is complete. Backend-only "it compiles" is not observable.

     If the task genuinely has no user-observable outcome (pure refactor,
     internal rename, dev tooling, test-only changes), explicitly say so:

         N/A — <one-sentence reason, e.g. "internal refactor; no behavior change">

     Feature work should NEVER be N/A. If you're writing an N/A for a
     feature, stop and identify the observable effect.

     acp.proceed validates this section after the task is marked complete. -->

- [ ] In a fresh session, the user can [specific observable thing]
- [ ] [Observable change in UI / output / API response]

**Example**:
- [ ] In a fresh browser session, hovering any German word in an Iris message shows a popover with article, gloss, and CEFR level
- [ ] `GET /api/word?q=Abfahrt&lang=de` returns JSON matching the schema in Step 2
- [ ] `agent/tasks/milestone-N/task-M-foo.md` file exists on disk with the content from Step 6

---

## Functional Requirements Covered (Optional)

<!-- Populated automatically by @acp.task-create when a spec at
     agent/specs/ matches the task topic. Lists the specific functional
     requirement IDs (FR<N>) and behavior table rows this task implements.

     Leave this section out entirely if no spec applies — acp.proceed
     does NOT require it. When present, each item should be checked
     off or explicitly deferred before marking the task complete.

     Two reference formats supported:

     1. **Bare format** (default for non-driver-bound projects):

            **Source**: agent/specs/local.feature-name.md

            Covered requirements:
            - [ ] FR<N>: <short description copied verbatim from spec>
            - [ ] FR<M>: <short description>

            Covered behaviors (from Behavior Table):
            - [ ] <scenario name / row id>

     2. **Fully-qualified format** (recommended when a driver is bound;
        spec files are uuid-suffixed via marker.mint, so refs include
        the spec's id to disambiguate across designs/specs that may
        share FR-IDs):

            Covered requirements:
            - [ ] spec.detector-validation~a1b2c3d4#FR-5: <description>
            - [ ] spec.detector-validation~a1b2c3d4#FR-8: <description>

     The bare format remains valid for v1 — driver-bound projects MAY
     use the fully-qualified format and SHOULD when their spec ids carry
     uuid suffixes that make bare FR-IDs ambiguous.
-->

---

## Verification

[Provide a checklist of items to verify the task is complete. Each item should be objectively verifiable.]

- [ ] Verification item 1: [Specific condition to check]
- [ ] Verification item 2: [Specific condition to check]
- [ ] Verification item 3: [Specific condition to check]
- [ ] Verification item 4: [Specific condition to check]
- [ ] Verification item 5: [Specific condition to check]

**Example**:
- [ ] Project directory created and contains expected subdirectories
- [ ] package.json exists and contains correct metadata
- [ ] tsconfig.json exists and is valid JSON
- [ ] All configuration files created (.gitignore, .env.example, etc.)
- [ ] Directory structure matches specification
- [ ] No syntax errors in configuration files

---

## Expected Output

[Describe what the project should look like after this task is complete.]

**File Structure**:
```
project-root/
├── file1
├── file2
└── directory/
    └── file3
```

**Key Files Created**:
- `file1`: [Purpose]
- `file2`: [Purpose]
- `directory/file3`: [Purpose]

---

## Design Requirements Covered (Optional)

<!-- Populated automatically by @acp.task-create when the task incorporates
     design requirements (DR<N>) from a referenced design document.

     This section is the design-side counterpart to "Functional Requirements
     Covered" above. Use it to declare which atomic design units (decisions,
     code snippets, schemas, formulas, etc.) this task inlines from the
     design.

     Two reference formats supported:

     1. **Bare format** (default for non-driver-bound projects):

            **Source**: agent/design/local.feature-name.md

            Covered design requirements:
            - [ ] DR<N>: <short description / atomic-unit summary>
            - [ ] DR<M>: <short description>

     2. **Fully-qualified format** (recommended when a driver is bound;
        design files are uuid-suffixed via marker.mint, so refs include
        the design's id to disambiguate):

            Covered design requirements:
            - [ ] design.auth-flow~c9d8e7f6#DR-1: <description>
            - [ ] design.auth-flow~c9d8e7f6#DR-3: <description>

     This section supersedes the older "Key Design Requirements" section
     name. The marker field `incorporates:` lists the same DR-IDs in
     compact form for query purposes. -->

---

## Key Design Requirements (Optional, legacy)

<!-- Legacy section name retained for backward-compat with tasks created
     before v7.0.0. New tasks should prefer "Design Requirements Covered"
     above. This section is also populated by @acp.clarification-capture
     when create commands are invoked with --from-clar / --from-chat /
     --from-context — the clarification-capture flow appends category-
     grouped decision tables here.

     Group decisions by agent-inferred category using tables:

### {Category}

| Decision | Choice | Rationale |
|---|---|---|
| {decision} | {choice} | {rationale} |
-->

---

## Common Issues and Solutions

[Document potential problems and how to resolve them:]

### Issue 1: [Problem description]
**Symptom**: [What the user will see]  
**Solution**: [How to fix it]  

### Issue 2: [Problem description]
**Symptom**: [What the user will see]  
**Solution**: [How to fix it]  

**Example**:

### Issue 1: npm init fails
**Symptom**: Error message about permissions or missing npm  
**Solution**: Ensure Node.js and npm are installed correctly. Run `node --version` and `npm --version` to verify.  

### Issue 2: TypeScript configuration errors
**Symptom**: tsc complains about invalid configuration  
**Solution**: Validate JSON syntax in tsconfig.json. Ensure all required fields are present.  

---

## Resources

[Link to relevant documentation, examples, or references:]

- [Resource 1 Name](URL): Description
- [Resource 2 Name](URL): Description
- [Resource 3 Name](URL): Description

**Example**:
- [TypeScript Handbook](https://www.typescriptlang.org/docs/): Official TypeScript documentation
- [esbuild Documentation](https://esbuild.github.io/): Build tool documentation
- [MCP SDK Documentation](https://github.com/modelcontextprotocol/sdk): MCP protocol reference

---

## Notes

[Any additional context, warnings, or considerations:]

- Note 1: [Important information]
- Note 2: [Important information]
- Note 3: [Important information]

**Example**:
- This task creates the foundation for all subsequent work
- Configuration files may need adjustment based on specific project requirements
- Keep .env files out of version control (ensure .gitignore is correct)

---

**Next Task**: [Link to next task: task-{N+1}-{name}.md]  
**Related Design Docs**: [Links to relevant design documents]  
**Estimated Completion Date**: [YYYY-MM-DD or "TBD"]  
