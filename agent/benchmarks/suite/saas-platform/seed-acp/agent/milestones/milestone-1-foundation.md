# Milestone 1: Foundation & Stabilization

## Goal

Fix critical bugs in the existing codebase, refactor the architecture
into a clean service layer, and introduce workspace multi-tenancy with
role-based access control. This milestone establishes the solid base
that all subsequent features build upon.

## Tasks

| #  | Task                     | Description                                           |
|----|--------------------------|-------------------------------------------------------|
| 1  | Codebase Analysis        | Audit the existing code, catalog bugs, map dependencies |
| 2  | Bug Fixes                | Fix auth flow, error handling, and data integrity issues |
| 3  | Architecture Refactor    | Extract routes/services/models, add middleware chain   |
| 4  | Workspace Multi-Tenancy  | Add workspace CRUD, membership, tenant-scoped queries  |
| 5  | RBAC Permissions         | Implement role system (owner/admin/member/viewer)      |

## Deliverables

- Clean separation of routes, services, and data access layers
- Working authentication flow (register, login, token validation)
- Workspace creation, joining, and scoping of all resources
- Role-based permission middleware enforcing the permission matrix
- All existing endpoints migrated to workspace-scoped architecture
- Consistent error responses following the error-handling pattern

## Success Criteria

- No known bugs remaining from the initial codebase audit
- Every API error returns the standard error response format
- Resources are isolated per workspace — no cross-tenant data leaks
- Permission checks enforce the role hierarchy on every protected route
- The refactored code follows the layered architecture (routes -> services -> stores)
- Manual smoke test of auth, workspace, and task CRUD passes cleanly
