#!/bin/bash
# Generic YAML Parser with AST
# Pure POSIX shell implementation
# Version: 1.0.0
# Created: 2026-02-21

# ============================================================================
# GLOBAL STATE
# ============================================================================

AST_FILE=""
AST_ROOT_ID=0
YAML_CURRENT_FILE=""

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

init_ast() {
    AST_FILE=$(mktemp)
    echo "0|map||root|-1|" > "$AST_FILE"
    AST_ROOT_ID=0
}

cleanup_ast() {
    if [ -n "$AST_FILE" ] && [ -f "$AST_FILE" ]; then
        rm -f "$AST_FILE"
    fi
}

get_next_node_id() {
    wc -l < "$AST_FILE"
}

create_node() {
    local type="$1"
    local key="$2"
    local value="$3"
    local parent_id="$4"
    
    key=$(echo "$key" | sed 's/|/\\|/g')
    value=$(echo "$value" | sed 's/|/\\|/g')
    
    local node_id
    node_id=$(get_next_node_id)
    
    echo "$node_id|$type|$key|$value|$parent_id|" >> "$AST_FILE"
    echo "$node_id"
}

get_node() {
    local node_id="$1"
    sed -n "$((node_id + 1))p" "$AST_FILE"
}

get_node_field() {
    local node_id="$1"
    local field_num="$2"
    get_node "$node_id" | cut -d'|' -f"$field_num"
}

add_child() {
    local parent_id="$1"
    local child_id="$2"
    
    local node
    node=$(get_node "$parent_id")
    
    local id type key value parent children
    id=$(echo "$node" | cut -d'|' -f1)
    type=$(echo "$node" | cut -d'|' -f2)
    key=$(echo "$node" | cut -d'|' -f3)
    value=$(echo "$node" | cut -d'|' -f4)
    parent=$(echo "$node" | cut -d'|' -f5)
    children=$(echo "$node" | cut -d'|' -f6)
    
    if [ -z "$children" ]; then
        children="$child_id"
    else
        children="$children,$child_id"
    fi
    
    local updated="$id|$type|$key|$value|$parent|$children"
    sed -i "$((parent_id + 1))s@.*@$updated@" "$AST_FILE"
}

update_node_type() {
    local node_id="$1"
    local new_type="$2"
    
    local node
    node=$(get_node "$node_id")
    
    local id type key value parent children
    id=$(echo "$node" | cut -d'|' -f1)
    key=$(echo "$node" | cut -d'|' -f3)
    value=$(echo "$node" | cut -d'|' -f4)
    parent=$(echo "$node" | cut -d'|' -f5)
    children=$(echo "$node" | cut -d'|' -f6)
    
    local updated="$id|$new_type|$key|$value|$parent|$children"
    sed -i "$((node_id + 1))s@.*@$updated@" "$AST_FILE"
}

# ============================================================================
# PARSER
# ============================================================================

yaml_parse() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        echo "Error: File not found: $file" >&2
        return 1
    fi
    
    cleanup_ast
    init_ast
    YAML_CURRENT_FILE="$file"
    
    # State tracking
    local parent_stack="0"
    local indent_stack="-1"
    local current_parent=0
    local prev_indent=-1
    local last_key_node=-1
    
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines
        [ -z "$line" ] && continue
        
        # Skip comment lines
        case "$line" in \#*) continue ;; esac
        
        # Strip inline comments
        line=$(echo "$line" | sed 's/#.*$//')
        
        # Calculate indentation
        local indent=0
        local trimmed="$line"
        while [ "$trimmed" != "${trimmed# }" ]; do
            indent=$((indent + 1))
            trimmed="${trimmed# }"
        done
        
        # Skip empty after trim
        [ -z "$trimmed" ] && continue
        
        # Handle dedent - pop stack
        while [ "$prev_indent" -ge 0 ] && [ "$indent" -le "$prev_indent" ]; do
            # Pop one level
            parent_stack=$(echo "$parent_stack" | sed 's/,[^,]*$//')
            indent_stack=$(echo "$indent_stack" | sed 's/,[^,]*$//')
            
            # Get new current parent
            current_parent=$(echo "$parent_stack" | awk -F',' '{print $NF}')
            prev_indent=$(echo "$indent_stack" | awk -F',' '{print $NF}')
            
            # Handle empty stack
            [ -z "$current_parent" ] && current_parent=0
            [ -z "$prev_indent" ] && prev_indent=-1
            
            last_key_node=-1
        done
        
        # Parse line content
        if echo "$trimmed" | grep -q '^-[[:space:]]'; then
            # Array item
            local item_content
            item_content=$(echo "$trimmed" | sed 's/^-[[:space:]]*//')
            
            # Convert last key node to array if needed
            if [ "$last_key_node" -ge 0 ]; then
                update_node_type "$last_key_node" "array"
                current_parent="$last_key_node"
                last_key_node=-1
            fi
            
            # Check if inline object (has colon on same line)
            if echo "$item_content" | grep -q ':'; then
                # Inline object: - name: value
                local obj_node
                obj_node=$(create_node "map" "" "" "$current_parent")
                add_child "$current_parent" "$obj_node"
                
                # Parse first field
                local key value
                key=$(echo "$item_content" | cut -d':' -f1 | sed 's/[[:space:]]*$//')
                value=$(echo "$item_content" | cut -d':' -f2- | sed 's/^[[:space:]]*//')
                
                local field_node
                field_node=$(create_node "scalar" "$key" "$value" "$obj_node")
                add_child "$obj_node" "$field_node"
                
                # Push object onto stack for potential additional fields
                parent_stack="$parent_stack,$obj_node"
                indent_stack="$indent_stack,$indent"
                current_parent="$obj_node"
                prev_indent="$indent"
            else
                # Simple array item: - value
                local item_node
                item_node=$(create_node "scalar" "" "$item_content" "$current_parent")
                add_child "$current_parent" "$item_node"
            fi
        elif echo "$trimmed" | grep -q ':'; then
            # Key-value pair
            local key value
            key=$(echo "$trimmed" | cut -d':' -f1 | sed 's/[[:space:]]*$//')
            value=$(echo "$trimmed" | cut -d':' -f2- | sed 's/^[[:space:]]*//')
            
            if [ -z "$value" ]; then
                # Key with no value - map or array follows
                local node_id
                node_id=$(create_node "map" "$key" "" "$current_parent")
                add_child "$current_parent" "$node_id"
                
                # Push onto stack
                parent_stack="$parent_stack,$node_id"
                indent_stack="$indent_stack,$indent"
                current_parent="$node_id"
                prev_indent="$indent"
                last_key_node="$node_id"
            else
                # Scalar value
                local node_id
                node_id=$(create_node "scalar" "$key" "$value" "$current_parent")
                add_child "$current_parent" "$node_id"
            fi
        fi
    done < "$file"
    
    return 0
}

# ============================================================================
# QUERY ENGINE
# ============================================================================

find_child_by_key() {
    local parent_id="$1"
    local key="$2"
    
    local children
    children=$(get_node_field "$parent_id" 6)
    
    [ -z "$children" ] && return 1
    
    local IFS=','
    for child_id in $children; do
        local child_key
        child_key=$(get_node_field "$child_id" 3)
        
        if [ "$child_key" = "$key" ]; then
            echo "$child_id"
            return 0
        fi
    done
    
    return 1
}

find_child_by_index() {
    local parent_id="$1"
    local index="$2"
    
    local children
    children=$(get_node_field "$parent_id" 6)
    
    [ -z "$children" ] && return 1
    
    local child_id
    child_id=$(echo "$children" | tr ',' '\n' | sed -n "$((index + 1))p")
    
    if [ -n "$child_id" ]; then
        echo "$child_id"
        return 0
    fi
    
    return 1
}

yaml_query() {
    local path="$1"
    
    if [ -z "$AST_FILE" ] || [ ! -f "$AST_FILE" ]; then
        echo "Error: No AST loaded. Call yaml_parse first." >&2
        return 1
    fi
    
    path=$(echo "$path" | sed 's/^\.//')
    
    local current_node="$AST_ROOT_ID"
    
    local IFS='.'
    for segment in $path; do
        if echo "$segment" | grep -q '\['; then
            local key index
            key=$(echo "$segment" | sed 's/\[.*//')
            index=$(echo "$segment" | sed 's/.*\[\([0-9]*\)\].*/\1/')
            
            current_node=$(find_child_by_key "$current_node" "$key")
            [ -z "$current_node" ] && return 1
            
            current_node=$(find_child_by_index "$current_node" "$index")
            [ -z "$current_node" ] && return 1
        else
            current_node=$(find_child_by_key "$current_node" "$segment")
            [ -z "$current_node" ] && return 1
        fi
    done
    
    get_node_field "$current_node" 4
}

yaml_set() {
    local path="$1"
    local new_value="$2"
    
    if [ -z "$AST_FILE" ] || [ ! -f "$AST_FILE" ]; then
        echo "Error: No AST loaded. Call yaml_parse first." >&2
        return 1
    fi
    
    path=$(echo "$path" | sed 's/^\.//')
    
    local current_node="$AST_ROOT_ID"
    local IFS='.'
    for segment in $path; do
        if echo "$segment" | grep -q '\['; then
            local key index
            key=$(echo "$segment" | sed 's/\[.*//')
            index=$(echo "$segment" | sed 's/.*\[\([0-9]*\)\].*/\1/')
            
            current_node=$(find_child_by_key "$current_node" "$key")
            [ -z "$current_node" ] && return 1
            
            current_node=$(find_child_by_index "$current_node" "$index")
            [ -z "$current_node" ] && return 1
        else
            current_node=$(find_child_by_key "$current_node" "$segment")
            [ -z "$current_node" ] && return 1
        fi
    done
    
    local node
    node=$(get_node "$current_node")
    
    local id type key value parent children
    id=$(echo "$node" | cut -d'|' -f1)
    type=$(echo "$node" | cut -d'|' -f2)
    key=$(echo "$node" | cut -d'|' -f3)
    parent=$(echo "$node" | cut -d'|' -f5)
    children=$(echo "$node" | cut -d'|' -f6)
    
    new_value=$(echo "$new_value" | sed 's/|/\\|/g')
    
    local updated="$id|$type|$key|$new_value|$parent|$children"
    sed -i "$((current_node + 1))s@.*@$updated@" "$AST_FILE"
}

yaml_write() {
    local output_file="$1"
    
    if [ -z "$AST_FILE" ] || [ ! -f "$AST_FILE" ]; then
        echo "Error: No AST loaded. Call yaml_parse first." >&2
        return 1
    fi
    
    serialize_node "$AST_ROOT_ID" 0 > "$output_file"
}

serialize_node() {
    local node_id="$1"
    local indent_level="$2"
    local parent_type="${3:-}"
    
    local node
    node=$(get_node "$node_id")
    
    local type key value children parent_id
    type=$(echo "$node" | cut -d'|' -f2)
    key=$(echo "$node" | cut -d'|' -f3)
    value=$(echo "$node" | cut -d'|' -f4)
    parent_id=$(echo "$node" | cut -d'|' -f5)
    children=$(echo "$node" | cut -d'|' -f6)
    
    # Determine parent type if not provided
    if [ -z "$parent_type" ] && [ "$parent_id" -ge 0 ]; then
        parent_type=$(get_node_field "$parent_id" 2)
    fi
    
    local indent=""
    local i=0
    while [ "$i" -lt "$indent_level" ]; do
        indent="$indent  "
        i=$((i + 1))
    done
    
    case "$type" in
        scalar)
            if [ -n "$key" ]; then
                echo "$indent$key: $value"
            else
                echo "$indent-  $value"
            fi
            ;;
        
        map)
            # If this map is in an array, first child gets dash prefix
            local is_first_child=true
            
            if [ "$node_id" -ne 0 ] && [ -n "$key" ]; then
                echo "$indent$key:"
            fi
            
            if [ -n "$children" ]; then
                local IFS=','
                local next_indent
                # Root node (id=0) doesn't add indentation
                if [ "$node_id" -eq 0 ]; then
                    next_indent="$indent_level"
                else
                    next_indent="$((indent_level + 1))"
                fi
                
                for child_id in $children; do
                    # If parent is array and this is first child, use dash
                    if [ "$parent_type" = "array" ] && [ "$is_first_child" = true ]; then
                        # Serialize first field with dash
                        local child_node
                        child_node=$(get_node "$child_id")
                        local child_type child_key child_value
                        child_type=$(echo "$child_node" | cut -d'|' -f2)
                        child_key=$(echo "$child_node" | cut -d'|' -f3)
                        child_value=$(echo "$child_node" | cut -d'|' -f4)
                        
                        if [ "$child_type" = "scalar" ] && [ -n "$child_key" ]; then
                            echo "$indent- $child_key: $child_value"
                        fi
                        is_first_child=false
                    else
                        serialize_node "$child_id" "$next_indent" "$type"
                    fi
                done
            fi
            ;;
        
        array)
            if [ -n "$key" ]; then
                echo "$indent$key:"
            fi
            
            if [ -n "$children" ]; then
                local IFS=','
                # Array children need to be indented
                for child_id in $children; do
                    serialize_node "$child_id" "$((indent_level + 1))" "array"
                done
            fi
            ;;
    esac
}

# ============================================================================
# BACKWARD COMPATIBILITY
# ============================================================================

yaml_get() {
    local file="$1"
    local key="$2"
    
    if [ "$YAML_CURRENT_FILE" != "$file" ]; then
        yaml_parse "$file" || return 1
    fi
    
    yaml_query ".$key"
}

yaml_get_nested() {
    local file="$1"
    local path="$2"
    
    if [ "$YAML_CURRENT_FILE" != "$file" ]; then
        yaml_parse "$file" || return 1
    fi
    
    yaml_query ".$path"
}

# Check if key exists (checks if node exists, not if it has a value)
yaml_has_key() {
    local file="$1"
    local key="$2"
    
    if [ "$YAML_CURRENT_FILE" != "$file" ]; then
        yaml_parse "$file" || return 1
    fi
    
    # Try to find the node (returns empty string on failure, but exit code tells us)
    path=$(echo "$key" | sed 's/^\.//')
    local current_node="$AST_ROOT_ID"
    
    local IFS='.'
    for segment in $path; do
        if echo "$segment" | grep -q '\['; then
            local k index
            k=$(echo "$segment" | sed 's/\[.*//')
            index=$(echo "$segment" | sed 's/.*\[\([0-9]*\)\].*/\1/')
            
            current_node=$(find_child_by_key "$current_node" "$k" 2>/dev/null)
            [ -z "$current_node" ] && return 1
            
            current_node=$(find_child_by_index "$current_node" "$index" 2>/dev/null)
            [ -z "$current_node" ] && return 1
        else
            current_node=$(find_child_by_key "$current_node" "$segment" 2>/dev/null)
            [ -z "$current_node" ] && return 1
        fi
    done
    
    # Node exists
    return 0
}

# Get array count (for object arrays)
# Usage: yaml_get_array file.yaml "contents.commands"
# Returns: count of array elements
yaml_get_array() {
    local file="$1"
    local path="$2"
    
    if [ "$YAML_CURRENT_FILE" != "$file" ]; then
        yaml_parse "$file" || return 1
    fi
    
    # Find the array node
    path=$(echo "$path" | sed 's/^\.//')
    local current_node="$AST_ROOT_ID"
    
    local IFS='.'
    for segment in $path; do
        current_node=$(find_child_by_key "$current_node" "$segment")
        [ -z "$current_node" ] && return 1
    done
    
    # Get children count
    local children
    children=$(get_node_field "$current_node" 6)
    
    if [ -z "$children" ]; then
        echo "0"
    else
        echo "$children" | tr ',' '\n' | wc -l
    fi
}

# Append scalar item to array
# Usage: yaml_array_append ".path.to.array" "value"
# Returns: node_id of new item
yaml_array_append() {
    local path="$1"
    local value="$2"
    
    if [ -z "$AST_FILE" ] || [ ! -f "$AST_FILE" ]; then
        echo "Error: No AST loaded. Call yaml_parse first." >&2
        return 1
    fi
    
    # Find the array node
    path=$(echo "$path" | sed 's/^\.//')
    local current_node="$AST_ROOT_ID"
    
    local IFS='.'
    for segment in $path; do
        if echo "$segment" | grep -q '\['; then
            local key index
            key=$(echo "$segment" | sed 's/\[.*//')
            index=$(echo "$segment" | sed 's/.*\[\([0-9]*\)\].*/\1/')
            
            current_node=$(find_child_by_key "$current_node" "$key")
            [ -z "$current_node" ] && return 1
            
            current_node=$(find_child_by_index "$current_node" "$index")
            [ -z "$current_node" ] && return 1
        else
            current_node=$(find_child_by_key "$current_node" "$segment")
            [ -z "$current_node" ] && return 1
        fi
    done
    
    # Verify it's an array
    local node_type
    node_type=$(get_node_field "$current_node" 2)
    
    if [ "$node_type" != "array" ]; then
        echo "Error: Path does not point to an array" >&2
        return 1
    fi
    
    # Create new scalar node
    local new_node
    new_node=$(create_node "scalar" "" "$value" "$current_node")
    
    # Add as child
    add_child "$current_node" "$new_node"
    
    echo "$new_node"
}

# Append object to array
# Usage: yaml_array_append_object ".path.to.array"
# Returns: node_id of new object (use yaml_object_set to add fields)
yaml_array_append_object() {
    local path="$1"
    
    if [ -z "$AST_FILE" ] || [ ! -f "$AST_FILE" ]; then
        echo "Error: No AST loaded. Call yaml_parse first." >&2
        return 1
    fi
    
    # Find the node
    path=$(echo "$path" | sed 's/^\.//')
    local current_node="$AST_ROOT_ID"
    
    local IFS='.'
    for segment in $path; do
        if echo "$segment" | grep -q '\['; then
            local key index
            key=$(echo "$segment" | sed 's/\[.*//')
            index=$(echo "$segment" | sed 's/.*\[\([0-9]*\)\].*/\1/')
            
            current_node=$(find_child_by_key "$current_node" "$key")
            [ -z "$current_node" ] && return 1
            
            current_node=$(find_child_by_index "$current_node" "$index")
            [ -z "$current_node" ] && return 1
        else
            current_node=$(find_child_by_key "$current_node" "$segment")
            [ -z "$current_node" ] && return 1
        fi
    done
    
    # Check node type
    local node_type
    node_type=$(get_node_field "$current_node" 2)
    
    # If it's a map with no children, convert to array
    if [ "$node_type" = "map" ]; then
        local children
        children=$(get_node_field "$current_node" 6)
        if [ -z "$children" ]; then
            # Empty map - convert to array
            update_node_type "$current_node" "array"
        else
            echo "Error: Path points to non-empty map, not array" >&2
            return 1
        fi
    elif [ "$node_type" != "array" ]; then
        echo "Error: Path does not point to an array" >&2
        return 1
    fi
    
    # Create new map node (object)
    local new_node
    new_node=$(create_node "map" "" "" "$current_node")
    
    # Add as child
    add_child "$current_node" "$new_node"
    
    echo "$new_node"
}

# Set field on object (for building objects in arrays)
# Usage: yaml_object_set node_id "field_name" "value"
yaml_object_set() {
    local object_node="$1"
    local field_name="$2"
    local field_value="$3"
    
    if [ -z "$AST_FILE" ] || [ ! -f "$AST_FILE" ]; then
        echo "Error: No AST loaded. Call yaml_parse first." >&2
        return 1
    fi
    
    # Create scalar field
    local field_node
    field_node=$(create_node "scalar" "$field_name" "$field_value" "$object_node")
    
    # Add as child
    add_child "$object_node" "$field_node"
    
    echo "$field_node"
}

# ============================================================================
# MAIN
# ============================================================================

trap cleanup_ast EXIT INT TERM

# Only run main if script is executed directly (not sourced)
if [ -n "$1" ] && [ "$1" != "-" ] && [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    case "$1" in
        parse)
            yaml_parse "$2"
            echo "✓ Parsed $2 ($(get_next_node_id) nodes)"
            ;;
        query)
            yaml_parse "$2"
            yaml_query "$3"
            ;;
        set)
            yaml_parse "$2"
            yaml_set "$3" "$4"
            yaml_write "$2"
            echo "✓ Updated $2"
            ;;
        debug)
            yaml_parse "$2"
            echo "AST Contents:"
            cat "$AST_FILE"
            ;;
        *)
            echo "Usage: $0 {parse|query|set|debug} file.yaml [path] [value]"
            echo ""
            echo "Examples:"
            echo "  $0 parse file.yaml"
            echo "  $0 query file.yaml .name"
            echo "  $0 query file.yaml .tags[0]"
            echo "  $0 set file.yaml .version 2.0.0"
            echo "  $0 debug file.yaml"
            exit 1
            ;;
    esac
fi
