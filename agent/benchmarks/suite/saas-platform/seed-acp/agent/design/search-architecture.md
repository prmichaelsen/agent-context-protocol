# Search Architecture

## Overview

The platform provides a unified search endpoint for full-text search across multiple resource types within a workspace. Users can search tasks, projects, and comments with a single query, apply filters, and sort by relevance or date. All searches are scoped to the workspace via the `x-workspace-id` header.

## API Endpoint

### GET /search

- **Auth**: Required, must be a workspace member.
- **Query Parameters**:

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| q | string | Yes | — | Search term, minimum 1 character |
| type | string | No | all | Comma-separated: `tasks`, `projects`, `comments` |
| status | string | No | — | Filter tasks by status |
| priority | string | No | — | Filter tasks by priority |
| assigneeId | UUID | No | — | Filter tasks by assignee |
| projectId | UUID | No | — | Filter by project association |
| dateFrom | ISO8601 | No | — | Results created on or after this date |
| dateTo | ISO8601 | No | — | Results created on or before this date |
| sort | string | No | `relevance` | `relevance`, `createdAt`, `updatedAt` |
| order | string | No | `desc` | `asc` or `desc` |
| page | number | No | 1 | Page number |
| limit | number | No | 20 | Max 100 |

- **Response**: `200 OK`
```json
{
  "data": [
    { "type": "task", "id": "uuid", "title": "Implement authentication",
      "status": "in_progress", "score": 0.95,
      "highlights": { "title": "Implement <mark>authentication</mark>" },
      "createdAt": "ISO8601" },
    { "type": "comment", "id": "uuid", "body": "The auth flow needs updating...",
      "taskId": "uuid", "score": 0.72,
      "highlights": { "body": "The <mark>auth</mark> flow needs updating..." },
      "createdAt": "ISO8601" }
  ],
  "pagination": { "page": 1, "limit": 20, "total": 8, "totalPages": 1 },
  "query": "auth"
}
```
- **Errors**: `400` if `q` is missing/empty or `type` contains invalid values.

## Searchable Fields

| Resource | Searchable Fields | Key Returned Fields |
|----------|-------------------|---------------------|
| Tasks | `title`, `description` | id, title, description, status, priority, assigneeId, projectId |
| Projects | `name`, `description` | id, name, description, status, ownerId |
| Comments | `body` | id, body, taskId, createdBy |

## Search Implementation

Search uses case-insensitive substring matching. For each resource type, iterate over workspace-scoped resources and check if the search term appears in any searchable field.

### Relevance Scoring

| Criteria | Score |
|----------|-------|
| Exact match in title/name | 1.0 |
| Partial match in title/name | 0.8 |
| Match in description/body | 0.5 |
| Match in multiple fields | +0.2 bonus |

### Highlights

The `highlights` object wraps matched terms in `<mark>` tags. Only matched fields are included. Text is truncated to 200 characters around the match.

## Filtering

- **status/priority/assigneeId**: Apply only to tasks, ignored for other types.
- **projectId**: Applies to tasks and comments on tasks in the project.
- **dateFrom/dateTo**: Filters `createdAt` across all types.

Filters are applied after search matching.

## Sorting and Pagination

| Sort | Behavior |
|------|----------|
| `relevance` | Descending by score (default) |
| `createdAt` | By creation date |
| `updatedAt` | By last update (falls back to createdAt for comments) |

Pagination uses the standard `{ page, limit, total, totalPages }` format, applied after filtering and sorting.

## Relationships

- All results are workspace-scoped (see workspace-architecture.md).
- RBAC: Viewers can search. No special permissions beyond workspace membership (see rbac-system.md).

## Edge Cases

- Empty `q` returns `400`. Use resource-specific list endpoints for unfiltered browsing.
- Special characters are treated as literals, not regex.
- Results from different types are interleaved by sort order, not grouped.
- Workspace scoping is mandatory; missing `x-workspace-id` returns `400`.
- Deleted resources are excluded. Only current field values are searched.
