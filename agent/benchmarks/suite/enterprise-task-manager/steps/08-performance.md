Add pagination, sorting, and search to all list endpoints.

**Pagination** (all list endpoints):
- Query params: ?limit=20&offset=0
- Response format: `{ "data": [...], "total": N, "limit": M, "offset": O }`
- Default limit: 20, max limit: 100
- Requests without pagination params should return the first page

**Sorting** (all list endpoints):
- Query params: ?sort=createdAt&order=desc
- Support sorting by: createdAt, name/title, updatedAt (where applicable)
- Default order: desc by createdAt
- Invalid sort fields should fall back to default

**Search**:
- GET /tasks?search=keyword — search across title and description (case-insensitive)
- GET /users?search=keyword — search across name and email
- GET /projects?search=keyword — search across name and description

**Combined:**
All query params should work together: search + sort + pagination + existing filters (status, teamId, etc.)

**Tests:**
- Test pagination (first page, second page, last page, beyond total)
- Test sorting (asc, desc, different fields)
- Test search (matching, non-matching, case-insensitive)
- Test combined params
- All existing tests must still pass (update any that depend on response format)