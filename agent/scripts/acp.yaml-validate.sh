#!/bin/bash
# ACP YAML Schema Validator
# Pure bash YAML validation against schema definitions
# Zero external dependencies

# Source YAML parser (using new generic AST-based parser)
SCRIPT_DIR="$(dirname "$0")"
. "${SCRIPT_DIR}/acp.yaml-parser.sh"
. "${SCRIPT_DIR}/acp.common.sh"

# Initialize colors
init_colors

# Validation error tracking
VALIDATION_ERRORS=0
VALIDATION_WARNINGS=0

# Add validation error
# Usage: add_error "Error message"
add_error() {
    echo "${RED}❌ $1${NC}" >&2
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
}

# Add validation warning
# Usage: add_warning "Warning message"
add_warning() {
    echo "${YELLOW}⚠️  $1${NC}" >&2
    VALIDATION_WARNINGS=$((VALIDATION_WARNINGS + 1))
}

# Validate field exists
# Usage: validate_field_exists "file.yaml" "field.path"
validate_field_exists() {
    local yaml_file="$1"
    local field_path="$2"
    
    if ! yaml_has_key "$yaml_file" "$field_path"; then
        return 1
    fi
    return 0
}

# Validate string pattern (regex)
# Usage: validate_pattern "value" "pattern" "field_name"
validate_pattern() {
    local value="$1"
    local pattern="$2"
    local field_name="$3"
    
    if ! echo "$value" | grep -qE "$pattern"; then
        return 1
    fi
    return 0
}

# Validate string length
# Usage: validate_length "value" min max "field_name"
validate_length() {
    local value="$1"
    local min="$2"
    local max="$3"
    local field_name="$4"
    
    local length=${#value}
    
    if [ -n "$min" ] && [ "$length" -lt "$min" ]; then
        add_error "Field '$field_name': Too short (minimum $min characters, got $length)"
        return 1
    fi
    
    if [ -n "$max" ] && [ "$length" -gt "$max" ]; then
        add_error "Field '$field_name': Too long (maximum $max characters, got $length)"
        return 1
    fi
    
    return 0
}

# Validate package.yaml file
# Usage: validate_package_yaml "package.yaml"
# Returns: 0 if valid, 1 if invalid
validate_package_yaml() {
    local yaml_file="$1"
    
    if [ ! -f "$yaml_file" ]; then
        add_error "File not found: $yaml_file"
        return 1
    fi
    
    echo "${BLUE}Validating $yaml_file...${NC}"
    echo ""
    
    # Check YAML syntax (try to parse)
    if ! yaml_get "$yaml_file" "name" >/dev/null 2>&1; then
        add_error "Invalid YAML syntax in $yaml_file"
        return 1
    fi
    
    # Validate required fields
    local required_fields="name version description author license repository"
    for field in $required_fields; do
        if ! validate_field_exists "$yaml_file" "$field"; then
            add_error "Required field missing: '$field'"
        fi
    done
    
    # Validate name field
    if validate_field_exists "$yaml_file" "name"; then
        local name=$(yaml_get "$yaml_file" "name")
        if ! validate_pattern "$name" "^[a-z0-9-]+$" "name"; then
            add_error "Field 'name': Must be lowercase letters, numbers, and hyphens only (got: '$name')"
        fi
        
        # Check reserved names
        case "$name" in
            acp|local|core|system|global)
                add_error "Field 'name': '$name' is a reserved package name"
                ;;
        esac
    fi
    
    # Validate version field
    if validate_field_exists "$yaml_file" "version"; then
        local version=$(yaml_get "$yaml_file" "version")
        if ! validate_pattern "$version" "^[0-9]+\\.[0-9]+\\.[0-9]+$" "version"; then
            add_error "Field 'version': Must be semantic version format X.Y.Z (got: '$version')"
        fi
    fi
    
    # Validate description field
    if validate_field_exists "$yaml_file" "description"; then
        local description=$(yaml_get "$yaml_file" "description")
        validate_length "$description" 10 200 "description"
    fi
    
    # Validate author field
    if validate_field_exists "$yaml_file" "author"; then
        local author=$(yaml_get "$yaml_file" "author")
        validate_length "$author" 2 "" "author"
    fi
    
    # Validate repository field
    if validate_field_exists "$yaml_file" "repository"; then
        local repository=$(yaml_get "$yaml_file" "repository")
        if ! validate_pattern "$repository" "^https?://.*\\.git$" "repository"; then
            add_error "Field 'repository': Must be a git URL ending with .git (got: '$repository')"
        fi
    fi
    
    # Validate homepage field (optional)
    if validate_field_exists "$yaml_file" "homepage"; then
        local homepage=$(yaml_get "$yaml_file" "homepage")
        if ! validate_pattern "$homepage" "^https?://.*" "homepage"; then
            add_error "Field 'homepage': Must be a valid HTTP/HTTPS URL (got: '$homepage')"
        fi
    fi
    
    # Validate contents field (required) - use grep since yaml_has_key may not work for nested objects
    if ! grep -q "^contents:" "$yaml_file"; then
        add_error "Required field missing: 'contents'"
    fi
    
    # Validate requires.acp field (optional)
    if validate_field_exists "$yaml_file" "requires.acp"; then
        local acp_version=$(yaml_get "$yaml_file" "requires.acp")
        if ! validate_pattern "$acp_version" "^>=?[0-9]+\\.[0-9]+\\.[0-9]+$" "requires.acp"; then
            add_error "Field 'requires.acp': Must be version constraint like '>=2.0.0' (got: '$acp_version')"
        fi
    fi
    
    # Report results
    echo ""
    if [ "$VALIDATION_ERRORS" -eq 0 ]; then
        echo "${GREEN}✅ Validation passed${NC}"
        if [ "$VALIDATION_WARNINGS" -gt 0 ]; then
            echo "${YELLOW}⚠️  $VALIDATION_WARNINGS warning(s)${NC}"
        fi
        return 0
    else
        echo "${RED}❌ Validation failed${NC}"
        echo "${RED}   $VALIDATION_ERRORS error(s)${NC}"
        if [ "$VALIDATION_WARNINGS" -gt 0 ]; then
            echo "${YELLOW}   $VALIDATION_WARNINGS warning(s)${NC}"
        fi
        return 1
    fi
}

# Main function for standalone execution
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    # Script is being executed directly
    if [ $# -eq 0 ]; then
        echo "Usage: $0 <yaml-file>"
        echo ""
        echo "Example:"
        echo "  $0 package.yaml"
        exit 1
    fi
    
    validate_package_yaml "$1"
    exit $?
fi

# Script is being sourced, functions are available
