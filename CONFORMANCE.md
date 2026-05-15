# Scry spec v1.0 conformance

**Declared**: 2026-05-14  
**Spec**: scry-spec v1.0 — `~/.acp/projects/scry-spec/v1.0.md`  
**Scope**: All ACP artifact markers in `agent/` directories

---

## Conformance statement

Agent Context Protocol (ACP) declares conformance to scry-spec v1.0.

All ACP artifact markers use `@scry.entry` / `@scry.entry.end` sentinels with a YAML body
meeting the scry-spec v1.0 required-field contract. The legacy `@acp.meta.*` marker format
has been retired; zero `@acp.meta.*` sentinel blocks exist in current ACP artifacts.

---

## Scope

Conformance applies to:

- All files under `agent/tasks/`, `agent/milestones/`, `agent/clarifications/`,
  `agent/design/`, `agent/patterns/`, `agent/specs/`, `agent/artifacts/`
- All document templates: `task.template.md`, `milestone.template.md`,
  `clarification.template.md`, `design.template.md`, `pattern.template.md`,
  `spec.template.md`, `research.template.md`, `glossary.template.md`,
  `reference.template.md`
- All ACP commands that stamp markers: `acp.task-create`, `acp.spec`,
  `acp.design-create`, `acp.pattern-create`, `acp.clarification-create`

Excluded from scope (historical / frozen):

- Wake reports in `agent/reports/` predating 2026-05-14 (historical records, not ACP artifacts)
- `CHANGELOG.md` prose references (describes the old format; not a marker site)
- `agent/progress.yaml` prose (operational state, not a marker site)

---

## Required fields

Every `@scry.entry` block in ACP satisfies scry-spec v1.0 FR 7 (required fields):

| Field | Required | Notes |
|---|---|---|
| `id` | Yes, non-empty | Minted via `scry_mint_with_check` — format `{kind}.{name}~{8hex}` |
| `kind` | Yes, non-empty | Baseline or ACP custom kind (see below) |
| `summary` | Yes, non-empty | One-line description, ≤150 chars |
| `status` | Yes, may be empty | One of: `draft`, `active`, `approved`, `stale`, `complete`, `completed` |
| `weight` | Yes, may be empty | 0.0–1.0 |
| `tags` | Yes, may be empty | YAML list, `"topic:keyword"` format |
| `rationale` | Yes, may be empty | Why this artifact matters |
| `applies` | Yes, may be empty | When to read this artifact |
| `seeded_questions` | Yes, may be empty | YAML list |

---

## Kind catalog

### Scry baseline kinds (used by ACP)

| Kind | Used for |
|---|---|
| `task` | Work items (tasks) |
| `milestone` | Phase markers with exit criteria |
| `design` | Design documents |
| `spec` | Formal specifications |
| `pattern` | Canonical recipes and reusable patterns |
| `research` | Artifacts: research notes, glossaries, reference docs |

### ACP custom kinds (FR 10 — custom kinds allowed)

| Kind | Used for |
|---|---|
| `clarification` | Clarification documents that resolve design questions |

---

## ACP extension fields (FR 11.5 — parsers MUST NOT error on unknown fields)

ACP carries the following custom fields in `@scry.entry` bodies. Scry-compliant parsers
silently preserve these; they do not break conformance.

| Field | Used in | Meaning |
|---|---|---|
| `milestone` | tasks | Milestone this task belongs to |
| `design` | tasks | Associated design document path |
| `incorporates` | tasks | DR-IDs this task implements |
| `covers` | milestones, specs | Functional or design requirements covered |
| `design_requirements` | designs, specs | DR-ID range defined in this document |
| `depends_on` | designs, tasks | Prerequisite document paths |
| `informs` | designs | Spec this design derives into |
| `started` / `completed` | tasks | Completion timestamps |
| `last_verified` / `confidence` | research artifacts | Research freshness signals |

---

## Parser guidance

Use the official scry parsers to scan ACP artifact markers:

- **Python**: `scry-parse-py` — https://pypi.org/project/scry-parse-py
- **TypeScript/Node**: `scry-parse-ts` — https://www.npmjs.com/package/scry-parse-ts

If your project is bound to the scry MCP driver, query via `scry_sql`:

```sql
SELECT id, kind, summary, status FROM scry__doc WHERE kind = 'task'
```

`agent/scripts/acp.meta-scan.sh` is retired. It parsed the old `@acp.meta.*` format and
no longer produces useful output on a migrated codebase.

---

## Deviations

None. ACP does not deviate from scry-spec v1.0.

ACP extension fields and custom kinds are explicitly permitted by the spec (FR 10, FR 11.5)
and do not constitute deviations.
