The application has several bugs. Your test suite may have already revealed some of them. Fix all of the following:

**Bug 1: Empty title accepted**
- Creating a note with an empty title (`""`) or missing title should return 400 with an error message, not 201.
- Add input validation: title is required and must be a non-empty string.

**Bug 2: Updating a non-existent note returns 200**
- PUT /notes/:id with a non-existent ID currently returns 200 with an empty object `{}`.
- It should return 404 with `{ "error": "not found" }`.

**Bug 3: Non-JSON content-type crashes the app**
- Sending a POST request with a non-JSON content-type (e.g., `text/plain`) can cause the app to crash or behave unexpectedly.
- Add proper content-type handling: if a POST/PUT request has a body but isn't JSON, return 400 with a clear error message.

For each bug:
1. Write or update a test that demonstrates the bug (test should fail before fix, pass after)
2. Fix the bug in the appropriate module
3. Run the full test suite to ensure no regressions

All tests must pass after fixes.