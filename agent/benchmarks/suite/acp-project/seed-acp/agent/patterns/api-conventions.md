# API Conventions

## REST Conventions

| Operation | Method | Path | Response |
|-----------|--------|------|----------|
| List | GET | /resources | 200 with paginated array |
| Get one | GET | /resources/:id | 200 with object |
| Create | POST | /resources | 201 with created object |
| Update | PUT | /resources/:id | 200 with updated object |
| Delete | DELETE | /resources/:id | 204 No Content |

## Pagination

All list endpoints return paginated responses:

```json
{
  "data": [ ... ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 42,
    "totalPages": 3
  }
}
```

**Query params**: `page` (default 1), `limit` (default 20, max 100).  

**Implementation helper**:

```javascript
function paginate(items, page = 1, limit = 20) {
  const p = Math.max(1, parseInt(page) || 1);
  const l = Math.min(100, Math.max(1, parseInt(limit) || 20));
  const total = items.length;
  const totalPages = Math.ceil(total / l);
  const start = (p - 1) * l;
  const data = items.slice(start, start + l);
  return { data, pagination: { page: p, limit: l, total, totalPages } };
}
```

## Sorting

List endpoints support `sort` and `order` query params:
- `sort` — field name (e.g., `createdAt`, `priority`)
- `order` — `asc` or `desc` (default: `desc`)

## Filtering

List endpoints support field-specific query params for filtering. Only filter on exact match unless otherwise specified. Multiple filters are AND-combined.

## Response Consistency

- All successful responses include the resource object(s) directly, or wrapped in `data` for lists
- All error responses use the standard error format from `agent/patterns/error-handling.md`
- Dates are always ISO8601 strings
- IDs are always UUID v4 strings
- Null fields are included in responses (not omitted)
