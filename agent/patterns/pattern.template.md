# {Pattern Name}

**Category**: [Architecture | Design | Code | Testing | Deployment]  
**Applicable To**: [What types of projects or components this pattern applies to]  
**Status**: [Stable | Experimental | Deprecated]  

---

## Overview

[Provide a high-level description of what this pattern is and when to use it. Include the problem space it addresses and the general approach it takes.]

**Example**: "The Service Layer Pattern provides a clear separation between business logic and data access, enabling better testability, maintainability, and code reuse across different interfaces (API, CLI, etc.)."  

---

## When to Use This Pattern

[Describe the scenarios where this pattern is appropriate:]

✅ **Use this pattern when:**
- Condition 1
- Condition 2
- Condition 3

❌ **Don't use this pattern when:**
- Condition 1
- Condition 2
- Condition 3

**Example**:

✅ **Use this pattern when:**
- You have complex business logic that needs to be shared across multiple interfaces
- You want to isolate business logic from infrastructure concerns
- You need to test business logic independently of data access

❌ **Don't use this pattern when:**
- Your application is very simple with minimal business logic
- You're building a thin wrapper around a database
- The overhead of additional layers outweighs the benefits

---

## Core Principles

[List the fundamental concepts that underpin this pattern:]

1. **Principle 1**: [Description]
2. **Principle 2**: [Description]
3. **Principle 3**: [Description]
4. **Principle 4**: [Description]

**Example**:

1. **Separation of Concerns**: Business logic is isolated from data access and presentation
2. **Single Responsibility**: Each service handles one domain concept
3. **Dependency Injection**: Services receive their dependencies rather than creating them
4. **Interface-Based Design**: Services depend on abstractions, not concrete implementations

---

## Implementation

[Provide detailed implementation guidance with code examples:]

### Structure

[Describe the overall structure of the pattern]

```
directory-structure/
├── component1/
│   └── file1.ext
└── component2/
    └── file2.ext
```

### Code Example

[Provide a complete, working example:]

```typescript
// Example implementation
interface ExampleInterface {
  method(): Promise<Result>;
}

class ExampleImplementation implements ExampleInterface {
  constructor(private dependency: Dependency) {}
  
  async method(): Promise<Result> {
    // Implementation
    return result;
  }
}
```

### Key Components

[Break down the major components:]

#### Component 1: [Name]
[Description and purpose]

```typescript
// Code example for this component
```

#### Component 2: [Name]
[Description and purpose]

```typescript
// Code example for this component
```

---

## Examples

[Provide multiple real-world examples showing different use cases:]

### Example 1: [Use Case Name]

[Description of the scenario]

```typescript
// Complete code example
class ConcreteExample {
  // Implementation
}

// Usage
const example = new ConcreteExample();
const result = await example.doSomething();
```

### Example 2: [Use Case Name]

[Description of the scenario]

```typescript
// Complete code example
```

---

## Benefits

[List the advantages of using this pattern:]

### 1. [Benefit Name]
[Detailed explanation of this benefit and why it matters]

### 2. [Benefit Name]
[Detailed explanation of this benefit and why it matters]

### 3. [Benefit Name]
[Detailed explanation of this benefit and why it matters]

**Example**:

### 1. Testability
Business logic can be tested in isolation without requiring database connections or external services. Mock dependencies can be easily injected for unit testing.

### 2. Reusability
The same business logic can be used across multiple interfaces (REST API, GraphQL, CLI, etc.) without duplication.

### 3. Maintainability
Changes to business logic are centralized in service classes, making the codebase easier to understand and modify.

---

## Trade-offs

[Honestly assess the downsides and limitations:]

### 1. [Trade-off Name]
**Downside**: [Description]  
**Mitigation**: [How to minimize this downside]  

### 2. [Trade-off Name]
**Downside**: [Description]  
**Mitigation**: [How to minimize this downside]  

**Example**:

### 1. Additional Complexity
**Downside**: Adds extra layers and files to the codebase, which can feel like over-engineering for simple applications.  
**Mitigation**: Only apply this pattern when complexity justifies it. Start simple and refactor to this pattern as needs grow.  

### 2. Performance Overhead
**Downside**: Additional function calls and abstractions can add minor performance overhead.  
**Mitigation**: In most applications, this overhead is negligible. Profile before optimizing.  

---

## Anti-Patterns

[Document what NOT to do - common mistakes and misuses:]

### ❌ Anti-Pattern 1: [Name]

**Description**: [What people do wrong]  

**Why it's bad**: [Consequences]  

**Instead, do this**: [Correct approach]  

```typescript
// ❌ Bad example
class BadExample {
  // What not to do
}

// ✅ Good example
class GoodExample {
  // Correct approach
}
```

### ❌ Anti-Pattern 2: [Name]

[Similar structure as above]

**Example**:

### ❌ Anti-Pattern 1: God Service

**Description**: Creating a single service class that handles all business logic for the entire application.  

**Why it's bad**: Violates single responsibility principle, becomes difficult to test and maintain, creates tight coupling.  

**Instead, do this**: Create focused services, each handling a specific domain concept.  

```typescript
// ❌ Bad: Everything in one service
class ApplicationService {
  createUser() {}
  deleteUser() {}
  createProduct() {}
  deleteProduct() {}
  processPayment() {}
  sendEmail() {}
}

// ✅ Good: Focused services
class UserService {
  createUser() {}
  deleteUser() {}
}

class ProductService {
  createProduct() {}
  deleteProduct() {}
}

class PaymentService {
  processPayment() {}
}
```

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

## Testing Strategy

[Describe how to test code that uses this pattern:]

### Unit Testing
[Approach for unit tests]

```typescript
// Example unit test
describe('ExampleService', () => {
  it('should do something', async () => {
    // Test implementation
  });
});
```

### Integration Testing
[Approach for integration tests]

```typescript
// Example integration test
```

---

## Related Patterns

[Link to related patterns and explain relationships:]

- **[Pattern Name](./pattern-name.md)**: [How it relates]
- **[Pattern Name](./pattern-name.md)**: [How it relates]
- **[Pattern Name](./pattern-name.md)**: [How it relates]

**Example**:
- **[Repository Pattern](./repository-pattern.md)**: Often used together; services use repositories for data access
- **[Factory Pattern](./factory-pattern.md)**: Can be used to create service instances with proper dependencies
- **[Dependency Injection](./dependency-injection.md)**: Essential for implementing this pattern correctly

---

## Migration Guide

[If adopting this pattern in an existing codebase, provide migration steps:]

### Step 1: [Action]
[Detailed description]

### Step 2: [Action]
[Detailed description]

### Step 3: [Action]
[Detailed description]

**Example**:

### Step 1: Identify Business Logic
Review existing code and identify business logic that's currently mixed with data access or presentation code.

### Step 2: Extract to Services
Create service classes and move business logic into them. Start with the most complex or frequently used logic.

### Step 3: Refactor Dependencies
Update calling code to use the new services. Inject dependencies rather than creating them directly.

---

## References

[Link to external resources, papers, books, or articles:]

- [Resource 1](URL): Description
- [Resource 2](URL): Description
- [Resource 3](URL): Description

**Example**:
- [Martin Fowler - Service Layer](https://martinfowler.com/eaaCatalog/serviceLayer.html): Original pattern description
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html): Related architectural concepts
- [Domain-Driven Design](https://www.domainlanguage.com/ddd/): Context for service design

---

## Checklist for Implementation

[Provide a checklist to ensure proper implementation:]

- [ ] Services are focused on single domain concepts
- [ ] Dependencies are injected, not created internally
- [ ] Business logic is isolated from infrastructure concerns
- [ ] Services have clear, well-documented interfaces
- [ ] Unit tests cover business logic in isolation
- [ ] Integration tests verify end-to-end functionality
- [ ] Error handling is consistent and appropriate
- [ ] Logging provides adequate visibility

---

**Status**: [Current status of this pattern document]  
**Recommendation**: [When and how to use this pattern]  
**Last Updated**: [YYYY-MM-DD]  
**Contributors**: [Names or "Community"]  
