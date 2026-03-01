# TaskFlow API

**Version**: 0.1.0
**Status**: In Development (MVP)

## Overview

TaskFlow is a task management REST API built with Express.js. It supports user authentication, project management, task tracking with assignment and priorities, and in-app notifications.

## Architecture

- **Runtime**: Node.js + Express
- **Storage**: In-memory (arrays/maps)
- **Auth**: JWT tokens via bcryptjs
- **IDs**: UUID v4

## Current State

### Working
- User registration and login (JWT)
- Health endpoint
- Express middleware chain
- Basic project structure (src/routes, src/models, src/middleware)

### Stubbed (Not Implemented)
- Task CRUD (routes return 501)
- Project CRUD (routes return 501)
- Notifications (routes return 501)
- No tests exist

## Key Design Documents
- `agent/design/api-design.md` — Full API specification
- `agent/design/data-model.md` — Entity definitions and relationships
- `agent/design/notification-system.md` — Notification triggers and delivery
- `agent/patterns/error-handling.md` — Error response format and codes
- `agent/patterns/testing.md` — Testing conventions
- `agent/patterns/api-conventions.md` — REST conventions, pagination, filtering
