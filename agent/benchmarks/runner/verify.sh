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

# Verify the legacy-refactor benchmark task
# Args: $1 = workspace directory
# Sets: FILE_EXISTS, FILE_EXECUTABLE, OUTPUT_CORRECT
# Returns: 0 if all checks pass, 1 if any fail
verify_legacy_refactor() {
    local workspace="$1"
    local all_pass=0

    FILE_EXISTS="false"
    FILE_EXECUTABLE="false"
    OUTPUT_CORRECT="false"

    # Check 1: refactored structure exists (routes dir, REFACTOR_PLAN.md, README.md)
    if [ -f "$workspace/package.json" ] && [ -d "$workspace/routes" ] && \
       [ -f "$workspace/REFACTOR_PLAN.md" ] && [ -f "$workspace/README.md" ]; then
        FILE_EXISTS="true"
    else
        all_pass=1
    fi

    # Check 2: middleware and tests directories exist
    if [ -d "$workspace/middleware" ] && [ -d "$workspace/tests" ]; then
        FILE_EXECUTABLE="true"
    else
        all_pass=1
    fi

    # Check 3: tests exist and pass
    if [ -f "$workspace/package.json" ] && [ -d "$workspace/tests" ]; then
        local test_result
        test_result=$(cd "$workspace" && npm test 2>&1) && OUTPUT_CORRECT="true" || all_pass=1
    else
        all_pass=1
    fi

    export FILE_EXISTS FILE_EXECUTABLE OUTPUT_CORRECT
    return $all_pass
}

# Verify the order-pipeline benchmark task
# Args: $1 = workspace directory
# Sets: FILE_EXISTS, FILE_EXECUTABLE, OUTPUT_CORRECT
# Returns: 0 if all checks pass, 1 if any fail
verify_order_pipeline() {
    local workspace="$1"
    local all_pass=0

    FILE_EXISTS="false"
    FILE_EXECUTABLE="false"
    OUTPUT_CORRECT="false"

    # Check 1: key files exist (package.json, README.md, event bus module)
    if [ -f "$workspace/package.json" ] && [ -f "$workspace/README.md" ]; then
        FILE_EXISTS="true"
    else
        all_pass=1
    fi

    # Check 2: event bus exists (proves the event-driven refactor happened)
    local eventbus_found="false"
    for candidate in "$workspace/events/event-bus.js" "$workspace/eventbus/index.js" \
                      "$workspace/src/events/event-bus.js" "$workspace/src/eventbus.js" \
                      "$workspace/lib/event-bus.js" "$workspace/events/eventBus.js" \
                      "$workspace/src/events/eventBus.js"; do
        if [ -f "$candidate" ]; then
            eventbus_found="true"
            break
        fi
    done
    if [ "$eventbus_found" = "true" ]; then
        FILE_EXECUTABLE="true"
    else
        all_pass=1
    fi

    # Check 3: tests exist and pass
    if [ -f "$workspace/package.json" ] && [ -d "$workspace/tests" ]; then
        local test_result
        test_result=$(cd "$workspace" && npm test 2>&1) && OUTPUT_CORRECT="true" || all_pass=1
    else
        all_pass=1
    fi

    export FILE_EXISTS FILE_EXECUTABLE OUTPUT_CORRECT
    return $all_pass
}

# Verify the enterprise-task-manager benchmark task
verify_enterprise_task_manager() {
    local workspace="$1"
    local all_pass=0

    FILE_EXISTS="false"
    FILE_EXECUTABLE="false"
    OUTPUT_CORRECT="false"

    # Check 1: key documentation files exist
    if [ -f "$workspace/package.json" ] && [ -f "$workspace/README.md" ] && \
       [ -f "$workspace/ANALYSIS.md" ] && [ -f "$workspace/MIGRATION.md" ] && \
       [ -f "$workspace/ARCHITECTURE.md" ]; then
        FILE_EXISTS="true"
    else
        all_pass=1
    fi

    # Check 2: proper structure (routes, models, middleware, tests dirs)
    if [ -d "$workspace/routes" ] && [ -d "$workspace/models" ] && \
       [ -d "$workspace/middleware" ] && [ -d "$workspace/tests" ]; then
        FILE_EXECUTABLE="true"
    else
        all_pass=1
    fi

    # Check 3: tests exist and pass
    if [ -f "$workspace/package.json" ] && [ -d "$workspace/tests" ]; then
        local test_result
        test_result=$(cd "$workspace" && npm test 2>&1) && OUTPUT_CORRECT="true" || all_pass=1
    else
        all_pass=1
    fi

    export FILE_EXISTS FILE_EXECUTABLE OUTPUT_CORRECT
    return $all_pass
}

# Verify the acp-project benchmark task
# Args: $1 = workspace directory
# Sets: FILE_EXISTS, FILE_EXECUTABLE, OUTPUT_CORRECT
# Returns: 0 if all checks pass, 1 if any fail
verify_acp_project() {
    local workspace="$1"
    local all_pass=0

    FILE_EXISTS="false"
    FILE_EXECUTABLE="false"
    OUTPUT_CORRECT="false"

    # Check 1: key files exist (task model, project model, README)
    if [ -f "$workspace/package.json" ] && [ -f "$workspace/src/index.js" ] && \
       [ -f "$workspace/README.md" ]; then
        # Check for task and project models (may be in src/models/ or other locations)
        local task_model_found="false"
        local project_model_found="false"
        for candidate in "$workspace/src/models/task.js" "$workspace/src/models/tasks.js" \
                          "$workspace/models/task.js" "$workspace/src/task.js"; do
            if [ -f "$candidate" ]; then
                task_model_found="true"
                break
            fi
        done
        for candidate in "$workspace/src/models/project.js" "$workspace/src/models/projects.js" \
                          "$workspace/models/project.js" "$workspace/src/project.js"; do
            if [ -f "$candidate" ]; then
                project_model_found="true"
                break
            fi
        done
        if [ "$task_model_found" = "true" ] && [ "$project_model_found" = "true" ]; then
            FILE_EXISTS="true"
        else
            all_pass=1
        fi
    else
        all_pass=1
    fi

    # Check 2: tests directory exists with test files
    if [ -d "$workspace/tests" ] || [ -d "$workspace/__tests__" ]; then
        local test_count
        test_count=$(find "$workspace/tests" "$workspace/__tests__" -name "*.test.js" -o -name "*.spec.js" 2>/dev/null | wc -l)
        if [ "$test_count" -ge 2 ]; then
            FILE_EXECUTABLE="true"
        else
            all_pass=1
        fi
    else
        all_pass=1
    fi

    # Check 3: tests pass
    if [ "$FILE_EXISTS" = "true" ] && [ "$FILE_EXECUTABLE" = "true" ]; then
        local test_result
        test_result=$(cd "$workspace" && npm test 2>&1) && OUTPUT_CORRECT="true" || all_pass=1
    else
        all_pass=1
    fi

    export FILE_EXISTS FILE_EXECUTABLE OUTPUT_CORRECT
    return $all_pass
}

# Verify the saas-platform benchmark task
# Args: $1 = workspace directory
# Sets: FILE_EXISTS, FILE_EXECUTABLE, OUTPUT_CORRECT
# Returns: 0 if all checks pass, 1 if any fail
verify_saas_platform() {
    local workspace="$1"
    local all_pass=0

    FILE_EXISTS="false"
    FILE_EXECUTABLE="false"
    OUTPUT_CORRECT="false"

    # Check 1: key files exist (package.json, server.js, docs)
    if [ -f "$workspace/package.json" ] && [ -f "$workspace/server.js" ] && \
       [ -f "$workspace/README.md" ] && [ -f "$workspace/ANALYSIS.md" ] && \
       [ -f "$workspace/ARCHITECTURE.md" ] && [ -f "$workspace/MIGRATION.md" ]; then
        FILE_EXISTS="true"
    else
        all_pass=1
    fi

    # Check 2: proper directory structure (models, routes, services, middleware, tests)
    if [ -d "$workspace/models" ] && [ -d "$workspace/routes" ] && \
       [ -d "$workspace/services" ] && [ -d "$workspace/middleware" ] && \
       [ -d "$workspace/tests" ]; then
        FILE_EXECUTABLE="true"
    else
        all_pass=1
    fi

    # Check 3: tests exist and pass
    if [ -f "$workspace/package.json" ] && [ -d "$workspace/tests" ]; then
        local test_result
        test_result=$(cd "$workspace" && npm test 2>&1) && OUTPUT_CORRECT="true" || all_pass=1
    else
        all_pass=1
    fi

    export FILE_EXISTS FILE_EXECUTABLE OUTPUT_CORRECT
    return $all_pass
}
