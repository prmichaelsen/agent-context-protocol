Add a task status state machine:

1. Expand statuses to: todo, in_progress, review, done, blocked
2. Define valid transitions:
   - todo → in_progress
   - in_progress → review, blocked
   - review → done, in_progress (send back)
   - blocked → in_progress (unblock)
   - done → todo (reopen)
3. Reject invalid transitions with 400 error: { error: { code: "VALIDATION_ERROR", message: "Cannot transition from X to Y" } }
4. Create a StatusHistory model: { id, taskId, fromStatus, toStatus, changedBy, changedAt, reason }
5. Record every status change in the history
6. Add GET /tasks/:id/history endpoint returning the status change timeline
