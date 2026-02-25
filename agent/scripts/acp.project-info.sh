#!/usr/bin/env bash
# acp.project-info.sh - Display detailed project information from registry
# Part of Agent Context Protocol (ACP)
# Usage: ./acp.project-info.sh <project-name>

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities
source "${SCRIPT_DIR}/acp.common.sh"

# Source YAML parser
source_yaml_parser

# Main function
main() {
  local project_name="${1:-}"
  
  # Validate argument
  if [ -z "$project_name" ]; then
    echo "Error: Project name required"
    echo ""
    echo "Usage: $0 <project-name>"
    echo ""
    echo "Example:"
    echo "  $0 remember-mcp-server"
    echo ""
    echo "Run 'acp.project-list.sh' to see available projects"
    return 1
  fi
  
  # Get registry path
  local registry_path
  registry_path=$(get_projects_registry_path)
  
  # Check if registry exists
  if [ ! -f "$registry_path" ]; then
    echo "Error: Project registry not found at: $registry_path"
    echo ""
    echo "The registry may not be initialized yet."
    echo "Create a project with '@acp.project-create' to initialize the registry."
    return 1
  fi
  
  # Parse registry
  if ! yaml_parse "$registry_path"; then
    echo "Error: Failed to parse registry at: $registry_path" >&2
    return 1
  fi
  
  # Check if project exists by trying to query it
  local project_type
  project_type=$(yaml_query ".projects.${project_name}.type" 2>&1 || echo "")
  
  if [ -z "$project_type" ] || [ "$project_type" = "null" ] || echo "$project_type" | grep -q "Error:"; then
    echo "Error: Project '${project_name}' not found in registry"
    echo ""
    echo "Available projects:"
    
    # List available projects
    local projects
    projects=$(yaml_query ".projects" 2>/dev/null || echo "")
    
    if [ -z "$projects" ] || [ "$projects" = "null" ]; then
      echo "  (none)"
    else
      echo "$projects" | grep -E "^[a-zA-Z0-9_-]+:" | sed 's/:$//' | while read -r proj; do
        echo "  - $proj"
      done
    fi
    
    return 1
  fi
  
  # Extract project metadata
  local path type description status created last_modified last_accessed
  path=$(yaml_query ".projects.${project_name}.path")
  type=$(yaml_query ".projects.${project_name}.type")
  description=$(yaml_query ".projects.${project_name}.description")
  status=$(yaml_query ".projects.${project_name}.status")
  created=$(yaml_query ".projects.${project_name}.created")
  last_modified=$(yaml_query ".projects.${project_name}.last_modified")
  last_accessed=$(yaml_query ".projects.${project_name}.last_accessed")
  
  # Get optional fields
  local tags related_projects dependencies
  tags=$(yaml_query ".projects.${project_name}.tags" 2>/dev/null || echo "")
  related_projects=$(yaml_query ".projects.${project_name}.related_projects" 2>/dev/null || echo "")
  dependencies=$(yaml_query ".projects.${project_name}.dependencies" 2>/dev/null || echo "")
  
  # Check if this is the current project
  local current_project
  current_project=$(yaml_query ".current_project" 2>/dev/null || echo "")
  local is_current=""
  if [ "$current_project" = "$project_name" ]; then
    is_current=" ⭐ Current"
  fi
  
  # Display project information
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "📦 ${project_name}${is_current}"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  # Basic information
  echo "Type: ${type}"
  echo "Status: ${status}"
  echo "Path: ${path}"
  echo ""
  echo "Description:"
  echo "  ${description}"
  echo ""
  
  # Timestamps
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Timestamps:"
  echo "  Created: ${created}"
  echo "  Last Modified: ${last_modified}"
  echo "  Last Accessed: ${last_accessed}"
  echo ""
  
  # Tags (if present)
  if [ -n "$tags" ] && [ "$tags" != "null" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Tags:"
    echo "$tags" | grep -v "^$" | sed 's/^/  - /'
    echo ""
  fi
  
  # Related projects (if present)
  if [ -n "$related_projects" ] && [ "$related_projects" != "null" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Related Projects:"
    echo "$related_projects" | grep -v "^$" | sed 's/^/  - /'
    echo ""
  fi
  
  # Dependencies (if present)
  if [ -n "$dependencies" ] && [ "$dependencies" != "null" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Dependencies:"
    
    # Check for npm dependencies
    local npm_deps
    npm_deps=$(yaml_query ".projects.${project_name}.dependencies.npm")
    if [ -n "$npm_deps" ] && [ "$npm_deps" != "null" ]; then
      echo "  npm:"
      echo "$npm_deps" | grep -v "^$" | sed 's/^/    - /'
    fi
    
    # Check for pip dependencies
    local pip_deps
    pip_deps=$(yaml_query ".projects.${project_name}.dependencies.pip")
    if [ -n "$pip_deps" ] && [ "$pip_deps" != "null" ]; then
      echo "  pip:"
      echo "$pip_deps" | grep -v "^$" | sed 's/^/    - /'
    fi
    
    # Check for cargo dependencies
    local cargo_deps
    cargo_deps=$(yaml_query ".projects.${project_name}.dependencies.cargo")
    if [ -n "$cargo_deps" ] && [ "$cargo_deps" != "null" ]; then
      echo "  cargo:"
      echo "$cargo_deps" | grep -v "^$" | sed 's/^/    - /'
    fi
    
    # Check for go dependencies
    local go_deps
    go_deps=$(yaml_query ".projects.${project_name}.dependencies.go")
    if [ -n "$go_deps" ] && [ "$go_deps" != "null" ]; then
      echo "  go:"
      echo "$go_deps" | grep -v "^$" | sed 's/^/    - /'
    fi
    
    echo ""
  fi
  
  # Directory status
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  # Expand tilde in path
  local expanded_path="${path/#\~/$HOME}"
  
  if [ -d "$expanded_path" ]; then
    echo "✅ Project directory exists"
    
    # Check if it's an ACP project
    if [ -f "${expanded_path}/AGENT.md" ]; then
      echo "✅ ACP project (AGENT.md found)"
      
      # Try to read version from AGENT.md
      if [ -f "${expanded_path}/agent/progress.yaml" ]; then
        local project_version
        yaml_parse "${expanded_path}/agent/progress.yaml"
        project_version=$(yaml_query ".project.version")
        if [ -n "$project_version" ] && [ "$project_version" != "null" ]; then
          echo "   Version: ${project_version}"
        fi
      fi
    else
      echo "⚠️  Not an ACP project (AGENT.md not found)"
    fi
  else
    echo "❌ Project directory not found: ${expanded_path}"
    echo "   The project may have been moved or deleted"
  fi
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}

# Execute main function
main "$@"
