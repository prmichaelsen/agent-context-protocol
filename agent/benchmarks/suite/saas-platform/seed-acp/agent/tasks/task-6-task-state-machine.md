# Task 6: Task State Machine

**Status:** not_started
**Milestone:** M2 — Core Features
**Estimated Hours:** 3
**Depends On:** task-5

## Objective

Replace free-form task status strings with a proper state machine that
enforces valid transitions. Track status history so teams can see the
full lifecycle of every task.

## Requirements

- Define valid task states:
  - `open` — Initial state when task is created
  - `in_progress` — Work has started
  - `in_review` — Submitted for review
  - `done` — Completed
  - `archived` — Removed from active view
- Define valid transitions:
  - open -> in_progress
  - in_progress -> in_review, open (reopen)
  - in_review -> in_progress (revision needed), done
  - done -> archived, open (reopen)
  - archived -> open (reopen)
- Create StatusHistory model:
  - Fields: id, taskId, fromStatus, toStatus, changedBy, reason (optional), timestamp
  - Immutable records (append-only)
- Implement transition validation:
  - Reject invalid transitions with 400 and list valid transitions
  - Support optional reason field on transition
  - Emit events on state change (for task-8 integration)
- Add status history endpoint:
  - GET /tasks/:id/history — Returns ordered list of status changes
- Update task creation to default status to `open`

## Key Files

- `src/services/task-service.js` — Add state machine logic
- `src/models/status-history.js` — New status history model
- `src/routes/tasks.js` — Transition endpoint, history endpoint
- `src/middleware/validation.js` — Transition validation helpers

## Acceptance Criteria

- [ ] Only valid transitions are allowed
- [ ] Invalid transitions return 400 with list of valid next states
- [ ] All transitions recorded in StatusHistory
- [ ] GET /tasks/:id/history returns complete ordered history
- [ ] New tasks default to `open` status
- [ ] Transition reason is optional and stored when provided
- [ ] State changes emit events for downstream consumers

## References

- `agent/design/task-state-machine.md` — State diagram and transition rules
