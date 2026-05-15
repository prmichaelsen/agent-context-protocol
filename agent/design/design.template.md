# {Feature/Pattern Name}

<!-- @scry.entry
id: design.{name}~{hash}
kind: design
summary: {one-line summary, <=150 chars}
status: draft
weight: 0.7
tags: [{comma-separated "topic:keyword" strings}]
rationale: ""
applies: ""
seeded_questions: []
informs: {agent/specs/{namespace}.{spec-name}.md or omit if no derived spec yet}
depends_on: []
design_requirements: {DR1..DR<N> or DR1, DR3, DR7 — omit if this design has no atomic units worth labeling}
updated: {YYYY-MM-DD}
@scry.entry.end -->

**Concept**: [One-line description of what this design addresses]  
**Created**: YYYY-MM-DD  

> **DR-IDs — atomic design units (Design Requirements).** Label any atomic, addressable chunk of this design with `DR<N>` so tasks can reference it exactly. Label:
>
> - **Key decisions**: `### DR1: Use SM-2 for scheduling`
> - **Code / schema snippets**: `**DR2: user_study_list table**` above a SQL/TS block
> - **Interfaces / type signatures**: `**DR3: WordDefinition contract**`
> - **Algorithms / formulas**: `**DR4: Effective priority calculation**`
> - **Key invariants or rules**: `**DR5: Markers supersede prose frontmatter**`
> - **Diagrams**: `**DR6: Character switching flow**` above an ASCII / mermaid / image block
>
> Prose context around an atomic unit does NOT need a DR-ID — only the atomic unit itself. DR-IDs are what tasks `incorporates:` in their marker.
>
> Keep numbering sequential (`DR1, DR2, DR3, ...`) across the whole document, regardless of section. Populate the marker's `design_requirements:` field with `DR1..DR<N>` (range) or `DR1, DR3, DR7` (list).

---

## Overview

[High-level description of what this design document covers and why it exists. Provide context about the problem space and the importance of this design decision.]

**Example**: "This document describes the authentication flow for multi-tenant access, enabling secure per-user data isolation across the system."  

---

## Problem Statement

[Clearly articulate the problem this design solves. Include:]
- What challenge or limitation exists?
- Why is this a problem worth solving?
- What are the consequences of not solving it?

**Example**: "Without proper multi-tenant isolation, users could potentially access each other's data, creating security vulnerabilities and privacy concerns."  

---

## Solution

[Describe the proposed solution at a conceptual level. Include:]
- High-level approach
- Key components involved
- How the solution addresses the problem
- Alternative approaches considered (and why they were rejected)

**Example**: "Implement row-level security using user_id as a tenant identifier, enforced at both the database and application layers."  

---

## Implementation

[Provide technical details needed to implement this design. Include:]
- Architecture diagrams (as ASCII art or references)
- Data structures and schemas
- API interfaces
- Code examples (use placeholder names)
- Configuration requirements
- Dependencies

**Example**:
```typescript
interface TenantContext {
  userId: string;
  permissions: string[];
}

class DataService {
  constructor(private context: TenantContext) {}
  
  async getData(id: string): Promise<Data> {
    // Implementation with tenant filtering
  }
}
```

---

## Benefits

[List the advantages of this approach:]
- Benefit 1: [Description]
- Benefit 2: [Description]
- Benefit 3: [Description]

**Example**:
- **Security**: Complete data isolation between tenants
- **Scalability**: Horizontal scaling without data mixing concerns
- **Compliance**: Meets data privacy regulations (GDPR, etc.)

---

## Trade-offs

[Honestly assess the downsides and limitations:]
- Trade-off 1: [Description and mitigation strategy]
- Trade-off 2: [Description and mitigation strategy]
- Trade-off 3: [Description and mitigation strategy]

**Example**:
- **Performance**: Additional filtering adds query overhead (mitigated by proper indexing)
- **Complexity**: More complex queries and testing requirements
- **Migration**: Existing data requires backfill with tenant identifiers

---

## Dependencies

[List any dependencies this design has:]
- External services or APIs
- Other design documents
- Infrastructure requirements
- Third-party libraries

---

## Testing Strategy

[Describe how to verify this design works correctly:]
- Unit test requirements
- Integration test scenarios
- Security test cases
- Performance benchmarks

---

## Migration Path

[If this changes existing functionality, describe the migration strategy:]
1. Step 1: [Description]
2. Step 2: [Description]
3. Step 3: [Description]

---

## Key Design Requirements (Optional)

<!-- This section is populated by @acp.clarification-capture when
     create commands are invoked with --from-clar, --from-chat, or
     --from-context. It can also be manually authored.
     Omit this section entirely if no design requirements to capture.

     Group design requirements by agent-inferred category using tables:

### {Category}

| Design Requirement | Choice | Rationale |
|---|---|---|
| {design requirement} | {choice} | {rationale} |
-->

---

## Future Considerations

[Note any future enhancements or related work:]
- Future enhancement 1
- Future enhancement 2
- Related design documents to create

---

**Status**: [Current implementation status]  
**Recommendation**: [What should be done next - implement, review, revise, etc.]  
**Related Documents**: [Links to related design docs, milestones, or tasks]  
