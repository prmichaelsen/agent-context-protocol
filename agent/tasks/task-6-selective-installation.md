# Task 6: Selective Installation

**Milestone**: [M3 - ACP Package Management System](../milestones/milestone-3-acp-package-management.md)  
**Estimated Time**: 4-6 hours  
**Dependencies**: Task 5 (Manifest System)  
**Status**: Not Started  
**Priority**: High  

---

## Objective

Implement selective installation flags (`--patterns`, `--commands`, `--designs`) and file-level selection to allow users to install only specific parts of a package instead of the entire package.

---

## Context

Users often only need specific patterns or commands from a package. Installing everything creates unnecessary clutter and potential conflicts. Selective installation allows users to pick exactly what they need, reducing bloat and improving clarity.

---

## Steps

### 1. Add Command-Line Argument Parsing

Enhance `scripts/package-acp.install.sh` to parse flags:

```bash
#!/bin/bash

# Parse arguments
REPO_URL=""
INSTALL_PATTERNS=false
INSTALL_COMMANDS=false
INSTALL_DESIGNS=false
PATTERN_FILES=()
COMMAND_FILES=()
DESIGN_FILES=()
LIST_ONLY=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --patterns)
      INSTALL_PATTERNS=true
      shift
      # Collect pattern file names
      while [[ $# -gt 0 && ! $1 =~ ^-- ]]; do
        PATTERN_FILES+=("$1")
        shift
      done
      ;;
    --commands)
      INSTALL_COMMANDS=true
      shift
      while [[ $# -gt 0 && ! $1 =~ ^-- ]]; do
        COMMAND_FILES+=("$1")
        shift
      done
      ;;
    --designs)
      INSTALL_DESIGNS=true
      shift
      while [[ $# -gt 0 && ! $1 =~ ^-- ]]; do
        DESIGN_FILES+=("$1")
        shift
      done
      ;;
    --list)
      LIST_ONLY=true
      shift
      ;;
    *)
      REPO_URL="$1"
      shift
      ;;
  esac
done

# Default: install everything if no flags specified
if [[ "$INSTALL_PATTERNS" == false && "$INSTALL_COMMANDS" == false && "$INSTALL_DESIGNS" == false ]]; then
  INSTALL_PATTERNS=true
  INSTALL_COMMANDS=true
  INSTALL_DESIGNS=true
fi
```

### 2. Implement List Mode

Add `--list` flag to preview files:

```bash
# List available files without installing
list_package_files() {
  local repo_dir=$1
  
  echo "📁 Available files in package:"
  echo ""
  
  if [ -d "$repo_dir/agent/patterns" ]; then
    echo "Patterns ($(ls -1 "$repo_dir/agent/patterns"/*.md 2>/dev/null | wc -l)):"
    ls -1 "$repo_dir/agent/patterns"/*.md 2>/dev/null | xargs -n1 basename
    echo ""
  fi
  
  if [ -d "$repo_dir/agent/commands" ]; then
    echo "Commands ($(ls -1 "$repo_dir/agent/commands"/*.md 2>/dev/null | wc -l)):"
    ls -1 "$repo_dir/agent/commands"/*.md 2>/dev/null | xargs -n1 basename
    echo ""
  fi
  
  if [ -d "$repo_dir/agent/designs" ]; then
    echo "Designs ($(ls -1 "$repo_dir/agent/design"/*.md 2>/dev/null | wc -l)):"
    ls -1 "$repo_dir/agent/design"/*.md 2>/dev/null | xargs -n1 basename
    echo ""
  fi
}
```

### 3. Implement Selective File Installation

Add logic to install only selected files:

```bash
# Install patterns
install_patterns() {
  local repo_dir=$1
  local package_name=$2
  local package_yaml="$repo_dir/package.yaml"
  
  if [[ ${#PATTERN_FILES[@]} -eq 0 ]]; then
    # Install all patterns
    for file in "$repo_dir/agent/patterns"/*.md; do
      if [ -f "$file" ]; then
        local file_name=$(basename "$file")
        local file_version=$(get_file_version "$package_yaml" "patterns" "$file_name")
        
        cp "$file" "agent/patterns/"
        add_file_to_manifest "$package_name" "patterns" "$file_name" "$file_version" "agent/patterns/$file_name"
        
        echo "✓ Installed patterns/$file_name"
      fi
    done
  else
    # Install specific patterns
    for file_name in "${PATTERN_FILES[@]}"; do
      # Add .md extension if not present
      [[ "$file_name" != *.md ]] && file_name="${file_name}.md"
      
      local file_path="$repo_dir/agent/patterns/$file_name"
      if [ ! -f "$file_path" ]; then
        echo "⚠️  Pattern not found: $file_name"
        continue
      fi
      
      local file_version=$(get_file_version "$package_yaml" "patterns" "$file_name")
      
      cp "$file_path" "agent/patterns/"
      add_file_to_manifest "$package_name" "patterns" "$file_name" "$file_version" "agent/patterns/$file_name"
      
      echo "✓ Installed patterns/$file_name"
    done
  fi
}

# Similar functions for commands and designs
install_commands() { ... }
install_designs() { ... }
```

### 4. Update Installation Summary

Show what was installed:

```bash
# Display installation summary
show_installation_summary() {
  local package_name=$1
  local patterns_count=$2
  local commands_count=$3
  local designs_count=$4
  local total_files=$((patterns_count + commands_count + designs_count))
  
  echo ""
  echo "✅ Installation complete!"
  echo ""
  echo "Package: $package_name ($PACKAGE_VERSION)"
  echo "Installed: $total_files file(s)"
  
  if [ $patterns_count -gt 0 ]; then
    echo "  - $patterns_count pattern(s)"
  fi
  
  if [ $commands_count -gt 0 ]; then
    echo "  - $commands_count command(s)"
  fi
  
  if [ $designs_count -gt 0 ]; then
    echo "  - $designs_count design(s)"
  fi
  
  echo ""
  echo "Manifest updated: agent/manifest.yaml"
}
```

### 5. Test Selective Installation

Test all installation modes:

```bash
# Test 1: Install only patterns
@acp.package-install https://github.com/test/acp-test.git --patterns

# Verify:
# - Only patterns/ files installed
# - Commands and designs not installed
# - Manifest tracks only patterns

# Test 2: Install specific patterns
@acp.package-install https://github.com/test/acp-test.git --patterns pattern1 pattern2

# Verify:
# - Only pattern1.md and pattern2.md installed
# - Other patterns not installed
# - Manifest tracks only these two files

# Test 3: Install patterns and commands
@acp.package-install https://github.com/test/acp-test.git --patterns --commands

# Verify:
# - Patterns and commands installed
# - Designs not installed
# - Manifest tracks both types

# Test 4: List mode
@acp.package-install https://github.com/test/acp-test.git --list

# Verify:
# - Shows available files
# - Does not install anything
# - Does not modify manifest
```

### 6. Handle Edge Cases

Add error handling:

```bash
# Handle missing files
if [ ! -f "$file_path" ]; then
  echo "⚠️  File not found: $file_name"
  echo "Available files:"
  ls -1 "$repo_dir/agent/$file_type"/*.md | xargs -n1 basename
  continue
fi

# Handle empty directories
if [ ! -d "$repo_dir/agent/patterns" ] || [ -z "$(ls -A "$repo_dir/agent/patterns")" ]; then
  echo "No patterns found in package"
fi

# Handle package without package.yaml
if [ ! -f "$repo_dir/package.yaml" ]; then
  echo "⚠️  No package.yaml found - using default versions (1.0.0)"
  DEFAULT_VERSION="1.0.0"
fi
```

---

## Verification

- [ ] `--patterns` flag installs only patterns
- [ ] `--commands` flag installs only commands
- [ ] `--designs` flag installs only designs
- [ ] Multiple flags work together
- [ ] File-level selection works (`--patterns file1 file2`)
- [ ] `.md` extension optional (auto-added)
- [ ] `--list` shows available files without installing
- [ ] Error messages for missing files
- [ ] Manifest tracks partial installations correctly
- [ ] Installation summary shows what was installed

---

## Files to Modify

1. `scripts/package-acp.install.sh` - Add argument parsing and selective installation
2. `commands/acp.package-install.md` - Document new flags

---

## Examples

### Example 1: Install Only Patterns
```bash
@acp.package-install https://github.com/prmichaelsen/acp-firebase.git --patterns

# Result:
# ✓ Installed patterns/user-scoped-collections.md
# ✓ Installed patterns/firebase-security-rules.md
# ✓ Installed patterns/firestore-queries.md
# ✅ Installation complete!
# Package: firebase (1.2.0)
# Installed: 3 file(s)
#   - 3 pattern(s)
```

### Example 2: Install Specific Files
```bash
@acp.package-install https://github.com/prmichaelsen/acp-firebase.git \
  --patterns user-scoped-collections firebase-security-rules

# Result:
# ✓ Installed patterns/user-scoped-collections.md
# ✓ Installed patterns/firebase-security-rules.md
# ✅ Installation complete!
# Package: firebase (1.2.0) - partial installation
# Installed: 2 of 6 file(s)
```

---

**Status**: Ready to implement  
**Priority**: High  
**Estimated Effort**: 4-6 hours  
