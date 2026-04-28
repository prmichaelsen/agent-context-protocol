# [Reference Title]

<!-- @acp.meta.artifact
topic: {comma-separated keywords}
last_verified: {YYYY-MM-DD}
confidence: high
status: active
updated: {YYYY-MM-DD}
@acp.meta.end -->

**Type**: reference
**Created**: YYYY-MM-DD
**Category**: [Domain-specific category, e.g., "Configuration", "Standards", "Troubleshooting"]
**Sources**: [List of primary sources with access dates]

---

## Purpose

<!-- Brief description of what this reference covers and when to use it -->

[1-2 sentence description of the reference purpose and use cases]

---

## Command-First Principle Check

<!-- This reference contains passive information that cannot be automated as a command -->

**Could this be a command?** No
**Reason**: [Brief explanation of why this is passive information vs executable directive]

---

## Content

<!-- Structure varies by reference type. Examples below: -->

<!-- FOR CONFIGURATION TABLES -->
### Configuration Reference

| Variable | Type | Default | Description | Required |
|----------|------|---------|-------------|----------|
| `[VAR_NAME]` | string | `[value]` | [Description] | Yes/No |
| `[VAR_NAME]` | number | `[value]` | [Description] | Yes/No |

<!-- FOR CLI SYNTAX -->
### Command Syntax

```bash
# [Command description]
[command] [options] [arguments]

# Options:
#   -a, --flag-a    [Description]
#   -b, --flag-b    [Description]

# Examples:
[command] --flag-a value
[command] --flag-b value1 value2
```

<!-- FOR STANDARDS/CONVENTIONS -->
### Standards

#### [Standard Category 1]

- **Rule 1**: [Description]
  - Example: `[code example]`
  - Rationale: [Why this standard exists]

- **Rule 2**: [Description]
  - Example: `[code example]`
  - Rationale: [Why this standard exists]

<!-- FOR ARCHITECTURE DIAGRAMS -->
### Architecture Overview

```
[ASCII diagram or mermaid diagram]
```

**Component Descriptions:**
- **[Component 1]**: [Purpose and responsibilities]
- **[Component 2]**: [Purpose and responsibilities]

<!-- FOR DATA SCHEMAS -->
### Schema Definition

```json
{
  "field1": "type",
  "field2": {
    "nested": "value"
  }
}
```

**Field Descriptions:**
- `field1`: [Description, constraints, examples]
- `field2.nested`: [Description, constraints, examples]

<!-- FOR TROUBLESHOOTING GUIDES -->
### Troubleshooting Decision Tree

**Symptom**: [Observable issue]

1. **Check [Thing 1]**
   - If [condition]: [Resolution]
   - If not: Go to step 2

2. **Check [Thing 2]**
   - If [condition]: [Resolution]
   - If not: Go to step 3

3. **Check [Thing 3]**
   - If [condition]: [Resolution]
   - If not: [Escalation path]

<!-- FOR API/PROTOCOL CONTRACTS -->
### API Contract

**Endpoint**: `[HTTP METHOD] /path/to/endpoint`

**Request Format:**
```json
{
  "field": "value"
}
```

**Response Format:**
```json
{
  "status": "success",
  "data": {}
}
```

**Error Codes:**
| Code | Meaning | Resolution |
|------|---------|------------|
| 400 | [Description] | [How to fix] |
| 404 | [Description] | [How to fix] |

---

## Sources & References

1. **[Source Name]**
   - URL: [Exact URL]
   - Date Accessed: YYYY-MM-DD
   - Attribution: [Author/Organization]
   - Version: [Version number if applicable]

2. **[Source Name]**
   - URL: [Exact URL]
   - Date Accessed: YYYY-MM-DD
   - Attribution: [Author/Organization]
   - Version: [Version number if applicable]

---

## Related Documents

- [Link to relevant commands]
- [Link to relevant design documents]
- [Link to relevant research artifacts]
