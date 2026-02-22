# Command: package-create

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.package-create` has been invoked. Follow the steps below to execute this command.
> Pretend this command was entered with this additional context: "Execute directive `@{namespace}-{command-name} NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."

**Namespace**: acp
**Version**: 2.0.0
**Created**: 2026-02-20
**Last Updated**: 2026-02-21
**Status**: Active

---

**Purpose**: Create a new ACP package with full ACP installation, release branch configuration, and pre-commit hooks
**Category**: Creation
**Frequency**: Once per package

---

## What This Command Does

This command creates a complete ACP package from scratch with:

1. **Full ACP Installation** - Runs `acp.install.sh` to install complete ACP structure
2. **Package Metadata** - Creates `package.yaml` with package information
3. **Release Branch Configuration** - Configures which branch(es) can publish
4. **Pre-Commit Hooks** - Installs validation hooks automatically
5. **Git Repository** - Initializes git with initial commit
6. **Documentation** - Creates README.md, LICENSE, CHANGELOG.md

Unlike the old version, this command:
- ✅ Installs **complete ACP** (all templates, commands, scripts)
- ✅ Configures **release branch** for publishing
- ✅ Installs **pre-commit hooks** for validation
- ❌ Does NOT create example files (use templates instead)

Use this command when starting a new ACP package that you plan to share with others.

---

## Auto-Initialization

When creating packages in `~/.acp/projects/` for the first time, the system automatically initializes `~/.acp/` infrastructure:
- Creates `~/.acp/` directory
- Installs full ACP (templates, scripts, schemas)
- Creates `~/.acp/projects/` directory
- Creates `~/.acp/agent/manifest.yaml` for package tracking

This happens automatically - no manual setup required.

---

## Prerequisites

- [ ] ACP installed in current directory (to access the script)
- [ ] Git installed on system
- [ ] Basic understanding of what content you want to package
- [ ] (Optional) GitHub account for publishing

---

## Steps

### 1. Gather Package Information via Chat

**IMPORTANT**: Collect all information from the user via chat BEFORE executing the script.

**Actions**:
1. Explain what information is needed and why
2. Ask user for each piece of information one at a time
3. Validate each input before proceeding
4. Summarize all collected information
5. Ask for confirmation before proceeding

**Information to Collect**:

**Package Name** (required)
- Ask: "What would you like to name your package? (lowercase, no spaces, hyphens allowed)"
- Validation: Must be lowercase, alphanumeric, and hyphens only
- Examples: "firebase", "mcp-integration", "oauth-2"
- Note: This becomes the directory name `acp-{name}/`

**Description** (required)
- Ask: "Provide a one-line description of your package:"
- Validation: Should be clear and concise (< 100 characters recommended)
- Examples: "Firebase patterns and utilities for ACP projects"

**Author Name** (required)
- Ask: "What is your name (package author)?"
- Examples: "Patrick Michaelsen", "Your Name"

**License** (optional, default: MIT)
- Ask: "What license would you like to use? (default: MIT)"
- Common options: MIT, Apache-2.0, GPL-3.0, BSD-3-Clause
- Default: MIT if not specified

**Homepage URL** (optional)
- Ask: "What is the homepage URL for this package? (optional, press Enter to skip)"
- Examples: "https://github.com/username/acp-firebase"
- Note: Can be GitHub repo URL or documentation site

**Repository URL** (required)
- Ask: "What is the git repository URL? (e.g., https://github.com/username/acp-{name}.git)"
- Validation: Should be a valid git URL
- Examples: "https://github.com/prmichaelsen/acp-firebase.git"

**Tags** (required)
- Ask: "What tags describe your package? (comma-separated, for discovery)"
- Validation: At least one tag recommended
- Examples: "firebase, firestore, database, backend"
- Note: These help users find your package via `@acp.package-search`

**Release Branch** (optional, default: main)
- Ask: "What branch should be used for publishing? (default: main)"
- Common options: main, master, mainline, release
- Default: main if not specified
- Note: Only commits to this branch can be published

**Target Directory** (optional)
- Ask: "Where would you like to create the package? (default: ~/.acp/projects/{package-name} or $HOME/.acp/projects/{package-name})"
- Supports: Absolute paths, relative paths, `~` expansion, `$HOME` expansion
- Examples: "~/.acp/projects/firebase", "~/dev/packages", "$HOME/packages", "/tmp", "."
- Default: `~/.acp/projects/{package-name}` if not specified (equivalent to `$HOME/.acp/projects/{package-name}`)
- Note: Package will be created in the specified directory
- Rationale: `~/.acp/projects/` is for development work, while `~/.acp/packages/` is reserved for installed packages from remote repositories

**Expected Outcome**: All metadata collected and validated

**Example Chat Interaction**:
```
Agent: Let's create a new ACP package! I'll need to collect some information from you.

Agent: What would you like to name your package? (lowercase, no spaces, hyphens allowed)
      Examples: "firebase", "mcp-integration", "oauth-2"

User: firebase

Agent: Great! "firebase" is a valid package name. ✓

Agent: Provide a one-line description of your package:

User: Firebase patterns and utilities for ACP projects

Agent: Perfect! ✓

Agent: What is your name (package author)?

User: Patrick Michaelsen

Agent: ✓

Agent: What license would you like to use? (default: MIT)

User: [Enter]

Agent: Using MIT license. ✓

Agent: What is the homepage URL for this package? (optional, press Enter to skip)

User: https://github.com/prmichaelsen/acp-firebase

Agent: ✓

Agent: What is the git repository URL?
      Example: https://github.com/username/acp-firebase.git

User: https://github.com/prmichaelsen/acp-firebase.git

Agent: ✓

Agent: What tags describe your package? (comma-separated, for discovery)
      These help users find your package via @acp.package-search

User: firebase, firestore, database, backend

Agent: ✓

Agent: What branch should be used for publishing? (default: main)

User: [Enter]

Agent: Using main branch. ✓

Agent: Where would you like to create the package? (default: ~/.acp/projects/firebase or $HOME/.acp/projects/firebase)

User: [Enter]

Agent: Using ~/.acp/projects/firebase. ✓

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Summary of collected information:

Package name: firebase
Description: Firebase patterns and utilities for ACP projects
Author: Patrick Michaelsen
License: MIT
Homepage: https://github.com/prmichaelsen/acp-firebase
Repository: https://github.com/prmichaelsen/acp-firebase.git
Tags: firebase, firestore, database, backend
Release branch: main
Target directory: ~/.acp/projects/firebase (or $HOME/.acp/projects/firebase)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Agent: Does this look correct? (yes/no)

User: yes

Agent: Excellent! I'll now create your package...
```

### 2. Execute Package Creation Script

Once all information is collected and confirmed, execute the script with the collected arguments.

**Actions**:
1. Prepare script execution with collected values
2. Execute `./agent/scripts/acp.package-create.sh` with heredoc input
3. Monitor script output and report progress
4. Verify successful completion

**Script Execution**:

```bash
cd /home/prmichaelsen/agent-context-protocol

./agent/scripts/acp.package-create.sh << 'EOF'
{package-name}
{description}
{author}
{license}
{homepage}
{repository-url}
{tags}
{release-branch}
{target-directory}
EOF
```

**Example with collected values**:
```bash
./agent/scripts/acp.package-create.sh << 'EOF'
firebase
Firebase patterns and utilities for ACP projects
Patrick Michaelsen
MIT
https://github.com/prmichaelsen/acp-firebase
https://github.com/prmichaelsen/acp-firebase.git
firebase, firestore, database, backend
main
.
EOF
```

**Path Expansion**:
- `~` expands to user's home directory
- `$HOME` expands to home directory
- Relative paths resolved from current directory
- Absolute paths used as-is

**Expected Outcome**: Script executes successfully and creates complete package structure

**Script Output to Display**:
```
📦 ACP Package Creator
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Creating new ACP package: firebase

Package name: firebase
Description: Firebase patterns and utilities for ACP projects
Author: Patrick Michaelsen
License: MIT
Homepage: https://github.com/prmichaelsen/acp-firebase
Repository: https://github.com/prmichaelsen/acp-firebase.git
Tags: firebase, firestore, database, backend
Release branch: main

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Creating Directory Structure

✓ Created directory: acp-firebase/

Installing ACP

✓ ACP installed successfully
✓ All templates and commands available

Creating package.yaml

✓ Created package.yaml
✓ Configured release branch: main

Creating Documentation

✓ Created README.md
✓ Created LICENSE (MIT)
✓ Created CHANGELOG.md
✓ Created .gitignore

Installing Pre-Commit Hook

✓ Installed pre-commit hook
✓ Validates package.yaml before commits

Initializing Git Repository

✓ Initialized git repository
✓ Created initial commit

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎉 Package Created Successfully!

Your ACP package is ready at: ./acp-firebase/

[Next steps displayed...]
```

**Directory Structure Created**:
```
acp-{package-name}/
├── AGENT.md                     # ACP documentation
├── README.md                    # Package documentation
├── LICENSE                      # License file (MIT)
├── CHANGELOG.md                 # Version history
├── package.yaml                 # Package metadata
├── .gitignore                   # Git exclusions
└── agent/
    ├── .gitignore               # Agent-specific exclusions
    ├── progress.template.yaml   # Progress tracking template
    ├── manifest.template.yaml   # Manifest template
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
    ├── commands/
    │   ├── command.template.md
    │   ├── acp.init.md
    │   ├── acp.proceed.md
    │   ├── acp.status.md
    │   └── ... (all ACP commands)
    ├── scripts/
    │   ├── acp.common.sh
    │   ├── acp.install.sh
    │   ├── acp.version-update.sh
    │   └── ... (all ACP scripts)
    └── schemas/
        └── package.schema.yaml
```

### 3. Display Script Output and Next Steps

After script execution completes, display the next steps for the user.

**Actions**:
- Confirm package was created successfully
- Show package location
- Provide GitHub publishing instructions
- Explain how to add content
- Remind about package.yaml maintenance

**Expected Outcome**: User knows exactly what to do next

**Instructions Display**:
```
🎉 Package Created Successfully!

Your ACP package is ready at: ./acp-{package-name}/

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Next Steps:

1. Add your content:
   - Use @acp.pattern-create to create patterns
   - Use @acp.command-create to create commands
   - Use @acp.design-create to create designs
   
   These commands automatically:
   - Add namespace prefix to filenames
   - Update package.yaml contents section
   - Update README.md "What's Included" section

2. Validate your package:
   cd acp-{package-name}
   @acp.package-validate
   
   This checks:
   - package.yaml structure
   - File existence and namespace consistency
   - Git repository setup
   - README.md structure

3. Create GitHub repository:
   - Go to https://github.com/new
   - Name: acp-{package-name}
   - Description: {description}
   - Create repository (public recommended)

4. Push to GitHub:
   cd acp-{package-name}
   git remote add origin {repository-url}
   git branch -M {release-branch}
   git push -u origin {release-branch}

5. Add GitHub topic for discoverability:
   - Go to repository settings
   - Add topic: "acp-package" (REQUIRED)
   - Add other topics: {tags}

6. Publish your first version:
   cd acp-{package-name}
   @acp.package-publish
   
   This will:
   - Validate package
   - Detect version bump from commits
   - Update CHANGELOG.md
   - Create git tag
   - Push to remote
   - Test installation

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📚 Resources:

- Package structure guide: See AGENT.md
- package.yaml reference: agent/design/acp-package-management-system.md
- Entity creation: @acp.pattern-create, @acp.command-create, @acp.design-create
- Validation: @acp.package-validate
- Publishing: @acp.package-publish

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Package creation complete!

Your package has:
✓ Full ACP installation (all templates and commands)
✓ Pre-commit hook (validates package.yaml before commits)
✓ Release branch configured ({release-branch})
✓ Git repository initialized

Ready to add content with @acp.pattern-create, @acp.command-create, @acp.design-create
```

### 4. Verify Package Creation

Check that all files were created correctly.

**Actions**:
- List created files
- Verify directory structure
- Check git repository status
- Confirm package.yaml is valid
- Verify pre-commit hook installed

**Expected Outcome**: Package is ready for content addition

**Verification Commands**:
```bash
# List package contents
ls -la acp-{package-name}/

# Check ACP installation
ls -la acp-{package-name}/agent/

# Check git status
cd acp-{package-name} && git status

# Verify package.yaml
cat acp-{package-name}/package.yaml

# Check pre-commit hook
ls -la acp-{package-name}/.git/hooks/pre-commit
```

---

## Verification

- [ ] Package directory created with correct name
- [ ] Full ACP installed (AGENT.md, agent/ directory with all files)
- [ ] All templates available (design, milestone, pattern, task, command)
- [ ] All ACP commands available (acp.init.md, acp.proceed.md, etc.)
- [ ] All ACP scripts available (acp.common.sh, acp.install.sh, etc.)
- [ ] `package.yaml` created with valid YAML
- [ ] Release branch configured in package.yaml
- [ ] README.md created with package information
- [ ] LICENSE file created
- [ ] CHANGELOG.md created with initial version
- [ ] .gitignore created
- [ ] Pre-commit hook installed and executable
- [ ] Git repository initialized
- [ ] Initial commit created
- [ ] GitHub publishing instructions displayed
- [ ] User understands next steps

---

## Expected Output

### Files Created

```
acp-{package-name}/
├── AGENT.md                     # ACP documentation
├── README.md                    # Package documentation
├── LICENSE                      # License file
├── CHANGELOG.md                 # Version history
├── package.yaml                 # Package metadata
├── .gitignore                   # Git exclusions
├── .git/
│   └── hooks/
│       └── pre-commit           # Validation hook
└── agent/
    ├── .gitignore               # Agent-specific exclusions
    ├── progress.template.yaml   # Progress tracking template
    ├── manifest.template.yaml   # Manifest template
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
    ├── commands/
    │   ├── command.template.md
    │   ├── acp.init.md
    │   ├── acp.proceed.md
    │   └── ... (all ACP commands)
    ├── scripts/
    │   ├── acp.common.sh
    │   ├── acp.install.sh
    │   └── ... (all ACP scripts)
    └── schemas/
        └── package.schema.yaml
```

### Console Output

```
📦 ACP Package Creator
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Creating new ACP package: firebase

Package name: firebase
Description: Firebase patterns and utilities for ACP projects
Author: Patrick Michaelsen
License: MIT
Homepage: https://github.com/prmichaelsen/acp-firebase
Repository: https://github.com/prmichaelsen/acp-firebase.git
Tags: firebase, firestore, database, backend
Release branch: main

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Creating Directory Structure

✓ Created directory: acp-firebase/

Installing ACP

✓ Cloning ACP repository...
✓ Creating directory structure...
✓ Installing ACP files...
✓ ACP installed successfully

Creating package.yaml

✓ Created package.yaml
✓ Configured release branch: main

Creating Documentation

✓ Created README.md
✓ Created LICENSE (MIT)
✓ Created CHANGELOG.md
✓ Created .gitignore

Installing Pre-Commit Hook

✓ Installed pre-commit hook
✓ Validates package.yaml before commits

Initializing Git Repository

✓ Initialized git repository
✓ Created initial commit

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎉 Package Created Successfully!

[Next steps displayed as shown in Step 3]
```

---

## Examples

### Example 1: Creating Firebase Package

**Context**: Want to share Firebase patterns with community

**Invocation**: `@acp.package-create`

**Interaction**:
```
Package name: firebase
Description: Firebase patterns and utilities for ACP projects
Author: Patrick Michaelsen
License [MIT]: 
Homepage: https://github.com/prmichaelsen/acp-firebase
Repository: https://github.com/prmichaelsen/acp-firebase.git
Tags: firebase, firestore, database, backend
Release branch [main]: 
Target directory [.]: 
```

**Result**: Complete ACP package with full installation, ready to add Firebase patterns

### Example 2: Creating MCP Integration Package

**Context**: Want to package MCP server integration patterns

**Invocation**: `@acp.package-create`

**Interaction**:
```
Package name: mcp-integration
Description: Model Context Protocol server integration patterns
Author: Patrick Michaelsen
License [MIT]: Apache-2.0
Homepage: https://github.com/prmichaelsen/acp-mcp-integration
Repository: https://github.com/prmichaelsen/acp-mcp-integration.git
Tags: mcp, model-context-protocol, integration, server
Release branch [main]: mainline
Target directory [.]: ~/projects
```

**Result**: Package created in ~/projects/acp-mcp-integration/ with Apache-2.0 license and mainline release branch

### Example 3: Creating OAuth Package with Custom Branch

**Context**: Want to share OAuth 2.0 implementation patterns, using release branch

**Invocation**: `@acp.package-create`

**Interaction**:
```
Package name: oauth
Description: OAuth 2.0 authentication patterns and flows
Author: Patrick Michaelsen
License [MIT]: MIT
Homepage: https://github.com/prmichaelsen/acp-oauth
Repository: https://github.com/prmichaelsen/acp-oauth.git
Tags: oauth, authentication, security, auth
Release branch [main]: release
Target directory [.]: 
```

**Result**: Package with release branch configured for publishing

---

## Related Commands

- [`@acp.pattern-create`](acp.pattern-create.md) - Create patterns in package
- [`@acp.command-create`](acp.command-create.md) - Create commands in package
- [`@acp.design-create`](acp.design-create.md) - Create designs in package
- [`@acp.package-validate`](acp.package-validate.md) - Validate package before publishing
- [`@acp.package-publish`](acp.package-publish.md) - Publish package to GitHub
- [`@acp.package-install`](acp.package-install.md) - Install packages (test your package)
- [`@git.init`](git.init.md) - Initialize git repository
- [`@git.commit`](git.commit.md) - Version-aware commits

---

## Troubleshooting

### Issue 1: Directory already exists

**Symptom**: Error "Directory acp-{name} already exists"

**Cause**: Package directory already created

**Solution**: 
- Choose a different package name
- Or remove existing directory: `rm -rf acp-{name}`
- Or work in existing directory (skip creation steps)

### Issue 2: Git not installed

**Symptom**: Error "git: command not found"

**Cause**: Git not installed on system

**Solution**: 
- Install git: https://git-scm.com/downloads
- Or skip git initialization (manual setup later)

### Issue 3: Invalid package name

**Symptom**: Warning about package name format

**Cause**: Package name contains spaces or special characters

**Solution**: 
- Use lowercase letters, numbers, and hyphens only
- No spaces or special characters
- Examples: "firebase", "mcp-integration", "oauth-2"

### Issue 4: ACP installation failed

**Symptom**: Error during ACP installation step

**Cause**: Network issues or repository unavailable

**Solution**:
- Check internet connection
- Verify GitHub is accessible
- Try again later
- Or manually install ACP: `curl -fsSL https://raw.githubusercontent.com/prmichaelsen/agent-context-protocol/mainline/agent/scripts/acp.install.sh | bash`

### Issue 5: Pre-commit hook not working

**Symptom**: Hook doesn't run or validation fails

**Cause**: Hook not executable or validation script missing

**Solution**:
- Make hook executable: `chmod +x .git/hooks/pre-commit`
- Verify validation script exists: `ls agent/scripts/acp.yaml-validate.sh`
- Test hook manually: `.git/hooks/pre-commit`

---

## Security Considerations

### File Access
- **Reads**: None (creates new files)
- **Writes**: Creates entire package directory structure
- **Executes**: `acp.install.sh`, `git init`, `git add`, `git commit`

### Network Access
- **APIs**: None
- **Repositories**: Clones agent-context-protocol repository for ACP installation

### Sensitive Data
- **Secrets**: Never include secrets in package files
- **Credentials**: Never commit credentials to git
- **Personal Info**: Only include what you want public

---

## Notes

- Package name becomes directory name: `acp-{name}/`
- Package name in `package.yaml` should NOT include "acp-" prefix
- GitHub repository name should include "acp-" prefix for clarity
- Always add "acp-package" topic to GitHub repository for discoverability
- Update `package.yaml` whenever you add/remove files (or use entity creation commands)
- Follow semantic versioning for package and file versions
- Test package installation before publishing: `@acp.package-validate`
- Use `@acp.package-publish` for automated publishing workflow
- Pre-commit hook validates package.yaml before every commit
- Release branch configuration prevents accidental publishing from wrong branch

---

## Best Practices

### Package Naming
- Use descriptive, single-word names when possible
- Use hyphens for multi-word names (e.g., "mcp-integration")
- Avoid generic names (e.g., "utils", "helpers")
- Be specific about what the package provides

### Content Organization
- **Patterns**: Reusable architectural patterns
- **Commands**: Workflow automation commands
- **Designs**: Technical specifications and architecture docs

### Documentation
- Write clear, concise descriptions
- Include usage examples in README.md
- Document dependencies clearly
- Keep CHANGELOG.md updated
- Add troubleshooting section for common issues

### Version Management
- Start at 1.0.0 for initial release
- Use semantic versioning (MAJOR.MINOR.PATCH)
- Update CHANGELOG.md with each version
- Use `@acp.package-publish` for automated versioning
- Tag releases in git: `git tag v1.0.0`

### GitHub Setup
- Add "acp-package" topic (required for discovery)
- Add descriptive topics/tags
- Write clear repository description
- Include installation instructions in README
- Add LICENSE file
- Consider adding GitHub Actions for validation

### Development Workflow
1. Create package with `@acp.package-create`
2. Add content with `@acp.pattern-create`, `@acp.command-create`, `@acp.design-create`
3. Validate with `@acp.package-validate`
4. Commit changes (pre-commit hook validates automatically)
5. Publish with `@acp.package-publish`
6. Test installation: `@acp.package-install {your-repo-url}`

---

## Changes from v1.0.0

### Breaking Changes
- **Complete rewrite**: Now installs full ACP instead of minimal structure
- **No example files**: Use templates from ACP installation instead
- **Release branch required**: Must configure release branch for publishing
- **Pre-commit hooks**: Automatically installed (validates package.yaml)

### New Features
- Full ACP installation with all templates and commands
- Release branch configuration
- Pre-commit hook installation
- Better error handling and validation
- Clearer next steps and instructions

### Migration Guide

If you have packages created with v1.0.0:

1. **Install full ACP**:
   ```bash
   cd your-package
   curl -fsSL https://raw.githubusercontent.com/prmichaelsen/agent-context-protocol/mainline/agent/scripts/acp.install.sh | bash
   ```

2. **Add release branch to package.yaml**:
   ```yaml
   release:
     branch: main  # or master, mainline, release
   ```

3. **Install pre-commit hook**:
   ```bash
   # In your package directory
   . agent/scripts/acp.common.sh
   install_precommit_hook
   ```

4. **Remove example files** (if present):
   ```bash
   rm agent/patterns/example-pattern.md
   rm agent/commands/example-command.md
   rm agent/design/example-design.md
   ```

5. **Update package.yaml contents** (remove example files from contents section)

---

**Namespace**: acp
**Command**: package-create
**Version**: 2.0.0
**Created**: 2026-02-20
**Last Updated**: 2026-02-21
**Status**: Active
**Compatibility**: ACP 2.8.0+
**Author**: ACP Project
