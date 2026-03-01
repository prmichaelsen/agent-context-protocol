# Workspace Architecture

## Overview

The platform uses a workspace-based multi-tenancy model. Every resource belongs to exactly one workspace. Users provide an `x-workspace-id` header on every request, and the server enforces tenant isolation: users can only interact with resources in workspaces where they hold an active membership.

## Data Model

### Workspace

| Field | Type | Constraints |
|-------|------|-------------|
| id | string (UUID v4) | Primary key, auto-generated |
| name | string | Required, 1-100 chars |
| description | string | Optional, max 500 chars |
| ownerId | string (UUID) | References User.id, set on creation |
| createdAt | string (ISO8601) | Auto-set on creation |
| updatedAt | string (ISO8601) | Auto-set on creation and every update |

### WorkspaceMember

| Field | Type | Constraints |
|-------|------|-------------|
| workspaceId | string (UUID) | Composite key with userId |
| userId | string (UUID) | Composite key with workspaceId |
| role | string | `owner`, `admin`, `member`, or `viewer` |
| joinedAt | string (ISO8601) | Auto-set when membership is created |

## API Endpoints

### Workspaces

#### GET /workspaces
- **Auth**: Required. Lists workspaces where the user is a member.
- **Response**: `200 OK` — Paginated array with workspace objects including the user's `role`.

#### POST /workspaces
- **Auth**: Required.
- **Body**: `{ "name": "required", "description": "optional" }`
- **Response**: `201 Created`. Creator is added as `owner`. **Errors**: `400` for invalid name.

#### GET /workspaces/:id
- **Auth**: Must be a member. **Errors**: `403`/`404`.

#### PUT /workspaces/:id
- **Auth**: `owner` or `admin`. Partial update of name/description. **Errors**: `403`/`404`.

#### DELETE /workspaces/:id
- **Auth**: `owner` only. Cascades to all members and scoped resources. **Errors**: `403`/`404`.

### Workspace Members

#### GET /workspaces/:id/members
- **Auth**: Must be a member. Returns array of `{ userId, name, email, role, joinedAt }`.

#### POST /workspaces/:id/members
- **Auth**: `owner` or `admin`.
- **Body**: `{ "userId": "required", "role": "admin|member|viewer" }`
- **Response**: `201 Created`. Only `owner` can assign the `admin` role.
- **Errors**: `400` if already a member, `403`/`404`.

#### DELETE /workspaces/:id/members/:userId
- **Auth**: `owner` or `admin`. Admins cannot remove other admins or the owner.
- **Errors**: `400` if removing owner, `403` if insufficient role.

## Workspace Scoping

All resource endpoints require the `x-workspace-id` header:
```
x-workspace-id: <workspace-uuid>
```

Server middleware must:
1. Validate the header is present (return `400` if missing).
2. Verify the user is a workspace member (return `403` if not).
3. Attach workspace context to the request.
4. Scope all queries to the workspace.

Missing header returns: `{ error: { code: "VALIDATION_ERROR", message: "x-workspace-id header is required" } }`

## Relationships

```
User 1──* WorkspaceMember (userId)
Workspace 1──* WorkspaceMember (workspaceId)
Workspace 1──* Task (workspaceId)
Workspace 1──* Project (workspaceId)
Workspace 1──* Comment (workspaceId)
```

## Edge Cases

- The creator is always `owner`. Owner cannot be removed via members endpoint; use ownership transfer (see rbac-system.md).
- Deleting a workspace cascades to all scoped resources. Client should confirm before proceeding.
- Removed users' resources remain but become uneditable by them.
- A workspace must always have exactly one owner.
