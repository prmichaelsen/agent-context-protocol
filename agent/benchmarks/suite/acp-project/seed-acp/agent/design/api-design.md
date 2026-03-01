# API Design

## Base URL

All endpoints are prefixed with `/` (no versioning for MVP).

## Authentication

All endpoints except `/health` and `/auth/*` require a Bearer token in the `Authorization` header.

Token format: `Authorization: Bearer <jwt_token>`

Unauthorized requests receive `401` with `{ error: { code: "UNAUTHORIZED", message: "Authentication required" } }`.

---

## Endpoints

### Health

#### GET /health
- **Auth**: None
- **Response**: `200 OK`
```json
{ "status": "ok", "uptime": 123.45 }
```

### Auth

#### POST /auth/register
- **Auth**: None
- **Request Body**:
```json
{
  "name": "string (required, 1-100 chars)",
  "email": "string (required, valid email format)",
  "password": "string (required, min 6 chars)"
}
```
- **Response**: `201 Created`
```json
{
  "user": { "id": "uuid", "name": "string", "email": "string" },
  "token": "jwt_string"
}
```
- **Errors**:
  - `400` — Missing required fields: `{ error: { code: "VALIDATION_ERROR", message: "Name, email, and password are required" } }`
  - `400` — Password too short: `{ error: { code: "VALIDATION_ERROR", message: "Password must be at least 6 characters" } }`
  - `409` — Duplicate email: `{ error: { code: "CONFLICT", message: "Email already registered" } }`

#### POST /auth/login
- **Auth**: None
- **Request Body**:
```json
{
  "email": "string (required)",
  "password": "string (required)"
}
```
- **Response**: `200 OK`
```json
{
  "user": { "id": "uuid", "name": "string", "email": "string" },
  "token": "jwt_string"
}
```
- **Errors**:
  - `400` — Missing fields: `{ error: { code: "VALIDATION_ERROR", message: "Email and password are required" } }`
  - `401` — Bad credentials: `{ error: { code: "UNAUTHORIZED", message: "Invalid credentials" } }`

---

### Tasks

#### GET /tasks
- **Auth**: Required
- **Query Parameters**:
  - `status` — Filter by status: `todo`, `in_progress`, `done` (optional)
  - `priority` — Filter by priority: `low`, `medium`, `high`, `urgent` (optional)
  - `projectId` — Filter by project (optional)
  - `assigneeId` — Filter by assignee (optional)
  - `page` — Page number, default 1 (optional)
  - `limit` — Items per page, default 20, max 100 (optional)
  - `sort` — Sort field: `createdAt`, `updatedAt`, `dueDate`, `priority` (optional, default: `createdAt`)
  - `order` — Sort order: `asc`, `desc` (optional, default: `desc`)
- **Response**: `200 OK`
```json
{
  "data": [
    {
      "id": "uuid",
      "title": "string",
      "description": "string",
      "status": "todo|in_progress|done",
      "priority": "low|medium|high|urgent",
      "projectId": "uuid|null",
      "assigneeId": "uuid|null",
      "createdBy": "uuid",
      "createdAt": "ISO8601",
      "updatedAt": "ISO8601",
      "dueDate": "ISO8601|null"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 42,
    "totalPages": 3
  }
}
```

#### GET /tasks/:id
- **Auth**: Required
- **Response**: `200 OK` — Single task object (same shape as array item above)
- **Errors**:
  - `404` — `{ error: { code: "NOT_FOUND", message: "Task not found" } }`

#### POST /tasks
- **Auth**: Required
- **Request Body**:
```json
{
  "title": "string (required, 1-200 chars)",
  "description": "string (optional, max 2000 chars)",
  "status": "todo|in_progress|done (optional, default: todo)",
  "priority": "low|medium|high|urgent (optional, default: medium)",
  "projectId": "uuid (optional, must reference existing project)",
  "assigneeId": "uuid (optional, must reference existing user)",
  "dueDate": "ISO8601 (optional)"
}
```
- **Response**: `201 Created` — Created task object
- **Errors**:
  - `400` — Missing title: `{ error: { code: "VALIDATION_ERROR", message: "Title is required" } }`
  - `400` — Title too long: `{ error: { code: "VALIDATION_ERROR", message: "Title must be 200 characters or less" } }`
  - `400` — Invalid status: `{ error: { code: "VALIDATION_ERROR", message: "Status must be one of: todo, in_progress, done" } }`
  - `400` — Invalid priority: `{ error: { code: "VALIDATION_ERROR", message: "Priority must be one of: low, medium, high, urgent" } }`
  - `404` — Invalid projectId: `{ error: { code: "NOT_FOUND", message: "Project not found" } }`
  - `404` — Invalid assigneeId: `{ error: { code: "NOT_FOUND", message: "User not found" } }`
- **Side Effects**: Creates a `task_created` notification for the assignee (if assigned to someone other than creator)

#### PUT /tasks/:id
- **Auth**: Required
- **Request Body**: Same fields as POST (all optional — partial update)
- **Response**: `200 OK` — Updated task object
- **Errors**:
  - `404` — Task not found
  - `400` — Validation errors (same as POST)
- **Side Effects**:
  - If `assigneeId` changes → creates `task_assigned` notification for new assignee
  - If `status` changes to `done` → creates `task_completed` notification for project owner

#### DELETE /tasks/:id
- **Auth**: Required
- **Response**: `204 No Content`
- **Errors**:
  - `404` — Task not found

---

### Projects

#### GET /projects
- **Auth**: Required
- **Query Parameters**:
  - `status` — Filter by status: `active`, `archived` (optional)
  - `page` — Page number, default 1 (optional)
  - `limit` — Items per page, default 20, max 100 (optional)
- **Response**: `200 OK`
```json
{
  "data": [
    {
      "id": "uuid",
      "name": "string",
      "description": "string",
      "ownerId": "uuid",
      "status": "active|archived",
      "createdAt": "ISO8601"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 5,
    "totalPages": 1
  }
}
```

#### GET /projects/:id
- **Auth**: Required
- **Response**: `200 OK` — Single project object
- **Errors**:
  - `404` — `{ error: { code: "NOT_FOUND", message: "Project not found" } }`

#### POST /projects
- **Auth**: Required
- **Request Body**:
```json
{
  "name": "string (required, 1-100 chars)",
  "description": "string (optional, max 500 chars)",
  "status": "active|archived (optional, default: active)"
}
```
- **Response**: `201 Created` — Created project (ownerId set to authenticated user)
- **Errors**:
  - `400` — Missing name: `{ error: { code: "VALIDATION_ERROR", message: "Name is required" } }`
  - `400` — Name too long: `{ error: { code: "VALIDATION_ERROR", message: "Name must be 100 characters or less" } }`

#### PUT /projects/:id
- **Auth**: Required
- **Request Body**: Same fields as POST (all optional)
- **Response**: `200 OK` — Updated project object
- **Errors**:
  - `404` — Project not found
  - `400` — Validation errors

#### DELETE /projects/:id
- **Auth**: Required
- **Response**: `204 No Content`
- **Errors**:
  - `404` — Project not found
- **Side Effects**: All tasks with this projectId have their projectId set to null

---

### Notifications

#### GET /notifications
- **Auth**: Required
- **Query Parameters**:
  - `unreadOnly` — If `true`, return only unread notifications (optional, default: false)
  - `page` — Page number, default 1
  - `limit` — Items per page, default 20, max 100
- **Response**: `200 OK`
```json
{
  "data": [
    {
      "id": "uuid",
      "userId": "uuid",
      "type": "task_assigned|task_completed|task_created|project_archived",
      "message": "string",
      "read": false,
      "entityType": "task|project",
      "entityId": "uuid",
      "createdAt": "ISO8601"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 8,
    "totalPages": 1
  }
}
```
- **Note**: Users only see their own notifications. Filter by `req.user.id`.

#### PUT /notifications/:id/read
- **Auth**: Required
- **Response**: `200 OK` — Updated notification with `read: true`
- **Errors**:
  - `404` — Notification not found (or doesn't belong to user)

#### PUT /notifications/read-all
- **Auth**: Required
- **Response**: `200 OK` — `{ "updated": 5 }` (count of notifications marked as read)
