# {Feature/Pattern Name}

<!-- @acp.meta.design
topic: {comma-separated keywords}
description: {one-line summary, <=150 chars}
informs: {agent/specs/{namespace}.{spec-name}.md or omit if no derived spec yet}
depends_on: {other design paths or omit}
decisions: {D1..D<N> or D1, D3, D7 — omit if this design has no atomic units worth labeling}
status: draft
updated: {YYYY-MM-DD}
@acp.meta.end -->

**Concept**: [One-line description of what this design addresses]  
**Created**: YYYY-MM-DD  

> **D-IDs — atomic design units.** Label any atomic, addressable chunk of this design with `D<N>` so tasks can reference it exactly. Label:
>
> - **Key decisions**: `### D1: Use SM-2 for scheduling`
> - **Code / schema snippets**: `**D2: user_study_list table**` above a SQL/TS block
> - **Interfaces / type signatures**: `**D3: WordDefinition contract**`
> - **Algorithms / formulas**: `**D4: Effective priority calculation**`
> - **Key invariants or rules**: `**D5: Markers supersede prose frontmatter**`
> - **Diagrams**: `**D6: Character switching flow**` above an ASCII / mermaid / image block
>
> Prose context around an atomic unit does NOT need a D-ID — only the atomic unit itself. D-IDs are what tasks `incorporates:` in their marker.
>
> Keep numbering sequential (`D1, D2, D3, ...`) across the whole document, regardless of section. Populate the marker's `decisions:` field with `D1..D<N>` (range) or `D1, D3, D7` (list).

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

## Key Design Decisions (Optional)

<!-- This section is populated by @acp.clarification-capture when
     create commands are invoked with --from-clar, --from-chat, or
     --from-context. It can also be manually authored.
     Omit this section entirely if no decisions to capture.

     Group decisions by agent-inferred category using tables:

### {Category}

| Decision | Choice | Rationale |
|---|---|---|
| {decision} | {choice} | {rationale} |
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
