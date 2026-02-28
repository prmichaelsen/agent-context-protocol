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

# --- Additional task verify functions ---

# Verify the simple-cli-tool benchmark task
# Args: $1 = workspace directory
# Sets: FILE_EXISTS, FILE_EXECUTABLE, OUTPUT_CORRECT
# Returns: 0 if all checks pass, 1 if any fail
verify_simple_cli_tool() {
    local workspace="$1"
    local all_pass=0

    FILE_EXISTS="false"
    FILE_EXECUTABLE="false"
    OUTPUT_CORRECT="false"

    # Check 1: csv2json.sh exists
    if [ -f "$workspace/csv2json.sh" ]; then
        FILE_EXISTS="true"
    else
        all_pass=1
    fi

    # Check 2: csv2json.sh is executable
    if [ -x "$workspace/csv2json.sh" ]; then
        FILE_EXECUTABLE="true"
    else
        all_pass=1
    fi

    # Check 3: basic conversion works correctly
    if [ "$FILE_EXISTS" = "true" ]; then
        # Create a test CSV
        local test_csv="$workspace/_verify_test.csv"
        printf 'name,age\nAlice,30\n' > "$test_csv"

        local actual_output
        actual_output=$(cd "$workspace" && bash csv2json.sh "$test_csv" 2>/dev/null)
        rm -f "$test_csv"

        # Check that output contains expected JSON structure
        if echo "$actual_output" | grep -q '"name"' && echo "$actual_output" | grep -q '"Alice"'; then
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

# Verify the medium-rest-api benchmark task
# Args: $1 = workspace directory
# Sets: FILE_EXISTS, FILE_EXECUTABLE, OUTPUT_CORRECT
# Returns: 0 if all checks pass, 1 if any fail
verify_medium_rest_api() {
    local workspace="$1"
    local all_pass=0

    FILE_EXISTS="false"
    FILE_EXECUTABLE="false"
    OUTPUT_CORRECT="false"

    # Check 1: key files exist (package.json, src/index.js, src/routes/todos.js)
    if [ -f "$workspace/package.json" ] && [ -f "$workspace/src/index.js" ]; then
        FILE_EXISTS="true"
    else
        all_pass=1
    fi

    # Check 2: routes module exists (refactor step completed)
    if [ -f "$workspace/src/routes/todos.js" ]; then
        FILE_EXECUTABLE="true"
    else
        # Partial credit: routes may not exist if refactor step didn't run
        all_pass=1
    fi

    # Check 3: tests exist and pass
    if [ "$FILE_EXISTS" = "true" ] && [ -d "$workspace/tests" ]; then
        local test_result
        test_result=$(cd "$workspace" && npm test 2>&1) && OUTPUT_CORRECT="true" || all_pass=1
    else
        all_pass=1
    fi

    export FILE_EXISTS FILE_EXECUTABLE OUTPUT_CORRECT
    return $all_pass
}

# Verify the complex-auth-system benchmark task
# Args: $1 = workspace directory
# Sets: FILE_EXISTS, FILE_EXECUTABLE, OUTPUT_CORRECT
# Returns: 0 if all checks pass, 1 if any fail
verify_complex_auth_system() {
    local workspace="$1"
    local all_pass=0

    FILE_EXISTS="false"
    FILE_EXECUTABLE="false"
    OUTPUT_CORRECT="false"

    # Check 1: key files exist (package.json, src/index.js, auth route, auth middleware, README)
    if [ -f "$workspace/package.json" ] && [ -f "$workspace/src/index.js" ] && \
       [ -f "$workspace/src/routes/auth.js" ] && [ -f "$workspace/src/middleware/auth.js" ]; then
        FILE_EXISTS="true"
    else
        all_pass=1
    fi

    # Check 2: README.md exists (docs step completed)
    if [ -f "$workspace/README.md" ]; then
        FILE_EXECUTABLE="true"
    else
        all_pass=1
    fi

    # Check 3: tests exist and pass
    if [ "$FILE_EXISTS" = "true" ] && [ -d "$workspace/tests" ]; then
        local test_result
        test_result=$(cd "$workspace" && npm test 2>&1) && OUTPUT_CORRECT="true" || all_pass=1
    else
        all_pass=1
    fi

    export FILE_EXISTS FILE_EXECUTABLE OUTPUT_CORRECT
    return $all_pass
}
