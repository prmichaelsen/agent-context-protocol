# Service Layer Pattern for TypeScript

**Category**: Architecture | Code
**Applicable To**: TypeScript projects with data access needs
**Status**: Stable

---

## Overview

The Service Layer Pattern provides a clear separation between business logic and data access, enabling better testability, maintainability, and code reuse. All data operations (API calls, database operations, external services) go through dedicated service layer classes.

---

## When to Use This Pattern

✅ **Use this pattern when:**
- You have data access operations (database, API, external services)
- You want to isolate business logic from infrastructure concerns
- You need to test business logic independently of data access
- You're building an application with multiple data sources

❌ **Don't use this pattern when:**
- Your application is very simple with minimal data access
- You're building a thin wrapper around a single data source
- The overhead of additional layers outweighs the benefits

---

## Core Principles

1. **Separation of Concerns**: Data access logic is isolated from business logic and presentation
2. **Single Responsibility**: Each service handles one domain concept
3. **Dependency Injection**: Services receive their dependencies rather than creating them
4. **Type Safety**: Services provide strongly-typed interfaces

---

## Service Types

### 1. Data Access Services
**Purpose**: Direct database/storage operations
**Naming**: `{Domain}DataService` or `{Domain}Repository`
**Used By**: API handlers, server-side code, background jobs

**Characteristics**:
- Directly interacts with database/storage
- Server-side only
- Handles data validation
- Manages timestamps and metadata
- Returns typed data models

### 2. API Client Services
**Purpose**: Wrap API endpoint calls for client-side use
**Naming**: `{Domain}ApiService` or `{Domain}Client`
**Used By**: UI components, client-side code

**Characteristics**:
- Calls HTTP endpoints
- Client-side safe
- Handles HTTP errors
- Returns typed data models

---

## Implementation

### Data Access Service Example

```typescript
// src/services/user-data.service.ts

export interface User {
  id: string;
  email: string;
  name: string;
  created_at: string;
  updated_at: string;
}

export interface CreateUserInput {
  email: string;
  name: string;
}

export class UserDataService {
  constructor(private db: DatabaseClient) {}

  async getUser(id: string): Promise<User | null> {
    try {
      const user = await this.db.findOne('users', { id });
      
      if (!user) return null;
      
      // Validate data structure
      return this.validateUser(user);
    } catch (error) {
      console.error(`Failed to get user ${id}:`, error);
      throw error;
    }
  }

  async createUser(input: CreateUserInput): Promise<User> {
    try {
      const now = new Date().toISOString();
      
      const user: User = {
        id: generateId(),
        ...input,
        created_at: now,
        updated_at: now,
      };
      
      await this.db.insert('users', user);
      
      return user;
    } catch (error) {
      console.error('Failed to create user:', error);
      throw error;
    }
  }

  async updateUser(id: string, updates: Partial<User>): Promise<User> {
    try {
      const user = await this.getUser(id);
      if (!user) throw new Error(`User ${id} not found`);
      
      const updated: User = {
        ...user,
        ...updates,
        updated_at: new Date().toISOString(),
      };
      
      await this.db.update('users', { id }, updated);
      
      return updated;
    } catch (error) {
      console.error(`Failed to update user ${id}:`, error);
      throw error;
    }
  }

  private validateUser(data: any): User {
    // Add validation logic (e.g., using Zod, Yup, etc.)
    if (!data.id || !data.email) {
      throw new Error('Invalid user data');
    }
    return data as User;
  }
}
```

### API Client Service Example

```typescript
// src/services/user-api.service.ts

export class UserApiService {
  constructor(private baseUrl: string) {}

  async getUser(id: string): Promise<User | null> {
    try {
      const response = await fetch(`${this.baseUrl}/users/${id}`);
      
      if (response.status === 404) return null;
      
      if (!response.ok) {
        throw new Error(`Failed to fetch user: ${response.statusText}`);
      }
      
      return await response.json();
    } catch (error) {
      console.error(`Failed to fetch user ${id}:`, error);
      throw error;
    }
  }

  async createUser(input: CreateUserInput): Promise<User> {
    try {
      const response = await fetch(`${this.baseUrl}/users`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(input),
      });
      
      if (!response.ok) {
        throw new Error(`Failed to create user: ${response.statusText}`);
      }
      
      return await response.json();
    } catch (error) {
      console.error('Failed to create user:', error);
      throw error;
    }
  }

  async updateUser(id: string, updates: Partial<User>): Promise<User> {
    try {
      const response = await fetch(`${this.baseUrl}/users/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(updates),
      });
      
      if (!response.ok) {
        throw new Error(`Failed to update user: ${response.statusText}`);
      }
      
      return await response.json();
    } catch (error) {
      console.error(`Failed to update user ${id}:`, error);
      throw error;
    }
  }
}
```

---

## Usage Examples

### In Server-Side Code

```typescript
import { UserDataService } from './services/user-data.service';

// API handler
async function handleGetUser(req: Request): Promise<Response> {
  const userId = req.params.id;
  const userService = new UserDataService(database);
  
  const user = await userService.getUser(userId);
  
  if (!user) {
    return new Response('Not found', { status: 404 });
  }
  
  return Response.json(user);
}
```

### In Client-Side Code

```typescript
import { UserApiService } from './services/user-api.service';

// React component
function UserProfile({ userId }: { userId: string }) {
  const [user, setUser] = useState<User | null>(null);
  const userApi = new UserApiService('/api');
  
  useEffect(() => {
    userApi.getUser(userId)
      .then(setUser)
      .catch(console.error);
  }, [userId]);
  
  if (!user) return <div>Loading...</div>;
  
  return <div>{user.name}</div>;
}
```

---

## Benefits

### 1. Testability
```typescript
// Easy to mock services in tests
const mockUserService = {
  getUser: jest.fn().mockResolvedValue({ id: '1', name: 'Test' }),
  createUser: jest.fn(),
  updateUser: jest.fn(),
};

test('component loads user', async () => {
  // Test component behavior with mocked service
});
```

### 2. Consistency
- All data operations follow the same pattern
- Consistent error handling and logging
- Consistent validation approach

### 3. Maintainability
- Change database structure in one place
- Update API endpoints in one place
- Easy to add caching, retry logic, etc.

### 4. Type Safety
- Services provide typed interfaces
- No `any` types leaking into application code
- Compile-time checking of data access

---

## Anti-Patterns

### ❌ Anti-Pattern 1: Direct Data Access in Components

**Description**: Directly accessing database or making API calls from UI components.

**Why it's bad**: Tight coupling, hard to test, duplicated logic.

```typescript
// ❌ Bad: Direct database access in component
function UserProfile({ userId }: Props) {
  useEffect(() => {
    database.findOne('users', { id: userId })
      .then(setUser);
  }, [userId]);
}

// ✅ Good: Use service layer
function UserProfile({ userId }: Props) {
  const userService = new UserApiService('/api');
  
  useEffect(() => {
    userService.getUser(userId)
      .then(setUser);
  }, [userId]);
}
```

### ❌ Anti-Pattern 2: God Service

**Description**: Creating a single service class that handles all business logic.

**Why it's bad**: Violates single responsibility, becomes difficult to test and maintain.

```typescript
// ❌ Bad: Everything in one service
class ApplicationService {
  createUser() {}
  deleteUser() {}
  createProduct() {}
  deleteProduct() {}
  processPayment() {}
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

### ❌ Anti-Pattern 3: Mixing Concerns

**Description**: Putting UI logic or presentation concerns in service layer.

**Why it's bad**: Services become coupled to specific UI frameworks.

```typescript
// ❌ Bad: UI logic in service
class UserService {
  async saveUser(user: User): Promise<void> {
    await this.db.save(user);
    showToast('User saved!'); // UI logic in service!
  }
}

// ✅ Good: Keep services pure
class UserService {
  async saveUser(user: User): Promise<void> {
    await this.db.save(user);
    // Return result, let caller handle UI
  }
}

// Handle UI in component
async function handleSave() {
  await userService.saveUser(user);
  showToast('User saved!'); // UI logic in component
}
```

---

## Testing Strategy

### Unit Testing Services

```typescript
describe('UserDataService', () => {
  let service: UserDataService;
  let mockDb: jest.Mocked<DatabaseClient>;
  
  beforeEach(() => {
    mockDb = {
      findOne: jest.fn(),
      insert: jest.fn(),
      update: jest.fn(),
    } as any;
    
    service = new UserDataService(mockDb);
  });
  
  it('should get user by id', async () => {
    const mockUser = { id: '1', email: 'test@example.com', name: 'Test' };
    mockDb.findOne.mockResolvedValue(mockUser);
    
    const user = await service.getUser('1');
    
    expect(user).toEqual(mockUser);
    expect(mockDb.findOne).toHaveBeenCalledWith('users', { id: '1' });
  });
  
  it('should return null for non-existent user', async () => {
    mockDb.findOne.mockResolvedValue(null);
    
    const user = await service.getUser('999');
    
    expect(user).toBeNull();
  });
});
```

---

## Related Patterns

- **[Repository Pattern](./repository-pattern.md)**: Alternative approach focusing on collection-like interface
- **[Factory Pattern](./factory-pattern.md)**: Can be used to create service instances
- **[Dependency Injection](./dependency-injection.md)**: Essential for implementing this pattern correctly

---

## Migration Guide

### Step 1: Identify Direct Data Access
Search codebase for:
- Direct database calls
- Direct `fetch()` calls
- Inline data manipulation

### Step 2: Create Service Classes
```typescript
// Create service for each domain
export class DomainDataService {
  async operation(): Promise<Result> {
    // Move data access logic here
  }
}
```

### Step 3: Update Callers
```typescript
// Before
const data = await database.find('collection', query);

// After
const service = new DomainDataService(database);
const data = await service.findData(query);
```

### Step 4: Add Tests
- Write unit tests for services
- Mock services in component/handler tests
- Verify functionality unchanged

---

## Checklist for Implementation

- [ ] Services are focused on single domain concepts
- [ ] Dependencies are injected, not created internally
- [ ] Business logic is isolated from infrastructure concerns
- [ ] Services have clear, well-documented interfaces
- [ ] Unit tests cover business logic in isolation
- [ ] Integration tests verify end-to-end functionality
- [ ] Error handling is consistent and appropriate
- [ ] Logging provides adequate visibility
- [ ] No UI logic in services
- [ ] Type safety maintained throughout

---

**Status**: Stable
**Recommendation**: Use for any TypeScript project with data access needs
**Last Updated**: 2026-02-13
