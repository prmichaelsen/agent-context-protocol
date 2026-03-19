# Data Model

All entities are stored in-memory as arrays. Each model module exports CRUD functions.

## User

| Field | Type | Constraints |
|-------|------|-------------|
| id | string (UUID v4) | Primary key, auto-generated |
| name | string | Required, 1-100 chars |
| email | string | Required, unique, valid email |
| passwordHash | string | bcrypt hash, never returned in API responses |
| role | string | `member` or `admin`, default: `member` |
| createdAt | string (ISO8601) | Auto-set on creation |

**API Response Shape** (never include passwordHash):
```json
{ "id": "...", "name": "...", "email": "...", "role": "...", "createdAt": "..." }
```

## Project

| Field | Type | Constraints |
|-------|------|-------------|
| id | string (UUID v4) | Primary key, auto-generated |
| name | string | Required, 1-100 chars |
| description | string | Optional, max 500 chars |
| ownerId | string (UUID) | References User.id, set to authenticated user on creation |
| status | string | `active` or `archived`, default: `active` |
| createdAt | string (ISO8601) | Auto-set on creation |

**On Delete**: All tasks referencing this project have their `projectId` set to `null`.  

## Task

| Field | Type | Constraints |
|-------|------|-------------|
| id | string (UUID v4) | Primary key, auto-generated |
| title | string | Required, 1-200 chars |
| description | string | Optional, max 2000 chars |
| status | string | `todo`, `in_progress`, or `done`, default: `todo` |
| priority | string | `low`, `medium`, `high`, or `urgent`, default: `medium` |
| projectId | string (UUID) or null | Optional, references Project.id |
| assigneeId | string (UUID) or null | Optional, references User.id |
| createdBy | string (UUID) | Set to authenticated user on creation |
| createdAt | string (ISO8601) | Auto-set on creation |
| updatedAt | string (ISO8601) | Auto-set on creation and every update |
| dueDate | string (ISO8601) or null | Optional |

**Validation on Create/Update**:
- `projectId` if provided must reference an existing project
- `assigneeId` if provided must reference an existing user
- `status` must be one of the allowed values
- `priority` must be one of the allowed values

## Notification

| Field | Type | Constraints |
|-------|------|-------------|
| id | string (UUID v4) | Primary key, auto-generated |
| userId | string (UUID) | References User.id — the recipient |
| type | string | `task_assigned`, `task_completed`, `task_created`, `project_archived` |
| message | string | Human-readable description |
| read | boolean | Default: `false` |
| entityType | string | `task` or `project` |
| entityId | string (UUID) | References the related entity |
| createdAt | string (ISO8601) | Auto-set on creation |

**Access Control**: Users can only see and modify their own notifications.  

## Relationships

```
User 1──* Project (ownerId)
User 1──* Task (assigneeId)
User 1──* Task (createdBy)
User 1──* Notification (userId)
Project 1──* Task (projectId)
```
