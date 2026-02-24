# Command: init

> **🤖 Agent Directive**: If you are reading this file, the command `@git.init` has been invoked. Follow the steps below to execute this command.

**Namespace**: git
**Version**: 1.0.0
**Created**: 2026-02-16
**Last Updated**: 2026-02-16
**Status**: Active
**Scripts**: None

---

**Purpose**: Initialize a git repository with intelligent .gitignore based on project type
**Category**: Creation
**Frequency**: Once

---

## What This Command Does

This command intelligently initializes a git repository for your project by:
1. Analyzing the project structure to detect the project type (Node.js, Python, Rust, etc.)
2. Running `git init` to create the repository
3. Creating or updating `.gitignore` with sensible defaults based on the detected project type
4. Ensuring dependency lock files are NOT ignored (they should be committed)
5. Ignoring build directories, distribution directories, and dependency installation directories

The command is smart about .gitignore - it evaluates your project to determine what should be ignored rather than using a generic template. This ensures your repository follows best practices for your specific technology stack.

**Example**: "For a Node.js project, this command will detect `package.json`, initialize git, and create a `.gitignore` that ignores `node_modules/`, `dist/`, `*.tgz`, but keeps `package-lock.json` committed."

---

## Prerequisites

- [ ] Project directory exists and contains project files
- [ ] Git is installed on the system
- [ ] No existing `.git` directory (or you want to reinitialize)

---

## Steps

### 1. Evaluate Project Type

Analyze the project structure to determine the technology stack and project type.

**Actions**:
- Check for `package.json` (Node.js/npm)
- Check for `pyproject.toml`, `setup.py`, `requirements.txt` (Python)
- Check for `Cargo.toml` (Rust)
- Check for `pom.xml`, `build.gradle` (Java)
- Check for `go.mod` (Go)
- Check for `composer.json` (PHP)
- Check for `.csproj`, `.sln` (C#/.NET)
- Check for `Gemfile` (Ruby)
- Identify any other project-specific files

**If Project Type is Unknown**:
- If the project type cannot be determined from known patterns, use available web search tools (e.g., `mcp--brave-search--brave_web_search`) to research the project structure
- Search for: "{detected_file_pattern} gitignore best practices"
- Search for: "{detected_file_pattern} project structure"
- Search for: "{language_or_framework} build artifacts"
- Use the search results to determine:
  - What directories should be ignored (build output, dependencies)
  - What lock files exist and should be committed
  - What temporary files should be ignored
  - Common IDE/editor files for that ecosystem

**Expected Outcome**: Determine the primary project type(s) and technology stack, using web research if necessary.

**Example**:
```bash
# Check for various project files
ls -la | grep -E "(package.json|pyproject.toml|Cargo.toml|go.mod)"
```

### 2. Initialize Git Repository

Create the git repository if it doesn't exist.

**Actions**:
- Run `git init` to initialize the repository
- Verify `.git` directory was created
- Set initial branch name (typically `main` or `mainline`)

**Expected Outcome**: Git repository initialized with `.git` directory created.

**Example**:
```bash
git init
git branch -M main  # or mainline, depending on preference
```

### 3. Create or Update .gitignore

Generate a `.gitignore` file with intelligent defaults based on the detected project type.

**Actions**:
- Create `.gitignore` if it doesn't exist, or read existing one
- Add project-type-specific ignore patterns
- Ensure dependency lock files are NOT ignored
- Add common ignore patterns for build/dist directories
- Add editor/IDE specific ignores

**Expected Outcome**: `.gitignore` file created or updated with appropriate patterns.

**Common Patterns to Include**:

#### All Projects
```gitignore
# Editor/IDE
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store
Thumbs.db

# Environment
.env
.env.local
.env.*.local
*.log
```

#### Node.js/npm Projects
```gitignore
# Dependencies
node_modules/

# Build output
dist/
build/
out/
.next/
.nuxt/

# Package files (but NOT lock files)
*.tgz

# Testing
coverage/
.nyc_output/

# Cache
.npm
.eslintcache
.cache/
```

#### Python Projects
```gitignore
# Dependencies
__pycache__/
*.py[cod]
*$py.class
.Python

# Virtual environments
venv/
env/
ENV/
.venv

# Build output
dist/
build/
*.egg-info/
.eggs/

# Testing
.pytest_cache/
.coverage
htmlcov/
.tox/
```

#### Rust Projects
```gitignore
# Build output
target/
Cargo.lock  # Only for libraries; applications should commit this

# Debug
**/*.rs.bk
```

#### Go Projects
```gitignore
# Build output
bin/
*.exe
*.exe~
*.dll
*.so
*.dylib

# Test
*.test
*.out

# Vendor (if not using modules)
vendor/
```

#### Java Projects
```gitignore
# Build output
target/
build/
out/
*.class
*.jar
*.war
*.ear

# IDE
.gradle/
.settings/
.classpath
.project
```

**CRITICAL**: Ensure these are NOT ignored:
- `package-lock.json` (Node.js)
- `yarn.lock` (Node.js/Yarn)
- `pnpm-lock.yaml` (Node.js/pnpm)
- `Pipfile.lock` (Python/Pipenv)
- `poetry.lock` (Python/Poetry)
- `Cargo.lock` (Rust applications)
- `go.sum` (Go)
- `composer.lock` (PHP)
- `Gemfile.lock` (Ruby)

### 4. Verify .gitignore

Check that the `.gitignore` file is correct and complete.

**Actions**:
- Read the created `.gitignore` file
- Verify lock files are not ignored
- Verify build/dist directories are ignored
- Verify dependency directories are ignored
- Check for any project-specific patterns that should be added

**Expected Outcome**: `.gitignore` file is correct and follows best practices.

### 5. Display Summary

Show what was done and what's ready to be committed.

**Actions**:
- Display detected project type
- Show `.gitignore` patterns added
- Run `git status` to show initial state
- Provide next steps

**Expected Outcome**: User understands what was initialized and what to do next.

**Example**:
```bash
git status
```

---

## Verification

- [ ] `.git` directory exists
- [ ] `.gitignore` file exists and contains appropriate patterns
- [ ] Dependency lock files are NOT in `.gitignore`
- [ ] Build directories (dist/, build/, target/) are in `.gitignore`
- [ ] Dependency install directories (node_modules/, venv/, etc.) are in `.gitignore`
- [ ] `git status` shows untracked files correctly
- [ ] No sensitive files (like `.env`) are accidentally tracked

---

## Expected Output

### Files Modified
- `.git/` - Git repository directory created
- `.gitignore` - Created or updated with project-specific patterns

### Console Output
```
✓ Detected project type: Node.js (npm)
✓ Initialized git repository
✓ Created .gitignore with patterns:
  - node_modules/ (dependencies)
  - dist/ (build output)
  - *.tgz (package archives)
  - .env* (environment files)
✓ Preserved lock files:
  - package-lock.json (will be committed)

Next steps:
  git add .
  git commit -m "Initial commit"
```

### Status Update
- Git repository initialized
- `.gitignore` configured for project type
- Ready for initial commit

---

## Examples

### Example 1: Node.js Project

**Context**: Starting a new Node.js project with npm

**Invocation**: `@git.init`

**Result**: 
- Detects `package.json`
- Initializes git repository
- Creates `.gitignore` with:
  - `node_modules/` ignored
  - `dist/`, `build/` ignored
  - `*.tgz` ignored
  - `package-lock.json` NOT ignored (will be committed)
  - `.env*` ignored

### Example 2: Python Project

**Context**: Starting a Python project with Poetry

**Invocation**: `@git.init`

**Result**:
- Detects `pyproject.toml`
- Initializes git repository
- Creates `.gitignore` with:
  - `__pycache__/`, `*.pyc` ignored
  - `venv/`, `.venv/` ignored
  - `dist/`, `build/` ignored
  - `poetry.lock` NOT ignored (will be committed)
  - `.env*` ignored

### Example 3: Rust Project

**Context**: Starting a Rust application

**Invocation**: `@git.init`

**Result**:
- Detects `Cargo.toml`
- Initializes git repository
- Creates `.gitignore` with:
  - `target/` ignored
  - `Cargo.lock` NOT ignored for applications (will be committed)
  - `.env*` ignored

### Example 4: Multi-Language Project

**Context**: Project with both Node.js frontend and Python backend

**Invocation**: `@git.init`

**Result**:
- Detects both `package.json` and `pyproject.toml`
- Initializes git repository
- Creates `.gitignore` with patterns for both:
  - `node_modules/` and `__pycache__/` ignored
  - `dist/`, `build/`, `target/` ignored
  - Both `package-lock.json` and `poetry.lock` NOT ignored
  - `.env*` ignored

### Example 5: Unknown Project Type (Elixir)

**Context**: Starting an Elixir project with Mix

**Invocation**: `@git.init`

**Process**:
- Detects `mix.exs` file (unknown to built-in patterns)
- Uses web search: "mix.exs gitignore best practices"
- Finds that Elixir projects should ignore:
  - `_build/` (build output)
  - `deps/` (dependencies)
  - `*.ez` (compiled archives)
  - `mix.lock` should be committed

**Result**:
- Initializes git repository
- Creates `.gitignore` based on web research:
  - `_build/` ignored
  - `deps/` ignored
  - `*.ez` ignored
  - `mix.lock` NOT ignored (will be committed)
  - `.env*` ignored

---

## Related Commands

- [`@git.commit`](git.commit.md) - Use after initialization to make your first commit
- [`@acp.init`](acp.init.md) - Use to initialize ACP structure after git init

---

## Troubleshooting

### Issue 1: Git already initialized

**Symptom**: Error message "Reinitialized existing Git repository"

**Cause**: `.git` directory already exists

**Solution**: This is usually fine - git will reinitialize without losing history. If you want a fresh start, delete `.git` directory first: `rm -rf .git`

### Issue 2: .gitignore conflicts with existing file

**Symptom**: `.gitignore` already exists with different patterns

**Cause**: Project already has a `.gitignore`

**Solution**: The command will merge patterns, adding new ones while preserving existing ones. Review the result and manually adjust if needed.

### Issue 3: Lock files are ignored

**Symptom**: `git status` shows lock files as ignored

**Cause**: Existing `.gitignore` has patterns that ignore lock files

**Solution**: Edit `.gitignore` and remove any lines that ignore lock files (e.g., `*.lock`, `*-lock.json`). Lock files should always be committed.

### Issue 4: Too many files shown as untracked

**Symptom**: `git status` shows hundreds of dependency files

**Cause**: Dependency directories not properly ignored

**Solution**: Verify `.gitignore` includes dependency directories for your project type. Add missing patterns manually if needed.

### Issue 5: Unknown or uncommon project type

**Symptom**: Project type cannot be automatically detected

**Cause**: Using a less common language, framework, or custom project structure

**Solution**:
1. The command will use web search tools to research the project type
2. Search queries will be constructed based on detected files (e.g., "makefile gitignore best practices")
3. Review the search results and manually verify the suggested patterns
4. If still unclear, create a minimal `.gitignore` with common patterns:
   ```gitignore
   # Dependencies (adjust as needed)
   vendor/
   deps/
   
   # Build output (adjust as needed)
   build/
   dist/
   out/
   target/
   
   # Environment
   .env
   .env.local
   
   # Editor
   .vscode/
   .idea/
   ```
5. Refine the `.gitignore` as you learn more about the project's build process

---

## Security Considerations

### File Access
- **Reads**: Project root directory to detect project type
- **Writes**: `.git/` directory (git repository), `.gitignore` file
- **Executes**: `git init` command

### Network Access
- **APIs**: May use web search APIs (e.g., Brave Search) to research unknown project types
- **Repositories**: None

### Sensitive Data
- **Secrets**: Automatically ignores `.env` files and environment-specific files
- **Credentials**: Does not access any credentials
- **Important**: Always verify `.env` files are in `.gitignore` before committing

---

## Notes

- Lock files (package-lock.json, poetry.lock, etc.) should ALWAYS be committed to ensure reproducible builds
- Build directories (dist/, build/, target/) should ALWAYS be ignored - they can be regenerated
- Dependency directories (node_modules/, venv/) should ALWAYS be ignored - they can be reinstalled
- `.tgz` files should be ignored for npm packages to avoid committing packed archives
- Environment files (`.env`, `.env.local`) should ALWAYS be ignored to prevent credential leaks
- The command is idempotent - running it multiple times is safe
- For monorepos, consider running this at the root and adding workspace-specific patterns
- Always review the generated `.gitignore` to ensure it matches your project's needs

---

**Namespace**: git
**Command**: init
**Version**: 1.0.0
**Created**: 2026-02-16
**Last Updated**: 2026-02-16
**Status**: Active
**Compatibility**: ACP 1.3.0+
**Author**: Agent Context Protocol
