# Task 5: RBAC Permission System

**Status:** not_started
**Milestone:** M1 — Foundation & Stabilization
**Estimated Hours:** 4
**Depends On:** task-4

## Objective

Implement a role-based access control system with four roles. Every API
endpoint must enforce appropriate permissions based on the user's role
within the current workspace context.

## Requirements

- Implement four-role hierarchy:
  - **owner** — Full control, can delete workspace, manage all roles
  - **admin** — Can manage members (except owner), full CRUD on all resources
  - **member** — Can create and manage own resources, view all workspace resources
  - **viewer** — Read-only access to all workspace resources
- Create permission middleware:
  - `requireRole(...roles)` — Middleware factory that checks user's workspace role
  - Attach role to request context during workspace middleware phase
  - Return 403 with clear error message when permission denied
- Apply per-endpoint authorization:
  - Workspace management: owner/admin only
  - Member management: owner/admin only (owner role changes: owner only)
  - Task/Project create: member and above
  - Task/Project update: member and above (own resources or admin+)
  - Task/Project delete: admin and above
  - Read operations: viewer and above
  - Workspace delete: owner only
- Role assignment rules:
  - Only owner can promote to admin
  - Only owner can demote admin
  - Admins can assign member/viewer roles
  - Cannot change own role
  - Cannot remove last owner

## Key Files

- `src/middleware/rbac.js` — New RBAC middleware
- `src/middleware/workspace.js` — Attach role to context
- `src/routes/workspaces.js` — Apply role checks
- `src/routes/tasks.js` — Apply role checks
- `src/routes/projects.js` — Apply role checks

## Acceptance Criteria

- [ ] All four roles enforced (owner, admin, member, viewer)
- [ ] requireRole middleware works as composable middleware factory
- [ ] Viewers cannot create, update, or delete any resource
- [ ] Members can only delete their own resources
- [ ] Admin+ can manage members (except owner role)
- [ ] Only owner can delete workspace or transfer ownership
- [ ] 403 responses include which role is required
- [ ] Cannot remove or demote the last owner

## References

- `agent/design/rbac-system.md` — Full RBAC design specification
- `agent/patterns/permission-patterns.md` — Permission check patterns
