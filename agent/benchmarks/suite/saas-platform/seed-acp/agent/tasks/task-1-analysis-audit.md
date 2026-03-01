# Task 1: Architecture Analysis & Audit

**Status:** not_started
**Milestone:** M1 — Foundation & Stabilization
**Estimated Hours:** 2

## Objective

Perform a thorough analysis of the existing codebase. Identify all bugs,
security vulnerabilities, architectural issues, and code quality problems.
Produce a comprehensive ANALYSIS.md document that serves as the roadmap
for all subsequent tasks.

## Requirements

- Read every source file in the project (server.js, routes, models, middleware)
- Identify and document all known bugs:
  - Auth bypass on empty/malformed tokens
  - Plaintext password storage (no hashing)
  - Missing email uniqueness constraint on registration
  - Filter bug using `||` instead of `&&` for multi-criteria filtering
  - 404 routes returning 200 with null body instead of proper 404
  - Missing request body validation on all endpoints
  - Error format inconsistency (mix of string messages and object responses)
  - No tenant isolation (any user can access any resource)
  - Wrong error handler signature (3 params instead of 4 in Express)
  - JWT expiry not enforced or configured incorrectly
  - 403 returned where 401 is semantically correct
  - Passwords leaked in API responses (not stripped from user objects)
- Document architectural problems (monolithic routes, no service layer, tight coupling)
- Note missing features required by design docs
- Write findings to ANALYSIS.md in project root

## Key Files

- `src/server.js` — Main application entry point, contains inline routes
- `src/routes/` — Route handlers (auth, tasks, projects)
- `src/models/` — Data models
- `src/middleware/` — Auth and error middleware

## Acceptance Criteria

- [ ] ANALYSIS.md exists in project root
- [ ] All 8+ bugs are documented with file paths and line numbers
- [ ] Security vulnerabilities are flagged with severity ratings
- [ ] Architectural recommendations are included
- [ ] Document covers every source file in the project
- [ ] No code changes made in this task (analysis only)

## References

- Review all files in `agent/design/` for intended architecture
- Review `agent/patterns/` for coding standards to check against
