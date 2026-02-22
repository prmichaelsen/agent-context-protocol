# Command: package-install

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.package-install` has been invoked. Follow the steps below to execute this command.
> Pretend this command was entered with this additional context: "Execute directive `@{namespace}-{command-name} NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."

**Namespace**: acp
**Version**: 1.0.0
**Created**: 2026-02-16
**Last Updated**: 2026-02-16
**Status**: Active

---

**Purpose**: Install third-party command packages from git repositories using the package-install script
**Category**: Maintenance
**Frequency**: As Needed

---

## What This Command Does

This command installs third-party ACP packages from git repositories by running the `agent/scripts/package-acp.install.sh` script. The script clones the repository and installs files from the `agent/` directory, including commands, patterns, and design documents.

Use this command when you want to add community-created commands and patterns, install organization-specific ACP content, or share reusable components across multiple projects. It enables extending ACP with custom functionality, patterns, and documentation.

⚠️ **SECURITY WARNING**: Third-party packages can instruct agents to modify files and execute scripts. Always review package contents before installation. You assume all risk when installing third-party packages.

---

## Manifest Tracking

When you install a package, `@acp.package-install` creates or updates `agent/manifest.yaml` to track:

- **Package metadata**:
  - Package name and version
  - Source URL (GitHub repository)
  - Git commit hash
  - Installation and update timestamps

- **Installed files**:
  - File names and individual versions
  - File checksums (SHA-256) for modification detection
  - Installation timestamps
  - Modified status (detected via checksum comparison)

This enables:
- ✅ **Smart updates** - Only update changed files
- ✅ **Conflict detection** - Detect locally modified files
- ✅ **Team collaboration** - Commit manifest to git for reproducible setups
- ✅ **Version tracking** - Know exactly what's installed
- ✅ **Reproducible installs** - Install from manifest on new machines

**Example manifest entry**:
```yaml
packages:
  firebase:
    source: https://github.com/prmichaelsen/acp-firebase.git
    package_version: 1.2.0
    commit: a1b2c3d4e5f6
    installed_at: 2026-02-18T10:30:00Z
    updated_at: 2026-02-18T10:30:00Z
    installed:
      patterns:
        - name: user-scoped-collections.md
          version: 1.1.0
          installed_at: 2026-02-18T10:30:00Z
          modified: false
          checksum: sha256:abc123...
```

---

## Auto-Initialization

When using the `--global` flag for the first time, the system automatically initializes `~/.acp/` infrastructure:
- Creates `~/.acp/` directory
- Installs full ACP (templates, scripts, schemas)
- Creates `~/.acp/projects/` directory for package development
- Creates `~/.acp/agent/manifest.yaml` for package tracking

This happens automatically - no manual setup required.

---

## Prerequisites

- [ ] ACP installed in project
- [ ] Git installed and available
- [ ] Internet connection available
- [ ] `agent/scripts/package-acp.install.sh` exists
- [ ] You trust the source of the commands
- [ ] You have reviewed the command repository

---

## Steps

### 1. Choose Installation Mode

Decide what to install from the package.

**Installation Modes**:

**A. Full Installation** (default):
```bash
./agent/scripts/acp.package-install.sh <repository-url>
```
Installs all patterns, commands, and designs from the package.

**B. List Mode** (preview files):
```bash
./agent/scripts/acp.package-install.sh --list <repository-url>
```
Shows available files without installing anything.

**C. Type-Selective Installation**:
```bash
# Install only patterns
./agent/scripts/acp.package-install.sh --patterns <repository-url>

# Install only commands
./agent/scripts/acp.package-install.sh --commands <repository-url>

# Install patterns and commands (not designs)
./agent/scripts/acp.package-install.sh --patterns --commands <repository-url>
```

**D. File-Selective Installation**:
```bash
# Install specific patterns
./agent/scripts/acp.package-install.sh --patterns file1 file2 <repository-url>

# Install specific commands
./agent/scripts/acp.package-install.sh --commands deploy.production <repository-url>

# Mix types and files
./agent/scripts/acp.package-install.sh --patterns file1 --commands cmd1 cmd2 <repository-url>
```

**Note**: File names can be specified with or without `.md` extension.

### 2. Run Package Install Script

Execute the package installation script with chosen options.

**Actions**:
- Verify `./agent/scripts/acp.package-install.sh` exists
- Run the script with desired flags and repository URL
- The script will:
  - Validate the repository URL
  - Clone the repository to a temporary location
  - Scan agent/ directory for installable files (commands, patterns, design)
  - Filter files based on selective flags (if any)
  - Validate command files (agent directive, namespace check)
  - Check for naming conflicts
  - Ask for confirmation (unless -y flag used)
  - Copy selected files to respective agent/ directories
  - Update manifest with installed files
  - Clean up temporary files
  - Report what was installed

**Expected Outcome**: Script completes successfully and selected files are installed

### 2. Review Installed Files

Verify the files were installed correctly.

**Actions**:
- List files in `agent/commands/` to see new commands
- List files in `agent/patterns/` to see new patterns
- List files in `agent/design/` to see new designs
- Read the installed files
- Verify commands have agent directives
- Check namespace is not `acp` (reserved for commands)
- Ensure no malicious content

**Expected Outcome**: Files verified safe and functional

### 3. Test Installed Commands

Try invoking one of the installed commands (if any). Prompt user for explicit confirmation before invoking.

**Actions**:
- Choose a simple command to test
- Invoke it using `@{namespace}.{action}` syntax
- Verify it works as expected
- Check for any errors

**Expected Outcome**: Commands work correctly

### 4. Verify Manifest Updated

Check that the manifest was created/updated correctly.

**Actions**:
- Verify `agent/manifest.yaml` exists
- Check package entry was added with:
  - Package name and version
  - Source URL
  - Commit hash
  - Installation timestamp
- Verify installed files are tracked with:
  - File names and versions
  - Checksums (for modification detection)
  - Installation timestamps

**Expected Outcome**: Manifest accurately tracks installation

### 5. Document Installation

Update progress tracking with installation notes.

**Actions**:
- Add note to `agent/progress.yaml` about installed package
- Document which package was installed
- Note installation date
- List installed files (commands, patterns, designs)

**Expected Outcome**: Installation tracked in progress

---

## Verification

- [ ] package-acp.install.sh script exists
- [ ] Script executed successfully
- [ ] Files installed to appropriate agent/ directories
- [ ] Installed commands reviewed for safety (if any)
- [ ] Installed patterns reviewed (if any)
- [ ] Installed designs reviewed (if any)
- [ ] Commands tested and working (if any)
- [ ] Installation documented in progress.yaml
- [ ] No errors during installation

---

## Expected Output

### Files Modified
- `agent/commands/*.md` - Installed command files (if any)
- `agent/patterns/*.md` - Installed pattern files (if any)
- `agent/design/*.md` - Installed design files (if any)

### Console Output
```
📦 ACP Package Installer
========================================

Repository: https://github.com/example/fullstack-package.git

Cloning repository...
✓ Repository cloned

Scanning for installable files...

📁 commands/ (3 file(s))
  ✓ deploy.production.md
  ✓ deploy.staging.md
  ⚠  deploy.rollback.md (will overwrite existing)

📁 patterns/ (2 file(s))
  ✓ api-service.md
  ✓ error-handling.md

📁 design/ (1 file(s))
  ✓ deployment-strategy.md

Ready to install 6 file(s)

Proceed with installation? (y/N) y

Installing files...
  ✓ Installed commands/deploy.production.md
  ✓ Installed commands/deploy.staging.md
  ✓ Installed commands/deploy.rollback.md
  ✓ Installed patterns/api-service.md
  ✓ Installed patterns/error-handling.md
  ✓ Installed design/deployment-strategy.md

✅ Installation complete!

Installed 6 file(s) from:
  https://github.com/example/fullstack-package.git

Installed commands:
  - @deploy.production
  - @deploy.staging
  - @deploy.rollback

⚠️  Security Reminder:
Review installed files before using them.
Third-party files can instruct agents to modify files and execute scripts.

Next steps:
  1. Review installed files in agent/ directories
  2. Test installed commands
  3. Update progress.yaml with installation notes
```

### Status Update
- Commands installed
- Installation documented
- Commands ready to use

---

## Examples

### Example 1: Installing Deployment Commands

**Context**: Want to add deployment commands from community

**Invocation**: `@acp.package-install https://github.com/example/acp-deploy-package.git`

**Result**: Script clones repo, installs 3 commands to agent/commands/, now can use @deploy.production

### Example 2: Installing Patterns Package

**Context**: Want to add TypeScript patterns from organization

**Invocation**: `@acp.package-install https://github.com/myorg/acp-typescript-patterns.git`

**Result**: Script installs 5 pattern files to agent/patterns/, now have reusable TypeScript patterns

### Example 3: Installing Complete Package

**Context**: Installing package with commands, patterns, and designs

**Invocation**: `@acp.package-install https://github.com/example/acp-fullstack-package.git`

**Result**: Script installs 3 commands, 4 patterns, 2 design docs across agent/ directories

### Example 4: Installing with Conflicts

**Context**: Installing package that conflicts with existing files

**Invocation**: `@acp.package-install https://github.com/example/acp-package.git`

**Result**: Script detects conflicts, asks for confirmation, overwrites if approved

---

## Related Commands

- [`@acp.validate`](acp.validate.md) - Validate installed commands
- [`@acp.version-update`](acp.version-update.md) - Update core ACP commands
- [`@acp.status`](acp.status.md) - View project status

---

## Troubleshooting

### Issue 1: Git clone fails

**Symptom**: Cannot clone repository

**Cause**: Invalid URL, no internet, or private repository

**Solution**: Verify URL is correct, check internet connection, ensure repository is public or you have access

### Issue 2: No commands found

**Symptom**: Repository cloned but no commands found

**Cause**: Commands not in expected location or wrong structure

**Solution**: Check repository structure, look for commands/ directory, verify files are .md format

### Issue 3: Validation fails

**Symptom**: Commands fail validation

**Cause**: Commands don't follow ACP structure

**Solution**: Review command files, ensure they have agent directive and required sections, contact command author

### Issue 4: Namespace conflict

**Symptom**: Command uses reserved namespace

**Cause**: Command tries to use 'acp' namespace

**Solution**: Cannot install - 'acp' namespace is reserved for core commands, contact command author to change namespace

---

## Security Considerations

### ⚠️ CRITICAL SECURITY WARNING

**Third-party packages can contain:**
- **Commands** that instruct agents to modify files and execute scripts
- **Patterns** that guide code implementation decisions
- **Designs** that influence architecture and technical decisions

**Third-party commands can:**
- Modify any files in your project
- Execute shell commands
- Make network requests
- Access environment variables
- Read sensitive data

**YOU ASSUME ALL RISK when installing third-party packages.**

### Security Best Practices

**Before Installing**:
1. Review the repository and command files
2. Check the author's reputation
3. Read what each command does
4. Verify no malicious content
5. Test in a non-production environment first

**After Installing**:
1. Review installed command files
2. Test commands in safe environment
3. Monitor command behavior
4. Remove if suspicious activity
5. Keep installation records

### File Access
- **Reads**: Repository files, existing files in agent/ directories
- **Writes**: `agent/commands/*.md`, `agent/patterns/*.md`, `agent/design/*.md`
- **Executes**: `git clone` command, `./agent/scripts/package-acp.install.sh`

### Network Access
- **APIs**: None directly
- **Repositories**: Clones from specified git repository

### Sensitive Data
- **Secrets**: Does not access secrets
- **Credentials**: May use git credentials for private repos

---

## Notes

- Installs from all agent/ directories: commands, patterns, design
- Only install packages from trusted sources
- Review all files before installation (commands, patterns, designs)
- Test in safe environment first
- Keep record of installed packages
- Update installed packages periodically
- Remove unused files
- Report security issues to package authors
- Consider forking repositories for stability
- Pin to specific versions/commits for reproducibility
- Use `-y` flag for automated/scripted installations
- Patterns and designs influence agent behavior just like commands

---

**Namespace**: acp
**Command**: package-install
**Version**: 1.0.0
**Created**: 2026-02-16
**Last Updated**: 2026-02-16
**Status**: Active
**Compatibility**: ACP 1.1.0+
**Author**: ACP Project
