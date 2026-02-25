#!/usr/bin/env bash
# acp.project-update.sh - Update project metadata in registry
# Part of Agent Context Protocol (ACP)
# Usage: ./acp.project-update.sh <project-name> [options]

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities
source "${SCRIPT_DIR}/acp.common.sh"

# Source YAML parser
source_yaml_parser

# Parse command line arguments
parse_args() {
  PROJECT_NAME=""
  UPDATE_STATUS=""
  UPDATE_DESCRIPTION=""
  UPDATE_TYPE=""
  ADD_TAGS=()
  REMOVE_TAGS=()
  ADD_RELATED=()
  REMOVE_RELATED=()
  
  while [[ $# -gt 0 ]]; do
    case $1 in
      --status)
        UPDATE_STATUS="$2"
        shift 2
        ;;
      --description)
        UPDATE_DESCRIPTION="$2"
        shift 2
        ;;
      --type)
        UPDATE_TYPE="$2"
        shift 2
        ;;
      --add-tag)
        ADD_TAGS+=("$2")
        shift 2
        ;;
      --remove-tag)
        REMOVE_TAGS+=("$2")
        shift 2
        ;;
      --add-related)
        ADD_RELATED+=("$2")
        shift 2
        ;;
      --remove-related)
        REMOVE_RELATED+=("$2")
        shift 2
        ;;
      -*)
        echo "Error: Unknown option: $1"
        return 1
        ;;
      *)
        if [ -z "$PROJECT_NAME" ]; then
          PROJECT_NAME="$1"
        else
          echo "Error: Multiple project names provided"
          return 1
        fi
        shift
        ;;
    esac
  done
}

# Main function
main() {
  # Parse arguments
  parse_args "$@"
  
  # Validate project name
  if [ -z "$PROJECT_NAME" ]; then
    echo "Error: Project name required"
    echo ""
    echo "Usage: $0 <project-name> [options]"
    echo ""
    echo "Options:"
    echo "  --status <status>           Update project status (active|archived|paused)"
    echo "  --description <text>        Update project description"
    echo "  --type <type>               Update project type"
    echo "  --add-tag <tag>             Add a tag (can be used multiple times)"
    echo "  --remove-tag <tag>          Remove a tag (can be used multiple times)"
    echo "  --add-related <project>     Add related project (can be used multiple times)"
    echo "  --remove-related <project>  Remove related project (can be used multiple times)"
    echo ""
    echo "Examples:"
    echo "  $0 my-project --status archived"
    echo "  $0 my-project --add-tag production --add-tag critical"
    echo "  $0 my-project --description 'Updated description'"
    return 1
  fi
  
  # Check if any updates specified
  if [ -z "$UPDATE_STATUS" ] && [ -z "$UPDATE_DESCRIPTION" ] && [ -z "$UPDATE_TYPE" ] && \
     [ ${#ADD_TAGS[@]} -eq 0 ] && [ ${#REMOVE_TAGS[@]} -eq 0 ] && \
     [ ${#ADD_RELATED[@]} -eq 0 ] && [ ${#REMOVE_RELATED[@]} -eq 0 ]; then
    echo "Error: No updates specified"
    echo ""
    echo "Provide at least one update option (--status, --description, --type, --add-tag, etc.)"
    echo "Run '$0 --help' for usage information"
    return 1
  fi
  
  # Get registry path
  local registry_path
  registry_path=$(get_projects_registry_path)
  
  # Check if registry exists
  if [ ! -f "$registry_path" ]; then
    echo "Error: Project registry not found at: $registry_path"
    return 1
  fi
  
  # Parse registry
  yaml_parse "$registry_path" || {
    echo "Error: Failed to parse registry"
    return 1
  }
  
  # Check if project exists by trying to query it
  local project_type_check
  project_type_check=$(yaml_query ".projects.${PROJECT_NAME}.type" 2>/dev/null || echo "")
  
  if [ -z "$project_type_check" ] || [ "$project_type_check" = "null" ]; then
    echo "Error: Project '${PROJECT_NAME}' not found in registry"
    echo ""
    echo "Run 'acp.project-list.sh' to see available projects"
    return 1
  fi
  
  echo ""
  echo "Updating project: ${PROJECT_NAME}"
  echo ""
  
  # Track what was updated
  local updates_made=0
  
  # Update status
  if [ -n "$UPDATE_STATUS" ]; then
    # Validate status value
    if [[ ! "$UPDATE_STATUS" =~ ^(active|archived|paused)$ ]]; then
      echo "Error: Invalid status '${UPDATE_STATUS}'"
      echo "Valid values: active, archived, paused"
      return 1
    fi
    
    yaml_set ".projects.${PROJECT_NAME}.status" "$UPDATE_STATUS"
    echo "✓ Updated status: ${UPDATE_STATUS}"
    updates_made=$((updates_made + 1))
  fi
  
  # Update description
  if [ -n "$UPDATE_DESCRIPTION" ]; then
    yaml_set ".projects.${PROJECT_NAME}.description" "$UPDATE_DESCRIPTION"
    echo "✓ Updated description"
    updates_made=$((updates_made + 1))
  fi
  
  # Update type
  if [ -n "$UPDATE_TYPE" ]; then
    yaml_set ".projects.${PROJECT_NAME}.type" "$UPDATE_TYPE"
    echo "✓ Updated type: ${UPDATE_TYPE}"
    updates_made=$((updates_made + 1))
  fi
  
  # Add tags
  if [ ${#ADD_TAGS[@]} -gt 0 ]; then
    for tag in "${ADD_TAGS[@]}"; do
      # Get current tags
      local current_tags
      current_tags=$(yaml_query ".projects.${PROJECT_NAME}.tags" 2>/dev/null || echo "")
      
      # Check if tag already exists
      if [ -n "$current_tags" ] && [ "$current_tags" != "null" ] && echo "$current_tags" | grep -q "^${tag}$"; then
        echo "⊘ Tag already exists: ${tag}"
      else
        # Ensure tags field exists (create empty array if missing)
        if [ -z "$current_tags" ] || [ "$current_tags" = "null" ]; then
          local registry_path
          registry_path=$(get_projects_registry_path)
          sed -i "/^  ${PROJECT_NAME}:/a\\    tags: []" "$registry_path"
          yaml_parse "$registry_path"
        fi

        # Use yaml_array_append to add tag
        if yaml_array_append ".projects.${PROJECT_NAME}.tags" "$tag" 2>/dev/null; then
          echo "✓ Added tag: ${tag}"
          updates_made=$((updates_made + 1))
        else
          echo "⚠️  Warning: Failed to add tag: ${tag}"
        fi
      fi
    done
  fi
  
  # Remove tags
  if [ ${#REMOVE_TAGS[@]} -gt 0 ]; then
    for tag in "${REMOVE_TAGS[@]}"; do
      # Get current tags
      local current_tags
      current_tags=$(yaml_query ".projects.${PROJECT_NAME}.tags" 2>/dev/null || echo "")
      
      # Check if tag exists
      if ! echo "$current_tags" | grep -q "^${tag}$"; then
        echo "⊘ Tag not found: ${tag}"
      else
        # Remove tag by rebuilding array
        local new_tags
        new_tags=$(echo "$current_tags" | grep -v "^${tag}$")
        
        # Clear existing tags
        yaml_set ".projects.${PROJECT_NAME}.tags" "[]"
        
        # Re-add remaining tags
        local idx=0
        while IFS= read -r remaining_tag; do
          if [ -n "$remaining_tag" ]; then
            yaml_set ".projects.${PROJECT_NAME}.tags[${idx}]" "$remaining_tag"
            idx=$((idx + 1))
          fi
        done <<< "$new_tags"
        
        echo "✓ Removed tag: ${tag}"
        updates_made=$((updates_made + 1))
      fi
    done
  fi
  
  # Add related projects
  if [ ${#ADD_RELATED[@]} -gt 0 ]; then
    for related in "${ADD_RELATED[@]}"; do
      # Get current related projects
      local current_related
      current_related=$(yaml_query ".projects.${PROJECT_NAME}.related_projects" 2>/dev/null || echo "")
      
      # Check if already exists
      if [ -n "$current_related" ] && [ "$current_related" != "null" ] && echo "$current_related" | grep -q "^${related}$"; then
        echo "⊘ Related project already exists: ${related}"
      else
        # Use yaml_array_append to add related project
        if yaml_array_append ".projects.${PROJECT_NAME}.related_projects" "$related" 2>/dev/null; then
          echo "✓ Added related project: ${related}"
          updates_made=$((updates_made + 1))
        else
          echo "⚠️  Warning: Failed to add related project: ${related}"
        fi
      fi
    done
  fi
  
  # Remove related projects
  if [ ${#REMOVE_RELATED[@]} -gt 0 ]; then
    for related in "${REMOVE_RELATED[@]}"; do
      # Get current related projects
      local current_related
      current_related=$(yaml_query ".projects.${PROJECT_NAME}.related_projects" 2>/dev/null || echo "")
      
      # Check if exists
      if ! echo "$current_related" | grep -q "^${related}$"; then
        echo "⊘ Related project not found: ${related}"
      else
        # Remove by rebuilding array
        local new_related
        new_related=$(echo "$current_related" | grep -v "^${related}$")
        
        # Clear existing
        yaml_set ".projects.${PROJECT_NAME}.related_projects" "[]"
        
        # Re-add remaining
        local idx=0
        while IFS= read -r remaining_related; do
          if [ -n "$remaining_related" ]; then
            yaml_set ".projects.${PROJECT_NAME}.related_projects[${idx}]" "$remaining_related"
            idx=$((idx + 1))
          fi
        done <<< "$new_related"
        
        echo "✓ Removed related project: ${related}"
        updates_made=$((updates_made + 1))
      fi
    done
  fi
  
  # Update last_modified timestamp
  local timestamp
  timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  yaml_set ".projects.${PROJECT_NAME}.last_modified" "$timestamp"
  
  # Update registry last_updated timestamp
  yaml_set ".last_updated" "$timestamp"
  
  # Write changes back to registry
  yaml_write "$registry_path"
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "✅ Project updated successfully!"
  echo "   Updates applied: ${updates_made}"
  echo "   Registry: ${registry_path}"
  echo ""
  echo "Run 'acp.project-info.sh ${PROJECT_NAME}' to see updated information"
  echo ""
}

# Execute main function
main "$@"
