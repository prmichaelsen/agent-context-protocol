#!/usr/bin/env bash
# ACP Project Remove - Remove project from registry
# Optionally delete project directory from filesystem

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities
source "${SCRIPT_DIR}/acp.common.sh"

# Source YAML parser
source_yaml_parser

# Default flags
DELETE_FILES=false
AUTO_CONFIRM=false

# Usage information
usage() {
  cat << EOF
Usage: acp.project-remove.sh <project-name> [options]

Remove a project from the global registry.

Arguments:
  project-name    Name of the project to remove

Options:
  --delete-files  Also delete the project directory from filesystem
  -y, --yes       Auto-confirm without prompting
  -h, --help      Show this help message

Examples:
  acp.project-remove.sh old-project
  acp.project-remove.sh old-project --delete-files
  acp.project-remove.sh old-project --delete-files -y

EOF
  exit 1
}

# Main function
main() {
  local project_name="$1"
  
  # Get registry path
  local registry_path=$(get_projects_registry_path)
  
  # Check if registry exists
  if [ ! -f "$registry_path" ]; then
    echo "Error: Project registry not found at: $registry_path"
    echo "No projects to remove"
    exit 1
  fi
  
  # Parse registry (sets global AST)
  yaml_parse "$registry_path"
  
  # Check if project exists in registry
  local project_path=$(yaml_query ".projects.${project_name}.path" 2>/dev/null || echo "")
  
  if [ -z "$project_path" ]; then
    echo "Error: Project '${project_name}' not found in registry"
    echo ""
    echo "Available projects:"
    
    # List available projects
    local projects=$(yaml_query ".projects" 2>/dev/null | grep -E "^[a-zA-Z0-9_-]+:" | sed 's/:$//' || echo "")
    
    if [ -n "$projects" ]; then
      echo "$projects" | while read -r proj; do
        echo "  - $proj"
      done
    else
      echo "  (none)"
    fi
    
    echo ""
    echo "Run '@acp.project-list' to see all projects"
    exit 1
  fi
  
  # Expand tilde in path
  project_path="${project_path/#\~/$HOME}"
  
  # Get current project
  local current_project=$(yaml_query ".current_project" 2>/dev/null || echo "")
  local is_current=false
  
  if [ "$current_project" = "$project_name" ]; then
    is_current=true
  fi
  
  # Get project metadata for display
  local project_type=$(yaml_query ".projects.${project_name}.type" 2>/dev/null || echo "unknown")
  local project_description=$(yaml_query ".projects.${project_name}.description" 2>/dev/null || echo "")
  local dir_exists=false
  
  if [ -d "$project_path" ]; then
    dir_exists=true
  fi
  
  # Display what will be removed
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Project to Remove"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Name: ${project_name}"
  echo "Type: ${project_type}"
  if [ -n "$project_description" ]; then
    echo "Description: ${project_description}"
  fi
  echo "Path: ${project_path}"
  
  if [ "$is_current" = true ]; then
    echo ""
    echo "⚠️  WARNING: This is the CURRENT project"
  fi
  
  if [ "$dir_exists" = true ]; then
    echo ""
    if [ "$DELETE_FILES" = true ]; then
      echo "⚠️  WARNING: Project directory will be DELETED from filesystem"
    else
      echo "ℹ️  Project directory will be kept (use --delete-files to remove)"
    fi
  else
    echo ""
    echo "ℹ️  Project directory not found (already deleted or moved)"
  fi
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  # Confirm removal
  if [ "$AUTO_CONFIRM" = false ]; then
    echo -n "Remove this project from registry? [y/N] "
    read -r response
    
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
      echo "Cancelled"
      exit 0
    fi
    
    # Additional confirmation for file deletion
    if [ "$DELETE_FILES" = true ] && [ "$dir_exists" = true ]; then
      echo ""
      echo "⚠️  DANGER: You are about to DELETE the project directory:"
      echo "  ${project_path}"
      echo ""
      echo -n "Are you ABSOLUTELY SURE? Type 'DELETE' to confirm: "
      read -r confirm_delete
      
      if [ "$confirm_delete" != "DELETE" ]; then
        echo "Cancelled - directory will not be deleted"
        DELETE_FILES=false
      fi
    fi
  fi
  
  # Delete project directory if requested
  if [ "$DELETE_FILES" = true ] && [ "$dir_exists" = true ]; then
    echo ""
    echo "Deleting project directory..."
    rm -rf "$project_path"
    echo "✓ Deleted: ${project_path}"
  fi
  
  # Re-parse registry for removal operations
  yaml_parse "$registry_path"
  
  # Remove project from registry using sed (yaml_set doesn't support deletion)
  # We'll use a temporary file approach
  local temp_file=$(mktemp)
  
  # Use awk to remove the project section
  awk -v proj="$project_name" '
    BEGIN { in_project = 0; indent_level = 0 }
    
    # Detect project start
    /^  [a-zA-Z0-9_-]+:/ {
      # Extract project name from line
      match($0, /^  ([a-zA-Z0-9_-]+):/, arr)
      if (arr[1] == proj) {
        in_project = 1
        indent_level = 2
        next
      } else {
        in_project = 0
      }
    }
    
    # Skip lines that are part of the project being removed
    in_project == 1 {
      # Check if this line is still part of the project (indented more than 2 spaces)
      if (match($0, /^    /)) {
        next
      } else if (match($0, /^  [a-zA-Z0-9_-]+:/)) {
        # New project started, stop skipping
        in_project = 0
      } else if (match($0, /^[a-zA-Z]/)) {
        # New top-level key, stop skipping
        in_project = 0
      }
    }
    
    # Print all other lines
    in_project == 0 { print }
  ' "$registry_path" > "$temp_file"
  
  # Replace registry with updated version
  mv "$temp_file" "$registry_path"
  
  # Update current_project if we removed the current project
  if [ "$is_current" = true ]; then
    yaml_parse "$registry_path"
    yaml_set "current_project" ""
    
    # Update timestamp
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    yaml_set "last_updated" "$timestamp"
    
    yaml_write "$registry_path"
  else
    # Just update timestamp
    yaml_parse "$registry_path"
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    yaml_set "last_updated" "$timestamp"
    yaml_write "$registry_path"
  fi
  
  # Report success
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Project Removed"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Removed from registry: ${project_name}"
  
  if [ "$DELETE_FILES" = true ] && [ "$dir_exists" = true ]; then
    echo "Deleted from filesystem: ${project_path}"
  elif [ "$dir_exists" = true ]; then
    echo "Directory preserved: ${project_path}"
  fi
  
  if [ "$is_current" = true ]; then
    echo ""
    echo "⚠️  This was the current project"
    echo "Run '@acp.project-set <name>' to switch to another project"
  fi
  
  echo ""
  echo "Run '@acp.project-list' to see remaining projects"
}

# Parse arguments
if [ $# -eq 0 ]; then
  usage
fi

PROJECT_NAME=""

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      ;;
    --delete-files)
      DELETE_FILES=true
      shift
      ;;
    -y|--yes)
      AUTO_CONFIRM=true
      shift
      ;;
    -*)
      echo "Error: Unknown option: $1"
      usage
      ;;
    *)
      if [ -z "$PROJECT_NAME" ]; then
        PROJECT_NAME="$1"
      else
        echo "Error: Multiple project names provided"
        usage
      fi
      shift
      ;;
  esac
done

# Validate project name provided
if [ -z "$PROJECT_NAME" ]; then
  echo "Error: Project name required"
  usage
fi

# Run main function
main "$PROJECT_NAME"
