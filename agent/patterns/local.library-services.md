# library-services

**Version**: 1.0.0  
**Last Updated**: 2026-02-20  
**Namespace**: local  

---

## Overview

Service layer, database layer, and API client layer architecture pattern for TypeScript libraries. This pattern establishes a clean separation of concerns with three distinct layers that work together to provide robust, testable, and maintainable library code.

## Problem

TypeScript libraries often suffer from:
- **Tight coupling** between business logic and data access
- **Difficult testing** due to hard-coded dependencies
- **Poor separation** of concerns
- **Inconsistent patterns** across different parts of the codebase
- **Hard to mock** external dependencies (databases, APIs)
- **Unclear boundaries** between layers

## Solution

Implement a three-layer architecture:

1. **Service Layer** - Business logic and orchestration
2. **Database Layer** - Data access and persistence
3. **API Client Layer** - External API communication

Each layer has clear responsibilities and dependencies flow in one direction:
```
Service Layer → Database Layer → Database
Service Layer → API Client Layer → External APIs
```

## Implementation

### Layer 1: Database Layer

**Purpose**: Encapsulate all database operations  

```typescript
// database/user-repository.ts
export class UserRepository {
  constructor(private db: Database) {}
  
  async findById(userId: string): Promise<User | null> {
    const doc = await this.db.collection('users').doc(userId).get();
    return doc.exists ? doc.data() as User : null;
  }
  
  async create(user: User): Promise<void> {
    await this.db.collection('users').doc(user.id).set(user);
  }
  
  async update(userId: string, updates: Partial<User>): Promise<void> {
    await this.db.collection('users').doc(userId).update(updates);
  }
  
  async delete(userId: string): Promise<void> {
    await this.db.collection('users').doc(userId).delete();
  }
}
```

**Key Principles**:
- One repository per entity
- Methods return domain objects, not database documents
- All database-specific code isolated here
- Easy to mock for testing

### Layer 2: API Client Layer

**Purpose**: Encapsulate external API calls  

```typescript
// api/github-client.ts
export class GitHubClient {
  constructor(
    private apiKey: string,
    private baseUrl: string = 'https://api.github.com'
  ) {}
  
  async getUser(username: string): Promise<GitHubUser> {
    const response = await fetch(`${this.baseUrl}/users/${username}`, {
      headers: { 'Authorization': `Bearer ${this.apiKey}` }
    });
    
    if (!response.ok) {
      throw new Error(`GitHub API error: ${response.statusText}`);
    }
    
    return response.json();
  }
  
  async getRepos(username: string): Promise<GitHubRepo[]> {
    const response = await fetch(`${this.baseUrl}/users/${username}/repos`, {
      headers: { 'Authorization': `Bearer ${this.apiKey}` }
    });
    
    if (!response.ok) {
      throw new Error(`GitHub API error: ${response.statusText}`);
    }
    
    return response.json();
  }
}
```

**Key Principles**:
- One client per external service
- Handle authentication and error handling
- Return typed responses
- Easy to mock for testing

### Layer 3: Service Layer

**Purpose**: Business logic and orchestration  

```typescript
// services/user-service.ts
export class UserService {
  constructor(
    private userRepo: UserRepository,
    private githubClient: GitHubClient
  ) {}
  
  async getUserProfile(userId: string): Promise<UserProfile> {
    // Get user from database
    const user = await this.userRepo.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }
    
    // Enrich with GitHub data if available
    let githubData = null;
    if (user.githubUsername) {
      try {
        githubData = await this.githubClient.getUser(user.githubUsername);
      } catch (error) {
        // Log error but don't fail - GitHub data is optional
        console.error('Failed to fetch GitHub data:', error);
      }
    }
    
    // Combine data
    return {
      ...user,
      github: githubData
    };
  }
  
  async createUser(userData: CreateUserInput): Promise<User> {
    // Validate input
    if (!userData.email || !userData.name) {
      throw new Error('Email and name are required');
    }
    
    // Create user object
    const user: User = {
      id: generateId(),
      ...userData,
      createdAt: new Date(),
      updatedAt: new Date()
    };
    
    // Save to database
    await this.userRepo.create(user);
    
    return user;
  }
}
```

**Key Principles**:
- Services orchestrate between layers
- Business logic lives here
- Services depend on repositories and clients (injected)
- Easy to test with mocked dependencies

### Dependency Injection

Wire everything together:

```typescript
// index.ts
import { Firestore } from '@google-cloud/firestore';
import { UserRepository } from './database/user-repository';
import { GitHubClient } from './api/github-client';
import { UserService } from './services/user-service';

// Initialize dependencies
const db = new Firestore();
const userRepo = new UserRepository(db);
const githubClient = new GitHubClient(process.env.GITHUB_API_KEY!);

// Create service with injected dependencies
const userService = new UserService(userRepo, githubClient);

// Export service
export { userService };
```

### Testing

Each layer can be tested independently:

```typescript
// services/user-service.test.ts
describe('UserService', () => {
  let userService: UserService;
  let mockUserRepo: jest.Mocked<UserRepository>;
  let mockGitHubClient: jest.Mocked<GitHubClient>;
  
  beforeEach(() => {
    // Create mocks
    mockUserRepo = {
      findById: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn()
    } as any;
    
    mockGitHubClient = {
      getUser: jest.fn(),
      getRepos: jest.fn()
    } as any;
    
    // Inject mocks
    userService = new UserService(mockUserRepo, mockGitHubClient);
  });
  
  it('should get user profile with GitHub data', async () => {
    // Arrange
    const user = { id: '123', name: 'Test', githubUsername: 'testuser' };
    const githubData = { login: 'testuser', followers: 100 };
    
    mockUserRepo.findById.mockResolvedValue(user);
    mockGitHubClient.getUser.mockResolvedValue(githubData);
    
    // Act
    const profile = await userService.getUserProfile('123');
    
    // Assert
    expect(profile).toEqual({ ...user, github: githubData });
    expect(mockUserRepo.findById).toHaveBeenCalledWith('123');
    expect(mockGitHubClient.getUser).toHaveBeenCalledWith('testuser');
  });
});
```

## Benefits

### 1. Separation of Concerns
- Each layer has a single responsibility
- Changes to one layer don't affect others
- Clear boundaries make code easier to understand

### 2. Testability
- Each layer can be tested independently
- Easy to mock dependencies
- Fast unit tests (no real database/API calls)
- High test coverage achievable

### 3. Maintainability
- Changes are localized to specific layers
- Easy to find where logic lives
- Consistent patterns across codebase
- New developers can understand quickly

### 4. Flexibility
- Easy to swap implementations (e.g., different database)
- Can add caching layer without changing services
- Can add retry logic in API client without changing services
- Supports multiple databases or APIs

### 5. Reusability
- Repositories can be reused across services
- API clients can be reused across services
- Services can be composed together

## Trade-offs

### 1. More Files and Classes
**Downside**: More boilerplate code, more files to navigate  

**Mitigation**: 
- Use consistent naming conventions
- Group by layer in directory structure
- Benefits outweigh costs for medium+ projects

### 2. Indirection
**Downside**: More layers to trace through when debugging  

**Mitigation**:
- Clear naming makes flow obvious
- Good logging at layer boundaries
- IDE navigation tools help

### 3. Over-Engineering for Simple Cases
**Downside**: Overkill for simple CRUD operations  

**Mitigation**:
- Use for complex business logic
- Simple operations can bypass service layer
- Apply pattern where it adds value

### 4. Dependency Injection Complexity
**Downside**: Need to wire dependencies together  

**Mitigation**:
- Use DI container for large projects
- Manual injection fine for small projects
- Clear initialization in index.ts

## When to Use

✅ **Use this pattern when**:
- Building libraries with complex business logic
- Need high test coverage
- Multiple developers on team
- Long-term maintenance expected
- Integrating multiple external services

❌ **Don't use when**:
- Simple CRUD operations only
- Prototype or throwaway code
- Single developer, short-term project
- Performance is critical (extra layers add overhead)

---

**Status**: Production Ready  
**Recommendation**: Use for TypeScript libraries with complex business logic and external integrations  
