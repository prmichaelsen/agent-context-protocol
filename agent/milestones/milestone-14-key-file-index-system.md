# Milestone 14: Key File Index System

**Status**: Not Started
**Started**: null
**Completed**: null
**Estimated Duration**: 2-3 weeks

---

## Goal

Implement the Key File Index System — a weighted index of critical project files that agents must read before taking action. This prevents agents from silently ignoring existing guardrails, patterns, and designs by providing a curated "must-read" list loaded during initialization, context compaction, and before commands requiring intelligent decisions.

---

## Deliverables

1. `agent/index/` directory with `{namespace}.{qualifier}.yaml` naming convention
2. `local.main.yaml` template for project-level key files
3. Command directive updates for contextual key file reading (@acp.init, @acp.resume, @acp.proceed, @acp.plan, creation commands)
4. `@acp.index` command for managing the index (add, remove, explore, show)
5. Package index support in `@acp.package-install`
6. Validation rules in `@acp.validate` and AGENT.md integration
7. Auto-prompting in creation commands to add new files to index
8. E2E test suite and documentation

---

## Success Criteria

- [ ] `agent/index/local.main.yaml` exists and is loadable by the agent
- [ ] `@acp.init` reads high-weight key files and produces visible output
- [ ] Creation commands contextually read relevant key files before generating content
- [ ] Creation commands prompt to add new files to index
- [ ] `@acp.index` command supports add, remove, explore, show
- [ ] `@acp.package-install` installs package index files to `agent/index/`
- [ ] `@acp.validate` checks index file paths, required fields, and weight ranges
- [ ] AGENT.md references the key file index system
- [ ] Context compaction re-read proposal flow works
- [ ] E2E tests pass for index loading, validation, and package integration

---

## Tasks

| Task | Name | Est. Hours | Status |
|------|------|-----------|--------|
| 99 | Index Directory Infrastructure | 2-3h | Not Started |
| 100 | Command Directive Integration | 3-4h | Not Started |
| 101 | Creation Command Integration | 2-3h | Not Started |
| 102 | @acp.index Command | 3-4h | Not Started |
| 103 | Package Index Support | 3-4h | Not Started |
| 104 | Validation & Documentation | 2-3h | Not Started |
| 105 | Testing | 3-4h | Not Started |

**Total estimated**: 19-25 hours

---

## Design Document

- [Key File Index System Design](../design/local.key-file-index-system.md)

---

## Dependencies

- ACP YAML parser (`acp.yaml-parser.sh`)
- Existing command directives
- Package installation system

---

## Notes

- This milestone was identified in clarification-5-key-file-directive as a standalone milestone
- The index system is directive-level (markdown instructions), not shell-script-level for most commands
- Shell scripting needed for: validation rules, package install support, and potentially `@acp.index explore`
