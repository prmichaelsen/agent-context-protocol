#!/bin/sh
# YAML Parser for Bash/Shell
#
# Source: https://github.com/fiftydinar/yaml-parser
# License: MIT
# Downloaded: 2026-02-18
#
# Original author: fiftydinar
# Modified: Added helper functions for ACP package management

yaml_help () {
  printf "\e[1;33mUsage:\e[0m \e[1;90m==================================================================\e[0m\n"
  printf "       \e[1;90mRead YAML file content:\e[0m\n"
  printf "       yaml-parser \"file.yml\"\n"
  printf "       \e[1;90mRead YAML value from YAML key:\e[0m\n"
  printf "       yaml-parser \"file.yml\" \"key\"\n"
  printf "       \e[1;90mWrite YAML value to YAML key:\e[0m\n"
  printf "       yaml-parser \"file.yml\" -w \"key\" \"value\"\n"
  printf "       yaml-parser \"file.yml\" --write \"key\" \"value\"\n"
  printf "       \e[1;90mWrite quoted YAML value to YAML key:\e[0m\n"
  printf "       yaml-parser \"file.yml\" -w \"key\" \"\\\\\\\"value\\\\\\\"\"\n"
  printf "       yaml-parser \"file.yml\" --write \"key\" \"\\\\\\\"value\\\\\\\"\"\n"
  printf "       \e[1;90mDo multiple operations with yaml-parser:\e[0m\n"
  printf "       yaml-parser \"file1.yml\" && yaml-parser \"file2.yml\"\n"
  printf "       \e[1;90m==================================================================\e[0m\n"
  printf "\e[1;33mNotes:\e[0m Only regular YAML keys are supported. Arrays are not supported.\n"
  printf "       Before making any changes to the YAML file,\n"
  printf "       please check if the file syntax is correct with:\n"
  yaml_lint_url="https://www.yamllint.com"
  printf "       \e]8;;%s\a%s\e]8;;\a\n" "${yaml_lint_url}" "${yaml_lint_url}"
  printf "\e[1;33mAbout:\e[0m \"yaml-parser\" is a tool written in SH shell, using GNU Utilities,\n       which can perform basic data reading & manipulation of YAML files.\n"
  yaml_parser_url="https://github.com/fiftydinar/yaml-parser"
  printf "       \e]8;;%s\a%s\e]8;;\a\n" "${yaml_parser_url}" "${yaml_parser_url}"
}

yaml_read () {
    result1=$(awk -F ": " -v key="${2}" '{sub(/#.*/, "", $2); gsub(/^[ \t]+|[ \t]+$/, "", $2)} $1 == key {gsub(/"/, "", $2); print $2}' "${1}")
    count1=$(awk -v key="^${2}:" '$0 ~ key {count++} END {if (count) print count; else print 0}' "${1}")
    if [ "${count1}" -gt 1 ]; then
      printf "\e[1;31mERROR: YAML file syntax is invalid, as it uses duplicate keys.\n       Remove duplicate keys in YAML file & try again.\e[0m\n"  # Print error message for multiple results
    elif [ -z "${result1}" ]; then
      printf "\e[1;31mnull\e[0m\n"  # Print "null" in red color if no results are found
    else
      printf "\e[1;94m%s\e[0m\n" "${result1}"  # Print the matching result in blue color
    fi
}

yaml_write () {
    result2=$(awk -F ": " -v key="${3}" '{sub(/#.*/, "", $2); gsub(/^[ \t]+|[ \t]+$/, "", $2)} $1 == key {print $2}' "${1}")
    count2=$(awk -v key="^${3}:" '$0 ~ key {count++} END {if (count) print count; else print 0}' "${1}")
    if [ "${count2}" -gt 1 ]; then
      printf "\e[1;31mERROR: YAML file syntax is invalid, as it uses duplicate keys.\n       Remove duplicate keys in YAML file & try again.\e[0m\n"  # Print error message for multiple results    
    elif [ -z "${result2}" ]; then
      printf "\e[1;31mERROR: Supplied YAML key doesn't exist.\e[0m\n" 1>&2
    else
      sed -i "s/\(${3}: ${result2}\)/${3}: ${4}/g" "${1}" # Write the supplied value to specified yaml key
    fi
}

if [ -z "${1}" ] || [ "${1}" = "help" ] || [ "${1}" = "--help" ] || [ "${1}" = "-h" ]; then
  yaml_help
elif case "${1}" in (*.yml|*.yaml) false;; (*) true;; esac; then
  printf "\e[1;31mERROR: YAML file is not specified in supported .yml or .yaml extension.\e[0m\n" 1>&2
elif [ -n "${1}" ] && [ -f "${1}" ] && [ -n "${2}" ] && [ ! "${2}" = "-w" ] && [ ! "${2}" = "--write" ]; then
  yaml_read "${1}" "${2}"
elif [ -n "${1}" ] && [ -f "${1}" ] && [ -n "${2}" ] && [ "${2}" = "-w" ] || [ "${2}" = "--write" ] && [ -n "${3}" ] && [ -n "${4}" ]; then
  yaml_write "${1}" "${2}" "${3}" "${4}"
elif [ -n "${1}" ] && [ -f "${1}" ]; then
line_number=1
while IFS= read -r line; do
    printf "\033[1;33m%4d|\033[0m\033[1;94m%s\033[0m\n" $line_number "${line}"
    ((line_number++))
done < "${1}"
elif ! [ -f "${1}" ]; then
  printf "\e[1;31mERROR: YAML file that is specified is not found in the directory.\e[0m\n" 1>&2
fi

# ============================================================================
# Helper Functions for Package Management Scripts
# ============================================================================
# These functions provide a simpler API when sourcing this script

# Read YAML value (strips color codes)
# Usage: yaml_get file.yaml "key"
yaml_get() {
  local file=$1
  local key=$2
  yaml_read "$file" "$key" 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g'
}

# Write YAML value (wrapper)
# Usage: yaml_set file.yaml "key" "value"
yaml_set() {
  local file=$1
  local key=$2
  local value=$3
  yaml_write "$file" "-w" "$key" "$value" 2>/dev/null
}

# Check if key exists
# Usage: yaml_has_key file.yaml "key"
yaml_has_key() {
  local file=$1
  local key=$2
  local result=$(yaml_get "$file" "$key")
  [ "$result" != "null" ] && [ -n "$result" ]
}

# Get array values (for simple arrays and object arrays)
# Usage: yaml_get_array file.yaml "tags" or yaml_get_array file.yaml "contents.commands"
# Returns: For simple arrays: values (one per line); For object arrays: count of objects
yaml_get_array() {
  local file=$1
  local key=$2
  
  # Handle nested keys (e.g., "contents.commands")
  if [[ "$key" == *.* ]]; then
    # Extract the final key (e.g., "commands" from "contents.commands")
    local final_key=$(echo "$key" | sed 's/.*\.//')
    
    # Extract array section using sed to find the nested key
    local array_content=$(sed -n "/^[[:space:]]*${final_key}:/,/^[[:space:]]*[a-z]/p" "$file" | grep "^[[:space:]]*-")
  else
    # Top-level key
    local array_content=$(awk "/^${key}:/{flag=1; next} /^[a-zA-Z]/{flag=0} flag && /^[[:space:]]*-/{print}" "$file")
  fi
  
  # Check if this is an object array (has "key:" after dash)
  if echo "$array_content" | grep -q "^[[:space:]]*-[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*:"; then
    # Object array - return count of objects (number of dashes)
    echo "$array_content" | grep -c "^[[:space:]]*-"
  else
    # Simple array - return values
    echo "$array_content" | sed 's/^[[:space:]]*-[[:space:]]*//'
  fi
}

# Get value from nested object in array
# Usage: yaml_get_nested file.yaml "contents.commands[0].name"
# Supports: array[index].field notation
# Returns: Field value or empty string if not found
yaml_get_nested() {
  local file="$1"
  local path="$2"
  
  # Check if path contains array notation [index]
  case "$path" in
    *"["*"]"*)
      # Extract components using sed
      local array_path=$(echo "$path" | sed 's/\[[0-9]*\].*//')
      local index=$(echo "$path" | sed 's/.*\[\([0-9]*\)\].*/\1/')
      local field=$(echo "$path" | sed 's/.*\[[0-9]*\]\.//')
      
      # Navigate to array, find nth object, extract field
      awk -v array_path="$array_path" -v idx="$index" -v field="$field" '
        BEGIN {
          split(array_path, path_parts, ".")
          target_key = path_parts[length(path_parts)]
          in_target_array = 0
          object_count = -1
          in_target_object = 0
        }
        
        # Match the target array key
        $1 == target_key ":" {
          in_target_array = 1
          next
        }
        
        # Exit array when we hit another top-level or same-level key
        in_target_array && /^[a-zA-Z_][a-zA-Z0-9_]*:/ && !/^[[:space:]]/ {
          in_target_array = 0
        }
        
        # Count array objects (lines starting with -)
        in_target_array && /^[[:space:]]*-/ {
          object_count++
          if (object_count == idx) {
            in_target_object = 1
          } else if (object_count > idx) {
            in_target_object = 0
          }
        }
        
        # Extract field from target object (inline: "- name: value")
        in_target_object && $0 ~ "^[[:space:]]*-[[:space:]]+" field ":" {
          sub("^[[:space:]]*-[[:space:]]+" field ":[[:space:]]*", "")
          print $0
          exit
        }
        
        # Extract field from target object (separate line: "  name: value")
        in_target_object && $0 ~ "^[[:space:]]+" field ":" {
          sub("^[[:space:]]+" field ":[[:space:]]*", "")
          print $0
          exit
        }
        
        # Exit object when we hit next dash
        in_target_object && /^[[:space:]]*-/ && object_count > idx {
          exit
        }
      ' "$file"
      ;;
    *)
      # For non-array paths, use standard yaml_read
      yaml_read "$file" "$path" 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g'
      ;;
  esac
}

# Initialize empty YAML file
# Usage: yaml_init file.yaml
yaml_init() {
  local file=$1
  cat > "$file" << 'EOF'
# YAML file
EOF
}
