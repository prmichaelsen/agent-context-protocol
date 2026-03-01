# Task 14: API Documentation

**Status:** not_started
**Milestone:** M3 — Production Hardening
**Estimated Hours:** 2
**Depends On:** task-13

## Objective

Write comprehensive project documentation covering setup, API reference,
system architecture, and a migration guide. Documentation should enable a
new developer to onboard quickly and an API consumer to integrate confidently.

## Requirements

- Write README.md:
  - Project overview and purpose
  - Prerequisites (Node.js version, npm)
  - Installation and setup instructions
  - Environment variables and configuration
  - How to run the server
  - How to run tests
  - Complete API reference with all endpoints:
    - Auth: POST /auth/register, POST /auth/login
    - Tasks: Full CRUD + state transitions + history + comments
    - Projects: Full CRUD
    - Workspaces: CRUD + members + activity + events + search + audit
    - Notifications: List, unread count, mark read
    - Webhooks: CRUD + deliveries
  - For each endpoint: method, path, required headers, request body, response format
- Write ARCHITECTURE.md:
  - High-level system design overview
  - Component diagram (text-based: server -> routes -> services -> models)
  - Middleware pipeline description
  - Data model relationships
  - Event system architecture (EventBus, SSE, webhooks)
  - Authentication and authorization flow
  - Design decisions and trade-offs
- Write MIGRATION.md:
  - Upgrade guide from v0.1 (legacy) to v1.0 (current)
  - Breaking changes list
  - New required headers (x-workspace-id)
  - Changed response formats
  - New authentication requirements
  - Step-by-step migration checklist

## Key Files

- `README.md` — Project documentation and API reference
- `ARCHITECTURE.md` — System architecture documentation
- `MIGRATION.md` — Migration and upgrade guide

## Acceptance Criteria

- [ ] README.md covers setup, configuration, and all API endpoints
- [ ] Every endpoint includes method, path, headers, body, and response format
- [ ] ARCHITECTURE.md explains system design with component relationships
- [ ] MIGRATION.md provides clear upgrade path from legacy to current
- [ ] Documentation is accurate and matches actual implementation
- [ ] A new developer could set up and use the project from README alone
