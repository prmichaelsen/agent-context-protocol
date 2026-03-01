# Pattern: API Conventions

## Response Shapes

**List endpoints** return a wrapper with data and pagination:

```json
{
  "data": [ ... ],
  "pagination": { "page": 1, "limit": 20, "total": 147, "totalPages": 8 }
}
```

**Single-resource endpoints** return the object directly (no wrapper).

## Pagination

| Param  | Default | Constraints        |
|--------|---------|--------------------|
| page   | 1       | Must be >= 1       |
| limit  | 20      | Must be 1..100     |

Calculate `totalPages` as `Math.ceil(total / limit)`.

## Filtering

Filter via query parameters matching field names:

```
GET /api/tasks?status=active&priority=high
```

Ignore unknown query parameters silently.

## Sorting

```
GET /api/tasks?sort=createdAt&order=desc
```

| Param | Default    | Values             |
|-------|------------|--------------------|
| sort  | createdAt  | Any sortable field |
| order | desc       | `asc` or `desc`   |

## Workspace Scoping

All workspace-scoped endpoints require the `x-workspace-id` header.
Missing header returns 400 VALIDATION_ERROR. Non-member returns 403.
Middleware extracts workspace ID and attaches it to `req.workspaceId`.

## HTTP Status Codes

| Operation | Status | Notes                       |
|-----------|--------|-----------------------------|
| Create    | 201    | Return the created resource |
| Read      | 200    | Single resource or list     |
| Update    | 200    | Return the updated resource |
| Delete    | 204    | No response body            |

## Naming Conventions

- Plural nouns for paths: `/api/tasks`, `/api/workspaces`
- Kebab-case for multi-word paths: `/api/workspace-members`
- Nest sub-resources: `/api/tasks/:taskId/comments`
