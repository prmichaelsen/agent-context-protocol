# Task 83: LLM Evaluator Implementation

**Milestone**: M11 - ACP Benchmark Suite
**Estimated Time**: 4-6 hours
**Dependencies**: Task 79 (runner infrastructure), Tasks 80-82 (at least one benchmark task to evaluate)
**Status**: Not Started

---

## Objective

Implement the LLM evaluator that scores benchmark outputs against a structured rubric, producing numeric scores (1-10) and categorical ratings (MISS/MEETS/EXCEEDS) for 6 quality dimensions.

---

## Context

The design spec calls for a separate Claude Code invocation that evaluates the workspace produced by each benchmark run. The evaluator uses a structured prompt with rubric and outputs JSON conforming to a schema. This provides qualitative assessment beyond pass/fail verification.

---

## Steps

### 1. Create evaluator-prompt.md
- Rubric with 6 categories: correctness, completeness, code style, documentation, architecture, testing
- Scoring guidelines for each category (what 1-3, 4-6, 7-8, 9-10 look like)
- Categorical mapping: 1-3=MISS, 4-7=MEETS, 8-10=EXCEEDS
- Instructions to read the workspace and expected structure
- Instructions to assess code quality, not just presence

### 2. Create evaluation-schema.json
- JSON schema for structured evaluator output
- Fields per category: score (1-10), rating (MISS/MEETS/EXCEEDS), rationale (string)
- Overall score (average) and overall rating
- Summary field for free-form assessment

### 3. Integrate Evaluator into Runner
- After verification step in run-single.sh, run evaluator
- Execute: `claude -p <evaluator-prompt> --output-format json --json-schema <schema> --allowedTools "Read,Glob,Grep,Bash" --max-turns 10`
- Save evaluation output to run directory

### 4. Add Evaluation to Reports
- Include evaluator scores in summary.yaml
- Add evaluation section to markdown report
- Add evaluation visualization to HTML report

### 5. Calibrate Evaluator
- Run evaluator on hello-world output (expected: high scores for trivial task)
- Manually verify scores seem reasonable
- Adjust rubric wording if scoring is off

---

## Verification

- [ ] evaluator-prompt.md has clear rubric for 6 categories
- [ ] evaluation-schema.json is valid JSON schema
- [ ] Evaluator runs successfully on a benchmark workspace
- [ ] Scores are 1-10 numeric with categorical ratings
- [ ] Evaluation results appear in reports
- [ ] Scores are roughly calibrated (trivial task gets high scores)

---

**Related Design Docs**: agent/design/local.benchmark-suite.md (LLM Evaluator)
