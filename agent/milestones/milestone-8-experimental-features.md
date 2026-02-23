# Milestone 8: Experimental Features System

**Goal**: Implement system for marking and managing experimental features with --experimental flag
**Duration**: 1-2 weeks
**Dependencies**: Milestone 3 (Package Management System), Milestone 4 (Package Development System)
**Status**: Not Started

---

## Overview

This milestone implements a comprehensive system for marking commands, patterns, designs, and scripts as "experimental" to exclude them from standard installations and updates. The system uses dual marking (package.yaml + file metadata) to ensure consistency and provide both installation control and clear documentation.

**Key Deliverables**:
- Schema enhancement with `experimental` field
- Installation filtering with `--experimental` flag
- Update handling for experimental features
- Validation for experimental marking consistency
- Complete documentation and examples

---

## Deliverables

### Phase 1: Schema and Validation
- [ ] Update `agent/schemas/package.schema.yaml` with experimental field
- [ ] Enhance `agent/scripts/acp.package-validate.sh` with consistency checks
- [ ] Add validation for experimental marking (package.yaml ↔ file metadata)
- [ ] Test validation with sample packages

### Phase 2: Installation Filtering
- [ ] Add `--experimental` flag to `agent/scripts/acp.package-install.sh`
- [ ] Implement `should_install_file()` filtering function
- [ ] Skip experimental features without flag
- [ ] Install experimental features with flag
- [ ] Update manifest tracking for experimental status
- [ ] Test installation with and without flag

### Phase 3: Update Handling
- [ ] Enhance `agent/scripts/acp.package-update.sh` for experimental features
- [ ] Implement `is_experimental_installed()` check function
- [ ] Update already-installed experimental features normally
- [ ] Skip new experimental features without flag
- [ ] Test update scenarios (installed vs new experimental)

### Phase 4: Documentation and Examples
- [ ] Update `agent/commands/acp.package-install.md` with --experimental flag
- [ ] Update `agent/commands/acp.package-update.md` with experimental behavior
- [ ] Update `agent/commands/acp.package-validate.md` with consistency checks
- [ ] Update `AGENT.md` with experimental features section
- [ ] Update `README.md` with experimental features examples
- [ ] Create example package with experimental features
- [ ] Update `CHANGELOG.md` with new feature

---

## Success Criteria

- [ ] Schema supports optional `experimental: true` field in contents arrays
- [ ] Validation detects inconsistent experimental marking
- [ ] Installation without `--experimental` skips experimental features
- [ ] Installation with `--experimental` includes experimental features
- [ ] Updates handle experimental features correctly (installed vs new)
- [ ] Manifest tracks experimental status
- [ ] All documentation updated with examples
- [ ] Test package demonstrates experimental features
- [ ] Backward compatible (existing packages work unchanged)

---

## Key Files to Create/Modify

**Modified Files**:
- `agent/schemas/package.schema.yaml` - Add experimental field
- `agent/scripts/acp.package-install.sh` - Add --experimental flag and filtering
- `agent/scripts/acp.package-update.sh` - Handle experimental features
- `agent/scripts/acp.package-validate.sh` - Add consistency validation
- `agent/commands/acp.package-install.md` - Document --experimental flag
- `agent/commands/acp.package-update.md` - Document experimental behavior
- `agent/commands/acp.package-validate.md` - Document consistency checks
- `AGENT.md` - Add experimental features section
- `README.md` - Add experimental features examples
- `CHANGELOG.md` - Document new feature

**New Files**:
- `agent/tasks/milestone-8-experimental-features/task-61-schema-validation.md`
- `agent/tasks/milestone-8-experimental-features/task-62-installation-filtering.md`
- `agent/tasks/milestone-8-experimental-features/task-63-update-handling.md`
- `agent/tasks/milestone-8-experimental-features/task-64-documentation.md`

---

## Dependencies

- **Milestone 3**: Package Management System (install, update, validate scripts)
- **Milestone 4**: Package Development System (schema validation, package.yaml structure)
- **YAML Parser**: Must support querying experimental field (already supported)

---

## Risks and Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Complexity for package maintainers | Medium | Clear documentation, validation ensures consistency |
| Discovery challenge (users don't know experimental features exist) | Low | Future enhancement: --list-experimental flag |
| Testing complexity (with/without flag) | Medium | Comprehensive test suite with both scenarios |
| Backward compatibility concerns | Low | Optional field, defaults to false, existing packages unchanged |

---

## Testing Strategy

### Unit Tests
- Installation filtering (with/without --experimental)
- Update behavior (installed vs new experimental)
- Validation consistency checks

### Integration Tests
- Create test package with experimental features
- Install without flag → verify only stable features
- Install with flag → verify all features
- Update scenarios → verify correct behavior
- Validation → verify consistency checks

### Edge Cases
- Experimental field missing (defaults to false)
- Status: Experimental in file but not in package.yaml
- Upgrading from old package format
- Graduating features from experimental to stable

---

## Timeline

**Week 1**:
- Task 61: Schema and Validation (2-3 hours)
- Task 62: Installation Filtering (3-4 hours)
- Task 63: Update Handling (2-3 hours)

**Week 2**:
- Task 64: Documentation and Examples (3-4 hours)
- Testing and refinement (2-3 hours)
- CHANGELOG and version bump (1 hour)

**Total Estimated**: 13-18 hours (1-2 weeks)

---

**Next Milestone**: TBD (Future enhancements: --list-experimental, graduation workflow, deprecation system)
**Blockers**: None
**Related Design**: [`agent/design/local.experimental-features-system.md`](../design/local.experimental-features-system.md)
