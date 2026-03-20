#!/usr/bin/env bash
# Unified E2E Test Runner for Agent Context Protocol
# Usage:
#   bash run-e2e-tests.sh              # Run all E2E tests
#   bash run-e2e-tests.sh sessions     # Run only tests matching "sessions"

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILTER="${1:-}"

passed=0
failed=0
skipped=0
failed_tests=()
total=0

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ACP E2E Test Runner"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for test_file in "$SCRIPT_DIR"/e2e/*.test.sh; do
    test_name="$(basename "$test_file")"

    # Apply filter if provided
    if [[ -n "$FILTER" ]] && [[ "$test_name" != *"$FILTER"* ]]; then
        skipped=$((skipped + 1))
        continue
    fi

    total=$((total + 1))
    printf "  %-50s " "$test_name"

    # Run test, capture output and exit code
    output=$(bash "$test_file" 2>&1)
    exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        echo "✅ PASS"
        passed=$((passed + 1))
    else
        echo "❌ FAIL (exit $exit_code)"
        failed=$((failed + 1))
        failed_tests+=("$test_name")

        # Show last 20 lines of output for debugging
        echo ""
        echo "    ── Output (last 20 lines) ──"
        echo "$output" | tail -20 | sed 's/^/    /'
        echo "    ────────────────────────────"
        echo ""
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Results"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Total:   $total"
echo "  Passed:  $passed"
echo "  Failed:  $failed"
if [[ $skipped -gt 0 ]]; then
    echo "  Skipped: $skipped (filter: '$FILTER')"
fi
echo ""

if [[ ${#failed_tests[@]} -gt 0 ]]; then
    echo "  Failed tests:"
    for ft in "${failed_tests[@]}"; do
        echo "    ❌ $ft"
    done
    echo ""
fi

if [[ $failed -eq 0 ]]; then
    echo "  ✅ All tests passed!"
else
    echo "  ❌ $failed test(s) failed"
fi
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

[[ $failed -eq 0 ]]
