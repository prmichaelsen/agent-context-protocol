# Task 4: Workspace Multi-tenancy

**Status:** not_started
**Milestone:** M1 — Foundation & Stabilization
**Estimated Hours:** 4
**Depends On:** task-3

## Objective

Implement workspace-based multi-tenancy so that all resources are scoped
to a workspace. Users can belong to multiple workspaces and only see data
within the workspace specified by the request context.

## Requirements

- Create Workspace model:
  - Fields: id, name, slug, ownerId, createdAt, updatedAt
  - Members collection: userId, role, joinedAt
- Add `x-workspace-id` header middleware:
  - Extract workspace ID from request header
  - Validate workspace exists
  - Verify requesting user is a member of the workspace
  - Attach workspace context to request object
  - Return 400 if header missing on workspace-scoped routes
  - Return 403 if user is not a member
- Scope all existing queries by workspace:
  - Tasks: add workspaceId field, filter all queries
  - Projects: add workspaceId field, filter all queries
  - Users: scoped through workspace membership
- Implement Workspace CRUD API:
  - POST /workspaces — Create workspace (creator becomes owner)
  - GET /workspaces — List user's workspaces
  - GET /workspaces/:id — Get workspace details
  - PUT /workspaces/:id — Update workspace (owner/admin only)
  - DELETE /workspaces/:id — Delete workspace (owner only)
- Implement Membership API:
  - POST /workspaces/:id/members — Add member
  - GET /workspaces/:id/members — List members
  - PUT /workspaces/:id/members/:userId — Update member role
  - DELETE /workspaces/:id/members/:userId — Remove member

## Key Files

- `src/models/workspace.js` — New workspace model
- `src/services/workspace-service.js` — Workspace business logic
- `src/routes/workspaces.js` — New workspace routes
- `src/middleware/workspace.js` — New workspace context middleware
- `src/routes/tasks.js` — Add workspace scoping
- `src/routes/projects.js` — Add workspace scoping

## Acceptance Criteria

- [ ] Workspace CRUD endpoints all functional
- [ ] Membership management endpoints all functional
- [ ] x-workspace-id header required on scoped routes
- [ ] Tasks and projects are fully scoped by workspace
- [ ] Users cannot access resources outside their workspaces
- [ ] Creating a workspace auto-assigns creator as owner
- [ ] Missing or invalid workspace header returns appropriate error

## References

- `agent/design/workspace-architecture.md` — Full workspace design spec
- `agent/patterns/api-conventions.md` — API endpoint conventions
