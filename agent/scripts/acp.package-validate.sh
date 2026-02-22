#!/bin/bash
# ACP Package Validation Script
# Comprehensive package validation with shell-based checks
# Version: 1.0.0

set -e

# Source common utilities
SCRIPT_DIR="$(dirname "$0")"
. "${SCRIPT_DIR}/acp.common.sh"
. "${SCRIPT_DIR}/acp.yaml-parser.sh"

# Initialize colors
init_colors

# Validation tracking
TOTAL_CHECKS=0
PASSED_CHECKS=0
ERRORS=()
WARNINGS=()
FIXABLE_ISSUES=()

# Add check result
check() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
}

# Add passed check
pass() {
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
    echo "  ${GREEN}✓${NC} $1"
}

# Add error
error() {
    echo "  ${RED}❌${NC} $1" >&2
    ERRORS+=("$1")
}

# Add warning
warning() {
    echo "  ${YELLOW}⚠️${NC}  $1"
    WARNINGS+=("$1")
}

# Add fixable issue
fixable() {
    FIXABLE_ISSUES+=("$1")
}

# Check if we're in a package directory
check_package_context() {
    echo "${BLUE}📦 Checking Package Context${NC}"
    echo ""
    
    check
    if [ ! -f "package.yaml" ]; then
        error "Not a package directory: package.yaml not found"
        echo ""
        echo "${RED}This command must be run from an ACP package directory.${NC}"
        echo "To create a package, use: @acp.package-create"
        exit 1
    fi
    pass "package.yaml found"
    
    # Extract package name and version
    PACKAGE_NAME=$(yaml_get "package.yaml" "name" 2>/dev/null || echo "unknown")
    PACKAGE_VERSION=$(yaml_get "package.yaml" "version" 2>/dev/null || echo "unknown")
    
    echo ""
    echo "${BOLD}Package: ${PACKAGE_NAME} (v${PACKAGE_VERSION})${NC}"
    echo ""
}

# Validate YAML structure
validate_yaml_structure() {
    echo "${BLUE}🔧 Shell Validation${NC}"
    echo ""
    echo "${BOLD}YAML Structure${NC}"
    
    # Run YAML schema validator
    check
    if "${SCRIPT_DIR}/acp.yaml-validate.sh" "package.yaml" >/dev/null 2>&1; then
        pass "package.yaml is valid YAML"
        pass "All required fields present"
        pass "Version format valid ($PACKAGE_VERSION)"
        
        # Check repository URL
        local repo_url=$(yaml_get "package.yaml" "repository" 2>/dev/null)
        if [ -n "$repo_url" ]; then
            pass "Repository URL valid"
        fi
        
        # Check reserved names
        case "$PACKAGE_NAME" in
            acp|local|core|system|global)
                error "Package name '$PACKAGE_NAME' is reserved"
                ;;
            *)
                pass "No reserved names used"
                ;;
        esac
    else
        error "package.yaml validation failed"
        echo ""
        echo "Running detailed validation:"
        "${SCRIPT_DIR}/acp.yaml-validate.sh" "package.yaml"
        fixable "Fix package.yaml structure"
    fi
    
    echo ""
}

# Validate file existence
validate_file_existence() {
    echo "${BOLD}File Existence${NC}"
    
    local total_files=0
    local missing_files=0
    
    # Check patterns
    if yaml_has_key "package.yaml" "contents.patterns"; then
        local pattern_count=$(yaml_get_array "package.yaml" "contents.patterns")
        for i in $(seq 0 $((pattern_count - 1))); do
            local pattern_name=$(yaml_get_nested "package.yaml" "contents.patterns[$i].name")
            if [ -n "$pattern_name" ]; then
                total_files=$((total_files + 1))
                check
                if [ -f "agent/patterns/$pattern_name" ]; then
                    pass "agent/patterns/$pattern_name ✓"
                else
                    error "Missing file: agent/patterns/$pattern_name"
                    missing_files=$((missing_files + 1))
                fi
            fi
        done
    fi
    
    # Check commands
    if yaml_has_key "package.yaml" "contents.commands"; then
        local command_count=$(yaml_get_array "package.yaml" "contents.commands")
        for i in $(seq 0 $((command_count - 1))); do
            local command_name=$(yaml_get_nested "package.yaml" "contents.commands[$i].name")
            if [ -n "$command_name" ]; then
                total_files=$((total_files + 1))
                check
                if [ -f "agent/commands/$command_name" ]; then
                    pass "agent/commands/$command_name ✓"
                else
                    error "Missing file: agent/commands/$command_name"
                    missing_files=$((missing_files + 1))
                fi
            fi
        done
    fi
    
    # Check designs
    if yaml_has_key "package.yaml" "contents.designs"; then
        local design_count=$(yaml_get_array "package.yaml" "contents.designs")
        for i in $(seq 0 $((design_count - 1))); do
            local design_name=$(yaml_get_nested "package.yaml" "contents.designs[$i].name")
            if [ -n "$design_name" ]; then
                total_files=$((total_files + 1))
                check
                if [ -f "agent/design/$design_name" ]; then
                    pass "agent/design/$design_name ✓"
                else
                    error "Missing file: agent/design/$design_name"
                    missing_files=$((missing_files + 1))
                fi
            fi
        done
    fi
    
    if [ "$missing_files" -eq 0 ]; then
        pass "All $total_files files in contents exist"
    else
        error "$missing_files of $total_files files missing"
        fixable "Remove missing files from package.yaml"
    fi
    
    echo ""
}

# Check for unlisted files
check_unlisted_files() {
    echo "${BOLD}Unlisted Files${NC}"
    
    local unlisted=0
    
    # Get files from manifest (all packages including acp-core)
    # Use simple grep to extract all "- name: filename" entries
    local manifest_files=""
    if [ -f "agent/manifest.yaml" ]; then
        manifest_files=$(grep -E "^[[:space:]]+-[[:space:]]+name:" agent/manifest.yaml | sed 's/.*name:[[:space:]]*//' || echo "")
    fi
    
    # Check patterns directory
    if [ -d "agent/patterns" ]; then
        for file in agent/patterns/*.md; do
            [ -f "$file" ] || continue
            local basename=$(basename "$file")
            
            # Skip templates
            [[ "$basename" == *.template.md ]] && continue
            [[ "$basename" == ".gitkeep" ]] && continue
            
            # Skip if in manifest (installed from another package)
            if echo "$manifest_files" | grep -q "^${basename}$"; then
                continue
            fi
            
            # Check if listed in package.yaml
            if ! grep -q "name: $basename" package.yaml 2>/dev/null; then
                warning "Found unlisted file: patterns/$basename"
                fixable "Add patterns/$basename to package.yaml"
                unlisted=$((unlisted + 1))
            fi
        done
    fi
    
    # Check commands directory
    if [ -d "agent/commands" ]; then
        for file in agent/commands/*.md; do
            [ -f "$file" ] || continue
            local basename=$(basename "$file")
            
            # Skip templates
            [[ "$basename" == *.template.md ]] && continue
            
            # Skip if in manifest (installed from another package, including acp-core)
            if echo "$manifest_files" | grep -q "^${basename}$"; then
                continue
            fi
            
            # Check if listed in package.yaml
            if ! grep -q "name: $basename" package.yaml 2>/dev/null; then
                warning "Found unlisted file: commands/$basename"
                fixable "Add commands/$basename to package.yaml"
                unlisted=$((unlisted + 1))
            fi
        done
    fi
    
    # Check designs directory
    if [ -d "agent/design" ]; then
        for file in agent/design/*.md; do
            [ -f "$file" ] || continue
            local basename=$(basename "$file")
            
            # Skip templates and .gitkeep
            [[ "$basename" == *.template.md ]] && continue
            [[ "$basename" == ".gitkeep" ]] && continue
            
            # Skip if in manifest (installed from another package)
            if echo "$manifest_files" | grep -q "^${basename}$"; then
                continue
            fi
            
            # Check if listed in package.yaml
            if ! grep -q "name: $basename" package.yaml 2>/dev/null; then
                warning "Found unlisted file: design/$basename"
                fixable "Add design/$basename to package.yaml"
                unlisted=$((unlisted + 1))
            fi
        done
    fi
    
    # Check scripts directory
    if [ -d "agent/scripts" ]; then
        for file in agent/scripts/*.sh; do
            [ -f "$file" ] || continue
            local basename=$(basename "$file")
            
            # Skip templates, acp core scripts, and common utilities
            [[ "$basename" == *.template.sh ]] && continue
            [[ "$basename" == acp.* ]] && continue
            [[ "$basename" == "acp.common.sh" ]] && continue
            
            # Skip if in manifest (installed from another package)
            if echo "$manifest_files" | grep -q "^${basename}$"; then
                continue
            fi
            
            # Check if listed in package.yaml
            if ! grep -q "name: $basename" package.yaml 2>/dev/null; then
                warning "Found unlisted file: scripts/$basename"
                fixable "Add scripts/$basename to package.yaml"
                unlisted=$((unlisted + 1))
            fi
        done
    fi
    
    check
    if [ "$unlisted" -eq 0 ]; then
        pass "No unlisted files found"
    else
        warning "Found $unlisted unlisted file(s)"
    fi
    
    echo ""
}

# Validate namespace consistency
validate_namespace_consistency() {
    echo "${BOLD}Namespace Consistency${NC}"
    
    local namespace="$PACKAGE_NAME"
    local inconsistent=0
    local skipped=0
    local skipped_package_files=0
    
    # Read package.yaml contents to know which files should be validated
    # Build list of filenames from contents (extract .name from each object)
    # yaml_get_array now handles object arrays and returns count
    local package_commands=""
    if yaml_has_key "package.yaml" "contents.commands"; then
        local command_count=$(yaml_get_array "package.yaml" "contents.commands")
        for i in $(seq 0 $((command_count - 1))); do
            local cmd_name=$(yaml_get_nested "package.yaml" "contents.commands[$i].name")
            [ -n "$cmd_name" ] && package_commands="${package_commands}${cmd_name}"$'\n'
        done
    fi
    
    local package_patterns=""
    if yaml_has_key "package.yaml" "contents.patterns"; then
        local pattern_count=$(yaml_get_array "package.yaml" "contents.patterns")
        for i in $(seq 0 $((pattern_count - 1))); do
            local pat_name=$(yaml_get_nested "package.yaml" "contents.patterns[$i].name")
            [ -n "$pat_name" ] && package_patterns="${package_patterns}${pat_name}"$'\n'
        done
    fi
    
    local package_designs=""
    if yaml_has_key "package.yaml" "contents.designs"; then
        local design_count=$(yaml_get_array "package.yaml" "contents.designs")
        for i in $(seq 0 $((design_count - 1))); do
            local des_name=$(yaml_get_nested "package.yaml" "contents.designs[$i].name")
            [ -n "$des_name" ] && package_designs="${package_designs}${des_name}"$'\n'
        done
    fi
    
    # Track package files that were skipped (for helpful warning)
    local skipped_package_files_list=""
    
    # Check command files
    if [ -d "agent/commands" ]; then
        for file in agent/commands/*.md; do
            [ -f "$file" ] || continue
            local basename=$(basename "$file")
            
            # Skip templates and core commands
            [[ "$basename" == *.template.md ]] && continue
            [[ "$basename" == acp.* ]] && continue
            [[ "$basename" == local.* ]] && continue
            
            # Check if file is in package.yaml contents
            if ! echo "$package_commands" | grep -q "^${basename}$"; then
                # Check if this is a package file (matches namespace)
                if [[ "$basename" =~ ^${namespace}\. ]]; then
                    skipped_package_files_list="${skipped_package_files_list}${basename}"$'\n'
                    skipped_package_files=$((skipped_package_files + 1))
                fi
                info "Skipping namespace check (not in package contents): $basename"
                skipped=$((skipped + 1))
                continue
            fi
            
            # Check if filename starts with namespace
            if [[ ! "$basename" =~ ^${namespace}\. ]]; then
                error "Command file missing namespace: $basename (should be ${namespace}.*.md)"
                fixable "Rename $basename to ${namespace}.${basename}"
                inconsistent=$((inconsistent + 1))
            fi
        done
    fi
    
    # Check pattern files (optional namespace for patterns)
    if [ -d "agent/patterns" ]; then
        for file in agent/patterns/*.md; do
            [ -f "$file" ] || continue
            local basename=$(basename "$file")
            
            # Skip templates
            [[ "$basename" == *.template.md ]] && continue
            
            # Check if file is in package.yaml contents
            if ! echo "$package_patterns" | grep -q "^${basename}$"; then
                # Check if this is a package file (matches namespace)
                if [[ "$basename" =~ ^${namespace}\. ]]; then
                    skipped_package_files_list="${skipped_package_files_list}${basename}"$'\n'
                    skipped_package_files=$((skipped_package_files + 1))
                fi
                info "Skipping namespace check (not in package contents): $basename"
                skipped=$((skipped + 1))
                continue
            fi
            
            # Patterns may or may not use namespace - just warn if inconsistent
            if [[ "$basename" =~ ^${namespace}\. ]]; then
                # Has namespace - good
                :
            else
                # No namespace - warn but don't error
                warning "Pattern file without namespace: $basename (consider ${namespace}.${basename})"
            fi
        done
    fi
    
    # Check design files
    if [ -d "agent/design" ]; then
        for file in agent/design/*.md; do
            [ -f "$file" ] || continue
            local basename=$(basename "$file")
            
            # Skip templates
            [[ "$basename" == *.template.md ]] && continue
            [[ "$basename" == .gitkeep ]] && continue
            
            # Check if file is in package.yaml contents
            if ! echo "$package_designs" | grep -q "^${basename}$"; then
                # Check if this is a package file (matches namespace)
                if [[ "$basename" =~ ^${namespace}\. ]]; then
                    skipped_package_files_list="${skipped_package_files_list}${basename}"$'\n'
                    skipped_package_files=$((skipped_package_files + 1))
                fi
                info "Skipping namespace check (not in package contents): $basename"
                skipped=$((skipped + 1))
                continue
            fi
        done
    fi
    
    check
    
    # Error if package files match namespace but aren't in contents
    if [ "$skipped_package_files" -gt 0 ]; then
        echo ""
        error "$skipped_package_files package file(s) match namespace but not in contents:"
        echo "$skipped_package_files_list" | while read -r fname; do
            [ -n "$fname" ] && echo "    ${RED}✗${NC} $fname"
        done
        echo ""
        echo "  ${RED}Package files matching namespace MUST be in package.yaml contents${NC}"
        echo "  Add them with: ${YELLOW}@acp.command-create${NC} or ${YELLOW}@acp.pattern-create${NC}"
        echo "  Or remove the namespace prefix if they're dependencies"
        inconsistent=$((inconsistent + skipped_package_files))
    fi
    
    if [ "$inconsistent" -eq 0 ]; then
        pass "All package content files use correct namespace"
        if [ "$skipped" -gt 0 ]; then
            info "$skipped file(s) skipped (not in package.yaml contents)"
            info "These files won't be installed to user projects"
            info "This is normal for installed dependencies (tracked in manifest.yaml)"
        fi
    else
        error "$inconsistent file(s) with namespace issues"
    fi
    
    echo ""
}

# Validate git repository
validate_git_repository() {
    echo "${BOLD}Git Repository${NC}"
    
    check
    if [ ! -d ".git" ]; then
        error "Git repository not initialized"
        fixable "Run: git init"
        echo ""
        return
    fi
    pass "Git repository initialized"
    
    # Check for remote
    check
    local remote_url=$(git remote get-url origin 2>/dev/null || echo "")
    if [ -z "$remote_url" ]; then
        error "Git remote not configured"
        fixable "Add git remote: git remote add origin <url>"
    else
        pass "Remote configured: $remote_url"
        
        # Compare with package.yaml
        local package_repo=$(yaml_get "package.yaml" "repository" 2>/dev/null || echo "")
        check
        if [ "$remote_url" = "$package_repo" ] || [ "${remote_url}.git" = "$package_repo" ]; then
            pass "Remote URL matches package.yaml"
        else
            warning "Remote URL mismatch:"
            echo "    Git remote: $remote_url"
            echo "    package.yaml: $package_repo"
            fixable "Update package.yaml repository field"
        fi
    fi
    
    echo ""
}

# Validate README.md
validate_readme() {
    echo "${BOLD}README.md${NC}"
    
    check
    if [ ! -f "README.md" ]; then
        error "README.md not found"
        fixable "Create README.md with package information"
        echo ""
        return
    fi
    pass "README.md exists"
    
    # Check for required sections
    local required_sections=("What's Included" "Installation" "License")
    for section in "${required_sections[@]}"; do
        check
        if grep -qi "## $section" README.md || grep -qi "# $section" README.md; then
            pass "Has '$section' section"
        else
            warning "Missing '$section' section in README.md"
            fixable "Add '$section' section to README.md"
        fi
    done
    
    echo ""
}

# Test installation
test_installation() {
    echo "${BLUE}🧪 Test Installation${NC}"
    echo ""
    
    local test_dir="/tmp/acp-validate-test-$(date +%s)"
    
    check
    echo "  Creating test directory: $test_dir"
    mkdir -p "$test_dir/agent/"{patterns,commands,design}
    
    # Create minimal manifest
    cat > "$test_dir/agent/manifest.yaml" << 'EOF'
packages: {}
manifest_version: 1.0.0
last_updated: null
EOF
    
    pass "Test directory created"
    
    # Try to install package
    check
    echo "  Installing package from current directory..."
    local current_dir=$(pwd)
    
    if cd "$test_dir" && "${current_dir}/agent/scripts/acp.package-install.sh" "$current_dir" --yes >/dev/null 2>&1; then
        pass "Package installed successfully"
        
        # Verify files were copied
        check
        local installed_files=$(find agent/ -name "*.md" -not -name "*.template.md" 2>/dev/null | wc -l)
        if [ "$installed_files" -gt 0 ]; then
            pass "Verified $installed_files file(s) copied"
        else
            error "No files were installed"
        fi
        
        # Verify manifest updated
        check
        if grep -q "packages:" agent/manifest.yaml && grep -q "$PACKAGE_NAME:" agent/manifest.yaml; then
            pass "Manifest updated correctly"
        else
            warning "Manifest may not have been updated correctly"
        fi
    else
        error "Package installation failed"
        echo "  ${YELLOW}This may indicate issues with package structure or install script${NC}"
    fi
    
    # Cleanup
    cd "$current_dir"
    rm -rf "$test_dir"
    pass "Test directory cleaned up"
    
    echo ""
}

# Check remote availability
check_remote_availability() {
    echo "${BLUE}🌐 Remote Availability${NC}"
    echo ""
    
    local repo_url=$(yaml_get "package.yaml" "repository" 2>/dev/null || echo "")
    
    if [ -z "$repo_url" ]; then
        check
        error "Repository URL not found in package.yaml"
        echo ""
        return
    fi
    
    echo "  Checking: $repo_url"
    
    check
    if git ls-remote "$repo_url" HEAD >/dev/null 2>&1; then
        pass "Remote repository accessible"
        
        # Get latest commit
        local latest_commit=$(git ls-remote "$repo_url" HEAD 2>/dev/null | cut -f1 | cut -c1-8)
        if [ -n "$latest_commit" ]; then
            pass "Latest commit: $latest_commit"
        fi
    else
        warning "Remote repository not accessible"
        echo "  ${YELLOW}This may be normal if repository is not yet created${NC}"
        echo "  ${YELLOW}Ensure repository exists before publishing${NC}"
    fi
    
    echo ""
}

# Generate validation report
generate_report() {
    echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "${BOLD}📊 Validation Summary${NC}"
    echo ""
    echo "Total Checks: $TOTAL_CHECKS"
    echo "Passed: $PASSED_CHECKS"
    echo "Warnings: ${#WARNINGS[@]}"
    echo "Errors: ${#ERRORS[@]}"
    echo ""
    
    # Calculate score (clean checks / total * 100)
    # Clean checks = checks that passed without errors or warnings
    local score=0
    if [ "$TOTAL_CHECKS" -gt 0 ]; then
        local clean_checks=$((TOTAL_CHECKS - ${#ERRORS[@]} - ${#WARNINGS[@]}))
        if [ "$clean_checks" -lt 0 ]; then
            clean_checks=0
        fi
        score=$((clean_checks * 100 / TOTAL_CHECKS))
    fi
    
    # Determine status
    if [ "${#ERRORS[@]}" -eq 0 ]; then
        if [ "${#WARNINGS[@]}" -eq 0 ]; then
            echo "Overall Status: ${GREEN}✅ PASS${NC}"
        else
            echo "Overall Status: ${YELLOW}✅ PASS WITH WARNINGS${NC}"
        fi
    else
        echo "Overall Status: ${RED}❌ FAIL${NC}"
    fi
    
    echo "Validation Score: ${score}%"
    echo ""
}

# Display issues
display_issues() {
    if [ "${#ERRORS[@]}" -gt 0 ]; then
        echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "${RED}❌ Errors Found (${#ERRORS[@]})${NC}"
        echo ""
        local i=1
        for err in "${ERRORS[@]}"; do
            echo "  $i. $err"
            i=$((i + 1))
        done
        echo ""
    fi
    
    if [ "${#WARNINGS[@]}" -gt 0 ]; then
        echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "${YELLOW}⚠️  Warnings (${#WARNINGS[@]})${NC}"
        echo ""
        local i=1
        for warn in "${WARNINGS[@]}"; do
            echo "  $i. $warn"
            i=$((i + 1))
        done
        echo ""
    fi
}

# Display fixable issues
display_fixable_issues() {
    if [ "${#FIXABLE_ISSUES[@]}" -gt 0 ]; then
        echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "${BOLD}🔧 Fixable Issues (${#FIXABLE_ISSUES[@]})${NC}"
        echo ""
        echo "The following issues can be fixed automatically:"
        echo ""
        local i=1
        for issue in "${FIXABLE_ISSUES[@]}"; do
            echo "  $i. $issue"
            i=$((i + 1))
        done
        echo ""
        echo "${YELLOW}Note: Auto-fix requires LLM agent context.${NC}"
        echo "Run this command via agent (e.g., in chat) to enable auto-fix."
        echo ""
    fi
}

# Main validation function
main() {
    echo "${BLUE}🔍 ACP Package Validation${NC}"
    echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Check package context
    check_package_context
    
    # Run shell validations
    validate_yaml_structure
    validate_file_existence
    check_unlisted_files
    validate_namespace_consistency
    validate_git_repository
    validate_readme
    
    # Test installation
    test_installation
    
    # Check remote availability
    check_remote_availability
    
    # Generate report
    generate_report
    
    # Display issues
    display_issues
    
    # Display fixable issues
    display_fixable_issues
    
    # Exit with appropriate code
    if [ "${#ERRORS[@]}" -gt 0 ]; then
        echo "${RED}Validation failed. Fix errors and run again.${NC}"
        echo ""
        exit 1
    else
        if [ "${#WARNINGS[@]}" -gt 0 ]; then
            echo "${GREEN}✅ Package validation passed with warnings.${NC}"
            echo ""
            echo "Recommendations:"
            echo "  - Address warnings before publishing"
            echo "  - Run @acp.package-publish when ready"
            echo ""
        else
            echo "${GREEN}✅ Package validation passed!${NC}"
            echo ""
            echo "Your package is ready to publish."
            echo "Run: @acp.package-publish"
            echo ""
        fi
        exit 0
    fi
}

# Run main function
main "$@"
