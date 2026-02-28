#!/bin/bash
# verify.sh — Verification functions for benchmark tasks
# Sourced by run-single.sh
#
# Each task should define a verify_<task_name> function (hyphens replaced with underscores).
# The function receives the workspace directory as $1 and should:
#   - Set exported variables for individual checks (e.g., FILE_EXISTS, FILE_EXECUTABLE)
#   - Return 0 if all checks pass, 1 if any fail

# Verify the hello-world benchmark task
# Args: $1 = workspace directory
# Sets: FILE_EXISTS, FILE_EXECUTABLE, OUTPUT_CORRECT
# Returns: 0 if all checks pass, 1 if any fail
verify_hello_world() {
    local workspace="$1"
    local all_pass=0

    FILE_EXISTS="false"
    FILE_EXECUTABLE="false"
    OUTPUT_CORRECT="false"

    # Check 1: hello_computer.sh exists
    if [ -f "$workspace/hello_computer.sh" ]; then
        FILE_EXISTS="true"
    else
        all_pass=1
    fi

    # Check 2: file is executable
    if [ -x "$workspace/hello_computer.sh" ]; then
        FILE_EXECUTABLE="true"
    else
        all_pass=1
    fi

    # Check 3: output is exactly "Hello World!\n"
    if [ "$FILE_EXISTS" = "true" ]; then
        local actual_output
        actual_output=$(cd "$workspace" && bash hello_computer.sh 2>/dev/null)
        if [ "$actual_output" = "Hello World!" ]; then
            OUTPUT_CORRECT="true"
        else
            all_pass=1
        fi
    else
        all_pass=1
    fi

    export FILE_EXISTS FILE_EXECUTABLE OUTPUT_CORRECT
    return $all_pass
}

# --- Add verify functions for future tasks below ---

# verify_simple_cli_tool() { ... }
# verify_medium_rest_api() { ... }
# verify_complex_auth_system() { ... }
