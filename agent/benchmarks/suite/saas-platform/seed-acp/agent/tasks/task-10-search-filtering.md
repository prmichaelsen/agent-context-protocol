# Task 10: Search & Filtering

**Status:** not_started
**Milestone:** M2 — Core Features
**Estimated Hours:** 3
**Depends On:** task-7

## Objective

Implement a unified search endpoint and enhanced filtering across all
resource types within a workspace. Enable users to quickly find tasks,
projects, and comments using full-text search.

## Requirements

- Create search endpoint:
  - GET /workspaces/:id/search?q=query — Search across resource types
  - Search across tasks (title, description), projects (name, description), comments (body)
  - Return results grouped by resource type
  - Include relevance scoring (simple substring match ranking)
  - Workspace-scoped: only search within the current workspace
- Implement full-text matching:
  - Case-insensitive substring matching
  - Match across multiple fields per resource type
  - Highlight or indicate which field matched (optional)
- Enhanced task filtering:
  - Filter by: status, assigneeId, projectId, priority, createdAfter, createdBefore
  - Multiple filters combine with AND logic
  - GET /tasks?status=open&assigneeId=123&projectId=456
- Sorting:
  - Support sortBy parameter: createdAt, updatedAt, title, status, priority
  - Support sortOrder parameter: asc, desc (default: desc)
- Pagination:
  - Support page and limit query parameters
  - Return pagination metadata: total, page, limit, totalPages
  - Default limit: 20, max limit: 100

## Key Files

- `src/services/search-service.js` — New search and indexing logic
- `src/routes/search.js` — Search endpoint
- `src/routes/tasks.js` — Enhanced filtering
- `src/routes/projects.js` — Enhanced filtering

## Acceptance Criteria

- [ ] Search endpoint returns results across tasks, projects, comments
- [ ] Search is case-insensitive and workspace-scoped
- [ ] Results grouped by resource type with match metadata
- [ ] Task filtering supports all specified filter parameters
- [ ] Multiple filters combine with AND logic
- [ ] Sorting works by all specified fields in both directions
- [ ] Pagination returns correct metadata and respects limits
- [ ] Empty search returns 400 with helpful error message

## References

- `agent/design/search-architecture.md` — Search design and ranking
- `agent/patterns/api-conventions.md` — Pagination and query parameter conventions
