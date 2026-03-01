# Task 13: Comprehensive Test Suite

**Status:** not_started
**Milestone:** M3 — Production Hardening
**Estimated Hours:** 5
**Depends On:** task-12

## Objective

Build a comprehensive integration and unit test suite that covers all
features and ensures confidence for future changes. All tests must pass
via `npm test`.

## Requirements

- Test framework setup:
  - Use Jest or the existing test framework in the project
  - Set up test helpers for authentication, workspace setup, seeding data
  - Create test fixtures for common scenarios
- Auth tests:
  - Registration with valid and invalid data
  - Login with correct and incorrect credentials
  - Token validation and expiry
  - Auth bypass attempts (empty token, malformed token, expired token)
  - Duplicate email registration
- Task tests:
  - Full CRUD lifecycle
  - State machine transitions (valid and invalid)
  - Status history tracking
  - Filtering with multiple criteria (AND logic)
  - Assignment and reassignment
- Project tests:
  - Full CRUD lifecycle
  - 404 handling for non-existent projects
- Workspace tests:
  - Workspace CRUD
  - Membership management
  - Cross-workspace isolation (cannot access other workspace resources)
- RBAC tests:
  - Each role tested against each endpoint category
  - Viewer cannot create/update/delete
  - Member cannot delete others' resources
  - Admin can manage members but not change owner
  - Owner has full access
- Comment tests:
  - CRUD on task comments
  - Soft deletion
  - Only author or admin+ can edit/delete
- Notification tests:
  - Auto-generation on relevant events
  - No self-notification
  - Mark read, mark all read, unread count
- Search tests:
  - Cross-resource search
  - Pagination and sorting
  - Empty query handling
- Webhook tests:
  - CRUD for webhook registration
  - Event delivery verification
  - HMAC signature validation
- Audit log tests:
  - Entries created on CRUD operations
  - Change diff accuracy
  - Query filtering
  - Immutability (no update/delete)

## Key Files

- `tests/` or `__tests__/` — Test directory
- `tests/helpers/` — Test utilities and fixtures
- `package.json` — Test script configuration

## Acceptance Criteria

- [ ] All test suites pass with `npm test`
- [ ] Auth flow fully tested including edge cases
- [ ] Task CRUD and state machine transitions tested
- [ ] Workspace isolation verified (cross-workspace access denied)
- [ ] All four RBAC roles tested per endpoint category
- [ ] Comment, notification, search, webhook, and audit features tested
- [ ] Test helpers exist for common setup (create user, create workspace, get token)
- [ ] No flaky tests — all tests deterministic and isolated

## References

- `agent/patterns/testing.md` — Testing patterns and conventions
