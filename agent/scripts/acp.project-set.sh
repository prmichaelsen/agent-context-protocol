#!/usr/bin/env bash
# ACP Project Set - Switch to a different project
# Sets current project in registry and changes to project directory

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities
source "${SCRIPT_DIR}/acp.common.sh"

# Source YAML parser
source_yaml_parser

# Usage information
usage() {
  cat << EOF
Usage: acp.project-set.sh <project-name>

Switch to a different project in the global registry.

Arguments:
  project-name    Name of the project to switch to

Examples:
  acp.project-set.sh remember-mcp-server
  acp.project-set.sh agentbase-mcp-server

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
    echo "Run '@acp.project-create' to create your first project"
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
  
  # Validate project directory exists
  if [ ! -d "$project_path" ]; then
    echo "Error: Project directory not found: $project_path"
    echo "Project may have been moved or deleted"
    echo ""
    echo "To fix:"
    echo "  1. Update project path: @acp.project-update ${project_name} --path <new-path>"
    echo "  2. Or remove from registry: @acp.project-remove ${project_name}"
    exit 1
  fi
  
  # Get project metadata
  local project_type=$(yaml_query ".projects.${project_name}.type")
  local project_description=$(yaml_query ".projects.${project_name}.description")
  
  # Re-parse for yaml_set operations (yaml_query cleans up AST)
  yaml_parse "$registry_path"
  
  # Update current_project in registry
  yaml_set "current_project" "$project_name"
  
  # Update last_accessed timestamp
  local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  yaml_set "projects.${project_name}.last_accessed" "$timestamp"
  
  # Update registry last_updated
  yaml_set "last_updated" "$timestamp"
  
  # Write changes
  yaml_write "$registry_path"
  
  # Report success
  echo "✓ Switched to project: ${project_name}"
  echo "  Path: ${project_path}"
  echo "  Type: ${project_type}"
  if [ -n "$project_description" ]; then
    echo "  Description: ${project_description}"
  fi
  echo ""
  echo "You are now in the project directory. All file operations will be relative to:"
  echo "  ${project_path}"
  echo ""
  echo "Run '@acp.init' to load project context"
  
  # Change to project directory (only if running interactively, not in tests)
  # Note: cd in a script only affects the script's process, not the parent shell
  # For interactive use, this script should be sourced or wrapped
  if [ -t 0 ]; then
    cd "$project_path" 2>/dev/null || true
  fi
}

# Parse arguments
if [ $# -eq 0 ]; then
  usage
fi

PROJECT_NAME="$1"

# Run main function
main "$PROJECT_NAME"
