# RBAC System

## Overview

The platform implements role-based access control (RBAC) at the workspace level. Each workspace member is assigned one of four roles that determines what operations they can perform. Authorization is enforced via middleware that checks the user's role against a permission matrix before allowing the request to proceed.

## Roles

| Role | Level | Description |
|------|-------|-------------|
| `owner` | 4 | Full control over the workspace, including deletion and ownership transfer |
| `admin` | 3 | Manage members, full CRUD on all resources within the workspace |
| `member` | 2 | Create and edit own resources, view all resources in the workspace |
| `viewer` | 1 | Read-only access to all resources in the workspace |

A workspace has exactly one `owner`. It may have any number of `admin`, `member`, and `viewer` roles.

## Permission Matrix

### Resource Permissions

| Resource | Action | owner | admin | member | viewer |
|----------|--------|-------|-------|--------|--------|
| Tasks | create | YES | YES | YES | NO |
| Tasks | read | YES | YES | YES | YES |
| Tasks | update | YES | YES | OWN | NO |
| Tasks | delete | YES | YES | OWN | NO |
| Projects | create | YES | YES | YES | NO |
| Projects | read | YES | YES | YES | YES |
| Projects | update | YES | YES | OWN | NO |
| Projects | delete | YES | YES | OWN | NO |
| Comments | create | YES | YES | YES | NO |
| Comments | read | YES | YES | YES | YES |
| Comments | update | YES | YES | OWN | NO |
| Comments | delete | YES | YES | OWN | NO |
| Members | read | YES | YES | YES | YES |
| Members | add | YES | YES | NO | NO |
| Members | remove | YES | YES | NO | NO |
| Members | change_role | YES | NO | NO | NO |
| Workspace | update | YES | YES | NO | NO |
| Workspace | delete | YES | NO | NO | NO |

**OWN** means the user can only perform the action on resources they created (`createdBy === userId`).

### Member Management Constraints

- Only `owner` can transfer workspace ownership.
- Only `owner` can change member roles.
- `admin` can add and remove `member` and `viewer` roles, but cannot add/remove other `admin` users or the `owner`.
- `admin` cannot promote a user to `admin` — only the `owner` can do that.
- No one can remove the `owner` via the members endpoint. Ownership must be transferred first.

## Implementation

### Permission Middleware

```
checkPermission(resource, action)
```

This middleware function is applied to route handlers. It:

1. Extracts the workspace ID from the `x-workspace-id` header.
2. Loads the authenticated user's WorkspaceMember record for that workspace.
3. Looks up the permission in the matrix for the user's role, resource, and action.
4. For `OWN` permissions, additionally checks that `resource.createdBy === user.id`.
5. Returns `403 Forbidden` if the check fails:
```json
{
  "error": {
    "code": "FORBIDDEN",
    "message": "You do not have permission to perform this action"
  }
}
```

### Endpoint Authorization Map

| Endpoint | Resource | Action |
|----------|----------|--------|
| `GET /tasks` | Tasks | read |
| `POST /tasks` | Tasks | create |
| `PUT /tasks/:id` | Tasks | update |
| `DELETE /tasks/:id` | Tasks | delete |
| `GET /projects` | Projects | read |
| `POST /projects` | Projects | create |
| `PUT /projects/:id` | Projects | update |
| `DELETE /projects/:id` | Projects | delete |
| `POST /tasks/:id/comments` | Comments | create |
| `PUT /comments/:id` | Comments | update |
| `DELETE /comments/:id` | Comments | delete |
| `GET /workspaces/:id/members` | Members | read |
| `POST /workspaces/:id/members` | Members | add |
| `DELETE /workspaces/:id/members/:userId` | Members | remove |
| `PUT /workspaces/:id/members/:userId/role` | Members | change_role |
| `PUT /workspaces/:id` | Workspace | update |
| `DELETE /workspaces/:id` | Workspace | delete |

### Ownership Transfer

#### PUT /workspaces/:id/transfer
- **Auth**: Required, role `owner` only.
- **Request Body**:
```json
{ "newOwnerId": "uuid (must be an existing member of the workspace)" }
```
- **Behavior**: The current owner's role is changed to `admin`. The target user's role is changed to `owner`.
- **Errors**: `400` if target user is not a workspace member, `403` if not owner.

## Relationships

- Depends on workspace-architecture.md for WorkspaceMember role data.
- Task, Project, and Comment models must include a `createdBy` field for OWN-level checks.
- Audit logging (audit-logging.md) records role changes and member management actions.

## Edge Cases

- A user who is not a member of the workspace receives `403` on all workspace-scoped endpoints.
- When checking `OWN` permissions, the middleware must load the target resource to compare `createdBy`. If the resource does not exist, return `404` (not `403`) to avoid leaking information about resource existence.
- Role changes take effect immediately. If an admin is demoted to viewer mid-session, their next request is denied.
- The permission middleware runs after authentication middleware. Unauthenticated requests receive `401`, not `403`.
- Webhooks and audit log endpoints have their own authorization rules (admin+ for webhooks, admin+ for audit log reads).
