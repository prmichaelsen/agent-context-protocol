# Task 70: Optimize Package Install Performance

**Milestone**: [M3 - ACP Package Management System](../milestones/milestone-3-acp-package-management.md)
**Estimated Time**: 2-3 hours
**Dependencies**: None
**Status**: Not Started

---

## Objective

Investigate and optimize the `acp.package-install.sh` script to significantly reduce file copy time. The script currently takes an excessive amount of time per file when copying patterns, designs, and commands during package installation.

---

## Context

Users have reported that `acp.package-install.sh` is extremely slow when installing packages, with noticeable delays for each file being copied. This creates a poor user experience and makes package installation impractical for packages with many files.

The performance issue likely stems from:
1. Inefficient file operations (multiple reads/writes per file)
2. Excessive checksum calculations
3. Redundant manifest operations
4. Suboptimal YAML parsing/writing
5. Unnecessary subprocess spawning

This task will profile the script, identify bottlenecks, and implement optimizations to achieve sub-second installation times for typical packages.

---

## Steps

### 1. Profile Current Performance

Measure baseline performance to identify bottlenecks:

**Actions**:
- Add timing instrumentation to `acp.package-install.sh`
- Test with a representative package (e.g., 10-20 files)
- Measure time spent in each major operation:
  - File copying
  - Checksum calculation
  - Manifest updates
  - YAML parsing/writing
- Identify the slowest operations

**Tools**:
```bash
# Add timing to script
time_start=$(date +%s%N)
# ... operation ...
time_end=$(date +%s%N)
echo "Operation took: $(( (time_end - time_start) / 1000000 ))ms"
```

### 2. Analyze Bottlenecks

Review the profiling data and identify root causes:

**Common Performance Issues**:
- **Manifest updates**: Writing to manifest.yaml after each file (O(n) file operations)
- **Checksum calculation**: Running `sha256sum` for each file individually
- **YAML operations**: Parsing/writing YAML repeatedly
- **Subprocess overhead**: Excessive forking for simple operations
- **File I/O**: Multiple reads of the same files

**Expected Findings**: Document which operations consume the most time

### 3. Implement Batch Operations

Optimize by batching operations instead of per-file processing:

**Optimizations**:
- **Batch checksums**: Calculate all checksums in one pass
  ```bash
  # Instead of: for each file: sha256sum file
  # Do: sha256sum file1 file2 file3 ... | process all at once
  ```
- **Batch manifest updates**: Collect all file entries, write manifest once at end
- **Batch file copies**: Use efficient copy methods (cp with multiple args)

### 4. Optimize YAML Operations

Reduce YAML parsing/writing overhead:

**Optimizations**:
- Parse YAML once at start, hold in memory
- Build manifest structure in memory
- Write YAML once at end
- Consider using `yaml_write()` efficiently from `acp.yaml-parser.sh`
- Avoid repeated `yaml_get()` calls for same data

### 5. Reduce Subprocess Spawning

Minimize expensive subprocess creation:

**Optimizations**:
- Use shell builtins where possible
- Batch external commands (sha256sum, cp, etc.)
- Avoid unnecessary `grep`, `awk`, `sed` calls
- Use shell string manipulation instead of external tools

### 6. Implement Progress Indicators

Add efficient progress feedback without slowing down:

**Implementation**:
```bash
# Efficient progress (update every N files, not every file)
total_files=20
processed=0
for file in "${files[@]}"; do
  # ... copy file ...
  ((processed++))
  if (( processed % 5 == 0 )); then
    echo "Progress: $processed/$total_files files"
  fi
done
```

### 7. Test Performance Improvements

Measure improvements and verify correctness:

**Actions**:
- Run same test package as Step 1
- Compare before/after timings
- Verify all files copied correctly
- Verify manifest is accurate
- Verify checksums are correct
- Test with various package sizes (1 file, 10 files, 50 files)

**Target**: Achieve at least 10x speedup (e.g., 10 seconds → 1 second)

### 8. Update Documentation

Document optimizations and any behavior changes:

**Actions**:
- Update `acp.package-install.md` if behavior changed
- Add performance notes to CHANGELOG.md
- Document any new flags or options
- Update version number if breaking changes

---

## Verification

- [ ] Profiling data collected showing current bottlenecks
- [ ] Bottlenecks identified and documented
- [ ] Batch operations implemented for checksums
- [ ] Batch operations implemented for manifest updates
- [ ] YAML operations optimized (parse once, write once)
- [ ] Subprocess spawning minimized
- [ ] Progress indicators added (efficient)
- [ ] Performance tests show significant improvement (>5x faster)
- [ ] All files still copied correctly
- [ ] Manifest still accurate with correct checksums
- [ ] No regressions in functionality
- [ ] Documentation updated

---

## Expected Output

### Performance Improvement

**Before**:
```
Installing package with 20 files...
  Copying patterns/example.md... (500ms)
  Copying commands/example.md... (500ms)
  ...
Total time: 10+ seconds
```

**After**:
```
Installing package with 20 files...
  Copying 20 files... ✓
  Calculating checksums... ✓
  Updating manifest... ✓
Total time: <1 second
```

### Key Optimizations

1. **Batch checksums**: Single `sha256sum` call for all files
2. **Batch manifest**: Build in memory, write once
3. **Efficient YAML**: Parse once, write once
4. **Reduced subprocesses**: Use shell builtins
5. **Smart progress**: Update every N files, not every file

---

## Common Issues and Solutions

### Issue 1: Checksums don't match after optimization

**Symptom**: Manifest checksums differ from file checksums
**Solution**: Ensure batch checksum processing preserves file-to-checksum mapping correctly. Verify with `sha256sum -c`.

### Issue 2: Manifest corruption

**Symptom**: manifest.yaml becomes invalid after batch update
**Solution**: Validate YAML structure before writing. Use `yaml_write()` correctly with proper escaping.

### Issue 3: Progress indicators slow down installation

**Symptom**: Adding progress makes it slower
**Solution**: Update progress every N files (e.g., every 5), not every file. Use efficient echo without subshells.

### Issue 4: Batch operations fail with many files

**Symptom**: "Argument list too long" error
**Solution**: Process files in chunks (e.g., 100 at a time) if dealing with very large packages.

---

## Resources

- [`acp.package-install.sh`](../scripts/acp.package-install.sh): Current implementation
- [`acp.yaml-parser.sh`](../scripts/acp.yaml-parser.sh): YAML operations
- [`acp.common.sh`](../scripts/acp.common.sh): Shared utilities
- [Bash Performance Tips](https://www.gnu.org/software/bash/manual/html_node/Shell-Builtin-Commands.html): Shell optimization guide

---

## Notes

- Focus on the most impactful optimizations first (likely manifest updates and checksums)
- Maintain backward compatibility with existing manifests
- Ensure error handling is not compromised by optimizations
- Consider adding a `--verbose` flag to show detailed timing for debugging
- Profile with `time` command and shell tracing (`set -x`) to identify bottlenecks
- This optimization will benefit all package installations, making ACP more user-friendly

---

**Next Task**: [Task 71: TBD]
**Related Design Docs**: [ACP Package Management System](../design/acp-package-management-system.md)
**Estimated Completion Date**: TBD
