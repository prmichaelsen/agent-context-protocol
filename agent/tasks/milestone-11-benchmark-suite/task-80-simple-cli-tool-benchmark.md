# Task 80: Simple CLI Tool Benchmark Task

**Milestone**: M11 - ACP Benchmark Suite
**Estimated Time**: 3-4 hours
**Dependencies**: Task 79 (runner must support multi-turn steps)
**Status**: Completed
**Actual Hours**: 0.5
**Completed**: 2026-02-28

---

## Objective

Create the `simple-cli-tool` benchmark task with 3 multi-turn steps (build, test, correction), config, and expected output structure.

---

## Context

The design spec defines a simple-complexity benchmark: building a CLI tool. This is the first real benchmark task (hello-world is kept as a smoke test only). The task should be achievable by Claude Code in ~2 minutes per run, testing basic project scaffolding, testing, and bug correction.

---

## Steps

### 1. Create Directory Structure
```
agent/benchmarks/suite/simple-cli-tool/
├── config.yaml
├── steps/
│   ├── 01-build.md
│   ├── 02-test.md
│   └── 03-correction.md
└── expected/
    └── structure.yaml
```

### 2. Define config.yaml
- name, description, complexity: simple, domain: cli
- timeout_minutes: 10, runs: 5
- 3 steps with max_turns and phases

### 3. Write Step Prompts
- **01-build.md**: "Build a CLI tool that converts CSV files to JSON. It should accept a file path argument and output JSON to stdout."
- **02-test.md**: "Add tests for the CSV-to-JSON converter. Test at least: valid CSV, empty file, missing file, and CSV with special characters."
- **03-correction.md**: "The tool crashes when the CSV has empty cells. Fix this bug so empty cells become null values in the JSON output."

### 4. Define Expected Structure
- Expected files: package.json or equivalent, source file, test file
- Expected behavior: executable, handles edge cases

### 5. Add Verification to verify.sh
- Add `verify_simple_cli_tool()` function
- Checks: file_exists, tests_pass, output_correct

---

## Verification

- [x] config.yaml valid with 3 steps (build, test, correction)
- [x] Step prompts are clear and self-contained
- [x] expected/structure.yaml defines file expectations
- [x] verify.sh has verify_simple_cli_tool() function
- [ ] Task can run end-to-end with runner (requires non-nested session)

---

**Related Design Docs**: agent/design/local.benchmark-suite.md (Benchmark Task Definition)
