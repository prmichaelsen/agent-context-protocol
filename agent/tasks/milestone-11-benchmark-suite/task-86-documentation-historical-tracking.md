# Task 86: Documentation & Historical Tracking

**Milestone**: M11 - ACP Benchmark Suite  
**Estimated Time**: 3-4 hours  
**Dependencies**: Tasks 79-85 (full pipeline must be working)  
**Status**: Not Started  

---

## Objective

Add documentation for the benchmark suite, implement historical result tracking, and set up a GitHub Pages dashboard for published benchmark results.

---

## Context

The benchmark suite needs user-facing documentation so others can run it, understand results, and contribute tasks. Historical tracking shows ACP improvement trends across versions. GitHub Pages makes results publicly accessible.

---

## Steps

### 1. Update AGENT.md
- Add Benchmark Suite section describing the feature
- Reference design doc and runner scripts
- Link to benchmark reports

### 2. Update README.md
- Add benchmark section with quick-start
- Example commands to run benchmarks
- Link to GitHub Pages dashboard

### 3. Update Design Document
- Change status from "Design Specification" to "Implemented"
- Add implementation notes referencing actual files

### 4. Implement Historical Tracking
- Script to compare current run against previous runs
- Version-tagged results (track which ACP version produced which scores)
- Trend data: improvement over time

### 5. Set Up GitHub Pages
- Configure GitHub Pages to serve from reports directory or docs/
- Landing page with latest benchmark results
- Historical comparison across versions

### 6. Update CHANGELOG.md
- Add M11 entry with all benchmark features

---

## Verification

- [ ] AGENT.md has benchmark section
- [ ] README.md has quick-start for running benchmarks
- [ ] Design doc status updated to Implemented
- [ ] Historical tracking produces version-tagged comparisons
- [ ] GitHub Pages serves benchmark dashboard
- [ ] CHANGELOG.md has M11 entry

---

**Related Design Docs**: agent/design/local.benchmark-suite.md (Future Considerations, Migration Path)  
