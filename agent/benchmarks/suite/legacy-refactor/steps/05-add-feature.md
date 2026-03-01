Add search, sorting, and pagination to the Notes API.

**Search** — GET /notes?search=keyword
- Search across both title and content fields (case-insensitive)
- Returns only notes that match the search term
- Returns empty array if no matches

**Sorting** — GET /notes?sort=createdAt&order=desc
- Support sorting by: createdAt, updatedAt, title
- Support order: asc (default), desc
- Invalid sort field should be ignored (use default order)

**Pagination** — GET /notes?limit=10&offset=0
- `limit` controls how many notes to return (default: all)
- `offset` controls how many to skip (default: 0)
- Response should include pagination metadata: `{ "notes": [...], "total": N, "limit": M, "offset": O }`

**Combined** — All query params should work together:
- GET /notes?search=hello&sort=createdAt&order=desc&limit=5&offset=0

Requirements:
1. Implement all three features in the notes route
2. Add tests for each feature individually
3. Add tests for combined query params
4. All existing tests must still pass (backward compatible — GET /notes without params still returns flat array or wrapped response)
5. Run the full test suite to verify