There are two bugs in the API that need to be fixed:

**Bug 1: DELETE returns wrong status code**
The DELETE endpoint returns `200` with `{ "message": "deleted" }`, but the correct RESTful behavior is to return `204 No Content` with an empty body for successful deletes.

Fix: Change DELETE /todos/:id to return 204 with no body on success (keep 404 for not found).

**Bug 2: PUT doesn't validate required fields**
The PUT endpoint accepts any body, even `{}` or `{ "foo": "bar" }`. It should validate that at least one valid field (`title` or `completed`) is provided and that `title` is a non-empty string if present.

Fix: Add validation to PUT /todos/:id:
- If the body has no valid fields (`title` or `completed`), return 400 with `{ "error": "No valid fields to update" }`
- If `title` is provided but is empty or not a string, return 400 with `{ "error": "Title must be a non-empty string" }`

After fixing both bugs, update the tests to match the new behavior:
- DELETE tests should expect 204 with no body
- PUT tests should include validation error cases

Run the full test suite and confirm all tests pass.
